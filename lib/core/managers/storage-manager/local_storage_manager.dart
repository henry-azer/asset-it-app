import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'i_storage_manager.dart';

class LocalStorageManager extends IStorageManager {
  LocalStorageManager();

  Future<SharedPreferences> _prefs() async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<T?> getValue<T>(String key) async {
    String? value = (await _prefs()).getString(key);
    return value != null ? jsonDecode(value) : null;
  }

  @override
  Future setValue(String key, dynamic value) async {
    await (await _prefs()).setString(key, jsonEncode(value));
  }

  @override
  void removeValue(String key) {
    _prefs().then((SharedPreferences pref) => pref.remove(key));
  }

  @override
  void clearAll() {
    _prefs().then((SharedPreferences pref) => pref.clear());
  }

  @override
  Future<String?> getString(String key) async {
    return (await _prefs()).getString(key);
  }

  @override
  Future<bool?> getBool(String key) async {
    return (await _prefs()).getBool(key);
  }

  @override
  Future<int?> getInt(String key) async {
    return (await _prefs()).getInt(key);
  }

  @override
  Future<double?> getDouble(String key) async {
    return (await _prefs()).getDouble(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    return (await _prefs()).setString(key, value);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return (await _prefs()).setBool(key, value);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    return (await _prefs()).setInt(key, value);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    return (await _prefs()).setDouble(key, value);
  }
}
