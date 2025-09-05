// firebase_exercise_service.dart
// 이 파일을 프로젝트의 lib 폴더에 새로 생성하세요

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseExerciseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 운동 완료 기록을 Firebase에 저장
  /// 각 탭의 마지막 운동 완료 시 호출됩니다
  static Future<void> saveCompletedTab({
    required String tabName,
    required List<String> exerciseNames,
    required DateTime date,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('사용자가 로그인되지 않음');
        return;
      }

      final dateKey = _formatDate(date);
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_log')
          .doc(dateKey);

      // 기존 데이터 확인
      final doc = await docRef.get();

      if (doc.exists) {
        // 기존 데이터에 추가
        await docRef.update({
          'completedTabs.$tabName': {
            'exercises': exerciseNames,
            'completedAt': FieldValue.serverTimestamp(),
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // 새 문서 생성
        await docRef.set({
          'date': dateKey,
          'completedTabs': {
            tabName: {
              'exercises': exerciseNames,
              'completedAt': FieldValue.serverTimestamp(),
            }
          },
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      print('Firebase에 운동 기록 저장 완료: $tabName');
    } catch (e) {
      print('Firebase 운동 기록 저장 실패: $e');
      rethrow;
    }
  }

  /// 특정 날짜의 운동 기록 가져오기
  static Future<Map<String, dynamic>?> getExerciseLogForDate(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('사용자가 로그인되지 않음');
        return null;
      }

      final dateKey = _formatDate(date);
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_log')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        print('Firebase에서 운동 기록 로드 완료: $dateKey');
        return doc.data();
      } else {
        print('해당 날짜의 운동 기록 없음: $dateKey');
        return null;
      }
    } catch (e) {
      print('Firebase 운동 기록 로딩 실패: $e');
      return null;
    }
  }

  /// 운동 기록이 있는 날짜들 가져오기 (캘린더 마커용)
  /// 특정 월의 운동한 날짜들을 반환합니다
  static Future<List<String>> getExerciseDates({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('사용자가 로그인되지 않음');
        return [];
      }

      final startKey = _formatDate(startDate);
      final endKey = _formatDate(endDate);

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_log')
          .where('date', isGreaterThanOrEqualTo: startKey)
          .where('date', isLessThanOrEqualTo: endKey)
          .get();

      final dates = querySnapshot.docs.map((doc) => doc.id).toList();
      print('운동 날짜 로드 완료: ${dates.length}개 날짜');
      return dates;
    } catch (e) {
      print('운동 날짜 로딩 실패: $e');
      return [];
    }
  }

  /// 날짜를 Firebase 문서 ID 형식으로 포맷팅 (yyyy-MM-dd)
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 특정 날짜의 완료된 탭과 운동 목록 반환
  /// DailyScreen에서 운동 기록을 표시할 때 사용됩니다
  static Future<Map<String, List<String>>> getCompletedExercises(DateTime date) async {
    final logData = await getExerciseLogForDate(date);
    if (logData == null || logData['completedTabs'] == null) {
      return {};
    }

    final Map<String, List<String>> result = {};
    final completedTabs = logData['completedTabs'] as Map<String, dynamic>;

    for (final entry in completedTabs.entries) {
      final tabName = entry.key;
      final tabData = entry.value as Map<String, dynamic>;
      final exercises = List<String>.from(tabData['exercises'] ?? []);
      result[tabName] = exercises;
    }

    return result;
  }

  /// 사용자의 운동 통계 정보 가져오기 (선택적 기능)
  static Future<Map<String, int>> getExerciseStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final startKey = _formatDate(startDate);
      final endKey = _formatDate(endDate);

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_log')
          .where('date', isGreaterThanOrEqualTo: startKey)
          .where('date', isLessThanOrEqualTo: endKey)
          .get();

      int totalDays = querySnapshot.docs.length;
      int totalTabs = 0;
      int totalExercises = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final completedTabs = data['completedTabs'] as Map<String, dynamic>? ?? {};

        totalTabs += completedTabs.length;

        for (final tabData in completedTabs.values) {
          final exercises = (tabData as Map<String, dynamic>)['exercises'] as List? ?? [];
          totalExercises += exercises.length;
        }
      }

      return {
        'totalDays': totalDays,
        'totalTabs': totalTabs,
        'totalExercises': totalExercises,
      };
    } catch (e) {
      print('운동 통계 로딩 실패: $e');
      return {};
    }
  }

  /// 특정 탭의 완료 기록 삭제 (필요시 사용)
  static Future<void> removeCompletedTab({
    required String tabName,
    required DateTime date,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dateKey = _formatDate(date);
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_log')
          .doc(dateKey);

      await docRef.update({
        'completedTabs.$tabName': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('운동 기록 삭제 완료: $tabName');
    } catch (e) {
      print('운동 기록 삭제 실패: $e');
      rethrow;
    }
  }
}