import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../models/message.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Message> _searchResults = [];
  bool _isSearching = false;
  List<String> _searchHistory = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final provider = context.read<MessageProvider>();
    final results = await provider.searchMessages(keyword);

    setState(() {
      _searchResults = results;
      _isSearching = false;
      if (keyword.isNotEmpty && !_searchHistory.contains(keyword)) {
        _searchHistory.insert(0, keyword);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 搜索话术'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '输入关键词搜索话术...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _performSearch,
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return _buildHistory();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '未找到相关话术',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '试试其他关键词',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final message = _searchResults[index];
        return _buildResultCard(message);
      },
    );
  }

  Widget _buildHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '搜索历史为空',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '输入关键词开始搜索',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '搜索历史',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchHistory.clear();
                });
              },
              child: const Text('清除'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _searchHistory.map((keyword) {
            return ActionChip(
              label: Text(keyword),
              onPressed: () {
                _searchController.text = keyword;
                _performSearch(keyword);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultCard(Message message) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _copyToClipboard(message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  _buildLevelBadge(message.level),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
              if (message.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: message.tags.map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    Color color;
    String text;
    switch (level) {
      case 'company':
        color = Colors.blue;
        text = '公司级';
        break;
      case 'group':
        color = Colors.orange;
        text = '小组级';
        break;
      default:
        color = Colors.green;
        text = '私人';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _copyToClipboard(Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 2)),
    );
  }
}
