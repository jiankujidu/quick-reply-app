import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            _buildSettingsList(context),
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
            decoration: BoxDecoration(
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

  Widget _buildSettingsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '璁剧疆',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        _buildSettingsItem(
          icon: Icons.sync,
          title: '浜戠鍚屾',
          subtitle: '涓婃鍚屾: 鍒氬垰',
          trailing: Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
        _buildSettingsItem(
          icon: Icons.notifications,
          title: '娑堟伅鎻愰啋',
          subtitle: '寮€鍚柊娑堟伅閫氱煡',
          trailing: Switch(
            value: true,
            onChanged: (value) {},
          ),
        ),
        _buildSettingsItem(
          icon: Icons.dark_mode,
          title: '娣辫壊妯″紡',
          subtitle: '璺熼殢绯荤粺璁剧疆',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.info,
          title: '鍏充簬鎴戜滑',
          subtitle: '鐗堟湰 1.0.0',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
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
