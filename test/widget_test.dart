// 日迹应用的基础测试
//
// 测试应用的基本功能，确保应用能正常启动和显示基础界面

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_mark/main.dart';

void main() {
  group('应用基础测试', () {
    testWidgets('应用成功启动并显示正确内容', (WidgetTester tester) async {
      // 构建应用并触发一帧渲染
      await tester.pumpWidget(const DailyMarkApp());

      // 验证应用标题显示正确
      expect(find.text('日迹'), findsOneWidget);
      
      // 验证初始化完成消息显示
      expect(find.text('项目初始化完成'), findsOneWidget);
      
      // 验证描述文本显示
      expect(find.text('日迹应用已准备就绪'), findsOneWidget);

      // 验证日历图标显示
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('应用主题配置正确', (WidgetTester tester) async {
      await tester.pumpWidget(const DailyMarkApp());

      // 获取 MaterialApp 组件
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // 验证应用标题
      expect(materialApp.title, '日迹');
      
      // 验证调试横幅已关闭
      expect(materialApp.debugShowCheckedModeBanner, false);
      
      // 验证主题模式设置为跟随系统
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('首页布局正确', (WidgetTester tester) async {
      await tester.pumpWidget(const DailyMarkApp());

      // 验证 Scaffold 存在
      expect(find.byType(Scaffold), findsOneWidget);
      
      // 验证 AppBar 存在
      expect(find.byType(AppBar), findsOneWidget);
      
      // 验证主要内容区域的布局
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
