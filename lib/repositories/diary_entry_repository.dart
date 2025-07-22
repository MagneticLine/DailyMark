import '../models/models.dart';
import 'base_repository.dart';

/// 日记条目Repository
/// 
/// 负责日记条目数据的持久化操作，包括CRUD和特定的查询方法
/// 处理日记内容、多媒体附件和标签记录的关联
class DiaryEntryRepository extends BaseRepository<DiaryEntry> {
  @override
  String get tableName => 'diary_entries';

  @override
  DiaryEntry fromMap(Map<String, dynamic> map) => DiaryEntry.fromMap(map);

  @override
  Map<String, dynamic> toMap(DiaryEntry entity) => entity.toMap();

  @override
  String getId(DiaryEntry entity) => entity.id;

  /// 根据日期查询日记条目
  Future<DiaryEntry?> findByDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final entries = await findWhere(
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    
    return entries.isNotEmpty ? entries.first : null;
  }

  /// 根据日期范围查询日记条目
  Future<List<DiaryEntry>> findByDateRange(DateTime startDate, DateTime endDate) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    return await findWhere(
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'date DESC',
    );
  }

  /// 搜索日记内容
  Future<List<DiaryEntry>> searchContent(String keyword) async {
    return await findWhere(
      where: 'content LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'date DESC',
    );
  }

  /// 根据心情评分查询日记
  Future<List<DiaryEntry>> findByMoodScore(int moodScore) async {
    return await findWhere(
      where: 'mood_score = ?',
      whereArgs: [moodScore],
      orderBy: 'date DESC',
    );
  }

  /// 根据心情评分范围查询日记
  Future<List<DiaryEntry>> findByMoodRange(int minScore, int maxScore) async {
    return await findWhere(
      where: 'mood_score >= ? AND mood_score <= ?',
      whereArgs: [minScore, maxScore],
      orderBy: 'date DESC',
    );
  }

  /// 查询有附件的日记条目
  Future<List<DiaryEntry>> findWithAttachments() async {
    return await findWhere(
      where: 'attachments IS NOT NULL AND attachments != ""',
      orderBy: 'date DESC',
    );
  }

  /// 查询最近的日记条目
  Future<List<DiaryEntry>> getRecentEntries({int limit = 10}) async {
    return await findWhere(
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  /// 获取日记统计信息
  Future<Map<String, dynamic>> getDiaryStatistics() async {
    final db = await database;
    
    // 总日记数量
    final totalCount = await count();
    
    // 有内容的日记数量
    final contentCount = await count(
      where: 'content IS NOT NULL AND content != ""',
    );
    
    // 有附件的日记数量
    final attachmentCount = await count(
      where: 'attachments IS NOT NULL AND attachments != ""',
    );
    
    // 有心情评分的日记数量
    final moodCount = await count(
      where: 'mood_score IS NOT NULL',
    );
    
    // 最早和最晚日记日期
    final dateRange = await db.rawQuery('''
      SELECT MIN(date) as earliest_date, MAX(date) as latest_date
      FROM diary_entries
    ''');
    
    // 平均心情评分
    final avgMood = await db.rawQuery('''
      SELECT AVG(mood_score) as avg_mood
      FROM diary_entries
      WHERE mood_score IS NOT NULL
    ''');
    
    // 最近7天的日记数量
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final sevenDaysAgoStr = sevenDaysAgo.toIso8601String().split('T')[0];
    final recentCount = await count(
      where: 'date >= ?',
      whereArgs: [sevenDaysAgoStr],
    );
    
    return {
      'total_entries': totalCount,
      'entries_with_content': contentCount,
      'entries_with_attachments': attachmentCount,
      'entries_with_mood': moodCount,
      'earliest_date': dateRange.first['earliest_date'],
      'latest_date': dateRange.first['latest_date'],
      'average_mood': avgMood.first['avg_mood'],
      'recent_7_days': recentCount,
    };
  }

  /// 获取心情评分分布
  Future<Map<int, int>> getMoodDistribution() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT mood_score, COUNT(*) as count
      FROM diary_entries
      WHERE mood_score IS NOT NULL
      GROUP BY mood_score
      ORDER BY mood_score ASC
    ''');
    
    final distribution = <int, int>{};
    for (final row in result) {
      distribution[row['mood_score'] as int] = row['count'] as int;
    }
    
    return distribution;
  }

  /// 获取写日记的频率统计（按月份）
  Future<Map<String, int>> getMonthlyFrequency() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', date) as month, COUNT(*) as count
      FROM diary_entries
      GROUP BY month
      ORDER BY month ASC
    ''');
    
    final frequency = <String, int>{};
    for (final row in result) {
      frequency[row['month'] as String] = row['count'] as int;
    }
    
    return frequency;
  }

  /// 获取写日记的频率统计（按星期几）
  Future<Map<int, int>> getWeekdayFrequency() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%w', date) as weekday, COUNT(*) as count
      FROM diary_entries
      GROUP BY weekday
      ORDER BY weekday ASC
    ''');
    
    final frequency = <int, int>{};
    for (final row in result) {
      // SQLite的%w返回0-6，0是周日
      frequency[row['weekday'] as int] = row['count'] as int;
    }
    
    return frequency;
  }

  /// 查找包含特定标签记录的日记
  Future<List<DiaryEntry>> findByTagRecordId(String tagRecordId) async {
    return await findWhere(
      where: 'tag_record_ids LIKE ?',
      whereArgs: ['%$tagRecordId%'],
      orderBy: 'date DESC',
    );
  }

  /// 更新日记的标签记录关联
  Future<int> updateTagRecordIds(String diaryId, List<String> tagRecordIds) async {
    final db = await database;
    return await db.update(
      tableName,
      {
        'tag_record_ids': tagRecordIds.join(','),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [diaryId],
    );
  }

  /// 添加标签记录关联到日记
  Future<int> addTagRecordId(String diaryId, String tagRecordId) async {
    final diary = await findById(diaryId);
    if (diary == null) return 0;
    
    final currentIds = diary.tagRecordIds.toList();
    if (!currentIds.contains(tagRecordId)) {
      currentIds.add(tagRecordId);
      return await updateTagRecordIds(diaryId, currentIds);
    }
    
    return 0;
  }

  /// 从日记中移除标签记录关联
  Future<int> removeTagRecordId(String diaryId, String tagRecordId) async {
    final diary = await findById(diaryId);
    if (diary == null) return 0;
    
    final currentIds = diary.tagRecordIds.toList();
    if (currentIds.remove(tagRecordId)) {
      return await updateTagRecordIds(diaryId, currentIds);
    }
    
    return 0;
  }

  /// 获取指定日期范围内的内容长度统计
  Future<Map<String, dynamic>> getContentLengthStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        AVG(LENGTH(content)) as avg_length,
        MIN(LENGTH(content)) as min_length,
        MAX(LENGTH(content)) as max_length,
        COUNT(*) as entry_count
      FROM diary_entries
      WHERE date >= ? AND date <= ? AND content IS NOT NULL AND content != ""
    ''', [startDateStr, endDateStr]);
    
    return result.first;
  }

  /// 清理空的日记条目（没有内容也没有附件）
  Future<int> cleanupEmptyEntries() async {
    return await deleteWhere(
      where: '(content IS NULL OR content = "") AND (attachments IS NULL OR attachments = "")',
    );
  }
}