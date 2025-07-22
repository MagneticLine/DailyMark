# 设计文档

## 概述

日迹(DailyMark)是一个基于Flutter的跨平台移动应用，采用日历为核心界面，帮助用户量化追踪日常状态。应用支持三种标签类型：量化标签（数值评分）、非量化标签（图标标记）和复杂标签（多子标签）。通过数据可视化、周期性预测和现代极简设计，为用户提供直观的生活规律分析工具。

## 架构

### 整体架构
采用Clean Architecture模式，分为三层：
- **表现层（Presentation Layer）**: Flutter UI组件、状态管理（Provider/Riverpod）
- **业务逻辑层（Domain Layer）**: 用例（Use Cases）、实体（Entities）、仓储接口
- **数据层（Data Layer）**: 本地数据库（SQLite/Hive）、云同步服务、仓储实现

### 技术栈选择理由
- **Flutter**: 跨平台开发，单一代码库支持iOS/Android，符合需求9
- **SQLite/Hive**: 本地数据存储，支持离线使用，符合需求9.4
- **Firebase/Supabase**: 云同步服务，实现跨设备数据同步，符合需求9.2

## 组件和接口

### 核心组件

#### 1. 日历组件 (CalendarWidget)
- **职责**: 显示月/周视图，渲染标签数据和预测信息
- **设计决策**: 自定义日历组件而非第三方库，确保完全控制数据可视化效果
- **接口**:
  ```dart
  class CalendarWidget extends StatefulWidget {
    final CalendarMode mode; // 月视图/周视图
    final List<Tag> selectedTags; // 当前筛选的标签
    final Function(DateTime) onDateSelected;
  }
  ```

#### 2. 标签管理器 (TagManager)
- **职责**: 处理三种标签类型的创建、编辑和数据处理
- **设计决策**: 使用策略模式处理不同标签类型，便于扩展新类型
- **接口**:
  ```dart
  abstract class TagStrategy {
    Widget buildInputWidget();
    dynamic processInput(dynamic input);
    Widget buildVisualization(List<TagRecord> records);
  }
  ```

#### 3. 日记界面 (DiaryInterface)
- **职责**: 提供快速输入界面，整合标签输入和富文本编辑
- **设计决策**: 单页面集成所有输入方式，减少用户操作步骤，符合需求4
- **接口**:
  ```dart
  class DiaryInterface extends StatefulWidget {
    final DateTime selectedDate;
    final List<Tag> presetTags;
  }
  ```

#### 4. 预测引擎 (PredictionEngine)
- **职责**: 分析历史数据，计算周期性规律，生成未来预测
- **设计决策**: 独立模块便于算法优化，支持手动和自动周期设置
- **接口**:
  ```dart
  class PredictionEngine {
    Future<List<Prediction>> generatePredictions(Tag tag, List<TagRecord> history);
    CycleAnalysis analyzeCycle(List<TagRecord> records);
  }
  ```

### 数据流设计
1. **输入流**: 用户输入 → 标签策略处理 → 数据验证 → 本地存储 → 云同步
2. **显示流**: 数据查询 → 可视化处理 → UI渲染 → 用户交互反馈
3. **预测流**: 历史数据 → 周期分析 → 预测生成 → 半透明显示

## 数据模型

### 核心实体

#### Tag（标签）
```dart
class Tag {
  final String id;
  final String name;
  final TagType type; // quantitative, binary, complex
  final Map<String, dynamic> config; // 配置信息（评分范围、图标、子标签等）
  final CycleSetting? cycleSetting;
}
```

#### TagRecord（标签记录）
```dart
class TagRecord {
  final String id;
  final String tagId;
  final DateTime date;
  final dynamic value; // 根据标签类型存储不同数据
  final bool isPrediction;
}
```

#### DiaryEntry（日记条目）
```dart
class DiaryEntry {
  final String id;
  final DateTime date;
  final String content;
  final List<MediaAttachment> attachments; // 图像、音频、视频
  final List<String> tagRecordIds;
}
```

### 数据关系设计
- **一对多**: Tag → TagRecord（一个标签对应多个记录）
- **一对一**: Date → DiaryEntry（每日一个日记条目）
- **多对多**: DiaryEntry ↔ TagRecord（日记条目可关联多个标签记录）

### 数据存储策略
- **本地优先**: 所有数据首先存储在本地SQLite数据库
- **增量同步**: 仅同步变更数据，减少网络传输
- **冲突解决**: 基于时间戳的最后写入获胜策略

## 错误处理

### 错误分类和处理策略

#### 1. 数据验证错误
- **场景**: 用户输入无效数据（如量化标签超出范围）
- **处理**: 实时验证，显示友好错误提示，阻止无效提交
- **用户体验**: 输入框红色边框 + 错误文本提示

#### 2. 网络同步错误
- **场景**: 云同步失败、网络连接问题
- **处理**: 本地数据优先，后台重试机制，用户可手动触发同步
- **用户体验**: 状态指示器显示同步状态，离线模式提示

#### 3. 数据不足错误
- **场景**: 周期分析数据不足（需求5.5）
- **处理**: 友好提示需要更多数据，建议继续记录
- **用户体验**: 信息性对话框，不阻断用户操作

#### 4. 系统级错误
- **场景**: 数据库损坏、内存不足
- **处理**: 错误日志记录，优雅降级，数据备份恢复
- **用户体验**: 错误报告界面，联系支持选项

## 测试策略

### 单元测试
- **标签策略类**: 测试各种标签类型的数据处理逻辑
- **预测引擎**: 测试周期分析算法的准确性
- **数据模型**: 测试数据验证和序列化逻辑
- **覆盖率目标**: 核心业务逻辑 > 90%

### 集成测试
- **数据流测试**: 从用户输入到数据存储的完整流程
- **同步测试**: 本地和云端数据同步的一致性
- **UI集成测试**: 关键用户路径的端到端测试

### UI测试
- **Widget测试**: 各个UI组件的渲染和交互
- **黄金测试**: 关键界面的视觉回归测试
- **响应式测试**: 不同屏幕尺寸的适配测试

### 性能测试
- **大数据量测试**: 测试大量历史数据下的应用性能
- **内存泄漏测试**: 长时间使用的内存管理
- **启动时间测试**: 应用冷启动和热启动性能

### 用户体验测试
- **可用性测试**: 核心功能的易用性评估
- **无障碍测试**: 屏幕阅读器和其他辅助功能支持
- **多语言测试**: 中英文界面的正确显示和交互

## 设计决策说明

### 1. 标签类型设计
**决策**: 采用三种标签类型（量化、非量化、复杂）
**理由**: 覆盖用户不同的记录需求，量化标签用于可测量状态，非量化标签用于是/否事件，复杂标签用于多维度状态

### 2. 日记界面集成设计
**决策**: 单一界面集成所有输入方式
**理由**: 减少用户在不同界面间切换，提高输入效率，符合快速记录的需求

### 3. 预测算法设计
**决策**: 支持手动和自动周期设置
**理由**: 平衡用户控制和智能化，手动设置适用于已知周期，自动分析适用于发现未知规律

### 4. 数据可视化设计
**决策**: 使用颜色深浅、数值和条形图多种方式
**理由**: 适应不同用户的视觉偏好，提供直观的数据理解方式

### 5. 跨平台架构设计
**决策**: Flutter + 云同步服务
**理由**: 单一代码库降低开发成本，云同步确保数据一致性，本地优先保证离线可用性