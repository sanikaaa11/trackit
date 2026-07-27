import 'package:hive_flutter/hive_flutter.dart';

part 'user_settings_model.g.dart';

@HiveType(typeId: 4)
class UserSettings extends HiveObject {
  @HiveField(0)
  double monthlyBudget;

  @HiveField(1)
  String userName;

  @HiveField(2)
  String userEmoji;

  @HiveField(3)
  int userVibe;

  @HiveField(4)
  bool hasCompletedOnboarding;

  UserSettings({
    this.monthlyBudget = 0,
    this.userName = '',
    this.userEmoji = '🔥',
    this.userVibe = 0,
    this.hasCompletedOnboarding = false,
  });
}
