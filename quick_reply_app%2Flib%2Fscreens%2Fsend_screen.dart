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
    // 鍔犺浇閫氳瘽璁板綍
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
        title: const Text('馃摓 鎷ㄦ墦鐢佃瘽'),
        actions: [
          IconButton(
            icon: Icon(_isDialPadVisible ? Icons.history : Icons.dialpad),
            onPressed: () {
              setState(() {
                _isDialPadVisible = !_isDialPadVisible;
              });
            },
            tooltip: _isDialPadVisible ? '閫氳瘽璁板綍' : '鎷ㄥ彿鐩?,
          ),
        ],
      ),
      body: Column(
        children: [
          // 浠婃棩缁熻鍗＄墖
          _buildTodayStatsCard(),
          
          // 鎵嬫満閫氳瘽缁熻锛堥噸澶?涓嶉噸澶嶅彿鐮佺粺璁★級
          _buildPhoneCallStatsCard(),
          
          // 涓诲唴瀹瑰尯锛氭嫧鍙风洏 鎴?閫氳瘽璁板綍
          Expanded(
            child: _isDialPadVisible
                ? _buildDialPad()
                : _buildCallHistory(),
          ),
        ],
      ),
    );
  }

  /// 浠婃棩缁熻鍗＄墖
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
                    '浠婃棩閫氳瘽缁熻',
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
                  _buildStatItem('鎬昏', stats['total'] ?? 0),
                  _buildStatItem('鈮?0绉?, stats['over30s'] ?? 0),
                  _buildStatItem('鈮?0绉?, stats['over50s'] ?? 0),
                  _buildStatItem('鈮?鍒嗛挓', stats['over1min'] ?? 0),
                  _buildStatItem('鈮?鍒嗛挓', stats['over2min'] ?? 0),
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

  /// 鎵嬫満閫氳瘽缁熻鍗＄墖锛堥噸澶?涓嶉噸澶嶅彿鐮侊級
  Widget _buildPhoneCallStatsCard() {
    return Consumer<CallLogProvider>(
      builder: (context, provider, _) {
        // 濡傛灉杩樻病鍔犺浇鎵嬫満閫氳瘽璁板綍锛屾樉绀哄姞杞芥寜閽?
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
                        '馃摫 鐐瑰嚮璇诲彇鎵嬫満閫氳瘽璁板綍',
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
                    '浠婃棩鎵嬫満閫氳瘽锛堥噸澶嶅彿鐮佺粺璁★級',
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
                    label: Text('鍒锋柊'),
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
                  _buildPhoneStatItem('鎬婚€氳瘽', total, Colors.blue),
                  _buildPhoneStatItem('涓嶉噸澶?, unique, Colors.green),
                  _buildPhoneStatItem('閲嶅娆℃暟', repeat, Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              // 鏄剧ず閲嶅娆℃暟鏈€澶氱殑鍙风爜
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
          '馃攣 閲嶅鎷ㄦ墦鏈€澶氱殑鍙风爜',
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
                    '$count娆?,
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

  /// 鎷ㄥ彿鐩?
  Widget _buildDialPad() {
    return Column(
      children: [
        // 鍙风爜鏄剧ず鍖?
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
                  hintText: '杈撳叆鎴栨嫧鎵撶數璇濆彿鐮?,
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
        
        // 鎷ㄥ彿鎸夐挳
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Row(
            children: [
              // 鎷ㄦ墦鐢佃瘽鎸夐挳
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
                        '鎷ㄦ墦',
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
        
        // 鎷ㄥ彿閿洏
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
        // 瑙﹁鍙嶉
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

  /// 閫氳瘽璁板綍鍒楄〃
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
                  '鏆傛棤閫氳瘽璁板綍',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '鎷ㄦ墦鐢佃瘽鍚庝細鑷姩璁板綍',
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
                  '\$timeStr 路 \${call.durationFormatted}',
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
              tooltip: '鎷ㄦ墦',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              onPressed: () => _deleteCallRecord(call),
              tooltip: '鍒犻櫎',
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
      _showSnackBar('璇疯緭鍏ユ湁鏁堢數璇濆彿鐮?, isError: true);
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
        _showSnackBar('鏃犳硶鎷ㄦ墦鐢佃瘽', isError: true);
      }
    } catch (e) {
      _showSnackBar('鎷ㄦ墦澶辫触锛歕$e', isError: true);
    }
  }

  void _showRecordCallDialog(String phoneNumber, DateTime startTime) {
    final durationController = TextEditingController();
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('馃摓 閫氳瘽璁板綍'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('鐢佃瘽鍙风爜锛歕$phoneNumber', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '閫氳瘽鏃堕暱锛堢锛?,
                hintText: '濡傦細60',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '澶囨敞锛堥€夊～锛?,
                hintText: '閫氳瘽鍐呭鎽樿...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('鍙栨秷')),
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
              _showSnackBar('閫氳瘽璁板綍宸蹭繚瀛?);
              setState(() { _isDialPadVisible = false; });
            },
            child: Text('淇濆瓨'),
          ),
        ],
      ),
    );
  }

  void _deleteCallRecord(CallRecord call) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('鍒犻櫎閫氳瘽璁板綍'),
        content: Text('纭畾瑕佸垹闄よ繖鏉￠€氳瘽璁板綍鍚楋紵'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('鍙栨秷')),
          ElevatedButton(
            onPressed: () {
              if (call.id != null) context.read<CallLogProvider>().deleteCallLog(call.id!);
              Navigator.pop(ctx);
              _showSnackBar('閫氳瘽璁板綍宸插垹闄?);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('鍒犻櫎', style: TextStyle(color: Colors.white)),
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
