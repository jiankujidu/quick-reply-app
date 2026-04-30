class Customer {
  final int? id;
  final DateTime followDate;      // 跟进日期
  final String company;            // 公司（学校）
  final String name;               // 姓名
  final String? phone;             // 电话
  final String? researchGroup;     // 课题组
  final String? product;           // 咨询产品
  final String? followResult;      // 跟进结果
  final String category;           // 分类（用于Excel分Sheet）
  final bool isPinned;             // 是否置顶
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.followDate,
    required this.company,
    required this.name,
    this.phone,
    this.researchGroup,
    this.product,
    this.followResult,
    this.category = '未分类',
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'followDate': followDate.toIso8601String(),
      'company': company,
      'name': name,
      'phone': phone,
      'researchGroup': researchGroup,
      'product': product,
      'followResult': followResult,
      'category': category,
      'isPinned': isPinned ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      followDate: map['followDate'] != null
          ? DateTime.tryParse(map['followDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      company: (map['company'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      phone: map['phone'] as String?,
      researchGroup: map['researchGroup'] as String?,
      product: map['product'] as String?,
      followResult: map['followResult'] as String?,
      category: (map['category'] as String?) ?? '未分类',
      isPinned: (map['isPinned'] as int?) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Customer copyWith({
    int? id,
    DateTime? followDate,
    String? company,
    String? name,
    String? phone,
    String? researchGroup,
    String? product,
    String? followResult,
    String? category,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      followDate: followDate ?? this.followDate,
      company: company ?? this.company,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      researchGroup: researchGroup ?? this.researchGroup,
      product: product ?? this.product,
      followResult: followResult ?? this.followResult,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 用于搜索的文本
  String get searchText => '$name $company $phone $researchGroup $product $followResult';
}
