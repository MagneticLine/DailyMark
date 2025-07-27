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
    
    // 为复杂标签创建子标签对象
    await _createSubTagsForComplexTag(workStatusTag);
  }

  /// 为复杂标签创建子标签对象
  Future<void> _createSubTagsForComplexTag(Tag complexTag) async {
    if (!complexTag.type.isComplex) return;
    
    final subTagNames = complexTag.complexSubTags;
    final now = DateTime.now();
    
    for (int i = 0; i < subTagNames.length; i++) {
      final subTagName = subTagNames[i];
      
      // 检查子标签是否已存在
      final existingTags = await _tagRepository.findActive();
      if (existingTags.any((tag) => tag.name == subTagName)) {
        continue; // 跳过已存在的子标签
      }
      
      // 根据子标签名称确定类型（这里简化处理，实际项目中可能需要更复杂的逻辑）
      TagType subTagType = TagType.binary; // 默认为非量化标签
      Map<String, dynamic> subTagConfig = {'icon': '✓'};
      
      // 为某些特定的子标签设置为量化类型
      if (subTagName.contains('加班')) {
        subTagType = TagType.quantitative;
        subTagConfig = {
          'minValue': 0.0,
          'maxValue': 12.0,
          'unit': '小时',
        };
      }
      
      final subTag = Tag(
        id: 'subtag_${complexTag.id}_$i',
        name: subTagName,
        type: subTagType,
        config: subTagConfig,
        color: complexTag.color, // 使用复杂标签的颜色
        enablePrediction: false,
        createdAt: now,
        updatedAt: now,
      );
      
      await _tagRepository.insert(subTag);
      print('创建子标签: $subTagName (${subTagType.displayName})');
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

  // ==================== 测试数据生成器 ====================

  /// 创建随机量化标签生成器
  /// 
  /// 生成随机名字和数值的量化标签，并随机填充2025年7月的日历数据
  Future<void> createRandomQuantitativeTags({int count = 5}) async {
    final random = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    
    // 量化标签名称池
    final quantitativeNames = [
      '心情指数', '睡眠质量', '工作效率', '学习专注度', '身体状态',
      '压力水平', '创造力', '社交活跃度', '饮食健康度', '运动强度',
      '阅读时长', '冥想深度', '沟通效果', '时间管理', '目标完成度'
    ];
    
    // 颜色池
    final colors = [
      '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5',
      '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50',
      '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800'
    ];
    
    final createdTags = <Tag>[];
    
    for (int i = 0; i < count; i++) {
      final tagId = 'random_quant_${random}_$i';
      final name = quantitativeNames[i % quantitativeNames.length];
      final color = colors[i % colors.length];
      
      // 随机生成评分范围
      final minValue = (i % 3) + 1; // 1-3
      final maxValue = minValue + 5 + (i % 5); // 6-12
      final units = ['分', '级', '度', '点', '星'][i % 5];
      
      final tag = Tag(
        id: tagId,
        name: '$name${i + 1}',
        type: TagType.quantitative,
        config: {
          'minValue': minValue,
          'maxValue': maxValue,
          'unit': units,
          'labels': _generateQuantitativeLabels(minValue, maxValue),
        },
        color: color,
        enablePrediction: i % 2 == 0, // 一半启用预测
        cycleDays: i % 2 == 0 ? (7 + i % 14) : null, // 7-20天周期
        createdAt: now,
        updatedAt: now,
      );
      
      await _tagRepository.insert(tag);
      createdTags.add(tag);
      print('创建随机量化标签: ${tag.name}');
    }
    
    // 为2025年7月生成随机数据
    await _generateRandomRecordsForMonth(createdTags, 2025, 7);
  }

  /// 创建随机非量化标签生成器
  /// 
  /// 生成随机名字和图标的非量化标签，并随机填充2025年7月的日历数据
  Future<void> createRandomBinaryTags({int count = 5}) async {
    final random = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    
    // 非量化标签名称和图标池
    final binaryData = [
      {'name': '早起', 'icon': '🌅'},
      {'name': '运动', 'icon': '🏃'},
      {'name': '阅读', 'icon': '📚'},
      {'name': '冥想', 'icon': '🧘'},
      {'name': '写日记', 'icon': '✍️'},
      {'name': '喝水充足', 'icon': '💧'},
      {'name': '按时吃饭', 'icon': '🍽️'},
      {'name': '早睡', 'icon': '😴'},
      {'name': '户外活动', 'icon': '🌳'},
      {'name': '学习新知识', 'icon': '🎓'},
      {'name': '整理房间', 'icon': '🏠'},
      {'name': '联系朋友', 'icon': '📞'},
      {'name': '听音乐', 'icon': '🎵'},
      {'name': '看电影', 'icon': '🎬'},
      {'name': '做饭', 'icon': '👨‍🍳'},
    ];
    
    // 颜色池
    final colors = [
      '#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336',
      '#00BCD4', '#8BC34A', '#FFC107', '#E91E63', '#673AB7',
      '#009688', '#CDDC39', '#FF5722', '#795548', '#607D8B'
    ];
    
    final createdTags = <Tag>[];
    
    for (int i = 0; i < count; i++) {
      final tagId = 'random_binary_${random}_$i';
      final data = binaryData[i % binaryData.length];
      final color = colors[i % colors.length];
      
      final tag = Tag(
        id: tagId,
        name: '${data['name']}${i + 1}',
        type: TagType.binary,
        config: {
          'icon': data['icon'],
          'activeColor': color,
        },
        color: color,
        enablePrediction: i % 3 == 0, // 三分之一启用预测
        cycleDays: i % 3 == 0 ? (2 + i % 5) : null, // 2-6天周期
        createdAt: now,
        updatedAt: now,
      );
      
      await _tagRepository.insert(tag);
      createdTags.add(tag);
      print('创建随机非量化标签: ${tag.name}');
    }
    
    // 为2025年7月生成随机数据
    await _generateRandomRecordsForMonth(createdTags, 2025, 7);
  }

  /// 创建随机复杂标签生成器
  /// 
  /// 生成随机名字和子标签的复杂标签，并随机填充2025年7月的日历数据
  Future<void> createRandomComplexTags({int count = 3}) async {
    final random = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    
    // 复杂标签数据池
    final complexData = [
      {
        'name': '工作状态',
        'subTags': ['在家办公', '公司办公', '出差', '会议', '休假', '加班']
      },
      {
        'name': '饮食情况',
        'subTags': ['健康饮食', '外卖', '自己做饭', '聚餐', '节食', '暴饮暴食']
      },
      {
        'name': '交通方式',
        'subTags': ['步行', '骑车', '地铁', '公交', '开车', '打车']
      },
      {
        'name': '学习方式',
        'subTags': ['看书', '在线课程', '实践练习', '讨论交流', '看视频', '做笔记']
      },
      {
        'name': '娱乐活动',
        'subTags': ['看电影', '玩游戏', '听音乐', '逛街', '聚会', '旅游']
      },
      {
        'name': '健康状况',
        'subTags': ['精力充沛', '有点疲惫', '身体不适', '感冒', '头痛', '失眠']
      },
    ];
    
    // 颜色池
    final colors = [
      '#607D8B', '#795548', '#FF5722', '#E91E63', '#9C27B0',
      '#673AB7', '#3F51B5', '#2196F3', '#00BCD4', '#009688'
    ];
    
    final createdTags = <Tag>[];
    
    for (int i = 0; i < count; i++) {
      final tagId = 'random_complex_${random}_$i';
      final data = complexData[i % complexData.length];
      final color = colors[i % colors.length];
      
      final tag = Tag(
        id: tagId,
        name: '${data['name']}${i + 1}',
        type: TagType.complex,
        config: {
          'subTags': data['subTags'],
        },
        color: color,
        enablePrediction: false, // 复杂标签暂不支持预测
        createdAt: now,
        updatedAt: now,
      );
      
      await _tagRepository.insert(tag);
      createdTags.add(tag);
      print('创建随机复杂标签: ${tag.name}');
      
      // 为复杂标签创建子标签
      await _createSubTagsForComplexTag(tag);
    }
    
    // 为2025年7月生成随机数据
    await _generateRandomRecordsForMonth(createdTags, 2025, 7);
  }

  /// 创建模拟用户使用一年后的日历情况
  /// 
  /// 生成大量历史数据，模拟用户长期使用的情况
  Future<void> createOneYearSimulationData() async {
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    
    print('开始创建一年模拟数据...');
    
    // 创建一些基础标签用于长期追踪
    await _createLongTermTrackingTags();
    
    // 获取所有标签
    final allTags = await _tagRepository.findActive();
    
    // 为过去一年的每个月生成数据
    for (int monthOffset = 0; monthOffset < 12; monthOffset++) {
      final targetDate = DateTime(oneYearAgo.year, oneYearAgo.month + monthOffset, 1);
      final year = targetDate.year;
      final month = targetDate.month;
      
      print('生成 $year年$month月 的数据...');
      
      // 为每个标签生成该月的数据
      for (final tag in allTags) {
        await _generateRandomRecordsForMonth([tag], year, month);
      }
      
      // 生成一些日记条目
      await _generateRandomDiariesForMonth(year, month);
    }
    
    print('一年模拟数据创建完成！');
  }

  /// 创建长期追踪标签
  Future<void> _createLongTermTrackingTags() async {
    final now = DateTime.now();
    
    final longTermTags = [
      Tag(
        id: 'longterm_mood',
        name: '每日心情',
        type: TagType.quantitative,
        config: {'minValue': 1, 'maxValue': 10, 'unit': '分'},
        color: '#FF9800',
        enablePrediction: true,
        cycleDays: 7,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'longterm_energy',
        name: '精力水平',
        type: TagType.quantitative,
        config: {'minValue': 1, 'maxValue': 5, 'unit': '级'},
        color: '#4CAF50',
        enablePrediction: true,
        cycleDays: 7,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'longterm_exercise',
        name: '运动打卡',
        type: TagType.binary,
        config: {'icon': '🏃', 'activeColor': '#2196F3'},
        color: '#2196F3',
        enablePrediction: true,
        cycleDays: 3,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'longterm_sleep',
        name: '睡眠时长',
        type: TagType.quantitative,
        config: {'minValue': 4, 'maxValue': 12, 'unit': '小时'},
        color: '#9C27B0',
        enablePrediction: true,
        cycleDays: 7,
        createdAt: now,
        updatedAt: now,
      ),
      Tag(
        id: 'longterm_work',
        name: '工作模式',
        type: TagType.complex,
        config: {'subTags': ['在家', '办公室', '出差', '休假']},
        color: '#607D8B',
        enablePrediction: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    
    for (final tag in longTermTags) {
      // 检查是否已存在
      final existing = await _tagRepository.findById(tag.id);
      if (existing == null) {
        await _tagRepository.insert(tag);
        if (tag.type.isComplex) {
          await _createSubTagsForComplexTag(tag);
        }
        print('创建长期追踪标签: ${tag.name}');
      }
    }
  }

  /// 为指定月份生成随机记录
  Future<void> _generateRandomRecordsForMonth(List<Tag> tags, int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    
    for (final tag in tags) {
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final recordId = 'record_${tag.id}_${date.millisecondsSinceEpoch}';
        
        // 随机决定是否在这一天有记录（70%概率）
        if ((random + day + tag.id.hashCode) % 10 < 7) {
          dynamic value;
          
          if (tag.type.isQuantitative) {
            final minValue = tag.quantitativeMinValue ?? 1;
            final maxValue = tag.quantitativeMaxValue ?? 10;
            // 生成带有一定规律性的随机值
            final baseValue = minValue + (maxValue - minValue) * 0.6;
            final variation = (maxValue - minValue) * 0.3;
            final randomFactor = ((random + day * 7 + tag.id.hashCode) % 100) / 100.0;
            value = (baseValue + variation * (randomFactor - 0.5) * 2).clamp(minValue, maxValue);
            value = double.parse(value.toStringAsFixed(1));
          } else if (tag.type.isBinary) {
            // 非量化标签有60%概率为true
            value = ((random + day * 3 + tag.id.hashCode) % 10) < 6;
          } else if (tag.type.isComplex) {
            final subTags = tag.complexSubTags;
            if (subTags.isNotEmpty) {
              // 随机选择1-2个子标签
              final selectedCount = 1 + ((random + day + tag.id.hashCode) % 2);
              final selectedSubTags = <String>[];
              for (int i = 0; i < selectedCount && i < subTags.length; i++) {
                final index = (random + day * (i + 1) + tag.id.hashCode) % subTags.length;
                final subTag = subTags[index];
                if (!selectedSubTags.contains(subTag)) {
                  selectedSubTags.add(subTag);
                }
              }
              value = selectedSubTags;
            }
          }
          
          if (value != null) {
            final record = TagRecord(
              id: recordId,
              tagId: tag.id,
              date: date,
              value: value,
              createdAt: date,
              updatedAt: date,
            );
            
            await _tagRecordRepository.insert(record);
          }
        }
      }
    }
  }

  /// 为指定月份生成随机日记
  Future<void> _generateRandomDiariesForMonth(int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    
    final diaryContents = [
      '今天过得很充实，完成了很多计划中的事情。',
      '心情不错，和朋友聊天很开心。',
      '工作有点忙，但是很有成就感。',
      '今天天气很好，出去走了走。',
      '学到了新东西，感觉很有收获。',
      '有点累，但是坚持完成了目标。',
      '今天比较放松，看了本好书。',
      '和家人一起度过了愉快的时光。',
      '遇到了一些挑战，但是克服了。',
      '今天的运动让我感觉很棒。',
    ];
    
    for (int day = 1; day <= daysInMonth; day++) {
      // 30%概率写日记
      if ((random + day * 13) % 10 < 3) {
        final date = DateTime(year, month, day);
        final diaryId = 'diary_${date.millisecondsSinceEpoch}';
        final contentIndex = (random + day * 7) % diaryContents.length;
        final moodScore = 5 + ((random + day * 11) % 6); // 5-10分
        
        final diary = DiaryEntry(
          id: diaryId,
          date: date,
          content: diaryContents[contentIndex],
          moodScore: moodScore,
          weather: ['晴天', '多云', '雨天', '阴天'][(random + day * 5) % 4],
          createdAt: date,
          updatedAt: date,
        );
        
        await _diaryEntryRepository.insert(diary);
      }
    }
  }

  /// 生成量化标签的标签列表
  List<String> _generateQuantitativeLabels(int minValue, int maxValue) {
    final range = maxValue - minValue;
    if (range <= 2) {
      return ['差', '好'];
    } else if (range <= 4) {
      return ['差', '一般', '好'];
    } else if (range <= 6) {
      return ['很差', '差', '一般', '好', '很好'];
    } else {
      return ['极差', '很差', '差', '一般', '好', '很好', '极好'];
    }
  }
}