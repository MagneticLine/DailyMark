/// 标签类型枚举
/// 
/// 定义了应用中支持的三种标签类型：
/// - quantitative: 量化标签，用于数值评分（如心情1-10分）
/// - binary: 非量化标签，用于是/否状态（如是否运动）
/// - complex: 复杂标签，用于多子标签选择（如睡眠质量的多个维度）
enum TagType {
  /// 量化标签 - 支持数值评分和范围设置
  /// 例如：心情评分(1-10)、体重记录、学习时长等
  quantitative('quantitative', '量化标签'),
  
  /// 非量化标签 - 简单的是/否或图标标记
  /// 例如：是否运动、是否早起、天气状况等
  binary('binary', '非量化标签'),
  
  /// 复杂标签 - 支持多个子标签的组合选择
  /// 例如：睡眠状态(深度、时长、质量)、饮食记录(种类、份量、时间)等
  complex('complex', '复杂标签');

  /// 构造函数
  const TagType(this.value, this.displayName);

  /// 枚举值（用于数据库存储）
  final String value;
  
  /// 显示名称（用于UI显示）
  final String displayName;

  /// 从字符串值创建枚举
  /// 
  /// [value] 字符串值
  /// 返回对应的TagType枚举，如果找不到则返回null
  static TagType? fromString(String value) {
    for (TagType type in TagType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }

  /// 获取所有可用的标签类型
  /// 
  /// 返回包含所有标签类型的列表，用于UI选择器
  static List<TagType> getAllTypes() {
    return TagType.values;
  }

  /// 检查是否为量化类型
  bool get isQuantitative => this == TagType.quantitative;

  /// 检查是否为非量化类型
  bool get isBinary => this == TagType.binary;

  /// 检查是否为复杂类型
  bool get isComplex => this == TagType.complex;

  @override
  String toString() => displayName;
}