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
}