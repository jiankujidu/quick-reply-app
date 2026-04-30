import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/message_provider.dart';
// auth_provider not used
import '../models/message.dart';
import '../services/database_service.dart';
// overlay_service not used
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadMessages();
    });
  }

  int _lastTabIndex = 0;

  void _onTabChanged() {
    if (_tabController.index == _lastTabIndex) return;
    _lastTabIndex = _tabController.index;
    // 切换tab时清除搜索
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // level filtering is handled by tab controller directly

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 话术库', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => _showCategoryManager(context),
            tooltip: '分类管理',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '📋 全部'),
            Tab(text: '🏢 公司级'),
            Tab(text: '👥 小组级'),
            Tab(text: '👤 我的'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(),
          // 分类筛选条
          _buildCategoryChips(messageProvider),
          const SizedBox(height: 4),
          // 话术列表
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessageList(null, messageProvider),   // 全部
                _buildMessageList('company', messageProvider),
                _buildMessageList('group', messageProvider),
                _buildMessageList('private', messageProvider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('新建话术'),
      ),
    );
  }

  /// 横向分类筛选条
  Widget _buildCategoryChips(MessageProvider provider) {
    if (provider.categories.isEmpty) return const SizedBox.shrink();
    final cats = provider.categories.where((c) => c['parentId'] == null).toList();
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('全部'),
              selected: _selectedCategory == null,
              selectedColor: Colors.blue.withOpacity(0.15),
              checkmarkColor: Colors.blue,
              side: BorderSide(color: _selectedCategory == null ? Colors.blue : Colors.grey.shade300),
              onSelected: (_) => setState(() => _selectedCategory = null),
            ),
          ),
          ...cats.map((cat) {
            final name = cat['name'] as String;
            final color = _getCategoryColor(name, provider);
            final selected = _selectedCategory == name;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                avatar: CircleAvatar(backgroundColor: color, radius: 8),
                label: Text(name),
                selected: selected,
                selectedColor: color.withOpacity(0.15),
                checkmarkColor: color,
                side: BorderSide(color: selected ? color : Colors.grey.shade300),
                onSelected: (_) => setState(() => _selectedCategory = selected ? null : name),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索话术...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  /// 根据 tab 过滤内存中的话术列表(不再重复请求数据库)
  List<Message> _filterMessages(List<Message> all, String? level) {
    if (level == null) return all;
    return all.where((m) {
      final ml = m.level.toLowerCase();
      final tl = level.toLowerCase();
      if (ml == tl) return true;
      if (tl == 'company' && (ml == '公司级' || ml.contains('公司'))) return true;
      if (tl == 'group' && (ml == '小组级' || ml.contains('小组'))) return true;
      if (tl == 'private' && (ml == '私人' || ml == '我的' || ml.contains('私人'))) return true;
      return false;
    }).toList();
  }

  Widget _buildMessageList(String? level, MessageProvider provider) {
    // 加载中
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 有错误
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('加载失败', style: TextStyle(color: Colors.red[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('${provider.error}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => provider.loadMessages(), child: const Text('重试')),
          ],
        ),
      );
    }

    // 过滤消息
    List<Message> filtered = _filterMessages(provider.messages, level);

    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((m) {
        return m.title.toLowerCase().contains(q) ||
            m.content.toLowerCase().contains(q) ||
            m.tags.any((t) => t.toLowerCase().contains(q)) ||
            m.category.toLowerCase().contains(q) ||
            (m.subcategory?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 空状态
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无${_getLevelName(level)}话术',
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => provider.loadMessages(),
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _navigateToEditor(context, level: level),
              icon: const Icon(Icons.add),
              label: const Text('添加话术'),
            ),
          ],
        ),
      );
    }

    // 有数据:显示分类列表
    return RefreshIndicator(
      onRefresh: () => provider.loadMessages(),
      child: _buildCategorizedList(filtered, provider),
    );
  }

  /// 构建按分类层级组织的列表
  Widget _buildCategorizedList(List<Message> messages, MessageProvider provider) {
    // 按一级分类分组
    final categoryGroups = <String, List<Message>>{};
    for (final msg in messages) {
      final category = msg.category.isEmpty ? '未分类' : msg.category;
      categoryGroups.putIfAbsent(category, () => []).add(msg);
    }

    // 按分类筛选条过滤
    if (_selectedCategory != null) {
      final filtered = <String, List<Message>>{};
      if (categoryGroups.containsKey(_selectedCategory)) {
        filtered[_selectedCategory!] = categoryGroups[_selectedCategory!]!;
      }
      categoryGroups.clear();
      categoryGroups.addAll(filtered);
    }

    // 按一级分类名称排序
    final sortedCategories = categoryGroups.keys.toList()..sort();

    if (sortedCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('该分类下暂无话术', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryMessages = categoryGroups[category]!;
        return _buildCategorySection(category, categoryMessages, provider);
      },
    );
  }

  /// 根据一级分类名获取颜色(从 provider.categories 匹配)
  Color _getCategoryColor(String categoryName, MessageProvider provider) {
    for (final cat in provider.categories) {
      if (cat['name'] == categoryName && cat['color'] != null) {
        final hex = (cat['color'] as String).replaceFirst('#', '');
        try {
          return Color(int.parse('FF$hex', radix: 16));
        } catch (_) {}
      }
    }
    // 默认颜色轮
    final defaults = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return defaults[categoryName.hashCode.abs() % defaults.length];
  }

  /// 构建一级分类区块 - 紧凑彩色版(左侧色条)
  Widget _buildCategorySection(String category, List<Message> messages, MessageProvider provider) {
    // 按二级分类再分组
    final subcategoryGroups = <String, List<Message>>{};
    for (final msg in messages) {
      final sub = msg.subcategory?.isEmpty ?? true ? '默认' : msg.subcategory!;
      subcategoryGroups.putIfAbsent(sub, () => []).add(msg);
    }
    final sortedSubs = subcategoryGroups.keys.toList()..sort();
    final color = _getCategoryColor(category, provider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧色条
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              ),
            ),
          // 右侧内容
          Expanded(
            child: ExpansionTile(
              tilePadding: const EdgeInsets.only(left: 8, right: 12),
              childrenPadding: const EdgeInsets.only(bottom: 4, left: 4),
              initiallyExpanded: true,
              title: Row(
                children: [
                  // 彩色圆点
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(category,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${messages.length}',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              children: sortedSubs.map((sub) {
                final subMsgs = subcategoryGroups[sub]!;
                return _buildSubcategorySection(sub, subMsgs, provider, color);
              }).toList(),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// 构建二级分类区块
  Widget _buildSubcategorySection(String subcategory, List<Message> messages, MessageProvider provider, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Card(
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(Icons.subdirectory_arrow_right, size: 16, color: accentColor.withOpacity(0.7)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subcategory,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800]),
                ),
              ),
              Text(
                '${messages.length}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.only(bottom: 4),
          initiallyExpanded: false,
          children: messages.map((msg) => _buildMessageCardCompact(msg, provider)).toList(),
        ),
      ),
    );
  }

  /// 紧凑版话术卡片(用于分类内显示)
  Widget _buildMessageCardCompact(Message message, MessageProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _navigateToEditor(context, message: message),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: '编辑',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            ),
            SlidableAction(
              onPressed: (_) => _confirmDelete(context, message, provider),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '删除',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _showMessageDetail(context, message),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.content,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 附件小图标
                if (message.images.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.image, size: 16, color: Colors.blue[400])),
                if (message.files.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.attach_file, size: 16, color: Colors.orange[400])),
                // 复制按钮 - 放大点击区域
                SizedBox(
                  width: 64,
                  height: 32,
                  child: TextButton.icon(
                    onPressed: () {
                      debugPrint('[快捷发送] 紧凑卡片复制按钮被点击');
                      _copyText(context, message);
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('复制', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                // 分享按钮 - 有附件时显示
                if (message.images.isNotEmpty || message.files.isNotEmpty)
                  SizedBox(
                    width: 64,
                    height: 32,
                    child: TextButton.icon(
                      onPressed: () {
                        debugPrint('[快捷发送] 紧凑卡片分享按钮被点击');
                        _shareAttachments(context, message);
                      },
                      icon: const Icon(Icons.share, size: 14),
                      label: const Text('分享', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(Message message, MessageProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _navigateToEditor(context, message: message),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: '编辑',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            SlidableAction(
              onPressed: (_) => _confirmDelete(context, message, provider),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '删除',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () => _shareAttachments(context, message),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 分类标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          message.subcategory ?? message.category,
                          style: const TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      // 附件图标
                      if (message.images.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.image, size: 16, color: Colors.blue),
                        ),
                      if (message.files.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.attach_file, size: 16, color: Colors.orange),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], height: 1.4),
                  ),
                  if (message.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.tags.map((tag) => _buildTag(tag)).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 快捷操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 复制按钮
                      TextButton.icon(
                        onPressed: () => _copyText(context, message),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: Size.zero,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 分享按钮
                      if (message.images.isNotEmpty || message.files.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _shareAttachments(context, message),
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('分享', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    final colors = {
      '欢迎语': Colors.green,
      '咨询': Colors.orange,
      '售后': Colors.red,
      '活动': Colors.purple,
      '常用': Colors.blue,
    };
    final color = colors[tag] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(tag, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  // === 操作方法 ===

  /// 显示话术详情
  void _showMessageDetail(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (message.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: message.tags.map((tag) => _buildTag(tag)).toList(),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  message.content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              if (message.images.isNotEmpty) ...[
                Text('图片附件:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: message.images.map((path) => Chip(label: Text(p.basename(path)))).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (message.files.isNotEmpty) ...[
                Text('文件附件:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: message.files.map((path) => Chip(label: Text(p.basename(path)))).toList(),
                ),
                const SizedBox(height: 16),
              ],
              // 操作按钮行:复制 + 分享微信
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _copyText(context, message);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('复制'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _shareAttachments(context, message);
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('分享'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 一键复制文字到剪贴板
  void _copyText(BuildContext context, Message message) {
    debugPrint('[快捷发送] 复制按钮点击: ${message.title}');
    debugPrint('[快捷发送] 内容长度: ${message.content.length}');
    Clipboard.setData(ClipboardData(text: message.content));
    debugPrint('[快捷发送] 已写入剪贴板');
    
    // 先尝试 SnackBar
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已复制到剪贴板'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('[快捷发送] SnackBar 显示失败: $e');
    }
  }

  /// 分享(文字+图片+文件一起发)
  Future<void> _shareAttachments(BuildContext context, Message message) async {
    debugPrint('[快捷发送] 分享按钮点击: ${message.title}');
    final allAttachments = <String>[...message.images, ...message.files];
    debugPrint('[快捷发送] 附件数量: ${allAttachments.length}');

    if (allAttachments.isEmpty) {
      debugPrint('[快捷发送] 无附件，转为复制文字');
      _copyText(context, message);
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final xfiles = <XFile>[];
      for (final rawPath in allAttachments) {
        // 相对路径转绝对路径(和 profile_screen.dart / editor_screen.dart 一致)
        final absPath = rawPath.startsWith('/') ? rawPath : '${appDir.path}/$rawPath';
        final file = File(absPath);
        debugPrint('[快捷发送] 检查文件: $absPath, 存在: ${await file.exists()}');
        if (await file.exists()) {
          xfiles.add(XFile(absPath));
        }
      }

      debugPrint('[快捷发送] 有效附件: ${xfiles.length}');
      if (xfiles.isNotEmpty) {
        debugPrint('[快捷发送] 调用 Share.shareXFiles');
        await Share.shareXFiles(xfiles, text: message.content);
      } else {
        debugPrint('[快捷发送] 无有效附件，转为复制文字');
        _copyText(context, message);
      }
    } catch (e, stackTrace) {
      debugPrint('[快捷发送] 分享出错: $e');
      debugPrint('[快捷发送] 堆栈: $stackTrace');
      _copyText(context, message);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ 分享出错,已复制文字: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _navigateToEditor(BuildContext context, {Message? message, String? level}) {
    // 如果没指定level,根据当前tab决定
    String currentLevel;
    if (level != null) {
      currentLevel = level;
    } else if (_tabController.index == 0) {
      currentLevel = 'private'; // "全部"标签默认创建私人级话术
    } else {
      final levels = ['private', 'company', 'group', 'private'];
      currentLevel = levels[_tabController.index];
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          message: message,
          defaultLevel: currentLevel,
        ),
      ),
    ).then((_) {
      // 从编辑器返回后刷新
      context.read<MessageProvider>().loadMessages();
    });
  }

  void _confirmDelete(BuildContext context, Message message, MessageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除话术"${message.title}"吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMessage(message.id!);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getLevelName(String? level) {
    if (level == null) return '';
    switch (level) {
      case 'company': return '公司级';
      case 'group': return '小组级';
      case 'private': return '私人';
      default: return '';
    }
  }

  void _showCategoryManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => _CategoryManagerSheet(
          onRefresh: () => context.read<MessageProvider>().loadMessages(),
        ),
      ),
    );
  }

}

// 分类管理组件 - 重构版,风格与主体一致

class _CategoryManagerSheet extends StatefulWidget {
  final VoidCallback onRefresh;
  const _CategoryManagerSheet({required this.onRefresh});
  @override
  State<_CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<_CategoryManagerSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedLevel = 'private';
  String _selectedColor = '#2563EB';
  List<Map<String, dynamic>> _allCategories = [];

  static const List<Map<String, String>> _presetColors = [
    {'hex': '#2563EB', 'name': '蓝色'},
    {'hex': '#10B981', 'name': '绿色'},
    {'hex': '#F59E0B', 'name': '橙色'},
    {'hex': '#EF4444', 'name': '红色'},
    {'hex': '#8B5CF6', 'name': '紫色'},
    {'hex': '#EC4899', 'name': '粉色'},
    {'hex': '#06B6D4', 'name': '青色'},
    {'hex': '#F97316', 'name': '深橙'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = DatabaseService();
    final all = await db.getAllCategories();
    setState(() {
      _allCategories = all;
    });
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  List<Map<String, dynamic>> _getRootCategories(String level) {
    return _allCategories.where((c) => c['parentId'] == null && (c['level'] ?? 'private') == level).toList();
  }

  List<Map<String, dynamic>> _getSubcategories(int parentId) {
    return _allCategories.where((c) => c['parentId'] == parentId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📁 分类管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),

          // 快速添加区域
          _buildQuickAdd(),
          const SizedBox(height: 16),

          // 分类列表
          const Divider(height: 24),
          Expanded(child: _buildCategoryList()),
        ],
      ),
    );
  }

  // 快速添加一级分类
  Widget _buildQuickAdd() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('快速添加', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 10),
          
          // 类型选择
          Row(
            children: [
              _buildQuickTypeChip('公司', 'company', Colors.blue),
              const SizedBox(width: 8),
              _buildQuickTypeChip('小组', 'group', Colors.green),
              const SizedBox(width: 8),
              _buildQuickTypeChip('私人', 'private', Colors.orange),
            ],
          ),
          const SizedBox(height: 10),
          
          // 名称输入 + 颜色 + 添加按钮
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '分类名称',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              // 颜色选择
              GestureDetector(
                onTap: () => _showColorPicker(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _parseColor(_selectedColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // 添加按钮
              ElevatedButton(
                onPressed: _nameController.text.isEmpty ? null : _quickAddCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('添加', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTypeChip(String label, String level, Color color) {
    final isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? color : Colors.grey[600], fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _presetColors.map((c) {
            final hex = c['hex']!;
            final isSelected = _selectedColor == hex;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = hex);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseColor(hex),
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _quickAddCategory() async {
    if (_nameController.text.isEmpty) return;
    final db = DatabaseService();
    final rootCats = _allCategories.where((c) => c['parentId'] == null && (c['level'] ?? 'private') == _selectedLevel).toList();
    await db.insertCategory({
      'name': _nameController.text,
      'color': _selectedColor,
      'level': _selectedLevel,
      'parentId': null,
      'sort': rootCats.length,
    });
    _nameController.clear();
    await _loadCategories();
    widget.onRefresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已添加'), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
    }
  }

  Widget _buildCategoryList() {
    if (_allCategories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('暂无分类', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView(
      children: [
        _buildLevelSection('🏢 公司级', 'company', Colors.blue),
        const SizedBox(height: 8),
        _buildLevelSection('👥 小组级', 'group', Colors.green),
        const SizedBox(height: 8),
        _buildLevelSection('👤 私人', 'private', Colors.orange),
      ],
    );
  }

  Widget _buildLevelSection(String title, String level, Color accentColor) {
    final cats = _getRootCategories(level);
    if (cats.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: accentColor)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${cats.length}', style: TextStyle(fontSize: 11, color: accentColor)),
                ),
              ],
            ),
          ),
          ...cats.map((cat) => _buildCategoryItem(cat, accentColor)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> cat, Color accentColor) {
    final name = cat['name'] as String;
    final color = _parseColor(cat['color'] as String);
    final children = _getSubcategories(cat['id']);
    final hasChildren = children.isNotEmpty;

    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          leading: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          title: Text(name, style: const TextStyle(fontSize: 14)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasChildren) Text('${children.length}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _addSubcategory(cat),
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.add, size: 18, color: Colors.green)),
              ),
              InkWell(
                onTap: () => _deleteCategory(cat['id']),
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 16, color: Colors.red)),
              ),
            ],
          ),
        ),
        if (hasChildren)
          Container(
            margin: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[300]!, width: 2))),
            child: Column(
              children: children.map((sub) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                leading: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                title: Text(sub['name'] as String, style: const TextStyle(fontSize: 13)),
                trailing: InkWell(
                  onTap: () => _deleteCategory(sub['id']),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 14, color: Colors.red)),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _addSubcategory(Map<String, dynamic> parent) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加子分类 - ${parent['name']}'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '输入子分类名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final db = DatabaseService();
                await db.insertCategory({
                  'name': controller.text,
                  'color': parent['color'],
                  'level': parent['level'],
                  'parentId': parent['id'],
                  'sort': 0,
                });
                await _loadCategories();
                widget.onRefresh();
              }
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int? id) async {
    if (id == null) return;
    final db = DatabaseService();
    final dbInstance = await db.database;
    await dbInstance.delete('categories', where: 'id = ?', whereArgs: [id]);
    await dbInstance.delete('categories', where: 'parentId = ?', whereArgs: [id]);
    await _loadCategories();
    widget.onRefresh();
  }
}
