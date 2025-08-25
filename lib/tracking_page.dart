import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  CameraController? _cameraController;
  late PoseDetector _poseDetector;
  bool _isBusy = false;

  final List<double> _angleHistory = [];
  double _latestScore = 100;
  DateTime? _startTime;
  int _totalTrackedSeconds = 0;

  List<PoseLandmark> _landmarksToDraw = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _startTime = DateTime.now();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
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
      final camera = _cameraController!.description;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation:
              InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty) {
        final pose = poses.first;
        _analyzePose(pose);
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _analyzePose(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (nose != null && leftShoulder != null && rightShoulder != null) {
      final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final diff = nose.y - avgShoulderY;

      // clamp에서 double을 명시
      final double score = (100 - (diff / 30 * 100)).clamp(0.0, 100.0);

      setState(() {
        _angleHistory.add(score);
        _latestScore = score;

        // 추적할 랜드마크: 얼굴(코, 눈, 귀) + 어깨
        _landmarksToDraw = [
          nose,
          if (pose.landmarks[PoseLandmarkType.leftEye] != null)
            pose.landmarks[PoseLandmarkType.leftEye]!,
          if (pose.landmarks[PoseLandmarkType.rightEye] != null)
            pose.landmarks[PoseLandmarkType.rightEye]!,
          if (pose.landmarks[PoseLandmarkType.leftEar] != null)
            pose.landmarks[PoseLandmarkType.leftEar]!,
          if (pose.landmarks[PoseLandmarkType.rightEar] != null)
            pose.landmarks[PoseLandmarkType.rightEar]!,
          leftShoulder,
          rightShoulder,
        ];
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _saveSession() async {
    final endTime = DateTime.now();
    _totalTrackedSeconds = endTime.difference(_startTime ?? endTime).inSeconds;

    final avgScore = _angleHistory.isEmpty
        ? 0
        : _angleHistory.reduce((a, b) => a + b) / _angleHistory.length;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/session.txt');
    final data =
        "평균 점수: ${avgScore.toStringAsFixed(1)}\n총 측정 시간: $_totalTrackedSeconds 초";
    await file.writeAsString(data);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('세션 저장 완료: ${file.path}')));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("세션 결과"),
        content: Text(
          "평균 점수: ${avgScore.toStringAsFixed(1)}\n총 측정 시간: $_totalTrackedSeconds 초",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추적 페이지'),
        actions: [
          IconButton(onPressed: _saveSession, icon: const Icon(Icons.save)),
        ],
      ),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  color: Colors.black, // 원본 카메라 화면 숨김
                ),
                CustomPaint(
                  painter: PosePainter(
                    landmarks: _landmarksToDraw,
                    score: _latestScore,
                  ),
                  child: Container(),
                ),
              ],
            ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<PoseLandmark> landmarks;
  final double score;

  PosePainter({required this.landmarks, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = _getColor(score);

    for (final landmark in landmarks) {
      canvas.drawCircle(
        Offset(landmark.x.toDouble(), landmark.y.toDouble()),
        8,
        paint,
      );
    }
  }

  Color _getColor(double score) {
    if (score > 80) return Colors.green;
    if (score > 50) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) =>
      oldDelegate.landmarks != landmarks || oldDelegate.score != score;
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
