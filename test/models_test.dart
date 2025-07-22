import 'package:flutter_test/flutter_test.dart';
import 'package:daily_mark/models/models.dart';

void main() {
  group('数据模型测试', () {
    
    group('TagType 枚举测试', () {
      test('应该正确创建和识别标签类型', () {
        expect(TagType.quantitative.value, equals('quantitative'));
        expect(TagType.quantitative.displayName, equals('量化标签'));
        expect(TagType.quantitative.isQuantitative, isTrue);
        expect(TagType.quantitative.isBinary, isFalse);
        expect(TagType.quantitative.isComplex, isFalse);
      });

      test('应该能从字符串创建枚举', () {
        expect(TagType.fromString('quantitative'), equals(TagType.quantitative));
        expect(TagType.fromString('binary'), equals(TagType.binary));
        expect(TagType.fromString('complex'), equals(TagType.complex));
        expect(TagType.fromString('invalid'), isNull);
      });
    });

    group('Tag 模型测试', () {
      test('应该正确创建量化标签', () {
        final now = DateTime.now();
        final tag = Tag(
          id: 'test-id',
          name: '心情评分',
          type: TagType.quantitative,
          config: {
            'minValue': 1,
            'maxValue': 10,
            'unit': '分',
          },
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        expect(tag.name, equals('心情评分'));
        expect(tag.type, equals(TagType.quantitative));
        expect(tag.quantitativeMinValue, equals(1.0));
        expect(tag.quantitativeMaxValue, equals(10.0));
        expect(tag.quantitativeUnit, equals('分'));
      });

      test('应该正确序列化和反序列化', () {
        final now = DateTime.now();
        final originalTag = Tag(
          id: 'test-id',
          name: '测试标签',
          type: TagType.binary,
          config: {'icon': '✓'},
          color: '#4CAF50',
          createdAt: now,
          updatedAt: now,
        );

        final map = originalTag.toMap();
        final restoredTag = Tag.fromMap(map);

        expect(restoredTag.id, equals(originalTag.id));
        expect(restoredTag.name, equals(originalTag.name));
        expect(restoredTag.type, equals(originalTag.type));
        expect(restoredTag.color, equals(originalTag.color));
      });
    });

    group('TagRecord 模型测试', () {
      test('应该正确处理量化记录', () {
        final now = DateTime.now();
        final record = TagRecord(
          id: 'record-id',
          tagId: 'tag-id',
          date: now,
          value: 8.5,
          createdAt: now,
          updatedAt: now,
        );

        expect(record.numericValue, equals(8.5));
        expect(record.hasValue, isTrue);
        expect(record.displayValue, equals('8.5'));
      });

      test('应该正确处理非量化记录', () {
        final now = DateTime.now();
        final record = TagRecord(
          id: 'record-id',
          tagId: 'tag-id',
          date: now,
          value: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(record.booleanValue, isTrue);
        expect(record.displayValue, equals('是'));
      });

      test('应该正确处理复杂记录', () {
        final now = DateTime.now();
        final record = TagRecord(
          id: 'record-id',
          tagId: 'tag-id',
          date: now,
          value: ['深度睡眠', '8小时'],
          createdAt: now,
          updatedAt: now,
        );

        expect(record.listValue, equals(['深度睡眠', '8小时']));
        expect(record.displayValue, equals('深度睡眠, 8小时'));
      });
    });

    group('数据验证测试', () {
      test('应该验证有效的量化标签', () {
        final now = DateTime.now();
        final tag = Tag(
          id: 'test-id',
          name: '心情评分',
          type: TagType.quantitative,
          config: {
            'minValue': 1,
            'maxValue': 10,
            'unit': '分',
          },
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        final result = DataValidator.validateTag(tag);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('应该检测无效的标签配置', () {
        final now = DateTime.now();
        final tag = Tag(
          id: '',
          name: '',
          type: TagType.quantitative,
          config: {
            'minValue': 10,
            'maxValue': 1, // 最小值大于最大值
          },
          color: 'invalid-color',
          createdAt: now,
          updatedAt: now,
        );

        final result = DataValidator.validateTag(tag);
        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThan(0));
      });

      test('应该验证标签记录值的范围', () {
        final now = DateTime.now();
        final tag = Tag(
          id: 'tag-id',
          name: '心情评分',
          type: TagType.quantitative,
          config: {
            'minValue': 1,
            'maxValue': 10,
          },
          color: '#FF5722',
          createdAt: now,
          updatedAt: now,
        );

        final record = TagRecord(
          id: 'record-id',
          tagId: 'tag-id',
          date: now,
          value: 15, // 超出最大值
          createdAt: now,
          updatedAt: now,
        );

        final result = DataValidator.validateTagRecord(record, tag);
        expect(result.isValid, isFalse);
        expect(result.errors.any((error) => error.contains('最大值')), isTrue);
      });
    });

    group('DiaryEntry 模型测试', () {
      test('应该正确创建日记条目', () {
        final now = DateTime.now();
        final entry = DiaryEntry(
          id: 'entry-id',
          date: now,
          content: '今天心情不错，完成了很多工作。',
          createdAt: now,
          updatedAt: now,
          moodScore: 8,
        );

        expect(entry.hasContent, isTrue);
        expect(entry.contentSummary, equals('今天心情不错，完成了很多工作。'));
        expect(entry.moodScore, equals(8));
      });

      test('应该正确处理长内容的摘要', () {
        final now = DateTime.now();
        final longContent = '这是一个很长的日记内容，' * 10; // 创建长内容
        final entry = DiaryEntry(
          id: 'entry-id',
          date: now,
          content: longContent,
          createdAt: now,
          updatedAt: now,
        );

        expect(entry.contentSummary.length, lessThanOrEqualTo(53)); // 50 + "..."
        expect(entry.contentSummary.endsWith('...'), isTrue);
      });
    });
  });
}