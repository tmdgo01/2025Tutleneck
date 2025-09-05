import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_exercise_service.dart'; // Firebase 서비스 import
import 'package:finalproject/posture_service.dart'; // PostureService 추가

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // PostureService 사용 (Firebase 직접 접근 대신)
  final PostureService _postureService = PostureService();

  // 자세 점수 관련
  double _postureScore = 0.0;
  bool _isLoadingScore = false;

  // 운동 기록 관련 (Firebase)
  Map<String, List<String>> _exerciseRecord = {};
  bool _isLoadingExercise = false;
  Set<String> _exerciseDates = {}; // 운동한 날짜들 (캘린더 마커용)

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadPostureScore(_selectedDay!);
    _loadExerciseRecord(_selectedDay!);
    _loadExerciseDates();
  }

  /// PostureService를 사용해서 해당 날짜의 자세 데이터 가져오기
  Future<void> _loadPostureScore(DateTime date) async {
    setState(() {
      _isLoadingScore = true;
    });

    try {
      // PostureService를 사용해서 사용자별 데이터 접근
      final data = await _postureService.getPostureData(date);

      if (data != null) {
        // 저장된 점수를 직접 사용 (PostureService에서 이미 계산된 점수)
        final scoreValue = data['score'];
        if (scoreValue != null && scoreValue is num) {
          _postureScore = scoreValue.toDouble();
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

  /// Firebase에서 해당 날짜의 운동 기록 가져오기
  Future<void> _loadExerciseRecord(DateTime date) async {
    setState(() {
      _isLoadingExercise = true;
    });

    try {
      final record = await FirebaseExerciseService.getCompletedExercises(date);
      _exerciseRecord = record;
    } catch (e) {
      debugPrint('운동 기록 로딩 실패: $e');
      _exerciseRecord = {};
    }

    setState(() {
      _isLoadingExercise = false;
    });
  }

  /// 운동한 날짜들 가져오기 (캘린더 마커용)
  Future<void> _loadExerciseDates() async {
    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final dates = await FirebaseExerciseService.getExerciseDates(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _exerciseDates = dates.toSet();
      });
    } catch (e) {
      debugPrint('운동 날짜 로딩 실패: $e');
    }
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
    final dateKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _exerciseDates.contains(dateKey);
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
        actions: [
          // 새로고침 버튼 추가
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              if (_selectedDay != null) {
                _loadPostureScore(_selectedDay!);
                _loadExerciseRecord(_selectedDay!);
                _loadExerciseDates();
              }
            },
            tooltip: '새로고침',
          ),
        ],
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
                  // 날짜 변경시 해당 날짜의 데이터 로드
                  _loadPostureScore(selectedDay);
                  _loadExerciseRecord(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadExerciseDates(); // 월 변경시 운동 날짜 다시 로드
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

                      // 자세 점수 박스 (PostureService 연동)
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
                              '자세 점수: ${_postureScore.toStringAsFixed(1)}점',
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

                  ////// Firebase 운동 기록 표시 부분 ////////
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
                        child: _buildFirebaseExerciseRecord(),
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

  /// Firebase 운동 기록 위젯 빌드
  Widget _buildFirebaseExerciseRecord() {
    if (_isLoadingExercise) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_exerciseRecord.isEmpty) {
      return const Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 8.0),
          Text(
            '선택된 날짜에 완료된 운동이 없습니다.',
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

    // 총 완료된 탭 수 계산
    int totalCompletedTabs = _exerciseRecord.length;
    int totalExercises = _exerciseRecord.values.expand((list) => list).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 완료 요약
        Row(
          children: [
            const Icon(
              Icons.fitness_center,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8.0),
            Text(
              '${totalCompletedTabs}개 탭 완료 (총 ${totalExercises}개 운동)',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16.0),

        // 탭별 운동 목록
        ..._exerciseRecord.entries.map((entry) {
          final tabName = entry.key;
          final exercises = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 탭 이름
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        tabName,
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '${exercises.length}개 운동 완료',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8.0),

                // 운동 목록
                ...exercises.map((exerciseName) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 4.0,
                          height: 4.0,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            exerciseName,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
                  totalCompletedTabs >= 3
                      ? '완벽해요! 모든 운동 카테고리를 완료하셨네요!'
                      : totalCompletedTabs >= 2
                      ? '훌륭해요! 꾸준한 운동으로 목과 어깨 건강을 지키고 계시네요!'
                      : '좋은 시작이에요! 다른 운동도 도전해보세요!',
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