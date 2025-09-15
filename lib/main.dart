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
import 'package:finalproject/posture_pal_page.dart' as posture;
import 'dart:async';
import 'background_alarm_service.dart';
import 'alarm_data.dart';
import 'firebase_options.dart';

List<CameraDescription> cameras = [];
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _isFirebaseInitialized = false;

void main() async {
  print('🚀 === 앱 시작 ===');
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ WidgetsFlutterBinding 초기화 성공');
  } catch (e) {
    print('❌ WidgetsFlutterBinding 초기화 실패: $e');
  }
  
  try {
    await initializeDateFormatting();
    print('✅ 날짜 포맷팅 초기화 성공');
  } catch (e) {
    print('⚠️ 날짜 포맷팅 초기화 실패: $e');
  }
  
  // Firebase 초기화를 더 안전하게 처리
  bool firebaseInitialized = false;
  try {
    print('🔄 Firebase 초기화 시작...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print('✅ Firebase 초기화 성공');
  } catch (e) {
    print('❌ Firebase 초기화 실패: $e');
    print('⚠️ 오프라인 모드로 실행됩니다.');
    firebaseInitialized = false;
  }

  // Firebase 상태를 전역 변수로 저장
  _isFirebaseInitialized = firebaseInitialized;

  // 카메라 초기화는 나중에 필요할 때 하도록 변경
  try {
    print('🔄 카메라 초기화 시작...');
    cameras = await availableCameras();
    print('✅ 사용 가능한 카메라: ${cameras.length}개');
  } catch (e) {
    print('⚠️ 카메라 초기화 실패: $e');
    // 카메라 실패해도 앱은 계속 실행
    cameras = [];
  }

  // 알람 서비스 초기화 - Firebase가 성공했을 때만 시도
  try {
    print('🔄 알람 서비스 초기화 시작...');
    await BackgroundAlarmService.initialize(navigatorKey: navigatorKey);
    print('✅ 알람 서비스 초기화 성공');
    
    // 권한 요청은 별도 스레드에서 실행
    BackgroundAlarmService.requestPermissions().then((granted) {
      if (granted) {
        print('✅ 알람 권한 승인됨');
      } else {
        print('⚠️ 알람 권한 거부됨');
      }
    }).catchError((e) {
      print('⚠️ 알람 권한 요청 실패: $e');
    });
  } catch (e) {
    print('⚠️ 알람 서비스 초기화 실패: $e');
    print('⚠️ 알람 기능 없이 실행됩니다.');
    // 알람 서비스 실패해도 앱은 계속 실행
  }

  print('🚀 MyApp 실행 시작...');
  runApp(const MyApp());
  print('✅ MyApp 실행 완료');
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
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  String _initMessage = '앱을 초기화하는 중...';
  List<String> _logs = [];
  bool _showLogs = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 10) {
        _logs.removeAt(0); // 최대 10개 로그만 유지
      }
    });
    print(message); // 콘솔에도 출력
  }

  @override
  void initState() {
    super.initState();
    _addLog('AuthWrapper 초기화 시작');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _addLog('Firebase 연결 시도 중...');
    setState(() {
      _initMessage = 'Firebase 연결 중...';
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      _addLog('Firebase 연결 성공');
      
      setState(() {
        _initMessage = '사용자 인증 확인 중...';
      });
      _addLog('사용자 인증 확인 시작');
      
      await Future.delayed(const Duration(seconds: 1));
      _addLog('초기화 완료');
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _addLog('초기화 오류: $e');
      setState(() {
        _isInitialized = true; // 오류가 있어도 계속 진행
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFE4F3E1),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 상단에 로그 토글 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '초기화 중...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showLogs = !_showLogs;
                        });
                      },
                      icon: Icon(
                        _showLogs ? Icons.visibility_off : Icons.visibility,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                
                // 로그 표시 영역
                if (_showLogs) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _logs.map((log) => Text(
                          log,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // 메인 로딩 영역
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        _initMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          _addLog('사용자가 건너뛰기 선택');
                          setState(() {
                            _isInitialized = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('건너뛰기'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _getAuthStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFE4F3E1),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    '로그인 상태 확인 중...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('AuthWrapper 오류: ${snapshot.error}');
          // Firebase 오류가 있어도 AuthScreen으로 이동
          return const AuthScreen();
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }

  Stream<User?> _getAuthStream() {
    if (!_isFirebaseInitialized) {
      print('Firebase가 초기화되지 않음 - null 스트림 반환');
      return Stream.value(null);
    }
    
    try {
      return FirebaseAuth.instance.authStateChanges();
    } catch (e) {
      print('FirebaseAuth 스트림 오류: $e');
      // Firebase가 실패하면 null 스트림을 반환 (로그인 안된 상태로 처리)
      return Stream.value(null);
    }
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 로고
              Flexible(
                flex: 2,
                child: Column(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Image.asset(
                        'asset/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 150,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.green[300],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pets,
                              size: 50,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
              ),

              const SizedBox(height: 32),

              // 메뉴 버튼 영역
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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