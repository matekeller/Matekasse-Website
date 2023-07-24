import 'package:hive/hive.dart';

part 'offering.g.dart';

@HiveType(typeId: 0)
class Offering {
  @HiveField(0)
  String name;

  @HiveField(1)
  String readableName;

  @HiveField(2)
  int priceCents;

  @HiveField(3)
  String imageUrl;

  @HiveField(5)
  int color;

  Offering(
      {required this.name,
      required this.readableName,
      required this.priceCents,
      required this.imageUrl,
      required this.color});
}
