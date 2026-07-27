// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 5;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      name: fields[1] as String,
      icon: fields[2] as String,
      frequency: fields[3] as String,
      targetDays: (fields[4] as List).cast<int>(),
      createdAt: fields[5] as DateTime,
      isArchived: fields[6] as bool,
      reminderTime: fields[7] as String?,
      isMedication: fields[8] as bool,
      medicationDose: fields[9] as String?,
      medicationTimes: (fields[10] as List?)?.cast<String>(),
      id: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.targetDays)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isArchived)
      ..writeByte(7)
      ..write(obj.reminderTime)
      ..writeByte(8)
      ..write(obj.isMedication)
      ..writeByte(9)
      ..write(obj.medicationDose)
      ..writeByte(10)
      ..write(obj.medicationTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitLogAdapter extends TypeAdapter<HabitLog> {
  @override
  final int typeId = 6;

  @override
  HabitLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLog(
      habitId: fields[1] as String,
      date: fields[2] as String,
      isCompleted: fields[3] as bool,
      loggedAt: fields[4] as DateTime,
      id: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.loggedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
