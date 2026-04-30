import 'package:flutter/services.dart';

/// 手机通话记录服务 - 通过原生层读取系统通话记录
class CallLogService {
  static const _channel = MethodChannel('app.quickreply/overlay');

  /// 读取手机通话记录
  static Future<List<DeviceCallLog>> readCallLogs() async {
    try {
      final result = await _channel.invokeMethod('readCallLogs');
      if (result == null) return [];
      
      final list = result as List<dynamic>;
      return list.map((item) => DeviceCallLog.fromMap(item as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      print('readCallLogs error: ${e.message}');
      return [];
    }
  }

  /// 是否有权限
  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod('checkPermission');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// 请求权限（跳转设置页）
  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }
}

/// 通话记录数据模型（从手机读取）
class DeviceCallLog {
  final String phoneNumber;
  final String contactName;
  final int startTime; // 毫秒时间戳
  final int durationSeconds;
  final String callType; // incoming, outgoing, missed

  DeviceCallLog({
    required this.phoneNumber,
    required this.contactName,
    required this.startTime,
    required this.durationSeconds,
    required this.callType,
  });

  factory DeviceCallLog.fromMap(Map<dynamic, dynamic> map) {
    return DeviceCallLog(
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      contactName: map['contactName']?.toString() ?? '',
      startTime: (map['startTime'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      callType: map['callType']?.toString() ?? 'unknown',
    );
  }

  DateTime get startDateTime => DateTime.fromMillisecondsSinceEpoch(startTime);

  /// 格式化时长显示
  String get durationFormatted {
    if (durationSeconds < 60) return '${durationSeconds}秒';
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    if (sec == 0) return '${min}分';
    return '${min}分${sec}秒';
  }

  /// 是否超过指定秒数
  bool isLongerThan(int seconds) => durationSeconds >= seconds;

  /// 获取去重后的号码集合
  static Set<String> getUniqueNumbers(List<DeviceCallLog> logs) {
    return logs.map((e) => e.phoneNumber).toSet();
  }

  /// 统计重复次数
  static int getRepeatCount(List<DeviceCallLog> logs, String phone) {
    return logs.where((e) => e.phoneNumber == phone).length;
  }

  /// 获取今日通话记录
  static List<DeviceCallLog> getTodayLogs(List<DeviceCallLog> logs) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    return logs.where((e) => e.startTime >= todayStart).toList();
  }

  /// 今日统计
  static Map<String, int> getTodayStats(List<DeviceCallLog> logs) {
    final today = getTodayLogs(logs);
    return {
      'total': today.length,
      'over30s': today.where((e) => e.isLongerThan(30)).length,
      'over50s': today.where((e) => e.isLongerThan(50)).length,
      'over1min': today.where((e) => e.isLongerThan(60)).length,
      'over2min': today.where((e) => e.isLongerThan(120)).length,
      'unique': getUniqueNumbers(today).length,
    };
  }

  /// 按号码分组统计
  static Map<String, List<DeviceCallLog>> groupByNumber(List<DeviceCallLog> logs) {
    final map = <String, List<DeviceCallLog>>{};
    for (final log in logs) {
      map.putIfAbsent(log.phoneNumber, () => []).add(log);
    }
    return map;
  }
}
