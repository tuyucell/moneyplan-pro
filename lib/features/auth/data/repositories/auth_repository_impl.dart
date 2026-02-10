import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';
import 'package:moneyplan_pro/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

import 'package:moneyplan_pro/core/services/google_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final sb.SupabaseClient _supabase;
  final gsi.GoogleSignIn _googleSignIn = GoogleAuthService().instance;

  AuthRepositoryImpl({
    required sb.SupabaseClient supabase,
  }) : _supabase = supabase;

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return await _fetchFullUserModel(user);
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Giriş başarısız: Kullanıcı bulunamadı.');
      }

      return await _fetchFullUserModel(response.user!);
    } on sb.AuthException catch (e) {
      debugPrint('SUPABASE_AUTH_ERROR: ${e.message} (Code: ${e.statusCode})');
      // Turkish friendly messages for common errors
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('E-posta veya şifre hatalı.');
      } else if (e.message.contains('Email not confirmed')) {
        throw Exception('Lütfen e-posta adresinizi onaylayın.');
      }
      rethrow;
    } catch (e) {
      debugPrint('GENERAL_AUTH_ERROR: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );

    if (response.user == null) {
      throw Exception('Kayıt başarısız oldu.');
    }

    return await _fetchFullUserModel(response.user!);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      debugPrint('AUTH_DEBUG: Starting Google Sign In Flow...');

      // Force clear previous cache to ensure fresh scope request
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        // Ignored, maybe not signed in
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('AUTH_DEBUG: Google Sign In cancelled by user.');
        throw Exception('Google girişi iptal edildi.');
      }
      debugPrint('AUTH_DEBUG: User signed into Google: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      debugPrint('AUTH_DEBUG: idToken obtained: ${idToken != null}');
      debugPrint('AUTH_DEBUG: accessToken obtained: ${accessToken != null}');

      if (idToken == null) {
        throw Exception('ID Token bulunamadı.');
      }

      debugPrint('AUTH_DEBUG: Signing into Supabase with idToken...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        debugPrint(
            'AUTH_DEBUG: Supabase returned null user after signInWithIdToken');
        throw Exception('Supabase Google girişi başarısız oldu.');
      }

      debugPrint(
          'AUTH_DEBUG: Successfully authenticated with Supabase: ${response.user!.email}');
      debugPrint('AUTH_DEBUG: Session: ${response.session != null}');

      return await _fetchFullUserModel(response.user!);
    } catch (e, stack) {
      debugPrint('AUTH_DEBUG: ERROR in signInWithGoogle: $e');
      debugPrint('AUTH_DEBUG: STACKTRACE: $stack');
      throw Exception('Google ile giriş yapılırken hata oluştu: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _supabase.auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;
      return await _fetchFullUserModel(user);
    });
  }

  Future<UserModel> _fetchFullUserModel(sb.User user) async {
    try {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        displayName: userData?['display_name'] ??
            user.userMetadata?['display_name'] ??
            user.userMetadata?['full_name'],
        avatarUrl: userData?['avatar_url'] ??
            user.userMetadata?['avatar_url'] ??
            user.userMetadata?['picture'],
        createdAt: DateTime.parse(user.createdAt),
        lastLoginAt: user.lastSignInAt != null
            ? DateTime.parse(user.lastSignInAt!)
            : null,
        authProvider: user.appMetadata['provider'] ?? 'email',
        birthYear: userData?['birth_year'],
        gender: userData?['gender'],
        occupation: userData?['occupation'],
        financialGoal: userData?['financial_goal'],
        riskTolerance: userData?['risk_tolerance'],
        isProfileCompleted: userData?['is_profile_completed'] ?? false,
      );
    } catch (e) {
      debugPrint('ERROR fetching full user model: $e');
      return _mapSupabaseUserToModel(user);
    }
  }

  @override
  Future<void> updateUserDetails(UserModel user) async {
    // 1. Update public.users table
    await _supabase.from('users').update({
      'display_name': user.displayName,
      'birth_year': user.birthYear,
      'gender': user.gender,
      'occupation': user.occupation,
      'financial_goal': user.financialGoal,
      'risk_tolerance': user.riskTolerance,
      'is_profile_completed': user.isProfileCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    // 2. Also update Auth user metadata for session consistency
    await _supabase.auth.updateUser(
      sb.UserAttributes(
        data: {
          'display_name': user.displayName,
          'birth_year': user.birthYear,
          'gender': user.gender,
          'occupation': user.occupation,
          'financial_goal': user.financialGoal,
          'risk_tolerance': user.riskTolerance,
          'is_profile_completed': user.isProfileCompleted,
        },
      ),
    );
  }

  UserModel _mapSupabaseUserToModel(sb.User user) {
    // Note: To get full details, we might need a separate fetch from 'users' table
    // For now, we return what's in the auth metadata
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      displayName:
          user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'],
      avatarUrl:
          user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'],
      createdAt: DateTime.parse(user.createdAt),
      lastLoginAt:
          user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null,
      authProvider: user.appMetadata['provider'] ?? 'email',
      birthYear: user.userMetadata?['birth_year'],
      gender: user.userMetadata?['gender'],
      occupation: user.userMetadata?['occupation'],
      financialGoal: user.userMetadata?['financial_goal'],
      riskTolerance: user.userMetadata?['risk_tolerance'],
      isProfileCompleted: user.userMetadata?['is_profile_completed'] ?? false,
    );
  }
}
