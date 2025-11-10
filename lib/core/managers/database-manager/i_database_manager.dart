abstract class IDatabaseManager {
  Future<void> init();
  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit});
  Future<int> insert(String table, Map<String, dynamic> data);
  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs});
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});
  Future<void> close();
}
