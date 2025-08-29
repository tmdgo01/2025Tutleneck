import 'package:finalproject/exercise_screen.dart';
import 'package:finalproject/setting-screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'alarm_list_page.dart';
import 'daily_screen.dart';
import 'package:provider/provider.dart';
import 'exercise_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  runApp(
      ChangeNotifierProvider(
        create: (context) => ExerciseLog(),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: HomeScreen(),
          ),
      ));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4F3E1),
      body: Column(
        children: [
          SizedBox(
            height: 50.0,  // 상단여백
            ///여백 수정
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('asset/logo.png',
                height: 250,
                width: 250,
              ),
            ],
          ),
          SizedBox(height: 10.0),  // 여백
          ///사이즈 박스 수정 여백 수정
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                Row(
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
                SizedBox(height: 30.0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MenuButton(
                      icon: Icons.fitness_center,
                      label: '운동',
                      color: Color(0xFFD2F0DC),
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
                      color: Color(0xFFF1F3C9),
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
                SizedBox(height: 30.0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MenuButton(
                      icon: Icons.settings,
                      label: '설정',
                      color: Color(0xFFD2F0DC),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Settingscreen(),
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
            Icon(icon,size: 30.0,),
            SizedBox(height: 10.0,),
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
