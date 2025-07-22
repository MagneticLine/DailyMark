import '../repositories/repositories.dart';
import '../models/models.dart';
import 'database_service.dart';

/// 数据服务类
/// 
/// 提供高级的数据操作接口，封装Repository的使用
/// 处理复杂的业务逻辑和跨表操作
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Repository实例
  final TagRepository _tagRepository = TagRepository();
  final TagRecordRepository _tagRecordRepository = TagRecordRepository();
  final DiaryEntryRepository _diaryEntryRepository = DiaryEntryRepository();
  final DatabaseService _databaseService = DatabaseService();

  // Getter方法提供Repository访问
  TagRepository get tags => _tagRepository;
  TagRecordRepository get tagRecords => _tagRecordRepository;
  DiaryEntryRepository get diaryEntries => _diaryEntryRepository;

  /// 初始化数据服务
  /// 
  /// 确保数据库已创建并可用
  Future<void> initialize() async {
    try {
      // 获取数据库连接，这会触发数据库创建
      await _databaseService.database;
      print('数据库初始化成功');
    } catch (e) {
      print('数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 创建示例数据（用于测试和演示）
  Future<void> createSampleData() async {
    try {
      // 创建示例标签
      await _createSampleTags();
      
      // 创建示例记录
      await _createSampleRecords();
      
      // 创建示例日记
      await _createSampleDiaries();
      
      print('示例数据创建成功');
    } catch (e) {
      print('创建示例数据失败: $e');
      rethrow;
    }
  }

  /// 创建示例标签
  Future<void> _createSampleTags() async {
    final now = DateTime.now();
    
    // 量化标签示例
    final sleepQualityTag = Tag(
      id: 'tag_sleep_quality',
      name: '睡眠质量',
      type: TagType.quantitative,
      config: {
        'minValue': 1,
        'maxValue': 10,
        'unit': '分',
        'labels': ['很差', '差', '一般', '好', '很好']
      },
      color: '#2196F3',
      enablePrediction: true,
      cycleDays: 7,
      createdAt: now,
      updatedAt: now,
    );

    final moodTag = Tag(
      id: 'tag_mood',
      name: '心情',
      type: TagType.quantitative,
      config: {
        'minValue': 1,
        'maxValue': 5,
        'unit': '级',
        'labels': ['很差', '差', '一般', '好', '很好']
      },
      color: '#FF9800',
      enablePrediction: false,
      createdAt: now,
      updatedAt: now,
    );

    // 非量化标签示例
    final exerciseTag = Tag(
      id: 'tag_exercise',
      name: '运动',
      type: TagType.binary,
      config: {
        'icon': '🏃',
        'activeColor': '#4CAF50'
      },
      color: '#4CAF50',
      enablePrediction: true,
      cycleDays: 2,
      createdAt: now,
      updatedAt: now,
    );

    final readingTag = Tag(
      id: 'tag_reading',
      name: '阅读',
      type: TagType.binary,
      config: {
        'icon': '📚',
        'activeColor': '#9C27B0'
      },
      color: '#9C27B0',
      enablePrediction: false,
      createdAt: now,
      updatedAt: now,
    );

    // 复杂标签示例
    final workStatusTag = Tag(
      id: 'tag_work_status',
      name: '工作状态',
      type: TagType.complex,
      config: {
        'subTags': ['在家办公', '公司办公', '出差', '休假', '加班']
      },
      color: '#607D8B',
      enablePrediction: false,
      createdAt: now,
      updatedAt: now,
    );

    // 插入标签
    final sampleTags = [sleepQualityTag, moodTag, exerciseTag, readingTag, workStatusTag];
    for (final tag in sampleTags) {
      await _tagRepository.insert(tag);
    }
  }

  /// 创建示例记录
  Future<void> _createSampleRecords() async {
    final now = DateTime.now();
    
    // 为过去7天创建一些示例记录
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      
      // 睡眠质量记录
      final sleepRecord = TagRecord(
        id: 'record_sleep_${date.millisecondsSinceEpoch}',
        tagId: 'tag_sleep_quality',
        date: date,
        value: 6 + (i % 4), // 6-9分的变化
        createdAt: date,
        updatedAt: date,
      );
      
      // 心情记录
      final moodRecord = TagRecord(
        id: 'record_mood_${date.millisecondsSinceEpoch}',
        tagId: 'tag_mood',
        date: date,
        value: 3 + (i % 3), // 3-5级的变化
        createdAt: date,
        updatedAt: date,
      );
      
      // 运动记录（隔天运动）
      if (i % 2 == 0) {
        final exerciseRecord = TagRecord(
          id: 'record_exercise_${date.millisecondsSinceEpoch}',
          tagId: 'tag_exercise',
          date: date,
          value: true,
          createdAt: date,
          updatedAt: date,
        );
        await _tagRecordRepository.insert(exerciseRecord);
      }
      
      // 工作状态记录
      final workStatuses = ['在家办公', '公司办公', '休假'];
      final workRecord = TagRecord(
        id: 'record_work_${date.millisecondsSinceEpoch}',
        tagId: 'tag_work_status',
        date: date,
        value: [workStatuses[i % workStatuses.length]],
        createdAt: date,
        updatedAt: date,
      );
      
      await _tagRecordRepository.insert(sleepRecord);
      await _tagRecordRepository.insert(moodRecord);
      await _tagRecordRepository.insert(workRecord);
    }
  }

  /// 创建示例日记
  Future<void> _createSampleDiaries() async {
    final now = DateTime.now();
    
    // 为过去3天创建示例日记
    final sampleContents = [
      '今天是美好的一天！完成了很多工作，心情不错。',
      '今天有点累，但是坚持运动了，感觉还是很有成就感的。',
      '周末在家休息，读了一本好书，很放松。',
    ];
    
    for (int i = 0; i < 3; i++) {
      final date = now.subtract(Duration(days: i));
      
      final diary = DiaryEntry(
        id: 'diary_${date.millisecondsSinceEpoch}',
        date: date,
        content: sampleContents[i],
        moodScore: 7 + (i % 3),
        weather: ['晴天', '多云', '雨天'][i % 3],
        createdAt: date,
        updatedAt: date,
      );
      
      await _diaryEntryRepository.insert(diary);
    }
  }

  /// 获取数据库状态信息
  Future<Map<String, dynamic>> getDatabaseStatus() async {
    try {
      final dbInfo = await _databaseService.getDatabaseInfo();
      final tagStats = await _tagRepository.getTagStatistics();
      final diaryStats = await _diaryEntryRepository.getDiaryStatistics();
      
      return {
        'database_info': dbInfo,
        'tag_statistics': tagStats,
        'diary_statistics': diaryStats,
        'status': 'healthy',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// 清理所有数据
  Future<void> clearAllData() async {
    await _databaseService.clearAllData();
    print('所有数据已清理');
  }

  /// 关闭数据库连接
  Future<void> close() async {
    await _databaseService.close();
  }

  /// 备份数据（简单实现）
  Future<Map<String, dynamic>> exportData() async {
    final tags = await _tagRepository.findAll();
    final records = await _tagRecordRepository.findAll();
    final diaries = await _diaryEntryRepository.findAll();
    
    return {
      'export_time': DateTime.now().toIso8601String(),
      'tags': tags.map((t) => t.toMap()).toList(),
      'records': records.map((r) => r.toMap()).toList(),
      'diaries': diaries.map((d) => d.toMap()).toList(),
    };
  }

  /// 导入数据（简单实现）
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // 清理现有数据
      await clearAllData();
      
      // 导入标签
      if (data['tags'] != null) {
        final tags = (data['tags'] as List)
            .map((tagMap) => Tag.fromMap(tagMap))
            .toList();
        await _tagRepository.insertBatch(tags);
      }
      
      // 导入记录
      if (data['records'] != null) {
        final records = (data['records'] as List)
            .map((recordMap) => TagRecord.fromMap(recordMap))
            .toList();
        await _tagRecordRepository.insertBatch(records);
      }
      
      // 导入日记
      if (data['diaries'] != null) {
        final diaries = (data['diaries'] as List)
            .map((diaryMap) => DiaryEntry.fromMap(diaryMap))
            .toList();
        await _diaryEntryRepository.insertBatch(diaries);
      }
      
      print('数据导入成功');
    } catch (e) {
      print('数据导入失败: $e');
      rethrow;
    }
  }
}