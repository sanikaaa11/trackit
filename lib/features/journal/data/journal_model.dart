import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'journal_model.g.dart';

@HiveType(typeId: 2)
class JournalEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String date;

  @HiveField(2)
  late String mood;

  @HiveField(3)
  late String body;

  @HiveField(4)
  late List<String> imagePaths;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  @HiveField(7)
  late int moodScore;

  @HiveField(8)
  late List<String> emotionTags;

  @HiveField(9)
  late String energyLevel;

  JournalEntry({
    required this.date,
    required this.mood,
    required this.body,
    required this.imagePaths,
    required this.createdAt,
    required this.updatedAt,
    String? id,
    int? moodScore,
    List<String>? emotionTags,
    String? energyLevel,
  }) {
    this.id = id ?? const Uuid().v4();
    this.moodScore = moodScore ?? 5;
    this.emotionTags = emotionTags ?? <String>[];
    this.energyLevel = energyLevel ?? 'Medium';
  }

  factory JournalEntry.create({
    required String date,
    String mood = 'Good',
    String body = '',
    List<String> imagePaths = const [],
    int moodScore = 5,
    List<String> emotionTags = const [],
    String energyLevel = 'Medium',
  }) {
    final now = DateTime.now();
    return JournalEntry(
      id: const Uuid().v4(),
      date: date,
      mood: mood,
      body: body,
      imagePaths: List<String>.from(imagePaths),
      moodScore: moodScore,
      emotionTags: List<String>.from(emotionTags),
      energyLevel: energyLevel,
      createdAt: now,
      updatedAt: now,
    );
  }
}
