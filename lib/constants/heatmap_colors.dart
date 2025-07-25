import 'package:flutter/material.dart';

/// 热力图颜色配置
/// 
/// 定义聚焦模式下日历格子背景的颜色范围
/// 方便调试和修改颜色方案
class HeatmapColors {
  /// 低值颜色（红色）
  static const Color lowValue = Color(0xFFF44336);  // 红色
  
  /// 中值颜色（黄色）
  static const Color midValue = Color(0xFFFFC107);  // 黄色
  
  /// 高值颜色（绿色）
  static const Color highValue = Color(0xFF4CAF50); // 绿色
  
  /// 无数据时的背景色（量化标签聚焦模式）
  static const Color noData = Colors.transparent;    // 透明，与默认背景保持一致
  
  /// 默认背景色（普通模式和非量化标签聚焦模式）
  static const Color defaultBackground = Colors.transparent; // 透明，继承父容器背景
  
  /// 数字文本颜色
  static const Color textColor = Colors.black87;
  
  // ========== 边框和线条相关常量 ==========
  
  /// 聚焦模式选中状态边框颜色（使用null表示使用主题色）
  static const Color? focusedSelectedBorderColor = null;
  
  /// 聚焦模式选中状态边框宽度
  static const double focusedSelectedBorderWidth = 2.0;
  
  /// 聚焦模式普通状态边框颜色
  static const Color focusedNormalBorderColor = Colors.black26;
  
  /// 聚焦模式普通状态边框宽度
  static const double focusedNormalBorderWidth = 0.09;
  
  /// 普通模式选中状态边框宽度
  static const double normalSelectedBorderWidth = 1.8;
  
  /// 普通模式普通状态边框宽度
  static const double normalBorderWidth = 0.5;
  
  /// 普通模式边框透明度
  static const double normalBorderAlpha = 0.2;
  
  // ========== 文字颜色相关常量 ==========
  
  /// 聚焦模式周末文字颜色
  static const Color focusedWeekendTextColor = Color.fromARGB(255, 134, 37, 30);
  
  /// 聚焦模式月外日期文字透明度
  static const double focusedOutsideTextAlpha = 0.3;
  
  ///
  /// 
  /// [intensity] 强度值，范围 0.0 - 1.0
  /// 返回对应的颜色，实现绿→黄→红的渐变
  static Color getColorForIntensity(double intensity) {
    if (intensity <= 0.0) {
      return noData;
    } else if (intensity <= 0.5) {
      // 0.0 - 0.5: 绿色到黄色的渐变
      return Color.lerp(lowValue, midValue, intensity * 2)!;
    } else {
      // 0.5 - 1.0: 黄色到红色的渐变
      return Color.lerp(midValue, highValue, (intensity - 0.5) * 2)!;
    }
  }
  
  /// 获取无数据状态的颜色（量化标签专用）
  static Color getNoDataColor() {
    return noData;
  }
  
  /// 获取默认背景色
  static Color getDefaultBackground() {
    return defaultBackground;
  }
  
  /// 获取文本颜色
  static Color getTextColor() {
    return textColor;
  }
}