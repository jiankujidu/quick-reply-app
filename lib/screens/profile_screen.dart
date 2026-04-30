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
        title: const Text('👤 我的'),
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
                user?.name.substring(0, 1) ?? '用',
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
                  user?.name ?? '用户',
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
            '📝',
            '${provider.messages.length}',
            '话术总数',
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🏢',
            '${provider.messages.where((m) => m.level == 'company').length}',
            '公司级',
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '👤',
            '${provider.messages.where((m) => m.level == 'private').length}',
            '私人',
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
          '设置',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        // 悬浮窗开关 - 核心功能
        _buildOverlaySwitch(context, messageProvider),
        // 备份与还原
        _buildSettingsItem(
          context: context,
          icon: Icons.upload_file,
          title: '📤 导出数据',
          subtitle: '备份话术、分类、标签',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _exportData(context),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.download,
          title: '📥 导入数据',
          subtitle: '从备份文件恢复',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _importData(context),
        ),
        _buildSettingsItem(
          context: context,
          icon: Icons.table_chart,
          title: '📊 导出客户Excel',
          subtitle: '导出所有客户画像数据',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _exportCustomersExcel(context),
        ),
        const SizedBox(height: 12),
        // 云端同步、消息提醒、深色模式 - 暂未实现，已隐藏
        _buildSettingsItem(
          context: context,
          icon: Icons.info,
          title: '关于快回复',
          subtitle: '版本 2.3.0',
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
      title: '🪟 悬浮窗',
      subtitle: _overlayEnabled ? '已开启 - 点击气泡查看话术' : '开启后可快速发送话术',
      trailing: Switch(
        value: _overlayEnabled,
        onChanged: (value) async {
          if (value) {
            // 开启悬浮窗
            final hasPermission = await OverlayService.checkPermission();
            if (!hasPermission) {
              final granted = await OverlayService.requestPermission();
              if (!granted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ 请在设置中授予悬浮窗权限'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }
              // 用户刚授权，等一下再检查
              await Future.delayed(const Duration(milliseconds: 500));
            }

            // 准备话术数据（含图片和文件）
            // 获取应用文档目录，将相对路径转为绝对路径
            final appDir = await getApplicationDocumentsDirectory();
            final messages = await Future.wait(messageProvider.messages.map((m) async {
              // 解析图片路径，转为绝对路径
              List<String> absoluteImages = [];
              for (var path in m.images) {
                if (path.isNotEmpty) {
                  if (!path.startsWith('/')) {
                    // 相对路径，转为绝对路径
                    absoluteImages.add('${appDir.path}/$path');
                  } else {
                    absoluteImages.add(path);
                  }
                }
              }
              // 解析文件路径，转为绝对路径
              List<String> absoluteFiles = [];
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

            // 启动悬浮气泡
            final success = await OverlayService.startFloatingBubble(messages);
            
            if (success && context.mounted) {
              setState(() {
                _overlayEnabled = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ 悬浮窗已开启！在任意应用点击气泡即可使用'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ 启动失败，请检查权限'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            // 关闭悬浮窗
            await OverlayService.stopFloatingBubble();
            setState(() {
              _overlayEnabled = false;
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ℹ️ 悬浮窗已关闭')),
              );
            }
          }
        },
      ),
    );
  }

  /// 导出数据到ZIP并分享
  Future<void> _exportData(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('正在打包备份...')]),
        ),
      );

      final db = DatabaseService();
      final zipPath = await db.exportZipBackup();
      debugPrint('[导出] ZIP路径: $zipPath');
      debugPrint('[导出] 文件存在: ${await File(zipPath).exists()}');
      debugPrint('[导出] 文件大小: ${await File(zipPath).length()} bytes');

      if (context.mounted) Navigator.pop(context);

      // 先复制到Downloads目录
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
          final destPath = '${downloadsDir.path}/快回复备份_$timestamp.zip';
          await File(zipPath).copy(destPath);
          debugPrint('[导出] 复制到: $destPath');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 备份已保存到:\n$destPath'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // 如果无法保存到Downloads，尝试分享
      await Share.shareXFiles(
        [XFile(zipPath)],
        subject: '快回复备份',
      );
    } catch (e, stackTrace) {
      debugPrint('[导出] 错误: $e');
      debugPrint('[导出] 堆栈: $stackTrace');
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 导入ZIP数据
  Future<void> _importData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 确认导入'),
        content: const Text(
          '导入会覆盖当前所有数据！\n\n请确保已备份当前数据再操作。',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认导入', style: TextStyle(color: Colors.white)),
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
        debugPrint('[导入] 用户取消选择');
        return;
      }
      final zipPath = result.files.first.path!;
      debugPrint('[导入] 选择的文件: $zipPath');
      
      // 检查文件是否存在
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        throw Exception('文件不存在: $zipPath');
      }
      final zipSize = await zipFile.length();
      debugPrint('[导入] 文件大小: $zipSize bytes');
      if (zipSize < 100) {
        throw Exception('文件太小，可能已损坏（${zipSize}字节）');
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
            content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('正在导入数据...')]),
          ),
        );
      }

      final db = DatabaseService();
      try {
        await db.importZipBackup(zipPath);
        debugPrint('[导入] 导入完成');
      } catch (e) {
        throw Exception('解压失败: $e\n请确认是快回复导出的备份文件');
      }

      // 刷新 MessageProvider
      if (context.mounted) {
        final messageProvider = context.read<MessageProvider>();
        await messageProvider.loadMessages();
      }

      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 导入成功！'), backgroundColor: Colors.green),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[导入] 错误: $e');
      debugPrint('[导入] 堆栈: $stackTrace');
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
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
            child: const Center(child: Text('快', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          const Text('快回复'),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: 2.4.0', style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Text('快回复是一款客服话术管理工具，帮助客服人员快速回复客户消息。', style: TextStyle(fontSize: 13, color: Colors.grey)),
            SizedBox(height: 16),
            Text('功能特点:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('• 话术分类管理', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• 图片和文件附件', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• 悬浮窗快速发送', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• 客户画像管理', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• 数据备份恢复', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• Excel导出', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
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

      // 尝试分享文件
      try {
        await Share.shareXFiles([XFile(filePath)], text: '客户画像数据');
      } catch (e) {
        // 分享失败，显示路径
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 已导出到: $filePath'),
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
            content: Text('导出失败: $e'),
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
        return '👑 管理员';
      case 'leader':
        return '👥 组长';
      default:
        return '👤 员工';
    }
  }
}
