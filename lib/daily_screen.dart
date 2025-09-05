import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'exercise_screen.dart'; // ExerciseLog import

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Firebase 연동
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 자세 점수 관련
  double _postureScore = 0.0;
  bool _isLoadingScore = false;

  // ExerciseLog 직접 접근을 위한 변수
  ExerciseLog? _exerciseLog;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadPostureScore(_selectedDay!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider가 있다면 가져오고, 없다면 새로 생성
    try {
      _exerciseLog = Provider.of<ExerciseLog>(context, listen: false);
    } catch (e) {
      // Provider가 없는 경우 새로 생성 (임시 방법)
      _exerciseLog = ExerciseLog();
    }
  }

  /// Firebase에서 해당 날짜의 자세 데이터 가져오기
  Future<void> _loadPostureScore(DateTime date) async {
    setState(() {
      _isLoadingScore = true;
    });

    try {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('posture_daily')
          .doc(dateKey)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final stats = data['stats'] as Map<String, dynamic>;
        final totalFrames = data['totalFrames'] as int;

        if (totalFrames > 0) {
          final normalCount = stats['정상'] ?? 0;
          _postureScore = (normalCount / totalFrames * 100).toDouble();
        } else {
          _postureScore = 0.0;
        }
      } else {
        _postureScore = 0.0; // 데이터 없음
      }
    } catch (e) {
      debugPrint('자세 점수 로딩 실패: $e');
      _postureScore = 0.0;
    }

    setState(() {
      _isLoadingScore = false;
    });
  }

  /// 점수에 따른 색상 반환
  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green; // 좋은 점수
    } else if (score >= 60) {
      return Colors.orange; // 보통 점수
    } else if (score > 0) {
      return Colors.red; // 낮은 점수
    } else {
      return Colors.grey; // 데이터 없음
    }
  }

  /// 점수에 따른 메시지 반환
  String _getScoreMessage(double score) {
    if (score >= 90) {
      return '완벽!';
    } else if (score >= 80) {
      return '좋음!';
    } else if (score >= 60) {
      return '보통';
    } else if (score > 0) {
      return '주의';
    } else {
      return '기록없음';
    }
  }

  /// 상세 메시지 반환
  String _getDetailedMessage(double score) {
    if (score >= 90) {
      return '정말 훌륭한 자세를 유지하고 계시네요! 계속해서 바른 자세를 유지해보세요.';
    } else if (score >= 80) {
      return '좋은 자세예요! 조금 더 신경쓰시면 완벽한 자세를 유지할 수 있어요.';
    } else if (score >= 60) {
      return '보통 수준의 자세예요. 조금 더 바른 자세에 신경써주세요.';
    } else if (score > 0) {
      return '자세 개선이 필요해요. 목과 어깨를 바르게 펴고 앉아주세요.';
    } else {
      return '아직 측정된 데이터가 없습니다.';
    }
  }

  /// 운동 기록이 있는 날짜인지 확인
  bool _hasExerciseRecord(DateTime day) {
    if (_exerciseLog == null) return false;
    final exercises = _exerciseLog!.getExercisesForDay(day);
    return exercises.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final defaultBoxDecoration = BoxDecoration(
      border: Border.all(
        color: Colors.grey[200]!,
        width: 1.0,
      ),
    );

    final defaultTextStyle = TextStyle(
      color: Colors.grey[600],
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          '일지',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TableCalendar(
                locale: 'ko_KR',
                focusedDay: _focusedDay,
                firstDay: DateTime(2000),
                lastDay: DateTime(3000),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  // 날짜 변경시 해당 날짜의 자세 점수 로드
                  _loadPostureScore(selectedDay);
                },

                ///// 헤더 스타일 /////
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                ///// 요일 스타일 /////
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                    color: Colors.black,
                    height: 1.0,
                  ),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    // 일요일 빨간색 표시
                    if (day.weekday == DateTime.sunday) {
                      return Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  // 운동 기록이 있는 날짜에 마커 표시
                  markerBuilder: (context, day, events) {
                    if (_hasExerciseRecord(day)) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          width: 6.0,
                          height: 6.0,
                        ),
                      );
                    }
                    return null;
                  },
                ),

                ///// 캘린더 스타일 /////
                calendarStyle: CalendarStyle(
                  isTodayHighlighted: true,
                  defaultDecoration: defaultBoxDecoration,
                  weekendDecoration: defaultBoxDecoration,
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent[100],
                  ),
                  todayDecoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black12,
                  ),
                  outsideDecoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.transparent,
                  ),
                  defaultTextStyle: defaultTextStyle,
                  weekendTextStyle: defaultTextStyle,
                  selectedTextStyle: defaultTextStyle.copyWith(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20.0),

              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 타임랩스 박스
                      Expanded(
                        child: Container(
                          height: 70.0,
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0E8D9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '타임랩스',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),

                      // 자세 점수 박스 (Firebase 연동)
                      Container(
                        width: 120.0,
                        height: 70.0,
                        decoration: BoxDecoration(
                          color: _getScoreColor(_postureScore),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: _isLoadingScore
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _postureScore > 0
                                  ? '${_postureScore.toStringAsFixed(0)}점'
                                  : '기록없음',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _postureScore > 0 ? 20.0 : 14.0,
                                color: Colors.white,
                              ),
                            ),
                            if (_postureScore > 0)
                              Text(
                                _getScoreMessage(_postureScore),
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white70,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10.0),
                  // 선으로 구분
                  const Divider(
                    color: Colors.green, // 선 색상
                    thickness: 3.0, // 선 두께
                    indent: 0.0, // 왼쪽 여백
                    endIndent: 0.0, // 오른쪽 여백
                  ),

                  ////// 자세 데이터 표시 부분 ////////
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 12.0,
                        ),
                        child: Text(
                          '오늘 자세 분석 결과',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // 자세 분석 결과 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(top: 3.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 4.0,
                              color: Colors.black12,
                            ),
                          ],
                        ),
                        child: _postureScore > 0
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 점수 표시
                            Row(
                              children: [
                                Icon(
                                  Icons.accessibility_new,
                                  color: _getScoreColor(_postureScore),
                                  size: 24,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  '자세 점수: ${_postureScore.toStringAsFixed(0)}점',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(_postureScore),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12.0),

                            // 자세 상태 메시지
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: _getScoreColor(_postureScore).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _postureScore >= 80
                                        ? Icons.sentiment_very_satisfied
                                        : _postureScore >= 60
                                        ? Icons.sentiment_neutral
                                        : Icons.sentiment_dissatisfied,
                                    color: _getScoreColor(_postureScore),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      _getDetailedMessage(_postureScore),
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8.0),

                            // 추가 정보
                            Text(
                              '정상 자세 유지 비율: ${_postureScore.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                            : const Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                              size: 48,
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              '선택된 날짜에 자세 측정 기록이 없습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              'PosturePal로 자세를 측정해보세요!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20.0),

                  ////// 운동 기록 표시 부분 ////////
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 12.0,
                        ),
                        child: Text(
                          '운동 기록',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // 운동 기록 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(top: 3.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 4.0,
                              color: Colors.black12,
                            ),
                          ],
                        ),
                        child: _buildExerciseRecord(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 운동 기록 위젯 빌드
  Widget _buildExerciseRecord() {
    if (_selectedDay == null || _exerciseLog == null) {
      return const Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 8.0),
          Text(
            '운동 기록을 불러올 수 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    final exercises = _exerciseLog!.getExercisesForDay(_selectedDay!);

    if (exercises.isEmpty) {
      return const Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 8.0),
          Text(
            '선택된 날짜에 운동 기록이 없습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            '목과 어깨 운동을 시작해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    // 운동 횟수 계산 (중복 허용)
    final exerciseCount = <String, int>{};
    for (final exercise in exercises) {
      exerciseCount[exercise] = (exerciseCount[exercise] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 운동 횟수 요약
        Row(
          children: [
            const Icon(
              Icons.fitness_center,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8.0),
            Text(
              '총 ${exercises.length}회 운동 완료',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 운동 목록
        ...exerciseCount.entries.map((entry) {
          final exerciseName = entry.key;
          final count = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    exerciseName,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (count > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      '${count}회',
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 12.0),

        // 격려 메시지
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.sentiment_very_satisfied,
                color: Colors.green,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  exercises.length >= 5
                      ? '훌륭해요! 꾸준한 운동으로 목과 어깨 건강을 지키고 계시네요!'
                      : exercises.length >= 3
                      ? '좋아요! 꾸준히 운동하시는 모습이 멋져요!'
                      : '좋은 시작이에요! 조금씩 운동량을 늘려보세요!',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}