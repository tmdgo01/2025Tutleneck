import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:finalproject/posture_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosturePalPage extends StatefulWidget {
  const PosturePalPage({super.key});

  @override
  State<PosturePalPage> createState() => _PosturePalPageState();
}

class _PosturePalPageState extends State<PosturePalPage> {
  CameraController? _cameraController;
  late PoseDetector _poseDetector;
  bool _isBusy = false;

  String _getPostureLabel(String posture) {
    switch (posture) {
      case "정상":
        return "바른 자세";
      case "위험":
      case "심각":
        return "나쁜 자세";
      default:
        return "분석중...";
    }
  }
  final List<String> _postureHistory = [];
  final List<List<double>> _vectorHistory = [];
  String _currentPosture = "분석중...";
  double _confidence = 0.0;
  int _badPostureCount = 0;

  Offset? _neckPoint;
  List<PoseLandmark> _landmarksToDraw = [];
  Size? _imageSize;
  bool _alertEnabled = true;

  // 하루 누적 통계 (앱을 재시작해도 이어짐)
  Map<String, int> _postureStats = {"정상": 0, "위험": 0, "심각": 0};
  DateTime _currentDate = DateTime.now();
  bool _isLoadingStats = true; // 기존 통계 로딩 상태

  // Firebase
  final PostureService _postureService = PostureService();
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _loadTodayStatsAndInitialize(); // 기존 통계를 불러온 후 초기화
  }

  /// 오늘의 기존 통계를 불러오고 카메라 초기화
  Future<void> _loadTodayStatsAndInitialize() async {
    try {
      // Firebase에서 오늘의 기존 통계 불러오기
      final todayStats = await _postureService.getTodayStats();

      setState(() {
        _postureStats = todayStats;
        _isLoadingStats = false;
      });

      debugPrint('오늘 기존 통계 로딩 완료: $_postureStats');

      // 기존 통계를 불러온 후 카메라와 타이머 시작
      await _initializeCamera();
      _startSavingTimer();

    } catch (e) {
      debugPrint('통계 로딩 실패: $e');
      setState(() {
        _postureStats = {"정상": 0, "위험": 0, "심각": 0};
        _isLoadingStats = false;
      });

      // 에러가 나도 카메라는 시작
      await _initializeCamera();
      _startSavingTimer();
    }
  }

  /// 하루 단위 자동 리셋 및 Firebase 저장
  void _startSavingTimer() {
    _saveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      // 자정이 지나면 통계 자동 리셋
      if (!_isSameDate(now, _currentDate)) {
        debugPrint('00시 통계 초기화: ${now.toIso8601String()}');
        setState(() {
          _currentDate = now;
          _postureStats = {"정상": 0, "위험": 0, "심각": 0};
        });
      }

      final totalFrames = _postureStats.values.fold(0, (prev, count) => prev + count);
      if (totalFrames == 0) return;

      final normalCount = _postureStats['정상'] ?? 0;
      final double currentScore = (normalCount / totalFrames) * 100.0;

      // Firebase에 실시간 저장
      _postureService.savePostureScore(
        score: currentScore,
        stats: Map<String, int>.from(_postureStats),
      );
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _initializeCamera() async {
    try {
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

      if (mounted) {
        _cameraController!.startImageStream(_processCameraImage);
        setState(() {});
      }
    } catch (e) {
      debugPrint('카메라 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카메라 초기화에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputImageRotation _getImageRotation() {
    if (_cameraController == null) return InputImageRotation.rotation0deg;
    final camera = _cameraController!.description;
    return InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || !mounted || _isLoadingStats) return; // 통계 로딩 중에는 처리하지 않음
    _isBusy = true;

    try {
      final bytes = WriteBufferHelper.concatenatePlanes(image.planes);
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
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
      if (poses.isNotEmpty && mounted) {
        _analyzePosturePal(poses.first);
      }
    } catch (e) {
      debugPrint('이미지 처리 오류: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _analyzePosturePal(Pose pose) {
    final keypoints = _extractKeypoints(pose);
    if (keypoints.isEmpty) return;

    final postureVector = _createPostureVector(keypoints);
    if (postureVector.isEmpty) return;

    final postureResult = _classifyPosture(postureVector, keypoints);

    _updatePostureStats(postureResult['posture']);
    _checkBadPostureAlert(postureResult['posture']);

    if (mounted) {
      setState(() {
        _currentPosture = postureResult['posture'];
        _confidence = postureResult['confidence'];
        _landmarksToDraw = _getAllLandmarks(pose);
        _neckPoint = keypoints['neck'];

        _postureHistory.add(_currentPosture);
        _vectorHistory.add(postureVector);
        if (_postureHistory.length > 100) {
          _postureHistory.removeAt(0);
          _vectorHistory.removeAt(0);
        }
      });
    }
  }

  Map<String, Offset?> _extractKeypoints(Pose pose) {
    final keypoints = <String, Offset?>{};
    keypoints['nose'] = _getLandmarkOffset(pose, PoseLandmarkType.nose);
    keypoints['leftEye'] = _getLandmarkOffset(pose, PoseLandmarkType.leftEye);
    keypoints['rightEye'] = _getLandmarkOffset(pose, PoseLandmarkType.rightEye);
    keypoints['leftEar'] = _getLandmarkOffset(pose, PoseLandmarkType.leftEar);
    keypoints['rightEar'] = _getLandmarkOffset(pose, PoseLandmarkType.rightEar);
    keypoints['leftShoulder'] = _getLandmarkOffset(pose, PoseLandmarkType.leftShoulder);
    keypoints['rightShoulder'] = _getLandmarkOffset(pose, PoseLandmarkType.rightShoulder);
    keypoints['leftElbow'] = _getLandmarkOffset(pose, PoseLandmarkType.leftElbow);
    keypoints['rightElbow'] = _getLandmarkOffset(pose, PoseLandmarkType.rightElbow);
    keypoints['leftWrist'] = _getLandmarkOffset(pose, PoseLandmarkType.leftWrist);
    keypoints['rightWrist'] = _getLandmarkOffset(pose, PoseLandmarkType.rightWrist);

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

  List<double> _createPostureVector(Map<String, Offset?> keypoints) {
    final neck = keypoints['neck'];
    if (neck == null) return [];

    final vector = <double>[];
    final keypointOrder = [
      'nose', 'leftEye', 'rightEye', 'leftEar', 'rightEar',
      'leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow',
      'leftWrist', 'rightWrist',
    ];

    for (final key in keypointOrder) {
      final point = keypoints[key];
      vector.add(point != null ? point.dx - neck.dx : 0.0);
      vector.add(point != null ? point.dy - neck.dy : 0.0);
    }

    return vector;
  }

  Map<String, dynamic> _classifyPosture(List<double> vector, Map<String, Offset?> keypoints) {
    final nose = keypoints['nose'];
    final neck = keypoints['neck'];
    final leftShoulder = keypoints['leftShoulder'];
    final rightShoulder = keypoints['rightShoulder'];

    if (nose == null || neck == null || leftShoulder == null || rightShoulder == null) {
      return {'posture': '분석중...', 'confidence': 0.0};
    }

    final headNeckAngle = _calculateHeadNeckAngle(nose, neck);
    final forwardRatio = _calculateForwardRatio(nose, neck);

    String posture;
    double confidence;

    // 좌우 대칭적으로 처리하기 위해 절댓값 사용
    final absForwardRatio = forwardRatio.abs();

    if (absForwardRatio > 0.25 || headNeckAngle < 50) {
      posture = "심각";
      confidence = min(absForwardRatio * 4, 1.0);
    } else if (absForwardRatio > 0.15 || headNeckAngle < 75) {
      posture = "위험";
      confidence = min(absForwardRatio * 6, 1.0);
    } else {
      posture = "정상";
      confidence = 1.0 - (absForwardRatio * 3);
    }

    confidence = confidence.clamp(0.0, 1.0);
    return {'posture': posture, 'confidence': confidence};
  }

  double _calculateHeadNeckAngle(Offset nose, Offset neck) {
    final dx = nose.dx - neck.dx;
    final dy = nose.dy - neck.dy;
    return atan2(dy.abs(), dx.abs()) * 180 / pi;
  }

  double _calculateForwardRatio(Offset nose, Offset neck) {
    final dx = nose.dx - neck.dx;
    final dy = nose.dy - neck.dy;
    final distance = sqrt(dx * dx + dy * dy);
    return distance == 0 ? 0 : dx / distance;
  }

  void _updatePostureStats(String posture) {
    if (posture == '분석중...') return;

    // 하루 누적 통계 업데이트
    _postureStats[posture] = (_postureStats[posture] ?? 0) + 1;
  }

  void _checkBadPostureAlert(String posture) {
    if (!_alertEnabled || !mounted) return;

    if (posture != "정상") {
      _badPostureCount++;
      if (_badPostureCount >= 30) {
        _triggerPostureAlert(posture);
        _badPostureCount = 0;
      }
    } else {
      _badPostureCount = 0;
    }
  }

  void _triggerPostureAlert(String badPosture) {
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
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

  /// 수동으로 통계 리셋하는 함수 (테스트용)
  void _resetTodayStats() {
    setState(() {
      _postureStats = {"정상": 0, "위험": 0, "심각": 0};
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('오늘의 통계가 초기화되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 하루 누적 통계로 계산
    final totalFrames = _postureStats.values.fold(0, (prev, count) => prev + count);
    final normalRatio = totalFrames > 0
        ? ((_postureStats['정상'] ?? 0) / totalFrames * 100)
        : 0;

    // 기존 통계 로딩 중일 때
    if (_isLoadingStats) {
      return Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('실시간 자세 측정'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                '오늘의 측정 기록을 불러오는 중...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: const Text('PosturePal - 자세 분석기'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _alertEnabled = !_alertEnabled),
            icon: Icon(_alertEnabled ? Icons.notifications_active : Icons.notifications_off),
            tooltip: '알림 ${_alertEnabled ? '끄기' : '켜기'}',
          ),
        ],
      ),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '카메라를 초기화하는 중...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            child: CameraPreview(_cameraController!),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            child: CustomPaint(
              painter: PosturePalPainter(
                landmarks: _landmarksToDraw,
                neckPoint: _neckPoint,
                postureType: _currentPosture,
                imageSize: _imageSize,
              ),
              child: Container(),
            ),
          ),
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
                  // 현재 자세 상태
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
                          "현재 자세: ${_getPostureLabel(_currentPosture)}",
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
                  // Text(
                  //   "신뢰도: ${(_confidence * 100).toStringAsFixed(1)}%",
                  //   style: const TextStyle(
                  //     color: Colors.white70,
                  //     fontSize: 14,
                  //   ),
                  // ),
                  const SizedBox(height: 16),

                  // 하루 누적 점수 (강조 표시)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: normalRatio >= 80
                          ? Colors.green.withOpacity(0.2)
                          : normalRatio >= 60
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "오늘 자세 점수:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${normalRatio.toStringAsFixed(1)}점",
                          style: TextStyle(
                            color: normalRatio >= 80
                                ? Colors.green
                                : normalRatio >= 60
                                ? Colors.orange
                                : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 총 측정 횟수 표시
                  if (totalFrames > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      "총 측정 횟수: ${totalFrames}회 (앱을 껐다 켜도 누적됩니다)",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

class PosturePalPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Offset? neckPoint;
  final String postureType;
  final Size? imageSize;

  PosturePalPainter({
    required this.landmarks,
    required this.neckPoint,
    required this.postureType,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 모든 시각적 표시 제거 - 키포인트, 목 포인트 등 모두 제거
    // 카메라 화면만 보이도록 함
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 헬퍼 클래스
class WriteBufferHelper {
  static Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}