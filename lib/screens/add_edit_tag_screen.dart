import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../repositories/tag_repository.dart';

/// 添加/编辑标签界面
/// 
/// 支持创建新标签或编辑现有标签
/// 根据标签类型显示不同的配置选项
class AddEditTagScreen extends StatefulWidget {
  /// 要编辑的标签，为null时表示创建新标签
  final Tag? tag;

  const AddEditTagScreen({super.key, this.tag});

  @override
  State<AddEditTagScreen> createState() => _AddEditTagScreenState();
}

class _AddEditTagScreenState extends State<AddEditTagScreen> {
  final _formKey = GlobalKey<FormState>();
  final TagRepository _tagRepository = TagRepository();
  
  // 表单控制器
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minValueController = TextEditingController();
  final TextEditingController _maxValueController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _subTagController = TextEditingController();
  
  // 表单状态
  TagType _selectedType = TagType.quantitative;
  String _selectedColor = '#6366F1';
  bool _enablePrediction = false;
  int? _cycleDays;
  List<String> _subTags = [];
  List<String> _quantitativeLabels = [];
  bool _isLoading = false;

  // 预定义颜色
  final List<String> _predefinedColors = [
    '#6366F1', '#8B5CF6', '#EC4899', '#EF4444',
    '#F97316', '#F59E0B', '#84CC16', '#22C55E',
    '#06B6D4', '#3B82F6', '#6366F1', '#8B5CF6',
  ];

  // 预定义图标
  final List<String> _predefinedIcons = [
    '✓', '×', '★', '♥', '●', '■', '▲', '♦',
    '☀', '☁', '☂', '⚡', '❄', '🔥', '💧', '🌟',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    _unitController.dispose();
    _iconController.dispose();
    _subTagController.dispose();
    super.dispose();
  }

  /// 初始化表单
  void _initializeForm() {
    if (widget.tag != null) {
      final tag = widget.tag!;
      _nameController.text = tag.name;
      _selectedType = tag.type;
      _selectedColor = tag.color;
      _enablePrediction = tag.enablePrediction;
      _cycleDays = tag.cycleDays;
      
      // 根据标签类型初始化特定配置
      switch (tag.type) {
        case TagType.quantitative:
          _minValueController.text = tag.quantitativeMinValue?.toString() ?? '1';
          _maxValueController.text = tag.quantitativeMaxValue?.toString() ?? '10';
          _unitController.text = tag.quantitativeUnit ?? '';
          if (tag.config.containsKey('labels')) {
            _quantitativeLabels = List<String>.from(tag.config['labels']);
          }
          break;
        case TagType.binary:
          _iconController.text = tag.binaryIcon ?? '✓';
          break;
        case TagType.complex:
          _subTags = List<String>.from(tag.complexSubTags);
          break;
      }
    } else {
      // 新标签的默认值
      _minValueController.text = '1';
      _maxValueController.text = '10';
      _iconController.text = '✓';
    }
  }

  /// 保存标签
  Future<void> _saveTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 构建配置对象
      final config = <String, dynamic>{};
      
      switch (_selectedType) {
        case TagType.quantitative:
          config['minValue'] = double.parse(_minValueController.text);
          config['maxValue'] = double.parse(_maxValueController.text);
          config['unit'] = _unitController.text.trim();
          if (_quantitativeLabels.isNotEmpty) {
            config['labels'] = _quantitativeLabels;
          }
          break;
        case TagType.binary:
          config['icon'] = _iconController.text.trim();
          break;
        case TagType.complex:
          config['subTags'] = _subTags;
          break;
      }

      final now = DateTime.now();
      final tag = Tag(
        id: widget.tag?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        type: _selectedType,
        config: config,
        color: _selectedColor,
        enablePrediction: _enablePrediction,
        cycleDays: _cycleDays,
        createdAt: widget.tag?.createdAt ?? now,
        updatedAt: now,
        isActive: true,
      );

      if (widget.tag != null) {
        await _tagRepository.update(tag);
      } else {
        await _tagRepository.insert(tag);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tag != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑标签' : '创建标签'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTag,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 基本信息
            _buildBasicInfoSection(),
            
            const SizedBox(height: 24),
            
            // 标签类型选择
            _buildTypeSelectionSection(),
            
            const SizedBox(height: 24),
            
            // 类型特定配置
            _buildTypeSpecificConfig(),
            
            const SizedBox(height: 24),
            
            // 颜色选择
            _buildColorSelectionSection(),
            
            const SizedBox(height: 24),
            
            // 预测设置
            _buildPredictionSection(),
            
            const SizedBox(height: 32),
            
            // 保存按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTag,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(isEditing ? '保存修改' : '创建标签'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建基本信息部分
  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '标签名称',
                hintText: '请输入标签名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入标签名称';
                }
                if (value.trim().length > 20) {
                  return '标签名称不能超过20个字符';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建类型选择部分
  Widget _buildTypeSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签类型',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: TagType.values.map((type) {
                return RadioListTile<TagType>(
                  title: Text(_getTypeDisplayName(type)),
                  subtitle: Text(_getTypeDescription(type)),
                  value: type,
                  groupValue: _selectedType,
                  onChanged: widget.tag != null ? null : (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                );
              }).toList(),
            ),
            if (widget.tag != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '注意：编辑时无法修改标签类型',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建类型特定配置
  Widget _buildTypeSpecificConfig() {
    switch (_selectedType) {
      case TagType.quantitative:
        return _buildQuantitativeConfig();
      case TagType.binary:
        return _buildBinaryConfig();
      case TagType.complex:
        return _buildComplexConfig();
    }
  }

  /// 构建量化标签配置
  Widget _buildQuantitativeConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '量化配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minValueController,
                    decoration: const InputDecoration(
                      labelText: '最小值',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入最小值';
                      }
                      final min = double.tryParse(value);
                      if (min == null) {
                        return '请输入有效数字';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxValueController,
                    decoration: const InputDecoration(
                      labelText: '最大值',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入最大值';
                      }
                      final max = double.tryParse(value);
                      if (max == null) {
                        return '请输入有效数字';
                      }
                      final min = double.tryParse(_minValueController.text);
                      if (min != null && max <= min) {
                        return '最大值必须大于最小值';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: '单位（可选）',
                hintText: '如：分、次、小时等',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建非量化标签配置
  Widget _buildBinaryConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '图标配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(
                labelText: '图标',
                hintText: '选择或输入图标',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请选择或输入图标';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              '预设图标',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedIcons.map((icon) {
                return GestureDetector(
                  onTap: () {
                    _iconController.text = icon;
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _iconController.text == icon
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: _iconController.text == icon ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建复杂标签配置
  Widget _buildComplexConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '子标签配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _subTagController,
                    decoration: const InputDecoration(
                      labelText: '子标签名称',
                      hintText: '输入子标签名称',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: _addSubTag,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addSubTag(_subTagController.text),
                  child: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_subTags.isNotEmpty) ...[
              Text(
                '已添加的子标签',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subTags.map((subTag) {
                  return Chip(
                    label: Text(subTag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeSubTag(subTag),
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '还没有添加子标签\n请在上方输入框中添加',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建颜色选择部分
  Widget _buildColorSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '标签颜色',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _predefinedColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预测设置部分
  Widget _buildPredictionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '预测设置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用周期预测'),
              subtitle: const Text('基于历史数据预测未来状态'),
              value: _enablePrediction,
              onChanged: (value) {
                setState(() {
                  _enablePrediction = value;
                });
              },
            ),
            if (_enablePrediction) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '周期天数（可选）',
                  hintText: '如：28（天）',
                  border: OutlineInputBorder(),
                  helperText: '留空将自动分析周期',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  _cycleDays = value.isEmpty ? null : int.tryParse(value);
                },
                initialValue: _cycleDays?.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 添加子标签
  void _addSubTag(String subTag) {
    final trimmed = subTag.trim();
    if (trimmed.isNotEmpty && !_subTags.contains(trimmed)) {
      setState(() {
        _subTags.add(trimmed);
        _subTagController.clear();
      });
    }
  }

  /// 移除子标签
  void _removeSubTag(String subTag) {
    setState(() {
      _subTags.remove(subTag);
    });
  }

  /// 获取标签类型显示名称
  String _getTypeDisplayName(TagType type) {
    switch (type) {
      case TagType.quantitative:
        return '量化标签';
      case TagType.binary:
        return '非量化标签';
      case TagType.complex:
        return '复杂标签';
    }
  }

  /// 获取标签类型描述
  String _getTypeDescription(TagType type) {
    switch (type) {
      case TagType.quantitative:
        return '用数值评分记录状态（如：心情 1-10分）';
      case TagType.binary:
        return '用图标标记是否发生（如：运动 ✓/×）';
      case TagType.complex:
        return '用多个子标签记录复杂状态（如：睡眠质量）';
    }
  }
}