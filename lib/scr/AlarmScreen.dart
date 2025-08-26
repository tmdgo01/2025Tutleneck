import 'package:flutter/material.dart';

class Alarm extends StatefulWidget {
  const Alarm({super.key});

  @override
  State<Alarm> createState() => _AlarmState();
}

class _AlarmState extends State<Alarm> {
  // 요일별 활성화 상태를 관리하는 List
  List<bool> activeDays = [false, false, false, false, false, false, false];

  // 요일 라벨 (일, 월, 화, 수, 목, 금, 토)
  final List<String> dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  // 운동 주기 관련 변수
  int selectedInterval = 1; // 기본값: 1시간
  final List<int> intervalOptions = [1, 2, 3]; // 1, 2, 3시간 옵션


  // 시간 관련 변수
  int startHour = 9;
  int startMinute = 0;
  int endHour = 18;
  int endMinute = 0;


  // 알람 활성화 상태
  bool isAlarmEnabled = true;

  // 컨트롤러들
  late FixedExtentScrollController startHourController;
  late FixedExtentScrollController startMinuteController;
  late FixedExtentScrollController endHourController;
  late FixedExtentScrollController endMinuteController;

  @override
  void initState() {
    super.initState();
    // 컨트롤러 초기화
    startHourController = FixedExtentScrollController(initialItem: startHour);
    startMinuteController = FixedExtentScrollController(initialItem: startMinute);
    endHourController = FixedExtentScrollController(initialItem: endHour);
    endMinuteController = FixedExtentScrollController(initialItem: endMinute);
  }

  // 시간 포맷팅 함수
  String _formatTime(int hour, int minute) {
    String period = hour < 12 ? '오전' : '오후';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // ListWheelScrollView 시간 피커 표시 함수
  Future<void> _showTimePicker(BuildContext context, bool isStartTime) async {
    int tempHour = isStartTime ? startHour : endHour;
    int tempMinute = isStartTime ? startMinute : endMinute;

    FixedExtentScrollController hourController =
    FixedExtentScrollController(initialItem: tempHour);
    FixedExtentScrollController minuteController =
    FixedExtentScrollController(initialItem: tempMinute);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    isStartTime ? '시작 시간 설정' : '종료 시간 설정',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (isStartTime) {
                          startHour = tempHour;
                          startMinute = tempMinute;
                        } else {
                          endHour = tempHour;
                          endMinute = tempMinute;
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 시간 피커 휠
              Expanded(
                child: Row(
                  children: [
                    // 시간 휠
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: hourController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (int index) {
                          tempHour = index;
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 24,
                          builder: (context, index) {
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const Text(
                      ' : ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // 분 휠
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: minuteController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (int index) {
                          tempMinute = index;
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) {
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ).whenComplete(() {
      hourController.dispose();
      minuteController.dispose();
    });
  }


  // 모든 알람 설정 초기화 함수
  void _resetAllSettings() {
    setState(() {
      // 모든 요일 비활성화
      activeDays = [false, false, false, false, false, false, false];

      // 운동 주기 기본값으로 리셋
      selectedInterval = 1;

      // 시작 시간 기본값으로 리셋 (오전 7:00)
      startHour = 7;
      startMinute = 0;

      // 종료 시간 기본값으로 리셋 (오전 9:00)
      endHour = 9;
      endMinute = 0;
    });

    // 사용자에게 알림
    /// 삭제 가능 기능 (확인요)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('모든 알람 설정이 해제되었습니다.'),
        ///색상 선택해주세요!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        backgroundColor: Colors.red[400],
        ///!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    print('알람 설정 초기화 완료');
  }

  // 설정 저장 함수
  void _saveSettings() {
    // 유효성 검사
    if (!_hasActiveDay()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('운동 실행 할 요일을 선택해주세요'),
          ///색상 선택해주세요!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          backgroundColor: Colors.orange,
          ///!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_isValidTimeRange()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시작 시간이 종료 시간보다 늦을 수 없습니다.'),
          ///색상 선택해주세요!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          backgroundColor: Colors.orange,
          ///!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // TODO: SharedPreferences나 Firebase에 저장
    // await _saveToStorage();

    // 성공 메시지 표시
    ///삭제가능(확인요)!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('알람 저장되었습니다!'),
        ///색상 선택!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        backgroundColor: Colors.green[400],
        ///!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    print('알람 설정 저장 완료');
    print('활성 요일: ${_getActiveDaysString()}');
    print('운동 시간: ${_formatTime(startHour, startMinute)} ~ ${_formatTime(endHour, endMinute)}');
    print('알람 주기: ${selectedInterval}시간 간격');
  }

  // 활성화된 요일이 있는지 확인
  bool _hasActiveDay() {
    return activeDays.any((day) => day);
  }

  // 시간 범위 유효성 검사
  bool _isValidTimeRange() {
    int startTotal = startHour * 60 + startMinute;
    int endTotal = endHour * 60 + endMinute;
    return endTotal > startTotal;
  }

  // 활성화된 요일 문자열 반환 (디버깅용)
  String _getActiveDaysString() {
    List<String> activeDayNames = [];
    for (int i = 0; i < activeDays.length; i++) {
      if (activeDays[i]) {
        activeDayNames.add(dayLabels[i]);
      }
    }
    return activeDayNames.join(', ');
  }


  @override
  void dispose() {
    // 컨트롤러 해제
    startHourController.dispose();
    startMinuteController.dispose();
    endHourController.dispose();
    endMinuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Color(0xFFE4F3E1),
      appBar: AppBar(
        title: const Text('알람 설정'),
        backgroundColor:Color(0xFFE4F3E1),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Text(
              '활성화된 요일',
              style:
              ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
              TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // 요일 선택 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                return _buildDayButton(index);
              }),
            ),

            const SizedBox(height: 100),

            // 운동 시간 설정 섹션
            const Text(
              '운동 시작 시간 및 종료 시간',
              ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // 시작 시간과 종료 시간을 나란히 배치
            Row(
              children: [
                // 시작 시간 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '시작',
                        ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _showTimePicker(context,true);
                          // TODO: TimePicker 구현
                          print('시작 시간 선택');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child:Text(
                            _formatTime(startHour, startMinute),
                            style: TextStyle(
                              ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 종료 시간 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '종료',
                        ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _showTimePicker(context, false);
                          // TODO: TimePicker 구현
                          print('종료 시간 선택');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            _formatTime(endHour, endMinute),
                            style: TextStyle(
                              ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100),

            // 운동 주기 설정 섹션
            const Text(
              '운동 주기',
              ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height:30),

            // 드롭다운 컨테이너
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<int>(
                    value: selectedInterval,
                    underline: const SizedBox(), // 기본 밑줄 제거
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 40,
                      color: Colors.black,
                    ),
                    items: intervalOptions.map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          ' ${value} ',
                          style: const TextStyle(
                            ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedInterval = newValue;
                        });

                        // 디버깅용 - 실제 앱에서는 제거
                        print('운동 주기 변경: $newValue시간 간격');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                const Text(
                  '시간 간격으로 알람',
                  ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

              ],
            ), const SizedBox(height:50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed:_resetAllSettings,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    side: BorderSide(
                      ///색상 정하기!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                      color: Colors.red!,
                      ///!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                  child: Text('알람 해제',
                    ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _saveSettings,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    // side: BorderSide(
                    //   /// 색상 정하기!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    //   color:Colors.black,
                    //   ///!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    //   width: 2,
                    // ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                  child: Text('저장',
                    style: TextStyle(
                      ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),

    );
  }

  // 요일 버튼을 생성하는 헬퍼 메서드
  Widget _buildDayButton(int index) {
    final isActive = activeDays[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          activeDays[index] = !activeDays[index];
        });

        // 디버깅용 - 실제 앱에서는 제거
        print('${dayLabels[index]} 요일 ${isActive ? '비활성화' : '활성화'}');
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          ///색상 정하기!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          color: isActive
              ? Color(0xFFFFFFD9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Color(0xFFFFFFD9)
                : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            dayLabels[index],
            style: TextStyle(
              ///글꼴,색상,크기 동일하게!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
              color: isActive ? Colors.black  : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}