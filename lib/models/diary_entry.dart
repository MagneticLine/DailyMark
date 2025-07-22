/// 多媒体附件数据模型
/// 
/// 表示日记条目中的图像、音频、视频等附件
class MediaAttachment {
  /// 附件唯一标识符
  final String id;
  
  /// 附件类型
  final MediaType type;
  
  /// 文件路径（本地存储路径）
  final String filePath;
  
  /// 文件名
  final String fileName;
  
  /// 文件大小（字节）
  final int fileSize;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 缩略图路径（可选，主要用于图片和视频）
  final String? thumbnailPath;

  const MediaAttachment({
    required this.id,
    required this.type,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    this.thumbnailPath,
  });

  /// 从Map创建MediaAttachment对象
  factory MediaAttachment.fromMap(Map<String, dynamic> map) {
    return MediaAttachment(
      id: map['id'] as String,
      type: MediaType.fromString(map['type'] as String) ?? MediaType.image,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileSize: map['file_size'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      thumbnailPath: map['thumbnail_path'] as String?,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'thumbnail_path': thumbnailPath,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaAttachment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 多媒体类型枚举
enum MediaType {
  image('image', '图片'),
  audio('audio', '音频'),
  video('video', '视频');

  const MediaType(this.value, this.displayName);

  final String value;
  final String displayName;

  static MediaType? fromString(String value) {
    for (MediaType type in MediaType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}

/// 日记条目数据模型
/// 
/// 表示用户在特定日期的日记记录，包含文本内容和多媒体附件
/// 与标签记录关联，形成完整的日常记录
class DiaryEntry {
  /// 日记条目唯一标识符
  final String id;
  
  /// 日记日期
  final DateTime date;
  
  /// 日记文本内容
  final String content;
  
  /// 多媒体附件列表
  final List<MediaAttachment> attachments;
  
  /// 关联的标签记录ID列表
  final List<String> tagRecordIds;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后修改时间
  final DateTime updatedAt;
  
  /// 心情评分（1-10，可选）
  final int? moodScore;
  
  /// 天气信息（可选）
  final String? weather;

  /// 构造函数
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    this.attachments = const [],
    this.tagRecordIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.moodScore,
    this.weather,
  });

  /// 从Map创建DiaryEntry对象（用于数据库读取）
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      content: map['content'] as String,
      attachments: _parseAttachments(map['attachments']),
      tagRecordIds: _parseTagRecordIds(map['tag_record_ids']),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      moodScore: map['mood_score'] as int?,
      weather: map['weather'] as String?,
    );
  }

  /// 解析附件列表
  static List<MediaAttachment> _parseAttachments(dynamic attachmentsData) {
    if (attachmentsData == null) return [];
    
    // 这里简化处理，实际项目中可能需要JSON解析
    if (attachmentsData is String && attachmentsData.isEmpty) {
      return [];
    }
    
    // 实际实现中，这里应该解析JSON字符串为MediaAttachment列表
    return [];
  }

  /// 解析标签记录ID列表
  static List<String> _parseTagRecordIds(dynamic tagRecordIdsData) {
    if (tagRecordIdsData == null) return [];
    
    if (tagRecordIdsData is String) {
      if (tagRecordIdsData.isEmpty) return [];
      
      // 简单的逗号分隔解析
      return tagRecordIdsData.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    
    return [];
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // 只存储日期部分
      'content': content,
      'attachments': _serializeAttachments(attachments),
      'tag_record_ids': tagRecordIds.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'mood_score': moodScore,
      'weather': weather,
    };
  }

  /// 序列化附件列表
  static String _serializeAttachments(List<MediaAttachment> attachments) {
    if (attachments.isEmpty) return '';
    
    // 实际实现中，这里应该将附件列表序列化为JSON字符串
    // 这里简化处理
    return attachments.map((a) => a.id).join(',');
  }

  /// 创建副本并修改部分属性
  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    List<MediaAttachment>? attachments,
    List<String>? tagRecordIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? moodScore,
    String? weather,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      tagRecordIds: tagRecordIds ?? this.tagRecordIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moodScore: moodScore ?? this.moodScore,
      weather: weather ?? this.weather,
    );
  }

  /// 检查是否有内容
  bool get hasContent {
    return content.trim().isNotEmpty || attachments.isNotEmpty;
  }

  /// 获取内容摘要（用于列表显示）
  String get contentSummary {
    if (content.isEmpty) return '无文字内容';
    
    const maxLength = 50;
    if (content.length <= maxLength) {
      return content;
    }
    
    return '${content.substring(0, maxLength)}...';
  }

  /// 获取附件数量统计
  Map<MediaType, int> get attachmentCounts {
    final counts = <MediaType, int>{};
    for (final attachment in attachments) {
      counts[attachment.type] = (counts[attachment.type] ?? 0) + 1;
    }
    return counts;
  }

  /// 检查是否有图片附件
  bool get hasImages => attachments.any((a) => a.type == MediaType.image);

  /// 检查是否有音频附件
  bool get hasAudio => attachments.any((a) => a.type == MediaType.audio);

  /// 检查是否有视频附件
  bool get hasVideo => attachments.any((a) => a.type == MediaType.video);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DiaryEntry(id: $id, date: $date, contentLength: ${content.length}, attachments: ${attachments.length})';
  }
}