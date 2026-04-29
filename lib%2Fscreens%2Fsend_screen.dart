import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/message_provider.dart';
import '../models/message.dart';

class SendScreen extends StatelessWidget {
  const SendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('馃摫 蹇嵎鍙戦€?),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipCard(),
            const SizedBox(height: 24),
            _buildRecentMessages(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                '蹇嵎鍙戦€?,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '鐐瑰嚮璇濇湳鑷姩澶嶅埗锛岀矘璐村埌鑱婂ぉ绐楀彛鍗冲彲鍙戦€併€傛敮鎸佸浘鐗囧拰鏂囦欢闄勪欢锛?,
            style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMessages(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '鏈€杩戜娇鐢?,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all messages
              },
              child: const Text('鏌ョ湅鍏ㄩ儴'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<MessageProvider>(
          builder: (context, provider, _) {
            final recentMessages = provider.recentMessages;
            
            if (recentMessages.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        '鏆傛棤鏈€杩戜娇鐢ㄧ殑璇濇湳',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: recentMessages.map((message) {
                return _buildQuickMessageCard(context, message);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickMessageCard(BuildContext context, Message message) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _copyMessage(context, message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.copy, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.content,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (message.images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.image, size: 20, color: Colors.grey[400]),
                ),
              if (message.files.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.attach_file, size: 20, color: Colors.grey[400]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '蹇嵎鎿嶄綔',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle,
                title: '鏂板缓璇濇湳',
                color: Colors.green,
                onTap: () {
                  // Navigate to editor
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.image,
                title: '娣诲姞鍥剧墖',
                color: Colors.orange,
                onTap: () {
                  // Open image picker
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.attach_file,
                title: '娣诲姞鏂囦欢',
                color: Colors.purple,
                onTap: () {
                  // Open file picker
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage(BuildContext context, Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    Fluttertoast.showToast(
      msg: '鉁?宸插鍒讹細${message.title}',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }
}
