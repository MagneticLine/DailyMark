/// 标签记录数据模型
/// 
/// 表示用户在特定日期对某个标签的记录
/// 根据标签类型存储不同格式的数据
class TagRecord {
  /// 记录唯一标识符
  final String id;
  
  /// 关联的标签ID
  final String tagId;
  
  /// 记录日期
  final DateTime date;
  
  /// 记录值（根据标签类型存储不同数据）
  /// 
  /// 不同类型的存储格式：
  /// - 量化标签：存储数值，如 8.5
  /// - 非量化标签：存储布尔值，如 true/false
  /// - 复杂标签：存储选中的子标签列表，如 ['深度睡眠', '8小时']
  final dynamic value;
  
  /// 是否为预测数据
  final bool isPrediction;
  
  /// 预测置信度（0.0-1.0，仅预测数据有效）
  final double? confidence;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后修改时间
  final DateTime updatedAt;
  
  /// 备注信息
  final String? note;

  /// 构造函数
  const TagRecord({
    required this.id,
    required this.tagId,
    required this.date,
    required this.value,
    this.isPrediction = false,
    this.confidence,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  /// 从Map创建TagRecord对象（用于数据库读取）
  factory TagRecord.fromMap(Map<String, dynamic> map) {
    return TagRecord(
      id: map['id'] as String,
      tagId: map['tag_id'] as String,
      date: DateTime.parse(map['date'] as String),
      value: _parseValue(map['value']),
      isPrediction: (map['is_prediction'] as int) == 1,
      confidence: map['confidence'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      note: map['note'] as String?,
    );
  }

  /// 解析存储的值
  static dynamic _parseValue(dynamic storedValue) {
    if (storedValue is String) {
      // 尝试解析为数字
      final numValue = double.tryParse(storedValue);
      if (numValue != null) {
        return numValue;
      }
      
      // 尝试解析为布尔值
      if (storedValue.toLowerCase() == 'true') {
        return true;
      } else if (storedValue.toLowerCase() == 'false') {
        return false;
      }
      
      // 尝试解析为列表（复杂标签的子标签）
      if (storedValue.startsWith('[') && storedValue.endsWith(']')) {
        try {
          // 简单的列表解析（实际项目中可能需要使用JSON解析）
          final content = storedValue.substring(1, storedValue.length - 1);
          if (content.isEmpty) return <String>[];
          return content.split(',').map((s) => s.trim().replaceAll('"', '')).toList();
        } catch (e) {
          return storedValue;
        }
      }
      
      return storedValue;
    }
    return storedValue;
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tag_id': tagId,
      'date': date.toIso8601String().split('T')[0], // 只存储日期部分
      'value': _serializeValue(value),
      'is_prediction': isPrediction ? 1 : 0,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'note': note,
    };
  }

  /// 序列化值用于存储
  static String _serializeValue(dynamic value) {
    if (value is List) {
      // 将列表转换为字符串格式存储
      return '[${value.map((item) => '"$item"').join(', ')}]';
    }
    return value.toString();
  }

  /// 创建副本并修改部分属性
  TagRecord copyWith({
    String? id,
    String? tagId,
    DateTime? date,
    dynamic value,
    bool? isPrediction,
    double? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
  }) {
    return TagRecord(
      id: id ?? this.id,
      tagId: tagId ?? this.tagId,
      date: date ?? this.date,
      value: value ?? this.value,
      isPrediction: isPrediction ?? this.isPrediction,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  /// 获取数值类型的值（用于量化标签）
  double? get numericValue {
    if (value is num) {
      return (value as num).toDouble();
    }
    return null;
  }

  /// 获取布尔类型的值（用于非量化标签）
  bool? get booleanValue {
    if (value is bool) {
      return value as bool;
    }
    return null;
  }

  /// 获取列表类型的值（用于复杂标签）
  List<String> get listValue {
    if (value is List) {
      return List<String>.from(value as List);
    }
    return [];
  }

  /// 检查记录是否有效（非空值）
  bool get hasValue {
    if (value == null) return false;
    if (value is List) return (value as List).isNotEmpty;
    if (value is String) return (value as String).isNotEmpty;
    return true;
  }

  /// 获取显示用的值字符串
  String get displayValue {
    if (value is bool) {
      return (value as bool) ? '是' : '否';
    } else if (value is List) {
      return (value as List).join(', ');
    } else if (value is num) {
      return value.toString();
    }
    return value?.toString() ?? '';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagRecord && 
           other.id == id && 
           other.tagId == tagId && 
           other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, tagId, date);

  @override
  String toString() {
    return 'TagRecord(id: $id, tagId: $tagId, date: $date, value: $value, isPrediction: $isPrediction)';
  }
}