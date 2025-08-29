import 'package:finalproject/exercise_screen.dart';
import 'package:finalproject/setting-screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:finalproject/scr/Alarm_list.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'daily_screen.dart';
import 'package:finalproject/scr/tracking_page.dart';

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
  ));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      body: Column(
        children: [
          const SizedBox(height: 50.0), // 상단 여백
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'asset/logo.png',
                height: 250,
                width: 250,
              ),
            ],
          ),
          const SizedBox(height: 10.0), // 여백
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MenuButton(
                      icon: Icons.monitor_heart,
                      label: '측정',
                      color: const Color(0xFFF1F3C9),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PosturePalPage(),
                            ),
                        );
                      }
                    ),
                    _MenuButton(
                      icon: Icons.calendar_month,
                      label: '일지',
                      color: const Color(0xFFD2F0DC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailyScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MenuButton(
                      icon: Icons.fitness_center,
                      label: '운동',
                      color: const Color(0xFFD2F0DC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuButton(
                      icon: Icons.access_alarms_outlined,
                      label: '알람',
                      color: const Color(0xFFF1F3C9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlarmListPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MenuButton(
                      icon: Icons.settings,
                      label: '설정',
                      color: const Color(0xFFD2F0DC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Settingscreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 메뉴 버튼 위젯
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30.0),
            const SizedBox(height: 10.0),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
