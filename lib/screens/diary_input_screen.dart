import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/tag_repository.dart';
import '../repositories/tag_record_repository.dart';
import '../widgets/quantitative_tag_input.dart';

/// 日记输入界面
/// 
/// 为选定日期提供快速的标签数据输入
/// 专注于量化标签的输入体验
class DiaryInputScreen extends StatefulWidget {
  /// 选中的日期
  final DateTime selectedDate;

  const DiaryInputScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DiaryInputScreen> createState() => _DiaryInputScreenState();
}

class _DiaryInputScreenState extends State<DiaryInputScreen> {
  final TagRepository _tagRepository = TagRepository();
  final TagRecordRepository _recordRepository = TagRecordRepository();
  
  List<Tag> _quantitativeTags = [];
  Map<String, double> _tagValues = {};
  Map<String, TagRecord?> _existingRecords = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 加载所有量化标签
      final allTags = await _tagRepository.findActive();
      _quantitativeTags = allTags.where((tag) => tag.type.isQuantitative).toList();
      
      // 加载该日期的现有记录
      for (final tag in _quantitativeTags) {
        final existingRecord = await _recordRepository.findByTagAndDate(
          tag.id,
          widget.selectedDate,
        );
        
        if (existingRecord != null) {
          _existingRecords[tag.id] = existingRecord;
          _tagValues[tag.id] = existingRecord.numericValue ?? tag.quantitativeMinValue ?? 1.0;
        } else {
          _existingRecords[tag.id] = null;
          _tagValues[tag.id] = tag.quantitativeMinValue ?? 1.0;
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  /// 保存所有标签数据
  Future<void> _saveAllData() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      
      for (final tag in _quantitativeTags) {
        final value = _tagValues[tag.id];
        if (value == null) continue;
        
        final existingRecord = _existingRecords[tag.id];
        
        if (existingRecord != null) {
          // 更新现有记录
          final updatedRecord = existingRecord.copyWith(
            value: value,
            updatedAt: now,
          );
          await _recordRepository.update(updatedRecord);
        } else {
          // 创建新记录
          final newRecord = TagRecord(
            id: '${tag.id}_${widget.selectedDate.millisecondsSinceEpoch}',
            tagId: tag.id,
            date: widget.selectedDate,
            value: value,
            isPrediction: false,
            createdAt: now,
            updatedAt: now,
          );
          await _recordRepository.insert(newRecord);
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.of(context).pop(true); // 返回true表示有数据变更
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  /// 处理标签值变化
  void _onTagValueChanged(String tagId, double value) {
    setState(() {
      _tagValues[tagId] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 格式化日期显示
    final year = widget.selectedDate.year;
    final month = widget.selectedDate.month;
    final day = widget.selectedDate.day;
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[widget.selectedDate.weekday - 1];

    return Scaffold(
      appBar: AppBar(
        title: Text('$year年$month月$day日 $weekday'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAllData,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quantitativeTags.isEmpty
              ? _buildEmptyState()
              : _buildTagInputList(),
      
      // 保存按钮
      floatingActionButton: _quantitativeTags.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveAllData,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('保存'),
            )
          : null,
    );
  }

  /// 构建标签输入列表
  Widget _buildTagInputList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quantitativeTags.length,
      itemBuilder: (context, index) {
        final tag = _quantitativeTags[index];
        final currentValue = _tagValues[tag.id];
        final hasExistingRecord = _existingRecords[tag.id] != null;
        
        return Column(
          children: [
            Stack(
              children: [
                QuantitativeTagInput(
                  tag: tag,
                  initialValue: currentValue,
                  onValueChanged: (value) => _onTagValueChanged(tag.id, value),
                  enabled: !_isSaving,
                ),
                
                // 已有记录标识
                if (hasExistingRecord)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '已记录',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            if (index < _quantitativeTags.length - 1)
              const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有量化标签',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先在标签管理中创建量化标签\n然后就可以在这里快速记录数据了',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
          ),
        ],
      ),
    );
  }
}