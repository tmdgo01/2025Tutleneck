import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'exercise_screen.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
      backgroundColor: Color(0xFFE4F3E1),
      appBar: AppBar(
        backgroundColor: Color(0xFFE4F3E1),
        elevation: 0,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
        title: Text('일지',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
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
              },

              ///// 헤더 스타일 /////
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                ),
              ),

              ///// 요일 스타일 /////
              daysOfWeekStyle: DaysOfWeekStyle(
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
                    if(day.weekday == DateTime.sunday) {
                      return Center(
                        child: Text('${day.day}',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,),
                        ),
                      );
                    }
                    return null;
                  }
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
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black12,
                ),
                outsideDecoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.transparent),
                defaultTextStyle: defaultTextStyle,
                weekendTextStyle: defaultTextStyle,
                selectedTextStyle: defaultTextStyle.copyWith(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 20.0),

            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 타임랩스 박스
                    Expanded(
                      child: Container(
                        height: 70.0,
                        margin: EdgeInsets.only(right: 8.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFD0E8D9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
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

                        // 점수 박스
                        Container(
                          width: 120.0,
                          height: 70.0,
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '50점!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                  ],
                ),

                SizedBox(height: 10.0),
                // 선으로 구분
                Divider(
                  color: Colors.green,    // 선 색상
                  thickness: 3.0,    // 선 두께
                  indent: 0.0,     // 왼쪽 여백
                  endIndent: 0.0,  // 오른쪽 여백
                ),


                ////// 날짜 선택 후 운동 목록 표시하는 부분 ////////
                SingleChildScrollView(
                  child: Consumer<ExerciseLog>(
                    builder: (context, exerciseLog, child) {
                      List<String> exercisesForSelectedDay =
                      exerciseLog.getExercisesForDay(_selectedDay ?? DateTime.now());

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 12.0,
                              ),
                            child: Text('오늘 운동 완료',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if(exercisesForSelectedDay.isNotEmpty)
                            Container(
                              width: double.infinity,   // 화면 크기 가로에 맞게
                              padding: EdgeInsets.all(16.0),
                              margin: EdgeInsets.only(top: 3.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.0),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Colors.black12,
                                  ),
                                ],
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                  exercisesForSelectedDay.map((e) {
                                    return Row(
                                      children: [
                                        //// 운동 아이콘 추가 ////
                                        Image.asset(
                                          'asset/1.png',
                                          width: 30.0,
                                          height: 30.0,
                                        ),

                                        Text(
                                          e,
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList()
                              ),
                            ),

                          if(exercisesForSelectedDay.isEmpty)
                            Container(
                              width: double.infinity,   // 화면 크기 가로에 맞게
                              padding: EdgeInsets.all(16.0), // padding 속성 추가
                              margin: EdgeInsets.only(top: 10.0), // 위쪽 간격
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Colors.black12,
                                  ),
                                ],
                              ),
                              child: Text(
                                '선택된 날짜에 운동 기록이 없습니다.',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
