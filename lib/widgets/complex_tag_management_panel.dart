import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/tag_repository.dart';
import '../repositories/tag_record_repository.dart';

/// 拖拽数据包装类，用于区分不同面板的拖拽
class TagDragData {
  final Tag tag;
  final String source; // 'main' 或 'complex'

  const TagDragData({required this.tag, required this.source});
}

/// 复杂标签专用的折叠式标签管理面板组件
///
/// 用于管理复杂标签的子标签，支持：
/// - 显示复杂标签包含的量化和非量化子标签
/// - 动态添加新的子标签
/// - 子标签的聚焦模式显示
/// - 保存复杂标签的记录
class ComplexTagManagementPanel extends StatefulWidget {
  /// 当前选中的日期
  final DateTime selectedDate;

  /// 当前管理的复杂标签
  final Tag complexTag;

  /// 当前聚焦的子标签（用于单标签聚焦模式）
  final Tag? focusedSubTag;

  /// 子标签点击回调（用于单标签聚焦模式）
  final Function(Tag)? onSubTagTap;

  /// 子标签长按回调
  final Function(Tag)? onSubTagLongPress;

  /// 复杂标签记录保存回调
  final Function(Tag, List<String>)? onComplexTagSave;

  /// 面板关闭回调
  final VoidCallback? onClose;

  /// 数据更新回调（用于通知父组件刷新）
  final VoidCallback? onDataChanged;

  const ComplexTagManagementPanel({
    super.key,
    required this.selectedDate,
    required this.complexTag,
    this.focusedSubTag,
    this.onSubTagTap,
    this.onSubTagLongPress,
    this.onComplexTagSave,
    this.onClose,
    this.onDataChanged,
  });

  @override
  State<ComplexTagManagementPanel> createState() =>
      _ComplexTagManagementPanelState();
}

class _ComplexTagManagementPanelState extends State<ComplexTagManagementPanel>
    with SingleTickerProviderStateMixin {
  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  // 数据仓库
  final TagRepository _tagRepository = TagRepository();
  final TagRecordRepository _recordRepository = TagRecordRepository();

  // 数据状态
  List<Tag> _subTags = []; // 子标签列表
  Set<String> _selectedSubTagNames = {}; // 当日选中的子标签名称集合

  // 面板状态
  bool _isExpanded = true; // 默认展开
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 创建展开动画
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // 默认展开
    _animationController.forward();

    // 加载数据
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ComplexTagManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果选中日期或复杂标签发生变化，重新加载数据
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.complexTag.id != widget.complexTag.id) {
      _loadData();
    }
  }

  /// 刷新数据（供外部调用，用于无痕更新）
  Future<void> refreshData() async {
    await _loadData();
  }

  /// 加载子标签和记录数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取复杂标签的子标签名称列表
      final subTagNames = widget.complexTag.complexSubTags;
      debugPrint(
        'ComplexTagManagementPanel: 复杂标签 ${widget.complexTag.name} 包含 ${subTagNames.length} 个子标签',
      );

      // 尝试从复杂标签配置中获取子标签的完整信息
      List<Tag> subTags;
      if (widget.complexTag.config.containsKey('subTagsConfig')) {
        // 使用新版本的完整配置信息
        final subTagsConfig = List<Map<String, dynamic>>.from(
          widget.complexTag.config['subTagsConfig'],
        );

        subTags = subTagsConfig.asMap().entries.map((entry) {
          final index = entry.key;
          final subTagData = entry.value;
          final name = subTagData['name'] as String;
          final typeString = subTagData['type'].toString();
          final config = Map<String, dynamic>.from(subTagData['config'] ?? {});

          // 解析标签类型
          TagType subTagType = TagType.binary;
          if (typeString.contains('quantitative')) {
            subTagType = TagType.quantitative;
          } else if (typeString.contains('binary')) {
            subTagType = TagType.binary;
          }

          return Tag(
            id: '${widget.complexTag.id}_sub_$index',
            name: name,
            type: subTagType,
            config: config,
            color: widget.complexTag.color,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      } else {
        // 兼容旧版本，使用推断的方式
        subTags = subTagNames.asMap().entries.map((entry) {
          final index = entry.key;
          final name = entry.value;

          // 根据子标签名称推断类型（这里可以根据实际需求调整）
          TagType subTagType = TagType.binary; // 默认为非量化标签
          Map<String, dynamic> subTagConfig = {'icon': '✓'};

          // 为某些特定的子标签设置为量化类型
          if (name.contains('加班') ||
              name.contains('时长') ||
              name.contains('次数')) {
            subTagType = TagType.quantitative;
            subTagConfig = {
              'minValue': 0.0,
              'maxValue': 12.0,
              'unit': name.contains('加班') ? '小时' : '',
            };
          }

          return Tag(
            id: '${widget.complexTag.id}_sub_$index',
            name: name,
            type: subTagType,
            config: subTagConfig,
            color: widget.complexTag.color,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
      }

      debugPrint('ComplexTagManagementPanel: 创建了 ${subTags.length} 个子标签显示对象');

      // 加载当日的复杂标签记录
      final complexRecord = await _recordRepository.findByTagAndDate(
        widget.complexTag.id,
        widget.selectedDate,
      );

      Set<String> selectedSubTagNames = {};
      if (complexRecord != null && complexRecord.listValue.isNotEmpty) {
        selectedSubTagNames = complexRecord.listValue.toSet();
        debugPrint(
          'ComplexTagManagementPanel: 当日已选中 ${selectedSubTagNames.length} 个子标签',
        );
      }

      setState(() {
        _subTags = subTags;
        _selectedSubTagNames = selectedSubTagNames;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载复杂标签数据失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 切换面板展开/折叠状态
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  /// 处理子标签点击
  void _handleSubTagTap(Tag subTag) {
    // 检查子标签是否已选中
    final isSelected = _selectedSubTagNames.contains(subTag.name);

    if (isSelected) {
      // 已选中的子标签：调用外部回调（用于聚焦模式）
      widget.onSubTagTap?.call(subTag);
    } else {
      // 未选中的子标签：点击无效果（删除原先的添加逻辑）
      debugPrint('未选中子标签的点击操作被忽略: ${subTag.name}');
    }
  }

  /// 处理子标签长按
  void _handleSubTagLongPress(Tag subTag) {
    // 检查子标签是否已选中
    final isSelected = _selectedSubTagNames.contains(subTag.name);

    if (isSelected) {
      // 已选中的子标签：调用外部回调
      widget.onSubTagLongPress?.call(subTag);
    } else {
      // 未选中的子标签：长按无效果（删除原先的添加逻辑）
      debugPrint('未选中子标签的长按操作被忽略: ${subTag.name}');
    }
  }

  /// 处理子标签拖拽到已选中区域
  Future<void> _handleSubTagDrop(TagDragData dragData) async {
    // 只接受来自复杂标签面板的拖拽
    if (dragData.source != 'complex') {
      debugPrint('拒绝来自其他面板的拖拽: ${dragData.tag.name}');
      return;
    }

    final subTag = dragData.tag;

    // 检查子标签是否已经选中
    if (_selectedSubTagNames.contains(subTag.name)) {
      debugPrint('子标签已选中，忽略拖拽: ${subTag.name}');
      return;
    }

    // 添加子标签到选中列表
    setState(() {
      _selectedSubTagNames.add(subTag.name);
      debugPrint('通过拖拽选中子标签: ${subTag.name}');
    });

    // 自动保存复杂标签记录
    await _saveComplexTagRecord();
  }

  /// 处理子标签拖拽到未选中区域（取消选择）
  Future<void> _handleSubTagRemove(TagDragData dragData) async {
    // 只接受来自复杂标签面板的拖拽
    if (dragData.source != 'complex') {
      debugPrint('拒绝来自其他面板的拖拽: ${dragData.tag.name}');
      return;
    }

    final subTag = dragData.tag;

    // 检查子标签是否已经选中
    if (!_selectedSubTagNames.contains(subTag.name)) {
      debugPrint('子标签未选中，无需取消: ${subTag.name}');
      return;
    }

    // 从选中列表中移除子标签
    setState(() {
      _selectedSubTagNames.remove(subTag.name);
      debugPrint('通过拖拽取消选中子标签: ${subTag.name}');
    });

    // 自动保存复杂标签记录
    await _saveComplexTagRecord();

    // 控制台输出成功信息
    debugPrint('✅ 已取消选择子标签: ${subTag.name}');
  }

  /// 保存复杂标签记录
  Future<void> _saveComplexTagRecord() async {
    try {
      final selectedList = _selectedSubTagNames.toList();

      // 查找是否已有记录
      final existingRecord = await _recordRepository.findByTagAndDate(
        widget.complexTag.id,
        widget.selectedDate,
      );

      if (selectedList.isEmpty) {
        // 如果没有选中任何子标签，删除记录
        if (existingRecord != null) {
          await _recordRepository.deleteById(existingRecord.id);
          debugPrint('删除复杂标签记录: ${widget.complexTag.name}');
        }
      } else {
        if (existingRecord != null) {
          // 更新现有记录
          final updatedRecord = existingRecord.copyWith(
            value: selectedList,
            updatedAt: DateTime.now(),
          );
          await _recordRepository.update(updatedRecord);
          debugPrint('更新复杂标签记录: ${widget.complexTag.name} = $selectedList');
        } else {
          // 创建新记录
          final newRecord = TagRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            tagId: widget.complexTag.id,
            date: widget.selectedDate,
            value: selectedList,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _recordRepository.insert(newRecord);
          debugPrint('创建复杂标签记录: ${widget.complexTag.name} = $selectedList');
        }
      }

      // 调用外部回调
      widget.onComplexTagSave?.call(widget.complexTag, selectedList);

      // 通知父组件数据已更新
      widget.onDataChanged?.call();
    } catch (e) {
      debugPrint('保存复杂标签记录失败: $e');
      // 错误信息已通过debugPrint输出
    }
  }

  /// 显示添加子标签对话框（带配置选项）
  void _showAddSubTagDialog() {
    final nameController = TextEditingController();
    final minValueController = TextEditingController(text: '1');
    final maxValueController = TextEditingController(text: '10');
    final unitController = TextEditingController();
    final iconController = TextEditingController(text: '✓');

    TagType selectedType = TagType.binary;

    // 预定义图标
    final predefinedIcons = [
      '✓',
      '×',
      '★',
      '♥',
      '●',
      '■',
      '▲',
      '♦',
      '☀',
      '☁',
      '☂',
      '⚡',
      '❄',
      '🔥',
      '💧',
      '🌟',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('添加子标签'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '子标签名称',
                    hintText: '输入子标签名称',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TagType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: '标签类型'),
                  items: [TagType.quantitative, TagType.binary].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getTagTypeIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(type == TagType.quantitative ? '量化' : '非量化'),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 根据类型显示不同的配置选项
                if (selectedType == TagType.quantitative) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '量化配置',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minValueController,
                          decoration: const InputDecoration(
                            labelText: '最小值',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxValueController,
                          decoration: const InputDecoration(
                            labelText: '最大值',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: '单位（可选）',
                      hintText: '如：分、次、小时等',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else if (selectedType == TagType.binary) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '图标配置',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: iconController,
                    decoration: const InputDecoration(
                      labelText: '图标',
                      hintText: '选择或输入图标',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '预设图标',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: predefinedIcons.take(8).map((icon) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            iconController.text = icon;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: iconController.text == icon
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              width: iconController.text == icon ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请输入子标签名称')));
                  return;
                }

                // 验证量化标签的数值范围
                if (selectedType == TagType.quantitative) {
                  final minValue = double.tryParse(minValueController.text);
                  final maxValue = double.tryParse(maxValueController.text);

                  if (minValue == null || maxValue == null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('请输入有效的数值范围')));
                    return;
                  }

                  if (maxValue <= minValue) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('最大值必须大于最小值')));
                    return;
                  }
                }

                // 验证非量化标签的图标
                if (selectedType == TagType.binary &&
                    iconController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请选择或输入图标')));
                  return;
                }

                // 检查是否已存在同名标签
                if (_subTags.any((tag) => tag.name == name)) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('该子标签已存在')));
                  return;
                }

                // 构建配置对象
                Map<String, dynamic> config = {};
                if (selectedType == TagType.quantitative) {
                  config = {
                    'minValue': double.parse(minValueController.text),
                    'maxValue': double.parse(maxValueController.text),
                    'unit': unitController.text.trim(),
                  };
                } else if (selectedType == TagType.binary) {
                  config = {'icon': iconController.text.trim()};
                }

                Navigator.of(context).pop();
                await _addNewSubTagWithConfig(name, selectedType, config);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  /// 添加带配置的新子标签
  Future<void> _addNewSubTagWithConfig(
    String name,
    TagType type,
    Map<String, dynamic> config,
  ) async {
    try {
      // 创建新的子标签
      final now = DateTime.now();
      final newSubTag = Tag(
        id: now.millisecondsSinceEpoch.toString(),
        name: name,
        type: type,
        config: config,
        color: widget.complexTag.color, // 使用复杂标签的颜色
        createdAt: now,
        updatedAt: now,
      );

      // 保存到数据库
      await _tagRepository.insert(newSubTag);

      // 更新复杂标签的子标签列表和配置
      final updatedSubTags = List<String>.from(
        widget.complexTag.complexSubTags,
      );
      updatedSubTags.add(name);

      // 获取现有的子标签配置
      List<Map<String, dynamic>> subTagsConfig = [];
      if (widget.complexTag.config.containsKey('subTagsConfig')) {
        subTagsConfig = List<Map<String, dynamic>>.from(
          widget.complexTag.config['subTagsConfig'],
        );
      }

      // 添加新子标签的配置
      subTagsConfig.add({'name': name, 'type': type, 'config': config});

      final updatedComplexTag = widget.complexTag.copyWith(
        config: {
          ...widget.complexTag.config,
          'subTags': updatedSubTags,
          'subTagsConfig': subTagsConfig,
        },
        updatedAt: now,
      );

      await _tagRepository.update(updatedComplexTag);

      // 立即更新本地状态，避免重新加载
      setState(() {
        _subTags.add(newSubTag);
      });

      // 控制台输出成功信息
      debugPrint('✅ 已添加子标签: $name');
    } catch (e) {
      debugPrint('添加子标签失败: $e');
      // 错误信息已通过debugPrint输出
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 解析复杂标签颜色
    Color complexTagColor;
    try {
      complexTagColor = Color(
        int.parse(widget.complexTag.color.replaceFirst('#', '0xFF')),
      );
    } catch (e) {
      complexTagColor = colorScheme.primary;
    }

    return GestureDetector(
      // 阻止事件冒泡到父级的GestureDetector
      onTap: () {},
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // 标题栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: complexTagColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // 复杂标签图标
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: complexTagColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 标题
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.complexTag.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: complexTagColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '已选中 ${_selectedSubTagNames.length} 个子标签',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: complexTagColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 添加子标签按钮
                  IconButton(
                    onPressed: _showAddSubTagDialog,
                    icon: Icon(Icons.add, color: complexTagColor, size: 20),
                    tooltip: '添加子标签',
                  ),

                  // 展开/折叠按钮
                  IconButton(
                    onPressed: _toggleExpanded,
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: complexTagColor,
                      ),
                    ),
                  ),

                  // 关闭按钮
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close, color: complexTagColor, size: 20),
                  ),
                ],
              ),
            ),

            // 可展开的内容区域
            AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _expandAnimation.value,
                    child: child,
                  ),
                );
              },
              child: _isLoading
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : _buildContent(theme, colorScheme, complexTagColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主要内容
  Widget _buildContent(
    ThemeData theme,
    ColorScheme colorScheme,
    Color complexTagColor,
  ) {
    // 分离已选中和未选中的子标签（类似原先标签管理面板的逻辑）
    final selectedSubTags = _subTags
        .where((tag) => _selectedSubTagNames.contains(tag.name))
        .toList();
    final unselectedSubTags = _subTags
        .where((tag) => !_selectedSubTagNames.contains(tag.name))
        .toList();

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 已选中的子标签区域（支持拖拽目标）
          DragTarget<TagDragData>(
            onAcceptWithDetails: (details) => _handleSubTagDrop(details.data),
            builder: (context, candidateData, rejectedData) {
              final isHighlighted = candidateData.isNotEmpty;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: selectedSubTags.isNotEmpty
                    ? _buildSubTagGrid(
                        selectedSubTags,
                        theme,
                        colorScheme,
                        complexTagColor,
                      )
                    : Center(
                        child: Text(
                          isHighlighted ? '拖拽到此处选择子标签' : '今日暂未选择子标签',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isHighlighted
                                ? complexTagColor
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 4),

          // 未选中的子标签区域（支持拖拽目标）
          if (unselectedSubTags.isNotEmpty) ...[
            DragTarget<TagDragData>(
              onAcceptWithDetails: (details) =>
                  _handleSubTagRemove(details.data),
              builder: (context, candidateData, rejectedData) {
                final isHighlighted = candidateData.isNotEmpty;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Column(
                    children: [
                      if (isHighlighted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '拖拽到此处取消选择子标签',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      _buildSubTagGrid(
                        unselectedSubTags,
                        theme,
                        colorScheme,
                        complexTagColor,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 构建子标签网格
  Widget _buildSubTagGrid(
    List<Tag> subTags,
    ThemeData theme,
    ColorScheme colorScheme,
    Color complexTagColor,
  ) {
    if (subTags.isEmpty) {
      return const SizedBox.shrink();
    }

    // 计算网格列数（与原先标签管理面板保持一致）
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = 32; // 左右各16的边距
    final availableWidth = screenWidth - cardPadding - 32; // 减去内边距
    final minTagWidth = 80; // 标签最小宽度（与原先面板一致）
    final crossAxisCount = (availableWidth / minTagWidth).floor().clamp(2, 6);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.8, // 与原先标签管理面板一致
      ),
      itemCount: subTags.length,
      itemBuilder: (context, index) {
        final subTag = subTags[index];
        return _buildSubTagChip(subTag, theme, colorScheme, complexTagColor);
      },
    );
  }

  /// 构建单个子标签芯片
  Widget _buildSubTagChip(
    Tag subTag,
    ThemeData theme,
    ColorScheme colorScheme,
    Color complexTagColor,
  ) {
    // 检查是否为选中状态（已添加到当日记录）
    final isSelected = _selectedSubTagNames.contains(subTag.name);

    // 检查是否为聚焦状态
    final isFocused = widget.focusedSubTag?.id == subTag.id;

    // 根据状态确定样式（与原先标签管理面板保持一致）
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    double borderWidth = 1;

    if (isFocused) {
      // 聚焦状态：高亮显示
      backgroundColor = complexTagColor.withValues(alpha: 0.3);
      borderColor = complexTagColor;
      textColor = complexTagColor;
      borderWidth = 2; // 加粗边框作为聚焦指示器
    } else if (isSelected) {
      // 已选中但未聚焦：原色显示（类似原先面板的已添加标签）
      backgroundColor = complexTagColor.withValues(alpha: 0.2);
      borderColor = complexTagColor;
      textColor = complexTagColor;
    } else {
      // 未选中：半透明显示（类似原先面板的未添加标签）
      backgroundColor = complexTagColor.withValues(alpha: 0.08);
      borderColor = complexTagColor.withValues(alpha: 0.3);
      textColor = complexTagColor.withValues(alpha: 0.6);
    }

    // 构建子标签内容
    Widget subTagContent = Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(8),
        // 聚焦状态添加阴影效果
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: complexTagColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标签类型图标和聚焦指示器
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(_getTagTypeIcon(subTag.type), size: 14, color: textColor),
                // 聚焦指示器：右上角小圆点
                if (isFocused)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: complexTagColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),

            // 子标签名称
            Flexible(
              child: Text(
                subTag.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: isFocused
                      ? FontWeight.w600
                      : (isSelected ? FontWeight.w500 : FontWeight.normal),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // 如果是未选中的子标签，支持拖拽到已选中区域
    if (!isSelected) {
      return Draggable<TagDragData>(
        data: TagDragData(tag: subTag, source: 'complex'),
        feedback: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          child: Container(
            width: 80, // 固定宽度，避免拖拽时变形
            height: 44, // 固定高度
            child: subTagContent,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _handleSubTagTap(subTag),
              onLongPress: () => _handleSubTagLongPress(subTag),
              borderRadius: BorderRadius.circular(8),
              child: subTagContent,
            ),
          ),
        ),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => _handleSubTagTap(subTag),
            onLongPress: () => _handleSubTagLongPress(subTag),
            borderRadius: BorderRadius.circular(8),
            child: subTagContent,
          ),
        ),
      );
    } else {
      // 已选中的子标签，支持拖拽到未选中区域删除记录
      return Draggable<TagDragData>(
        data: TagDragData(tag: subTag, source: 'complex'),
        feedback: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          child: Container(
            width: 80, // 固定宽度，避免拖拽时变形
            height: 44, // 固定高度
            child: subTagContent,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _handleSubTagTap(subTag),
              onLongPress: () => _handleSubTagLongPress(subTag),
              borderRadius: BorderRadius.circular(8),
              child: subTagContent,
            ),
          ),
        ),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => _handleSubTagTap(subTag),
            onLongPress: () => _handleSubTagLongPress(subTag),
            borderRadius: BorderRadius.circular(8),
            child: subTagContent,
          ),
        ),
      );
    }
  }

  /// 获取标签类型对应的图标
  IconData _getTagTypeIcon(TagType type) {
    switch (type) {
      case TagType.quantitative:
        return Icons.trending_up;
      case TagType.binary:
        return Icons.check_circle_outline;
      case TagType.complex:
        return Icons.category_outlined;
    }
  }
}
