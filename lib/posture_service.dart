import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostureService {
  static final PostureService _instance = PostureService._internal();
  factory PostureService() => _instance;
  PostureService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 사용자의 자세 점수 저장
  Future<void> savePostureScore({
    required double score,
    required Map<String, int> stats,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('postureData')
          .doc('latest')
          .set({
        'score': score,
        'stats': stats,
        'lastUpdated': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD 형태
      });

      print('자세 점수 저장됨: ${score.toStringAsFixed(1)}점');
    } catch (e) {
      print('자세 점수 저장 실패: $e');
    }
  }

  /// 현재 사용자의 최신 자세 점수 가져오기
  Future<double> getLatestPostureScore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('postureData')
          .doc('latest')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return (data['score'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e) {
      print('자세 점수 불러오기 실패: $e');
    }
    return 0.0;
  }

  /// 자세 점수 실시간 스트림
  Stream<double> getPostureScoreStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0.0);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('postureData')
        .doc('latest')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return (data['score'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    });
  }

  /// 일별 자세 기록 저장 (히스토리 용도)
  Future<void> saveDailyPostureRecord({
    required double averageScore,
    required Map<String, int> dailyStats,
    required int totalMinutes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('postureHistory')
          .doc(today)
          .set({
        'date': today,
        'averageScore': averageScore,
        'stats': dailyStats,
        'totalMinutes': totalMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('일별 자세 기록 저장됨: $today - ${averageScore.toStringAsFixed(1)}점');
    } catch (e) {
      print('일별 자세 기록 저장 실패: $e');
    }
  }

  /// 최근 7일 자세 점수 평균 가져오기
  Future<double> getWeeklyAverageScore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final sevenDaysAgoStr = sevenDaysAgo.toIso8601String().split('T')[0];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('postureHistory')
          .where('date', isGreaterThanOrEqualTo: sevenDaysAgoStr)
          .orderBy('date', descending: true)
          .limit(7)
          .get();

      if (querySnapshot.docs.isEmpty) return 0.0;

      double totalScore = 0.0;
      int count = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final score = (data['averageScore'] as num?)?.toDouble();
        if (score != null) {
          totalScore += score;
          count++;
        }
      }

      return count > 0 ? totalScore / count : 0.0;
    } catch (e) {
      print('주간 평균 점수 계산 실패: $e');
      return 0.0;
    }
  }
}