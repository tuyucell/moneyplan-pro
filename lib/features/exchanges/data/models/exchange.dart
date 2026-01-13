class Exchange {
  final String id;
  final String name;
  final String? shortName;
  final String? descriptionTr;
  final String? descriptionEn;
  final String? logoUrl;
  final String? websiteUrl;
  final String? appIosUrl;
  final String? appAndroidUrl;

  // Location
  final String countryCode;
  final String? countryNameTr;
  final String? countryNameEn;
  final String? city;
  final String? timezone;

  // Trading info
  final Map<String, dynamic>? tradingHoursUtc;
  final String? tradingHoursLocal;

  // Metrics
  final double? totalVolume24hUsd;
  final int? trustScore;
  final int? yearEstablished;

  // Supported categories
  final List<String> supportedCategories;

  final bool isActive;
  final bool isFeatured;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Exchange({
    required this.id,
    required this.name,
    this.shortName,
    this.descriptionTr,
    this.descriptionEn,
    this.logoUrl,
    this.websiteUrl,
    this.appIosUrl,
    this.appAndroidUrl,
    required this.countryCode,
    this.countryNameTr,
    this.countryNameEn,
    this.city,
    this.timezone,
    this.tradingHoursUtc,
    this.tradingHoursLocal,
    this.totalVolume24hUsd,
    this.trustScore,
    this.yearEstablished,
    this.supportedCategories = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Exchange.fromJson(Map<String, dynamic> json) {
    return Exchange(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String?,
      descriptionTr: json['description_tr'] as String?,
      descriptionEn: json['description_en'] as String?,
      logoUrl: json['logo_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      appIosUrl: json['app_ios_url'] as String?,
      appAndroidUrl: json['app_android_url'] as String?,
      countryCode: json['country_code'] as String,
      countryNameTr: json['country_name_tr'] as String?,
      countryNameEn: json['country_name_en'] as String?,
      city: json['city'] as String?,
      timezone: json['timezone'] as String?,
      tradingHoursUtc: json['trading_hours_utc'] as Map<String, dynamic>?,
      tradingHoursLocal: json['trading_hours_local'] as String?,
      totalVolume24hUsd: json['total_volume_24h_usd'] != null
          ? double.tryParse(json['total_volume_24h_usd'].toString())
          : null,
      trustScore: json['trust_score'] as int?,
      yearEstablished: json['year_established'] as int?,
      supportedCategories: json['supported_categories'] != null
          ? List<String>.from(json['supported_categories'] as List)
          : [],
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'description_tr': descriptionTr,
      'description_en': descriptionEn,
      'logo_url': logoUrl,
      'website_url': websiteUrl,
      'app_ios_url': appIosUrl,
      'app_android_url': appAndroidUrl,
      'country_code': countryCode,
      'country_name_tr': countryNameTr,
      'country_name_en': countryNameEn,
      'city': city,
      'timezone': timezone,
      'trading_hours_utc': tradingHoursUtc,
      'trading_hours_local': tradingHoursLocal,
      'total_volume_24h_usd': totalVolume24hUsd,
      'trust_score': trustScore,
      'year_established': yearEstablished,
      'supported_categories': supportedCategories,
      'is_active': isActive,
      'is_featured': isFeatured,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ExchangeSummary {
  final Exchange exchange;
  final int supportedAssetsCount;
  final double? avgRating;
  final int reviewCount;

  ExchangeSummary({
    required this.exchange,
    this.supportedAssetsCount = 0,
    this.avgRating,
    this.reviewCount = 0,
  });

  factory ExchangeSummary.fromJson(Map<String, dynamic> json) {
    return ExchangeSummary(
      exchange: Exchange.fromJson(json),
      supportedAssetsCount: json['supported_assets_count'] as int? ?? 0,
      avgRating: json['avg_rating'] != null
          ? double.tryParse(json['avg_rating'].toString())
          : null,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }
}
