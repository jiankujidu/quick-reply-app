import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/message_provider.dart';
import '../providers/auth_provider.dart';
import '../models/message.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadMessages();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '馃摑 璇濇湳搴?,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            final levels = ['company', 'group', 'private'];
            messageProvider.setLevel(levels[index]);
          },
          tabs: const [
            Tab(text: '馃彚 鍏徃绾?),
            Tab(text: '馃懃 灏忕粍绾?),
            Tab(text: '馃懁 鎴戠殑'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList('company', messageProvider),
          _buildMessageList('group', messageProvider),
          _buildMessageList('private', messageProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('鏂板缓璇濇湳'),
      ),
    );
  }

  Widget _buildMessageList(String level, MessageProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final messages = provider.messages.where((m) => m.level == level).toList();

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '鏆傛棤${_getLevelName(level)}璇濇湳',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _navigateToEditor(context, level: level),
              icon: const Icon(Icons.add),
              label: const Text('娣诲姞绗竴鏉¤瘽鏈?),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMessages(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _buildMessageCard(message, provider);
        },
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
            onTap: () => _copyToClipboard(context, message),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (message.images.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.image, size: 18, color: Colors.grey[600]),
                        ),
                      if (message.files.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.attach_file, size: 18, color: Colors.grey[600]),
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
      child: Text(
        tag,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    Fluttertoast.showToast(
      msg: '鉁?宸插鍒跺埌鍓创鏉?,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void _navigateToEditor(BuildContext context, {Message? message, String? level}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          message: message,
          defaultLevel: level ?? 'private',
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Message message, MessageProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('纭鍒犻櫎'),
        content: Text('纭畾瑕佸垹闄よ瘽鏈?${message.title}"鍚楋紵'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('鍙栨秷'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMessage(message.id!);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: '宸插垹闄?, backgroundColor: Colors.red);
            },
            child: const Text('鍒犻櫎', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getLevelName(String level) {
    switch (level) {
      case 'company':
        return '鍏徃绾?;
      case 'group':
        return '灏忕粍绾?;
      case 'private':
        return '绉佷汉';
      default:
        return '';
    }
  }
}
