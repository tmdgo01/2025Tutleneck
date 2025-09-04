import 'package:finalproject/exercise_screen.dart';
import 'package:finalproject/setting_screen.dart';
import 'package:finalproject/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:finalproject/alarm_list_page.dart';
import 'package:finalproject/posture_service.dart'; // Firebase 자세 점수 서비스
import 'package:intl/date_symbol_data_local.dart';
import 'daily_screen.dart';
import 'package:finalproject/scr/tracking_page.dart' as tracking;
import 'package:finalproject/scr/splash.dart';
import 'package:finalproject/posture_pal_page.dart' as posture;
import 'dart:async';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  try {
    cameras = await availableCameras();
    print('사용 가능한 카메라: ${cameras.length}개');
  } catch (e) {
    print('카메라 초기화 실패: $e');
  }

  runApp(const EntryPoint());
}

class EntryPoint extends StatelessWidget {
  const EntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // 스플래시 먼저 보여줌
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFE4F3E1),
              body: Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            );
          }

          if (snapshot.hasError) {
            return const Scaffold(
              backgroundColor: Color(0xFFE4F3E1),
              body: Center(
                child: Text(
                  'Firebase 초기화 중 오류가 발생했습니다.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          return const AuthWrapper();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFE4F3E1),
            body: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '사용자';
  final PostureService _postureService = PostureService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc.get('name') ?? user.displayName ?? '사용자';
          });
        } else if (user.displayName != null) {
          setState(() {
            userName = user.displayName!;
          });
        }
      }
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 로고
              Column(
                children: [
                  SizedBox(
                    width: 190,
                    child: Image.asset(
                      'asset/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 190,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green[300],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

              const SizedBox(height: 32),

              // Firebase 실시간 자세 점수 표시 - 수정된 부분
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _postureService.getTodayPostureStream(),  // 오늘 날짜로 자동 설정됨
                  builder: (context, snapshot) {
                    // 연결 상태 확인
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '안녕하세요 $userName 님!\n 오늘도 좋은 하루 보내세요 \n',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(
                              text: '자세 점수를 불러오는 중...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 오류 처리
                    if (snapshot.hasError) {
                      return RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '안녕하세요 $userName 님!\n 오늘도 좋은 하루 보내세요 \n',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(
                              text: '자세 점수 로딩 중 오류 발생',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 안전하게 점수 추출
                    double score = 0.0;
                    try {
                      if (snapshot.hasData &&
                          snapshot.data!.exists &&
                          snapshot.data!.data() != null) {
                        final data = snapshot.data!.data()!;
                        final scoreValue = data['score'];
                        if (scoreValue != null && scoreValue is num) {
                          score = scoreValue.toDouble();
                        }
                      }
                    } catch (e) {
                      debugPrint('점수 추출 오류: $e');
                      score = 0.0;
                    }

                    // 점수에 따른 색상 결정
                    Color scoreColor;
                    String scoreMessage;

                    if (score >= 80) {
                      scoreColor = Colors.green[700]!;
                      scoreMessage = '자세 점수 ${score.toStringAsFixed(1)}점 (훌륭해요!)';
                    } else if (score >= 60) {
                      scoreColor = Colors.orange[700]!;
                      scoreMessage = '자세 점수 ${score.toStringAsFixed(1)}점 (괜찮아요!)';
                    } else if (score > 0) {
                      scoreColor = Colors.red[700]!;
                      scoreMessage = '자세 점수 ${score.toStringAsFixed(1)}점 (개선이 필요해요)';
                    } else {
                      scoreColor = Colors.grey[600]!;
                      scoreMessage = '아직 자세 측정 기록이 없어요';
                    }

                    return RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '안녕하세요 $userName 님!\n 오늘도 좋은 하루 보내세요 \n',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: scoreMessage,
                            style: TextStyle(
                              fontSize: 16,
                              color: scoreColor,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // 메뉴 버튼
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuButton(
                      icon: Icons.monitor_heart,
                      label: '측정',
                      color: const Color(0xFFF1F3C9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const posture.PosturePalPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      icon: Icons.calendar_month,
                      label: '일지',
                      color: const Color(0xFFD2F0DC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DailyScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      icon: Icons.fitness_center,
                      label: '운동',
                      color: const Color(0xFFF1F3C9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      icon: Icons.access_alarms_outlined,
                      label: '알람',
                      color: const Color(0xFFD2F0DC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AlarmListPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      icon: Icons.settings,
                      label: '설정',
                      color: const Color(0xFFF1F3C9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingScreen(), // const 제거
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 메뉴 버튼 생성 함수
  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: Colors.black87),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}