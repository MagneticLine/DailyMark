import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/models.dart';

/// 数据库演示界面
/// 
/// 展示数据存储功能的基本使用方法
/// 包括创建示例数据、查看数据统计、清理数据等功能
class DatabaseDemoScreen extends StatefulWidget {
  const DatabaseDemoScreen({super.key});

  @override
  State<DatabaseDemoScreen> createState() => _DatabaseDemoScreenState();
}

class _DatabaseDemoScreenState extends State<DatabaseDemoScreen> {
  final DataService _dataService = DataService();
  Map<String, dynamic>? _databaseStatus;
  bool _isLoading = false;
  String _message = '';
  bool _hasDataChanged = false; // 跟踪数据是否有变更

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  /// 初始化数据库
  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
      _message = '正在初始化数据库...';
    });

    try {
      await _dataService.initialize();
      await _refreshStatus();
      setState(() {
        _message = '数据库初始化成功';
      });
    } catch (e) {
      setState(() {
        _message = '数据库初始化失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 刷新数据库状态
  Future<void> _refreshStatus() async {
    final status = await _dataService.getDatabaseStatus();
    setState(() {
      _databaseStatus = status;
    });
  }

  /// 创建示例数据
  Future<void> _createSampleData() async {
    setState(() {
      _isLoading = true;
      _message = '正在创建示例数据...';
    });

    try {
      await _dataService.createSampleData();
      _hasDataChanged = true; // 标记数据已变更
      await _refreshStatus();
      setState(() {
        _message = '示例数据创建成功';
      });
    } catch (e) {
      setState(() {
        _message = '创建示例数据失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 清理所有数据
  Future<void> _clearAllData() async {
    setState(() {
      _isLoading = true;
      _message = '正在清理数据...';
    });

    try {
      await _dataService.clearAllData();
      _hasDataChanged = true; // 标记数据已变更
      await _refreshStatus();
      setState(() {
        _message = '数据清理完成';
      });
    } catch (e) {
      setState(() {
        _message = '数据清理失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 测试标签操作
  Future<void> _testTagOperations() async {
    setState(() {
      _isLoading = true;
      _message = '正在测试标签操作...';
    });

    try {
      // 创建测试标签
      final testTag = Tag(
        id: 'test_tag_${DateTime.now().millisecondsSinceEpoch}',
        name: '测试标签',
        type: TagType.quantitative,
        config: {'minValue': 1, 'maxValue': 10, 'unit': '分'},
        color: '#FF5722',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataService.tags.insert(testTag);

      // 创建测试记录
      final testRecord = TagRecord(
        id: 'test_record_${DateTime.now().millisecondsSinceEpoch}',
        tagId: testTag.id,
        date: DateTime.now(),
        value: 8.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataService.tagRecords.insert(testRecord);

      _hasDataChanged = true; // 标记数据已变更
      await _refreshStatus();
      setState(() {
        _message = '标签操作测试完成';
      });
    } catch (e) {
      setState(() {
        _message = '标签操作测试失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(_hasDataChanged);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据库状态',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_databaseStatus != null)
                      _buildStatusInfo()
                    else
                      const Text('暂无状态信息'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 消息显示
            if (_message.isNotEmpty)
              Card(
                color: _message.contains('失败') 
                    ? Colors.red.shade50 
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _message.contains('失败') 
                          ? Colors.red.shade700 
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            Expanded(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _refreshStatus,
                    child: const Text('刷新状态'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createSampleData,
                    child: const Text('创建示例数据'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _testTagOperations,
                    child: const Text('测试标签操作'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _clearAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('清理所有数据'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态信息显示
  Widget _buildStatusInfo() {
    final dbInfo = _databaseStatus!['database_info'] as Map<String, dynamic>;
    final tagStats = _databaseStatus!['tag_statistics'] as Map<String, dynamic>?;
    final diaryStats = _databaseStatus!['diary_statistics'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('状态: ${_databaseStatus!['status']}'),
        Text('数据库版本: ${dbInfo['database_version']}'),
        const SizedBox(height: 8),
        Text('数据统计:', style: Theme.of(context).textTheme.titleMedium),
        Text('• 标签数量: ${dbInfo['tag_count']}'),
        Text('• 记录数量: ${dbInfo['record_count']}'),
        Text('• 日记数量: ${dbInfo['diary_count']}'),
        Text('• 附件数量: ${dbInfo['attachment_count']}'),
        
        if (tagStats != null && tagStats.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('标签类型统计:', style: Theme.of(context).textTheme.titleMedium),
          ...tagStats.entries.map((entry) => 
            Text('• ${entry.key}: ${entry.value}')
          ),
        ],
        
        if (diaryStats != null && diaryStats['total_entries'] > 0) ...[
          const SizedBox(height: 8),
          Text('日记统计:', style: Theme.of(context).textTheme.titleMedium),
          Text('• 总条目: ${diaryStats['total_entries']}'),
          Text('• 有内容: ${diaryStats['entries_with_content']}'),
          Text('• 有附件: ${diaryStats['entries_with_attachments']}'),
          if (diaryStats['average_mood'] != null)
            Text('• 平均心情: ${(diaryStats['average_mood'] as double).toStringAsFixed(1)}'),
        ],
      ],
    );
  }
}