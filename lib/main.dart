import 'package:finalproject/exercise_screen.dart';
import 'package:finalproject/setting-screen.dart';
import 'package:finalproject/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera/camera.dart';
import 'package:finalproject/alarm_list_page.dart'; // 경로 수정
import 'package:intl/date_symbol_data_local.dart';
import 'daily_screen.dart';
import 'package:finalproject/scr/tracking_page.dart';

List<CameraDescription> cameras = [];

void main() async {
  // Flutter 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  try {
    // 카메라 초기화
    cameras = await availableCameras();
    print('사용 가능한 카메라: ${cameras.length}개');
  } catch (e) {
    print('카메라 초기화 실패: $e');
  }

  runApp(MyApp());
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
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
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

          return AuthWrapper();
        },
      ),
      routes: {
        '/home': (context) => HomeScreen(),
        '/auth': (context) => AuthScreen(),
      },
    );
  }
}

// 인증 상태를 확인하는 래퍼 위젯
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
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          // 사용자가 로그인된 경우
          return HomeScreen();
        } else {
          // 사용자가 로그인되지 않은 경우
          return AuthScreen();
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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestore에서 사용자 정보 가져오기
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
        title: Text(
          '안녕하세요, ${userName}님!',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // 로그아웃 버튼 추가
          IconButton(
            onPressed: () async {
              // 로그아웃 확인 다이얼로그
              bool? shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                try {
                  // Firebase 로그아웃
                  await FirebaseAuth.instance.signOut();

                  // 로그인 페이지로 강제 이동
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/auth',
                          (Route<dynamic> route) => false, // 모든 이전 페이지 제거
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('로그아웃이 완료되었습니다.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('로그아웃 중 오류 발생: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('로그아웃 중 오류가 발생했습니다.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout, color: Colors.black54),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30.0), // 상단 여백
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 대신 거북이 아이콘과 함께 welcome 메시지
              Column(
                children: [
                  Container(
                    width: 120,
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
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'turtle',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ' neck',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${userName}님, 환영합니다!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40.0), // 여백
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
                            builder: (context) => const AlarmListPage(), // const 추가
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30.0, color: Colors.black87),
            const SizedBox(height: 10.0),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}