import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:finalproject/scr/HomeScreen.dart';
import 'package:intl/date_symbol_data_local.dart';

List<CameraDescription> cameras = [];

void main() async {
  // Flutter 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  try {
    // Firebase 초기화
    await Firebase.initializeApp();

    // 카메라 초기화
    cameras = await availableCameras();

    print('Firebase 초기화 성공');
    print('사용 가능한 카메라: ${cameras.length}개');

  } catch (e) {
    print('초기화 실패: $e');
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
  )
  );
}

