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
import 'background_alarm_service.dart';
import 'alarm_data.dart';

List<CameraDescription> cameras = [];
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Firebase.initializeApp();

  try {
    cameras = await availableCameras();
    print('사용 가능한 카메라: ${cameras.length}개');
  } catch (e) {
    print('카메라 초기화 실패: $e');
  }
  await BackgroundAlarmService.initialize(navigatorKey: navigatorKey);

  // 알람 권한 요청
  bool granted = await BackgroundAlarmService.requestPermissions();
  if (!granted) {
    print('⚠️ 알람 권한 거부됨');
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
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _scheduleAlarmsOnStart(); // 앱 시작 시 알람 예약
  }

  /// 앱 시작 시 Firestore에서 알람 데이터를 가져와 예약
  Future<void> _scheduleAlarmsOnStart() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Firestore에서 알람 컬렉션 불러오기
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('alarms')
          .get();

      // AlarmData 객체로 변환 후 활성 알람만 필터링
      final alarms = snapshot.docs
          .map((doc) => AlarmData.fromMap(doc.data()))
          .where((alarm) => alarm.isAlarmEnabled)
          .toList();

      if (alarms.isEmpty) {
        print('⚠️ 활성 알람이 없습니다.');
        return;
      }

      // 알람 예약
      await BackgroundAlarmService.scheduleAllAlarms(alarms);

      // 예약된 알람 로그 확인
      await BackgroundAlarmService.printScheduledNotifications();

      print('✅ 알람 예약 완료: ${alarms.length}개');
    } catch (e) {
      print('⚠️ 알람 예약 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/alarm': (context) => const AlarmListPage(),
      },
    );
  }
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       debugShowCheckedModeBanner: false,
//       home: FutureBuilder(
//         future: Firebase.initializeApp(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               backgroundColor: Color(0xFFE4F3E1),
//               body: Center(
//                 child: CircularProgressIndicator(color: Colors.green),
//               ),
//             );
//           }
//
//           if (snapshot.hasError) {
//             return const Scaffold(
//               backgroundColor: Color(0xFFE4F3E1),
//               body: Center(
//                 child: Text(
//                   'Firebase 초기화 중 오류가 발생했습니다.',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             );
//           }
//
//           return const AuthWrapper();
//         },
//       ),
//       routes: {
//         '/home': (context) => const HomeScreen(),
//         '/auth': (context) => const AuthScreen(),
//         '/alarm': (context) => const AlarmListPage(),
//       },
//     );
//   }
// }

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
                    width: 170,
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

              const SizedBox(height: 30),

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
                      scoreMessage = '자세 점수 ${score.toStringAsFixed(1)}점이에요. 훌륭해요!)';
                    } else if (score >= 60) {
                      scoreColor = Colors.orange[700]!;
                      scoreMessage = '자세 점수 ${score.toStringAsFixed(1)}점이네요. 조금만 신경 써주세요.';
                    } else if (score > 0) {
                      scoreColor = Colors.red[700]!;
                      scoreMessage = '자세 점수 ${score.toStringAsFixed(1)}점이에요... 자세를 고쳐야 해요';
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
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20), // 상단 여백 추가
                        _buildMenuButton(
                          icon: Icons.monitor_heart,
                          label: '측정',
                          color: const Color(0xFFF1F3C9),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const posture.PosturePalPage()),
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
                                builder: (context) => SettingScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20), // 하단 여백 추가
                      ],
                    ),
                  ),
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