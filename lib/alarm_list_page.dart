import 'package:flutter/material.dart';
import 'alarm_data.dart';
import 'alarm_repository.dart';
import 'alarm_service.dart';
import 'alarm_settings_page.dart';

class AlarmListPage extends StatefulWidget {
  const AlarmListPage({super.key});

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage> with WidgetsBindingObserver {
  List<AlarmData> alarms = [];
  final AlarmRepository _repository = AlarmRepository();
  final AlarmService _alarmService = AlarmService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAlarms();
    _startAlarmService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alarmService.stopAlarmService();
    super.dispose();
  }

  // 앱 생명주기 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _startAlarmService();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        _alarmService.stopAlarmService();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startAlarmService() {
    _alarmService.startAlarmService(context);
    print('알람 서비스가 시작되었습니다.');
  }

  Future<void> _loadAlarms() async {
    setState(() => _isLoading = true);

    try {
      final loadedAlarms = await _repository.loadAlarms();
      setState(() {
        alarms = loadedAlarms;
        _isLoading = false;
      });

      _alarmService.refreshAlarms();
    } catch (e) {
      print('알람 로드 오류: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAlarm(AlarmData alarm) async {
    try {
      final success = await _repository.saveAlarm(alarm);
      if (success) {
        setState(() {
          alarms.add(alarm);
          alarms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
        _alarmService.refreshAlarms();
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

  Future<void> _updateAlarm(int index, AlarmData updatedAlarm) async {
    try {
      final success = await _repository.updateAlarm(updatedAlarm);

      if (success) {
        setState(() {
          alarms[index] = updatedAlarm;
        });
        _alarmService.refreshAlarms();
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

  Future<void> _deleteAlarm(int index) async {
    try {
      final alarmId = alarms[index].id;
      final success = await _repository.deleteAlarm(alarmId);

      if (success) {
        setState(() {
          alarms.removeAt(index);
        });
        _alarmService.refreshAlarms();
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

  Future<void> _toggleAlarm(int index, bool value) async {
    try {
      final alarmId = alarms[index].id;
      final success = await _repository.updateAlarmStatus(alarmId, value);

      if (success) {
        setState(() {
          alarms[index].isAlarmEnabled = value;
        });
        _alarmService.refreshAlarms();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '알람이 활성화되었습니다' : '알람이 비활성화되었습니다'),
          ),
        );
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

  void _showDebugInfo() {
    final status = _alarmService.getStatus();
    final activeAlarms = alarms.where((alarm) => alarm.isAlarmEnabled).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알람 상태'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('전체 알람: ${alarms.length}개'),
              Text('활성 알람: $activeAlarms개'),
              Text('서비스 상태: ${status['isRunning'] ? "실행중" : "중지됨"}'),
              Text('캐시된 알람: ${status['cachedAlarmsCount']}개'),
              const SizedBox(height: 10),
              const Text('마지막 실행:'),
              Text(status['lastTriggeredTime']?.toString().substring(0, 19) ?? '없음',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _alarmService.testAlarm(label: '테스트 알람');
              Navigator.pop(context);
            },
            child: const Text('테스트 알람'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 알람 수정 페이지로 이동하는 함수
  Future<void> _editAlarm(int index) async {
    print('알람 수정 시도: ${alarms[index].label}'); // 디버그용

    final updatedAlarm = await Navigator.push<AlarmData>(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmSettingsPage(
          existingAlarm: alarms[index],
        ),
      ),
    );

    if (updatedAlarm != null) {
      print('알람 수정 완료: ${updatedAlarm.label}'); // 디버그용
      await _updateAlarm(index, updatedAlarm);
    } else {
      print('알람 수정 취소됨'); // 디버그용
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4F3E1),
      appBar: AppBar(
        title: const Text('운동 알람'),
        backgroundColor: const Color(0xFFE4F3E1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDebugInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4CAF50)),
            SizedBox(height: 16),
            Text('알람 로딩 중...'),
          ],
        ),
      )
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
          : RefreshIndicator(
        onRefresh: _loadAlarms,
        child: ListView.builder(
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
                onTap: () {
                  print('알람 카드 탭됨: ${alarm.label}'); // 디버그용
                  _editAlarm(index);
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
                                  Text(
                                    alarm.label ?? '운동 알람',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: alarm.isAlarmEnabled ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${alarm.formattedStartTime} ~ ${alarm.formattedEndTime}',
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
                                alarm.activeDaysString,
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
                                    content: Text('${alarm.label ?? "이 알람"}을 삭제하시겠습니까?'),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4CAF50),
        onPressed: () async {
          print('새 알람 버튼 클릭됨'); // 디버그용

          final newAlarm = await Navigator.push<AlarmData>(
            context,
            MaterialPageRoute(
              builder: (context) => const AlarmSettingsPage(),
            ),
          );

          if (newAlarm != null) {
            print('새 알람 생성됨: ${newAlarm.label}'); // 디버그용
            await _addAlarm(newAlarm);
          } else {
            print('새 알람 생성 취소됨'); // 디버그용
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