import 'dart:async';
import 'package:flutter/material.dart';
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

  /// 알람 서비스 시작
  void startAlarmService(BuildContext context) {
    _context = context;

    // 기존 타이머가 있으면 취소
    _timer?.cancel();

    // 1분마다 알람 체크
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAlarms();
    });

    print('알람 서비스 시작됨 - 1분마다 체크');
  }

  /// 알람 서비스 중지
  void stopAlarmService() {
    _timer?.cancel();
    _timer = null;
    print('알람 서비스 중지됨');
  }

  /// 현재 시간에 맞는 알람이 있는지 체크
  Future<void> _checkAlarms() async {
    if (_context == null) return;

    try {
      final alarms = await _repository.getActiveAlarms();
      final now = DateTime.now();

      for (final alarm in alarms) {
        if (_shouldTriggerAlarm(alarm, now)) {
          _triggerAlarm(alarm);
        }
      }
    } catch (e) {
      print('알람 체크 중 오류: $e');
    }
  }

  /// 알람이 울려야 하는지 판단
  bool _shouldTriggerAlarm(AlarmData alarm, DateTime now) {
    // 요일 체크 (0: 일요일, 1: 월요일, ..., 6: 토요일)
    final currentWeekday = now.weekday % 7; // Flutter의 weekday를 0-6으로 변환
    if (!alarm.activeDays[currentWeekday]) {
      return false;
    }

    final currentHour = now.hour;
    final currentMinute = now.minute;

    // 현재 시간이 알람 시작 시간과 종료 시간 사이인지 체크
    final startTotalMinutes = alarm.startHour * 60 + alarm.startMinute;
    final endTotalMinutes = alarm.endHour * 60 + alarm.endMinute;
    final currentTotalMinutes = currentHour * 60 + currentMinute;

    if (currentTotalMinutes < startTotalMinutes || currentTotalMinutes > endTotalMinutes) {
      return false;
    }

    // 간격 체크 (간단 버전: 시작 시간부터 간격에 맞는지)
    final minutesSinceStart = currentTotalMinutes - startTotalMinutes;
    final intervalMinutes = alarm.selectedInterval * 60;

    return minutesSinceStart % intervalMinutes == 0;
  }

  /// 알람 실행
  void _triggerAlarm(AlarmData alarm) {
    if (_context == null) return;

    print('알람 실행: ${alarm.label ?? "운동 알람"} - ${alarm.startHour}:${alarm.startMinute}');

    // AlarmPage 표시
    Navigator.of(_context!).push(
      MaterialPageRoute(
        builder: (context) => AlarmPage(
          alarmLabel: alarm.label ?? "운동 알람",
          alarmTime: _formatTime(alarm.startHour, alarm.startMinute),
        ),
        fullscreenDialog: true, // 전체 화면 모달로 표시
      ),
    );
  }

  /// 시간 포맷팅
  String _formatTime(int hour, int minute) {
    String period = hour < 12 ? '오전' : '오후';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}