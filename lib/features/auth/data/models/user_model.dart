class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String preferredCurrency;
  final String preferredLanguage;
  final String theme;
  final bool isEmailVerified;
  final String authProvider;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final int? birthYear;
  final String? gender;
  final String? occupation;
  final String? financialGoal;
  final String? riskTolerance;
  final bool isProfileCompleted;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.preferredCurrency = 'TRY',
    this.preferredLanguage = 'tr',
    this.theme = 'system',
    this.isEmailVerified = false,
    this.authProvider = 'email',
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.birthYear,
    this.gender,
    this.occupation,
    this.financialGoal,
    this.riskTolerance,
    this.isProfileCompleted = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      preferredCurrency: json['preferred_currency'] as String? ?? 'TRY',
      preferredLanguage: json['preferred_language'] as String? ?? 'tr',
      theme: json['theme'] as String? ?? 'system',
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      authProvider: json['auth_provider'] as String? ?? 'email',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
      birthYear: json['birth_year'] as int?,
      gender: json['gender'] as String?,
      occupation: json['occupation'] as String?,
      financialGoal: json['financial_goal'] as String?,
      riskTolerance: json['risk_tolerance'] as String?,
      isProfileCompleted: json['is_profile_completed'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'preferred_currency': preferredCurrency,
      'preferred_language': preferredLanguage,
      'theme': theme,
      'is_email_verified': isEmailVerified,
      'auth_provider': authProvider,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'birth_year': birthYear,
      'gender': gender,
      'occupation': occupation,
      'financial_goal': financialGoal,
      'risk_tolerance': riskTolerance,
      'is_profile_completed': isProfileCompleted,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? preferredCurrency,
    String? preferredLanguage,
    String? theme,
    bool? isEmailVerified,
    String? authProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    int? birthYear,
    String? gender,
    String? occupation,
    String? financialGoal,
    String? riskTolerance,
    bool? isProfileCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      theme: theme ?? this.theme,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      financialGoal: financialGoal ?? this.financialGoal,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
    );
  }
}

// Auth State
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
