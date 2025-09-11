import 'package:finalproject/exercise_screen.dart';
import 'package:finalproject/setting_screen.dart';
import 'package:finalproject/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:finalproject/alarm_list_page.dart';
import 'package:finalproject/posture_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'daily_screen.dart';
// import 'package:finalproject/scr/splash.dart'; // 스플래시 관련 import 제거
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
  bool granted = await BackgroundAlarmService.requestPermissions();
  if (!granted) {
    print('⚠️ 알람 권한 거부됨');
  }

  // 스플래시 화면 없이 바로 MyApp 실행
  runApp(const MyApp());
}

// EntryPoint 클래스 제거 - 더 이상 필요 없음

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _scheduleAlarmsOnStart();
  }

  Future<void> _scheduleAlarmsOnStart() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('alarms')
          .get();

      final alarms = snapshot.docs
          .map((doc) => AlarmData.fromMap(doc.data()))
          .where((alarm) => alarm.isAlarmEnabled)
          .toList();

      if (alarms.isEmpty) {
        print('⚠️ 활성 알람이 없습니다.');
        return;
      }

      await BackgroundAlarmService.scheduleAllAlarms(alarms);
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
      home: const AuthWrapper(), // 바로 AuthWrapper로 이동
      routes: {
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/alarm': (context) => const AlarmListPage(),
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
              const SizedBox(height: 10),

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
                  // const SizedBox(height: 16),
                ],
              ),

              const SizedBox(height: 30),

              // 점수 카드
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
                  stream: _postureService.getTodayPostureStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildStatusText(
                        userName,
                        '자세 점수를 불러오는 중...',
                        Colors.grey,
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildStatusText(
                        userName,
                        '자세 점수 로딩 중 오류 발생',
                        Colors.red,
                      );
                    }

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

                    // 점수 색상 및 메시지
                    Color scoreColor;
                    TextSpan scoreTextSpan;

                    if (score >= 80) {
                      scoreColor = Colors.green[700]!;
                      scoreTextSpan =
                          _scoreSpan(score, scoreColor, '이에요. \n훌륭해요!');
                    } else if (score >= 60) {
                      scoreColor = Colors.orange[700]!;
                      scoreTextSpan =
                          _scoreSpan(score, scoreColor, '이네요. \n조금만 신경 써주세요.');
                    } else if (score > 0) {
                      scoreColor = Colors.red[700]!;
                      scoreTextSpan = _scoreSpan(
                        score,
                        scoreColor,
                        '이에요.\n더 건강한 자세를 위해\n 전문가와 상담해보는 건 어떨까요?',
                      );
                    } else {
                      scoreColor = Colors.grey[600]!;
                      scoreTextSpan = const TextSpan(
                        text: '아직 자세 측정 기록이 없어요',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      );
                    }

                    return RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(text: '안녕하세요 $userName 님!\n'),
                          scoreTextSpan,
                        ],
                      ),
                    );
                  },
                ),
              ),

              // const SizedBox(height: 30),

              // 메뉴 버튼 영역
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuButton(
                      context,
                      icon: Icons.monitor_heart,
                      label: '측정',
                      color: const Color(0xFFF1F3C9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const posture.PosturePalPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
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
                      context,
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
                      context,
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
                      context,
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
                    // const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 점수 메시지 TextSpan 생성
  TextSpan _scoreSpan(double score, Color scoreColor, String message) {
    return TextSpan(
      children: [
        const TextSpan(
          text: '자세 점수 ',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        TextSpan(
          text: '${score.toStringAsFixed(1)}점',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: scoreColor,
          ),
        ),
        TextSpan(
          text: message,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  /// 상태 메시지(RichText) 생성
  RichText _buildStatusText(String userName, String message, Color color) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: '안녕하세요 $userName 님!\n'),
          TextSpan(
            text: message,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  /// 메뉴 버튼 생성
  Widget _buildMenuButton(
      BuildContext context, {
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
              // const SizedBox(width: 16),
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