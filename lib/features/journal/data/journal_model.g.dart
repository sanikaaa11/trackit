// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalEntryAdapter extends TypeAdapter<JournalEntry> {
  @override
  final int typeId = 2;

  @override
  JournalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntry(
      date: fields[1] as String,
      mood: fields[2] as String,
      body: fields[3] as String,
      imagePaths: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      id: fields[0] as String?,
      moodScore: fields[7] as int?,
      emotionTags: (fields[8] as List?)?.cast<String>(),
      energyLevel: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntry obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.mood)
      ..writeByte(3)
      ..write(obj.body)
      ..writeByte(4)
      ..write(obj.imagePaths)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.moodScore)
      ..writeByte(8)
      ..write(obj.emotionTags)
      ..writeByte(9)
      ..write(obj.energyLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
