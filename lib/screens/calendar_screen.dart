import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_demo_screen.dart';
import 'tag_management_screen.dart';
import 'diary_input_screen.dart';
import '../models/models.dart';
import '../repositories/tag_repository.dart';
import '../repositories/tag_record_repository.dart';
import '../widgets/tag_management_panel.dart';
import '../widgets/tag_value_dialog.dart';
import '../widgets/complex_tag_management_panel.dart';
import '../constants/heatmap_colors.dart';

/// 日历主界面
/// 
/// 重构版本：清晰的模式分离和统一的背景色策略
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TagRepository _tagRepository = TagRepository();
  final TagRecordRepository _recordRepository = TagRecordRepository();
  
  // 日历格式：月视图
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 当前聚焦的日期（用于日历导航）
  DateTime _focusedDay = DateTime.now();
  
  // 用户选中的日期
  DateTime? _selectedDay;
  
  // 标签和记录数据
  List<Tag> _allTags = [];
  final Map<String, List<TagRecord>> _tagRecords = {};
  
  // 数据刷新计数器，用于触发子组件重新加载
  int _dataRefreshCounter = 0;
  
  // 单标签聚焦模式状态
  Tag? _focusedTag; // 当前聚焦的标签，null表示普通模式
  
  // 复杂标签管理面板状态
  Tag? _showingComplexTag; // 当前显示复杂标签管理面板的标签，null表示不显示
  Tag? _focusedSubTag; // 当前聚焦的子标签（用于复杂标签的子标签聚焦模式）
  
  // 数据缓存优化
  final Map<String, Map<String, TagRecord>> _recordCache = {}; // tagId -> {dateKey -> record}
  DateTime? _cachedMonth; // 当前缓存的月份

  @override
  void initState() {
    super.initState();
    // 初始化时选中今天
    _selectedDay = DateTime.now();
    _loadTagsAndRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('日迹'),
        elevation: 0,
        actions: [
          // 标签管理按钮
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const TagManagementScreen(),
                ),
              );
              
              // 如果有数据变更，强制重新加载数据
              if (result == true) {
                // 清空缓存，强制重新加载
                _cachedMonth = null;
                _recordCache.clear();
                _tagRecords.clear();
                
                await _loadTagsAndRecords();
                setState(() {
                  _dataRefreshCounter++;
                });
              }
            },
            icon: const Icon(Icons.label),
            tooltip: '标签管理',
          ),
          // 数据库演示按钮
          IconButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const DatabaseDemoScreen(),
                ),
              );
              
              // 如果有数据变更，强制重新加载数据
              if (result == true) {
                // 清空缓存，强制重新加载
                _cachedMonth = null;
                _recordCache.clear();
                _tagRecords.clear();
                
                await _loadTagsAndRecords();
                setState(() {
                  _dataRefreshCounter++;
                });
              }
            },
            icon: const Icon(Icons.storage),
            tooltip: '数据库演示',
          ),
        ],
      ),
      body: GestureDetector(
        // 点击空白处取消聚焦
        onTap: () => _handleBackgroundTap(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          child: Column(
            children: [
            // 日历组件
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TableCalendar<dynamic>(
                  // 设置日历行高
                  rowHeight: 60,
                  // 基础配置
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  
                  // 日历格式
                  calendarFormat: _calendarFormat,
                  
                  // 选中日期
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  
                  // 日期选择回调
                  onDaySelected: _onDaySelected,
                  
                  // 页面变化回调（月份切换）
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    _loadTagsAndRecords();
                  },
                  
                  // 格式变化回调
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  
                  // 样式配置
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(0),
                    cellPadding: const EdgeInsets.all(0),
                    
                    // 今天的样式
                    todayDecoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                      shape: BoxShape.rectangle,
                    ),
                    todayTextStyle: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    
                    // 选中日期的样式
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                      shape: BoxShape.rectangle,
                    ),
                    selectedTextStyle: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    
                    // 默认日期样式
                    defaultTextStyle: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    
                    // 周末样式
                    weekendTextStyle: TextStyle(
                      color: colorScheme.error,
                      fontSize: 16,
                    ),
                    
                    // 默认装饰
                    defaultDecoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                      shape: BoxShape.rectangle,
                    ),
                    
                    // 周末装饰
                    weekendDecoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                      shape: BoxShape.rectangle,
                    ),
                    
                    // 隐藏默认标记
                    markersMaxCount: 0,
                  ),
                  
                  // 头部样式
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    titleTextStyle: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: colorScheme.onSurface,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  
                  // 星期标题样式
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    weekendStyle: TextStyle(
                      color: colorScheme.error.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  // 自定义日期单元格构建器
                  calendarBuilders: CalendarBuilders(
                    // 默认日期单元格
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildDateCell(context, day, false, false);
                    },
                    
                    // 选中日期的单元格
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildDateCell(context, day, false, true);
                    },
                    
                    // 今天的日期单元格
                    todayBuilder: (context, day, focusedDay) {
                      final isSelected = isSameDay(_selectedDay, day);
                      return _buildDateCell(context, day, true, isSelected);
                    },
                    
                    // 周末日期单元格
                    outsideBuilder: (context, day, focusedDay) {
                      return _buildDateCell(context, day, false, false, isOutside: true);
                    },
                  ),
                ),
              ),
            ),
            // 标签管理面板
            TagManagementPanel(
              key: ValueKey('${_selectedDay?.millisecondsSinceEpoch ?? 0}'),
              selectedDate: _selectedDay ?? DateTime.now(),
              focusedTag: _focusedTag,
              onTagTap: _handleTagTap,
              onTagLongPress: _handleTagLongPress,
              onTagVisibilityChanged: _handleTagVisibilityChanged,
              onDataChanged: _handleDataChanged,
            ),
            
            // 复杂标签管理面板（在原先折叠式标签管理面板组件下方）
            if (_showingComplexTag != null)
              ComplexTagManagementPanel(
                key: ValueKey('${_showingComplexTag!.id}_${_selectedDay?.millisecondsSinceEpoch ?? 0}'),
                selectedDate: _selectedDay ?? DateTime.now(),
                complexTag: _showingComplexTag!,
                focusedSubTag: _focusedSubTag,
                onSubTagTap: _handleSubTagTap,
                onSubTagLongPress: _handleSubTagLongPress,
                onComplexTagSave: _handleComplexTagSave,
                onClose: _handleComplexTagPanelClose,
                onDataChanged: _handleDataChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理日期选择
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      debugPrint('选中日期: ${selectedDay.toString().split(' ')[0]}');
    }
  }

  /// 加载标签和记录数据
  Future<void> _loadTagsAndRecords() async {
    try {
      // 加载所有激活的标签
      final allTags = await _tagRepository.findActive();
      _allTags = allTags;
      
      // 检查是否需要重新加载数据
      final currentMonth = DateTime(_focusedDay.year, _focusedDay.month);
      final needsReload = _shouldReloadData(currentMonth);
      
      if (needsReload) {
        debugPrint('重新加载月份数据: ${currentMonth.year}-${currentMonth.month}');
        await _loadMonthData(currentMonth);
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('加载数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('数据加载失败，请稍后重试'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  /// 检查是否需要重新加载数据
  bool _shouldReloadData(DateTime currentMonth) {
    return _cachedMonth == null || 
           _cachedMonth!.year != currentMonth.year || 
           _cachedMonth!.month != currentMonth.month ||
           _allTags.isEmpty;
  }
  
  /// 加载指定月份的数据
  Future<void> _loadMonthData(DateTime month) async {
    // 清空当前月份的缓存
    _recordCache.clear();
    _tagRecords.clear();
    
    // 计算月份范围
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    // 批量加载所有标签的记录数据
    final futures = _allTags.map((tag) async {
      try {
        final records = await _recordRepository.findByTagAndDateRange(
          tag.id,
          startOfMonth,
          endOfMonth,
        );
        
        // 更新记录列表
        _tagRecords[tag.id] = records;
        
        // 构建日期索引缓存
        final recordMap = <String, TagRecord>{};
        for (final record in records) {
          final dateKey = _getDateKey(record.date);
          recordMap[dateKey] = record;
        }
        _recordCache[tag.id] = recordMap;
        
        return records.length;
      } catch (e) {
        debugPrint('加载标签 ${tag.name} 的数据失败: $e');
        _tagRecords[tag.id] = [];
        _recordCache[tag.id] = {};
        return 0;
      }
    });
    
    // 等待所有数据加载完成
    final recordCounts = await Future.wait(futures);
    final totalRecords = recordCounts.fold<int>(0, (sum, count) => sum + count);
    
    debugPrint('加载完成: ${_allTags.length} 个标签，$totalRecords 条记录');
    _cachedMonth = month;
  }
  
  /// 生成日期缓存键
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 快速获取指定日期的标签记录
  TagRecord? _getRecordForDate(String tagId, DateTime date) {
    final dateKey = _getDateKey(date);
    return _recordCache[tagId]?[dateKey];
  }

  /// 处理背景点击
  void _handleBackgroundTap() {
    bool hasChanges = false;
    
    if (_focusedTag != null) {
      _focusedTag = null;
      _focusedSubTag = null; // 同时取消子标签聚焦
      hasChanges = true;
      debugPrint('点击空白处，取消聚焦模式');
    }
    
    if (_showingComplexTag != null) {
      _showingComplexTag = null;
      hasChanges = true;
      debugPrint('点击空白处，关闭复杂标签管理面板');
    }
    
    if (hasChanges) {
      setState(() {});
    }
  }

  /// 处理标签点击（单标签聚焦模式）
  void _handleTagTap(Tag tag) {
    debugPrint('标签点击: ${tag.name}');
    
    setState(() {
      // 如果点击的是当前聚焦的标签，则取消聚焦
      if (_focusedTag?.id == tag.id) {
        _focusedTag = null;
        _focusedSubTag = null; // 同时取消子标签聚焦
        _showingComplexTag = null; // 关闭复杂标签管理面板
        debugPrint('取消聚焦模式');
      } else {
        // 否则聚焦到该标签
        _focusedTag = tag;
        _focusedSubTag = null; // 重置子标签聚焦状态
        debugPrint('聚焦到标签: ${tag.name}');
        
        // 如果是复杂标签，自动显示子标签管理面板
        if (tag.type.isComplex) {
          _showingComplexTag = tag;
          debugPrint('自动显示复杂标签管理面板: ${tag.name}');
        } else {
          _showingComplexTag = null; // 关闭复杂标签管理面板
        }
      }
    });
  }

  /// 处理标签长按
  void _handleTagLongPress(Tag tag) {
    debugPrint('标签长按: ${tag.name}');
    
    if (tag.type.isQuantitative) {
      // 量化标签：显示数值修改对话框
      _showTagValueDialog(tag);
    } else if (tag.type.isBinary) {
      // 非量化标签：显示删除对话框
      _showTagDeleteDialog(tag);
    } else if (tag.type.isComplex) {
      // 复杂标签：显示删除对话框
      _showTagDeleteDialog(tag);
    }
  }

  /// 处理标签可见性变化
  void _handleTagVisibilityChanged(Tag tag, bool isVisible) {
    debugPrint('标签可见性变化: ${tag.name} -> $isVisible');
  }

  /// 处理复杂标签管理面板关闭
  void _handleComplexTagPanelClose() {
    setState(() {
      _showingComplexTag = null;
      _focusedSubTag = null;
    });
    debugPrint('关闭复杂标签管理面板');
  }

  /// 处理数据更新
  void _handleDataChanged() {
    // 清空缓存，强制重新加载当前月份的数据
    _cachedMonth = null;
    _recordCache.clear();
    _tagRecords.clear();
    
    // 重新加载数据以更新日历标记
    _loadTagsAndRecords().then((_) {
      // 只更新状态，不强制重建子组件
      if (mounted) {
        setState(() {
          // 不增加 _dataRefreshCounter，避免子组件重建
        });
      }
    });
    debugPrint('✅ 数据已更新，清空缓存并刷新日历标记');
  }

  /// 处理子标签点击（用于子标签聚焦模式）
  void _handleSubTagTap(Tag subTag) {
    setState(() {
      // 如果点击的是当前聚焦的子标签，则取消聚焦
      if (_focusedSubTag?.id == subTag.id) {
        _focusedSubTag = null;
        _focusedTag = null; // 同时取消主标签聚焦
        debugPrint('取消子标签聚焦模式');
      } else {
        // 否则聚焦到该子标签
        _focusedSubTag = subTag;
        _focusedTag = subTag; // 同时设置主标签聚焦以在日历上显示
        debugPrint('聚焦到子标签: ${subTag.name}');
      }
    });
  }

  /// 处理子标签长按
  void _handleSubTagLongPress(Tag subTag) {
    debugPrint('子标签长按: ${subTag.name}');
    
    if (subTag.type.isQuantitative || subTag.type.isBinary) {
      // 量化子标签或非量化子标签：显示修改对话框
      _showTagValueDialog(subTag);
    } else {
      // 复杂子标签：暂不支持
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${subTag.type.displayName}功能将在后续版本中提供'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  /// 处理复杂标签记录保存
  void _handleComplexTagSave(Tag complexTag, List<String> selectedSubTags) {
    debugPrint('复杂标签记录保存: ${complexTag.name} = $selectedSubTags');
    
    // 清空缓存，强制重新加载数据
    _cachedMonth = null;
    _recordCache.clear();
    _tagRecords.clear();
    
    // 重新加载数据以更新界面，但不强制重建子组件
    _loadTagsAndRecords().then((_) {
      if (mounted) {
        setState(() {
          // 只更新状态，不增加刷新计数器
        });
      }
    });
    
    // 控制台输出成功信息
    debugPrint('✅ 已保存复杂标签记录: ${complexTag.name}');
  }

  /// 显示标签数值修改对话框
  Future<void> _showTagValueDialog(Tag tag) async {
    final selectedDate = _selectedDay ?? DateTime.now();
    
    try {
      // 查找当日该标签的记录
      final existingRecord = await _recordRepository.findByTagAndDate(tag.id, selectedDate);
      
      // 显示对话框
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => TagValueDialog(
            tag: tag,
            currentValue: existingRecord?.value,
            showDeleteButton: existingRecord != null,
            onConfirm: (value) => _saveTagRecord(tag, selectedDate, value),
            onDelete: existingRecord != null 
                ? () => _deleteTagRecord(existingRecord) 
                : null,
          ),
        );
      }
    } catch (e) {
      debugPrint('显示标签对话框失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载标签数据失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示标签删除对话框
  Future<void> _showTagDeleteDialog(Tag tag) async {
    final selectedDate = _selectedDay ?? DateTime.now();
    
    try {
      // 查找当日该标签的记录
      final existingRecord = await _recordRepository.findByTagAndDate(tag.id, selectedDate);
      
      if (existingRecord == null) {
        // 如果没有记录，提示用户
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('当日没有该标签的记录')),
          );
        }
        return;
      }
      
      // 显示删除确认对话框
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('删除标签记录'),
            content: Text('确定要删除 ${tag.name} 在 ${selectedDate.toString().split(' ')[0]} 的记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteTagRecord(existingRecord);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('显示删除对话框失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载标签数据失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 保存标签记录
  Future<void> _saveTagRecord(Tag tag, DateTime date, dynamic value) async {
    try {
      // 查找是否已有记录
      final existingRecord = await _recordRepository.findByTagAndDate(tag.id, date);
      
      if (existingRecord != null) {
        // 更新现有记录
        final updatedRecord = existingRecord.copyWith(
          value: value,
          updatedAt: DateTime.now(),
        );
        await _recordRepository.update(updatedRecord);
        debugPrint('更新标签记录: ${tag.name} = $value');
      } else {
        // 创建新记录
        final newRecord = TagRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tagId: tag.id,
          date: date,
          value: value,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _recordRepository.insert(newRecord);
        debugPrint('创建标签记录: ${tag.name} = $value');
      }
      
      // 清空缓存，强制重新加载数据
      _cachedMonth = null;
      _recordCache.clear();
      _tagRecords.clear();
      
      // 重新加载数据以更新界面，但不强制重建子组件
      await _loadTagsAndRecords();
      
      // 触发界面刷新
      if (mounted) {
        setState(() {
          // 只更新状态，不增加刷新计数器
        });
      }
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已保存 ${tag.name} 的记录'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('保存标签记录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 删除标签记录
  Future<void> _deleteTagRecord(TagRecord record) async {
    try {
      await _recordRepository.deleteById(record.id);
      debugPrint('删除标签记录: ${record.id}');
      
      // 清空缓存，强制重新加载数据
      _cachedMonth = null;
      _recordCache.clear();
      _tagRecords.clear();
      
      // 重新加载数据以更新界面，但不强制重建子组件
      await _loadTagsAndRecords();
      
      // 触发界面刷新
      if (mounted) {
        setState(() {
          // 只更新状态，不增加刷新计数器
        });
      }
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除记录'),
          ),
        );
      }
    } catch (e) {
      debugPrint('删除标签记录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 构建日期单元格（重构版本）
  /// 
  /// 新的设计思路：
  /// 1. 统一的背景色策略
  /// 2. 清晰的模式分离
  /// 3. 简化的条件判断
  Widget _buildDateCell(
    BuildContext context, 
    DateTime day, 
    bool isToday, 
    bool isSelected, {
    bool isOutside = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 1. 确定背景色和边框（统一策略）
    Color? backgroundColor;
    Border? border;
    Color textColor;
    
    // 量化标签聚焦模式：特殊的背景色处理
    if (_focusedTag != null && (_focusedTag!.type.isQuantitative || 
        (_focusedSubTag != null && _focusedSubTag!.type.isQuantitative))) {
      final heatmapColor = _getQuantitativeHeatmapColor(day);
      backgroundColor = heatmapColor;
      
      // 聚焦模式下也要考虑周末和月外日期的文字颜色
      if (isOutside) {
        textColor = HeatmapColors.getTextColor().withValues(alpha: HeatmapColors.focusedOutsideTextAlpha);
      } else if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        textColor = HeatmapColors.focusedWeekendTextColor;
      } else {
        textColor = HeatmapColors.getTextColor();
      }
      
      // 选中状态使用加粗边框
      if (isSelected) {
        border = Border.all(
          color: HeatmapColors.focusedSelectedBorderColor ?? colorScheme.primary, 
          width: HeatmapColors.focusedSelectedBorderWidth,
        );
      } else {
        border = Border.all(
          color: HeatmapColors.focusedNormalBorderColor, 
          width: HeatmapColors.focusedNormalBorderWidth,
        );
      }
    } else {
      // 普通模式和其他聚焦模式：统一的背景色策略
      backgroundColor = HeatmapColors.getDefaultBackground();
      
      // 确定文本颜色
      if (isOutside) {
        textColor = colorScheme.onSurface.withValues(alpha: 0.3);
      } else if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        textColor = colorScheme.error;
      } else {
        textColor = colorScheme.onSurface;
      }
      
      // 选中状态的特殊处理
      if (isSelected) {
        backgroundColor = colorScheme.primary.withValues(alpha: HeatmapColors.normalBorderAlpha);
        border = Border.all(
          color: colorScheme.primary, 
          width: HeatmapColors.normalSelectedBorderWidth,
        );
        textColor = colorScheme.primary;
      } else {
        border = Border.all(
          color: colorScheme.outline.withValues(alpha: HeatmapColors.normalBorderAlpha),
          width: HeatmapColors.normalBorderWidth,
        );
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
        shape: BoxShape.rectangle,
      ),
      child: Stack(
        children: [
          // 日期数字
          Positioned(
            top: 4,
            left: 6,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          
          // 2. 根据模式显示不同内容
          ..._buildDateCellContent(day, textColor),
          
          // 点击区域
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onDaySelected(day, day),
                onDoubleTap: () => _openDiaryInput(day),
                borderRadius: BorderRadius.zero,
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建日期单元格内容（根据模式）
  List<Widget> _buildDateCellContent(DateTime day, Color textColor) {
    if (_focusedTag == null) {
      // 普通模式：显示所有标签的小指示器
      return [
        Positioned(
          bottom: 2,
          left: 2,
          right: 2,
          child: SizedBox(
            height: 16,
            child: _buildMultiTagIndicators(day),
          ),
        ),
      ];
    } else {
      // 聚焦模式：根据标签类型显示不同内容
      return _buildFocusedModeContent(day, textColor);
    }
  }
  
  /// 构建聚焦模式内容
  List<Widget> _buildFocusedModeContent(DateTime day, Color textColor) {
    // 如果是子标签聚焦模式，需要特殊处理
    if (_focusedSubTag != null) {
      return _buildSubTagFocusedContent(day, textColor);
    }
    
    final record = _getRecordForDate(_focusedTag!.id, day);
    
    if (_focusedTag!.type.isQuantitative) {
      // 量化标签：显示数值（背景色已在_buildDateCell中处理）
      if (record?.numericValue != null) {
        final displayValue = _formatQuantitativeValue(record!.numericValue!, _focusedTag!);
        return [
          Positioned(
            bottom: 4,
            right: 6,
            child: Text(
              displayValue,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ];
      }
    } else if (_focusedTag!.type.isBinary) {
      // 非量化标签：显示标记
      if (record?.booleanValue == true) {
        return [_buildBinaryMarker(day)];
      }
    } else if (_focusedTag!.type.isComplex) {
      // 复杂标签：显示选中的子标签数量或具体子标签
      if (record?.listValue.isNotEmpty == true) {
        return [_buildComplexMarker(day, record!)];
      }
    }
    
    return [];
  }
  
  /// 获取量化标签的热力图颜色
  Color _getQuantitativeHeatmapColor(DateTime day) {
    // 如果是子标签聚焦模式
    if (_focusedSubTag != null && _focusedSubTag!.type.isQuantitative) {
      return _getSubTagQuantitativeHeatmapColor(day);
    }
    
    final record = _getRecordForDate(_focusedTag!.id, day);
    
    if (record?.numericValue == null) {
      return HeatmapColors.getNoDataColor();
    }
    
    // 计算强度值
    final minValue = _focusedTag!.quantitativeMinValue ?? 1.0;
    final maxValue = _focusedTag!.quantitativeMaxValue ?? 10.0;
    final value = record!.numericValue!;
    final normalizedValue = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    
    // 使用增强对比度算法
    final intensity = _enhanceContrast(normalizedValue);
    
    return HeatmapColors.getColorForIntensity(intensity);
  }
  
  /// 获取量化子标签的热力图颜色
  Color _getSubTagQuantitativeHeatmapColor(DateTime day) {
    // 获取复杂标签的记录
    final complexRecord = _getRecordForDate(_showingComplexTag!.id, day);
    
    if (complexRecord?.listValue.isEmpty != false) {
      return HeatmapColors.getNoDataColor();
    }
    
    final selectedSubTags = complexRecord!.listValue;
    
    // 检查当前聚焦的量化子标签是否被选中
    if (!selectedSubTags.contains(_focusedSubTag!.name)) {
      return HeatmapColors.getNoDataColor();
    }
    
    // 对于量化子标签，我们使用一个简化的方案：
    // 基于子标签在复杂标签中的"重要性"或者给一个固定的中等强度值
    // 这里我们给一个中等强度值 (0.6) 来显示热力图效果
    final intensity = 0.6;
    
    return HeatmapColors.getColorForIntensity(intensity);
  }
  
  /// 增强对比度的非线性映射函数
  double _enhanceContrast(double normalizedValue) {
    if (normalizedValue < 0.5) {
      // 低值区间：使用平方根增强区分度
      return 0.5 * math.sqrt(normalizedValue * 2);
    } else {
      // 高值区间：使用平方函数增强区分度
      final adjustedValue = (normalizedValue - 0.5) * 2;
      return 0.5 + 0.5 * (adjustedValue * adjustedValue);
    }
  }
  
  /// 格式化量化标签数值
  String _formatQuantitativeValue(double value, Tag tag) {
    // 获取标签单位
    final unit = tag.quantitativeUnit;
    
    // 智能格式化数值
    String valueText;
    if (value % 1 == 0) {
      valueText = value.toInt().toString();
    } else if (value < 10) {
      valueText = value.toStringAsFixed(1);
    } else {
      valueText = value.toStringAsFixed(0);
    }
    
    // 添加单位（如果有且不会太长）
    if (unit != null && unit.length <= 2 && valueText.length <= 3) {
      return '$valueText$unit';
    }
    
    return valueText;
  }
  
  /// 构建非量化标签的标记
  Widget _buildBinaryMarker(DateTime day) {
    // 解析标签颜色
    Color tagColor;
    try {
      tagColor = Color(int.parse(_focusedTag!.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      tagColor = Theme.of(context).colorScheme.primary;
    }
    
    return Positioned(
      bottom: 4,
      right: 6,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: tagColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 8,
        ),
      ),
    );
  }
  
  /// 构建复杂标签的标记
  Widget _buildComplexMarker(DateTime day, TagRecord record) {
    // 解析标签颜色
    Color tagColor;
    try {
      tagColor = Color(int.parse(_focusedTag!.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      tagColor = Theme.of(context).colorScheme.primary;
    }
    
    final selectedSubTags = record.listValue;
    final totalSubTags = _focusedTag!.complexSubTags.length;
    
    // 如果只选中了一个子标签，显示子标签名称
    if (selectedSubTags.length == 1) {
      final subTagName = selectedSubTags.first;
      return Positioned(
        bottom: 2,
        left: 2,
        right: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            subTagName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } else {
      // 如果选中了多个子标签，显示数量
      return Positioned(
        bottom: 4,
        right: 6,
        child: Container(
          width: 16,
          height: 12,
          decoration: BoxDecoration(
            color: tagColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${selectedSubTags.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
  }
  
  /// 构建子标签聚焦模式内容
  List<Widget> _buildSubTagFocusedContent(DateTime day, Color textColor) {
    // 获取复杂标签的记录
    final complexRecord = _getRecordForDate(_showingComplexTag!.id, day);
    
    if (complexRecord?.listValue.isNotEmpty == true) {
      final selectedSubTags = complexRecord!.listValue;
      
      // 检查当前聚焦的子标签是否在选中列表中
      if (selectedSubTags.contains(_focusedSubTag!.name)) {
        // 如果子标签是量化类型，可以显示数值（这里简化处理）
        if (_focusedSubTag!.type.isQuantitative) {
          // 对于量化子标签，可以考虑从复杂记录中提取具体数值
          // 这里简化为显示子标签名称
          return [
            Positioned(
              bottom: 2,
              left: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: _getSubTagColor().withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _focusedSubTag!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ];
        } else {
          // 非量化子标签：显示标记
          return [
            Positioned(
              bottom: 4,
              right: 6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getSubTagColor(),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
          ];
        }
      }
    }
    
    return [];
  }
  
  /// 获取子标签颜色
  Color _getSubTagColor() {
    try {
      return Color(int.parse(_focusedSubTag!.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Theme.of(context).colorScheme.primary;
    }
  }
  
  /// 构建多标签指示器（普通模式）
  Widget _buildMultiTagIndicators(DateTime day) {
    final List<Widget> tagIndicators = [];
    
    // 获取当日有记录的标签，按重要性排序
    final tagsWithRecords = <Tag, TagRecord>{};
    for (final tag in _allTags) {
      final dayRecord = _getRecordForDate(tag.id, day);
      if (dayRecord != null && dayRecord.hasValue) {
        tagsWithRecords[tag] = dayRecord;
      }
    }
    
    if (tagsWithRecords.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 按标签类型和数值重要性排序
    final sortedEntries = tagsWithRecords.entries.toList()
      ..sort((a, b) {
        // 优先显示量化标签，然后按数值大小排序
        if (a.key.type.isQuantitative && b.key.type.isQuantitative) {
          final aValue = a.value.numericValue ?? 0;
          final bValue = b.value.numericValue ?? 0;
          return bValue.compareTo(aValue); // 降序，高数值优先
        } else if (a.key.type.isQuantitative) {
          return -1; // 量化标签优先
        } else if (b.key.type.isQuantitative) {
          return 1;
        }
        return a.key.name.compareTo(b.key.name); // 其他按名称排序
      });
    
    // 动态计算最大显示数量
    const maxIndicators = 6;
    final displayCount = sortedEntries.length > maxIndicators ? maxIndicators - 1 : sortedEntries.length;
    
    // 构建标签指示器
    for (int i = 0; i < displayCount; i++) {
      final entry = sortedEntries[i];
      final indicator = _buildTagIndicator(entry.key, entry.value);
      if (indicator != null) {
        tagIndicators.add(indicator);
      }
    }
    
    // 如果有更多标签，显示省略指示器
    final remainingCount = sortedEntries.length - displayCount;
    if (remainingCount > 0) {
      tagIndicators.add(
        Container(
          width: 10,
          height: 6,
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                fontSize: 7,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 1.5,
      runSpacing: 1,
      children: tagIndicators,
    );
  }
  
  /// 构建单个标签指示器
  Widget? _buildTagIndicator(Tag tag, TagRecord record) {
    // 解析标签颜色
    Color tagColor;
    try {
      tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      tagColor = Theme.of(context).colorScheme.primary;
    }
    
    // 根据标签类型构建不同的指示器
    if (tag.type.isQuantitative && record.numericValue != null) {
      return _buildQuantitativeIndicator(tag, record, tagColor);
    } else if (tag.type.isBinary && record.booleanValue != null) {
      return _buildBinaryIndicator(tag, record, tagColor);
    } else if (tag.type.isComplex && record.listValue.isNotEmpty) {
      return _buildComplexIndicator(tag, record, tagColor);
    }
    
    return null;
  }
  
  /// 构建量化标签指示器
  Widget _buildQuantitativeIndicator(Tag tag, TagRecord record, Color tagColor) {
    final minValue = tag.quantitativeMinValue ?? 1.0;
    final maxValue = tag.quantitativeMaxValue ?? 10.0;
    final value = record.numericValue!;
    
    // 使用非线性映射增强对比度
    final normalizedValue = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    final intensity = _enhanceContrast(normalizedValue);
    
    // 动态颜色计算
    final alpha = 0.3 + intensity * 0.7;
    final backgroundColor = tagColor.withValues(alpha: alpha);
    
    // 高强度值添加边框
    final shouldAddBorder = intensity > 0.6;
    
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(1.5),
        border: shouldAddBorder ? Border.all(
          color: tagColor.withValues(alpha: 0.9),
          width: 0.5,
        ) : null,
        // 高强度值添加阴影
        boxShadow: intensity > 0.8 ? [
          BoxShadow(
            color: tagColor.withValues(alpha: 0.4),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ] : null,
      ),
    );
  }
  
  /// 构建非量化标签指示器
  Widget _buildBinaryIndicator(Tag tag, TagRecord record, Color tagColor) {
    final isActive = record.booleanValue == true;
    
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive ? tagColor.withValues(alpha: 0.9) : tagColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? tagColor : tagColor.withValues(alpha: 0.5),
          width: isActive ? 0.8 : 0.5,
        ),
        // 激活状态添加阴影
        boxShadow: isActive ? [
          BoxShadow(
            color: tagColor.withValues(alpha: 0.3),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ] : null,
      ),
      // 激活状态显示小勾号
      child: isActive ? const Icon(
        Icons.check,
        size: 4,
        color: Colors.white,
      ) : null,
    );
  }
  
  /// 构建复杂标签指示器
  Widget _buildComplexIndicator(Tag tag, TagRecord record, Color tagColor) {
    final subTagCount = record.listValue.length;
    final maxSubTags = tag.complexSubTags.length;
    final intensity = maxSubTags > 0 ? (subTagCount / maxSubTags).clamp(0.0, 1.0) : 0.5;
    
    // 使用增强对比度算法
    final enhancedIntensity = _enhanceContrast(intensity);
    
    return Container(
      width: 8,
      height: 7,
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.3 + enhancedIntensity * 0.6),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.7 + enhancedIntensity * 0.3),
          width: 0.5,
        ),
        // 高复杂度添加阴影
        boxShadow: enhancedIntensity > 0.7 ? [
          BoxShadow(
            color: tagColor.withValues(alpha: 0.3),
            blurRadius: 1,
            offset: const Offset(0, 0.5),
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          '$subTagCount',
          style: TextStyle(
            fontSize: 6,
            color: enhancedIntensity > 0.5 ? Colors.white : tagColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 打开日记输入界面
  Future<void> _openDiaryInput(DateTime date) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DiaryInputScreen(selectedDate: date),
      ),
    );
    
    // 如果有数据变更，重新加载数据
    if (result == true) {
      _loadTagsAndRecords();
    }
  }
}