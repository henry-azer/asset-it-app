abstract class IStorageManager {
  Future<T?> getValue<T>(String key);
  Future setValue(String key, dynamic value);
  void removeValue(String key);
  void clearAll();
  
  Future<String?> getString(String key);
  Future<bool?> getBool(String key);
  Future<int?> getInt(String key);
  Future<double?> getDouble(String key);
  
  Future<bool> setString(String key, String value);
  Future<bool> setBool(String key, bool value);
  Future<bool> setInt(String key, int value);
  Future<bool> setDouble(String key, double value);
}
