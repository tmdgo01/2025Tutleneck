import 'package:flutter/material.dart';
import 'alarm_data.dart';
import 'alarm_repository.dart';
import 'alarm_settings_page.dart';

class AlarmListPage extends StatefulWidget {
  const AlarmListPage({super.key});

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage> {
  List<AlarmData> alarms = [];
  final AlarmRepository _repository = AlarmRepository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  /// 알람 데이터를 저장소에서 불러오기
  Future<void> _loadAlarms() async {
    setState(() => _isLoading = true);

    try {
      final loadedAlarms = await _repository.loadAlarms();
      setState(() {
        alarms = loadedAlarms;
        _isLoading = false;
      });
    } catch (e) {
      print('알람 로드 오류: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 새 알람 추가 및 저장소에 저장
  Future<void> _addAlarm(AlarmData alarm) async {
    try {
      final success = await _repository.saveAlarm(alarm);
      if (success) {
        setState(() {
          alarms.add(alarm);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람이 추가되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람 저장 실패'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('알람 추가 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류가 발생했습니다'), backgroundColor: Colors.red),
      );
    }
  }

  /// 알람 업데이트
  Future<void> _updateAlarm(int index, AlarmData updatedAlarm) async {
    try {
      final success = await _repository.updateAlarm(updatedAlarm);

      if (success) {
        setState(() {
          alarms[index] = updatedAlarm;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람이 수정되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람 수정 실패'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('알람 수정 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류가 발생했습니다'), backgroundColor: Colors.red),
      );
    }
  }

  /// 알람 삭제 및 저장소에서 제거
  Future<void> _deleteAlarm(int index) async {
    try {
      final alarmId = alarms[index].id;
      final success = await _repository.deleteAlarm(alarmId);

      if (success) {
        setState(() {
          alarms.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람이 삭제되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알람 삭제 실패'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('알람 삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류가 발생했습니다'), backgroundColor: Colors.red),
      );
    }
  }

  /// 알람 상태 토글 및 저장소 업데이트
  Future<void> _toggleAlarm(int index, bool value) async {
    try {
      final alarmId = alarms[index].id;
      final success = await _repository.updateAlarmStatus(alarmId, value);

      if (success) {
        setState(() {
          alarms[index].isAlarmEnabled = value;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상태 변경 실패'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('알람 상태 변경 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류가 발생했습니다'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatTime(int hour, int minute) {
    String period = hour < 12 ? '오전' : '오후';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _getActiveDaysString(List<bool> activeDays) {
    final dayLabels = ['일','월','화','수','목','금','토'];
    List<String> activeDayNames = [];
    for (int i = 0; i < activeDays.length; i++) {
      if (activeDays[i]) activeDayNames.add(dayLabels[i]);
    }
    return activeDayNames.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        title: const Text('운동 알람'),
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : alarms.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '알람이 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '+ 버튼으로 새 알람을 추가하세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () async {
                // 알람 수정 페이지로 이동
                final updatedAlarm = await Navigator.push<AlarmData>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlarmSettingsPage(
                      existingAlarm: alarm, // 기존 알람 데이터 전달
                    ),
                  ),
                );

                // 수정된 알람이 반환되면 업데이트
                if (updatedAlarm != null) {
                  await _updateAlarm(index, updatedAlarm);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: alarm.isAlarmEnabled
                        ? [Colors.white, const Color(0xFFF8FFF8)]
                        : [Colors.grey[50]!, Colors.grey[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alarm.label ?? '운동 알람',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: alarm.isAlarmEnabled ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatTime(alarm.startHour, alarm.startMinute)} ~ ${_formatTime(alarm.endHour, alarm.endMinute)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: alarm.isAlarmEnabled ? const Color(0xFF4CAF50) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: alarm.isAlarmEnabled,
                            onChanged: (val) => _toggleAlarm(index, val),
                            activeColor: const Color(0xFF4CAF50),
                            activeTrackColor: const Color(0xFF4CAF50).withOpacity(0.3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${alarm.selectedInterval}시간 간격',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getActiveDaysString(alarm.activeDays),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[400],
                              size: 20,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('알람 삭제'),
                                  content: const Text('이 알람을 삭제하시겠습니까?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteAlarm(index);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4CAF50),
        onPressed: () async {
          final newAlarm = await Navigator.push<AlarmData>(
            context,
            MaterialPageRoute(
              builder: (context) => AlarmSettingsPage(
                onAlarmCreated: null, // 콜백 대신 return 값으로 처리
              ),
            ),
          );

          if (newAlarm != null) {
            await _addAlarm(newAlarm);
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '새 알람',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}