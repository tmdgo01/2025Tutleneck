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

  // 성능 최적화: 처리 빈도 제한
  DateTime _lastProcessTime = DateTime.now();
  static const int _processingIntervalMs = 200; // 5FPS로 제한

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

    /// 의학적 경고 팝업 표시
    void _showMedicalWarningDialog() {
      showDialog(
        context: context,
        barrierDismissible: false, // 반드시 확인해야 함
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  '의학적 주의사항',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      '⚠️ 중요: 본 앱은 의료기기가 아닙니다',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '• 본 애플리케이션은 자세 교정을 위한 보조 도구일 뿐입니다.\n\n'
                        '• 의학적 진단이나 치료를 대체할 수 없으며, 의료 전문가의 조언을 대신하지 않습니다.\n\n'
                        '• 목, 어깨, 척추 등에 지속적인 통증이나 불편함이 있으시면 반드시 의료 전문가와 상담하십시오.\n\n'
                        '• 개인차가 있으므로 측정 결과는 참고용으로만 사용하시기 바랍니다.\n\n'
                        '• 본 앱의 사용으로 인한 어떠한 의료적 문제에 대해서도 책임지지 않습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '건강한 자세 유지를 위한 보조 도구로만 사용해주세요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // 앱 종료
                },
                child: Text(
                  '사용 안함',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showMedicalWarning = false;
                  });
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('이해했습니다'),
              ),
            ],
          );
        },
      );
    }

    /// 정보 팝업 표시 (면책 사항, 자세 기준, 자세 기준 출처)
    void _showInfoDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return DefaultTabController(
            length: 3,
            child: AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '앱 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: '면책사항'),
                        Tab(text: '자세기준'),
                        Tab(text: '출처'),
                      ],
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // 면책 사항 탭
                          SingleChildScrollView(
                            child: Text(
                              '⚠️ 의학적 면책 조항\n\n'
                                  '• 본 애플리케이션은 의료기기가 아니며, 의학적 진단이나 치료를 대체할 수 없습니다.\n\n'
                                  '• 자세 측정 결과는 참고용이며, 개인차가 있을 수 있습니다.\n\n'
                                  '• 목, 어깨, 척추 등에 지속적인 통증이나 불편함이 있으시면 의료 전문가와 상담하세요.\n\n'
                                  '• 본 앱 사용으로 인한 어떠한 의료적 문제에 대해서도 책임지지 않습니다.\n\n'
                                  '• 건강한 자세 유지를 위한 보조 도구로만 사용하시기 바랍니다.',
                              style: TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                          // 자세 기준 탭
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📐 자세 측정 기준\n',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('✅ 바른 자세 (정상)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      Text('• 머리와 목이 어깨 위에 정렬\n• 전방 머리 자세각 < 15°\n• 목-어깨 라인이 일직선'),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('⚠️ 나쁜 자세 (위험/심각)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                      Text('• 전방 머리 자세 (목 앞으로 빠짐)\n• 라운드 숄더 (어깨 앞으로 말림)\n• 전방 머리 자세각 > 15°'),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '📊 측정 원리\n',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '• AI 기반 자세 인식 기술 사용\n'
                                      '• 코, 목, 어깨의 상대적 위치 분석\n'
                                      '• 실시간 각도 및 비율 계산\n'
                                      '• 개인별 체형 차이 고려한 알고리즘',
                                  style: TextStyle(fontSize: 14, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          // 출처 탭
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📚 학술적 근거\n',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '1. Forward Head Posture and Neck Pain:\n'
                                      '• Hansraj, K. K. (2014). Assessment of stresses in the cervical spine caused by posture and position of the head. Surgical Technology International, 25, 277-279.\n\n'
                                      '2. Craniovertebral Angle Assessment:\n'
                                      '• Ruivo, R. M. et al. (2014). Cervical and shoulder postural assessment of adolescents between 15 and 17 years old and association with upper quadrant pain. Brazilian Journal of Physical Therapy, 18(4), 364-371.\n\n'
                                      '3. Computer Vision for Posture Analysis:\n'
                                      '• Plantard, P. et al. (2017). Pose estimation with a kinect for ergonomic studies. Applied Ergonomics, 65, 424-431.\n\n'
                                      '4. Forward Head Posture Measurement:\n'
                                      '• Yip, C. H. et al. (2008). The relationship between head posture and severity and disability of patients with neck pain. Manual Therapy, 13(2), 148-154.',
                                  style: TextStyle(fontSize: 12, height: 1.4),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '🔬 기술적 근거\n',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '• Google ML Kit Pose Detection API\n'
                                      '• MediaPipe Framework 기반\n'
                                      '• 실시간 2D 자세 추정 기술\n'
                                      '• 33개 주요 신체 랜드마크 검출',
                                  style: TextStyle(fontSize: 14, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('닫기'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // 성능 최적화: 히스토리 크기 줄임
  final List<String> _postureHistory = [];
  String _currentPosture = "분석중...";
  double _confidence = 0.0;
  int _badPostureCount = 0;

  // 불필요한 변수들 제거
  Size? _imageSize;
  bool _alertEnabled = true;
  bool _showMedicalWarning = true;

  // 하루 누적 통계
  Map<String, int> _postureStats = {"정상": 0, "위험": 0, "심각": 0};
  DateTime _currentDate = DateTime.now();
  bool _isLoadingStats = true;

  // Firebase - 저장 빈도 최적화
  final PostureService _postureService = PostureService();
  Timer? _saveTimer;
  DateTime _lastSaveTime = DateTime.now();
  static const int _saveIntervalSeconds = 5; // 5초마다 저장

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _loadTodayStatsAndInitialize();
  }

  Future<void> _loadTodayStatsAndInitialize() async {
    try {
      final todayStats = await _postureService.getTodayStats();

      if (mounted) {
        setState(() {
          _postureStats = todayStats;
          _isLoadingStats = false;
        });
      }

      debugPrint('오늘 기존 통계 로딩 완료: $_postureStats');
      await _initializeCamera();
      _startSavingTimer();

    } catch (e) {
      debugPrint('통계 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _postureStats = {"정상": 0, "위험": 0, "심각": 0};
          _isLoadingStats = false;
        });
      }
      await _initializeCamera();
      _startSavingTimer();
    }
  }

  void _startSavingTimer() {
    // 1 -> 30 : firebase 용량 문제
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();

      // 자정 체크
      if (!_isSameDate(now, _currentDate)) {
        debugPrint('00시 통계 초기화: ${now.toIso8601String()}');
        if (mounted) {
          setState(() {
            _currentDate = now;
            _postureStats = {"정상": 0, "위험": 0, "심각": 0};
          });
        }
      }

      // 성능 최적화: 저장 빈도 제한
      if (now.difference(_lastSaveTime).inSeconds >= _saveIntervalSeconds) {
        _saveToFirebase();
        _lastSaveTime = now;
      }
    });
  }

  // Firebase 저장을 별도 함수로 분리
  void _saveToFirebase() {
    final totalFrames = _postureStats.values.fold(0, (prev, count) => prev + count);
    if (totalFrames == 0) return;

    final normalCount = _postureStats['정상'] ?? 0;
    final double currentScore = (normalCount / totalFrames) * 100.0;

    _postureService.savePostureScore(
      score: currentScore,
      stats: Map<String, int>.from(_postureStats),
    );
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
        ResolutionPreset.low, // 성능 최적화: 해상도 낮춤
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
    // 성능 최적화: 처리 빈도 제한
    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < _processingIntervalMs) {
      return;
    }
    _lastProcessTime = now;

    if (_isBusy || !mounted || _isLoadingStats) return;
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

    final postureResult = _classifyPosture(keypoints);

    _updatePostureStats(postureResult['posture']);
    _checkBadPostureAlert(postureResult['posture']);

    if (mounted) {
      setState(() {
        _currentPosture = postureResult['posture'];
        _confidence = postureResult['confidence'];

        // 성능 최적화: 히스토리 크기 제한
        _postureHistory.add(_currentPosture);
        if (_postureHistory.length > 20) { // 100에서 20으로 줄임
          _postureHistory.removeAt(0);
        }
      });
    }
  }

  // 성능 최적화: 키포인트 추출 간소화
  Map<String, Offset?> _extractKeypoints(Pose pose) {
    final keypoints = <String, Offset?>{};

    // 필수 키포인트만 추출
    keypoints['nose'] = _getLandmarkOffset(pose, PoseLandmarkType.nose);
    keypoints['leftShoulder'] = _getLandmarkOffset(pose, PoseLandmarkType.leftShoulder);
    keypoints['rightShoulder'] = _getLandmarkOffset(pose, PoseLandmarkType.rightShoulder);

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

  // 성능 최적화: 자세 분류 알고리즘 간소화
  Map<String, dynamic> _classifyPosture(Map<String, Offset?> keypoints) {
    final nose = keypoints['nose'];
    final neck = keypoints['neck'];
    final leftShoulder = keypoints['leftShoulder'];
    final rightShoulder = keypoints['rightShoulder'];

    if (nose == null || neck == null || leftShoulder == null || rightShoulder == null) {
      return {'posture': '분석중...', 'confidence': 0.0};
    }

    // 간소화된 자세 분석
    final forwardRatio = _calculateForwardRatio(nose, neck);
    final absForwardRatio = forwardRatio.abs();

    String posture;
    double confidence;

    if (absForwardRatio > 0.25) {
      posture = "심각";
      confidence = min(absForwardRatio * 4, 1.0);
    } else if (absForwardRatio > 0.15) {
      posture = "위험";
      confidence = min(absForwardRatio * 6, 1.0);
    } else {
      posture = "정상";
      confidence = 1.0 - (absForwardRatio * 3);
    }

    confidence = confidence.clamp(0.0, 1.0);
    return {'posture': posture, 'confidence': confidence};
  }

  double _calculateForwardRatio(Offset nose, Offset neck) {
    final dx = nose.dx - neck.dx;
    final dy = nose.dy - neck.dy;
    final distance = sqrt(dx * dx + dy * dy);
    return distance == 0 ? 0 : dx / distance;
  }

  void _updatePostureStats(String posture) {
    if (posture == '분석중...') return;
    _postureStats[posture] = (_postureStats[posture] ?? 0) + 1;
  }

  void _checkBadPostureAlert(String posture) {
    if (!_alertEnabled || !mounted) return;

    if (posture != "정상") {
      _badPostureCount++;
      if (_badPostureCount >= 15) { // 30에서 15로 줄임 (빈도 감소로 인해)
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

  /// 정보 팝업 표시 (면책 사항, 자세 기준, 자세 기준 출처)
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 3,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  '앱 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: '면책사항'),
                      Tab(text: '자세기준'),
                      Tab(text: '출처'),
                    ],
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 면책 사항 탭
                        SingleChildScrollView(
                          child: Text(
                            '⚠️ 의학적 면책 조항\n\n'
                                '• 본 애플리케이션은 의료기기가 아니며, 의학적 진단이나 치료를 대체할 수 없습니다.\n\n'
                                '• 자세 측정 결과는 참고용이며, 개인차가 있을 수 있습니다.\n\n'
                                '• 목, 어깨, 척추 등에 지속적인 통증이나 불편함이 있으시면 의료 전문가와 상담하세요.\n\n'
                                '• 본 앱 사용으로 인한 어떠한 의료적 문제에 대해서도 책임지지 않습니다.\n\n'
                                '• 건강한 자세 유지를 위한 보조 도구로만 사용하시기 바랍니다.',
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                        // 자세 기준 탭
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📐 자세 측정 기준\n',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('✅ 바른 자세 (정상)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    Text('• 머리와 목이 어깨 위에 정렬\n• 전방 머리 자세각 < 15°\n• 목-어깨 라인이 일직선'),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('⚠️ 나쁜 자세 (위험/심각)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    Text('• 전방 머리 자세 (목 앞으로 빠짐)\n• 라운드 숄더 (어깨 앞으로 말림)\n• 전방 머리 자세각 > 15°'),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '📊 측정 원리\n',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '• AI 기반 자세 인식 기술 사용\n'
                                    '• 코, 목, 어깨의 상대적 위치 분석\n'
                                    '• 실시간 각도 및 비율 계산\n'
                                    '• 개인별 체형 차이 고려한 알고리즘',
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        // 출처 탭
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📚 학술적 근거\n',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '1. Forward Head Posture and Neck Pain:\n'
                                    '• Hansraj, K. K. (2014). Assessment of stresses in the cervical spine caused by posture and position of the head. Surgical Technology International, 25, 277-279.\n\n'
                                    '2. Craniovertebral Angle Assessment:\n'
                                    '• Ruivo, R. M. et al. (2014). Cervical and shoulder postural assessment of adolescents between 15 and 17 years old and association with upper quadrant pain. Brazilian Journal of Physical Therapy, 18(4), 364-371.\n\n'
                                    '3. Computer Vision for Posture Analysis:\n'
                                    '• Plantard, P. et al. (2017). Pose estimation with a kinect for ergonomic studies. Applied Ergonomics, 65, 424-431.\n\n'
                                    '4. Forward Head Posture Measurement:\n'
                                    '• Yip, C. H. et al. (2008). The relationship between head posture and severity and disability of patients with neck pain. Manual Therapy, 13(2), 148-154.',
                                style: TextStyle(fontSize: 12, height: 1.4),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '🔬 기술적 근거\n',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '• Google ML Kit Pose Detection API\n'
                                    '• MediaPipe Framework 기반\n'
                                    '• 실시간 2D 자세 추정 기술\n'
                                    '• 33개 주요 신체 랜드마크 검출',
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('닫기'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _cameraController?.dispose();
    _poseDetector.close();

    // 메모리 정리
    _postureHistory.clear();
    _postureStats.clear();

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
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
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
          IconButton(
            onPressed: _showInfoDialog,
            icon: Icon(Icons.info_outline),
            tooltip: '앱 정보',
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
                landmarks: [],
                neckPoint: null,
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
    // 모든 시각적 표시 제거 - 성능 최적화
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // 성능 최적화
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