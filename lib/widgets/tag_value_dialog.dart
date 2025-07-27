import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// 标签数值修改弹窗组件
/// 
/// 支持的标签类型：
/// - 量化标签：数值输入或滑块选择
/// - 非量化标签：开关切换
/// 
/// 注意：复杂标签将在后续版本中支持
class TagValueDialog extends StatefulWidget {
  /// 要修改的标签
  final Tag tag;
  
  /// 当前记录值（可能为null，表示新增记录）
  final dynamic currentValue;
  
  /// 是否显示删除按钮
  final bool showDeleteButton;
  
  /// 确认回调
  final Function(dynamic value) onConfirm;
  
  /// 删除回调
  final VoidCallback? onDelete;

  const TagValueDialog({
    super.key,
    required this.tag,
    this.currentValue,
    this.showDeleteButton = false,
    required this.onConfirm,
    this.onDelete,
  });

  @override
  State<TagValueDialog> createState() => _TagValueDialogState();
}

class _TagValueDialogState extends State<TagValueDialog> {
  late dynamic _currentValue;
  late TextEditingController _textController;
  bool _isValid = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.currentValue;
    _textController = TextEditingController();
    
    // 根据标签类型初始化默认值
    _initializeValue();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 初始化值
  void _initializeValue() {
    // 检查标签类型，当前支持量化标签和非量化标签
    if (widget.tag.type.isComplex) {
      throw UnsupportedError('复杂标签将在后续版本中支持');
    }
    
    if (widget.tag.type.isQuantitative) {
      // 量化标签初始化
      if (_currentValue is num) {
        _textController.text = _currentValue.toString();
      } else {
        // 使用中间值作为默认值
        final minValue = widget.tag.quantitativeMinValue ?? 1.0;
        final maxValue = widget.tag.quantitativeMaxValue ?? 10.0;
        final defaultValue = (minValue + maxValue) / 2;
        _currentValue = defaultValue;
        _textController.text = defaultValue.toString();
      }
    } else if (widget.tag.type.isBinary) {
      // 非量化标签初始化
      if (_currentValue is bool) {
        // 保持当前值
      } else {
        // 默认为false
        _currentValue = false;
      }
    }
  }

  /// 验证输入值
  bool _validateInput() {
    setState(() {
      _isValid = true;
      _errorMessage = null;
    });

    if (widget.tag.type.isComplex) {
      setState(() {
        _isValid = false;
        _errorMessage = '复杂标签暂不支持';
      });
      return false;
    }
    
    if (widget.tag.type.isQuantitative) {
      // 量化标签验证
      final text = _textController.text.trim();
      if (text.isEmpty) {
        setState(() {
          _isValid = false;
          _errorMessage = '请输入数值';
        });
        return false;
      }
      
      final value = double.tryParse(text);
      if (value == null) {
        setState(() {
          _isValid = false;
          _errorMessage = '请输入有效的数值';
        });
        return false;
      }
      
      final minValue = widget.tag.quantitativeMinValue ?? double.negativeInfinity;
      final maxValue = widget.tag.quantitativeMaxValue ?? double.infinity;
      
      if (value < minValue || value > maxValue) {
        setState(() {
          _isValid = false;
          _errorMessage = '数值应在 $minValue - $maxValue 之间';
        });
        return false;
      }
      
      _currentValue = value;
    } else if (widget.tag.type.isBinary) {
      // 非量化标签不需要特殊验证，_currentValue已经是bool类型
    }
    
    return true;
  }

  /// 处理确认
  void _handleConfirm() {
    if (_validateInput()) {
      widget.onConfirm(_currentValue);
      Navigator.of(context).pop();
    }
  }

  /// 处理删除
  void _handleDelete() {
    // 显示删除确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除标签"${widget.tag.name}"的记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭确认对话框
              Navigator.of(context).pop(); // 关闭主对话框
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getTagTypeIcon(widget.tag.type),
            color: _getTagColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.tag.name,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 根据标签类型显示不同的输入界面
            _buildInputWidget(),
            
            // 错误提示
            if (!_isValid && _errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        // 删除按钮（仅在显示删除按钮时显示）
        if (widget.showDeleteButton)
          TextButton(
            onPressed: _handleDelete,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        
        // 确认按钮
        FilledButton(
          onPressed: _handleConfirm,
          child: Text(_getConfirmButtonText()),
        ),
      ],
    );
  }

  /// 构建输入组件
  Widget _buildInputWidget() {
    if (widget.tag.type.isComplex) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '暂不支持${widget.tag.type.displayName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '该功能将在后续版本中提供',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }
    
    if (widget.tag.type.isQuantitative) {
      return _buildQuantitativeInput();
    } else if (widget.tag.type.isBinary) {
      return _buildBinaryInput();
    }
    
    return const SizedBox.shrink();
  }

  /// 构建量化标签输入界面
  Widget _buildQuantitativeInput() {
    final minValue = widget.tag.quantitativeMinValue ?? 1.0;
    final maxValue = widget.tag.quantitativeMaxValue ?? 10.0;
    final unit = widget.tag.quantitativeUnit ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '请输入数值 ($minValue - $maxValue${unit.isNotEmpty ? ' $unit' : ''})',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        
        // 数值输入框
        TextField(
          controller: _textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            labelText: '数值',
            suffixText: unit.isNotEmpty ? unit : null,
            border: const OutlineInputBorder(),
            errorText: !_isValid ? _errorMessage : null,
          ),
          onChanged: (value) {
            // 实时验证
            setState(() {
              _isValid = true;
              _errorMessage = null;
            });
          },
        ),
        
        // 滑块（如果范围合理的话）
        if (maxValue - minValue <= 20)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '或使用滑块选择',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: (_currentValue as num).toDouble().clamp(minValue, maxValue),
                  min: minValue,
                  max: maxValue,
                  divisions: ((maxValue - minValue) * 2).round(), // 支持0.5的精度
                  label: '${(_currentValue as num).toDouble()}${unit.isNotEmpty ? ' $unit' : ''}',
                  onChanged: (value) {
                    setState(() {
                      _currentValue = value;
                      _textController.text = value.toString();
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }



  /// 获取标签类型图标
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

  /// 获取标签颜色
  Color _getTagColor() {
    try {
      return Color(int.parse(widget.tag.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Theme.of(context).colorScheme.primary;
    }
  }

  /// 构建非量化标签输入界面
  Widget _buildBinaryInput() {
    final icon = widget.tag.binaryIcon ?? '✓';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '设置标签状态',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        
        // 开关控件
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 图标显示
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (_currentValue as bool) 
                      ? _getTagColor().withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_currentValue as bool) 
                        ? _getTagColor()
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    (_currentValue as bool) ? icon : '',
                    style: TextStyle(
                      fontSize: 20,
                      color: (_currentValue as bool) 
                          ? _getTagColor()
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 状态文本和开关
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tag.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          (_currentValue as bool) ? '已完成' : '未完成',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: (_currentValue as bool) 
                                ? _getTagColor()
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    
                    Switch(
                      value: _currentValue as bool,
                      onChanged: (value) {
                        setState(() {
                          _currentValue = value;
                        });
                      },
                      activeColor: _getTagColor(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 获取确认按钮文本
  String _getConfirmButtonText() {
    if (widget.tag.type.isComplex) {
      return '暂不支持';
    }
    return widget.currentValue == null ? '添加' : '确认';
  }
}