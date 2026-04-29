class Customer {
  final int? id;
  final DateTime followDate;      // 璺熻繘鏃ユ湡
  final String company;            // 鍏徃锛堝鏍★級
  final String name;               // 濮撳悕
  final String? phone;             // 鐢佃瘽
  final String? researchGroup;     // 璇鹃缁?  final String? product;           // 鍜ㄨ浜у搧
  final String? followResult;      // 璺熻繘缁撴灉
  final String category;           // 鍒嗙被锛堢敤浜嶦xcel鍒哠heet锛?  final bool isPinned;             // 鏄惁缃《
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
    this.category = '鏈垎绫?,
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
      category: (map['category'] as String?) ?? '鏈垎绫?,
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

  /// 鐢ㄤ簬鎼滅储鐨勬枃鏈?  String get searchText => '$name $company $phone $researchGroup $product $followResult';
}
