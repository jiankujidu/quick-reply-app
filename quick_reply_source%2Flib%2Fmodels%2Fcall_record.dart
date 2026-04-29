/// 閫氳瘽璁板綍妯″瀷
class CallRecord {
  final int? id;
  final String phoneNumber;
  final String contactName;
  final int durationSeconds; // 閫氳瘽鏃堕暱锛堢锛?  final DateTime startTime;
  final DateTime endTime;
  final String callType; // 'outgoing' | 'incoming' | 'missed'
  final String? notes; // 澶囨敞

  CallRecord({
    this.id,
    required this.phoneNumber,
    this.contactName = '',
    required this.durationSeconds,
    required this.startTime,
    required this.endTime,
    this.callType = 'outgoing',
    this.notes,
  });

  /// 鏍煎紡鍖栨椂闀挎樉绀?  String get durationFormatted {
    if (durationSeconds < 60) {
      return '$durationSeconds绉?;
    }
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes鍒?{seconds}绉?;
  }

  /// 鏄惁瓒呰繃鎸囧畾绉掓暟
  bool isLongerThan(int seconds) {
    return durationSeconds >= seconds;
  }

  /// 浠庢暟鎹簱Map鍒涘缓
  factory CallRecord.fromMap(Map<String, dynamic> map) {
    return CallRecord(
      id: map['id'] as int?,
      phoneNumber: map['phone_number'] as String? ?? '',
      contactName: map['contact_name'] as String? ?? '',
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      callType: map['call_type'] as String? ?? 'outgoing',
      notes: map['notes'] as String?,
    );
  }

  /// 杞崲涓烘暟鎹簱Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'phone_number': phoneNumber,
      'contact_name': contactName,
      'duration_seconds': durationSeconds,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'call_type': callType,
      'notes': notes,
    };
  }

  /// 澶嶅埗骞朵慨鏀?  CallRecord copyWith({
    int? id,
    String? phoneNumber,
    String? contactName,
    int? durationSeconds,
    DateTime? startTime,
    DateTime? endTime,
    String? callType,
    String? notes,
  }) {
    return CallRecord(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      callType: callType ?? this.callType,
      notes: notes ?? this.notes,
    );
  }
}
