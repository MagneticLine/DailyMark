import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_demo_screen.dart';
import 'tag_management_screen.dart';

/// 日历主界面
/// 
/// 这是应用的核心界面，显示月视图日历并支持日期选择
/// 采用现代极简设计风格，符合Material 3设计规范
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 日历格式：月视图
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 当前聚焦的日期（用于日历导航）
  DateTime _focusedDay = DateTime.now();
  
  // 用户选中的日期
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // 初始化时选中今天
    _selectedDay = DateTime.now();
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
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TagManagementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.label),
            tooltip: '标签管理',
          ),
          // 数据库演示按钮
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DatabaseDemoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.storage),
            tooltip: '数据库演示',
          ),
          // 今天按钮 - 快速回到当前日期
          IconButton(
            onPressed: _goToToday,
            icon: const Icon(Icons.today),
            tooltip: '回到今天',
          ),
        ],
      ),
      body: Column(
        children: [
          // 日历组件
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar<dynamic>(
                // 设置日历行高，确保方形单元格有足够空间
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
                },
                
                // 格式变化回调
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                
                // 样式配置 - 台历式方形设计
                calendarStyle: CalendarStyle(
                  // 外部装饰
                  outsideDaysVisible: false,
                  
                  // 单元格大小和间距
                  cellMargin: const EdgeInsets.all(0), // 紧密相连，无间距
                  cellPadding: const EdgeInsets.all(0),
                  
                  // 今天的样式 - 方形边框
                  todayDecoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                    shape: BoxShape.rectangle,
                  ),
                  todayTextStyle: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  
                  // 选中日期的样式 - 方形背景
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
                  
                  // 默认装饰 - 添加淡边框以区分日期格子
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
                  
                  // 标记样式（为后续功能预留）
                  markersMaxCount: 0, // 暂时隐藏默认标记，后续自定义
                ),
                
                // 头部样式（星期标题）
                headerStyle: HeaderStyle(
                  // 格式按钮样式
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
                  
                  // 标题样式
                  titleTextStyle: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  
                  // 左右箭头样式
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
                  
                  // 今天的单元格
                  todayBuilder: (context, day, focusedDay) {
                    return _buildDateCell(context, day, true, false);
                  },
                  
                  // 选中日期的单元格
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildDateCell(context, day, false, true);
                  },
                  
                  // 周末日期单元格
                  outsideBuilder: (context, day, focusedDay) {
                    return _buildDateCell(context, day, false, false, isOutside: true);
                  },
                ),
              ),
            ),
          ),
          
          // 选中日期信息显示区域
          if (_selectedDay != null) ...[
            const SizedBox(height: 16),
            _buildSelectedDateInfo(),
          ],
        ],
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
      
      // 这里可以添加日期选择的回调处理
      // 比如加载该日期的标签数据等
      _onDateChanged(selectedDay);
    }
  }

  /// 回到今天
  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _focusedDay = today;
    });
    _onDateChanged(today);
  }

  /// 日期变化处理
  void _onDateChanged(DateTime date) {
    // 这里是日期选择的核心逻辑
    // 后续会在这里加载对应日期的标签数据
    debugPrint('选中日期: ${date.toString().split(' ')[0]}');
  }

  /// 构建台历式日期单元格
  /// 
  /// [day] 日期
  /// [isToday] 是否是今天
  /// [isSelected] 是否被选中
  /// [isOutside] 是否是月外日期
  Widget _buildDateCell(
    BuildContext context, 
    DateTime day, 
    bool isToday, 
    bool isSelected, {
    bool isOutside = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 确定文本颜色
    Color textColor;
    if (isOutside) {
      textColor = colorScheme.onSurface.withValues(alpha: 0.3);
    } else if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      textColor = colorScheme.error;
    } else {
      textColor = colorScheme.onSurface;
    }
    
    // 确定背景和边框
    Color? backgroundColor;
    Border? border;
    
    if (isSelected) {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.2);
      border = Border.all(color: colorScheme.primary, width: 2);
    } else if (isToday) {
      border = Border.all(color: colorScheme.primary, width: 2);
    } else {
      border = Border.all(
        color: colorScheme.outline.withValues(alpha: 0.2),
        width: 0.5,
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
        shape: BoxShape.rectangle,
      ),
      child: Stack(
        children: [
          // 日期数字 - 显示在左上角
          Positioned(
            top: 4,
            left: 6,
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isToday || isSelected ? colorScheme.primary : textColor,
                fontSize: 14,
                fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          
          // 农历显示区域（预留，后续可添加）
          // Positioned(
          //   top: 4,
          //   right: 6,
          //   child: Text(
          //     '初一', // 示例农历
          //     style: TextStyle(
          //       color: textColor.withValues(alpha: 0.6),
          //       fontSize: 10,
          //     ),
          //   ),
          // ),
          
          // 标签颜色标记区域 - 预留在底部
          Positioned(
            bottom: 2,
            left: 2,
            right: 2,
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  // 这里后续会显示标签的颜色条
                  // 示例：不同颜色的小方块表示不同标签
                  // Container(
                  //   width: 6,
                  //   height: 6,
                  //   margin: EdgeInsets.only(right: 1),
                  //   decoration: BoxDecoration(
                  //     color: Colors.blue,
                  //     borderRadius: BorderRadius.circular(1),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          
          // 点击区域
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onDaySelected(day, day),
                borderRadius: BorderRadius.zero,
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建选中日期信息显示
  Widget _buildSelectedDateInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 格式化选中的日期
    final selectedDate = _selectedDay!;
    final year = selectedDate.year;
    final month = selectedDate.month;
    final day = selectedDate.day;
    
    // 获取星期
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[selectedDate.weekday - 1];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 日期图标
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 日期信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$year年$month月$day日',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekday,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 是否是今天的标识
              if (isSameDay(selectedDate, DateTime.now()))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '今天',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}