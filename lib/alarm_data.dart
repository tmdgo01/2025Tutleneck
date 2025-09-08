import 'dart:convert';

class AlarmData {
  final String id;
  final List<bool> activeDays;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int selectedInterval;
  bool isAlarmEnabled;
  final DateTime createdAt;
  final String? label;

  AlarmData({
    required this.id,
    required this.activeDays,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.selectedInterval,
    this.isAlarmEnabled = true,
    required this.createdAt,
    this.label,
  });

  // SharedPreferences용 JSON 직렬화
  Map<String, dynamic> toJson() => {
    'id': id,
    'activeDays': activeDays,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'selectedInterval': selectedInterval,
    'isAlarmEnabled': isAlarmEnabled,
    'createdAt': createdAt.toIso8601String(),
    'label': label,
  };

  factory AlarmData.fromJson(Map<String, dynamic> json) {
    try {
      return AlarmData(
        id: json['id'] ?? '',
        activeDays: json['activeDays'] != null
            ? List<bool>.from(json['activeDays'])
            : List.generate(7, (_) => false),
        startHour: json['startHour'] ?? 9,
        startMinute: json['startMinute'] ?? 0,
        endHour: json['endHour'] ?? 18,
        endMinute: json['endMinute'] ?? 0,
        selectedInterval: json['selectedInterval'] ?? 1,
        isAlarmEnabled: json['isAlarmEnabled'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        label: json['label'],
      );
    } catch (e) {
      print('AlarmData fromJson 오류: $e');
      // 기본값으로 안전한 AlarmData 반환
      return AlarmData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        activeDays: List.generate(7, (_) => false),
        startHour: 9,
        startMinute: 0,
        endHour: 18,
        endMinute: 0,
        selectedInterval: 1,
        isAlarmEnabled: true,
        createdAt: DateTime.now(),
        label: null,
      );
    }
  }

  // Firestore용 Map 변환
  Map<String, dynamic> toMap() => {
    'id': id,
    'activeDays': activeDays,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'selectedInterval': selectedInterval,
    'isAlarmEnabled': isAlarmEnabled,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'label': label,
  };

  factory AlarmData.fromMap(Map<String, dynamic> map) => AlarmData(
    id: map['id'],
    activeDays: List<bool>.from(map['activeDays']),
    startHour: map['startHour'],
    startMinute: map['startMinute'],
    endHour: map['endHour'],
    endMinute: map['endMinute'],
    selectedInterval: map['selectedInterval'],
    isAlarmEnabled: map['isAlarmEnabled'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    label: map['label'],
  );

  // ========== 누락된 편의 메서드들 추가 ==========

  /// 시작 시간을 포맷팅된 문자열로 반환 (예: "오전 09:00")
  String get formattedStartTime => _formatTime(startHour, startMinute);

  /// 종료 시간을 포맷팅된 문자열로 반환 (예: "오후 06:00")
  String get formattedEndTime => _formatTime(endHour, endMinute);

  /// 활성 요일들을 문자열로 반환 (예: "월, 화, 수, 목, 금")
  String get activeDaysString {
    final dayLabels = ['일','월','화','수','목','금','토'];
    List<String> activeDayNames = [];
    for (int i = 0; i < activeDays.length; i++) {
      if (activeDays[i]) activeDayNames.add(dayLabels[i]);
    }
    return activeDayNames.join(', ');
  }

  /// 시간을 12시간 형식으로 포맷팅하는 내부 메서드
  String _formatTime(int hour, int minute) {
    String period = hour < 12 ? '오전' : '오후';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 다음 알람 시간까지의 시간을 계산
  Duration? getTimeUntilNextAlarm() {
    final now = DateTime.now();
    final currentWeekday = now.weekday % 7;

    // 오늘이 활성 요일인지 확인
    if (activeDays[currentWeekday]) {
      final startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
      final endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);

      // 오늘 시간 범위 내인지 확인
      if (now.isBefore(startTime)) {
        return startTime.difference(now);
      } else if (now.isBefore(endTime)) {
        // 현재 시간 범위 내 - 다음 간격까지의 시간 계산
        final currentMinutes = now.hour * 60 + now.minute;
        final startMinutes = startHour * 60 + startMinute;
        final minutesSinceStart = currentMinutes - startMinutes;
        final intervalMinutes = selectedInterval * 60;
        final nextIntervalMinutes = ((minutesSinceStart ~/ intervalMinutes) + 1) * intervalMinutes;
        final nextTotalMinutes = startMinutes + nextIntervalMinutes;

        if (nextTotalMinutes <= endHour * 60 + endMinute) {
          final nextHour = nextTotalMinutes ~/ 60;
          final nextMinute = nextTotalMinutes % 60;
          final nextAlarmTime = DateTime(now.year, now.month, now.day, nextHour, nextMinute);
          return nextAlarmTime.difference(now);
        }
      }
    }

    // 다음 활성 요일 찾기
    for (int i = 1; i <= 7; i++) {
      final checkDay = (currentWeekday + i) % 7;
      if (activeDays[checkDay]) {
        final targetDate = now.add(Duration(days: i));
        final nextAlarmTime = DateTime(targetDate.year, targetDate.month, targetDate.day, startHour, startMinute);
        return nextAlarmTime.difference(now);
      }
    }

    return null; // 활성 요일이 없음
  }

  /// 알람이 현재 활성 시간 범위인지 확인
  bool get isInActiveTimeRange {
    final now = DateTime.now();
    final currentWeekday = now.weekday % 7;

    // 오늘이 활성 요일이 아니면 false
    if (!activeDays[currentWeekday]) {
      return false;
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  /// 알람 요약 정보 반환
  String get summary {
    final statusText = isAlarmEnabled ? "활성" : "비활성";
    final timeRange = "$formattedStartTime ~ $formattedEndTime";
    final intervalText = "${selectedInterval}시간 간격";

    return "$statusText | $timeRange | $intervalText | $activeDaysString";
  }

  @override
  String toString() {
    return 'AlarmData(id: $id, label: ${label ?? "무제"}, time: $formattedStartTime~$formattedEndTime, interval: ${selectedInterval}h, enabled: $isAlarmEnabled, days: $activeDaysString)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AlarmData &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}