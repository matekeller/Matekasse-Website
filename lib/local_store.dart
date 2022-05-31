import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:matemate/offering.dart';

class LocalStore {
  static Box? _box;
  static Future<void> init() async {
    _box = await Hive.openBox("LocalStore");
  }

  static String get authToken => _box!.get("authToken") ?? "";
  static set authToken(String authToken) {
    _box!.put("authToken", authToken);
  }

  static String get userName => _box!.get("userName") ?? "";
  static set userName(String userName) {
    _box!.put("userName", userName);
  }

  static String get password => _box!.get("password") ?? "";
  static set password(String password) {
    _box!.put("password", password);
  }

  static List<String> get failedTransactionRequests =>
      _box!.get("failedTransactionRequests") ?? [];
  static addFailedTransactionRequest(String body) {
    failedTransactionRequests.add(body);
    _box!.put("failedTransactionRequests", failedTransactionRequests);
  }

  static String get allUsersJson => _box!.get("allUsersJson") ?? "";
  static set allUsersJson(String allUsers) {
    _box!.put("allUsersJson", allUsers);
  }

  static List<Offering> get offerings => _box!.get("offerings") ?? <Offering>[];
  static set offerings(List<Offering> newOfferings) =>
      _box!.put("offerings", newOfferings);
}
