import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/tag_repository.dart';

import 'add_edit_tag_screen.dart';

/// 标签管理界面
/// 
/// 显示所有标签的列表，支持添加、编辑、删除标签
/// 按标签类型分组显示，提供搜索和筛选功能
class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final TagRepository _tagRepository = TagRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<Tag> _allTags = [];
  List<Tag> _filteredTags = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TagType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _loadTags();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载所有标签
  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tags = await _tagRepository.findActive();
      setState(() {
        _allTags = tags;
        _filteredTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载标签失败: $e')),
        );
      }
    }
  }

  /// 搜索变化处理
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  /// 应用筛选条件
  void _applyFilters() {
    _filteredTags = _allTags.where((tag) {
      // 搜索筛选
      final matchesSearch = _searchQuery.isEmpty ||
          tag.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // 类型筛选
      final matchesType = _selectedTypeFilter == null ||
          tag.type == _selectedTypeFilter;
      
      return matchesSearch && matchesType;
    }).toList();
  }

  /// 类型筛选变化
  void _onTypeFilterChanged(TagType? type) {
    setState(() {
      _selectedTypeFilter = type;
      _applyFilters();
    });
  }

  /// 添加新标签
  Future<void> _addNewTag() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditTagScreen(),
      ),
    );
    
    if (result == true) {
      _loadTags(); // 重新加载标签列表
    }
  }

  /// 编辑标签
  Future<void> _editTag(Tag tag) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditTagScreen(tag: tag),
      ),
    );
    
    if (result == true) {
      _loadTags(); // 重新加载标签列表
    }
  }

  /// 删除标签
  Future<void> _deleteTag(Tag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确定要删除标签"${tag.name}"吗？\n\n删除后相关的记录数据将保留，但标签将不再显示。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _tagRepository.softDelete(tag.id);
        _loadTags(); // 重新加载标签列表
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('标签"${tag.name}"已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理'),
        actions: [
          // 添加标签按钮
          IconButton(
            onPressed: _addNewTag,
            icon: const Icon(Icons.add),
            tooltip: '添加标签',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选区域
          _buildSearchAndFilter(),
          
          // 标签列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTags.isEmpty
                    ? _buildEmptyState()
                    : _buildTagList(),
          ),
        ],
      ),
      
      // 浮动添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTag,
        tooltip: '添加标签',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建搜索和筛选区域
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 搜索框
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索标签...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 类型筛选
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('全部', null),
                const SizedBox(width: 8),
                _buildFilterChip('量化标签', TagType.quantitative),
                const SizedBox(width: 8),
                _buildFilterChip('非量化标签', TagType.binary),
                const SizedBox(width: 8),
                _buildFilterChip('复杂标签', TagType.complex),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip(String label, TagType? type) {
    final isSelected = _selectedTypeFilter == type;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _onTypeFilterChanged(selected ? type : null);
      },
    );
  }

  /// 构建标签列表
  Widget _buildTagList() {
    // 按类型分组
    final groupedTags = <TagType, List<Tag>>{};
    for (final tag in _filteredTags) {
      groupedTags.putIfAbsent(tag.type, () => []).add(tag);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTags.length,
      itemBuilder: (context, index) {
        final type = groupedTags.keys.elementAt(index);
        final tags = groupedTags[type]!;
        
        return _buildTagGroup(type, tags);
      },
    );
  }

  /// 构建标签分组
  Widget _buildTagGroup(TagType type, List<Tag> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _getTypeDisplayName(type),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // 标签卡片列表
        ...tags.map((tag) => _buildTagCard(tag)),
        
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建标签卡片
  Widget _buildTagCard(Tag tag) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 解析标签颜色
    Color tagColor;
    try {
      tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      tagColor = colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // 标签颜色指示器
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: tagColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        
        // 标签名称和类型
        title: Text(
          tag.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getTypeDisplayName(tag.type)),
            if (tag.enablePrediction) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.auto_graph,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '已启用预测',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        
        // 操作按钮
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editTag(tag);
                break;
              case 'delete':
                _deleteTag(tag);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('编辑'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        
        // 点击编辑
        onTap: () => _editTag(tag),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedTypeFilter != null
                ? '没有找到匹配的标签'
                : '还没有创建任何标签',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedTypeFilter != null
                ? '尝试调整搜索条件或筛选器'
                : '点击右下角的 + 按钮开始创建第一个标签',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && _selectedTypeFilter == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addNewTag,
              icon: const Icon(Icons.add),
              label: const Text('创建标签'),
            ),
          ],
        ],
      ),
    );
  }

  /// 获取标签类型的显示名称
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
}