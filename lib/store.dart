import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Store {
  static late final SharedPreferences prefs;
  Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
  }

  static Future<Iterable<String>> keys({String? prefix}) async {
    final keys = prefs.getKeys();
    if (prefix == null) return keys;
    return keys.where((k) => k.startsWith(prefix));
  }

  static Future<bool> contains(String key) async {
    return prefs.containsKey(key);
  }

  static Future<void> clear() async {
    await prefs.clear();
  }

  static Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  static Future<void> write(String key, Map<String, dynamic> json) async {
    await prefs.setString(key, jsonEncode(json));
  }

  static Future<Map<String, dynamic>> read(String key) async {
    var content = prefs.getString(key);
    if (content != null) return jsonDecode(content);
    throw ArgumentError('key $key not found');
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
