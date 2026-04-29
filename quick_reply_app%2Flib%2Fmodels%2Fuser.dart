class User {
  final int id;
  final String name;
  final String role; // admin, leader, member
  final String? groupId;
  final String? companyId;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.groupId,
    this.companyId,
  });

  bool get isAdmin => role == 'admin';
  bool get isLeader => role == 'leader';
  bool get isMember => role == 'member';

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      name: map['name'] as String,
      role: map['role'] as String,
      groupId: map['groupId'] as String?,
      companyId: map['companyId'] as String?,
    );
  }
}
