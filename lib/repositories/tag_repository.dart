import 'dart:convert';
import '../models/models.dart';
import 'base_repository.dart';

/// 标签Repository
/// 
/// 负责标签数据的持久化操作，包括CRUD和特定的查询方法
/// 继承自BaseRepository，获得通用的数据库操作能力
class TagRepository extends BaseRepository<Tag> {
  @override
  String get tableName => 'tags';

  @override
  Tag fromMap(Map<String, dynamic> map) {
    // 解析config字段（JSON字符串转Map）
    Map<String, dynamic> config = {};
    if (map['config'] != null && map['config'] is String) {
      try {
        config = json.decode(map['config'] as String);
      } catch (e) {
        // 如果解析失败，使用空配置
        config = {};
      }
    }

    return Tag.fromMap({
      ...map,
      'config': config,
    });
  }

  @override
  Map<String, dynamic> toMap(Tag entity) {
    final map = entity.toMap();
    // 将config字段序列化为JSON字符串
    map['config'] = json.encode(map['config']);
    return map;
  }

  @override
  String getId(Tag entity) => entity.id;

  /// 根据类型查询标签
  Future<List<Tag>> findByType(TagType type) async {
    return await findWhere(
      where: 'type = ? AND is_active = 1',
      whereArgs: [type.value],
      orderBy: 'created_at DESC',
    );
  }

  /// 查询所有激活的标签
  Future<List<Tag>> findActive() async {
    return await findWhere(
      where: 'is_active = 1',
      whereArgs: null,
      orderBy: 'created_at DESC',
    );
  }

  /// 根据名称查询标签（模糊匹配）
  Future<List<Tag>> findByName(String name) async {
    return await findWhere(
      where: 'name LIKE ? AND is_active = 1',
      whereArgs: ['%$name%'],
      orderBy: 'name ASC',
    );
  }

  /// 查询启用预测的标签
  Future<List<Tag>> findPredictionEnabled() async {
    return await findWhere(
      where: 'enable_prediction = 1 AND is_active = 1',
      whereArgs: null,
      orderBy: 'created_at DESC',
    );
  }

  /// 软删除标签（设置is_active为false）
  Future<int> softDelete(String id) async {
    final db = await database;
    return await db.update(
      tableName,
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 恢复软删除的标签
  Future<int> restore(String id) async {
    final db = await database;
    return await db.update(
      tableName,
      {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 检查标签名称是否已存在
  Future<bool> nameExists(String name, {String? excludeId}) async {
    String where = 'name = ? AND is_active = 1';
    List<Object?> whereArgs = [name];
    
    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final count = await this.count(where: where, whereArgs: whereArgs);
    return count > 0;
  }

  /// 获取标签统计信息
  Future<Map<String, int>> getTagStatistics() async {
    final db = await database;
    
    // 统计各类型标签数量
    final typeStats = await db.rawQuery('''
      SELECT type, COUNT(*) as count 
      FROM tags 
      WHERE is_active = 1 
      GROUP BY type
    ''');
    
    // 统计启用预测的标签数量
    final predictionCount = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM tags 
      WHERE enable_prediction = 1 AND is_active = 1
    ''');
    
    final result = <String, int>{};
    
    // 处理类型统计
    for (final row in typeStats) {
      result[row['type'] as String] = row['count'] as int;
    }
    
    // 添加预测标签统计
    result['prediction_enabled'] = predictionCount.first['count'] as int;
    
    return result;
  }

  /// 获取最近创建的标签
  Future<List<Tag>> getRecentTags({int limit = 10}) async {
    return await findWhere(
      where: 'is_active = 1',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  /// 获取最常使用的标签（基于记录数量）
  Future<List<Tag>> getMostUsedTags({int limit = 10}) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT t.*, COUNT(tr.id) as usage_count
      FROM tags t
      LEFT JOIN tag_records tr ON t.id = tr.tag_id
      WHERE t.is_active = 1
      GROUP BY t.id
      ORDER BY usage_count DESC, t.created_at DESC
      LIMIT ?
    ''', [limit]);
    
    return result.map((map) => fromMap(map)).toList();
  }

  /// 批量更新标签的updated_at字段
  Future<void> touchTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return;
    
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final batch = db.batch();
    for (final tagId in tagIds) {
      batch.update(
        tableName,
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [tagId],
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// 清理未使用的标签（没有任何记录的标签）
  Future<List<String>> findUnusedTags() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT t.id, t.name
      FROM tags t
      LEFT JOIN tag_records tr ON t.id = tr.tag_id
      WHERE t.is_active = 1 AND tr.id IS NULL
      ORDER BY t.created_at ASC
    ''');
    
    return result.map((row) => row['id'] as String).toList();
  }
}