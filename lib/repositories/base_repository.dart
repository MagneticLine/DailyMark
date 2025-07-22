import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';

/// Repository基类
/// 
/// 提供通用的数据库操作方法，所有具体的Repository都继承自这个基类
/// 实现了基本的CRUD操作模板
abstract class BaseRepository<T> {
  /// 数据库服务实例
  final DatabaseService _databaseService = DatabaseService();

  /// 获取数据库连接
  Future<Database> get database => _databaseService.database;

  /// 表名（由子类实现）
  String get tableName;

  /// 从Map创建实体对象（由子类实现）
  T fromMap(Map<String, dynamic> map);

  /// 将实体对象转换为Map（由子类实现）
  Map<String, dynamic> toMap(T entity);

  /// 获取实体的ID（由子类实现）
  String getId(T entity);

  /// 插入单个实体
  Future<void> insert(T entity) async {
    final db = await database;
    await db.insert(
      tableName,
      toMap(entity),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量插入实体
  Future<void> insertBatch(List<T> entities) async {
    if (entities.isEmpty) return;
    
    final db = await database;
    final batch = db.batch();
    
    for (final entity in entities) {
      batch.insert(
        tableName,
        toMap(entity),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// 根据ID查询单个实体
  Future<T?> findById(String id) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  /// 查询所有实体
  Future<List<T>> findAll() async {
    final db = await database;
    final maps = await db.query(tableName);
    return maps.map((map) => fromMap(map)).toList();
  }

  /// 根据条件查询实体列表
  Future<List<T>> findWhere({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  /// 更新实体
  Future<int> update(T entity) async {
    final db = await database;
    return await db.update(
      tableName,
      toMap(entity),
      where: 'id = ?',
      whereArgs: [getId(entity)],
    );
  }

  /// 根据ID删除实体
  Future<int> deleteById(String id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根据条件删除实体
  Future<int> deleteWhere({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// 清空表
  Future<int> deleteAll() async {
    final db = await database;
    return await db.delete(tableName);
  }

  /// 统计记录数量
  Future<int> count({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    final result = await db.query(
      tableName,
      columns: ['COUNT(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );
    return result.first['count'] as int;
  }

  /// 检查实体是否存在
  Future<bool> exists(String id) async {
    final count = await this.count(
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// 执行原始SQL查询
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// 执行原始SQL命令
  Future<int> rawExecute(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
}