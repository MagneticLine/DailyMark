import 'tag_type.dart';

/// 标签数据模型
/// 
/// 表示用户创建的标签，包含标签的基本信息和配置
/// 支持三种类型：量化、非量化、复杂标签
class Tag {
  /// 标签唯一标识符
  final String id;
  
  /// 标签名称
  final String name;
  
  /// 标签类型
  final TagType type;
  
  /// 标签配置信息（JSON格式存储）
  /// 
  /// 不同类型的标签有不同的配置：
  /// - 量化标签：{'minValue': 1, 'maxValue': 10, 'unit': '分', 'labels': ['差', '良', '优']}
  /// - 非量化标签：{'icon': '✓', 'activeColor': '#4CAF50'}
  /// - 复杂标签：{'subTags': ['深度睡眠', '浅度睡眠', '失眠']}
  final Map<String, dynamic> config;
  
  /// 标签颜色（十六进制格式，如 #FF5722）
  final String color;
  
  /// 是否启用周期预测
  final bool enablePrediction;
  
  /// 周期设置（天数，null表示未设置）
  final int? cycleDays;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后修改时间
  final DateTime updatedAt;
  
  /// 是否激活（软删除标记）
  final bool isActive;

  /// 构造函数
  const Tag({
    required this.id,
    required this.name,
    required this.type,
    required this.config,
    required this.color,
    this.enablePrediction = false,
    this.cycleDays,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// 从Map创建Tag对象（用于数据库读取）
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      type: TagType.fromString(map['type'] as String) ?? TagType.quantitative,
      config: Map<String, dynamic>.from(map['config'] as Map),
      color: map['color'] as String,
      enablePrediction: (map['enable_prediction'] as int) == 1,
      cycleDays: map['cycle_days'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'config': config,
      'color': color,
      'enable_prediction': enablePrediction ? 1 : 0,
      'cycle_days': cycleDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// 创建副本并修改部分属性
  Tag copyWith({
    String? id,
    String? name,
    TagType? type,
    Map<String, dynamic>? config,
    String? color,
    bool? enablePrediction,
    int? cycleDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      config: config ?? this.config,
      color: color ?? this.color,
      enablePrediction: enablePrediction ?? this.enablePrediction,
      cycleDays: cycleDays ?? this.cycleDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 获取量化标签的最小值
  double? get quantitativeMinValue {
    if (type.isQuantitative && config.containsKey('minValue')) {
      return (config['minValue'] as num).toDouble();
    }
    return null;
  }

  /// 获取量化标签的最大值
  double? get quantitativeMaxValue {
    if (type.isQuantitative && config.containsKey('maxValue')) {
      return (config['maxValue'] as num).toDouble();
    }
    return null;
  }

  /// 获取量化标签的单位
  String? get quantitativeUnit {
    if (type.isQuantitative && config.containsKey('unit')) {
      return config['unit'] as String;
    }
    return null;
  }

  /// 获取非量化标签的图标
  String? get binaryIcon {
    if (type.isBinary && config.containsKey('icon')) {
      return config['icon'] as String;
    }
    return null;
  }

  /// 获取复杂标签的子标签列表
  List<String> get complexSubTags {
    if (type.isComplex && config.containsKey('subTags')) {
      return List<String>.from(config['subTags'] as List);
    }
    return [];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, type: $type)';
  }
}