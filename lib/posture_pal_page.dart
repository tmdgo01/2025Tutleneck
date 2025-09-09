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

  final List<String> _postureHistory = [];
  String _currentPosture = "분석중...";
  double _confidence = 0.0;
  double _currentScore = 0.0;
  double _estimatedCVA = 0.0;
  String _currentFeedback = "";
  int _badPostureCount = 0;

  // 값 안정화를 위한 변수들
  final List<double> _recentCVAValues = [];
  final List<double> _recentScores = [];
  final List<String> _recentPostures = [];
  double _smoothedCVA = 0.0;
  double _smoothedScore = 0.0;
  String _stablePosture = "분석중...";

  // 인식 품질 검증을 위한 변수들
  int _validFrameCount = 0;
  int _totalFrameCount = 0;
  double _recognitionQuality = 0.0;
  bool _isUserDetected = false;
  int _consecutiveValidFrames = 0;

  // 측정 상태 관리
  bool _isMeasuring = false;
  String _measurementStatus = "사용자를 찾고 있습니다...";

  // 의학적 위험도 평가 추가
  Map<String, dynamic> _medicalRisk = {
    'level': 'unknown',
    'message': '측정 준비 중...',
    'color': Colors.grey,
  };

  Offset? _neckPoint;
  List<PoseLandmark> _landmarksToDraw = [];
  Size? _imageSize;
  bool _alertEnabled = true;
  bool _showOffsets = false;
  bool _showMedicalDisclaimer = true;

  // CVA 기반 통계 (의학적 기준 적용)
  Map<String, int> _postureStats = {"우수": 0, "양호": 0, "주의": 0, "위험": 0};
  DateTime _currentDate = DateTime.now();
  bool _isLoadingStats = true;

  // Firebase
  final PostureService _postureService = PostureService();
  Timer? _saveTimer;
  Timer? _memoryMonitorTimer;

  // 디버깅용 카운터
  int _processCount = 0;
  int _analysisCount = 0;

  @override
  void initState() {
    super.initState();
    print('안정화된 의학적 기준 CVA PosturePal 초기화 시작');

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    );

    _startMemoryMonitoring();
    _loadTodayStatsAndInitialize();

    // 최초 실행시 의료 면책 조항 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showMedicalDisclaimer) {
        _showMedicalDisclaimerDialog();
      }
    });
  }

  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print('안정화 CVA 측정 - 이미지: $_processCount, 분석: $_analysisCount, 인식률: ${(_recognitionQuality * 100).toStringAsFixed(1)}%');
    });
  }

  Future<void> _loadTodayStatsAndInitialize() async {
    print('오늘 안정화 CVA 통계 로딩 시작...');
    try {
      final todayStats = await _postureService.getTodayStats();

      Map<String, int> convertedStats = {"우수": 0, "양호": 0, "주의": 0, "위험": 0};
      if (todayStats.containsKey("우수")) {
        convertedStats["우수"] = todayStats["우수"] ?? 0;
      }
      if (todayStats.containsKey("양호")) {
        convertedStats["양호"] = todayStats["양호"] ?? 0;
      }
      if (todayStats.containsKey("주의")) {
        convertedStats["주의"] = todayStats["주의"] ?? 0;
      }
      if (todayStats.containsKey("위험")) {
        convertedStats["위험"] = todayStats["위험"] ?? 0;
      }

      setState(() {
        _postureStats = convertedStats;
        _isLoadingStats = false;
      });

      print('안정화 CVA 통계 로딩 완료: $_postureStats');
      await _initializeCamera();
      _startSavingTimer();

    } catch (e) {
      print('안정화 CVA 통계 로딩 실패: $e');
      setState(() {
        _postureStats = {"우수": 0, "양호": 0, "주의": 0, "위험": 0};
        _isLoadingStats = false;
      });
      await _initializeCamera();
      _startSavingTimer();
    }
  }

  void _startSavingTimer() {
    _saveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      if (!_isSameDate(now, _currentDate)) {
        debugPrint('새로운 날! 안정화 CVA 통계 초기화: ${now.toIso8601String()}');
        setState(() {
          _currentDate = now;
          _postureStats = {"우수": 0, "양호": 0, "주의": 0, "위험": 0};
        });
      }

      // 측정이 진행 중일 때만 저장
      if (_isMeasuring && _isUserDetected) {
        final totalFrames = _postureStats.values.fold(0, (prev, count) => prev + count);
        if (totalFrames == 0) return;

        final goodCount = (_postureStats['우수'] ?? 0) + (_postureStats['양호'] ?? 0);
        final double currentScore = (goodCount / totalFrames) * 100.0;

        _postureService.savePostureScore(
          score: currentScore,
          stats: Map<String, int>.from(_postureStats),
        );
      }
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _initializeCamera() async {
    try {
      print('카메라 초기화 시작...');

      final cameras = await availableCameras();
      print('사용 가능한 카메라 개수: ${cameras.length}');

      final frontCamera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // 해상도 향상으로 안정성 증대
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        _cameraController!.startImageStream(_processCameraImage);
        setState(() {});
        print('안정화된 CVA 측정 카메라 준비 완료!');
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 오류: $e')),
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
    if (_isBusy || !mounted || _isLoadingStats) return;

    _isBusy = true;
    _processCount++;
    _totalFrameCount++;

    try {
      if (_processCount % 10 == 1) {
        print('안정화 CVA 이미지 처리 #$_processCount - 인식률: ${(_recognitionQuality * 100).toStringAsFixed(1)}%');
      }

      // 프레임 스킵 줄여서 안정성 향상
      if (_processCount % 2 != 0) {
        return;
      }

      final inputImage = await _convertCameraImageToInputImageOptimized(image);
      if (inputImage == null) return;

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isNotEmpty && mounted) {
        _analyzeStabilizedCVAPosture(poses.first);
      } else {
        // 사용자가 감지되지 않은 경우 처리
        _handleUserNotDetected();
      }
    } catch (e) {
      print('안정화 CVA 이미지 처리 오류: $e');
      _handleUserNotDetected();
    } finally {
      _isBusy = false;
    }
  }

  Future<InputImage?> _convertCameraImageToInputImageOptimized(CameraImage image) async {
    try {
      final bytes = _concatenatePlanes(image.planes);

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getImageRotation(),
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      return inputImage;
    } catch (e) {
      print('이미지 변환 오류: $e');
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  // 사용자 미감지 처리
  void _handleUserNotDetected() {
    _consecutiveValidFrames = 0;

    if (mounted) {
      setState(() {
        _isUserDetected = false;
        _isMeasuring = false;
        _measurementStatus = "카메라에 상체가 보이도록 위치를 조정해주세요";
        _currentPosture = "사용자 감지 안됨";
        _confidence = 0.0;
      });
    }
  }

  // 안정화된 CVA 기반 자세 분석
  void _analyzeStabilizedCVAPosture(Pose pose) {
    try {
      _analysisCount++;

      final keypoints = _extractKeypoints(pose);
      final landmarkQuality = _assessLandmarkQuality(keypoints, pose);

      // 랜드마크 품질이 낮으면 측정하지 않음
      if (landmarkQuality.isInsufficient) {
        _handleInsufficientLandmarks(landmarkQuality);
        return;
      }

      // 유효한 프레임으로 카운트
      _validFrameCount++;
      _consecutiveValidFrames++;
      _recognitionQuality = _validFrameCount / _totalFrameCount;

      // 충분한 연속 프레임이 확보되어야 측정 시작
      if (_consecutiveValidFrames < 5) {
        if (mounted) {
          setState(() {
            _measurementStatus = "자세를 인식 중입니다... (${_consecutiveValidFrames}/5)";
            _isUserDetected = true;
            _isMeasuring = false;
          });
        }
        return;
      }

      // 이제 안전하게 측정 시작
      _isMeasuring = true;
      final cvaResult = _calculateStabilizedCVAFromFrontView(keypoints);

      // 값 안정화 처리
      _stabilizeValues(cvaResult);

      if (_analysisCount % 15 == 1) {
        print('안정화 CVA 분석 성공 #$_analysisCount: ${_smoothedCVA.toStringAsFixed(1)}° (${_stablePosture})');
      }

      // 안정화된 값으로만 통계 업데이트
      _updateMedicalCVAStats(_stablePosture, _smoothedScore);
      _checkPostureAlert(_stablePosture);

      if (mounted) {
        setState(() {
          _measurementStatus = "측정 중 (품질: ${(landmarkQuality.confidence * 100).toStringAsFixed(0)}%)";
          _currentPosture = _stablePosture;
          _confidence = landmarkQuality.confidence;
          _currentScore = _smoothedScore;
          _estimatedCVA = _smoothedCVA;
          _currentFeedback = cvaResult['feedback'] ?? "";
          _medicalRisk = cvaResult['medicalRisk'] ?? _medicalRisk;
          _landmarksToDraw = _getAllLandmarks(pose);
          _neckPoint = keypoints['nose'];
          _isUserDetected = true;

          _postureHistory.add(_stablePosture);
          if (_postureHistory.length > 50) {
            _postureHistory.removeAt(0);
          }
        });
      }
    } catch (e) {
      print('안정화 CVA 분석 오류 #$_analysisCount: $e');
      _handleUserNotDetected();
    }
  }

  // 랜드마크 품질 평가
  LandmarkQuality _assessLandmarkQuality(Map<String, Offset?> keypoints, Pose pose) {
    final nose = keypoints['nose'];
    final leftShoulder = keypoints['leftShoulder'];
    final rightShoulder = keypoints['rightShoulder'];

    // 필수 포인트 검사
    if (nose == null || leftShoulder == null || rightShoulder == null) {
      return LandmarkQuality.insufficient("필수 랜드마크 부족");
    }

    // 어깨 너비 검사 (너무 좁으면 부정확)
    final shoulderWidth = (leftShoulder.dx - rightShoulder.dx).abs();
    if (shoulderWidth < 50) {
      return LandmarkQuality.insufficient("어깨 폭이 너무 좁음 - 카메라에서 멀어져 주세요");
    }

    // 상체 높이 검사
    final bodyHeight = (nose.dy - ((leftShoulder.dy + rightShoulder.dy) / 2)).abs();
    if (bodyHeight < 30) {
      return LandmarkQuality.insufficient("상체 높이가 부족 - 상체 전체가 보이도록 해주세요");
    }

    // 포즈 신뢰도 검사 (ML Kit의 신뢰도)
    double avgConfidence = 0.0;
    int landmarkCount = 0;

    for (final landmarkType in [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftEar,
      PoseLandmarkType.rightEar,
    ]) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null) {
        // ML Kit은 0-1 범위의 신뢰도를 제공하지 않으므로 위치 기반 신뢰도 계산
        landmarkCount++;
      }
    }

    // 감지된 랜드마크 비율로 신뢰도 계산
    avgConfidence = landmarkCount / 5.0;

    // 귀 감지 여부에 따른 보너스
    final hasEars = keypoints['leftEar'] != null && keypoints['rightEar'] != null;
    if (hasEars) {
      avgConfidence = min(1.0, avgConfidence + 0.1);
    }

    if (avgConfidence < 0.6) {
      return LandmarkQuality.insufficient("감지 신뢰도 부족 - 조명을 밝게 하거나 배경을 단순하게 해주세요");
    }

    return LandmarkQuality.sufficient(avgConfidence);
  }

  // 부족한 랜드마크 처리
  void _handleInsufficientLandmarks(LandmarkQuality quality) {
    _consecutiveValidFrames = 0;

    if (mounted) {
      setState(() {
        _isUserDetected = false;
        _isMeasuring = false;
        _measurementStatus = quality.message;
        _currentPosture = "측정 불가";
        _confidence = 0.0;
      });
    }
  }

  // 값 안정화 처리
  void _stabilizeValues(Map<String, dynamic> cvaResult) {
    final newCVA = cvaResult['estimatedCVA'] ?? 0.0;
    final newScore = cvaResult['score'] ?? 0.0;
    final newPosture = cvaResult['posture'] ?? "측정 불가";

    // CVA 값 안정화 (이동평균 적용)
    _recentCVAValues.add(newCVA);
    if (_recentCVAValues.length > 8) { // 8프레임 평균
      _recentCVAValues.removeAt(0);
    }
    _smoothedCVA = _recentCVAValues.reduce((a, b) => a + b) / _recentCVAValues.length;

    // 점수 안정화
    _recentScores.add(newScore);
    if (_recentScores.length > 8) {
      _recentScores.removeAt(0);
    }
    _smoothedScore = _recentScores.reduce((a, b) => a + b) / _recentScores.length;

    // 자세 안정화 (최빈값 사용)
    _recentPostures.add(newPosture);
    if (_recentPostures.length > 10) {
      _recentPostures.removeAt(0);
    }
    _stablePosture = _getMostFrequentPosture(_recentPostures);
  }

  // 최빈 자세 계산
  String _getMostFrequentPosture(List<String> postures) {
    if (postures.isEmpty) return "측정 불가";

    final Map<String, int> frequency = {};
    for (final posture in postures) {
      frequency[posture] = (frequency[posture] ?? 0) + 1;
    }

    String mostFrequent = postures.first;
    int maxCount = 0;

    frequency.forEach((posture, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequent = posture;
      }
    });

    return mostFrequent;
  }

  // 의학 연구 기반 CVA 자세 분석 (안정화 버전)
  Map<String, dynamic> _calculateStabilizedCVAFromFrontView(Map<String, Offset?> keypoints) {
    final nose = keypoints['nose'];
    final leftEar = keypoints['leftEar'];
    final rightEar = keypoints['rightEar'];
    final leftShoulder = keypoints['leftShoulder'];
    final rightShoulder = keypoints['rightShoulder'];

    // 어깨 중점 및 머리 위치 계산
    final shoulderCenter = Offset(
      (leftShoulder!.dx + rightShoulder!.dx) / 2,
      (leftShoulder.dy + rightShoulder.dy) / 2,
    );

    Offset headPosition = nose!;
    bool hasEarData = false;

    if (leftEar != null && rightEar != null) {
      headPosition = Offset(
        (leftEar.dx + rightEar.dx) / 2,
        (leftEar.dy + rightEar.dy) / 2,
      );
      hasEarData = true;
    }

    // 측정값 계산
    final verticalDistance = (shoulderCenter.dy - headPosition.dy).abs();
    final horizontalOffset = (headPosition.dx - shoulderCenter.dx).abs();
    final shoulderWidth = (leftShoulder.dx - rightShoulder.dx).abs();
    final normalizedOffset = shoulderWidth > 0 ? horizontalOffset / shoulderWidth : 0.0;

    final shoulderHeightDiff = (leftShoulder.dy - rightShoulder.dy).abs();
    final shoulderTiltAngle = shoulderWidth > 0 ?
    atan(shoulderHeightDiff / shoulderWidth) * 180 / pi : 0.0;

    // 의학 연구 기반 엄격한 평가 기준
    double postureScore = 100.0;

    // 1. 수평 정렬 평가 (50점)
    if (normalizedOffset <= 0.05) {
      postureScore -= 0;
    } else if (normalizedOffset <= 0.08) {
      postureScore -= 5;
    } else if (normalizedOffset <= 0.12) {
      postureScore -= 15;
    } else if (normalizedOffset <= 0.18) {
      postureScore -= 25;
    } else if (normalizedOffset <= 0.25) {
      postureScore -= 35;
    } else {
      postureScore -= 50;
    }

    // 2. 어깨 균형 평가 (35점)
    if (shoulderTiltAngle <= 1.5) {
      postureScore -= 0;
    } else if (shoulderTiltAngle <= 3.0) {
      postureScore -= 5;
    } else if (shoulderTiltAngle <= 5.0) {
      postureScore -= 15;
    } else if (shoulderTiltAngle <= 8.0) {
      postureScore -= 25;
    } else {
      postureScore -= 35;
    }

    // 3. 신뢰도 평가 (15점)
    double reliabilityScore = 15.0;
    if (!hasEarData) {
      reliabilityScore -= 5; // 감점을 줄여서 안정성 향상
    }
    if (verticalDistance < 50) {
      reliabilityScore -= 5;
    }

    postureScore -= (15 - reliabilityScore);

    // 4. 안정화된 CVA 계산 (랜덤 제거)
    double estimatedCVA = 48.76; // 의학 연구 기반 평균값

    // 수평 편차에 따른 CVA 조정 (일관된 공식 사용)
    if (normalizedOffset <= 0.05) {
      estimatedCVA = 53.5; // 고정값 사용
    } else if (normalizedOffset <= 0.08) {
      estimatedCVA = 51.0;
    } else if (normalizedOffset <= 0.12) {
      estimatedCVA = 49.0;
    } else if (normalizedOffset <= 0.18) {
      estimatedCVA = 46.5;
    } else if (normalizedOffset <= 0.25) {
      estimatedCVA = 43.5;
    } else {
      estimatedCVA = 40.0;
    }

    // 어깨 기울기 보정
    if (shoulderTiltAngle > 5.0) {
      estimatedCVA -= (shoulderTiltAngle - 5.0) * 0.3; // 보정 강도 감소
    }

    estimatedCVA = estimatedCVA.clamp(35.0, 58.0);

    // 최종 점수 계산
    final finalScore = postureScore.clamp(0.0, 100.0);
    final confidence = _calculateConfidence(hasEarData, verticalDistance, shoulderWidth);

    // 의학적 기준에 따른 자세 분류
    String posture;
    String feedback;
    Map<String, dynamic> medicalRisk;

    if (finalScore >= 90 && estimatedCVA >= 52) {
      posture = "매우 우수";
      feedback = "완벽한 목-어깨 정렬입니다! (CVA > 52°)";
      medicalRisk = {
        'level': 'excellent',
        'message': '이상적인 자세입니다',
        'color': Colors.blue,
      };
    } else if (finalScore >= 80 && estimatedCVA >= 48) {
      posture = "양호";
      feedback = "정상 범위의 자세를 유지하고 있습니다.";
      medicalRisk = {
        'level': 'good',
        'message': '현재 자세를 유지하세요',
        'color': Colors.green,
      };
    } else if (finalScore >= 65 && estimatedCVA >= 45) {
      posture = "보통";
      feedback = _generateDetailedFeedback(normalizedOffset, shoulderTiltAngle);
      medicalRisk = {
        'level': 'moderate',
        'message': '자세 개선 운동을 권장합니다',
        'color': Colors.orange,
      };
    } else if (finalScore >= 50 && estimatedCVA >= 42) {
      posture = "주의 필요";
      feedback = "경미한 거북목 위험. 목을 더 세워주세요.";
      medicalRisk = {
        'level': 'caution',
        'message': '거북목 위험 - 자세 교정 필요',
        'color': Colors.orange,
      };
    } else {
      posture = "개선 필요";
      feedback = "심각한 거북목 위험. 즉시 자세 교정하세요.";
      medicalRisk = {
        'level': 'high',
        'message': '전문의 상담을 권장합니다',
        'color': Colors.red,
      };
    }

    return {
      'posture': posture,
      'confidence': confidence,
      'score': finalScore,
      'estimatedCVA': estimatedCVA,
      'shoulderTiltAngle': shoulderTiltAngle,
      'normalizedOffset': normalizedOffset,
      'hasEarData': hasEarData,
      'feedback': feedback,
      'medicalRisk': medicalRisk,
    };
  }

  double _calculateConfidence(bool hasEarData, double verticalDistance, double shoulderWidth) {
    double confidence = 0.7;

    if (hasEarData) confidence += 0.15;
    if (verticalDistance >= 80) confidence += 0.1;
    if (shoulderWidth >= 100) confidence += 0.05;

    return confidence.clamp(0.5, 1.0);
  }

  String _generateDetailedFeedback(double normalizedOffset, double shoulderTilt) {
    List<String> suggestions = [];

    if (normalizedOffset > 0.15) {
      suggestions.add("머리를 어깨 중심선으로");
    }
    if (shoulderTilt > 5.0) {
      suggestions.add("어깨 높이를 맞춰주세요");
    }
    if (suggestions.isEmpty) {
      suggestions.add("목을 조금 더 곧게 세워주세요");
    }

    return suggestions.join(', ');
  }

  Map<String, Offset?> _extractKeypoints(Pose pose) {
    final keypoints = <String, Offset?>{};
    keypoints['nose'] = _getLandmarkOffset(pose, PoseLandmarkType.nose);
    keypoints['leftEar'] = _getLandmarkOffset(pose, PoseLandmarkType.leftEar);
    keypoints['rightEar'] = _getLandmarkOffset(pose, PoseLandmarkType.rightEar);
    keypoints['leftShoulder'] = _getLandmarkOffset(pose, PoseLandmarkType.leftShoulder);
    keypoints['rightShoulder'] = _getLandmarkOffset(pose, PoseLandmarkType.rightShoulder);
    return keypoints;
  }

  void _updateMedicalCVAStats(String posture, double score) {
    if (posture == '측정 불가' || posture == '사용자 감지 안됨') return;

    String category;
    if (score >= 90) {
      category = "우수";
    } else if (score >= 80) {
      category = "양호";
    } else if (score >= 65) {
      category = "주의";
    } else {
      category = "위험";
    }

    _postureStats[category] = (_postureStats[category] ?? 0) + 1;
  }

  void _checkPostureAlert(String posture) {
    if (!_alertEnabled || !mounted || !_isMeasuring) return;

    if (posture != "양호" && posture != "매우 우수") {
      _badPostureCount++;
      if (_badPostureCount >= 30) {
        _badPostureCount = 0;
      }
    } else {
      _badPostureCount = 0;
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

  // 의료 면책 조항 다이얼로그
  void _showMedicalDisclaimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.medical_services, color: Colors.red),
              SizedBox(width: 8),
              Text('의료 면책 조항'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '안정화된 측정 시스템:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text('1. 이동평균을 이용한 값 안정화 적용'),
                SizedBox(height: 4),
                Text('2. 엄격한 사용자 인식 검증 시스템'),
                SizedBox(height: 4),
                Text('3. 의학 연구 기반 CVA 기준 (48-53°)'),
                SizedBox(height: 8),
                Text('4. 정면 카메라 측정의 한계가 있습니다'),
                SizedBox(height: 8),
                Text('5. 실제 CVA 측정은 측면 X-ray가 필요합니다'),
                SizedBox(height: 8),
                Text('6. 지속적인 목/어깨 통증시 전문의 상담 필수'),
                SizedBox(height: 12),
                Text(
                  '이 앱은 안정화된 의학 연구 기반 자세 개선 보조 도구입니다.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('안정화 시스템을 이해했습니다'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showMedicalDisclaimer = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    print('정면 카메라 기반 PosturePal 종료');
    _memoryMonitorTimer?.cancel();
    _saveTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalFrames = _postureStats.values.fold(0, (prev, count) => prev + count);
    final goodRatio = totalFrames > 0
        ? (((_postureStats['우수'] ?? 0) + (_postureStats['양호'] ?? 0)) / totalFrames * 100)
        : 0;

    if (_isLoadingStats) {
      return Scaffold(
        backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Text('PosturePal - 안정화 CVA 분석'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                '안정화된 CVA 측정 시스템 초기화 중...',
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
        title: const Text('PosturePal - 안정화 CVA 측정', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _showMedicalDisclaimerDialog,
            icon: const Icon(Icons.medical_information, color: Colors.white),
            tooltip: '안정화 시스템 정보',
          ),
          IconButton(
            onPressed: () => _showCVAInfoDialog(),
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'CVA 정보',
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
              '카메라 초기화 중...',
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
                showOffsets: _showOffsets,
              ),
              child: Container(),
            ),
          ),
          // 측정 상태 표시
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isUserDetected
                    ? (_isMeasuring ? Colors.green : Colors.orange)
                    : Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isUserDetected
                    ? (_isMeasuring ? Colors.green : Colors.orange)
                    : Colors.red),
              ),
              child: Row(
                children: [
                  Icon(
                    _isUserDetected
                        ? (_isMeasuring ? Icons.check_circle : Icons.hourglass_empty)
                        : Icons.person_search,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _measurementStatus,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  if (_isUserDetected) ...[
                    Text(
                      '${(_recognitionQuality * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
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
                  // 현재 자세 상태 (측정 중일 때만 표시)
                  if (_isMeasuring) ...[
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
                    const SizedBox(height: 16),

                    // 안정화된 자세 점수 표시
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _smoothedScore >= 85
                            ? Colors.green.withOpacity(0.2)
                            : _smoothedScore >= 60
                            ? Colors.white.withOpacity(0.1)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "자세 점수",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${_smoothedScore.toStringAsFixed(1)}점",
                            style: TextStyle(
                              color: _smoothedScore >= 85
                                  ? Colors.green
                                  : _smoothedScore >= 60
                                  ? Colors.white
                                  : Colors.red,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 측정하지 않을 때 안내 메시지
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            _isUserDetected ? Icons.hourglass_empty : Icons.person_search,
                            color: _isUserDetected ? Colors.orange : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isUserDetected
                                ? "자세 인식 중입니다..."
                                : "상체가 잘 보이도록 위치를 조정해주세요",
                            style: TextStyle(
                              color: _isUserDetected ? Colors.orange : Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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

  // CVA 의학적 해석 함수
  String _getCVAInterpretation(double cva) {
    if (cva >= 53) return "이상적";
    if (cva >= 48) return "정상";
    if (cva >= 45) return "경미한 FHP";
    if (cva >= 42) return "중등도 FHP";
    return "심각한 FHP";
  }

  Color _getCVAColor(double cva) {
    if (cva >= 53) return Colors.blue;
    if (cva >= 48) return Colors.green;
    if (cva >= 45) return Colors.orange;
    return Colors.red;
  }

  // CVA 정보 다이얼로그
  void _showCVAInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('안정화 CVA 측정 정보'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '안정화 기능:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 8프레임 이동평균으로 값 안정화'),
                Text('• 연속 5프레임 확보 후 측정 시작'),
                Text('• 엄격한 랜드마크 품질 검증'),
                SizedBox(height: 12),
                Text(
                  'CVA 의학적 기준:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('• 이상적: 53° 이상'),
                Text('• 정상: 48-53°'),
                Text('• 경미한 거북목: 45-48°'),
                Text('• 중등도 거북목: 42-45°'),
                Text('• 심각한 거북목: 42° 미만'),
                SizedBox(height: 12),
                Text(
                  '출처:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('PMC11042887, PMC10558335', style: TextStyle(fontSize: 12)),
                Text('MDPI 2076-3417/14/19/8639', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  IconData _getPostureIcon(String posture) {
    switch (posture) {
      case "매우 우수":
        return Icons.stars;
      case "양호":
        return Icons.check_circle;
      case "보통":
      case "주의 필요":
        return Icons.warning_amber;
      case "개선 필요":
        return Icons.error;
      case "측정 불가":
      case "사용자 감지 안됨":
        return Icons.visibility_off;
      default:
        return Icons.help;
    }
  }

  Color _getPostureColor(String posture) {
    switch (posture) {
      case "매우 우수":
        return Colors.blue;
      case "양호":
        return Colors.green;
      case "보통":
      case "주의 필요":
        return Colors.orange;
      case "개선 필요":
        return Colors.red;
      case "측정 불가":
      case "사용자 감지 안됨":
        return Colors.grey;
      default:
        return Colors.white;
    }
  }
}

// 랜드마크 품질 평가 클래스
class LandmarkQuality {
  final bool isInsufficient;
  final double confidence;
  final String message;

  LandmarkQuality.insufficient(this.message)
      : isInsufficient = true, confidence = 0.0;

  LandmarkQuality.sufficient(this.confidence)
      : isInsufficient = false, message = "";
}

class PosturePalPainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final Offset? neckPoint;
  final String postureType;
  final Size? imageSize;
  final bool showOffsets;

  PosturePalPainter({
    required this.landmarks,
    required this.neckPoint,
    required this.postureType,
    required this.imageSize,
    required this.showOffsets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == null || neckPoint == null) return;

    final scaleX = size.width / imageSize!.width;
    final scaleY = size.height / imageSize!.height;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0
      ..color = Colors.blueAccent;

    if (showOffsets) {
      for (final landmark in landmarks) {
        final offset = Offset(landmark.x * scaleX, landmark.y * scaleY);
        canvas.drawCircle(offset, 4, paint);
      }
    }

    if (neckPoint != null) {
      final neckOffset = Offset(neckPoint!.dx * scaleX, neckPoint!.dy * scaleY);
      final neckPaint = Paint()..color = Colors.yellow;
      canvas.drawCircle(neckOffset, 6, neckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}