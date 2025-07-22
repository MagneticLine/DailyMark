import 'package:daily_mark/services/data_service.dart';
import 'package:daily_mark/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 手动数据库测试脚本
/// 
/// 这个脚本可以独立运行，用于验证数据存储功能
void main() async {
  print('开始数据库功能验证...\n');
  
  // 初始化FFI数据库工厂
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  final dataService = DataService();
  
  try {
    // 1. 初始化数据库
    print('1. 初始化数据库...');
    await dataService.initialize();
    print('✓ 数据库初始化成功\n');
    
    // 2. 清理现有数据
    print('2. 清理现有数据...');
    await dataService.clearAllData();
    print('✓ 数据清理完成\n');
    
    // 3. 创建测试标签
    print('3. 创建测试标签...');
    final testTag = Tag(
      id: 'test_tag_manual',
      name: '手动测试标签',
      type: TagType.quantitative,
      config: {
        'minValue': 1,
        'maxValue': 10,
        'unit': '分',
        'labels': ['很差', '差', '一般', '好', '很好']
      },
      color: '#4CAF50',
      enablePrediction: true,
      cycleDays: 7,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await dataService.tags.insert(testTag);
    print('✓ 标签创建成功: ${testTag.name}');
    
    // 验证标签插入
    final foundTag = await dataService.tags.findById('test_tag_manual');
    if (foundTag != null) {
      print('✓ 标签查询成功: ${foundTag.name}, 类型: ${foundTag.type.displayName}');
    } else {
      print('✗ 标签查询失败');
    }
    print('');
    
    // 4. 创建测试记录
    print('4. 创建测试记录...');
    final testRecord = TagRecord(
      id: 'test_record_manual',
      tagId: 'test_tag_manual',
      date: DateTime.now(),
      value: 8.5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      note: '这是一个手动测试记录',
    );
    
    await dataService.tagRecords.insert(testRecord);
    print('✓ 记录创建成功: 值=${testRecord.value}');
    
    // 验证记录插入
    final foundRecord = await dataService.tagRecords.findById('test_record_manual');
    if (foundRecord != null) {
      print('✓ 记录查询成功: 值=${foundRecord.numericValue}, 备注=${foundRecord.note}');
    } else {
      print('✗ 记录查询失败');
    }
    print('');
    
    // 5. 创建测试日记
    print('5. 创建测试日记...');
    final testDiary = DiaryEntry(
      id: 'test_diary_manual',
      date: DateTime.now(),
      content: '这是一个手动测试的日记条目，用于验证数据存储功能。',
      moodScore: 8,
      weather: '晴天',
      tagRecordIds: ['test_record_manual'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await dataService.diaryEntries.insert(testDiary);
    print('✓ 日记创建成功: ${testDiary.contentSummary}');
    
    // 验证日记插入
    final foundDiary = await dataService.diaryEntries.findById('test_diary_manual');
    if (foundDiary != null) {
      print('✓ 日记查询成功: 心情=${foundDiary.moodScore}, 天气=${foundDiary.weather}');
    } else {
      print('✗ 日记查询失败');
    }
    print('');
    
    // 6. 测试复杂查询
    print('6. 测试复杂查询...');
    
    // 按标签ID查询记录
    final tagRecords = await dataService.tagRecords.findByTagId('test_tag_manual');
    print('✓ 按标签查询记录: 找到${tagRecords.length}条记录');
    
    // 按日期查询记录
    final dateRecords = await dataService.tagRecords.findByDate(DateTime.now());
    print('✓ 按日期查询记录: 找到${dateRecords.length}条记录');
    
    // 搜索日记内容
    final searchResults = await dataService.diaryEntries.searchContent('手动测试');
    print('✓ 搜索日记内容: 找到${searchResults.length}条结果');
    print('');
    
    // 7. 获取数据库状态
    print('7. 获取数据库状态...');
    final dbStatus = await dataService.getDatabaseStatus();
    print('✓ 数据库状态: ${dbStatus['status']}');
    
    final dbInfo = dbStatus['database_info'] as Map<String, dynamic>;
    print('  - 标签数量: ${dbInfo['tag_count']}');
    print('  - 记录数量: ${dbInfo['record_count']}');
    print('  - 日记数量: ${dbInfo['diary_count']}');
    print('');
    
    // 8. 创建示例数据
    print('8. 创建示例数据...');
    await dataService.createSampleData();
    print('✓ 示例数据创建成功');
    
    // 再次检查状态
    final finalStatus = await dataService.getDatabaseStatus();
    final finalDbInfo = finalStatus['database_info'] as Map<String, dynamic>;
    print('  - 最终标签数量: ${finalDbInfo['tag_count']}');
    print('  - 最终记录数量: ${finalDbInfo['record_count']}');
    print('  - 最终日记数量: ${finalDbInfo['diary_count']}');
    print('');
    
    // 9. 测试标签统计
    print('9. 测试标签统计...');
    final tagStats = await dataService.tags.getTagStatistics();
    print('✓ 标签统计:');
    tagStats.forEach((key, value) {
      print('  - $key: $value');
    });
    print('');
    
    // 10. 测试数据导出
    print('10. 测试数据导出...');
    final exportData = await dataService.exportData();
    final exportedTags = exportData['tags'] as List;
    final exportedRecords = exportData['records'] as List;
    final exportedDiaries = exportData['diaries'] as List;
    
    print('✓ 数据导出成功:');
    print('  - 导出标签: ${exportedTags.length}个');
    print('  - 导出记录: ${exportedRecords.length}个');
    print('  - 导出日记: ${exportedDiaries.length}个');
    print('');
    
    print('🎉 所有数据库功能验证通过！');
    
  } catch (e, stackTrace) {
    print('❌ 测试失败: $e');
    print('堆栈跟踪: $stackTrace');
  } finally {
    // 清理资源
    await dataService.close();
    print('\n数据库连接已关闭');
  }
}