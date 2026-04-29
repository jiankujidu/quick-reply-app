import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quick_reply_app/providers/auth_provider.dart';
import 'package:quick_reply_app/providers/message_provider.dart';
import 'package:quick_reply_app/services/database_service.dart';
import 'package:quick_reply_app/services/overlay_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _overlayEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkOverlayStatus();
  }

  Future<void> _checkOverlayStatus() async {
    final hasPermission = await OverlayService.checkPermission();
    setState(() {
      _overlayEnabled = hasPermission && OverlayService.isBubbleActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messageProvider = context.watch<MessageProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('馃懁 鎴戠殑'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(user),
            const SizedBox(height: 24),
            _buildStatsGrid(messageProvider),
            const SizedBox(height: 24),
            _buildSettingsList(context, messageProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user?.name.substring(0, 1) ?? '鐢?,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '鐢ㄦ埛',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleName(user?.role ?? 'member'),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(MessageProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '馃摑',
            '${provider.messages.length}',
            '璇濇湳鎬绘暟',
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '馃彚',
            '${provider.messages.where((m) => m.level == 'company').length}',
            '鍏徃绾?,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '馃懁',
            '${provider.messages.where((m) => m.level == 'private').length}',
            '绉佷汉',
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, MessageProvider messageProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '璁剧疆',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        // 鎮诞绐楀紑鍏?- 鏍稿績鍔熻兘
        _buildOverlaySwitch(context, messageProvider),
        // 澶囦唤涓庤繕鍘?        _buildSettingsItem(
          context: context,
          icon: Icons.upload_file,
          title: '馃摛 瀵煎嚭鏁版嵁',
          subtitle: '澶囦唤璇濇湳銆佸垎绫汇€佹爣绛?,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _exportData(context),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.download,
          title: '馃摜 瀵煎叆鏁版嵁',
          subtitle: '浠庡浠芥枃浠舵仮澶?,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _importData(context),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.table_chart,
          title: '馃搳 瀵煎嚭瀹㈡埛Excel',
          subtitle: '瀵煎嚭鎵€鏈夊鎴风敾鍍忔暟鎹?,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _exportCustomersExcel(context),
        ),
        const SizedBox(height: 12),
        // 浜戠鍚屾銆佹秷鎭彁閱掋€佹繁鑹叉ā寮?- 鏆傛湭瀹炵幇锛屽凡闅愯棌
        _buildSettingsItem(
          context: context,
          icon: Icons.info,
          title: '鍏充簬蹇洖澶?,
          subtitle: '鐗堟湰 2.3.0',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  Widget _buildOverlaySwitch(BuildContext context, MessageProvider messageProvider) {
    return _buildSettingsItem(
      context: context,
      icon: Icons.picture_in_picture,
      title: '馃獰 鎮诞绐?,
      subtitle: _overlayEnabled ? '宸插紑鍚?- 鐐瑰嚮姘旀场鏌ョ湅璇濇湳' : '寮€鍚悗鍙揩閫熷彂閫佽瘽鏈?,
      trailing: Switch(
        value: _overlayEnabled,
        onChanged: (value) async {
          if (value) {
            // 寮€鍚偓娴獥
            final hasPermission = await OverlayService.checkPermission();
            if (!hasPermission) {
              final granted = await OverlayService.requestPermission();
              if (!granted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('鈿狅笍 璇峰湪璁剧疆涓巿浜堟偓娴獥鏉冮檺'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              // 鐢ㄦ埛鍒氭巿鏉冿紝绛変竴涓嬪啀妫€鏌?              await Future.delayed(const Duration(milliseconds: 500));
            }

            // 鍑嗗璇濇湳鏁版嵁锛堝惈鍥剧墖鍜屾枃浠讹級
            // 鑾峰彇搴旂敤鏂囨。鐩綍锛屽皢鐩稿璺緞杞负缁濆璺緞
            final appDir = await getApplicationDocumentsDirectory();
            final messages = await Future.wait(messageProvider.messages.map((m) async {
              // 瑙ｆ瀽鍥剧墖璺緞锛岃浆涓虹粷瀵硅矾寰?              List<String> absoluteImages = [];
              for (var path in m.images) {
                if (path.isNotEmpty) {
                  if (!path.startsWith('/')) {
                    // 鐩稿璺緞锛岃浆涓虹粷瀵硅矾寰?                    absoluteImages.add('${appDir.path}/$path');
                  } else {
                    absoluteImages.add(path);
                  }
                }
              }
              // 瑙ｆ瀽鏂囦欢璺緞锛岃浆涓虹粷瀵硅矾寰?              List<String> absoluteFiles = [];
              for (var path in m.files) {
                if (path.isNotEmpty) {
                  if (!path.startsWith('/')) {
                    absoluteFiles.add('${appDir.path}/$path');
                  } else {
                    absoluteFiles.add(path);
                  }
                }
              }
              return {
                'id': m.id,
                'title': m.title,
                'content': m.content,
                'category': m.category ?? '',
                'subcategory': m.subcategory ?? '',
                'images': absoluteImages.join(','),
                'files': absoluteFiles.join(','),
              };
            }).toList());

            // 鍚姩鎮诞姘旀场
            final success = await OverlayService.startFloatingBubble(messages);
            
            if (success && context.mounted) {
              setState(() {
                _overlayEnabled = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('鉁?鎮诞绐楀凡寮€鍚紒鍦ㄤ换鎰忓簲鐢ㄧ偣鍑绘皵娉″嵆鍙娇鐢?),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('鉂?鍚姩澶辫触锛岃妫€鏌ユ潈闄?),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            // 鍏抽棴鎮诞绐?            await OverlayService.stopFloatingBubble();
            setState(() {
              _overlayEnabled = false;
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('鈩癸笍 鎮诞绐楀凡鍏抽棴')),
              );
            }
          }
        },
      ),
    );
  }

  /// 瀵煎嚭鏁版嵁鍒癦IP骞跺垎浜?  Future<void> _exportData(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('姝ｅ湪鎵撳寘澶囦唤...')]),
        ),
      );

      final db = DatabaseService();
      final zipPath = await db.exportZipBackup();
      debugPrint('[瀵煎嚭] ZIP璺緞: $zipPath');
      debugPrint('[瀵煎嚭] 鏂囦欢瀛樺湪: ${await File(zipPath).exists()}');
      debugPrint('[瀵煎嚭] 鏂囦欢澶у皬: ${await File(zipPath).length()} bytes');

      if (context.mounted) Navigator.pop(context);

      // 鍏堝鍒跺埌Downloads鐩綍
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
          final destPath = '${downloadsDir.path}/蹇洖澶嶅浠絖$timestamp.zip';
          await File(zipPath).copy(destPath);
          debugPrint('[瀵煎嚭] 澶嶅埗鍒? $destPath');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('鉁?澶囦唤宸蹭繚瀛樺埌:\n$destPath'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // 濡傛灉鏃犳硶淇濆瓨鍒癉ownloads锛屽皾璇曞垎浜?      await Share.shareXFiles(
        [XFile(zipPath)],
        subject: '蹇洖澶嶅浠?,
      );
    } catch (e, stackTrace) {
      debugPrint('[瀵煎嚭] 閿欒: $e');
      debugPrint('[瀵煎嚭] 鍫嗘爤: $stackTrace');
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('瀵煎嚭澶辫触: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 瀵煎叆ZIP鏁版嵁
  Future<void> _importData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('鈿狅笍 纭瀵煎叆'),
        content: const Text(
          '瀵煎叆浼氳鐩栧綋鍓嶆墍鏈夋暟鎹紒\n\n璇风‘淇濆凡澶囦唤褰撳墠鏁版嵁鍐嶆搷浣溿€?,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('鍙栨秷')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('纭瀵煎叆', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.isEmpty) {
        debugPrint('[瀵煎叆] 鐢ㄦ埛鍙栨秷閫夋嫨');
        return;
      }
      final zipPath = result.files.first.path!;
      debugPrint('[瀵煎叆] 閫夋嫨鐨勬枃浠? $zipPath');
      
      // 妫€鏌ユ枃浠舵槸鍚﹀瓨鍦?      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('鏂囦欢涓嶅瓨鍦? $zipPath');
      }
      final zipSize = await zipFile.length();
      debugPrint('[瀵煎叆] 鏂囦欢澶у皬: $zipSize bytes');
      if (zipSize < 100) {
        throw Exception('鏂囦欢澶皬锛屽彲鑳藉凡鎹熷潖锛?{zipSize}瀛楄妭锛?);
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
            content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('姝ｅ湪瀵煎叆鏁版嵁...')]),
          ),
        );
      }

      final db = DatabaseService();
      try {
        await db.importZipBackup(zipPath);
        debugPrint('[瀵煎叆] 瀵煎叆瀹屾垚');
      } catch (e) {
        throw Exception('瑙ｅ帇澶辫触: $e\n璇风‘璁ゆ槸蹇洖澶嶅鍑虹殑澶囦唤鏂囦欢');
      }

      // 鍒锋柊 MessageProvider
      if (context.mounted) {
        final messageProvider = context.read<MessageProvider>();
        await messageProvider.loadMessages();
      }

      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('鉁?瀵煎叆鎴愬姛锛?), backgroundColor: Colors.green),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[瀵煎叆] 閿欒: $e');
      debugPrint('[瀵煎叆] 鍫嗘爤: $stackTrace');
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('瀵煎叆澶辫触: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('蹇?, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          const Text('蹇洖澶?),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('鐗堟湰: 2.4.0', style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text('蹇洖澶嶆槸涓€娆惧鏈嶈瘽鏈鐞嗗伐鍏凤紝甯姪瀹㈡湇浜哄憳蹇€熷洖澶嶅鎴锋秷鎭€?, style: TextStyle(fontSize: 13, color: Colors.grey)),
            SizedBox(height: 16),
            Text('鍔熻兘鐗圭偣:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('鈥?璇濇湳鍒嗙被绠＄悊', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('鈥?鍥剧墖鍜屾枃浠堕檮浠?, style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('鈥?鎮诞绐楀揩閫熷彂閫?, style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('鈥?瀹㈡埛鐢诲儚绠＄悊', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('鈥?鏁版嵁澶囦唤鎭㈠', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('鈥?Excel瀵煎嚭', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('纭畾')),
        ],
      ),
    );
  }

  Future<void> _exportCustomersExcel(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final db = DatabaseService();
      final filePath = await db.exportCustomersToExcel();

      if (context.mounted) Navigator.pop(context);

      // 灏濊瘯鍒嗕韩鏂囦欢
      try {
        await Share.shareXFiles([XFile(filePath)], text: '瀹㈡埛鐢诲儚鏁版嵁');
      } catch (e) {
        // 鍒嗕韩澶辫触锛屾樉绀鸿矾寰?        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('鉁?宸插鍑哄埌: $filePath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('瀵煎嚭澶辫触: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return '馃憫 绠＄悊鍛?;
      case 'leader':
        return '馃懃 缁勯暱';
      default:
        return '馃懁 鍛樺伐';
    }
  }
}
