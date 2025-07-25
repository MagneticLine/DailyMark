# Requirements Document

## Introduction

这是一个基于日历框架的生活记录应用，旨在帮助用户量化和追踪日常状态，通过数据可视化和分析来发现生活规律，并提供预测功能。应用采用现代极简的界面设计，使用Flutter进行跨平台开发。

## Requirements

### Requirement 1

**User Story:** 作为用户，我希望能够在日历上量化记录日常状态，以便直观地查看自己的生活规律和状态变化。

#### Acceptance Criteria

1. WHEN 用户双击某个日期 THEN 系统 SHALL 显示该日期的状态记录界面
2. WHEN 用户创建新的量化标签 THEN 系统 SHALL 允许用户自定义评分范围（数值或文字如差优良）
3. WHEN 用户对某个标签进行评价 THEN 系统 SHALL 保存该评价并关联到当前日期
4. WHEN 用户查看某标签的月视图 THEN 系统 SHALL 通过颜色深浅、数值或条形图显示标签状态的起伏变化
5. WHEN 用户查看某标签的周视图 THEN 系统 SHALL 显示该周内各标签的状态变化趋势
6. WHEN 用户点击特定标签 THEN 系统 SHALL 隐藏其他标签数据，仅显示当前标签的热力图或放大标记
7. WHEN 用户点击空白处 THEN 系统 SHALL 恢复显示所有标签数据

### Requirement 2

**User Story:** 作为用户，我希望能够使用简单的图标标记非量化事件，以便快速记录是否发生的事情。

#### Acceptance Criteria

1. WHEN 用户创建非量化标签 THEN 系统 SHALL 允许用户选择或自定义图标（如×、✓等）
2. WHEN 用户点击非量化标签 THEN 系统 SHALL 切换该标签的状态（有/无）
3. WHEN 用户查看日历 THEN 系统 SHALL 在对应日期显示相应的图标标记

### Requirement 3

**User Story:** 作为用户，我希望能够为复杂状态创建多个子标签，以便更详细地记录状态信息。

#### Acceptance Criteria

1. WHEN 用户创建复杂标签（如睡眠状态） THEN 系统 SHALL 允许添加多个子标签
2. WHEN 用户输入新的子标签 THEN 系统 SHALL 将其添加到标签库中供后续使用
3. WHEN 用户选择复杂标签 THEN 系统 SHALL 显示所有可用的子标签选项
4. WHEN 用户保存复杂标签记录 THEN 系统 SHALL 保存所有选中的子标签

### Requirement 4

**User Story:** 作为用户，我希望通过折叠式标签界面快速管理当日标签，以便高效地记录和修改状态。

#### Acceptance Criteria

1. WHEN 用户查看日历下方 THEN 系统 SHALL 显示一个折叠条，点击后展开显示标签管理界面
2. WHEN 折叠条展开 THEN 系统 SHALL 显示已添加标签（原色）和未添加标签（半透明浅色）
3. WHEN 用户长按已添加标签 THEN 系统 SHALL 弹出修改数值窗口，包含删除按钮
4. WHEN 用户长按未添加标签 THEN 系统 SHALL 自动为当日添加该标签并弹出数值修改窗口
5. WHEN 用户点击已添加或未添加标签 THEN 系统 SHALL 在日历上仅显示该标签的数据可视化
6. WHEN 用户点击空白处 THEN 系统 SHALL 恢复显示所有标签的数据
7. WHEN 标签管理界面宽度 THEN 系统 SHALL 与日历宽度保持一致

### Requirement 5

**User Story:** 作为用户，我希望能够为标签设置周期性规律，以便系统在未来日历上显示预测。

#### Acceptance Criteria

1. WHEN 用户为标签设置周期 THEN 系统 SHALL 允许用户手动输入周期天数和单位（如28天、1年等）
2. WHEN 用户选择自动分析周期 THEN 系统 SHALL 基于历史数据使用算法拟合最佳周期
3. WHEN 周期设置完成 THEN 系统 SHALL 根据最近的记录和设定周期计算未来预测日期
4. WHEN 系统计算预测 THEN 系统 SHALL 在未来对应日期显示半透明的预测标签
5. IF 历史数据不足或分析得到的周期过大 THEN 系统 SHALL 提示用户需要更多数据来进行周期分析

### Requirement 6

**User Story:** 作为用户，我希望在日历上清楚地区分实际记录和预测信息，以便合理规划未来。

#### Acceptance Criteria

1. WHEN 系统显示预测标签 THEN 系统 SHALL 使用半透明样式区分预测和实际记录
2. WHEN 用户查看未来日期 THEN 系统 SHALL 显示基于周期设置的预测标签
3. WHEN 用户点击预测标签 THEN 系统 SHALL 显示预测依据（周期设置、上次记录时间等）
4. WHEN 预测日期到达 THEN 系统 SHALL 提醒用户确认或更新实际状态
5. WHEN 用户在预测日期添加实际记录 THEN 系统 SHALL 用实际记录替换预测标签

### Requirement 7

**User Story:** 作为用户，我希望能够按标签筛选和查看特定领域的数据，以便专注分析某个方面的规律。

#### Acceptance Criteria

1. WHEN 用户选择标签筛选 THEN 系统 SHALL 显示所有可用标签列表
2. WHEN 用户选择特定标签 THEN 系统 SHALL 只显示该标签相关的数据
3. WHEN 筛选激活 THEN 系统 SHALL 在日历视图中突出显示相关数据
4. WHEN 用户查看筛选结果 THEN 系统 SHALL 提供该标签的统计信息和趋势分析

### Requirement 8

**User Story:** 作为用户，我希望应用具有现代极简的界面设计，以便获得良好的使用体验。

#### Acceptance Criteria

1. WHEN 应用启动 THEN 系统 SHALL 显示简洁的日历主界面
2. WHEN 用户进行任何操作 THEN 系统 SHALL 提供流畅的动画过渡效果
3. WHEN 显示数据可视化 THEN 系统 SHALL 使用清晰易读的图表和颜色方案
4. WHEN 用户导航 THEN 系统 SHALL 提供直观的操作反馈
5. IF 设备支持 THEN 系统 SHALL 适配深色/浅色主题模式

### Requirement 9

**User Story:** 作为用户，我希望应用能够跨平台运行，以便在不同设备上同步使用。

#### Acceptance Criteria

1. WHEN 应用部署 THEN 系统 SHALL 支持iOS和Android平台
2. WHEN 用户在不同设备登录 THEN 系统 SHALL 同步用户的所有数据
3. WHEN 应用在不同屏幕尺寸运行 THEN 系统 SHALL 自适应界面布局
4. WHEN 用户离线使用 THEN 系统 SHALL 支持本地数据存储和后续同步