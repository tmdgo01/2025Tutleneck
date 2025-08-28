import 'package:flutter/material.dart';
import 'dart:math';
import 'alarm_data.dart';


class Alarm extends StatefulWidget {
  final Function(AlarmData)? onAlarmCreated;

  const Alarm({super.key, this.onAlarmCreated});

  @override
  State<Alarm> createState() => _AlarmState();
}

class _AlarmState extends State<Alarm> {

  // 라벨 목록
  final List<String> _labels = ['목', '어깨', '등'];
  String? _selectedLabel;

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

  // 알람 제목 (선택사항)
  String alarmLabel = '';

  // 저장 로딩 상태
  bool _isSaving = false;

  // 컨트롤러들
  late FixedExtentScrollController startHourController;
  late FixedExtentScrollController startMinuteController;
  late FixedExtentScrollController endHourController;
  late FixedExtentScrollController endMinuteController;

  // 고유 ID 생성
  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

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

      // 시작 시간 기본값으로 리셋 (오전 9:00)
      startHour = 9;
      startMinute = 0;

      // 종료 시간 기본값으로 리셋 (오후 6:00)
      endHour = 18;
      endMinute = 0;

      // 알람 제목 초기화
      alarmLabel = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('모든 설정이 초기화되었습니다.'),
        backgroundColor: Colors.orange[400],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // 설정 저장 함수 - AlarmData 객체 생성 및 전달
  Future<void> _saveSettings() async {
    // 유효성 검사
    if (!_hasActiveDay()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('운동 실행 할 요일을 선택해주세요'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_isValidTimeRange()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('시작 시간이 종료 시간보다 늦을 수 없습니다.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // AlarmData 객체 생성
      final newAlarm = AlarmData(
        id: _generateUniqueId(),
        activeDays: List.from(activeDays),
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        selectedInterval: selectedInterval,
        isAlarmEnabled: true, // 기본적으로 활성화
        createdAt: DateTime.now(),
        label: alarmLabel.trim().isEmpty ? null : alarmLabel.trim(),
      );

      // 콜백을 통해 부모 위젯에 알람 추가
      if (widget.onAlarmCreated != null) {
        widget.onAlarmCreated!(newAlarm);
      }

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('운동 알람이 저장되었습니다!'),
          backgroundColor: Colors.green[400],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      // 1초 후에 이전 페이지로 돌아가기
      await Future.delayed(Duration(seconds: 1));
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('알람 저장에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
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
      backgroundColor: Color(0xFFE4F3E1),
      appBar: AppBar(
        title: const Text('운동 알람 설정'),
        backgroundColor: Color(0xFFE4F3E1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            /// --- 1. 라벨 Dropdown ---
            const Text(
              '운동 부위',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLabel,
                  hint: const Text('부위를 선택하세요'),
                  items: _labels.map((label) {
                    return DropdownMenuItem<String>(
                      value: label,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLabel = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 알람 제목 입력 (새로 추가)
            Card(
              color:Color(0xFFE4F3E1),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '알람 제목 (선택사항)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => alarmLabel = value,
                      decoration: InputDecoration(
                        hintText: '예: 아침 운동, 점심 스트레칭',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '활성화된 요일',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 요일 선택 버튼들
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    return _buildDayButton(index);
                  }),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 운동 시간 설정 섹션
            const Text(
              '운동 시작 시간 및 종료 시간',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 시작 시간과 종료 시간을 나란히 배치
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // 시작 시간 영역
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '시작',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showTimePicker(context, true),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _formatTime(startHour, startMinute),
                                style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showTimePicker(context, false),
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
              ),
            ),

            const SizedBox(height: 24),

            // 운동 주기 설정 섹션
            const Text(
              '운동 주기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 드롭다운 컨테이너
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
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
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      '시간 간격으로 알람',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 하단 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetAllSettings,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                      ),
                    ),
                    child: Text(
                      '초기화',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      '저장',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 미리보기 카드 (설정이 있을 때만 표시)
            if (_hasActiveDay() && _isValidTimeRange()) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFFF8F9FA),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.preview, color: Color(0xFF4CAF50)),
                          SizedBox(width: 8),
                          Text(
                            '알람 미리보기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• 활성 요일: ${_getActiveDaysString()}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• 운동 시간: ${_formatTime(startHour, startMinute)} ~ ${_formatTime(endHour, endMinute)}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• 알람 주기: ${selectedInterval}시간 간격',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• 하루 예상 알람: ${((endHour * 60 + endMinute) - (startHour * 60 + startMinute)) ~/ (selectedInterval * 60) + 1}회',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
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
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? Color(0xFFFFFFD9) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Color(0xFFFFFFD9) : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            dayLabels[index],
            style: TextStyle(
              color: isActive ? Colors.black : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}