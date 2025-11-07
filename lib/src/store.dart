import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Store {
  static SharedPreferences? _prefs;
  static Future<Iterable<String>> keys({String? prefix}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final keys = _prefs!.getKeys();
    if (prefix == null) return keys;
    return keys.where((k) => k.startsWith(prefix));
  }

  static Future<bool> contains(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.containsKey(key);
  }

  static Future<void> clear() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.clear();
  }

  static Future<void> remove(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(key);
  }

  static Future<void> write(String key, dynamic json) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(key, jsonEncode(json));
  }

  static Future<dynamic> read(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    var content = _prefs!.getString(key);
    if (content != null) return jsonDecode(content);
    throw ArgumentError('key $key not found');
  }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
