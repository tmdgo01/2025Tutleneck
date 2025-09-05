import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PostureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 사용자 UID 가져오기
  String? get _currentUserId => _auth.currentUser?.uid;

  /// 사용자별 컬렉션 경로 생성
  String get _userPostureCollection {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('사용자가 로그인되어 있지 않습니다.');
    }
    return 'users/$userId/posture_daily';
  }

  /// 오늘의 기존 통계를 불러오는 함수 (앱 시작시 사용)
  Future<Map<String, int>> getTodayStats() async {
    try {
      if (_currentUserId == null) {
        debugPrint('사용자가 로그인되어 있지 않음');
        return {"정상": 0, "위험": 0, "심각": 0};
      }

      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection(_userPostureCollection)
          .doc(dateKey)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final stats = data['stats'] as Map<String, dynamic>?;

        if (stats != null) {
          return {
            "정상": (stats['정상'] as num?)?.toInt() ?? 0,
            "위험": (stats['위험'] as num?)?.toInt() ?? 0,
            "심각": (stats['심각'] as num?)?.toInt() ?? 0,
          };
        }
      }

      // 오늘 데이터가 없으면 0부터 시작
      return {"정상": 0, "위험": 0, "심각": 0};
    } catch (e) {
      debugPrint('오늘 통계 로딩 실패: $e');
      return {"정상": 0, "위험": 0, "심각": 0};
    }
  }

  /// Firebase에 자세 점수와 통계를 저장하는 함수
  Future<void> savePostureScore({
    required double score,
    required Map<String, int> stats,
  }) async {
    try {
      if (_currentUserId == null) {
        debugPrint('사용자가 로그인되어 있지 않음 - 데이터 저장 불가');
        return;
      }

      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 총 프레임 수 계산
      final totalFrames = stats.values.fold(0, (prev, count) => prev + count);

      // 문서가 이미 존재하는지 확인
      final docRef = _firestore.collection(_userPostureCollection).doc(dateKey);
      final doc = await docRef.get();

      if (doc.exists) {
        // 기존 데이터 업데이트
        await docRef.update({
          'score': score,
          'stats': stats,
          'totalFrames': totalFrames,
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': _currentUserId, // 사용자 ID 추가 (중복 확인용)
        });
      } else {
        // 새 데이터 생성
        await docRef.set({
          'score': score,
          'stats': stats,
          'totalFrames': totalFrames,
          'date': dateKey,
          'userId': _currentUserId, // 사용자 ID 추가
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('자세 점수 저장 완료: $score점, 총 프레임: $totalFrames (사용자: $_currentUserId)');
    } catch (e) {
      debugPrint('자세 점수 저장 실패: $e');
      rethrow; // 에러를 다시 던져서 UI에서 처리할 수 있도록 함
    }
  }

  /// 특정 날짜의 자세 데이터를 가져오는 함수
  Future<Map<String, dynamic>?> getPostureData(DateTime date) async {
    try {
      if (_currentUserId == null) {
        debugPrint('사용자가 로그인되어 있지 않음');
        return null;
      }

      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection(_userPostureCollection)
          .doc(dateKey)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('자세 데이터 로딩 실패: $e');
      return null;
    }
  }

  /// 특정 기간의 자세 데이터를 가져오는 함수
  Future<List<Map<String, dynamic>>> getPostureDataRange(
      DateTime startDate,
      DateTime endDate
      ) async {
    try {
      if (_currentUserId == null) {
        debugPrint('사용자가 로그인되어 있지 않음');
        return [];
      }

      final startDateKey = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateKey = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final querySnapshot = await _firestore
          .collection(_userPostureCollection)
          .where('date', isGreaterThanOrEqualTo: startDateKey)
          .where('date', isLessThanOrEqualTo: endDateKey)
          .orderBy('date')
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('자세 데이터 범위 로딩 실패: $e');
      return [];
    }
  }

  /// 오늘의 자세 점수를 실시간으로 스트림으로 받는 함수
  Stream<DocumentSnapshot<Map<String, dynamic>>> getTodayPostureStream() {
    if (_currentUserId == null) {
      // 빈 스트림 반환
      return const Stream.empty();
    }

    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection(_userPostureCollection)
        .doc(dateKey)
        .snapshots();
  }

  /// 자세 기록을 삭제하는 함수
  Future<void> deletePostureData(DateTime date) async {
    try {
      if (_currentUserId == null) {
        debugPrint('사용자가 로그인되어 있지 않음');
        return;
      }

      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection(_userPostureCollection)
          .doc(dateKey)
          .delete();

      debugPrint('자세 데이터 삭제 완료: $dateKey (사용자: $_currentUserId)');
    } catch (e) {
      debugPrint('자세 데이터 삭제 실패: $e');
    }
  }

  /// 주간 평균 점수 계산
  Future<double> getWeeklyAverageScore() async {
    try {
      if (_currentUserId == null) {
        debugPrint('사용자가 로그인되어 있지 않음');
        return 0.0;
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final weeklyData = await getPostureDataRange(weekStart, weekEnd);

      if (weeklyData.isEmpty) return 0.0;

      final totalScore = weeklyData
          .map((data) => (data['score'] as num?)?.toDouble() ?? 0.0)
          .fold(0.0, (prev, score) => prev + score);

      return totalScore / weeklyData.length;
    } catch (e) {
      debugPrint('주간 평균 점수 계산 실패: $e');
      return 0.0;
    }
  }

  /// 월간 평균 점수 계산
  Future<double> getMonthlyAverageScore() async {
    try {
      if (_currentUserId == null) {
        debugPrint('사용자가 로그인되어 있지 않음');
        return 0.0;
      }

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final monthlyData = await getPostureDataRange(monthStart, monthEnd);

      if (monthlyData.isEmpty) return 0.0;

      final totalScore = monthlyData
          .map((data) => (data['score'] as num?)?.toDouble() ?? 0.0)
          .fold(0.0, (prev, score) => prev + score);

      return totalScore / monthlyData.length;
    } catch (e) {
      debugPrint('월간 평균 점수 계산 실패: $e');
      return 0.0;
    }
  }

  /// 스트림에서 안전하게 점수를 추출하는 헬퍼 함수
  double extractScoreFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    try {
      if (!snapshot.exists || snapshot.data() == null) {
        return 0.0;
      }

      final data = snapshot.data()!;
      final score = data['score'];

      if (score == null) return 0.0;

      if (score is num) {
        return score.toDouble();
      }

      return 0.0;
    } catch (e) {
      debugPrint('점수 추출 오류: $e');
      return 0.0;
    }
  }

  /// 스트림에서 안전하게 통계를 추출하는 헬퍼 함수
  Map<String, int> extractStatsFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    try {
      if (!snapshot.exists || snapshot.data() == null) {
        return {"정상": 0, "위험": 0, "심각": 0};
      }

      final data = snapshot.data()!;
      final stats = data['stats'] as Map<String, dynamic>?;

      if (stats == null) {
        return {"정상": 0, "위험": 0, "심각": 0};
      }

      return {
        "정상": (stats['정상'] as num?)?.toInt() ?? 0,
        "위험": (stats['위험'] as num?)?.toInt() ?? 0,
        "심각": (stats['심각'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      debugPrint('통계 추출 오류: $e');
      return {"정상": 0, "위험": 0, "심각": 0};
    }
  }

  /// 스트림 연결 상태를 확인하는 함수
  Future<bool> checkFirebaseConnection() async {
    try {
      if (_currentUserId == null) {
        return false;
      }

      await _firestore.collection(_userPostureCollection).limit(1).get();
      return true;
    } catch (e) {
      debugPrint('Firebase 연결 확인 실패: $e');
      return false;
    }
  }

  /// 사용자 데이터 초기화 (새 사용자일 때)
  Future<void> initializeUserData() async {
    try {
      if (_currentUserId == null) {
        debugPrint('사용자가 로그인되어 있지 않음');
        return;
      }

      // 사용자 프로필 문서 생성 (이미 있으면 무시)
      final userDocRef = _firestore.collection('users').doc(_currentUserId);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await userDocRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        debugPrint('새 사용자 데이터 초기화 완료: $_currentUserId');
      } else {
        // 기존 사용자 - 마지막 로그인 시간 업데이트
        await userDocRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('사용자 데이터 초기화 실패: $e');
    }
  }

  /// 사용자 로그아웃 시 로컬 캐시 정리
  void clearUserData() {
    debugPrint('사용자 데이터 캐시 정리');
    // 필요시 로컬 캐시나 상태 정리 로직 추가
  }
}