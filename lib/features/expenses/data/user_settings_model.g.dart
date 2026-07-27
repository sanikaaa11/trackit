// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 4;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      monthlyBudget: fields[0] as double,
      userName: fields[1] as String,
      userEmoji: fields[2] as String,
      userVibe: fields[3] as int,
      hasCompletedOnboarding: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.monthlyBudget)
      ..writeByte(1)
      ..write(obj.userName)
      ..writeByte(2)
      ..write(obj.userEmoji)
      ..writeByte(3)
      ..write(obj.userVibe)
      ..writeByte(4)
      ..write(obj.hasCompletedOnboarding);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
