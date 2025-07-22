import 'tag.dart';
import 'tag_type.dart';
import 'tag_record.dart';
import 'diary_entry.dart';

/// 数据验证结果
class ValidationResult {
  /// 是否验证通过
  final bool isValid;
  
  /// 错误消息列表
  final List<String> errors;
  
  /// 警告消息列表
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// 创建成功的验证结果
  factory ValidationResult.success({List<String> warnings = const []}) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// 创建失败的验证结果
  factory ValidationResult.failure(List<String> errors, {List<String> warnings = const []}) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 合并多个验证结果
  static ValidationResult combine(List<ValidationResult> results) {
    final allErrors = <String>[];
    final allWarnings = <String>[];
    bool isValid = true;

    for (final result in results) {
      if (!result.isValid) {
        isValid = false;
      }
      allErrors.addAll(result.errors);
      allWarnings.addAll(result.warnings);
    }

    return ValidationResult(
      isValid: isValid,
      errors: allErrors,
      warnings: allWarnings,
    );
  }
}

/// 数据验证工具类
/// 
/// 提供对Tag、TagRecord、DiaryEntry等数据模型的验证功能
class DataValidator {
  
  /// 验证标签数据
  /// 
  /// [tag] 要验证的标签对象
  /// 返回验证结果
  static ValidationResult validateTag(Tag tag) {
    final errors = <String>[];
    final warnings = <String>[];

    // 验证基础字段
    if (tag.id.trim().isEmpty) {
      errors.add('标签ID不能为空');
    }

    if (tag.name.trim().isEmpty) {
      errors.add('标签名称不能为空');
    } else if (tag.name.length > 50) {
      errors.add('标签名称不能超过50个字符');
    }

    // 验证颜色格式
    if (!_isValidHexColor(tag.color)) {
      errors.add('标签颜色格式无效，应为十六进制格式（如#FF5722）');
    }

    // 验证周期设置
    if (tag.enablePrediction && tag.cycleDays != null) {
      if (tag.cycleDays! <= 0) {
        errors.add('周期天数必须大于0');
      } else if (tag.cycleDays! > 365) {
        warnings.add('周期天数超过365天，预测准确性可能较低');
      }
    }

    // 根据标签类型验证配置
    final configValidation = _validateTagConfig(tag.type, tag.config);
    errors.addAll(configValidation.errors);
    warnings.addAll(configValidation.warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 验证标签记录数据
  /// 
  /// [record] 要验证的标签记录对象
  /// [tag] 关联的标签对象（用于验证值的有效性）
  /// 返回验证结果
  static ValidationResult validateTagRecord(TagRecord record, Tag tag) {
    final errors = <String>[];
    final warnings = <String>[];

    // 验证基础字段
    if (record.id.trim().isEmpty) {
      errors.add('记录ID不能为空');
    }

    if (record.tagId.trim().isEmpty) {
      errors.add('标签ID不能为空');
    }

    if (record.tagId != tag.id) {
      errors.add('记录的标签ID与提供的标签不匹配');
    }

    // 验证日期
    final now = DateTime.now();
    if (record.date.isAfter(now.add(const Duration(days: 365)))) {
      warnings.add('记录日期距离现在超过一年，请确认日期是否正确');
    }

    // 验证预测相关字段
    if (record.isPrediction) {
      if (record.confidence != null) {
        if (record.confidence! < 0.0 || record.confidence! > 1.0) {
          errors.add('预测置信度必须在0.0到1.0之间');
        }
      }
    } else {
      if (record.confidence != null) {
        warnings.add('非预测记录不应设置置信度');
      }
    }

    // 根据标签类型验证记录值
    final valueValidation = _validateRecordValue(tag.type, record.value, tag.config);
    errors.addAll(valueValidation.errors);
    warnings.addAll(valueValidation.warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 验证日记条目数据
  /// 
  /// [entry] 要验证的日记条目对象
  /// 返回验证结果
  static ValidationResult validateDiaryEntry(DiaryEntry entry) {
    final errors = <String>[];
    final warnings = <String>[];

    // 验证基础字段
    if (entry.id.trim().isEmpty) {
      errors.add('日记条目ID不能为空');
    }

    // 验证内容长度
    if (entry.content.length > 10000) {
      errors.add('日记内容不能超过10000个字符');
    }

    // 验证心情评分
    if (entry.moodScore != null) {
      if (entry.moodScore! < 1 || entry.moodScore! > 10) {
        errors.add('心情评分必须在1到10之间');
      }
    }

    // 验证附件
    for (int i = 0; i < entry.attachments.length; i++) {
      final attachment = entry.attachments[i];
      if (attachment.fileName.trim().isEmpty) {
        errors.add('第${i + 1}个附件的文件名不能为空');
      }
      if (attachment.fileSize <= 0) {
        errors.add('第${i + 1}个附件的文件大小无效');
      }
      if (attachment.fileSize > 100 * 1024 * 1024) { // 100MB
        warnings.add('第${i + 1}个附件文件过大（超过100MB），可能影响应用性能');
      }
    }

    // 检查是否有实际内容
    if (!entry.hasContent) {
      warnings.add('日记条目没有文字内容或附件');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 验证标签配置
  static ValidationResult _validateTagConfig(TagType type, Map<String, dynamic> config) {
    final errors = <String>[];
    final warnings = <String>[];

    switch (type) {
      case TagType.quantitative:
        // 验证量化标签配置
        if (!config.containsKey('minValue') || !config.containsKey('maxValue')) {
          errors.add('量化标签必须设置最小值和最大值');
        } else {
          final minValue = config['minValue'];
          final maxValue = config['maxValue'];
          
          if (minValue is! num || maxValue is! num) {
            errors.add('量化标签的最小值和最大值必须为数字');
          } else if (minValue >= maxValue) {
            errors.add('量化标签的最小值必须小于最大值');
          }
        }
        
        if (config.containsKey('unit') && config['unit'] is! String) {
          errors.add('量化标签的单位必须为字符串');
        }
        break;

      case TagType.binary:
        // 验证非量化标签配置
        if (config.containsKey('icon') && config['icon'] is! String) {
          errors.add('非量化标签的图标必须为字符串');
        }
        break;

      case TagType.complex:
        // 验证复杂标签配置
        if (!config.containsKey('subTags')) {
          errors.add('复杂标签必须设置子标签列表');
        } else {
          final subTags = config['subTags'];
          if (subTags is! List) {
            errors.add('复杂标签的子标签必须为列表');
          } else if (subTags.isEmpty) {
            errors.add('复杂标签至少需要一个子标签');
          } else {
            for (int i = 0; i < subTags.length; i++) {
              if (subTags[i] is! String || (subTags[i] as String).trim().isEmpty) {
                errors.add('第${i + 1}个子标签名称无效');
              }
            }
          }
        }
        break;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 验证记录值
  static ValidationResult _validateRecordValue(TagType type, dynamic value, Map<String, dynamic> config) {
    final errors = <String>[];
    final warnings = <String>[];

    switch (type) {
      case TagType.quantitative:
        // 验证量化值
        if (value is! num) {
          errors.add('量化标签的记录值必须为数字');
        } else {
          final minValue = config['minValue'] as num?;
          final maxValue = config['maxValue'] as num?;
          
          if (minValue != null && value < minValue) {
            errors.add('记录值不能小于最小值$minValue');
          }
          if (maxValue != null && value > maxValue) {
            errors.add('记录值不能大于最大值$maxValue');
          }
        }
        break;

      case TagType.binary:
        // 验证非量化值
        if (value is! bool) {
          errors.add('非量化标签的记录值必须为布尔值');
        }
        break;

      case TagType.complex:
        // 验证复杂值
        if (value is! List) {
          errors.add('复杂标签的记录值必须为列表');
        } else {
          final subTags = config['subTags'] as List?;
          if (subTags != null) {
            for (final selectedTag in value) {
              if (!subTags.contains(selectedTag)) {
                warnings.add('选中的子标签"$selectedTag"不在预设列表中');
              }
            }
          }
        }
        break;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 验证十六进制颜色格式
  static bool _isValidHexColor(String color) {
    final hexColorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexColorRegex.hasMatch(color);
  }

  /// 批量验证标签列表
  static ValidationResult validateTags(List<Tag> tags) {
    final results = tags.map((tag) => validateTag(tag)).toList();
    return ValidationResult.combine(results);
  }

  /// 批量验证标签记录列表
  static ValidationResult validateTagRecords(List<TagRecord> records, List<Tag> tags) {
    final results = <ValidationResult>[];
    
    for (final record in records) {
      final tag = tags.where((t) => t.id == record.tagId).firstOrNull;
      if (tag == null) {
        results.add(ValidationResult.failure(['找不到ID为${record.tagId}的标签']));
      } else {
        results.add(validateTagRecord(record, tag));
      }
    }
    
    return ValidationResult.combine(results);
  }
}