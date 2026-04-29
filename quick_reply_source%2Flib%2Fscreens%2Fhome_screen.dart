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
    // 鍒囨崲tab鏃舵竻闄ゆ悳绱?
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
        title: const Text('馃摑 璇濇湳搴?, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => _showCategoryManager(context),
            tooltip: '鍒嗙被绠＄悊',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '馃搵 鍏ㄩ儴'),
            Tab(text: '馃彚 鍏徃绾?),
            Tab(text: '馃懃 灏忕粍绾?),
            Tab(text: '馃懁 鎴戠殑'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 鎼滅储妗?
          _buildSearchBar(),
          // 鍒嗙被绛涢€夋潯
          _buildCategoryChips(messageProvider),
          const SizedBox(height: 4),
          // 璇濇湳鍒楄〃
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessageList(null, messageProvider),   // 鍏ㄩ儴
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
        label: const Text('鏂板缓璇濇湳'),
      ),
    );
  }

  /// 妯悜鍒嗙被绛涢€夋潯
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
              label: const Text('鍏ㄩ儴'),
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
          hintText: '鎼滅储璇濇湳...',
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

  /// 鏍规嵁 tab 杩囨护鍐呭瓨涓殑璇濇湳鍒楄〃(涓嶅啀閲嶅璇锋眰鏁版嵁搴?
  List<Message> _filterMessages(List<Message> all, String? level) {
    if (level == null) return all;
    return all.where((m) {
      final ml = m.level.toLowerCase();
      final tl = level.toLowerCase();
      if (ml == tl) return true;
      if (tl == 'company' && (ml == '鍏徃绾? || ml.contains('鍏徃'))) return true;
      if (tl == 'group' && (ml == '灏忕粍绾? || ml.contains('灏忕粍'))) return true;
      if (tl == 'private' && (ml == '绉佷汉' || ml == '鎴戠殑' || ml.contains('绉佷汉'))) return true;
      return false;
    }).toList();
  }

  Widget _buildMessageList(String? level, MessageProvider provider) {
    // 鍔犺浇涓?
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 鏈夐敊璇?
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('鍔犺浇澶辫触', style: TextStyle(color: Colors.red[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('${provider.error}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => provider.loadMessages(), child: const Text('閲嶈瘯')),
          ],
        ),
      );
    }

    // 杩囨护娑堟伅
    List<Message> filtered = _filterMessages(provider.messages, level);

    // 鎼滅储杩囨护
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

    // 绌虹姸鎬?
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('鏆傛棤${_getLevelName(level)}璇濇湳',
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => provider.loadMessages(),
              icon: const Icon(Icons.refresh),
              label: const Text('鍒锋柊'),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _navigateToEditor(context, level: level),
              icon: const Icon(Icons.add),
              label: const Text('娣诲姞璇濇湳'),
            ),
          ],
        ),
      );
    }

    // 鏈夋暟鎹?鏄剧ず鍒嗙被鍒楄〃
    return RefreshIndicator(
      onRefresh: () => provider.loadMessages(),
      child: _buildCategorizedList(filtered, provider),
    );
  }

  /// 鏋勫缓鎸夊垎绫诲眰绾х粍缁囩殑鍒楄〃
  Widget _buildCategorizedList(List<Message> messages, MessageProvider provider) {
    // 鎸変竴绾у垎绫诲垎缁?
    final categoryGroups = <String, List<Message>>{};
    for (final msg in messages) {
      final category = msg.category.isEmpty ? '鏈垎绫? : msg.category;
      categoryGroups.putIfAbsent(category, () => []).add(msg);
    }

    // 鎸夊垎绫荤瓫閫夋潯杩囨护
    if (_selectedCategory != null) {
      final filtered = <String, List<Message>>{};
      if (categoryGroups.containsKey(_selectedCategory)) {
        filtered[_selectedCategory!] = categoryGroups[_selectedCategory!]!;
      }
      categoryGroups.clear();
      categoryGroups.addAll(filtered);
    }

    // 鎸変竴绾у垎绫诲悕绉版帓搴?
    final sortedCategories = categoryGroups.keys.toList()..sort();

    if (sortedCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('璇ュ垎绫讳笅鏆傛棤璇濇湳', style: TextStyle(color: Colors.grey[400])),
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

  /// 鏍规嵁涓€绾у垎绫诲悕鑾峰彇棰滆壊(浠?provider.categories 鍖归厤)
  Color _getCategoryColor(String categoryName, MessageProvider provider) {
    for (final cat in provider.categories) {
      if (cat['name'] == categoryName && cat['color'] != null) {
        final hex = (cat['color'] as String).replaceFirst('#', '');
        try {
          return Color(int.parse('FF$hex', radix: 16));
        } catch (_) {}
      }
    }
    // 榛樿棰滆壊杞?
    final defaults = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return defaults[categoryName.hashCode.abs() % defaults.length];
  }

  /// 鏋勫缓涓€绾у垎绫诲尯鍧?- 绱у噾褰╄壊鐗?宸︿晶鑹叉潯)
  Widget _buildCategorySection(String category, List<Message> messages, MessageProvider provider) {
    // 鎸変簩绾у垎绫诲啀鍒嗙粍
    final subcategoryGroups = <String, List<Message>>{};
    for (final msg in messages) {
      final sub = msg.subcategory?.isEmpty ?? true ? '榛樿' : msg.subcategory!;
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
            // 宸︿晶鑹叉潯
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              ),
            ),
          // 鍙充晶鍐呭
          Expanded(
            child: ExpansionTile(
              tilePadding: const EdgeInsets.only(left: 8, right: 12),
              childrenPadding: const EdgeInsets.only(bottom: 4, left: 4),
              initiallyExpanded: true,
              title: Row(
                children: [
                  // 褰╄壊鍦嗙偣
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

  /// 鏋勫缓浜岀骇鍒嗙被鍖哄潡
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

  /// 绱у噾鐗堣瘽鏈崱鐗?鐢ㄤ簬鍒嗙被鍐呮樉绀?
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
              label: '缂栬緫',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            ),
            SlidableAction(
              onPressed: (_) => _confirmDelete(context, message, provider),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '鍒犻櫎',
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
                // 闄勪欢灏忓浘鏍?
                if (message.images.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.image, size: 16, color: Colors.blue[400])),
                if (message.files.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.attach_file, size: 16, color: Colors.orange[400])),
                // 澶嶅埗鎸夐挳 - 鏀惧ぇ鐐瑰嚮鍖哄煙
                SizedBox(
                  width: 64,
                  height: 32,
                  child: TextButton.icon(
                    onPressed: () {
                      debugPrint('[蹇嵎鍙戦€乚 绱у噾鍗＄墖澶嶅埗鎸夐挳琚偣鍑?);
                      _copyText(context, message);
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('澶嶅埗', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                // 鍒嗕韩鎸夐挳 - 鏈夐檮浠舵椂鏄剧ず
                if (message.images.isNotEmpty || message.files.isNotEmpty)
                  SizedBox(
                    width: 64,
                    height: 32,
                    child: TextButton.icon(
                      onPressed: () {
                        debugPrint('[蹇嵎鍙戦€乚 绱у噾鍗＄墖鍒嗕韩鎸夐挳琚偣鍑?);
                        _shareAttachments(context, message);
                      },
                      icon: const Icon(Icons.share, size: 14),
                      label: const Text('鍒嗕韩', style: TextStyle(fontSize: 12)),
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
              label: '缂栬緫',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            SlidableAction(
              onPressed: (_) => _confirmDelete(context, message, provider),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '鍒犻櫎',
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
                      // 鍒嗙被鏍囩
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
                      // 闄勪欢鍥炬爣
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
                  // 蹇嵎鎿嶄綔鎸夐挳
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 澶嶅埗鎸夐挳
                      TextButton.icon(
                        onPressed: () => _copyText(context, message),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('澶嶅埗', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          minimumSize: Size.zero,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // 鍒嗕韩鎸夐挳
                      if (message.images.isNotEmpty || message.files.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _shareAttachments(context, message),
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('鍒嗕韩', style: TextStyle(fontSize: 12)),
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
      '娆㈣繋璇?: Colors.green,
      '鍜ㄨ': Colors.orange,
      '鍞悗': Colors.red,
      '娲诲姩': Colors.purple,
      '甯哥敤': Colors.blue,
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

  // === 鎿嶄綔鏂规硶 ===

  /// 鏄剧ず璇濇湳璇︽儏
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
                Text('鍥剧墖闄勪欢:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: message.images.map((path) => Chip(label: Text(p.basename(path)))).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (message.files.isNotEmpty) ...[
                Text('鏂囦欢闄勪欢:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: message.files.map((path) => Chip(label: Text(p.basename(path)))).toList(),
                ),
                const SizedBox(height: 16),
              ],
              // 鎿嶄綔鎸夐挳琛?澶嶅埗 + 鍒嗕韩寰俊
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _copyText(context, message);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('澶嶅埗'),
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
                      label: const Text('鍒嗕韩'),
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

  /// 涓€閿鍒舵枃瀛楀埌鍓创鏉?
  void _copyText(BuildContext context, Message message) {
    debugPrint('[蹇嵎鍙戦€乚 澶嶅埗鎸夐挳鐐瑰嚮: ${message.title}');
    debugPrint('[蹇嵎鍙戦€乚 鍐呭闀垮害: ${message.content.length}');
    Clipboard.setData(ClipboardData(text: message.content));
    debugPrint('[蹇嵎鍙戦€乚 宸插啓鍏ュ壀璐存澘');
    
    // 鍏堝皾璇?SnackBar
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('鉁?宸插鍒跺埌鍓创鏉?),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('[蹇嵎鍙戦€乚 SnackBar 鏄剧ず澶辫触: $e');
    }
  }

  /// 鍒嗕韩(鏂囧瓧+鍥剧墖+鏂囦欢涓€璧峰彂)
  Future<void> _shareAttachments(BuildContext context, Message message) async {
    debugPrint('[蹇嵎鍙戦€乚 鍒嗕韩鎸夐挳鐐瑰嚮: ${message.title}');
    final allAttachments = <String>[...message.images, ...message.files];
    debugPrint('[蹇嵎鍙戦€乚 闄勪欢鏁伴噺: ${allAttachments.length}');

    if (allAttachments.isEmpty) {
      debugPrint('[蹇嵎鍙戦€乚 鏃犻檮浠讹紝杞负澶嶅埗鏂囧瓧');
      _copyText(context, message);
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final xfiles = <XFile>[];
      for (final rawPath in allAttachments) {
        // 鐩稿璺緞杞粷瀵硅矾寰?鍜?profile_screen.dart / editor_screen.dart 涓€鑷?
        final absPath = rawPath.startsWith('/') ? rawPath : '${appDir.path}/$rawPath';
        final file = File(absPath);
        debugPrint('[蹇嵎鍙戦€乚 妫€鏌ユ枃浠? $absPath, 瀛樺湪: ${await file.exists()}');
        if (await file.exists()) {
          xfiles.add(XFile(absPath));
        }
      }

      debugPrint('[蹇嵎鍙戦€乚 鏈夋晥闄勪欢: ${xfiles.length}');
      if (xfiles.isNotEmpty) {
        debugPrint('[蹇嵎鍙戦€乚 璋冪敤 Share.shareXFiles');
        await Share.shareXFiles(xfiles, text: message.content);
      } else {
        debugPrint('[蹇嵎鍙戦€乚 鏃犳湁鏁堥檮浠讹紝杞负澶嶅埗鏂囧瓧');
        _copyText(context, message);
      }
    } catch (e, stackTrace) {
      debugPrint('[蹇嵎鍙戦€乚 鍒嗕韩鍑洪敊: $e');
      debugPrint('[蹇嵎鍙戦€乚 鍫嗘爤: $stackTrace');
      _copyText(context, message);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('鈿狅笍 鍒嗕韩鍑洪敊,宸插鍒舵枃瀛? $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _navigateToEditor(BuildContext context, {Message? message, String? level}) {
    // 濡傛灉娌℃寚瀹歭evel,鏍规嵁褰撳墠tab鍐冲畾
    String currentLevel;
    if (level != null) {
      currentLevel = level;
    } else if (_tabController.index == 0) {
      currentLevel = 'private'; // "鍏ㄩ儴"鏍囩榛樿鍒涘缓绉佷汉绾ц瘽鏈?
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
      // 浠庣紪杈戝櫒杩斿洖鍚庡埛鏂?
      context.read<MessageProvider>().loadMessages();
    });
  }

  void _confirmDelete(BuildContext context, Message message, MessageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('纭鍒犻櫎'),
        content: Text('纭畾瑕佸垹闄よ瘽鏈?${message.title}"鍚?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('鍙栨秷'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMessage(message.id!);
              Navigator.pop(context);
            },
            child: const Text('鍒犻櫎', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getLevelName(String? level) {
    if (level == null) return '';
    switch (level) {
      case 'company': return '鍏徃绾?;
      case 'group': return '灏忕粍绾?;
      case 'private': return '绉佷汉';
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

// 鍒嗙被绠＄悊缁勪欢 - 閲嶆瀯鐗?椋庢牸涓庝富浣撲竴鑷?

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
    {'hex': '#2563EB', 'name': '钃濊壊'},
    {'hex': '#10B981', 'name': '缁胯壊'},
    {'hex': '#F59E0B', 'name': '姗欒壊'},
    {'hex': '#EF4444', 'name': '绾㈣壊'},
    {'hex': '#8B5CF6', 'name': '绱壊'},
    {'hex': '#EC4899', 'name': '绮夎壊'},
    {'hex': '#06B6D4', 'name': '闈掕壊'},
    {'hex': '#F97316', 'name': '娣辨'},
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
          // 鏍囬鏍?
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('馃搧 鍒嗙被绠＄悊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),

          // 蹇€熸坊鍔犲尯鍩?
          _buildQuickAdd(),
          const SizedBox(height: 16),

          // 鍒嗙被鍒楄〃
          const Divider(height: 24),
          Expanded(child: _buildCategoryList()),
        ],
      ),
    );
  }

  // 蹇€熸坊鍔犱竴绾у垎绫?
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
          const Text('蹇€熸坊鍔?, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 10),
          
          // 绫诲瀷閫夋嫨
          Row(
            children: [
              _buildQuickTypeChip('鍏徃', 'company', Colors.blue),
              const SizedBox(width: 8),
              _buildQuickTypeChip('灏忕粍', 'group', Colors.green),
              const SizedBox(width: 8),
              _buildQuickTypeChip('绉佷汉', 'private', Colors.orange),
            ],
          ),
          const SizedBox(height: 10),
          
          // 鍚嶇О杈撳叆 + 棰滆壊 + 娣诲姞鎸夐挳
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: '鍒嗙被鍚嶇О',
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
              // 棰滆壊閫夋嫨
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
              // 娣诲姞鎸夐挳
              ElevatedButton(
                onPressed: _nameController.text.isEmpty ? null : _quickAddCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('娣诲姞', style: TextStyle(color: Colors.white, fontSize: 13)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('鉁?宸叉坊鍔?), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
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
            Text('鏆傛棤鍒嗙被', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView(
      children: [
        _buildLevelSection('馃彚 鍏徃绾?, 'company', Colors.blue),
        const SizedBox(height: 8),
        _buildLevelSection('馃懃 灏忕粍绾?, 'group', Colors.green),
        const SizedBox(height: 8),
        _buildLevelSection('馃懁 绉佷汉', 'private', Colors.orange),
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
        title: Text('娣诲姞瀛愬垎绫?- ${parent['name']}'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '杈撳叆瀛愬垎绫诲悕绉?)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('鍙栨秷')),
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
            child: const Text('娣诲姞'),
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
