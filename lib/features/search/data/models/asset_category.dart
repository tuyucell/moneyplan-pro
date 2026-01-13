class AssetCategory {
  final int id;
  final String name;
  final String displayNameTr;
  final String displayNameEn;
  final String? icon;
  final String? color;
  final int sortOrder;
  final bool isActive;

  AssetCategory({
    required this.id,
    required this.name,
    required this.displayNameTr,
    required this.displayNameEn,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory AssetCategory.fromJson(Map<String, dynamic> json) {
    return AssetCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      displayNameTr: json['display_name_tr'] as String,
      displayNameEn: json['display_name_en'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name_tr': displayNameTr,
      'display_name_en': displayNameEn,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}

// Predefined categories
class AssetCategoryType {
  static const String commodity = 'commodity';
  static const String crypto = 'crypto';
  static const String forex = 'forex';
  static const String stock = 'stock';
  static const String etf = 'etf';
  static const String bond = 'bond';
}
