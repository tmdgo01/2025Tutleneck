// firebase_exercise_service.dart
// 기존 파일을 이 코드로 완전히 교체하세요

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseExerciseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 탭별 운동 목록 정의 (실제 앱의 데이터와 일치해야 함)
  static const Map<String, List<String>> tabExercises = {
    '일상 스트레칭': [
      '턱 당기기',
      '목 강화 운동1 (선 자세)',
      '목 강화 운동2',
      '목 스트레칭1(앉은 자세)',
      '목 스트레칭2(앉은 자세)',
      '좌,우 목 돌리기',
      '원 방향 목 돌리기',
    ],
    '증상 완화 운동': [
      '벽 밀기 (대흉근 스트레칭)',
      '가슴 스트레칭(소흉근 스트레칭)',
      '목 강화 운동1',
      'WYT 자세 운동',
      'Cat–Cow (척추 가동성 운동)',
    ],
    '폼롤러 운동': [
      '척추기립근 스트레칭',
      '뒤통수 아래 스트레칭 (후두 하근 스트레칭)',
      '폼롤러 체스트 오픈',
      '목 스트레칭',
      '등 전체 폼롤러 스트레칭',
      '소흉근 스트레칭',
    ],
  };

  /// 개별 운동 완료 기록을 Firebase에 저장하고 탭 완료 횟수 자동 업데이트
  static Future<void> saveIndividualExercise({
    required String exerciseName,
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
        final data = doc.data()!;
        final exerciseCompletions = data['exerciseCompletions'] as Map<String, dynamic>? ?? {};

        // 개별 운동 완료 횟수 증가
        final currentCount = exerciseCompletions[exerciseName] ?? 0;

        await docRef.update({
          'exerciseCompletions.$exerciseName': currentCount + 1,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // 새 문서 생성
        await docRef.set({
          'date': dateKey,
          'exerciseCompletions': {
            exerciseName: 1,
          },
          'completedTabs': {},
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // 탭 완료 횟수 재계산 및 업데이트
      await _updateTabCompletions(dateKey, user.uid);

      print('Firebase에 개별 운동 기록 저장 및 탭 완료 횟수 업데이트 완료: $exerciseName');
    } catch (e) {
      print('Firebase 개별 운동 기록 저장 실패: $e');
      rethrow;
    }
  }

  /// 탭 완료 횟수를 개별 운동 완료 횟수를 기반으로 자동 계산하여 업데이트
  static Future<void> _updateTabCompletions(String dateKey, String userId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('exercise_log')
          .doc(dateKey);

      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final exerciseCompletions = data['exerciseCompletions'] as Map<String, dynamic>? ?? {};

      Map<String, dynamic> completedTabs = {};

      // 각 탭별로 완료 횟수 계산
      for (final entry in tabExercises.entries) {
        final tabName = entry.key;
        final exercisesInTab = entry.value;

        // 해당 탭의 모든 운동 완료 횟수를 확인
        List<int> completionCounts = [];
        bool allExercisesCompleted = true;

        for (final exerciseName in exercisesInTab) {
          final count = exerciseCompletions[exerciseName] as int? ?? 0;
          if (count == 0) {
            allExercisesCompleted = false;
            break;
          }
          completionCounts.add(count);
        }

        // 모든 운동이 최소 1번씩 완료되었다면 탭 완료
        if (allExercisesCompleted && completionCounts.isNotEmpty) {
          // 탭 완료 횟수 = 가장 적게 완료한 운동의 횟수
          final tabCompletionCount = completionCounts.reduce((a, b) => a < b ? a : b);

          completedTabs[tabName] = {
            'exercises': exercisesInTab,
            'completedCount': tabCompletionCount,
            'lastUpdated': FieldValue.serverTimestamp(),
          };
        }
      }

      // 계산된 탭 완료 정보 업데이트
      await docRef.update({
        'completedTabs': completedTabs,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('탭 완료 횟수 자동 계산 완료');
    } catch (e) {
      print('탭 완료 횟수 계산 실패: $e');
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

  /// 특정 날짜의 개별 운동 완료 횟수 가져오기
  static Future<Map<String, int>> getExerciseCompletions(DateTime date) async {
    final logData = await getExerciseLogForDate(date);
    if (logData == null || logData['exerciseCompletions'] == null) {
      return {};
    }

    final Map<String, int> result = {};
    final exerciseCompletions = logData['exerciseCompletions'] as Map<String, dynamic>;

    for (final entry in exerciseCompletions.entries) {
      final exerciseName = entry.key;
      final count = entry.value as int? ?? 0;
      result[exerciseName] = count;
    }

    return result;
  }

  /// 특정 날짜의 탭 완료 횟수 가져오기 (자동 계산된 값)
  static Future<Map<String, int>> getTabCompletions(DateTime date) async {
    final logData = await getExerciseLogForDate(date);
    if (logData == null || logData['completedTabs'] == null) {
      return {};
    }

    final Map<String, int> result = {};
    final completedTabs = logData['completedTabs'] as Map<String, dynamic>;

    for (final entry in completedTabs.entries) {
      final tabName = entry.key;
      final tabData = entry.value as Map<String, dynamic>;
      final count = tabData['completedCount'] as int? ?? 0;
      result[tabName] = count;
    }

    return result;
  }

  /// 특정 날짜의 탭별 운동 완료 현황 가져오기 (상세 정보 포함)
  static Future<Map<String, Map<String, dynamic>>> getDetailedTabProgress(DateTime date) async {
    final logData = await getExerciseLogForDate(date);
    if (logData == null) {
      return {};
    }

    final exerciseCompletions = logData['exerciseCompletions'] as Map<String, dynamic>? ?? {};
    final completedTabs = logData['completedTabs'] as Map<String, dynamic>? ?? {};

    final Map<String, Map<String, dynamic>> result = {};

    for (final entry in tabExercises.entries) {
      final tabName = entry.key;
      final exercisesInTab = entry.value;

      // 각 운동의 완료 횟수
      Map<String, int> exerciseProgress = {};
      List<int> completionCounts = [];

      for (final exerciseName in exercisesInTab) {
        final count = exerciseCompletions[exerciseName] as int? ?? 0;
        exerciseProgress[exerciseName] = count;
        completionCounts.add(count);
      }

      // 탭 완료 횟수 계산
      final minCompletions = completionCounts.isEmpty ? 0 : completionCounts.reduce((a, b) => a < b ? a : b);
      final isTabCompleted = minCompletions > 0;

      result[tabName] = {
        'exerciseProgress': exerciseProgress,
        'tabCompletions': minCompletions,
        'isCompleted': isTabCompleted,
        'exercises': exercisesInTab,
        'totalExercises': exercisesInTab.length,
        'completedExercises': completionCounts.where((count) => count > 0).length,
      };
    }

    return result;
  }

  /// 특정 날짜의 완료된 탭과 운동 목록 반환 (기존 호환성 유지)
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

  /// 운동 기록이 있는 날짜들 가져오기 (캘린더 마커용)
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

  /// 사용자의 운동 통계 정보 가져오기 (개선된 버전)
  static Future<Map<String, dynamic>> getDetailedExerciseStats({
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
      int totalTabCompletions = 0;
      int totalExerciseCompletions = 0;
      Map<String, int> tabStats = {};
      Map<String, int> exerciseStats = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // 탭 완료 통계
        final completedTabs = data['completedTabs'] as Map<String, dynamic>? ?? {};
        for (final entry in completedTabs.entries) {
          final tabName = entry.key;
          final tabData = entry.value as Map<String, dynamic>;
          final count = tabData['completedCount'] as int? ?? 0;

          totalTabCompletions += count;
          tabStats[tabName] = (tabStats[tabName] ?? 0) + count;
        }

        // 개별 운동 완료 통계
        final exerciseCompletions = data['exerciseCompletions'] as Map<String, dynamic>? ?? {};
        for (final entry in exerciseCompletions.entries) {
          final exerciseName = entry.key;
          final count = entry.value as int? ?? 0;

          totalExerciseCompletions += count;
          exerciseStats[exerciseName] = (exerciseStats[exerciseName] ?? 0) + count;
        }
      }

      return {
        'totalDays': totalDays,
        'totalTabCompletions': totalTabCompletions,
        'totalExerciseCompletions': totalExerciseCompletions,
        'tabStats': tabStats,
        'exerciseStats': exerciseStats,
      };
    } catch (e) {
      print('상세 운동 통계 로딩 실패: $e');
      return {};
    }
  }

  /// 특정 운동의 완료 기록 삭제 (필요시 사용)
  static Future<void> removeExerciseCompletion({
    required String exerciseName,
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
        'exerciseCompletions.$exerciseName': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 탭 완료 횟수 재계산
      await _updateTabCompletions(dateKey, user.uid);

      print('개별 운동 기록 삭제 및 탭 완료 횟수 재계산 완료: $exerciseName');
    } catch (e) {
      print('개별 운동 기록 삭제 실패: $e');
      rethrow;
    }
  }

  /// 운동 탭 완료 기록을 Firebase에 저장 (탭 완료 버튼용 - 기존 호환성)
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

      // 탭의 모든 운동을 1번씩 완료 처리
      Map<String, dynamic> exerciseUpdates = {};
      for (final exerciseName in exerciseNames) {
        exerciseUpdates['exerciseCompletions.$exerciseName'] = FieldValue.increment(1);
      }

      // 기존 데이터 확인
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          ...exerciseUpdates,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // 새 문서 생성
        Map<String, int> initialExerciseCompletions = {};
        for (final exerciseName in exerciseNames) {
          initialExerciseCompletions[exerciseName] = 1;
        }

        await docRef.set({
          'date': dateKey,
          'exerciseCompletions': initialExerciseCompletions,
          'completedTabs': {},
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // 탭 완료 횟수 재계산
      await _updateTabCompletions(dateKey, user.uid);

      print('Firebase에 탭 완료 기록 저장 완료: $tabName');
    } catch (e) {
      print('Firebase 탭 완료 기록 저장 실패: $e');
      rethrow;
    }
  }
}