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
  List<Map<String, dynamic>> _subTags = []; // 改为包含类型信息的Map列表
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
          // 尝试从配置中读取完整的子标签信息
          if (tag.config.containsKey('subTagsConfig')) {
            _subTags = List<Map<String, dynamic>>.from(tag.config['subTagsConfig']);
          } else {
            // 兼容旧版本，将字符串列表转换为包含类型信息的Map列表
            _subTags = tag.complexSubTags.map((name) => {
              'name': name,
              'type': TagType.binary, // 默认类型
              'config': {'icon': '✓'}, // 默认配置
            }).toList();
          }
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
          // 保存子标签的完整信息，包括类型和配置
          config['subTags'] = _subTags.map((subTag) => subTag['name'] as String).toList();
          config['subTagsConfig'] = _subTags; // 保存完整的子标签配置
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
            const SizedBox(height: 16),
            _buildQuantitativeLabelsSection(),
          ],
        ),
      ),
    );
  }

  /// 构建量化标签的文字标签部分
  Widget _buildQuantitativeLabelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '文字标签（可选）',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: '为数值范围添加文字描述，如：1-3分对应"差"，4-7分对应"良"，8-10分对应"优"',
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_quantitativeLabels.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quantitativeLabels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              return Chip(
                label: Text('${index + 1}. $label'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeQuantitativeLabel(index),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: '添加文字标签',
                  hintText: '如：差、良、优',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: _addQuantitativeLabel,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('添加文字标签'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: '标签名称',
                            hintText: '如：差、良、优',
                          ),
                          autofocus: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '将按顺序对应数值范围',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          _addQuantitativeLabel(controller.text);
                          Navigator.of(context).pop();
                        },
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('添加'),
            ),
          ],
        ),
        if (_quantitativeLabels.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '可以为数值范围添加文字描述，让标签更直观易懂',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  /// 添加量化标签的文字标签
  void _addQuantitativeLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isNotEmpty) {
      setState(() {
        _quantitativeLabels.add(trimmed);
      });
    }
  }

  /// 移除量化标签的文字标签
  void _removeQuantitativeLabel(int index) {
    setState(() {
      _quantitativeLabels.removeAt(index);
    });
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
            
            // 添加子标签按钮
            ElevatedButton.icon(
              onPressed: _showAddSubTagDialog,
              icon: const Icon(Icons.add),
              label: const Text('添加子标签'),
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
              
              // 子标签列表
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subTags.length,
                itemBuilder: (context, index) {
                  final subTag = _subTags[index];
                  final name = subTag['name'] as String;
                  final type = subTag['type'] as TagType;
                  final config = subTag['config'] as Map<String, dynamic>? ?? {};
                  
                  // 构建子标题，显示配置信息
                  String subtitle = _getTypeDisplayName(type);
                  if (type == TagType.quantitative && config.isNotEmpty) {
                    final minValue = config['minValue']?.toString() ?? '1';
                    final maxValue = config['maxValue']?.toString() ?? '10';
                    final unit = config['unit']?.toString() ?? '';
                    subtitle += ' • $minValue-$maxValue${unit.isNotEmpty ? unit : ''}';
                  } else if (type == TagType.binary && config.isNotEmpty) {
                    final icon = config['icon']?.toString() ?? '✓';
                    subtitle += ' • $icon';
                  }
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(_getTagTypeIcon(type)),
                      title: Text(name),
                      subtitle: Text(subtitle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editSubTag(index),
                            icon: const Icon(Icons.edit),
                            tooltip: '编辑',
                          ),
                          IconButton(
                            onPressed: () => _removeSubTag(index),
                            icon: const Icon(Icons.delete),
                            tooltip: '删除',
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                    '还没有添加子标签\n点击上方按钮添加子标签',
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

  /// 显示添加子标签对话框
  void _showAddSubTagDialog() {
    _showSubTagDialog();
  }

  /// 编辑子标签
  void _editSubTag(int index) {
    final subTag = _subTags[index];
    _showSubTagDialog(
      initialName: subTag['name'] as String,
      initialType: subTag['type'] as TagType,
      index: index,
    );
  }

  /// 显示子标签编辑对话框
  void _showSubTagDialog({
    String? initialName,
    TagType? initialType,
    int? index,
  }) {
    final nameController = TextEditingController(text: initialName ?? '');
    final minValueController = TextEditingController();
    final maxValueController = TextEditingController();
    final unitController = TextEditingController();
    final iconController = TextEditingController();
    
    TagType selectedType = initialType ?? TagType.binary;
    
    // 如果是编辑模式，初始化配置值
    if (index != null && _subTags[index].containsKey('config')) {
      final config = _subTags[index]['config'] as Map<String, dynamic>;
      if (selectedType == TagType.quantitative) {
        minValueController.text = config['minValue']?.toString() ?? '1';
        maxValueController.text = config['maxValue']?.toString() ?? '10';
        unitController.text = config['unit']?.toString() ?? '';
      } else if (selectedType == TagType.binary) {
        iconController.text = config['icon']?.toString() ?? '✓';
      }
    } else {
      // 默认值
      minValueController.text = '1';
      maxValueController.text = '10';
      iconController.text = '✓';
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index != null ? '编辑子标签' : '添加子标签'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '子标签名称',
                    hintText: '输入子标签名称',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TagType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: '标签类型',
                  ),
                  items: [TagType.quantitative, TagType.binary].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getTagTypeIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(_getTypeDisplayName(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _getTypeDescription(selectedType),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 根据类型显示不同的配置选项
                if (selectedType == TagType.quantitative) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '量化配置',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minValueController,
                          decoration: const InputDecoration(
                            labelText: '最小值',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxValueController,
                          decoration: const InputDecoration(
                            labelText: '最大值',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: '单位（可选）',
                      hintText: '如：分、次、小时等',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ] else if (selectedType == TagType.binary) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '图标配置',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: iconController,
                    decoration: const InputDecoration(
                      labelText: '图标',
                      hintText: '选择或输入图标',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '预设图标',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _predefinedIcons.take(8).map((icon) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            iconController.text = icon;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: iconController.text == icon
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              width: iconController.text == icon ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入子标签名称')),
                  );
                  return;
                }
                
                // 验证量化标签的数值范围
                if (selectedType == TagType.quantitative) {
                  final minValue = double.tryParse(minValueController.text);
                  final maxValue = double.tryParse(maxValueController.text);
                  
                  if (minValue == null || maxValue == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入有效的数值范围')),
                    );
                    return;
                  }
                  
                  if (maxValue <= minValue) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('最大值必须大于最小值')),
                    );
                    return;
                  }
                }
                
                // 验证非量化标签的图标
                if (selectedType == TagType.binary && iconController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请选择或输入图标')),
                  );
                  return;
                }
                
                // 检查是否重名（排除自己）
                final isDuplicate = _subTags.asMap().entries.any((entry) {
                  return entry.key != index && entry.value['name'] == name;
                });
                
                if (isDuplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('子标签名称已存在')),
                  );
                  return;
                }
                
                // 构建配置对象
                Map<String, dynamic> config = {};
                if (selectedType == TagType.quantitative) {
                  config = {
                    'minValue': double.parse(minValueController.text),
                    'maxValue': double.parse(maxValueController.text),
                    'unit': unitController.text.trim(),
                  };
                } else if (selectedType == TagType.binary) {
                  config = {
                    'icon': iconController.text.trim(),
                  };
                }
                
                setState(() {
                  final subTagData = {
                    'name': name,
                    'type': selectedType,
                    'config': config,
                  };
                  
                  if (index != null) {
                    _subTags[index] = subTagData;
                  } else {
                    _subTags.add(subTagData);
                  }
                });
                
                Navigator.of(context).pop();
              },
              child: Text(index != null ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }

  /// 移除子标签
  void _removeSubTag(int index) {
    setState(() {
      _subTags.removeAt(index);
    });
  }

  /// 获取标签类型对应的图标
  IconData _getTagTypeIcon(TagType type) {
    switch (type) {
      case TagType.quantitative:
        return Icons.trending_up;
      case TagType.binary:
        return Icons.check_circle_outline;
      case TagType.complex:
        return Icons.category_outlined;
    }
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