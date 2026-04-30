import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/call_log_provider.dart';
import '../models/call_record.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isDialPadVisible = true;

  @override
  void initState() {
    super.initState();
    // 加载通话记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallLogProvider>().loadCallLogs();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📞 拨打电话'),
        actions: [
          IconButton(
            icon: Icon(_isDialPadVisible ? Icons.history : Icons.dialpad),
            onPressed: () {
              setState(() {
                _isDialPadVisible = !_isDialPadVisible;
              });
            },
            tooltip: _isDialPadVisible ? '通话记录' : '拨号盘',
          ),
        ],
      ),
      body: Column(
        children: [
          // 今日统计卡片
          _buildTodayStatsCard(),
          
          // 手机通话统计（重复/不重复号码统计）
          _buildPhoneCallStatsCard(),
          
          // 主内容区：拨号盘 或 通话记录
          Expanded(
            child: _isDialPadVisible
                ? _buildDialPad()
                : _buildCallHistory(),
          ),
        ],
      ),
    );
  }

  /// 今日统计卡片
  Widget _buildTodayStatsCard() {
    return Consumer<CallLogProvider>(
      builder: (context, provider, _) {
        final stats = provider.getTodayStats();
        
        return Container(
          margin: const EdgeInsets.all(16),
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
                  Icon(Icons.bar_chart_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '今日通话统计',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('总计', stats['total'] ?? 0),
                  _buildStatItem('≥30秒', stats['over30s'] ?? 0),
                  _buildStatItem('≥50秒', stats['over50s'] ?? 0),
                  _buildStatItem('≥1分钟', stats['over1min'] ?? 0),
                  _buildStatItem('≥2分钟', stats['over2min'] ?? 0),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 手机通话统计卡片（重复/不重复号码）
  Widget _buildPhoneCallStatsCard() {
    return Consumer<CallLogProvider>(
      builder: (context, provider, _) {
        // 如果还没加载手机通话记录，显示加载按钮
        if (provider.deviceCallLogs.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                onTap: () async {
                  await provider.loadDeviceCallLogs();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_callback, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        '📱 点击读取手机通话记录',
                        style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        
        final repeatStats = provider.getDeviceRepeatStats();
        final total = repeatStats['total'] ?? 0;
        final unique = repeatStats['unique'] ?? 0;
        final repeat = repeatStats['repeat'] ?? 0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_callback, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '今日手机通话（重复号码统计）',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await provider.loadDeviceCallLogs();
                    },
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('刷新'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      padding: EdgeInsets.zero,
                      minimumSize: Size(60, 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPhoneStatItem('总通话', total, Colors.blue),
                  _buildPhoneStatItem('不重复', unique, Colors.green),
                  _buildPhoneStatItem('重复次数', repeat, Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              // 显示重复次数最多的号码
              _buildTopRepeatNumbers(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTopRepeatNumbers(CallLogProvider provider) {
    final topRepeat = provider.getTopRepeatNumbers(limit: 5);
    if (topRepeat.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 16),
        Text(
          '🔁 重复拨打最多的号码',
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...topRepeat.map((entry) {
          final phone = entry.key;
          final count = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.call, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    phone,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count次',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.call, size: 18, color: Colors.green[600]),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _makePhoneCall(phone),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 拨号盘
  Widget _buildDialPad() {
    return Column(
      children: [
        // 号码显示区
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '输入或拨打电话号码',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
                  border: InputBorder.none,
                  suffixIcon: _phoneController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.backspace_outlined, color: Colors.grey[600]),
                          onPressed: () {
                            if (_phoneController.text.isNotEmpty) {
                              _phoneController.text = _phoneController.text
                                  .substring(0, _phoneController.text.length - 1);
                              setState(() {});
                            }
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        
        // 拨号按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Row(
            children: [
              // 拨打电话按钮
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _phoneController.text.isNotEmpty
                      ? () => _makePhoneCall(_phoneController.text)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '拨打',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 拨号键盘
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            childAspectRatio: 1.5,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildDialButton('1', ''),
              _buildDialButton('2', 'ABC'),
              _buildDialButton('3', 'DEF'),
              _buildDialButton('4', 'GHI'),
              _buildDialButton('5', 'JKL'),
              _buildDialButton('6', 'MNO'),
              _buildDialButton('7', 'PQRS'),
              _buildDialButton('8', 'TUV'),
              _buildDialButton('9', 'WXYZ'),
              _buildDialButton('*', ''),
              _buildDialButton('0', '+'),
              _buildDialButton('#', ''),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDialButton(String number, String letters) {
    return InkWell(
      onTap: () {
        _phoneController.text += number;
        setState(() {});
        // 触觉反馈
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[100],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 通话记录列表
  Widget _buildCallHistory() {
    return Consumer<CallLogProvider>(
      builder: (context, provider, _) {
        final recentCalls = provider.getRecentCallLogs(limit: 50);
        
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (recentCalls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_callback_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  '暂无通话记录',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '拨打电话后会自动记录',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recentCalls.length,
          itemBuilder: (context, index) {
            final call = recentCalls[index];
            return _buildCallRecordItem(call);
          },
        );
      },
    );
  }

  Widget _buildCallRecordItem(CallRecord call) {
    final isToday = _isToday(call.startTime);
    final timeStr = isToday 
        ? _formatTime(call.startTime) 
        : _formatDate(call.startTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(
            call.callType == 'incoming' ? Icons.call_received : Icons.call_made,
            color: Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          call.contactName.isNotEmpty ? call.contactName : call.phoneNumber,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(call.phoneNumber, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '\$timeStr · \${call.durationFormatted}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.call, color: Colors.green[600]),
              onPressed: () => _makePhoneCall(call.phoneNumber),
              tooltip: '拨打',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              onPressed: () => _deleteCallRecord(call),
              tooltip: '删除',
            ),
          ],
        ),
        onTap: () => _makePhoneCall(call.phoneNumber),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+*#]'), '');
    if (cleanNumber.isEmpty) {
      _showSnackBar('请输入有效电话号码', isError: true);
      return;
    }
    final uri = Uri.parse('tel:\$cleanNumber');
    try {
      final startTime = DateTime.now();
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) {
          _showRecordCallDialog(phoneNumber, startTime);
        }
      } else {
        _showSnackBar('无法拨打电话', isError: true);
      }
    } catch (e) {
      _showSnackBar('拨打失败：\$e', isError: true);
    }
  }

  void _showRecordCallDialog(String phoneNumber, DateTime startTime) {
    final durationController = TextEditingController();
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('📞 通话记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('电话号码：\$phoneNumber', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '通话时长（秒）',
                hintText: '如：60',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '备注（选填）',
                hintText: '通话内容摘要...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          ElevatedButton(
            onPressed: () {
              final duration = int.tryParse(durationController.text) ?? 0;
              final endTime = DateTime.now();
              final record = CallRecord(
                phoneNumber: phoneNumber,
                durationSeconds: duration,
                startTime: startTime,
                endTime: endTime,
                callType: 'outgoing',
                notes: notesController.text.isNotEmpty ? notesController.text : null,
              );
              context.read<CallLogProvider>().addCallLog(record);
              Navigator.pop(ctx);
              _showSnackBar('通话记录已保存');
              setState(() { _isDialPadVisible = false; });
            },
            child: Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteCallRecord(CallRecord call) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除通话记录'),
        content: Text('确定要删除这条通话记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (call.id != null) context.read<CallLogProvider>().deleteCallLog(call.id!);
              Navigator.pop(ctx);
              _showSnackBar('通话记录已删除');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '\${date.month}/\${date.day} \${_formatTime(date)}';
  }
}
