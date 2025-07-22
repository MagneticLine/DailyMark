import 'package:flutter/material.dart';
import 'screens/calendar_screen.dart';


void main() {
  runApp(const DailyMarkApp());
}

/// 日迹应用主类
/// 
/// 这是应用的入口点，配置了应用的基础主题和路由
class DailyMarkApp extends StatelessWidget {
  const DailyMarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日迹',
      debugShowCheckedModeBanner: false, // 移除调试横幅
      
      // 配置浅色主题 - 现代极简设计
      theme: ThemeData(
        useMaterial3: true, // 使用 Material 3 设计系统
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // 主色调：现代蓝紫色
          brightness: Brightness.light,
        ),
        
        // 应用栏主题
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        
        // 卡片主题
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // 浮动按钮主题
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      
      // 配置深色主题
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      
      // 跟随系统主题设置
      themeMode: ThemeMode.system,
      
      // 设置首页为日历界面
      home: const CalendarScreen(),
    );
  }
}

