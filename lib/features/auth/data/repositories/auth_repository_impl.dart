import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final sb.SupabaseClient _supabase;
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn();

  AuthRepositoryImpl({
    required sb.SupabaseClient supabase,
  }) : _supabase = supabase;

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Giriş başarısız oldu.');
    }

    return _mapSupabaseUserToModel(response.user!);
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

    return _mapSupabaseUserToModel(response.user!);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google girişi iptal edildi.');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('ID Token bulunamadı.');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
      );

      if (response.user == null) {
        throw Exception('Supabase Google girişi başarısız oldu.');
      }

      return _mapSupabaseUserToModel(response.user!);
    } catch (e) {
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
  Future<UserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _mapSupabaseUserToModel(user);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return _mapSupabaseUserToModel(user);
    });
  }

  UserModel _mapSupabaseUserToModel(sb.User user) {
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
    );
  }
}
