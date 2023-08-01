import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String bluecardId;

  @HiveField(1)
  final List<String> smartcards;

  @HiveField(2)
  final String username;

  @HiveField(3)
  final String fullName;

  @HiveField(4)
  final int balanceCents;

  @HiveField(5)
  final bool isAdmin;

  const User(
      {required this.username,
      required this.fullName,
      required this.balanceCents,
      required this.bluecardId,
      required this.smartcards,
      required this.isAdmin});
}
