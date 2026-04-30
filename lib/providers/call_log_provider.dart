import 'package:flutter/foundation.dart';
import 'package:quick_reply_app/models/call_record.dart';
import 'package:quick_reply_app/services/database_service.dart';
import 'package:quick_reply_app/services/call_log_service.dart';

/// CallLog Provider - Manages call records state
class CallLogProvider extends ChangeNotifier {
  List<CallRecord> _callLogs = [];  // 本App记录的通话
  bool _isLoading = false;
  
  // 手机通话记录
  List<DeviceCallLog> _deviceCallLogs = [];
  bool _deviceLogsLoading = false;

  List<CallRecord> get callLogs => _callLogs;
  bool get isLoading => _isLoading;
  
  List<DeviceCallLog> get deviceCallLogs => _deviceCallLogs;
  bool get deviceLogsLoading => _deviceLogsLoading;
  
  /// 读取手机通话记录
  Future<void> loadDeviceCallLogs() async {
    _deviceLogsLoading = true;
    notifyListeners();
    try {
      _deviceCallLogs = await CallLogService.readCallLogs();
    } catch (e) {
      debugPrint('loadDeviceCallLogs error: $e');
      _deviceCallLogs = [];
    }
    _deviceLogsLoading = false;
    notifyListeners();
  }
  
  /// 今日手机通话统计
  Map<String, int> getDeviceTodayStats() {
    return DeviceCallLog.getTodayStats(_deviceCallLogs);
  }
  
  /// 今日重复号码统计
  Map<String, int> getDeviceRepeatStats() {
    final today = DeviceCallLog.getTodayLogs(_deviceCallLogs);
    final total = today.length;
    final unique = DeviceCallLog.getUniqueNumbers(today).length;
    final repeat = total - unique;
    return {
      'total': total,
      'unique': unique,
      'repeat': repeat,
    };
  }
  
  /// 获取重复次数最多的号码
  List<MapEntry<String, int>> getTopRepeatNumbers({int limit = 10}) {
    final today = DeviceCallLog.getTodayLogs(_deviceCallLogs);
    final grouped = DeviceCallLog.groupByNumber(today);
    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return sorted.take(limit).map((e) => MapEntry(e.key, e.value.length)).toList();
  }

  Future<void> loadCallLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      _callLogs = await DatabaseService().getCallLogs();
    } catch (e) {
      debugPrint('loadCallLogs error: $e');
      _callLogs = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCallLog(CallRecord record) async {
    try {
      await DatabaseService().insertCallLog(record);
      await loadCallLogs();
    } catch (e) {
      debugPrint('addCallLog error: $e');
    }
  }

  Future<void> updateCallLog(CallRecord record) async {
    try {
      await DatabaseService().updateCallLog(record);
      await loadCallLogs();
    } catch (e) {
      debugPrint('updateCallLog error: $e');
    }
  }

  Future<void> deleteCallLog(int id) async {
    try {
      await DatabaseService().deleteCallLog(id);
      await loadCallLogs();
    } catch (e) {
      debugPrint('deleteCallLog error: $e');
    }
  }

  List<CallRecord> getTodayCallLogs() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _callLogs.where((log) => log.startTime.isAfter(todayStart)).toList();
  }

  Map<String, int> getTodayStats() {
    final todayLogs = getTodayCallLogs();
    return {
      'total': todayLogs.length,
      'over30s': todayLogs.where((log) => log.isLongerThan(30)).length,
      'over50s': todayLogs.where((log) => log.isLongerThan(50)).length,
      'over1min': todayLogs.where((log) => log.isLongerThan(60)).length,
      'over2min': todayLogs.where((log) => log.isLongerThan(120)).length,
    };
  }

  List<CallRecord> getRecentCallLogs({int limit = 10}) {
    final sorted = List<CallRecord>.from(_callLogs)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted.take(limit).toList();
  }
}
