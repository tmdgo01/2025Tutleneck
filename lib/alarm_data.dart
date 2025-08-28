import 'package:flutter/material.dart';



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
    this.isAlarmEnabled =true,
    required this.createdAt,
    this.label,
  });
}