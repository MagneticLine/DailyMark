import '../models/models.dart';
import 'base_repository.dart';

/// 标签记录Repository
/// 
/// 负责标签记录数据的持久化操作，包括CRUD和特定的查询方法
/// 支持按日期、标签、预测状态等多种条件查询
class TagRecordRepository extends BaseRepository<TagRecord> {
  @override
  String get tableName => 'tag_records';

  @override
  TagRecord fromMap(Map<String, dynamic> map) => TagRecord.fromMap(map);

  @override
  Map<String, dynamic> toMap(TagRecord entity) => entity.toMap();

  @override
  String getId(TagRecord entity) => entity.id;

  /// 根据标签ID查询记录
  Future<List<TagRecord>> findByTagId(String tagId) async {
    return await findWhere(
      where: 'tag_id = ?',
      whereArgs: [tagId],
      orderBy: 'date DESC',
    );
  }

  /// 根据日期查询记录
  Future<List<TagRecord>> findByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await findWhere(
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at ASC',
    );
  }

  /// 根据日期范围查询记录
  Future<List<TagRecord>> findByDateRange(DateTime startDate, DateTime endDate) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    return await findWhere(
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'date ASC, created_at ASC',
    );
  }

  /// 根据标签ID和日期查询记录
  Future<TagRecord?> findByTagIdAndDate(String tagId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final records = await findWhere(
      where: 'tag_id = ? AND date = ?',
      whereArgs: [tagId, dateStr],
      limit: 1,
    );
    
    return records.isNotEmpty ? records.first : null;
  }

  /// 查询预测记录
  Future<List<TagRecord>> findPredictions({
    String? tagId,
    DateTime? fromDate,
  }) async {
    String where = 'is_prediction = 1';
    List<Object?> whereArgs = [];
    
    if (tagId != null) {
      where += ' AND tag_id = ?';
      whereArgs.add(tagId);
    }
    
    if (fromDate != null) {
      final fromDateStr = fromDate.toIso8601String().split('T')[0];
      where += ' AND date >= ?';
      whereArgs.add(fromDateStr);
    }
    
    return await findWhere(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date ASC',
    );
  }

  /// 查询实际记录（非预测）
  Future<List<TagRecord>> findActualRecords({
    String? tagId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    String where = 'is_prediction = 0';
    List<Object?> whereArgs = [];
    
    if (tagId != null) {
      where += ' AND tag_id = ?';
      whereArgs.add(tagId);
    }
    
    if (fromDate != null) {
      final fromDateStr = fromDate.toIso8601String().split('T')[0];
      where += ' AND date >= ?';
      whereArgs.add(fromDateStr);
    }
    
    if (toDate != null) {
      final toDateStr = toDate.toIso8601String().split('T')[0];
      where += ' AND date <= ?';
      whereArgs.add(toDateStr);
    }
    
    return await findWhere(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date ASC',
    );
  }

  /// 获取标签的最新记录
  Future<TagRecord?> getLatestRecord(String tagId, {bool includePredicitions = false}) async {
    String where = 'tag_id = ?';
    List<Object?> whereArgs = [tagId];
    
    if (!includePredicitions) {
      where += ' AND is_prediction = 0';
    }
    
    final records = await findWhere(
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: 1,
    );
    
    return records.isNotEmpty ? records.first : null;
  }

  /// 获取标签的历史记录统计
  Future<Map<String, dynamic>> getTagStatistics(String tagId) async {
    final db = await database;
    
    // 总记录数
    final totalCount = await count(
      where: 'tag_id = ? AND is_prediction = 0',
      whereArgs: [tagId],
    );
    
    // 预测记录数
    final predictionCount = await count(
      where: 'tag_id = ? AND is_prediction = 1',
      whereArgs: [tagId],
    );
    
    // 最早和最晚记录日期
    final dateRange = await db.rawQuery('''
      SELECT MIN(date) as earliest_date, MAX(date) as latest_date
      FROM tag_records
      WHERE tag_id = ? AND is_prediction = 0
    ''', [tagId]);
    
    // 最近7天的记录数
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final sevenDaysAgoStr = sevenDaysAgo.toIso8601String().split('T')[0];
    final recentCount = await count(
      where: 'tag_id = ? AND is_prediction = 0 AND date >= ?',
      whereArgs: [tagId, sevenDaysAgoStr],
    );
    
    return {
      'total_records': totalCount,
      'prediction_records': predictionCount,
      'earliest_date': dateRange.first['earliest_date'],
      'latest_date': dateRange.first['latest_date'],
      'recent_7_days': recentCount,
    };
  }

  /// 删除指定日期之前的预测记录
  Future<int> deletePredictionsBefore(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await deleteWhere(
      where: 'is_prediction = 1 AND date < ?',
      whereArgs: [dateStr],
    );
  }

  /// 删除指定标签的所有预测记录
  Future<int> deleteTagPredictions(String tagId) async {
    return await deleteWhere(
      where: 'tag_id = ? AND is_prediction = 1',
      whereArgs: [tagId],
    );
  }

  /// 将预测记录转换为实际记录
  Future<int> convertPredictionToActual(String recordId, dynamic actualValue) async {
    final db = await database;
    return await db.update(
      tableName,
      {
        'value': _serializeValue(actualValue),
        'is_prediction': 0,
        'confidence': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND is_prediction = 1',
      whereArgs: [recordId],
    );
  }

  /// 序列化值用于存储
  static String _serializeValue(dynamic value) {
    if (value is List) {
      // 将列表转换为字符串格式存储
      return '[${value.map((item) => '"$item"').join(', ')}]';
    }
    return value.toString();
  }

  /// 批量插入记录（用于预测数据生成）
  Future<void> insertPredictions(List<TagRecord> predictions) async {
    if (predictions.isEmpty) return;
    
    // 确保所有记录都标记为预测
    final predictionRecords = predictions.map((record) => 
      record.copyWith(isPrediction: true)
    ).toList();
    
    await insertBatch(predictionRecords);
  }

  /// 获取指定时间段内的记录密度（每天的记录数量）
  Future<Map<String, int>> getRecordDensity(
    String tagId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final db = await database;
    final result = await db.rawQuery('''
      SELECT date, COUNT(*) as count
      FROM tag_records
      WHERE tag_id = ? AND is_prediction = 0 AND date >= ? AND date <= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [tagId, startDateStr, endDateStr]);
    
    final density = <String, int>{};
    for (final row in result) {
      density[row['date'] as String] = row['count'] as int;
    }
    
    return density;
  }

  /// 获取标签的数值趋势（仅适用于量化标签）
  Future<List<Map<String, dynamic>>> getNumericTrend(
    String tagId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final db = await database;
    return await db.rawQuery('''
      SELECT date, value, is_prediction
      FROM tag_records
      WHERE tag_id = ? AND date >= ? AND date <= ?
      ORDER BY date ASC
    ''', [tagId, startDateStr, endDateStr]);
  }

  /// 清理过期的预测记录（超过指定天数的预测）
  Future<int> cleanupExpiredPredictions({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final cutoffDateStr = cutoffDate.toIso8601String().split('T')[0];
    
    return await deleteWhere(
      where: 'is_prediction = 1 AND date < ?',
      whereArgs: [cutoffDateStr],
    );
  }
}