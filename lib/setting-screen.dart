import 'package:finalproject/exercise_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'exercise_screen.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _SettingsItem(
            icon: Icons.nightlight_round,
            title: '야간 알람 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _NightAlarmSettingScreen()),
              );
            },
          ),

          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.volume_up,
            title: '알람 사운드 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const _AlarmSoundSettingScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.bar_chart,
            title: '앱 사용 통계',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _AppUsageStatsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.flag,
            title: '운동 목표 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _GoalSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 재사용 가능한 설정 아이템 위젯
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}


/// 야간 알람 설정 ///
class _NightAlarmSettingScreen extends StatefulWidget {
  const _NightAlarmSettingScreen({Key? key}) : super(key: key);

  @override
  State<_NightAlarmSettingScreen> createState() => _NightAlarmSettingScreenState();
}

class _NightAlarmSettingScreenState extends State<_NightAlarmSettingScreen> {
  TimeOfDay _startTime = TimeOfDay(hour: 22, minute: 0); // 오후 10시
  TimeOfDay _endTime = TimeOfDay(hour: 7, minute: 0);    // 오전 7시

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const SizedBox(height: 10),
          const Text(
            "🔔 야간 알람 설정",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 시작 시간
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.nightlight_round),
            title: Text("시작 시간: ${_formatTime(_startTime)}"),
            trailing: ElevatedButton(
              onPressed: () => _selectTime(isStart: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2F0DC),
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text("변경"),
            ),

          ),
          const SizedBox(height: 12),

          // 종료 시간
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.wb_sunny),
            title: Text("종료 시간: ${_formatTime(_endTime)}"),
            trailing: ElevatedButton(
              onPressed: () => _selectTime(isStart: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2F0DC), // 연한 연녹색
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text("변경"),
            ),
          ),
            const SizedBox(height: 30),

          // 저장 버튼
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("설정 저장"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("야간 알람 시간대가 저장되었습니다.")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 시간 선택
  Future<void> _selectTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      initialEntryMode: TimePickerEntryMode.dial, // ✅ 시계 모양 유지
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFFE4F3E1), // ✅ 다이얼 배경색
              hourMinuteColor: Colors.white,           // 시/분 박스 배경
              hourMinuteTextColor: Colors.black87,     // 시/분 글자
              dialHandColor: Colors.green,             // 다이얼 포인터
              dialBackgroundColor: Colors.white,       // 다이얼 원 배경
              dialTextColor: Colors.black,             // 숫자 색
              entryModeIconColor: Colors.green,        // 왼쪽 하단 아이콘

              // ✅ AM/PM 버튼을 초록 배경 + 흰 글씨로
              dayPeriodColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.green; // 선택됨 → 초록 배경
                }
                return Colors.green.shade100; // 선택 안 됨 → 연한 초록
              }),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
                return Colors.white; // 항상 흰 글씨
              }),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide.none,
              ),
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  /// 시간 포맷 (오전/오후 HH:MM)
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "오전" : "오후";
    return "$period $hour:$minute";
  }
}

/////// 알람 사운드 설정 ///////
class _AlarmSoundSettingScreen extends StatefulWidget {
  const _AlarmSoundSettingScreen({super.key});

  @override
  State<_AlarmSoundSettingScreen> createState() => _AlarmSoundSettingScreenState();
}

class _AlarmSoundSettingScreenState extends State<_AlarmSoundSettingScreen> {
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
        title: const Text('알람 사운드 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('🔔 소리 알림 사용'),
              subtitle: const Text('알람 시 소리를 재생합니다.'),
              value: _soundEnabled,
              activeColor: Colors.green,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('📳 진동 알림 사용'),
              subtitle: const Text('알람 시 진동을 울립니다.'),
              value: _vibrationEnabled,
              activeColor: Colors.green,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 저장 처리 (ex. SharedPreferences)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알람 설정이 저장되었습니다.')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text("설정 저장"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}


///////// 앱 사용 통계 ////////
class _AppUsageStatsScreen extends StatelessWidget {
  _AppUsageStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final exerciseLog = Provider.of<ExerciseLog>(context);

    final today = DateTime.now();

    // 요일별 데이터 배열 (월=0, ..., 일=6)
    final List<int> weeklyData = List.filled(7, 0);

    // 최근 7일 운동 기록 가져오기
    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final count = exerciseLog.getExercisesForDay(day).length;

      // ✅ 올바른 요일 인덱스 계산
      int weekdayIndex = day.weekday - 1;  // 월=0, ..., 일=6
      weeklyData[weekdayIndex] += count;
    }

    // 동적 maxY 설정
    double maxY = weeklyData.reduce(max).toDouble();
    if (maxY < 6) maxY = 6;

    // 총 횟수
    final totalCount = weeklyData.reduce((a, b) => a + b);

    // 요일 라벨 고정 (월~일)
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 사용 통계'),
        backgroundColor: Colors.green[100],
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '최근 7일 운동 횟수: $totalCount회',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          // ✅ 요일 레이블 목록
                          const labels = ['월', '화', '수', '목', '금', '토', '일'];
                          int index = value.toInt();

                          // ✅ 현재 요일 (월=0, ..., 일=6)
                          int todayIndex = DateTime.now().weekday - 1;

                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }

                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 📍 요일 텍스트
                                Text(
                                  labels[index],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),

                                // 📍 오늘인 경우만 '오늘' 표시
                                if (index == todayIndex)
                                  const Text(
                                    '오늘',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyData[index].toDouble(),
                          color: Colors.green,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/////// 운동 목표 설정 ////////
class _GoalSettingsPage extends StatefulWidget {
  @override
  _GoalSettingsPageState createState() => _GoalSettingsPageState();
}

class _GoalSettingsPageState extends State<_GoalSettingsPage> {
  final _dailyGoalController = TextEditingController();
  final _weeklyGoalController = TextEditingController();

  int? _dailyGoal;
  int? _weeklyGoal;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyGoal = prefs.getInt('dailyGoal') ?? 3; // 기본값 3회
      _weeklyGoal = prefs.getInt('weeklyGoal') ?? 5; // 기본값 5일

      _dailyGoalController.text = _dailyGoal.toString();
      _weeklyGoalController.text = _weeklyGoal.toString();
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final daily = int.tryParse(_dailyGoalController.text);
    final weekly = int.tryParse(_weeklyGoalController.text);

    if (daily == null || weekly == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목표 값은 숫자여야 합니다!')),
      );
      return;
    }

    await prefs.setInt('dailyGoal', daily);
    await prefs.setInt('weeklyGoal', weekly);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('목표가 저장되었습니다!')),
    );

    setState(() {
      _dailyGoal = daily;
      _weeklyGoal = weekly;
    });
  }

  @override
  void dispose() {
    _dailyGoalController.dispose();
    _weeklyGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('목표 설정'),
        backgroundColor: Colors.green[100],
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _dailyGoalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '하루 운동 목표 횟수',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _weeklyGoalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '주간 운동 목표 일수',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 36),
            ElevatedButton(
              onPressed: _saveGoals,
              child: Text('목표 저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[300],
                foregroundColor: Colors.black87,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
