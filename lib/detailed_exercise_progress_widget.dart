import 'package:flutter/material.dart';
import 'firebase_exercise_service.dart';

class DetailedExerciseProgressWidget extends StatefulWidget {
  final DateTime date;

  const DetailedExerciseProgressWidget({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  State<DetailedExerciseProgressWidget> createState() => _DetailedExerciseProgressWidgetState();
}

class _DetailedExerciseProgressWidgetState extends State<DetailedExerciseProgressWidget> {
  Map<String, Map<String, dynamic>> tabProgress = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetailedProgress();
  }

  @override
  void didUpdateWidget(DetailedExerciseProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadDetailedProgress();
    }
  }

  Future<void> _loadDetailedProgress() async {
    setState(() {
      isLoading = true;
    });

    try {
      final progress = await FirebaseExerciseService.getDetailedTabProgress(widget.date);

      if (mounted) {
        setState(() {
          tabProgress = progress;
          isLoading = false;
        });
      }
    } catch (e) {
      print('상세 운동 진행 상황 로딩 실패: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        child: Container(
          height: 200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // 운동 기록이 없는 경우
    if (tabProgress.isEmpty || !tabProgress.values.any((tab) => tab['completedExercises'] > 0)) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                '이 날은 운동 기록이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '목과 어깨 운동을 시작해보세요!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Icon(
                  Icons.analytics,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '상세 운동 기록',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(widget.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 전체 통계 요약
            _buildOverallStats(),
            const SizedBox(height: 16),

            // 탭별 상세 진행 상황
            ...tabProgress.entries.map((entry) {
              final tabName = entry.key;
              final tabData = entry.value;
              return _buildTabProgressCard(tabName, tabData);
            }).toList(),
          ],
        ),
      ),
    );
  }

  // 전체 통계 요약
  Widget _buildOverallStats() {
    int totalCompletedTabs = 0;
    int totalExerciseCompletions = 0;
    int totalPossibleTabs = tabProgress.length;

    for (final tabData in tabProgress.values) {
      if (tabData['isCompleted'] == true) {
        totalCompletedTabs++;
      }
      final exerciseProgress = tabData['exerciseProgress'] as Map<String, int>;
      totalExerciseCompletions += exerciseProgress.values.fold(0, (sum, count) => sum + count);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            '완료한 프로그램',
            '$totalCompletedTabs/$totalPossibleTabs',
            Icons.check_circle,
            Colors.green,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          _buildStatColumn(
            '총 운동 횟수',
            '${totalExerciseCompletions}회',
            Icons.fitness_center,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  // 통계 컬럼 위젯
  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 탭별 진행 상황 카드
  Widget _buildTabProgressCard(String tabName, Map<String, dynamic> tabData) {
    final tabCompletions = tabData['tabCompletions'] as int;
    final isCompleted = tabData['isCompleted'] as bool;
    final exerciseProgress = tabData['exerciseProgress'] as Map<String, int>;
    final exercises = tabData['exercises'] as List<String>;
    final completedExercises = tabData['completedExercises'] as int;
    final totalExercises = tabData['totalExercises'] as int;

    // 탭에 운동 기록이 하나도 없으면 표시하지 않음
    if (completedExercises == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green[300]! : Colors.orange[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 탭 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.schedule,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tabName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? '${tabCompletions}회 완료' : '진행중',
                    style: TextStyle(
                      color: isCompleted ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 진행률 바
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: completedExercises / totalExercises,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completedExercises/$totalExercises',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 운동별 완료 횟수
            const Text(
              '운동별 완료 횟수',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            ...exercises.map((exerciseName) {
              final count = exerciseProgress[exerciseName] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: count > 0 ? Colors.blue[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: count > 0 ? Colors.blue[200]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: count > 0 ? Colors.blue : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: TextStyle(
                          fontSize: 14,
                          color: count > 0 ? Colors.black87 : Colors.grey[600],
                          fontWeight: count > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${count}회',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),

            if (isCompleted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tabCompletions > 1
                            ? '${tabCompletions}번이나 완주하셨네요! 정말 대단해요!'
                            : '모든 운동을 완료하셨어요! 훌륭합니다!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }
}