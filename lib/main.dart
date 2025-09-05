import 'package:finalproject/exercise_screen.dart';
import 'package:finalproject/setting-screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'alarm_list_page.dart';
import 'daily_screen.dart';
import 'package:provider/provider.dart';
import 'exercise_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  runApp(
      ChangeNotifierProvider(
        create: (context) => ExerciseLog(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: _LoadingScreen(),
        ),
      ));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int dailyGoal = 3;  // 기본값
  int weeklyGoal = 5;  // 기본값

  String goalMessage = '';


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoalsAndCheck();
    });

  }

  Future<void> _loadGoalsAndCheck() async {
    final prefs = await SharedPreferences.getInstance();
    int loadedDailyGoal = prefs.getInt('dailyGoal') ?? 3;
    int loadedWeeklyGoal = prefs.getInt('weeklyGoal') ?? 5;

    setState(() {
      dailyGoal = loadedDailyGoal;
      weeklyGoal = loadedWeeklyGoal;
    });

    _checkGoals();
  }

  void _checkGoals() {
    final exerciseLog = Provider.of<ExerciseLog>(context, listen: false);
    int todayCount = exerciseLog.todayCount;
    int weeklyDays = exerciseLog.weeklyExerciseDays;

    String message;

    if (todayCount >= dailyGoal && weeklyDays >= weeklyGoal) {
      message = "오늘과 이번 주 목표를 모두 달성했어요! 정말 멋져요! 🎉";
    } else if (todayCount >= dailyGoal) {
      message = "오늘 목표를 달성했어요! 잘했어요! 👍";
    } else if (weeklyDays >= weeklyGoal) {
      message = "이번 주 목표를 달성했어요! 멋져요! 💪";
    } else {
      message = "오늘도 화이팅! 조금만 더 힘내요! 😊";
    }

    setState(() {
      goalMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4F3E1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 80.0,  // 상단여백
              ///여백 수정
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('asset/logo.png',
                  height: 200,
                  width: 300,
                ),
              ],
            ),

            // 목표 달성 메시지 박스 추가
            Container(
              width: 300,
              height: 60,
              margin: EdgeInsets.only(top: 20, bottom: 20),
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(color: Colors.black12),
              ),
              child: Center(
                child: Text(
                  goalMessage.isEmpty
                      ? '목표 데이터를 불러오는 중입니다...'
                      : goalMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // 텍스트 메시지 박스 (필요하면 삭제 가능)
            Container(
              width: 300,
              height: 100,
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(color: Colors.black12),
              ),
              child: Text('ooo님, 현재 [심각 단계]입니다. \n 오늘도 회복을 위한 '
                  '\n 작은 움직임을 함께 해봐요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 10.0),

            ///사이즈 박스 수정 여백 수정
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MenuButton(
                        icon: Icons.monitor_heart,
                        label: '측정',
                        color: Color(0xFFF1F3C9),
                        onTap: (){
                          print('측정 클릭됨!');
                        },
                      ),
                      _MenuButton(
                        icon: Icons.calendar_month,
                        label: '일지',
                        color: Color(0xFFD2F0DC),
                        onTap: (){
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

                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MenuButton(
                        icon: Icons.fitness_center,
                        label: '운동',
                        color: Color(0xFFF1F3C9),
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
                        color: Color(0xFFD2F0DC),
                        onTap: (){
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
                  ///수정 사항입니다(메뉴버튼 추가, 로고 이동), 버튼 위치 조정
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MenuButton(
                        icon: Icons.settings,
                        label: '설정',
                        color: Color(0xFFF1F3C9),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingScreen(),
                            ),
                          );
                        },
                      ),
                      // Image.asset('asset/sit.png',
                      //   width: 100.0,)
                    ],
                  ),
                  ///수정입니다 (수정 사항 끝)
                  ///거북이 위치 확인!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                  // SizedBox(height: 100,),
                  //  Row(
                  //    mainAxisAlignment: MainAxisAlignment.end,
                  //    children: [
                  //      Image.asset('asset/bottom.png',
                  //        width: 80.0,)
                  //    ],

                  ////////////////////////////////////////////////////////////////////////
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


///  메뉴 버튼
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
    super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 20.0,
        ),
        padding: EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,size: 30.0,),
            SizedBox(width: 12.0,),
            Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

////// 로딩 화면 //////
class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen({super.key});

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // 페이드 인 시작
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // 3초 뒤 메인 화면 이동
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE4F3E1),
              Color(0xFFD2F0DC),   // 아래쪾에 살짝 붉은빛 도는 색상
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: Duration(seconds: 2),
                curve: Curves.easeInOut,
                opacity: _opacity,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.lightGreenAccent.withOpacity(0.5),  /// 빛나는 색
                        blurRadius: 80.0,
                        spreadRadius: 30.0,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'asset/1.png',
                    width: 200,
                    height: 200,
                  ),
                ),
              ),

              SizedBox(height: 12.0),
              /// 하단 텍스트
              Padding(
                padding: EdgeInsets.only(bottom: 40.0),
                child: Text(
                  'Turtle neck',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5), // 반투명 흰색
                    fontSize: 20.0,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}
// class _SplashPage extends StatefulWidget {
//   const _SplashPage({super.key});
//
//   @override
//   State<_SplashPage> createState() => _SplashPageState();
// }
//
// class _SplashPageState extends State<_SplashPage> {
//   @override
//   void initState() {
//     super.initState();
//     Timer(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => HomeScreen()),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFFFDF8E8),
//       body: Center(
//         child: Lottie.asset(
//           'assets/dh.json',  // GIF를 변환한 Lottie 파일
//           width:300,
//           height: 300,
//           fit: BoxFit.contain,
//         ),
//       ),
//     );
//   }
// }