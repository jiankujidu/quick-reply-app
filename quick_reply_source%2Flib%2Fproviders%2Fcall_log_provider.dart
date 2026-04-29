import 'package:flutter/foundation.dart';
import 'package:quick_reply_app/models/call_record.dart';
import 'package:quick_reply_app/services/database_service.dart';

/// 閫氳瘽璁板綍鐘舵€佺鐞?class CallLogProvider extends ChangeNotifier {
  List<CallRecord> _callLogs = [];
  bool _isLoading = false;

  List<CallRecord> get callLogs => _callLogs;
  bool get isLoading => _isLoading;

  /// 鍔犺浇鎵€鏈夐€氳瘽璁板綍
  Future<void> loadCallLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _callLogs = await DatabaseService.instance.getCallLogs();
    } catch (e) {
      debugPrint('鍔犺浇閫氳瘽璁板綍澶辫触: $e');
      _callLogs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 娣诲姞閫氳瘽璁板綍
  Future<void> addCallLog(CallRecord record) async {
    try {
      await DatabaseService.instance.insertCallLog(record);
      await loadCallLogs();
    } catch (e) {
      debugPrint('娣诲姞閫氳瘽璁板綍澶辫触: $e');
    }
  }

  /// 鏇存柊閫氳瘽璁板綍
  Future<void> updateCallLog(CallRecord record) async {
    try {
      await DatabaseService.instance.updateCallLog(record);
      await loadCallLogs();
    } catch (e) {
      debugPrint('鏇存柊閫氳瘽璁板綍澶辫触: $e');
    }
  }

  /// 鍒犻櫎閫氳瘽璁板綍
  Future<void> deleteCallLog(int id) async {
    try {
      await DatabaseService.instance.deleteCallLog(id);
      await loadCallLogs();
    } catch (e) {
      debugPrint('鍒犻櫎閫氳瘽璁板綍澶辫触: $e');
    }
  }

  /// 鑾峰彇浠婃棩閫氳瘽璁板綍
  List<CallRecord> getTodayCallLogs() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _callLogs.where((log) => log.startTime.isAfter(todayStart)).toList();
  }

  /// 鑾峰彇浠婃棩缁熻鏁版嵁
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

  /// 鑾峰彇鏈€杩慛鏉￠€氳瘽璁板綍
  List<CallRecord> getRecentCallLogs({int limit = 10}) {
    final sorted = List<CallRecord>.from(_callLogs)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted.take(limit).toList();
  }
}
