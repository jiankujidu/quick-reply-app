class Message {
  final int? id;
  final String title;
  final String content;
  final List<String> images;
  final List<String> files;
  final List<String> tags;
  final String level; // company, group, private
  final String? groupId;
  final int userId;
  final String category; // 涓€绾у垎绫?  final String? subcategory; // 浜岀骇鍒嗙被
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    this.id,
    required this.title,
    required this.content,
    this.images = const [],
    this.files = const [],
    this.tags = const [],
    required this.level,
    this.groupId,
    required this.userId,
    this.category = '鏈垎绫?,
    this.subcategory,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'images': images.join(','),
      'files': files.join(','),
      'tags': tags.join(','),
      'level': level,
      'groupId': groupId,
      'userId': userId,
      'category': category,
      'subcategory': subcategory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    // 瀹夊叏瑙ｆ瀽 userId
    int userId;
    final rawUserId = map['userId'];
    if (rawUserId is int) {
      userId = rawUserId;
    } else if (rawUserId is String) {
      userId = int.tryParse(rawUserId) ?? 1;
    } else {
      userId = 1;
    }

    // 瀹夊叏瑙ｆ瀽骞舵爣鍑嗗寲 level
    String level = (map['level'] as String?) ?? 'private';
    if (level == '鍏徃绾? || level == '鍏徃') level = 'company';
    if (level == '灏忕粍绾? || level == '灏忕粍') level = 'group';
    if (level == '绉佷汉' || level == '鎴戠殑' || level == '涓汉') level = 'private';

    return Message(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      images: (map['images'] as String?)?.isNotEmpty == true
          ? (map['images'] as String).split(',').where((p) => p.isNotEmpty).toList()
          : [],
      files: (map['files'] as String?)?.isNotEmpty == true
          ? (map['files'] as String).split(',').where((p) => p.isNotEmpty).toList()
          : [],
      tags: (map['tags'] as String?)?.isNotEmpty == true
          ? (map['tags'] as String).split(',').where((p) => p.isNotEmpty).toList()
          : [],
      level: level,
      groupId: map['groupId'] as String?,
      userId: userId,
      category: (map['category'] as String?) ?? '鏈垎绫?,
      subcategory: map['subcategory'] as String?,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Message copyWith({
    int? id,
    String? title,
    String? content,
    List<String>? images,
    List<String>? files,
    List<String>? tags,
    String? level,
    String? groupId,
    int? userId,
    String? category,
    String? subcategory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      files: files ?? this.files,
      tags: tags ?? this.tags,
      level: level ?? this.level,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
