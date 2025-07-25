import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// 量化标签输入组件
/// 
/// 提供数值输入和单位选择功能
/// 支持滑块和数字输入两种方式
class QuantitativeTagInput extends StatefulWidget {
  /// 标签配置
  final Tag tag;
  
  /// 初始值
  final double? initialValue;
  
  /// 值变化回调
  final ValueChanged<double> onValueChanged;
  
  /// 是否启用输入
  final bool enabled;

  const QuantitativeTagInput({
    super.key,
    required this.tag,
    this.initialValue,
    required this.onValueChanged,
    this.enabled = true,
  });

  @override
  State<QuantitativeTagInput> createState() => _QuantitativeTagInputState();
}

class _QuantitativeTagInputState extends State<QuantitativeTagInput> {
  late TextEditingController _textController;
  late double _currentValue;
  late double _minValue;
  late double _maxValue;
  late String _unit;
  List<String> _labels = [];
  
  @override
  void initState() {
    super.initState();
    _initializeValues();
    _textController = TextEditingController(text: _currentValue.toString());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 初始化数值
  void _initializeValues() {
    _minValue = widget.tag.quantitativeMinValue ?? 1.0;
    _maxValue = widget.tag.quantitativeMaxValue ?? 10.0;
    _unit = widget.tag.quantitativeUnit ?? '';
    
    // 获取标签配置中的文字标签
    if (widget.tag.config.containsKey('labels')) {
      _labels = List<String>.from(widget.tag.config['labels']);
    }
    
    // 设置初始值
    _currentValue = widget.initialValue ?? _minValue;
    
    // 确保初始值在范围内
    _currentValue = _currentValue.clamp(_minValue, _maxValue);
  }

  /// 更新数值
  void _updateValue(double newValue) {
    final clampedValue = newValue.clamp(_minValue, _maxValue);
    setState(() {
      _currentValue = clampedValue;
      _textController.text = _formatValue(clampedValue);
    });
    widget.onValueChanged(clampedValue);
  }

  /// 格式化数值显示
  String _formatValue(double value) {
    // 如果是整数，不显示小数点
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// 获取当前值对应的文字标签
  String? _getCurrentLabel() {
    if (_labels.isEmpty) return null;
    
    // 计算当前值在范围中的位置比例
    final ratio = (_currentValue - _minValue) / (_maxValue - _minValue);
    final index = (ratio * (_labels.length - 1)).round();
    
    return _labels[index.clamp(0, _labels.length - 1)];
  }

  /// 获取颜色深浅（用于可视化）
  double _getColorIntensity() {
    return (_currentValue - _minValue) / (_maxValue - _minValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 解析标签颜色
    Color tagColor;
    try {
      tagColor = Color(int.parse(widget.tag.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      tagColor = colorScheme.primary;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标签名称和当前值
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.tag.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_formatValue(_currentValue)}${_unit.isNotEmpty ? ' $_unit' : ''}',
                    style: TextStyle(
                      color: tagColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            // 文字标签（如果有）
            if (_getCurrentLabel() != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getCurrentLabel()!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tagColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // 滑块输入
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: tagColor,
                inactiveTrackColor: tagColor.withValues(alpha: 0.3),
                thumbColor: tagColor,
                overlayColor: tagColor.withValues(alpha: 0.2),
                valueIndicatorColor: tagColor,
                valueIndicatorTextStyle: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: Slider(
                value: _currentValue,
                min: _minValue,
                max: _maxValue,
                divisions: ((_maxValue - _minValue) * 10).round(),
                label: '${_formatValue(_currentValue)}${_unit.isNotEmpty ? ' $_unit' : ''}',
                onChanged: widget.enabled ? _updateValue : null,
              ),
            ),
            
            // 范围标识
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatValue(_minValue)}${_unit.isNotEmpty ? ' $_unit' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${_formatValue(_maxValue)}${_unit.isNotEmpty ? ' $_unit' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 数字输入框
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _textController,
                    enabled: widget.enabled,
                    decoration: InputDecoration(
                      labelText: '精确输入',
                      suffixText: _unit.isNotEmpty ? _unit : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (value) {
                      final numValue = double.tryParse(value);
                      if (numValue != null) {
                        _updateValue(numValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // 快速调整按钮
                Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 32,
                      child: IconButton(
                        onPressed: widget.enabled && _currentValue < _maxValue
                            ? () => _updateValue(_currentValue + 0.1)
                            : null,
                        icon: const Icon(Icons.add, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: tagColor.withValues(alpha: 0.1),
                          foregroundColor: tagColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 40,
                      height: 32,
                      child: IconButton(
                        onPressed: widget.enabled && _currentValue > _minValue
                            ? () => _updateValue(_currentValue - 0.1)
                            : null,
                        icon: const Icon(Icons.remove, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: tagColor.withValues(alpha: 0.1),
                          foregroundColor: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // 颜色深浅可视化预览
            const SizedBox(height: 16),
            _buildColorPreview(tagColor),
          ],
        ),
      ),
    );
  }

  /// 构建颜色深浅预览
  Widget _buildColorPreview(Color tagColor) {
    final intensity = _getColorIntensity();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '日历显示预览',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 颜色深浅示例
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.3 + intensity * 0.7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: tagColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _formatValue(_currentValue),
                  style: TextStyle(
                    color: intensity > 0.5 ? Colors.white : tagColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '在日历上将显示为此颜色深浅\n数值越高，颜色越深',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}