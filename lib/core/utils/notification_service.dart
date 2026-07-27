import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../features/habits/data/habit_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
    await _configureLocalTimeZone();
  }

  static Future<void> _configureLocalTimeZone() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  static const AndroidNotificationDetails _taskDetails =
      AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Reminders for task deadlines',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

  static const AndroidNotificationDetails _habitDetails =
      AndroidNotificationDetails(
        'habit_reminders',
        'Habit Reminders',
        channelDescription: 'Daily reminders for habits',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

  static const AndroidNotificationDetails _medicationDetails =
      AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Daily medication dose reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

  static const AndroidNotificationDetails _journalDetails =
      AndroidNotificationDetails(
        'journal_reminders',
        'Journal Reminders',
        channelDescription: 'Daily journal reflection reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

  static Future<void> scheduleTaskNotification({
    required int id,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    if (dueDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      '⚡ Task Due Now!',
      taskTitle,
      tz.TZDateTime.from(dueDate, tz.local),
      NotificationDetails(android: _taskDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelTaskNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required TimeOfDay reminderTime,
  }) async {
    final tz.TZDateTime scheduled = _nextInstanceOfTime(reminderTime);

    await _notifications.zonedSchedule(
      id,
      '🔥 Habit Reminder',
      "Don't break your streak! $habitName is waiting",
      scheduled,
      NotificationDetails(android: _habitDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleJournalReminder({
    required int id,
    required TimeOfDay reminderTime,
  }) async {
    final tz.TZDateTime scheduled = _nextInstanceOfTime(reminderTime);

    await _notifications.zonedSchedule(
      id,
      '📔 Journal time!',
      'How was your day? Take a moment to reflect.',
      scheduled,
      NotificationDetails(android: _journalDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleMedicationReminders(Habit habit) async {
    for (var i = 0; i < habit.medicationTimesOfDay.length; i++) {
      final reminderTime = habit.medicationTimesOfDay[i];
      final scheduled = _nextInstanceOfTime(reminderTime);

      await _notifications.zonedSchedule(
        medicationNotificationId(habit.id, i),
        '💊 Medication Reminder',
        '${habit.name}${habit.medicationDose != null ? ' — ${habit.medicationDose}' : ''}. Time to take your dose!',
        scheduled,
        NotificationDetails(android: _medicationDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static Future<void> cancelHabitReminder(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelJournalReminder(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelMedicationReminders(
    String habitId,
    int count,
  ) async {
    for (var i = 0; i < count; i++) {
      await _notifications.cancel(medicationNotificationId(habitId, i));
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static int taskNotificationId(String taskId) {
    return taskId.hashCode.abs();
  }

  static int habitNotificationId(String habitId) {
    return (habitId + '_habit').hashCode.abs();
  }

  static int medicationNotificationId(String habitId, int index) {
    return (habitId + '_med_$index').hashCode.abs();
  }
}
