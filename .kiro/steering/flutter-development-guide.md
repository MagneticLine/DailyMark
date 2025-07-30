# Flutter开发指南

## 核心开发原则

### 🚨 重要提醒
**每次认为任务完成或者需求全部完成前，一定要执行 `flutter run --debug` 让产品经理（我）进行测试，否则不能武断得认为任务已经完成。当我提交需求的时候，说明测试已经进行，请直接开始开发或者修改**

## Flutter常用命令

### 项目管理
```bash
# 创建新的Flutter项目
flutter create <output directory>

# 运行Flutter应用（调试模式）
flutter run --debug

# 运行Flutter应用（发布模式）
flutter run --release

# 清理构建缓存
flutter clean

# 获取依赖包
flutter pub get

# 升级依赖包
flutter pub upgrade
```

### 开发调试
```bash
# 分析代码问题
flutter analyze

# 运行测试
flutter test

# 构建APK（调试版）
flutter build apk --debug

# 构建APK（发布版）
flutter build apk --release

# 查看连接的设备
flutter devices

# 查看日志
flutter logs
```

### 热重载和热重启
在应用运行时：
- 按 `r` 键：热重载（Hot Reload）
- 按 `R` 键：热重启（Hot Restart）
- 按 `q` 键：退出应用

## 开发工作流程

### 1. 任务开始前
```bash
# 确保依赖是最新的
flutter pub get

# 检查代码质量
flutter analyze
```

### 2. 开发过程中
```bash
# 启动调试模式进行开发
flutter run --debug

# 使用热重载快速测试更改
# 在终端中按 'r' 键
```

### 3. 任务完成前（必须执行）
```bash
# 1. 代码质量检查
flutter analyze

# 2. 启动应用进行测试
flutter run --debug

# 3. 让产品经理进行功能测试
# 4. 确认所有功能正常后才能标记任务完成
```

## 调试技巧

### 常见问题解决
```bash
# 如果遇到依赖问题
flutter clean
flutter pub get

# 如果热重载不工作
# 按 'R' 进行热重启

# 如果应用崩溃
# 查看终端输出的错误信息
# 使用 flutter logs 查看详细日志
```

### 性能调试
```bash
# 启用性能分析
flutter run --debug --enable-software-rendering

# 查看widget树
# 在调试模式下按 'w' 键
```

## 代码质量要求

### 编译要求
- 代码必须能够通过 `flutter analyze` 检查
- 不允许有编译错误
- 警告应该尽量修复

### 测试要求
- 每个功能实现后必须进行实际设备测试
- 使用 `flutter run --debug` 在真实环境中验证
- 确保UI响应正常，没有崩溃

### 用户体验要求
- 界面必须响应流畅
- 按钮和交互元素必须可见且可用
- 错误处理要用户友好
- 加载状态要有适当提示

## 项目特定注意事项

### 生活追踪日历项目
- 重点关注日记输入界面的用户体验
- 多媒体功能必须在真实设备上测试
- 数据库操作要确保数据持久化正常
- 标签系统的拖拽功能需要仔细测试

### 常见UI问题
- 底部工具栏被遮挡：检查Scaffold结构
- 键盘弹出时布局问题：使用SingleChildScrollView
- 不同屏幕尺寸适配：测试多种设备

## 发布前检查清单

- [ ] `flutter analyze` 无错误
- [ ] `flutter test` 所有测试通过
- [ ] `flutter run --debug` 应用正常启动
- [ ] 核心功能在真实设备上测试通过
- [ ] 产品经理确认功能符合需求
- [ ] 用户界面在不同屏幕尺寸下正常显示
- [ ] 错误处理和边界情况已测试

## 紧急情况处理

### 应用无法启动
```bash
flutter clean
flutter pub get
flutter run --debug
```

### 依赖冲突
```bash
flutter pub deps
flutter pub upgrade --major-versions
```

### 构建失败
```bash
flutter clean
rm -rf .dart_tool/
flutter pub get
flutter run --debug
```

---

**记住：任何功能开发完成后，都必须通过 `flutter run --debug` 进行实际测试，并让产品经理确认功能正常，才能认为任务真正完成！**