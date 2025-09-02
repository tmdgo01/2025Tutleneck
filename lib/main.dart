import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'models/Alarm_Data.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'scr/AlarmPage.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin(); // [수정] 전역 객체 생성

final scheduledDate = tz.TZDateTime.from(
  DateTime.now().add(Duration(seconds: 5)),
  tz.local, // 기기의 로컬 타임존 사용

);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // <- 타임존 초기화
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  await initializeDateFormatting();



  // [수정] 알림 초기화
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // [수정] 알림 클릭 시 라우트 이동
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamed('/alarm');
      }
    },
  );
// 안드로이드 13 이상 알림 권한 요청
  final plugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (plugin != null) {
    final bool? granted = await plugin.areNotificationsEnabled();
    final bool isGranted = granted ?? false;
    if (!isGranted) {
      // 사용자가 설정에서 직접 켜야 하는 경우 안내 필요
      print('알림 권한이 꺼져 있음 (Android 13 이상)');
    }
  }


  runApp(MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); // [수정] 전역 네비게이터

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Alarm Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
      routes: {
        '/alarm': (context) => AlarmPage(), // [수정] 알람 라우트 추가
      },
    );
  }
}

class HomePage extends StatelessWidget {
  Future<void> _scheduleAlarm() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Channel',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // ✅ 풀스크린 알람
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '테스트 알람',
      '5초 후 알람이 울립니다!',
      tz.TZDateTime.from(DateTime.now().add(Duration(seconds: 5)), tz.local), // ✅ 5초 후
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Alarm Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  child: Text('알람 화면 직접 열기'),
                  onPressed: () =>Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlarmPage(),
                    ),
                  )

                //Navigator.pushNamed(context, '/alarm'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('5초 후 알람 울리기'),
                onPressed:_scheduleAlarm,


              ),
            ],
          ),
        )
    );
  }
}
