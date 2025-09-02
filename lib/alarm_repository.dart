import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'alarm_data.dart';

class AlarmRepository {
  static const String _alarmsKeyPrefix = 'alarms_list_';

  /// 현재 로그인한 사용자의 알람 키 생성
  String _getUserAlarmsKey() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('사용자가 로그인되지 않았습니다.');
    }
    return '${_alarmsKeyPrefix}${user.uid}';
  }

  /// 모든 알람 불러오기
  Future<List<AlarmData>> loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserAlarmsKey();
      final alarmsStringList = prefs.getStringList(userKey) ?? [];

      List<AlarmData> alarms = [];
      for (String alarmString in alarmsStringList) {
        try {
          final Map<String, dynamic> alarmJson = jsonDecode(alarmString);
          final alarm = AlarmData.fromJson(alarmJson);
          alarms.add(alarm);
        } catch (e) {
          print('개별 알람 파싱 오류: $e, 데이터: $alarmString');
          continue;
        }
      }

      return alarms;
    } catch (e) {
      print('알람 로드 중 오류 발생: $e');
      return [];
    }
  }

  /// 새 알람 추가
  Future<bool> saveAlarm(AlarmData alarm) async {
    try {
      final alarms = await loadAlarms();
      alarms.add(alarm);
      return await _saveAllAlarms(alarms);
    } catch (e) {
      print('알람 저장 중 오류 발생: $e');
      return false;
    }
  }

  /// 알람 삭제
  Future<bool> deleteAlarm(String alarmId) async {
    try {
      final alarms = await loadAlarms();
      alarms.removeWhere((alarm) => alarm.id == alarmId);
      return await _saveAllAlarms(alarms);
    } catch (e) {
      print('알람 삭제 중 오류 발생: $e');
      return false;
    }
  }

  /// 알람 상태 업데이트
  Future<bool> updateAlarmStatus(String alarmId, bool isEnabled) async {
    try {
      final alarms = await loadAlarms();
      final index = alarms.indexWhere((alarm) => alarm.id == alarmId);

      if (index != -1) {
        alarms[index].isAlarmEnabled = isEnabled;
        return await _saveAllAlarms(alarms);
      }
      return false;
    } catch (e) {
      print('알람 상태 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  /// 현재 사용자 데이터 삭제
  Future<bool> clearCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserAlarmsKey();
      await prefs.remove(userKey);
      return true;
    } catch (e) {
      print('사용자 데이터 삭제 중 오류 발생: $e');
      return false;
    }
  }

  /// 내부 메서드: 모든 알람을 SharedPreferences에 저장
  Future<bool> _saveAllAlarms(List<AlarmData> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserAlarmsKey();
      final alarmsStringList = alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
      await prefs.setStringList(userKey, alarmsStringList);
      return true;
    } catch (e) {
      print('알람 리스트 저장 중 오류 발생: $e');
      return false;
    }
  }
}