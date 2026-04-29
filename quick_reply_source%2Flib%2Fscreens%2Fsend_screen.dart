import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/message_provider.dart';
import '../models/message.dart';
import 'editor_screen.dart';
import 'package:quick_reply_app/main.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final ImagePicker _imagePicker = ImagePicker();

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
                // 鍒囨崲鍒拌瘽鏈簱tab
                MainScreen.goToTab(0);
              },
              child: const Text('鏌ョ湅鍏ㄩ儴 鈫?),
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
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/home');
                        },
                        child: const Text('鍘绘坊鍔犺瘽鏈?),
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
    final hasImages = message.images.isNotEmpty;
    final hasFiles = message.files.isNotEmpty;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _copyMessage(context, message),
        onLongPress: () => _shareMessage(context, message),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // 宸︿晶澶嶅埗鎸夐挳鍖哄煙 - 鍙偣鍑?              GestureDetector(
                onTap: () => _copyMessage(context, message),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.copy_rounded, color: Colors.blue, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              // 涓棿鍐呭鍖?              Expanded(
                child: GestureDetector(
                  onTap: () => _copyMessage(context, message),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message.content,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // 鍙充晶鎿嶄綔鎸夐挳
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 鍒嗕韩鎸夐挳锛堟湁闄勪欢鏃舵樉绀猴級
                  if (hasImages || hasFiles)
                    GestureDetector(
                      onTap: () => _shareAttachments(context, message),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: Colors.green[600],
                        ),
                      ),
                    ),
                  // 澶嶅埗鏂囧瓧鎸夐挳
                  GestureDetector(
                    onTap: () => _copyTextOnly(context, message),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.content_copy_rounded,
                        size: 18,
                        color: Colors.orange[600],
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
                icon: Icons.add_circle_outline_rounded,
                title: '鏂板缓璇濇湳',
                subtitle: '鍒涘缓鏂板洖澶?,
                color: Colors.green,
                onTap: () => _navigateToEditor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.image_outlined,
                title: '娣诲姞鍥剧墖',
                subtitle: '閫夋嫨鍙戦€?,
                color: Colors.orange,
                onTap: () => _pickAndShareImage(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.attach_file_outlined,
                title: '娣诲姞鏂囦欢',
                subtitle: '閫夋嫨鍙戦€?,
                color: Colors.purple,
                onTap: () => _pickAndShareFile(context),
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
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: color.withOpacity(0.6), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 澶嶅埗璇濇湳鏂囨湰鍒板壀璐存澘
  void _copyMessage(BuildContext context, Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    _showSuccessSnackBar(context, '鉁?宸插鍒讹細${message.title}');
  }

  /// 鍙鍒舵枃鏈紙鍙充晶鎸夐挳锛?  void _copyTextOnly(BuildContext context, Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    _showSuccessSnackBar(context, '馃搵 鏂囨湰宸插鍒?);
  }

  /// 鍒嗕韩璇濇湳锛堥暱鎸夛級
  void _shareMessage(BuildContext context, Message message) {
    final text = '${message.title}\n\n${message.content}';
    Share.share(text, subject: message.title);
  }

  /// 鍒嗕韩闄勪欢锛堝浘鐗?鏂囦欢锛?  void _shareAttachments(BuildContext context, Message message) async {
    try {
      final List<XFile> attachments = [];
      
      // 娣诲姞鍥剧墖
      for (final path in message.images) {
        if (path.isNotEmpty) {
          final file = File(path);
          if (file.existsSync()) {
            attachments.add(XFile(path));
          }
        }
      }
      
      // 娣诲姞鏂囦欢
      for (final path in message.files) {
        if (path.isNotEmpty) {
          final file = File(path);
          if (file.existsSync()) {
            attachments.add(XFile(path));
          }
        }
      }
      
      if (attachments.isEmpty) {
        // 娌℃湁鏈夋晥闄勪欢锛屽垎浜枃鏈?        Share.share(message.content, subject: message.title);
        return;
      }
      
      // 鍒嗕韩闄勪欢 + 鏂囨湰
      await Share.shareXFiles(
        attachments,
        text: message.content,
        subject: message.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('鍒嗕韩澶辫触锛?e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 璺宠浆鍒扮紪杈戝櫒鏂板缓璇濇湳
  void _navigateToEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditorScreen(),
      ),
    ).then((_) {
      // 杩斿洖鍚庡埛鏂版暟鎹?      if (mounted) {
        context.read<MessageProvider>().loadMessages();
      }
    });
  }

  /// 閫夋嫨鍥剧墖骞跺垎浜?  Future<void> _pickAndShareImage(BuildContext context) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      await Share.shareXFiles([image], subject: '鍒嗕韩鍥剧墖');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('閫夋嫨鍥剧墖澶辫触锛?e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 閫夋嫨鏂囦欢骞跺垎浜?  Future<void> _pickAndShareFile(BuildContext context) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      
      if (result == null || result.files.isEmpty) return;
      
      final file = result.files.first;
      final xfile = XFile(file.path!);
      
      await Share.shareXFiles([xfile], subject: '鍒嗕韩鏂囦欢锛?{file.name}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('閫夋嫨鏂囦欢澶辫触锛?e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 鏄剧ず鎴愬姛鎻愮ず
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}
