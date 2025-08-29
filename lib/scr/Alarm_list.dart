import 'package:flutter/material.dart';
import '../models/Alarm_Data.dart';
import 'AlarmScreen.dart';

class AlarmListPage extends StatefulWidget {
  const AlarmListPage({Key? key}) : super(key: key);

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage> {
  List<AlarmData> alarms = [];

  void _addAlarm(AlarmData alarm) {
    setState(() {
      alarms.add(alarm);
    });
  }

  void _deleteAlarm(int index) {
    setState(() {
      alarms.removeAt(index);
    });
  }

  void _toggleAlarm(int index, bool value) {
    setState(() {
      alarms[index].isAlarmEnabled = value;
    });
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
