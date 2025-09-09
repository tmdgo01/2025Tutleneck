import 'package:finalproject/exercise_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finalproject/posture_service.dart'; // PostureService 추가
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finalproject/auth_screen.dart';

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
            icon: Icons.bar_chart,
            title: '자세 측정 통계',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _PostureStatsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _SettingsItem(
            icon: Icons.flag,
            title: '자세 목표 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _PostureGoalSettingsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 🔴 로그아웃 버튼
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                                (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        '확인',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: const [
                  Icon(Icons.logout, size: 28, color: Colors.white),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
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


class _ExerciseStatsScreen extends StatefulWidget {
  const _ExerciseStatsScreen({super.key});

  @override
  State<_ExerciseStatsScreen> createState() => _ExerciseStatsScreenState();
}

class _ExerciseStatsScreenState extends State<_ExerciseStatsScreen> {
  @override
  Widget build(BuildContext context) {
    final exerciseLog = Provider.of<ExerciseLog>(context);
    final today = DateTime.now();

    // 최근 7일간의 운동 데이터 수집
    final List<int> weeklyData = [];
    final List<String> dateLabels = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final count = exerciseLog.getExercisesForDay(date).length;
      weeklyData.add(count);

      // 날짜 라벨 생성 (월/일)
      dateLabels.add('${date.month}/${date.day}');
    }

    // 통계 계산
    final totalCount = weeklyData.reduce((a, b) => a + b);
    final maxCount = weeklyData.isEmpty ? 0 : weeklyData.reduce(max);
    final avgCount = totalCount > 0 ? (totalCount / 7).toStringAsFixed(1) : '0.0';

    // 차트 최대값 설정
    final chartMaxY = maxCount < 5 ? 5.0 : (maxCount + 1).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 통계'),
        backgroundColor: Colors.green[100],
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주간 통계 요약
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '이번 주 총 운동',
                    '$totalCount회',
                    Colors.blue,
                    Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '일일 평균',
                    '${avgCount}회',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 차트 제목
            const Text(
              '최근 7일 운동 횟수',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 운동 횟수 차트
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = today.subtract(Duration(days: 6 - groupIndex));
                        final count = weeklyData[groupIndex];
                        final isToday = date.day == today.day &&
                            date.month == today.month;

                        return BarTooltipItem(
                          '${isToday ? "오늘" : "${date.month}/${date.day}"}\n${count}회 운동',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < 7) {
                            final date = today.subtract(Duration(days: 6 - index));
                            final isToday = date.day == today.day &&
                                date.month == today.month;

                            // 요일 표시
                            const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                            final weekdayName = weekdays[date.weekday - 1];

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  weekdayName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                if (isToday)
                                  const Text(
                                    '오늘',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red
                                    ),
                                  ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    final count = weeklyData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: count > 0 ? Colors.blue : Colors.grey[300]!,
                          width: 24,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: chartMaxY,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 오늘의 운동 목록
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '오늘의 운동 기록 (${weeklyData.last}회)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...exerciseLog.getExercisesForDay(today).map((exerciseName) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exerciseName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (weeklyData.last == 0)
                    const Text(
                      '아직 운동 기록이 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


///////// 자세 측정 통계 (기존) ////////
class _PostureStatsScreen extends StatefulWidget {
  const _PostureStatsScreen({super.key});

  @override
  State<_PostureStatsScreen> createState() => _PostureStatsScreenState();
}

class _PostureStatsScreenState extends State<_PostureStatsScreen> {
  final PostureService _postureService = PostureService();
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = true;
  double _weeklyAverage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWeeklyStats();
  }

  Future<void> _loadWeeklyStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final today = DateTime.now();
      final weekData = <Map<String, dynamic>>[];

      // 최근 7일간의 데이터 가져오기
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final data = await _postureService.getPostureData(date);

        weekData.add({
          'date': date,
          'score': data?['score']?.toDouble() ?? 0.0,
          'totalFrames': data?['totalFrames'] ?? 0,
          'stats': data?['stats'] ?? {"정상": 0, "위험": 0, "심각": 0},
        });
      }

      // 주간 평균 계산
      final validScores = weekData.where((data) => data['score'] > 0).map((data) => data['score'] as double);
      final average = validScores.isNotEmpty ? validScores.reduce((a, b) => a + b) / validScores.length : 0.0;

      setState(() {
        _weeklyData = weekData;
        _weeklyAverage = average;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('주간 통계 로딩 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('자세 측정 통계'),
          backgroundColor: Colors.green[100],
          foregroundColor: Colors.black87,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    // 차트 데이터 준비
    final chartData = _weeklyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data['score'].toDouble(),
            color: data['score'] >= 80
                ? Colors.green
                : data['score'] >= 60
                ? Colors.orange
                : data['score'] > 0
                ? Colors.red
                : Colors.grey,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('자세 측정 통계'),
        backgroundColor: Colors.green[100],
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeeklyStats,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주간 평균 점수
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '주간 평균 자세 점수',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_weeklyAverage.toStringAsFixed(1)}점',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _weeklyAverage >= 80
                          ? Colors.green
                          : _weeklyAverage >= 60
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 차트 제목
            const Text(
              '최근 7일 자세 점수 추이',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 차트
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = _weeklyData[groupIndex];
                        final date = data['date'] as DateTime;
                        final score = data['score'] as double;

                        return BarTooltipItem(
                          '${date.month}/${date.day}\n${score.toStringAsFixed(1)}점',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _weeklyData.length) {
                            final date = _weeklyData[index]['date'] as DateTime;
                            final today = DateTime.now();

                            // 요일 이름
                            const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
                            final weekdayName = weekdays[date.weekday - 1];

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  weekdayName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                if (date.day == today.day && date.month == today.month)
                                  const Text(
                                    '오늘',
                                    style: TextStyle(fontSize: 10, color: Colors.red),
                                  ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: chartData,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 점수 범례
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('우수 (80점 이상)', Colors.green),
                _buildLegendItem('보통 (60-79점)', Colors.orange),
                _buildLegendItem('주의 (60점 미만)', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}


/////// 자세 목표 설정 (수정됨) ////////
class _PostureGoalSettingsPage extends StatefulWidget {
  @override
  _PostureGoalSettingsPageState createState() => _PostureGoalSettingsPageState();
}

class _PostureGoalSettingsPageState extends State<_PostureGoalSettingsPage> {
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
      _dailyGoal = prefs.getInt('postureTargetScore') ?? 80; // 기본값 80점
      _weeklyGoal = prefs.getInt('weeklyMeasurementDays') ?? 5; // 기본값 주 5일

      _dailyGoalController.text = _dailyGoal.toString();
      _weeklyGoalController.text = _weeklyGoal.toString();
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyTarget = int.tryParse(_dailyGoalController.text);
    final weeklyDays = int.tryParse(_weeklyGoalController.text);

    if (dailyTarget == null || weeklyDays == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 값은 숫자여야 합니다!')),
      );
      return;
    }

    if (dailyTarget < 0 || dailyTarget > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자세 점수는 0-100 사이여야 합니다!')),
      );
      return;
    }

    if (weeklyDays < 1 || weeklyDays > 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주간 측정 일수는 1-7 사이여야 합니다!')),
      );
      return;
    }

    await prefs.setInt('postureTargetScore', dailyTarget);
    await prefs.setInt('weeklyMeasurementDays', weeklyDays);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('자세 목표가 저장되었습니다!')),
    );

    setState(() {
      _dailyGoal = dailyTarget;
      _weeklyGoal = weeklyDays;
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
        title: const Text('자세 목표 설정'),
        backgroundColor: Colors.green[100],
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 일일 자세 점수 목표',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dailyGoalController,
                keyboardType: TextInputType.number,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                decoration: const InputDecoration(
                  labelText: '목표 점수 (0-100점)',
                  border: OutlineInputBorder(),
                  suffixText: '점',
                  helperText: '하루 동안 달성하고 싶은 자세 점수를 설정하세요',
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                '📅 주간 측정 목표',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weeklyGoalController,
                keyboardType: TextInputType.number,
                scrollPadding: const EdgeInsets.only(bottom: 100),
                decoration: const InputDecoration(
                  labelText: '주간 측정 일수 (1-7일)',
                  border: OutlineInputBorder(),
                  suffixText: '일',
                  helperText: '일주일에 몇 일 자세를 측정할지 설정하세요',
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveGoals,
                  icon: const Icon(Icons.save),
                  label: const Text('목표 저장', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 현재 목표 표시
              if (_dailyGoal != null && _weeklyGoal != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎯 현재 설정된 목표',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('• 일일 자세 점수 목표: ${_dailyGoal}점'),
                      Text('• 주간 측정 일수 목표: 주 ${_weeklyGoal}일'),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              // 로그아웃 버튼
            ],
          ),
        ),
      ),
    );
  }
}