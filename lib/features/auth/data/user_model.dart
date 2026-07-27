import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 7)
class UserModel extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String email;

  @HiveField(2)
  DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.createdAt,
  });
}
