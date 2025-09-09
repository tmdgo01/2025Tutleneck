import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'alarm_data.dart';
import 'alarmpage.dart';

class BackgroundAlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// 초기화
  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTapped(response, navigatorKey);
      },
    );

    _isInitialized = true;
    print('✅ BackgroundAlarmService 초기화 완료');
  }

  static Future<void> printScheduledNotifications() async {
    try {
      await initialize(); // 안전하게 초기화
      final pending = await _notifications.pendingNotificationRequests();
      print('📅 예약된 알람 개수: ${pending.length}');
      for (final n in pending.take(10)) {
        print('ID: ${n.id}, 제목: ${n.title}, 내용: ${n.body}, payload: ${n.payload}');
      }
    } catch (e) {
      print('⚠️ 예약 알람 조회 중 오류: $e');
    }
  }

  /// 알림 클릭 시 동작
  static void _onNotificationTapped(
      NotificationResponse response,
      GlobalKey<NavigatorState>? navigatorKey,
      ) {
    print('🔔 알림 탭됨: ${response.payload}');
    if (navigatorKey?.currentState == null) {
      print('❗ NavigatorState 없음 → 라우팅 불가');
      return;
    }

    final payload = response.payload ?? '';
    final alarmId = payload.split('_').first;

    navigatorKey!.currentState!.push(
      MaterialPageRoute(
        builder: (_) => AlarmPage(
          alarmLabel: '운동 알람',
          alarmTime: DateTime.now().toString(),
          onDismiss: () {
            print('알람 종료!');
          },
        ),
      ),
    );
  }

  /// 알람 전체 등록
  static Future<void> scheduleAllAlarms(List<AlarmData> alarms) async {
    await initialize();
    // 필요시 기존 알람 취소
    // await _notifications.cancelAll();

    final now = DateTime.now();

    for (final alarm in alarms) {
      if (!alarm.isAlarmEnabled) continue;

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final targetDate = now.add(Duration(days: dayOffset));
        final weekday = targetDate.weekday % 7;
        if (!alarm.activeDays[weekday]) continue;

        final alarmTimes = _calculateAlarmTimesForDay(alarm, targetDate);

        for (int i = 0; i < alarmTimes.length; i++) {
          final alarmTime = alarmTimes[i];
          if (alarmTime.isBefore(now)) continue;

          final notificationId = _generateNotificationId(alarm.id, dayOffset, i);

          await _notifications.zonedSchedule(
            notificationId,
            '운동 시간입니다! 🐢',
            '${alarm.label ?? "운동 알람"} - 지금 운동하세요!',
            tz.TZDateTime.from(alarmTime, tz.local),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'exercise_alarm',
                '운동 알람',
                channelDescription: '정기적인 운동 알림',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                fullScreenIntent: true,
                category: AndroidNotificationCategory.alarm,
              ),
              iOS: const DarwinNotificationDetails(
                sound: 'default',
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                interruptionLevel: InterruptionLevel.critical,
              ),
            ),
            payload: '${alarm.id}_${alarmTime.millisecondsSinceEpoch}',
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    }

    print('✅ ${alarms.where((a) => a.isAlarmEnabled).length}개 알람 등록됨');
  }

  static List<DateTime> _calculateAlarmTimesForDay(AlarmData alarm, DateTime date) {
    final List<DateTime> times = [];
    final startTime = DateTime(date.year, date.month, date.day, alarm.startHour, alarm.startMinute);
    final endTime = DateTime(date.year, date.month, date.day, alarm.endHour, alarm.endMinute);
    final interval = Duration(hours: alarm.selectedInterval);

    DateTime current = startTime;
    while (current.isBefore(endTime) || current.isAtSameMomentAs(endTime)) {
      times.add(current);
      current = current.add(interval);
    }
    return times;
  }

  static int _generateNotificationId(String alarmId, int dayOffset, int timeIndex) {
    return ('$alarmId-$dayOffset-$timeIndex').hashCode.abs() % 2147483647;
  }

  static Future<void> cancelAllAlarms() async {
    await initialize();
    await _notifications.cancelAll();
    print('🛑 모든 알람 취소됨');
  }

  static Future<bool> requestPermissions() async {
    await initialize();
    final androidImpl =
    _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      if (granted ?? false) return true;
    }

    final iosImpl =
    _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
      if (granted ?? false) return true;
    }

    return false;
  }
}