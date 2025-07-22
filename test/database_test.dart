import 'package:flutter_test/flutter_test.dart';
import 'package:daily_mark/services/data_service.dart';
import 'package:daily_mark/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // 初始化测试数据库
  setUpAll(() {
    // 初始化FFI数据库工厂用于测试
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('数据库测试', () {
    late DataService dataService;

    setUp(() async {
      dataService = DataService();
      await dataService.initialize();
      await dataService.clearAllData(); // 清理测试数据
    });

    tearDown(() async {
      await dataService.clearAllData();
      await dataService.close();
    });

    test('数据库初始化测试', () async {
      final status = await dataService.getDatabaseStatus();
      expect(status['status'], 'healthy');
      expect(status['database_info']['tag_count'], 0);
    });

    test('标签CRUD操作测试', () async {
      // 创建标签
      final tag = Tag(
        id: 'test_tag_1',
        name: '测试标签',
        type: TagType.quantitative,
        config: {'minValue': 1, 'maxValue': 10},
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 插入标签
      await dataService.tags.insert(tag);

      // 查询标签
      final foundTag = await dataService.tags.findById('test_tag_1');
      expect(foundTag, isNotNull);
      expect(foundTag!.name, '测试标签');
      expect(foundTag.type, TagType.quantitative);

      // 更新标签
      final updatedTag = foundTag.copyWith(name: '更新后的标签');
      await dataService.tags.update(updatedTag);

      final updatedFoundTag = await dataService.tags.findById('test_tag_1');
      expect(updatedFoundTag!.name, '更新后的标签');

      // 删除标签
      await dataService.tags.deleteById('test_tag_1');
      final deletedTag = await dataService.tags.findById('test_tag_1');
      expect(deletedTag, isNull);
    });

    test('标签记录CRUD操作测试', () async {
      // 先创建一个标签
      final tag = Tag(
        id: 'test_tag_2',
        name: '测试标签2',
        type: TagType.quantitative,
        config: {'minValue': 1, 'maxValue': 10},
        color: '#00FF00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dataService.tags.insert(tag);

      // 创建标签记录
      final record = TagRecord(
        id: 'test_record_1',
        tagId: 'test_tag_2',
        date: DateTime.now(),
        value: 8.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 插入记录
      await dataService.tagRecords.insert(record);

      // 查询记录
      final foundRecord = await dataService.tagRecords.findById('test_record_1');
      expect(foundRecord, isNotNull);
      expect(foundRecord!.tagId, 'test_tag_2');
      expect(foundRecord.numericValue, 8.5);

      // 按标签ID查询记录
      final tagRecords = await dataService.tagRecords.findByTagId('test_tag_2');
      expect(tagRecords.length, 1);
      expect(tagRecords.first.id, 'test_record_1');

      // 按日期查询记录
      final today = DateTime.now();
      final dateRecords = await dataService.tagRecords.findByDate(today);
      expect(dateRecords.length, 1);
    });

    test('日记条目CRUD操作测试', () async {
      final today = DateTime.now();
      
      // 创建日记条目
      final diary = DiaryEntry(
        id: 'test_diary_1',
        date: today,
        content: '这是一个测试日记条目',
        moodScore: 8,
        weather: '晴天',
        createdAt: today,
        updatedAt: today,
      );

      // 插入日记
      await dataService.diaryEntries.insert(diary);

      // 查询日记
      final foundDiary = await dataService.diaryEntries.findById('test_diary_1');
      expect(foundDiary, isNotNull);
      expect(foundDiary!.content, '这是一个测试日记条目');
      expect(foundDiary.moodScore, 8);

      // 按日期查询日记
      final dateDiary = await dataService.diaryEntries.findByDate(today);
      expect(dateDiary, isNotNull);
      expect(dateDiary!.id, 'test_diary_1');

      // 搜索日记内容
      final searchResults = await dataService.diaryEntries.searchContent('测试');
      expect(searchResults.length, 1);
      expect(searchResults.first.id, 'test_diary_1');
    });

    test('复杂查询测试', () async {
      // 创建测试数据
      await dataService.createSampleData();

      // 测试标签统计
      final tagStats = await dataService.tags.getTagStatistics();
      expect(tagStats.isNotEmpty, true);

      // 测试日记统计
      final diaryStats = await dataService.diaryEntries.getDiaryStatistics();
      expect(diaryStats['total_entries'], greaterThan(0));

      // 测试数据库状态
      final dbStatus = await dataService.getDatabaseStatus();
      expect(dbStatus['status'], 'healthy');
      expect(dbStatus['database_info']['tag_count'], greaterThan(0));
    });

    test('数据导出导入测试', () async {
      // 创建测试数据
      await dataService.createSampleData();

      // 导出数据
      final exportedData = await dataService.exportData();
      expect(exportedData['tags'], isNotEmpty);
      expect(exportedData['records'], isNotEmpty);
      expect(exportedData['diaries'], isNotEmpty);

      // 清理数据
      await dataService.clearAllData();
      
      // 验证数据已清理
      final emptyStatus = await dataService.getDatabaseStatus();
      expect(emptyStatus['database_info']['tag_count'], 0);

      // 导入数据
      await dataService.importData(exportedData);

      // 验证数据已导入
      final importedStatus = await dataService.getDatabaseStatus();
      expect(importedStatus['database_info']['tag_count'], greaterThan(0));
    });
  });
}