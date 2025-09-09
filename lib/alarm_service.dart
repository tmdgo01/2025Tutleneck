import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'alarm_data.dart';
import 'alarm_repository.dart';
import 'alarmpage.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  Timer? _timer;
  final AlarmRepository _repository = AlarmRepository();
  BuildContext? _context;
  bool _isRunning = false;
  List<AlarmData>? _cachedAlarms;
  DateTime? _lastTriggeredTime;
  String? _lastTriggeredAlarmId;

  /// 서비스 실행 상태 확인
  bool get isRunning => _isRunning;

  /// 알람 서비스 시작
  void startAlarmService(BuildContext context) {
    _context = context;

    if (_isRunning) {
      print('⚠️ 알람 서비스가 이미 실행 중입니다.');
      return;
    }

    // 기존 타이머가 있으면 취소
    _timer?.cancel();

    // 처음 시작할 때 즉시 한번 체크
    _checkAlarms();

    // 30초마다 알람 체크 (더 정확한 체크를 위해)
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAlarms();
    });

    _isRunning = true;
    print('🔔 알람 서비스 시작됨 - 30초마다 체크');
  }

  /// 알람 서비스 중지
  void stopAlarmService() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _cachedAlarms = null;
    _lastTriggeredTime = null;
    _lastTriggeredAlarmId = null;
    print('⏹️ 알람 서비스 중지됨');
  }

  /// 알람 목록 새로고침 (알람 추가/수정/삭제 시 호출)
  void refreshAlarms() {
    _cachedAlarms = null; // 캐시 초기화
    print('🔄 알람 목록 새로고침됨');
  }

  /// 현재 시간에 맞는 알람이 있는지 체크
  Future<void> _checkAlarms() async {
    if (_context == null || !_isRunning) return;

    try {
      // 캐시된 알람이 없으면 로드
      _cachedAlarms ??= await _repository.getActiveAlarms();

      final now = DateTime.now();
      final activeAlarmsCount = _cachedAlarms?.length ?? 0;

      // 디버그 정보 (매분마다만 출력)
      if (now.second == 0 || now.second == 30) {
        print('⏰ 알람 체크: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} (활성 알람: ${activeAlarmsCount}개)');
      }

      for (final alarm in _cachedAlarms ?? <AlarmData>[]) {
        if (_shouldTriggerAlarm(alarm, now)) {
          await _triggerAlarm(alarm);
          break; // 한 번에 하나의 알람만 실행
        }
      }
    } catch (e) {
      print('❌ 알람 체크 중 오류: $e');
      // 오류 발생 시 캐시 초기화하여 다음번에 다시 로드
      _cachedAlarms = null;
    }
  }

  /// 알람이 울려야 하는지 판단
  bool _shouldTriggerAlarm(AlarmData alarm, DateTime now) {
    // 알람이 비활성화되어 있으면 건너뛰기
    if (!alarm.isAlarmEnabled) {
      return false;
    }

    // 요일 체크 (0: 일요일, 1: 월요일, ..., 6: 토요일)
    final currentWeekday = now.weekday % 7;
    if (!alarm.activeDays[currentWeekday]) {
      return false;
    }

    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTotalMinutes = currentHour * 60 + currentMinute;

    // 현재 시간이 알람 시작 시간과 종료 시간 사이인지 체크
    final startTotalMinutes = alarm.startHour * 60 + alarm.startMinute;
    final endTotalMinutes = alarm.endHour * 60 + alarm.endMinute;

    if (currentTotalMinutes < startTotalMinutes || currentTotalMinutes > endTotalMinutes) {
      return false;
    }

    // 간격 체크
    final minutesSinceStart = currentTotalMinutes - startTotalMinutes;
    final intervalMinutes = alarm.selectedInterval * 60;

    // 정확히 간격에 맞는 시간인지 체크
    if (minutesSinceStart % intervalMinutes != 0) {
      return false;
    }

    // 중복 알람 방지: 같은 알람이 같은 분에 이미 울렸는지 체크
    final currentTimeKey = '${alarm.id}_${currentHour}_${currentMinute}';
    final lastTriggeredKey = _lastTriggeredAlarmId != null && _lastTriggeredTime != null
        ? '${_lastTriggeredAlarmId}_${_lastTriggeredTime!.hour}_${_lastTriggeredTime!.minute}'
        : null;

    if (currentTimeKey == lastTriggeredKey) {
      return false;
    }

    print('✅ 알람 조건 충족: ${alarm.label ?? "운동 알람"} - $currentHour:$currentMinute (${alarm.selectedInterval}시간 간격)');
    return true;
  }

  /// 알람 실행
  Future<void> _triggerAlarm(AlarmData alarm) async {
    if (_context == null) return;

    _lastTriggeredTime = DateTime.now();
    _lastTriggeredAlarmId = alarm.id;

    print('🔔 알람 실행: ${alarm.label ?? "운동 알람"} - ${alarm.formattedStartTime}');

    // 진동 실행
    try {
      await HapticFeedback.vibrate();
      // 연속 진동 효과
      Timer(const Duration(milliseconds: 300), () => HapticFeedback.vibrate());
      Timer(const Duration(milliseconds: 600), () => HapticFeedback.vibrate());
    } catch (e) {
      print('❌ 진동 실행 오류: $e');
    }

    // 알람 페이지 표시
    try {
      final navigator = Navigator.of(_context!);

      // 이미 알람 페이지가 열려있는지 체크
      final currentRoute = ModalRoute.of(_context!)?.settings.name;
      if (currentRoute == '/alarm') {
        print('⚠️ 이미 알람 페이지가 열려있습니다.');
        return;
      }

      await navigator.push(
        MaterialPageRoute(
          builder: (context) => AlarmPage(
            alarmLabel: alarm.label ?? "운동 알람",
            alarmTime: alarm.formattedStartTime,
            onDismiss: () {
              print('✋ 알람이 해제되었습니다: ${alarm.label ?? "운동 알람"}');
            },
          ),
          fullscreenDialog: true,
          settings: const RouteSettings(name: '/alarm'),
        ),
      );
    } catch (e) {
      print('❌ 알람 페이지 표시 오류: $e');
    }
  }

  /// 테스트용 수동 알람 트리거
  void testAlarm({String? label}) {
    if (_context == null) {
      print('❌ Context가 없어서 테스트 알람을 실행할 수 없습니다.');
      return;
    }

    final now = DateTime.now();
    final testAlarm = AlarmData(
      id: 'test_${now.millisecondsSinceEpoch}',
      startHour: now.hour,
      startMinute: now.minute,
      endHour: now.hour,
      endMinute: now.minute,
      selectedInterval: 1,
      activeDays: [true, true, true, true, true, true, true],
      isAlarmEnabled: true,
      createdAt: now,
      label: label ?? '테스트 알람',
    );

    print('🧪 테스트 알람 실행');
    _triggerAlarm(testAlarm);
  }

  /// 다음 알람 시간 계산
  Future<DateTime?> getNextAlarmTime() async {
    try {
      final alarms = await _repository.getActiveAlarms();
      if (alarms.isEmpty) return null;

      final now = DateTime.now();
      DateTime? nextAlarmTime;

      for (final alarm in alarms) {
        final nextTime = _calculateNextAlarmTime(alarm, now);
        if (nextTime != null) {
          if (nextAlarmTime == null || nextTime.isBefore(nextAlarmTime)) {
            nextAlarmTime = nextTime;
          }
        }
      }

      return nextAlarmTime;
    } catch (e) {
      print('❌ 다음 알람 시간 계산 오류: $e');
      return null;
    }
  }

  /// 특정 알람의 다음 실행 시간 계산
  DateTime? _calculateNextAlarmTime(AlarmData alarm, DateTime now) {
    if (!alarm.isAlarmEnabled) return null;

    final currentWeekday = now.weekday % 7;
    final startTotalMinutes = alarm.startHour * 60 + alarm.startMinute;
    final endTotalMinutes = alarm.endHour * 60 + alarm.endMinute;
    final intervalMinutes = alarm.selectedInterval * 60;

    // 오늘 체크
    if (alarm.activeDays[currentWeekday]) {
      final nowTotalMinutes = now.hour * 60 + now.minute;

      if (nowTotalMinutes < startTotalMinutes) {
        // 오늘 시작 시간 전
        return DateTime(now.year, now.month, now.day, alarm.startHour, alarm.startMinute);
      } else if (nowTotalMinutes <= endTotalMinutes) {
        // 오늘 시간 범위 내 - 다음 간격 시간 계산
        final minutesSinceStart = nowTotalMinutes - startTotalMinutes;
        final nextIntervalMinutes = ((minutesSinceStart ~/ intervalMinutes) + 1) * intervalMinutes;
        final nextTotalMinutes = startTotalMinutes + nextIntervalMinutes;

        if (nextTotalMinutes <= endTotalMinutes) {
          final nextHour = nextTotalMinutes ~/ 60;
          final nextMinute = nextTotalMinutes % 60;
          return DateTime(now.year, now.month, now.day, nextHour, nextMinute);
        }
      }
    }

    // 다음 활성 요일 찾기
    for (int i = 1; i <= 7; i++) {
      final checkDay = (currentWeekday + i) % 7;
      if (alarm.activeDays[checkDay]) {
        final targetDate = now.add(Duration(days: i));
        return DateTime(targetDate.year, targetDate.month, targetDate.day, alarm.startHour, alarm.startMinute);
      }
    }

    return null;
  }

  /// 현재 상태 정보 반환
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'cachedAlarmsCount': _cachedAlarms?.length ?? 0,
      'lastTriggeredTime': _lastTriggeredTime?.toString(),
      'lastTriggeredAlarmId': _lastTriggeredAlarmId,
      'currentTime': DateTime.now().toString(),
      'contextAvailable': _context != null,
    };
  }

  /// 상태 정보를 보기 좋게 포맷팅
  String getFormattedStatus() {
    final status = getStatus();
    return '''
      🔔 알람 서비스 상태
      • 실행 상태: ${status['isRunning'] ? '실행중' : '중지됨'}
      • 캐시된 알람: ${status['cachedAlarmsCount']}개
      • 마지막 실행: ${status['lastTriggeredTime'] ?? '없음'}
      • Context 상태: ${status['contextAvailable'] ? '정상' : '없음'}
      • 현재 시간: ${DateTime.now().toString().substring(0, 19)}
      ''';
  }
}