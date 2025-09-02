import 'package:flutter/material.dart';
import 'Alarm_list.dart';
import 'ExerciseScreen.dart';

class AlarmPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알람 화면'),
        backgroundColor: Color(0xFFE4F3E1),
      ),
      backgroundColor: Color(0xFFE4F3E1), // [수정] 시각적으로 눈에 띄게
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  '운  동  해',
                  style: TextStyle(
                    fontSize: 50,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Image.asset('asset/sit.png',
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                      ),
                      onPressed:(){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>AlarmListPage(),
                          ),
                        );
                      },
                      child:const Icon(Icons.call_end, size: 32, color: Colors.white),
                    ),
                    SizedBox(width:100 ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                      ),
                      onPressed:(){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>ExerciseScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.call, size: 32, color: Colors.white),
                    ),
                  ],
                )
              ]
          ),
        ),
      ),
    );
  }
}
