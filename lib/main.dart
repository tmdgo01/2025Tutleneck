import 'package:flutter/material.dart';
import 'tracking_page.dart'; // ✅ 이 줄 반드시 필요!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Final Project',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TrackingPage(), // ✅ TrackingPage 호출
    );
  }
}
