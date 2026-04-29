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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      images: (map['images'] as String?)?.isNotEmpty == true
          ? (map['images'] as String).split(',')
          : [],
      files: (map['files'] as String?)?.isNotEmpty == true
          ? (map['files'] as String).split(',')
          : [],
      tags: (map['tags'] as String?)?.isNotEmpty == true
          ? (map['tags'] as String).split(',')
          : [],
      level: map['level'] as String,
      groupId: map['groupId'] as String?,
      userId: map['userId'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
