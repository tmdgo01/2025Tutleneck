import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PostureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase에 자세 점수와 통계를 저장하는 함수
  Future<void> savePostureScore({
    required double score,
    required Map<String, int> stats,
  }) async {
    try {
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 총 프레임 수 계산
      final totalFrames = stats.values.fold(0, (prev, count) => prev + count);

      // 문서가 이미 존재하는지 확인
      final docRef = _firestore.collection('posture_daily').doc(dateKey);
      final doc = await docRef.get();

      if (doc.exists) {
        // 기존 데이터 업데이트
        await docRef.update({
          'score': score,
          'stats': stats,
          'totalFrames': totalFrames,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // 새 데이터 생성
        await docRef.set({
          'score': score,
          'stats': stats,
          'totalFrames': totalFrames,
          'date': dateKey,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('자세 점수 저장 완료: $score점, 총 프레임: $totalFrames');
    } catch (e) {
      debugPrint('자세 점수 저장 실패: $e');
    }
  }

  /// 특정 날짜의 자세 데이터를 가져오는 함수
  Future<Map<String, dynamic>?> getPostureData(DateTime date) async {
    try {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('posture_daily')
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
      final startDateKey = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateKey = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final querySnapshot = await _firestore
          .collection('posture_daily')
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
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return _firestore
        .collection('posture_daily')
        .doc(dateKey)
        .snapshots();
  }

  /// 자세 기록을 삭제하는 함수
  Future<void> deletePostureData(DateTime date) async {
    try {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('posture_daily')
          .doc(dateKey)
          .delete();

      debugPrint('자세 데이터 삭제 완료: $dateKey');
    } catch (e) {
      debugPrint('자세 데이터 삭제 실패: $e');
    }
  }

  /// 주간 평균 점수 계산
  Future<double> getWeeklyAverageScore() async {
    try {
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
      await _firestore.collection('posture_daily').limit(1).get();
      return true;
    } catch (e) {
      debugPrint('Firebase 연결 확인 실패: $e');
      return false;
    }
  }
}