import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'note_model.g.dart';

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String body;

  @HiveField(3)
  late String colorLabel;

  @HiveField(4)
  late bool isPinned;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  Note({
    required this.title,
    this.body = '',
    this.colorLabel = '#1A1A1A',
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    String? id,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  factory Note.create({
    required String title,
    String body = '',
    String colorLabel = '#1A1A1A',
  }) {
    final now = DateTime.now();
    return Note(
      id: const Uuid().v4(),
      title: title,
      body: body,
      colorLabel: colorLabel,
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
