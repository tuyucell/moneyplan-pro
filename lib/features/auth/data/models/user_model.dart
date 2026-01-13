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
    };
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
