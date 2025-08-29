import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

class PosturePalPage extends StatefulWidget {
  const PosturePalPage({super.key});

  @override
  State<PosturePalPage> createState() => _PosturePalPageState();
}

class _PosturePalPageState extends State<PosturePalPage> {
  CameraController? _cameraController;
  late PoseDetector _poseDetector;
  bool _isBusy = false;

  // PosturePal 기반 상태 변수들
  final List<String> _postureHistory = [];
  final List<List<double>> _vectorHistory = [];
  String _currentPosture = "분석중...";
  String _previousPosture = "정상";
  double _confidence = 0.0;
  int _badPostureCount = 0; // 연속 나쁜 자세 카운트

  DateTime? _startTime;
  int _totalTrackedSeconds = 0;
  List<PoseLandmark> _landmarksToDraw = [];
  Offset? _neckPoint;
  bool _alertEnabled = true; // 알림 활성화
  bool _showOffsets = false; // offset 표기 토글
  Size? _imageSize; // 카메라 이미지 크기 저장

  // PosturePal 통계 (3단계 구분)
  Map<String, int> _postureStats = {"정상": 0, "위험": 0, "심각": 0};

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _startTime = DateTime.now();
  }

  /// 전면 카메라 초기화
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  /// 플랫폼별 이미지 회전값 계산
  InputImageRotation _getImageRotation() {
    final camera = _cameraController!.description;
    return InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final bytes = WriteBufferHelper.concatenatePlanes(image.planes);
      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      // 이미지 크기 저장
      _imageSize = imageSize;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: _getImageRotation(),
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty) {
        _analyzePosturePal(poses.first);
      }
    } catch (e) {
      // Error handling without debug output
    } finally {
      _isBusy = false;
    }
  }

  /// PosturePal 핵심 자세 분석 알고리즘
  void _analyzePosturePal(Pose pose) {
    // 키포인트 추출 (PosturePal 기준)
    final keypoints = _extractKeypoints(pose);
    if (keypoints.isEmpty) return;

    // 36차원 벡터 생성
    final postureVector = _createPostureVector(keypoints);
    if (postureVector.isEmpty) return;

    // 자세 분류 (3단계 구분)
    final postureResult = _classifyPosture(postureVector, keypoints);

    // 통계 업데이트
    _updatePostureStats(postureResult['posture']);

    // 나쁜 자세 알림 체크
    _checkBadPostureAlert(postureResult['posture']);

    setState(() {
      _currentPosture = postureResult['posture'];
      _confidence = postureResult['confidence'];
      _landmarksToDraw = _getAllLandmarks(pose);
      _neckPoint = keypoints['neck'];

      // 히스토리 관리
      _postureHistory.add(_currentPosture);
      _vectorHistory.add(postureVector);
      if (_postureHistory.length > 100) {
        _postureHistory.removeAt(0);
        _vectorHistory.removeAt(0);
      }
    });
  }

  /// PosturePal 키포인트 추출
  Map<String, Offset?> _extractKeypoints(Pose pose) {
    final keypoints = <String, Offset?>{};

    // PosturePal 논문의 주요 키포인트들
    keypoints['nose'] = _getLandmarkOffset(pose, PoseLandmarkType.nose);
    keypoints['leftEye'] = _getLandmarkOffset(pose, PoseLandmarkType.leftEye);
    keypoints['rightEye'] = _getLandmarkOffset(pose, PoseLandmarkType.rightEye);
    keypoints['leftEar'] = _getLandmarkOffset(pose, PoseLandmarkType.leftEar);
    keypoints['rightEar'] = _getLandmarkOffset(pose, PoseLandmarkType.rightEar);
    keypoints['leftShoulder'] = _getLandmarkOffset(
      pose,
      PoseLandmarkType.leftShoulder,
    );
    keypoints['rightShoulder'] = _getLandmarkOffset(
      pose,
      PoseLandmarkType.rightShoulder,
    );
    keypoints['leftElbow'] = _getLandmarkOffset(
      pose,
      PoseLandmarkType.leftElbow,
    );
    keypoints['rightElbow'] = _getLandmarkOffset(
      pose,
      PoseLandmarkType.rightElbow,
    );
    keypoints['leftWrist'] = _getLandmarkOffset(
      pose,
      PoseLandmarkType.leftWrist,
    );
    keypoints['rightWrist'] = _getLandmarkOffset(
      pose,
      PoseLandmarkType.rightWrist,
    );

    // 목 중심점 계산 (PosturePal 기준점)
    final leftShoulder = keypoints['leftShoulder'];
    final rightShoulder = keypoints['rightShoulder'];
    if (leftShoulder != null && rightShoulder != null) {
      keypoints['neck'] = Offset(
        (leftShoulder.dx + rightShoulder.dx) / 2,
        (leftShoulder.dy + rightShoulder.dy) / 2,
      );
    }

    return keypoints;
  }

  /// 36차원 자세 벡터 생성 (PosturePal 방식)
  List<double> _createPostureVector(Map<String, Offset?> keypoints) {
    final neck = keypoints['neck'];
    if (neck == null) return [];

    final vector = <double>[];

    // 목을 기준으로 상대 좌표 계산
    final keypointOrder = [
      'nose',
      'leftEye',
      'rightEye',
      'leftEar',
      'rightEar',
      'leftShoulder',
      'rightShoulder',
      'leftElbow',
      'rightElbow',
      'leftWrist',
      'rightWrist',
    ];

    for (final key in keypointOrder) {
      final point = keypoints[key];
      if (point != null) {
        vector.add(point.dx - neck.dx); // 상대 X 좌표
        vector.add(point.dy - neck.dy); // 상대 Y 좌표
      } else {
        // Keypoint dropout 처리
        vector.add(0.0);
        vector.add(0.0);
      }
    }

    return vector;
  }

  /// 자세 분류기 (3단계 구분: 정상/위험/심각)
  Map<String, dynamic> _classifyPosture(
      List<double> vector,
      Map<String, Offset?> keypoints,
      ) {
    final nose = keypoints['nose'];
    final neck = keypoints['neck'];
    final leftShoulder = keypoints['leftShoulder'];
    final rightShoulder = keypoints['rightShoulder'];

    if (nose == null ||
        neck == null ||
        leftShoulder == null ||
        rightShoulder == null) {
      return {'posture': '분석중...', 'confidence': 0.0};
    }

    // PosturePal 핵심 각도 계산들
    final headNeckAngle = _calculateHeadNeckAngle(nose, neck);
    final shoulderSlope = _calculateShoulderSlope(leftShoulder, rightShoulder);
    final forwardRatio = _calculateForwardRatio(nose, neck);

    // 3단계 자세 분류 규칙
    String posture;
    double confidence;

    // 심각: 매우 나쁜 자세
    if (forwardRatio > 0.25 || headNeckAngle < 50) {
      posture = "심각";
      confidence = min(forwardRatio * 4, 1.0);
    }
    // 위험: 약간 나쁜 자세
    else if (forwardRatio > 0.15 || headNeckAngle < 75) {
      posture = "위험";
      confidence = min(forwardRatio * 6, 1.0);
    }
    // 정상: 좋은 자세
    else {
      posture = "정상";
      confidence = 1.0 - (forwardRatio.abs() * 3);
    }

    confidence = confidence.clamp(0.0, 1.0);

    return {'posture': posture, 'confidence': confidence};
  }

  /// 머리-목 각도 계산
  double _calculateHeadNeckAngle(Offset nose, Offset neck) {
    final dx = nose.dx - neck.dx;
    final dy = nose.dy - neck.dy;
    final angle = atan2(dy.abs(), dx.abs()) * 180 / pi;
    return angle;
  }

  /// 어깨 기울기 계산
  double _calculateShoulderSlope(Offset leftShoulder, Offset rightShoulder) {
    final dy = rightShoulder.dy - leftShoulder.dy;
    final dx = rightShoulder.dx - leftShoulder.dx;
    return dx == 0 ? 0 : dy / dx;
  }

  /// 전방 비율 계산 (PosturePal 핵심)
  double _calculateForwardRatio(Offset nose, Offset neck) {
    final dx = nose.dx - neck.dx;
    final dy = nose.dy - neck.dy;
    final distance = sqrt(dx * dx + dy * dy);
    return distance == 0 ? 0 : dx / distance;
  }

  /// 자세 통계 업데이트
  void _updatePostureStats(String posture) {
    // 안전한 업데이트
    switch (posture) {
      case "정상":
        _postureStats["정상"] = (_postureStats["정상"] ?? 0) + 1;
        break;
      case "위험":
        _postureStats["위험"] = (_postureStats["위험"] ?? 0) + 1;
        break;
      case "심각":
        _postureStats["심각"] = (_postureStats["심각"] ?? 0) + 1;
        break;
      default:
        return;
    }
  }

  /// 나쁜 자세 알림 체크
  void _checkBadPostureAlert(String posture) {
    if (!_alertEnabled) return;

    if (posture != "정상") {
      _badPostureCount++;
      // 연속 30프레임(약 1초) 나쁜 자세 시 알림
      if (_badPostureCount >= 30) {
        _triggerPostureAlert(posture);
        _badPostureCount = 0; // 리셋
      }
    } else {
      _badPostureCount = 0;
    }
  }

  /// 자세 알림 트리거
  void _triggerPostureAlert(String badPosture) {
    // 진동 알림
    HapticFeedback.mediumImpact();

    // 화면 알림
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                badPosture == "심각" ? Icons.dangerous : Icons.warning,
                color: badPosture == "심각" ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$badPosture 자세를 감지했습니다!\n바른 자세를 취해주세요.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: badPosture == "심각"
              ? Colors.red.shade700
              : Colors.orange.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 헬퍼 함수들
  Offset? _getLandmarkOffset(Pose pose, PoseLandmarkType type) {
    final landmark = pose.landmarks[type];
    return landmark != null ? Offset(landmark.x, landmark.y) : null;
  }

  List<PoseLandmark> _getAllLandmarks(Pose pose) {
    final landmarks = <PoseLandmark>[];
    for (final type in PoseLandmarkType.values) {
      final landmark = pose.landmarks[type];
      if (landmark != null) landmarks.add(landmark);
    }
    return landmarks;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // totalFrames 계산 시 안전한 처리
    final totalFrames = _postureStats.values.isEmpty
        ? 0
        : _postureStats.values.reduce((a, b) => a + b);
    final normalRatio = totalFrames > 0
        ? ((_postureStats['정상'] ?? 0) / totalFrames * 100)
        : 0;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('PosturePal - 자세 분석기'),
        actions: [
          // 알림 토글
          IconButton(
            onPressed: () {
              setState(() {
                _alertEnabled = !_alertEnabled;
              });
            },
            icon: Icon(
              _alertEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
            ),
          ),
          // offset 표기 토글 추가 (전체 키포인트 on/off)
          IconButton(
            onPressed: () {
              setState(() {
                _showOffsets = !_showOffsets;
              });
            },
            icon: Icon(_showOffsets ? Icons.visibility : Icons.visibility_off),
            tooltip: '키포인트 표시',
          ),
        ],
      ),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // 카메라 미러 모드
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            child: CameraPreview(_cameraController!),
          ),

          // 키포인트 오버레이 (상체만, offset 토글 적용)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            child: CustomPaint(
              painter: PosturePalPainter(
                landmarks: _landmarksToDraw,
                neckPoint: _neckPoint,
                postureType: _currentPosture,
                imageSize: _imageSize,
                showOffsets: _showOffsets, // offset 표기 토글 전달
              ),
              child: Container(),
            ),
          ),

          // PosturePal UI
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 현재 자세 (3단계 구분)
                  Row(
                    children: [
                      Icon(
                        _getPostureIcon(_currentPosture),
                        color: _getPostureColor(_currentPosture),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "현재 자세: $_currentPosture",
                          style: TextStyle(
                            color: _getPostureColor(_currentPosture),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 신뢰도
                  Text(
                    "신뢰도: ${(_confidence * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 정상 자세 비율
                  Text(
                    "정상 자세 비율: ${normalRatio.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: normalRatio >= 80
                          ? Colors.green
                          : normalRatio >= 60
                          ? Colors.orange
                          : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3단계 통계 (null 방지)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "정상: ${_postureStats['정상'] ?? 0}회",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "위험: ${_postureStats['위험'] ?? 0}회",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "심각: ${_postureStats['심각'] ?? 0}회",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 자세별 아이콘 반환
  IconData _getPostureIcon(String posture) {
    switch (posture) {
      case "정상":
        return Icons.check_circle;
      case "위험":
        return Icons.warning;
      case "심각":
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  /// 자세별 색상 반환
  Color _getPostureColor(String posture) {
    switch (posture) {
      case "정상":
        return Colors.green;
      case "위험":
        return Colors.orange;
      case "심각":
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}

/// PosturePal 전용 페인터 (상체만, offset 토글 적용)
class PosturePalPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Offset? neckPoint;
  final String postureType;
  final Size? imageSize;
  final bool showOffsets; // offset 표기 토글

  PosturePalPainter({
    required this.landmarks,
    required this.neckPoint,
    required this.postureType,
    this.imageSize,
    this.showOffsets = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null || !showOffsets)
      return; // showOffsets가 false면 아무것도 그리지 않음

    // 자세별 색상 (3단계)
    Color postureColor;
    switch (postureType) {
      case "정상":
        postureColor = Colors.green;
        break;
      case "위험":
        postureColor = Colors.orange;
        break;
      case "심각":
        postureColor = Colors.red;
        break;
      default:
        postureColor = Colors.white;
    }

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = postureColor;

    // 한국어 신체 부위 매핑
    String getLandmarkName(int index) {
      final types = [
        '코',
        '왼눈안',
        '왼눈',
        '왼눈밖',
        '오른눈안',
        '오른눈',
        '오른눈밖',
        '왼귀',
        '오른귀',
        '입좌',
        '입우',
        '왼어깨',
        '오른어깨',
        '왼팔꿈치',
        '오른팔꿈치',
        '왼손목',
        '오른손목',
        '왼엉덩이',
        '오른엉덩이',
        '왼무릎',
        '오른무릎',
        '왼발목',
        '오른발목',
        '왼발뒤꿈치',
        '오른발뒤꿈치',
        '왼발가락',
        '오른발가락',
        '왼손새끼',
        '오른손새끼',
        '왼손검지',
        '오른손검지',
        '왼손엄지',
        '오른손엄지',
      ];
      return index < types.length ? types[index] : '알수없음';
    }

    // 상체만 표시 (점만)
    for (int i = 0; i < landmarks.length; i++) {
      final landmark = landmarks[i];
      final landmarkName = getLandmarkName(i);

      // 상체 부위만 필터링 (하체 완전 제외)
      final upperBodyParts = [
        '코',
        '왼눈안',
        '왼눈',
        '왼눈밖',
        '오른눈안',
        '오른눈',
        '오른눈밖',
        '왼귀',
        '오른귀',
        '입좌',
        '입우',
        '왼어깨',
        '오른어깨',
        '왼팔꿈치',
        '오른팔꿈치',
        '왼손목',
        '오른손목',
      ];

      if (!upperBodyParts.contains(landmarkName)) continue; // 하체 완전 스킵

      // 점만 그리기 (위치 보정: y좌표를 위로 이동)
      canvas.drawCircle(
        Offset(landmark.x - 30, landmark.y - 65), // 좌표 수정
        3,
        pointPaint,
      );
    }

    // 목 중심점 표시 (위치 보정: y좌표를 위로 이동)
    if (neckPoint != null) {
      canvas.drawCircle(
        Offset(neckPoint!.dx - 30, neckPoint!.dy - 80), // 좌표 수정
        5,
        pointPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PosturePalPainter oldDelegate) =>
      oldDelegate.landmarks != landmarks ||
          oldDelegate.neckPoint != neckPoint ||
          oldDelegate.postureType != postureType ||
          oldDelegate.imageSize != imageSize ||
          oldDelegate.showOffsets != showOffsets;
}

class WriteBufferHelper {
  static Uint8List concatenatePlanes(List<Plane> planes) {
    final allBytes = BytesBuilder();
    for (final Plane plane in planes) {
      allBytes.add(plane.bytes);
    }
    return allBytes.toBytes();
  }
}
