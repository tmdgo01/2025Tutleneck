import 'package:flutter/material.dart';
import 'dart:math';
import 'alarm_data.dart'; // lib 폴더 직접 참조

class AlarmSettingsPage extends StatefulWidget {
  final Function(AlarmData)? onAlarmCreated;

  const AlarmSettingsPage({super.key, this.onAlarmCreated});

  @override
  State<AlarmSettingsPage> createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  final List<String> _labels = ['목', '어깨', '등'];
  String? _selectedLabel;
  List<bool> activeDays = List.generate(7, (_) => false);
  final List<String> dayLabels = ['일','월','화','수','목','금','토'];
  int selectedInterval = 1;
  final List<int> intervalOptions = [1,2,3];
  int startHour = 9;
  int startMinute = 0;
  int endHour = 18;
  int endMinute = 0;
  String alarmLabel = '';
  bool _isSaving = false;

  String _generateUniqueId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
          Random().nextInt(1000).toString();

  bool _hasActiveDay() => activeDays.any((d) => d);
  bool _isValidTimeRange() => (endHour * 60 + endMinute) > (startHour * 60 + startMinute);

  String _formatTime(int hour, int minute) {
    String period = hour < 12 ? '오전' : '오후';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')}';
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                  Text(
                    isStartTime ? '시작 시간 설정' : '종료 시간 설정',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                    child: const Text('완료', style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: hourController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (int index) => tempHour = index,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 24,
                          builder: (context, index) => Container(
                            alignment: Alignment.center,
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(' : ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: minuteController,
                        itemExtent: 50,
                        perspective: 0.005,
                        diameterRatio: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (int index) => tempMinute = index,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) => Container(
                            alignment: Alignment.center,
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      hourController.dispose();
      minuteController.dispose();
    });
  }

  void _resetAllSettings() {
    setState(() {
      activeDays = List.generate(7, (_) => false);
      selectedInterval = 1;
      startHour = 9;
      startMinute = 0;
      endHour = 18;
      endMinute = 0;
      alarmLabel = '';
      _selectedLabel = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('모든 설정이 초기화되었습니다.'),
        backgroundColor: Colors.orange[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_hasActiveDay()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('운동 실행 할 요일을 선택해주세요'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_isValidTimeRange()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작 시간이 종료 시간보다 늦을 수 없습니다.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newAlarm = AlarmData(
        id: _generateUniqueId(),
        activeDays: List.from(activeDays),
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        selectedInterval: selectedInterval,
        isAlarmEnabled: true,
        createdAt: DateTime.now(),
        label: alarmLabel.trim().isEmpty ? null : alarmLabel.trim(),
      );

      if (widget.onAlarmCreated != null) {
        widget.onAlarmCreated!(newAlarm);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('운동 알람이 저장되었습니다!'),
          backgroundColor: Colors.green[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      // 콜백과 return 값 모두 지원
      if (widget.onAlarmCreated != null) {
        widget.onAlarmCreated!(newAlarm);
      }

      // Navigator.pop으로 알람 데이터 반환
      Navigator.pop(context, newAlarm);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('알람 저장에 실패했습니다: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _getActiveDaysString() {
    List<String> activeDayNames = [];
    for (int i = 0; i < activeDays.length; i++) {
      if (activeDays[i]) activeDayNames.add(dayLabels[i]);
    }
    return activeDayNames.join(', ');
  }

  Widget _buildDayButton(int index) {
    final isActive = activeDays[index];
    return GestureDetector(
      onTap: () => setState(() => activeDays[index] = !activeDays[index]),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            dayLabels[index],
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        title: const Text('운동 알람 설정'),
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 운동 부위 선택
            const Text('운동 부위', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                  items: _labels.map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                  onChanged: (value) => setState(() => _selectedLabel = value),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 알람 제목
            Card(
              color: const Color(0xFFE4F3E1),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('알람 제목 (선택사항)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => alarmLabel = value,
                      decoration: InputDecoration(
                        hintText: '예: 아침 운동, 점심 스트레칭',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
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

            // 요일 선택
            const Text('활성화된 요일', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) => _buildDayButton(index)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 시간 설정
            const Text('운동 시작 시간 및 종료 시간', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('시작', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
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
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('종료', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
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
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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

            // 운동 주기 설정
            const Text('운동 주기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        underline: const SizedBox(),
                        items: intervalOptions.map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(' $value ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        )).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => selectedInterval = newValue);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text('시간 간격으로 알람', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetAllSettings,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('초기화', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('저장', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 미리보기
            if (_hasActiveDay() && _isValidTimeRange()) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF8F9FA),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.preview, color: Color(0xFF4CAF50)),
                          SizedBox(width: 8),
                          Text('알람 미리보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('• 활성 요일: ${_getActiveDaysString()}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('• 운동 시간: ${_formatTime(startHour, startMinute)} ~ ${_formatTime(endHour, endMinute)}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('• 알람 주기: ${selectedInterval}시간 간격', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        '• 하루 예상 알람: ${((endHour * 60 + endMinute) - (startHour * 60 + startMinute)) ~/ (selectedInterval * 60) + 1}회',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
}