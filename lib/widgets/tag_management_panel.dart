import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/tag_repository.dart';
import '../repositories/tag_record_repository.dart';

/// 拖拽数据包装类，用于区分不同面板的拖拽
class TagDragData {
  final Tag tag;
  final String source; // 'main' 或 'complex'
  
  const TagDragData({
    required this.tag,
    required this.source,
  });
}

/// 折叠式标签管理面板组件
/// 
/// 提供折叠/展开的标签管理界面，布局结构：
/// - 上方：显示当日已选中的标签（原色显示）
/// - 下方：窄窄的折叠条，点击后展开显示未选中的标签（半透明显示）
/// - 支持长按交互功能
/// - 与日历宽度一致的设计
/// - 支持单标签聚焦模式的视觉指示
class TagManagementPanel extends StatefulWidget {
  /// 当前选中的日期
  final DateTime selectedDate;
  
  /// 当前聚焦的标签（用于单标签聚焦模式）
  final Tag? focusedTag;
  
  /// 标签可见性变化回调
  final Function(Tag, bool)? onTagVisibilityChanged;
  
  /// 标签长按回调
  final Function(Tag)? onTagLongPress;
  
  /// 标签点击回调（用于单标签聚焦模式）
  final Function(Tag)? onTagTap;
  
  /// 数据更新回调（用于通知父组件刷新）
  final VoidCallback? onDataChanged;

  const TagManagementPanel({
    super.key,
    required this.selectedDate,
    this.focusedTag,
    this.onTagVisibilityChanged,
    this.onTagLongPress,
    this.onTagTap,
    this.onDataChanged,
  });

  @override
  State<TagManagementPanel> createState() => _TagManagementPanelState();
}

class _TagManagementPanelState extends State<TagManagementPanel>
    with SingleTickerProviderStateMixin {
  
  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  // 数据仓库
  final TagRepository _tagRepository = TagRepository();
  final TagRecordRepository _recordRepository = TagRecordRepository();
  
  // 数据状态
  List<Tag> _allTags = [];
  Set<String> _addedTagIds = {}; // 当日已添加的标签ID集合
  
  // 面板状态
  bool _isExpanded = false;
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
    
    // 加载数据
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TagManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果选中日期发生变化，重新加载数据
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadData();
    }
    
    // 如果进入聚焦模式，自动折叠面板
    if (oldWidget.focusedTag == null && widget.focusedTag != null) {
      if (_isExpanded) {
        setState(() {
          _isExpanded = false;
        });
        _animationController.reverse();
        debugPrint('进入聚焦模式，自动折叠标签管理面板');
      }
    }
  }

  /// 刷新数据（供外部调用，用于无痕更新）
  Future<void> refreshData() async {
    await _loadData();
  }

  /// 加载标签和记录数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 加载所有激活的标签
      final allTags = await _tagRepository.findActive();
      debugPrint('TagManagementPanel: 加载到 ${allTags.length} 个标签');
      
      // 加载当日的标签记录
      final records = await _recordRepository.findByDate(widget.selectedDate);
      final addedTagIds = records.map((record) => record.tagId).toSet();
      debugPrint('TagManagementPanel: 当日有 ${records.length} 条记录，涉及 ${addedTagIds.length} 个标签');
      
      setState(() {
        _allTags = allTags;
        _addedTagIds = addedTagIds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载标签数据失败: $e');
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

  /// 处理标签点击
  void _handleTagTap(Tag tag) {
    // 所有标签点击都进入聚焦模式，方便查看标签在其他日期的使用情况
    widget.onTagTap?.call(tag);
    debugPrint('标签点击进入聚焦模式: ${tag.name}');
  }

  /// 处理标签长按
  void _handleTagLongPress(Tag tag) {
    // 检查标签是否已添加到当日记录
    final isAdded = _addedTagIds.contains(tag.id);
    
    if (isAdded) {
      // 已添加的标签：调用外部回调（显示修改/删除对话框）
      widget.onTagLongPress?.call(tag);
    } else {
      // 未添加的标签：长按无效果（删除原先的添加逻辑）
      debugPrint('未添加标签的长按操作被忽略: ${tag.name}');
    }
  }

  /// 处理标签拖拽到已选中区域
  Future<void> _handleTagDrop(TagDragData dragData) async {
    // 只接受来自主面板的拖拽
    if (dragData.source != 'main') {
      debugPrint('拒绝来自其他面板的拖拽: ${dragData.tag.name}');
      return;
    }
    
    final tag = dragData.tag;
    
    // 检查标签是否已经添加
    if (_addedTagIds.contains(tag.id)) {
      debugPrint('标签已存在，忽略拖拽: ${tag.name}');
      return;
    }
    
    await _addTagToToday(tag);
  }

  /// 处理标签拖拽到未选中区域（删除记录）
  Future<void> _handleTagRemove(TagDragData dragData) async {
    // 只接受来自主面板的拖拽
    if (dragData.source != 'main') {
      debugPrint('拒绝来自其他面板的拖拽: ${dragData.tag.name}');
      return;
    }
    
    final tag = dragData.tag;
    
    // 检查标签是否已经添加
    if (!_addedTagIds.contains(tag.id)) {
      debugPrint('标签未添加，无需删除: ${tag.name}');
      return;
    }
    
    await _removeTagFromToday(tag);
  }

  /// 从当日记录中删除标签
  Future<void> _removeTagFromToday(Tag tag) async {
    try {
      debugPrint('从当日删除标签: ${tag.name}');
      
      // 查找当日该标签的记录
      final existingRecord = await _recordRepository.findByTagAndDate(tag.id, widget.selectedDate);
      
      if (existingRecord != null) {
        // 删除记录
        await _recordRepository.deleteById(existingRecord.id);
        debugPrint('删除标签记录: ${tag.name}');
        
        // 立即更新本地状态，避免重新加载
        setState(() {
          _addedTagIds.remove(tag.id);
        });
        
        // 通知父组件数据已更新
        widget.onDataChanged?.call();
        
        // 控制台输出成功信息
        debugPrint('✅ 已删除标签记录: ${tag.name}');
      } else {
        debugPrint('未找到要删除的记录: ${tag.name}');
      }
    } catch (e) {
      debugPrint('删除标签记录失败: $e');
      // 错误信息已通过debugPrint输出
    }
  }

  /// 添加标签到当日记录
  Future<void> _addTagToToday(Tag tag) async {
    try {
      debugPrint('添加标签到当日: ${tag.name}');
      
      if (tag.type.isQuantitative) {
        // 量化标签：弹出数值输入窗口
        _showQuantitativeTagDialog(tag);
      } else if (tag.type.isBinary) {
        // 非量化标签：直接生效
        await _saveTagRecord(tag, true);
      } else if (tag.type.isComplex) {
        // 复杂标签：直接生效（空的子标签列表）
        await _saveTagRecord(tag, <String>[]);
      }
    } catch (e) {
      debugPrint('添加标签失败: $e');
      // 错误信息已通过debugPrint输出
    }
  }

  /// 显示量化标签数值输入对话框
  void _showQuantitativeTagDialog(Tag tag) {
    final minValue = tag.quantitativeMinValue ?? 1.0;
    final maxValue = tag.quantitativeMaxValue ?? 10.0;
    final unit = tag.quantitativeUnit ?? '';
    
    final controller = TextEditingController(text: minValue.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('输入${tag.name}的数值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '数值',
                hintText: '输入 $minValue - $maxValue 之间的数值',
                suffixText: unit.isNotEmpty ? unit : null,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              '范围: $minValue - $maxValue${unit.isNotEmpty ? ' $unit' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final valueText = controller.text.trim();
              final value = double.tryParse(valueText);
              
              if (value == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的数值')),
                );
                return;
              }
              
              if (value < minValue || value > maxValue) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('数值必须在 $minValue - $maxValue 之间')),
                );
                return;
              }
              
              Navigator.of(context).pop();
              await _saveTagRecord(tag, value);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 保存标签记录
  Future<void> _saveTagRecord(Tag tag, dynamic value) async {
    try {
      // 创建新记录
      final newRecord = TagRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tagId: tag.id,
        date: widget.selectedDate,
        value: value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _recordRepository.insert(newRecord);
      debugPrint('创建标签记录: ${tag.name} = $value');
      
      // 立即更新本地状态，避免重新加载
      setState(() {
        _addedTagIds.add(tag.id);
      });
      
      // 通知父组件数据已更新
      debugPrint('🔔 调用 onDataChanged 回调');
      widget.onDataChanged?.call();
      
      // 控制台输出成功信息
      debugPrint('✅ 已添加标签: ${tag.name}');
    } catch (e) {
      debugPrint('保存标签记录失败: $e');
      // 错误信息已通过debugPrint输出
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    if (_allTags.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildEmptyState(theme, colorScheme),
      );
    }
    
    // 分离已选中和未选中的标签
    final selectedTags = _allTags.where((tag) => _addedTagIds.contains(tag.id)).toList();
    final unselectedTags = _allTags.where((tag) => !_addedTagIds.contains(tag.id)).toList();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 聚焦模式提示条
          if (widget.focusedTag != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.center_focus_strong,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '聚焦模式：${widget.focusedTag!.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '点击空白处退出',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          
          // 主要内容区域：显示已选中的标签（支持拖拽目标）
          DragTarget<TagDragData>(
            onAcceptWithDetails: (details) => _handleTagDrop(details.data),
            builder: (context, candidateData, rejectedData) {
              final isHighlighted = candidateData.isNotEmpty;
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: selectedTags.isNotEmpty
                    ? _buildTagGrid(selectedTags, true, theme, colorScheme)
                    : Center(
                        child: Text(
                          isHighlighted 
                              ? '拖拽到此处启用标签'
                              : '今日暂无标签记录',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isHighlighted 
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
              );
            },
          ),
          
          // 可展开的未选中标签区域（支持拖拽目标）
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
            child: unselectedTags.isNotEmpty
                ? DragTarget<TagDragData>(
                    onAcceptWithDetails: (details) => _handleTagRemove(details.data),
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
                                  '拖拽到此处删除标签记录',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            _buildTagGrid(unselectedTags, false, theme, colorScheme),
                          ],
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
          
          // 底部折叠条（只有未选中标签时才显示）
          if (unselectedTags.isNotEmpty)
            _buildBottomExpandBar(unselectedTags.length, theme, colorScheme),
        ],
      ),
    );
  }

  /// 构建底部展开条
  Widget _buildBottomExpandBar(int unselectedCount, ThemeData theme, ColorScheme colorScheme) {
    return InkWell(
      onTap: _toggleExpanded,
      child: Container(
        width: double.infinity,
        height: 32, // 窄窄的条
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          color: colorScheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 展开/折叠图标
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                size: 18,
              ),
            ),
            const SizedBox(width: 4),
            
            // 提示文本
            Text(
              _isExpanded ? '收起' : '更多标签 ($unselectedCount)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.label_off_outlined,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无标签',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击右上角标签管理按钮添加标签',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签网格
  Widget _buildTagGrid(List<Tag> tags, bool isSelected, ThemeData theme, ColorScheme colorScheme) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 计算网格列数（根据屏幕宽度自适应）
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = 32; // 左右各16的边距
    final availableWidth = screenWidth - cardPadding - 32; // 减去内边距
    final minTagWidth = 80; // 标签最小宽度
    final crossAxisCount = (availableWidth / minTagWidth).floor().clamp(2, 6);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.8, // 进一步调整宽高比，给标签更多高度
      ),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        return _buildTagChip(tag, isSelected, theme, colorScheme);
      },
    );
  }

  /// 构建单个标签芯片
  Widget _buildTagChip(Tag tag, bool isSelected, ThemeData theme, ColorScheme colorScheme) {
    // 解析标签颜色
    Color tagColor;
    try {
      tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      tagColor = colorScheme.primary;
    }
    
    // 检查是否为聚焦标签
    final isFocused = widget.focusedTag?.id == tag.id;
    
    // 根据状态确定样式
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    double borderWidth = 1;
    
    if (isFocused) {
      // 聚焦状态：高亮显示
      backgroundColor = tagColor.withValues(alpha: 0.3);
      borderColor = tagColor;
      textColor = tagColor;
      borderWidth = 2; // 加粗边框作为聚焦指示器
    } else if (isSelected) {
      // 已选中但未聚焦：原色显示
      backgroundColor = tagColor.withValues(alpha: 0.2);
      borderColor = tagColor;
      textColor = tagColor;
    } else {
      // 未选中：半透明显示
      backgroundColor = tagColor.withValues(alpha: 0.08);
      borderColor = tagColor.withValues(alpha: 0.3);
      textColor = tagColor.withValues(alpha: 0.6);
    }
    
    // 构建标签内容
    Widget tagContent = Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(8),
        // 聚焦状态添加阴影效果
        boxShadow: isFocused ? [
          BoxShadow(
            color: tagColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
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
                Icon(
                  _getTagTypeIcon(tag.type),
                  size: 14,
                  color: textColor,
                ),
                // 聚焦指示器：右上角小圆点
                if (isFocused)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tagColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            
            // 标签名称
            Flexible(
              child: Text(
                tag.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: isFocused ? FontWeight.w600 : 
                              (isSelected ? FontWeight.w500 : FontWeight.normal),
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
    
    // 如果是未选中的标签，支持拖拽到已选中区域
    if (!isSelected) {
      return Draggable<TagDragData>(
        data: TagDragData(tag: tag, source: 'main'),
        feedback: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          child: Container(
            width: 80, // 固定宽度，避免拖拽时变形
            height: 44, // 固定高度
            child: tagContent,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _handleTagTap(tag),
              onLongPress: () => _handleTagLongPress(tag),
              borderRadius: BorderRadius.circular(8),
              child: tagContent,
            ),
          ),
        ),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => _handleTagTap(tag),
            onLongPress: () => _handleTagLongPress(tag),
            borderRadius: BorderRadius.circular(8),
            child: tagContent,
          ),
        ),
      );
    } else {
      // 已选中的标签，支持拖拽到未选中区域删除记录
      return Draggable<TagDragData>(
        data: TagDragData(tag: tag, source: 'main'),
        feedback: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          child: Container(
            width: 80, // 固定宽度，避免拖拽时变形
            height: 44, // 固定高度
            child: tagContent,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _handleTagTap(tag),
              onLongPress: () => _handleTagLongPress(tag),
              borderRadius: BorderRadius.circular(8),
              child: tagContent,
            ),
          ),
        ),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => _handleTagTap(tag),
            onLongPress: () => _handleTagLongPress(tag),
            borderRadius: BorderRadius.circular(8),
            child: tagContent,
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