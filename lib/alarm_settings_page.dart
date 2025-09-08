import 'package:flutter/material.dart';
import 'alarm_data.dart';

class AlarmSettingsPage extends StatefulWidget {
  final AlarmData? existingAlarm; // 수정용 기존 알람
  final Function(AlarmData)? onAlarmCreated; // 콜백 (사용 안 함)

  const AlarmSettingsPage({
    super.key,
    this.existingAlarm,
    this.onAlarmCreated,
  });

  @override
  State<AlarmSettingsPage> createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  late TextEditingController _labelController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _selectedInterval;
  late List<bool> _activeDays;

  final List<String> _dayLabels = ['일', '월', '화', '수', '목', '금', '토'];
  final List<int> _intervalOptions = [1, 2, 3];

  @override
  void initState() {
    super.initState();

    if (widget.existingAlarm != null) {
      // 기존 알람 수정
      final alarm = widget.existingAlarm!;
      _labelController = TextEditingController(text: alarm.label ?? '');
      _startTime = TimeOfDay(hour: alarm.startHour, minute: alarm.startMinute);
      _endTime = TimeOfDay(hour: alarm.endHour, minute: alarm.endMinute);

      // 기존 간격이 현재 옵션에 없으면 기본값으로 설정
      if (_intervalOptions.contains(alarm.selectedInterval)) {
        _selectedInterval = alarm.selectedInterval;
      } else {
        _selectedInterval = 2; // 기본값 2시간
        print('기존 알람의 간격(${alarm.selectedInterval}시간)이 현재 옵션에 없어 2시간으로 변경됩니다.');
      }

      _activeDays = List.from(alarm.activeDays);
    } else {
      // 새 알람 생성
      _labelController = TextEditingController(text: '운동 알람');
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 18, minute: 0);
      _selectedInterval = 2;
      _activeDays = [false, true, true, true, true, true, false]; // 평일 기본
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  // 하루 알람 횟수 계산 메서드
  int _calculateDailyAlarmCount() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final totalMinutes = endMinutes - startMinutes;
    final intervalMinutes = _selectedInterval * 60;

    if (totalMinutes <= 0 || intervalMinutes <= 0) return 0;

    // 시작 시간부터 간격마다 울리는 횟수 계산
    return (totalMinutes / intervalMinutes).floor() + 1;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    String period = time.hour < 12 ? '오전' : '오후';
    int displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // 시작 시간이 종료 시간보다 늦으면 종료 시간 조정
          if (_startTime.hour > _endTime.hour ||
              (_startTime.hour == _endTime.hour && _startTime.minute >= _endTime.minute)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 4) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
          // 종료 시간이 시작 시간보다 이르면 시작 시간 조정
          if (_endTime.hour < _startTime.hour ||
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _startTime = TimeOfDay(
              hour: (_endTime.hour - 1 + 24) % 24,
              minute: _endTime.minute,
            );
          }
        }
      });
    }
  }

  void _saveAlarm() {
    // 유효성 검사
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알람 제목을 입력해주세요')),
      );
      return;
    }

    if (!_activeDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 하나의 요일을 선택해주세요')),
      );
      return;
    }

    // 알람 데이터 생성
    final alarmData = AlarmData(
      id: widget.existingAlarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      activeDays: _activeDays,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      selectedInterval: _selectedInterval,
      isAlarmEnabled: widget.existingAlarm?.isAlarmEnabled ?? true,
      createdAt: widget.existingAlarm?.createdAt ?? DateTime.now(),
      label: _labelController.text.trim(),
    );

    // 결과 반환
    Navigator.of(context).pop(alarmData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        title: Text(widget.existingAlarm != null ? '알람 수정' : '새 알람'),
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text(
              '저장',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 알람 제목
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '알람 제목',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        hintText: '예: 운동 시간',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 시간 설정
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '시간 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(context, true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('시작 시간', style: TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimeOfDay(_startTime),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('~', style: TextStyle(fontSize: 20)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(context, false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text('종료 시간', style: TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimeOfDay(_endTime),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 간격 설정 (드롭다운)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '알람 간격',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedInterval,
                          isExpanded: true,
                          items: _intervalOptions.map((interval) {
                            return DropdownMenuItem<int>(
                              value: interval,
                              child: Text(
                                '${interval}시간 간격',
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedInterval = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '하루 총 ${_calculateDailyAlarmCount()}회 알림',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 요일 설정
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '반복 요일',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (index) {
                        final isSelected = _activeDays[index];
                        return GestureDetector(
                          onTap: () => setState(() => _activeDays[index] = !_activeDays[index]),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[200],
                            ),
                            child: Center(
                              child: Text(
                                _dayLabels[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 미리보기 (흰색 배경)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '미리보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _labelController.text.isNotEmpty ? _labelController.text : "운동 알람",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTimeOfDay(_startTime)} ~ ${_formatTimeOfDay(_endTime)}',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF4CAF50)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedInterval}시간 간격 • 하루 ${_calculateDailyAlarmCount()}회',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeDays.asMap().entries
                          .where((entry) => entry.value)
                          .map((entry) => _dayLabels[entry.key])
                          .join(', '),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}