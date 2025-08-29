import 'package:finalproject/scr/AlarmScreen.dart';
import 'package:flutter/material.dart';

class ExerciseScreen extends StatelessWidget {
  final List<Map<String, String>> exercises = [
    {'name': '턱 당기기', 'image': 'asset/ex1.jpg'},
    {'name': '벽 밀기', 'image': 'asset/ex2.jpg'},
    {'name': '목 늘리기', 'image': 'asset/ex3.jpg'},
    {'name': '턱 당기기', 'image': 'asset/ex4.jpg'},
  ];

  ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4F3E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Alarm()),
                );
              },

              /// 알람 설정 기능 연결
              child: Text('운동 알람 설정하러 가기!'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return ListTile(
                  leading: Container(
                    width: 60.0,
                    height: 60.0,
                    decoration: BoxDecoration(
                      color: index % 2 == 0
                          ? Color(0xFFF5F1BF)
                          : Color(0xFFCDEBE8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(exercise['image']!, fit: BoxFit.contain),
                  ),
                  title: Text(exercise['name']!),
                );
              },
            ),
          ),
          // Padding(
          //   padding: EdgeInsets.only(bottom: 16.0),
          //   child: Image.asset('asset/bottom.png', width: 80.0),
          // ),
        ],
      ),
    );
  }
}
