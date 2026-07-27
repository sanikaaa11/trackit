import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 5)
class Habit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String icon;

  @HiveField(3)
  late String frequency;

  @HiveField(4)
  late List<int> targetDays;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  bool isArchived;

  @HiveField(7)
  String? reminderTime;

  @HiveField(8)
  bool isMedication;

  @HiveField(9)
  String? medicationDose;

  @HiveField(10)
  List<String> medicationTimes;

  Habit({
    required this.name,
    required this.icon,
    required this.frequency,
    required this.targetDays,
    required this.createdAt,
    this.isArchived = false,
    this.reminderTime,
    this.isMedication = false,
    this.medicationDose,
    List<String>? medicationTimes,
    String? id,
  }) : medicationTimes = medicationTimes ?? <String>[] {
    this.id = id ?? const Uuid().v4();
  }

  factory Habit.create({
    required String name,
    required String icon,
    required String frequency,
    List<int> targetDays = const [],
    String? reminderTime,
    bool isMedication = false,
    String? medicationDose,
    List<String> medicationTimes = const [],
  }) {
    return Habit(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      frequency: frequency,
      targetDays: List<int>.from(targetDays),
      createdAt: DateTime.now(),
      isArchived: false,
      reminderTime: reminderTime,
      isMedication: isMedication,
      medicationDose: medicationDose,
      medicationTimes: List<String>.from(medicationTimes),
    );
  }

  TimeOfDay? get reminderTimeOfDay {
    if (reminderTime == null) return null;
    try {
      final parts = reminderTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  List<TimeOfDay> get medicationTimesOfDay {
    return medicationTimes.map((time) {
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }).toList();
  }
}

@HiveType(typeId: 6)
class HabitLog extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String habitId;

  @HiveField(2)
  late String date;

  @HiveField(3)
  late bool isCompleted;

  @HiveField(4)
  late DateTime loggedAt;

  HabitLog({
    required this.habitId,
    required this.date,
    required this.isCompleted,
    required this.loggedAt,
    String? id,
  }) {
    this.id = id ?? '${habitId}_$date';
  }

  factory HabitLog.create({
    required String habitId,
    required String date,
    bool isCompleted = true,
  }) {
    return HabitLog(
      id: '${habitId}_$date',
      habitId: habitId,
      date: date,
      isCompleted: isCompleted,
      loggedAt: DateTime.now(),
    );
  }
}
