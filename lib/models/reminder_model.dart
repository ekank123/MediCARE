import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show BuildContext;

class ReminderModel {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<TimeOfDay> times;
  final List<bool> daysOfWeek; // 7 booleans for each day (Monday-Sunday)
  final bool isActive;
  final String? medicineImageUrl;
  final String? scanId; // Reference to the scan that prompted this reminder

  ReminderModel({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.times,
    required this.daysOfWeek,
    required this.isActive,
    this.medicineImageUrl,
    this.scanId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'times': times.map((time) => '${time.hour}:${time.minute}').toList(),
      'daysOfWeek': _boolListToIntList(daysOfWeek),
      'isActive': isActive,
      'medicineImageUrl': medicineImageUrl,
      'scanId': scanId,
    };
  }
  
  // Convert bool list to int list for storage
  List<int> _boolListToIntList(List<bool> boolList) {
    List<int> result = [];
    for (int i = 0; i < boolList.length; i++) {
      if (boolList[i]) {
        result.add(i);
      }
    }
    return result;
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    // Convert the stored int list to a bool list of 7 days
    List<int> daysIndexes = List<int>.from(map['daysOfWeek'] ?? []);
    List<bool> daysOfWeek = List.generate(7, (index) => daysIndexes.contains(index));
    
    return ReminderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : DateTime.now().add(const Duration(days: 30)),
      times: List<String>.from(map['times'] ?? [])
          .map((timeStr) {
            final parts = timeStr.split(':');
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          })
          .toList(),
      daysOfWeek: daysOfWeek,
      isActive: map['isActive'] ?? true,
      medicineImageUrl: map['medicineImageUrl'],
      scanId: map['scanId'],
    );
  }
  
  // Add copyWith method to create a copy with modified fields
  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<TimeOfDay>? times,
    List<bool>? daysOfWeek,
    bool? isActive,
    String? medicineImageUrl,
    String? scanId,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      times: times ?? this.times,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      medicineImageUrl: medicineImageUrl ?? this.medicineImageUrl,
      scanId: scanId ?? this.scanId,
    );
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() {
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }

  String format(BuildContext context) {
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }
}