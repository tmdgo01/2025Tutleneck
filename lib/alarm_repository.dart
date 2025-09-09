import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_data.dart';

class AlarmRepository {
  static const String _alarmsKey = 'alarms_list_v2'; // 버전 업데이트

  /// 모든 알람 불러오기
  Future<List<AlarmData>> loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsStringList = prefs.getStringList(_alarmsKey) ?? [];

      List<AlarmData> alarms = [];
      int successCount = 0;
      int errorCount = 0;

      for (String alarmString in alarmsStringList) {
        try {
          final Map<String, dynamic> alarmJson = jsonDecode(alarmString);
          final alarm = AlarmData.fromJson(alarmJson);
          alarms.add(alarm);
          successCount++;
        } catch (e) {
          print('❌ 개별 알람 파싱 오류: $e');
          errorCount++;
          continue;
        }
      }

      print('📋 알람 로드 완료: 성공 ${successCount}개, 오류 ${errorCount}개');

      // 생성 시간순으로 정렬 (최신 순)
      alarms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return alarms;
    } catch (e) {
      print('❌ 알람 로드 중 전체 오류 발생: $e');
      return [];
    }
  }

  /// 새 알람 추가
  Future<bool> saveAlarm(AlarmData alarm) async {
    try {
      final alarms = await loadAlarms();

      // 중복 ID 체크
      final existingIndex = alarms.indexWhere((a) => a.id == alarm.id);
      if (existingIndex != -1) {
        print('⚠️ 중복된 알람 ID 발견, 업데이트로 처리: ${alarm.id}');
        alarms[existingIndex] = alarm;
      } else {
        alarms.add(alarm);
      }

      final success = await _saveAllAlarms(alarms);
      if (success) {
        print('✅ 알람 저장 성공: ${alarm.label ?? alarm.id}');
      }
      return success;
    } catch (e) {
      print('❌ 알람 저장 중 오류 발생: $e');
      return false;
    }
  }

  /// 알람 삭제
  Future<bool> deleteAlarm(String alarmId) async {
    try {
      final alarms = await loadAlarms();
      final initialCount = alarms.length;
      alarms.removeWhere((alarm) => alarm.id == alarmId);

      if (alarms.length < initialCount) {
        final success = await _saveAllAlarms(alarms);
        if (success) {
          print('🗑️ 알람 삭제 성공: $alarmId');
        }
        return success;
      } else {
        print('⚠️ 삭제할 알람을 찾을 수 없음: $alarmId');
        return false;
      }
    } catch (e) {
      print('❌ 알람 삭제 중 오류 발생: $e');
      return false;
    }
  }

  /// 알람 상태 업데이트 (활성화/비활성화)
  Future<bool> updateAlarmStatus(String alarmId, bool isEnabled) async {
    try {
      final alarms = await loadAlarms();
      final index = alarms.indexWhere((alarm) => alarm.id == alarmId);

      if (index != -1) {
        alarms[index].isAlarmEnabled = isEnabled;
        final success = await _saveAllAlarms(alarms);
        if (success) {
          print('🔄 알람 상태 변경 성공: $alarmId -> ${isEnabled ? "활성화" : "비활성화"}');
        }
        return success;
      } else {
        print('⚠️ 상태를 변경할 알람을 찾을 수 없음: $alarmId');
        return false;
      }
    } catch (e) {
      print('❌ 알람 상태 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  /// 특정 알람 업데이트
  Future<bool> updateAlarm(AlarmData updatedAlarm) async {
    try {
      final alarms = await loadAlarms();
      final index = alarms.indexWhere((alarm) => alarm.id == updatedAlarm.id);

      if (index != -1) {
        alarms[index] = updatedAlarm;
        final success = await _saveAllAlarms(alarms);
        if (success) {
          print('📝 알람 업데이트 성공: ${updatedAlarm.label ?? updatedAlarm.id}');
        }
        return success;
      } else {
        print('⚠️ 업데이트할 알람을 찾을 수 없음: ${updatedAlarm.id}');
        return false;
      }
    } catch (e) {
      print('❌ 알람 업데이트 중 오류 발생: $e');
      return false;
    }
  }

  /// 활성화된 알람만 가져오기 (알람 서비스에서 사용)
  Future<List<AlarmData>> getActiveAlarms() async {
    try {
      final allAlarms = await loadAlarms();
      final activeAlarms = allAlarms.where((alarm) => alarm.isAlarmEnabled).toList();

      // 시작 시간순으로 정렬
      activeAlarms.sort((a, b) {
        final aTime = a.startHour * 60 + a.startMinute;
        final bTime = b.startHour * 60 + b.startMinute;
        return aTime.compareTo(bTime);
      });

      print('⚡ 활성화된 알람 로드: ${activeAlarms.length}개');
      return activeAlarms;
    } catch (e) {
      print('❌ 활성 알람 로드 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 ID로 알람 찾기
  Future<AlarmData?> getAlarmById(String alarmId) async {
    try {
      final alarms = await loadAlarms();
      final index = alarms.indexWhere((alarm) => alarm.id == alarmId);

      if (index != -1) {
        print('🔍 알람 검색 성공: $alarmId');
        return alarms[index];
      } else {
        print('⚠️ 알람을 찾을 수 없음: $alarmId');
        return null;
      }
    } catch (e) {
      print('❌ 알람 검색 중 오류 발생: $e');
      return null;
    }
  }

  /// 총 알람 개수
  Future<int> getAlarmCount() async {
    try {
      final alarms = await loadAlarms();
      return alarms.length;
    } catch (e) {
      print('❌ 알람 개수 조회 중 오류 발생: $e');
      return 0;
    }
  }

  /// 활성화된 알람 개수
  Future<int> getActiveAlarmCount() async {
    try {
      final activeAlarms = await getActiveAlarms();
      return activeAlarms.length;
    } catch (e) {
      print('❌ 활성 알람 개수 조회 중 오류 발생: $e');
      return 0;
    }
  }

  /// 모든 알람 삭제 (테스트/디버그용)
  Future<bool> clearAllAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_alarmsKey);
      print('🧹 모든 알람 데이터 삭제됨');
      return true;
    } catch (e) {
      print('❌ 모든 알람 삭제 중 오류 발생: $e');
      return false;
    }
  }

  /// 통계 정보 가져오기
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final alarms = await loadAlarms();
      final activeAlarms = alarms.where((a) => a.isAlarmEnabled).toList();

      // 요일별 활성 알람 개수
      final dayStats = List.filled(7, 0);
      for (final alarm in activeAlarms) {
        for (int i = 0; i < 7; i++) {
          if (alarm.activeDays[i]) {
            dayStats[i]++;
          }
        }
      }

      // 시간대별 알람 개수
      final hourStats = List.filled(24, 0);
      for (final alarm in activeAlarms) {
        hourStats[alarm.startHour]++;
      }

      return {
        'totalAlarms': alarms.length,
        'activeAlarms': activeAlarms.length,
        'inactiveAlarms': alarms.length - activeAlarms.length,
        'dayStatistics': dayStats,
        'hourStatistics': hourStats,
        'oldestAlarm': alarms.isNotEmpty ? alarms.map((a) => a.createdAt).reduce((a, b) => a.isBefore(b) ? a : b) : null,
        'newestAlarm': alarms.isNotEmpty ? alarms.map((a) => a.createdAt).reduce((a, b) => a.isAfter(b) ? a : b) : null,
      };
    } catch (e) {
      print('❌ 통계 조회 중 오류 발생: $e');
      return {};
    }
  }

  /// 내부 메서드: 모든 알람을 SharedPreferences에 저장
  Future<bool> _saveAllAlarms(List<AlarmData> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsStringList = alarms.map((alarm) => jsonEncode(alarm.toJson())).toList();
      await prefs.setStringList(_alarmsKey, alarmsStringList);
      print('💾 알람 데이터 저장 완료: ${alarms.length}개');
      return true;
    } catch (e) {
      print('❌ 알람 리스트 저장 중 오류 발생: $e');
      return false;
    }
  }

  /// 디버그용: 저장된 모든 데이터 출력
  Future<void> debugPrintAllData() async {
    try {
      final alarms = await loadAlarms();
      print('\n=== 📊 저장된 알람 데이터 디버그 정보 ===');
      print('총 알람 개수: ${alarms.length}');

      for (int i = 0; i < alarms.length; i++) {
        final alarm = alarms[i];
        print('알람 ${i + 1}: ${alarm.toString()}');
      }

      final stats = await getStatistics();
      print('\n📈 통계:');
      print('• 활성 알람: ${stats['activeAlarms']}개');
      print('• 비활성 알람: ${stats['inactiveAlarms']}개');
      print('=====================================\n');
    } catch (e) {
      print('❌ 디버그 출력 오류: $e');
    }
  }

  /// 데이터 무결성 검사
  Future<bool> validateData() async {
    try {
      final alarms = await loadAlarms();
      bool hasErrors = false;

      for (final alarm in alarms) {
        // 기본 검증
        if (alarm.id.isEmpty) {
          print('❌ 무결성 오류: 빈 ID 발견');
          hasErrors = true;
        }

        if (alarm.startHour < 0 || alarm.startHour > 23) {
          print('❌ 무결성 오류: 잘못된 시작 시간 ${alarm.startHour}');
          hasErrors = true;
        }

        if (alarm.startMinute < 0 || alarm.startMinute > 59) {
          print('❌ 무결성 오류: 잘못된 시작 분 ${alarm.startMinute}');
          hasErrors = true;
        }

        if (alarm.selectedInterval <= 0) {
          print('❌ 무결성 오류: 잘못된 간격 ${alarm.selectedInterval}');
          hasErrors = true;
        }

        if (alarm.activeDays.length != 7) {
          print('❌ 무결성 오류: 잘못된 요일 배열 길이 ${alarm.activeDays.length}');
          hasErrors = true;
        }
      }

      if (!hasErrors) {
        print('✅ 데이터 무결성 검사 통과');
      }

      return !hasErrors;
    } catch (e) {
      print('❌ 데이터 무결성 검사 중 오류: $e');
      return false;
    }
  }
}