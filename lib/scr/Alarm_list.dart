import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../main.dart';
import '../models/Alarm_Data.dart';
import 'AlarmScreen.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';


class AlarmListPage extends StatefulWidget {
  const AlarmListPage({Key? key}) : super(key: key);

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage> {
  List<AlarmData> alarms = [];
  int _nextNotificationId = 0;

  @override
  void initState() {
    super.initState();
    _initTimezone();
  }

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  void _addAlarm(AlarmData alarm) {
    setState(() {
      alarms.add(alarm);
    });
  }

  Future<void> _deleteAlarm(int index) async {
    final alarm = alarms[index];
    if (alarm.isAlarmEnabled) {
      await _cancelAlarm(alarm);
    }
    setState(() {
      alarms.removeAt(index);
    });
  }

  Future<void> _toggleAlarm(int index, bool value ) async {
    final alarm = alarms[index];
    setState(() {
      alarm.isAlarmEnabled = value;
    });

    if (value) {
      // Android 13+ 알림 권한 요청 (활성화 시에만)
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      bool granted = false;
      if (androidImplementation != null) {
        granted = await androidImplementation.requestNotificationsPermission() ?? false;
      } else {
        // 비-Android 플랫폼(예: iOS)에서는 권한이 이미 처리되었다고 가정
        granted = true;
      }

      if (granted) {
        // 알람 예약
        await _scheduleAlarm(alarm);
      } else {
        // 권한 거부 시 상태 복원 및 안내
        setState(() {
          alarm.isAlarmEnabled = false;
        });
        // TODO: 사용자에게 다이얼로그나 스낵바로 알림 권한 필요성 안내
        print('알림 권한이 거부되었습니다. 설정에서 활성화해주세요.');
      }
    } else {
      // 알람 취소
      await _cancelAlarm(alarm);
    }
  }
  Future<void> _scheduleAlarm(AlarmData alarm) async {
    alarm.notificationIds.clear();

    final now = tz.TZDateTime.now(tz.local);
    var startTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, alarm.startHour, alarm.startMinute);
    final endTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, alarm.endHour, alarm.endMinute);

    // 간격이 0이면 예외 처리 (무한 루프 방지)
    if (alarm.selectedInterval <= 0) {
      print('간격이 유효하지 않습니다.');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'exercise_alarm_channel',
      'Exercise Alarm Channel',
      channelDescription: 'Channel for exercise alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    for (var time = startTime; !time.isAfter(endTime); time = time.add(Duration(hours: alarm.selectedInterval))) {
      var scheduledTime = time;
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final int id = _nextNotificationId++;
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '운동 알람',
        alarm.label ?? '운동 시간입니다!',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,  // 매일 반복
      );
      alarm.notificationIds.add(id);
    }
  }

  Future<void> _cancelAlarm(AlarmData alarm) async {
    for (int id in alarm.notificationIds) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
    alarm.notificationIds.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE4F3E1),
      appBar: AppBar(
        title: const Text('운동 알람'),
        backgroundColor: Color(0xFFE4F3E1),
        elevation: 0,
      ),
      body: alarms.isEmpty
          ? const Center(child: Text('알람이 없습니다. + 버튼으로 추가하세요'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final alarm = alarms[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              title: Text(
                alarm.label ?? '운동 알람',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${alarm.startHour.toString().padLeft(2, '0')}:${alarm.startMinute.toString().padLeft(2, '0')}'
                    ' ~ '
                    '${alarm.endHour.toString().padLeft(2, '0')}:${alarm.endMinute.toString().padLeft(2, '0')}'
                    ' | ${alarm.selectedInterval}시간 간격',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: alarm.isAlarmEnabled,
                    onChanged: (val) => _toggleAlarm(index, val),
                    activeColor: Color(0xFF4CAF50),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAlarm(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF4CAF50),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Alarm(
                onAlarmCreated: (newAlarm) {
                  _addAlarm(newAlarm);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
