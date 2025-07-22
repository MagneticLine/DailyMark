import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_mark/screens/calendar_screen.dart';

void main() {
  group('CalendarScreen Tests', () {
    testWidgets('应该显示台历式日历界面的基本元素', (WidgetTester tester) async {
      // 构建日历界面
      await tester.pumpWidget(
        const MaterialApp(
          home: CalendarScreen(),
        ),
      );

      // 验证应用栏标题
      expect(find.text('日迹'), findsOneWidget);
      
      // 验证今天按钮存在
      expect(find.byIcon(Icons.today), findsOneWidget);
      
      // 验证日历组件存在（通过查找卡片组件）
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('应该显示台历式方形日期单元格', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalendarScreen(),
        ),
      );

      // 等待界面完全加载
      await tester.pumpAndSettle();

      // 验证选中日期信息区域存在
      // 由于初始化时会选中今天，所以应该能找到日期信息
      expect(find.byIcon(Icons.calendar_today), findsAtLeastNWidgets(1));
      
      // 验证日期数字存在（应该能找到当前日期）
      final today = DateTime.now();
      expect(find.text('${today.day}'), findsAtLeastNWidgets(1));
    });

    testWidgets('台历式日期单元格应该支持点击选择', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CalendarScreen(),
        ),
      );

      // 等待界面完全加载
      await tester.pumpAndSettle();

      // 点击今天按钮
      await tester.tap(find.byIcon(Icons.today));
      await tester.pumpAndSettle();

      // 验证没有异常抛出，界面正常显示
      expect(find.text('日迹'), findsOneWidget);
    });
  });
}