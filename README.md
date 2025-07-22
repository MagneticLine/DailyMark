# 日迹 (DailyMark)

基于 Flutter 开发的生活状态追踪应用，帮助用户记录和管理日常生活状态。

## 项目结构

```
lib/
├── main.dart                 # 应用入口文件
├── controllers/              # 控制器层（状态管理）
│   └── calendar_controller.dart
├── models/                   # 数据模型层
│   └── life_marker.dart
├── views/                    # 视图层（页面）
│   └── home_page.dart
├── widgets/                  # 自定义组件
│   └── custom_card.dart
├── services/                 # 服务层（数据库、网络等）
│   └── database_service.dart
└── utils/                    # 工具类
    ├── constants.dart
    └── date_utils.dart
```

## 主要功能

- 📅 日历视图展示
- 🏷️ 生活状态标记
- 💾 本地数据存储
- 🎨 自定义主题样式

## 技术栈

- **框架**: Flutter 3.8.1+
- **状态管理**: Provider
- **本地存储**: SQLite (sqflite)
- **日历组件**: table_calendar
- **日期处理**: intl

## 开发环境设置

1. 确保已安装 Flutter SDK
2. 启用 Windows 开发者模式（用于符号链接支持）
3. 运行 `flutter pub get` 安装依赖
4. 运行 `flutter run` 启动应用

## 项目初始化状态

✅ 项目基础结构已创建  
✅ 必要依赖包已配置  
✅ 应用主题和样式已设置  
✅ 基础数据模型已定义  
✅ 状态管理架构已搭建  

## 下一步开发计划

1. 实现基础日历界面
2. 添加日期选择功能
3. 实现生活状态标记功能
4. 完善数据存储逻辑
5. 添加更多自定义功能

---

*这是一个学习项目，采用循序渐进的开发方式，每个功能模块都会详细解释和测试。*