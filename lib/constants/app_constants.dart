import 'package:flutter/material.dart';

/// 应用常量定义
/// 
/// 包含应用中使用的各种常量，如颜色、尺寸、字符串等

/// 应用颜色常量
class AppColors {
  // 主色调
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  
  // 功能色
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // 中性色
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
}

/// 应用尺寸常量
class AppSizes {
  // 间距
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  
  // 圆角
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  
  // 图标尺寸
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
}

/// 应用字符串常量
class AppStrings {
  // 应用基础信息
  static const String appName = '生活记录日历';
  static const String appDescription = '基于日历框架的生活状态追踪应用';
  
  // 通用文本
  static const String confirm = '确认';
  static const String cancel = '取消';
  static const String save = '保存';
  static const String delete = '删除';
  static const String edit = '编辑';
  static const String add = '添加';
  
  // 日历相关
  static const String today = '今天';
  static const String calendar = '日历';
  static const String monthView = '月视图';
  static const String weekView = '周视图';
  
  // 标签相关
  static const String tag = '标签';
  static const String tags = '标签';
  static const String quantitativeTag = '量化标签';
  static const String binaryTag = '非量化标签';
  static const String complexTag = '复杂标签';
  
  // 日记相关
  static const String diary = '日记';
  static const String diaryEntry = '日记条目';
  static const String writeEntry = '写日记';
}

/// 应用动画时长常量
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}