import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/core/services/push_notification_service.dart';
import 'package:invest_guide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:invest_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:invest_guide/core/services/security/secure_storage_service.dart';
import 'package:invest_guide/core/services/security/biometric_service.dart';
import 'package:invest_guide/core/providers/common_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Supabase client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(supabase: supabase);
});

// Auth State Provider (Direct stream from Firebase/Supabase)
final authStateProvider = StreamProvider<AuthState>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);

  // Initial state check
  final currentUser = await repo.getCurrentUser();
  if (currentUser != null) {
    yield AuthAuthenticated(currentUser);
  } else {
    yield AuthUnauthenticated();
  }

  // Listen to changes
  await for (final user in repo.authStateChanges) {
    if (user != null) {
      yield AuthAuthenticated(user);
    } else {
      yield AuthUnauthenticated();
    }
  }
});

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _secureStorage;
  final BiometricService _biometricService;
  final SharedPreferences _prefs;

  AuthNotifier(this._repository, this._secureStorage, this._biometricService,
      this._prefs)
      : super(AuthInitial()) {
    _checkInitialState();
  }

  UserModel _checkLocalCompletion(UserModel user) {
    // Logic to check local completion override
    final localCompleted =
        _prefs.getBool('profile_completed_${user.id}') ?? false;
    if (localCompleted && !user.isProfileCompleted) {
      return user.copyWith(isProfileCompleted: true);
    }
    return user;
  }

  Future<void> _checkInitialState() async {
    state = AuthLoading();
    final userResult = await _repository.getCurrentUser();
    if (userResult != null) {
      final user = _checkLocalCompletion(userResult);
      state = AuthAuthenticated(user);
      await PushNotificationService().login(user.id);
    } else {
      state = AuthUnauthenticated();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = AuthLoading();
      final userResult = await _repository.signInWithEmail(email, password);
      final user = _checkLocalCompletion(userResult);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
      rethrow;
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      state = AuthLoading();
      final userResult =
          await _repository.signUpWithEmail(email, password, displayName);
      // New users haven't completed profile yet, so no local check needed really,
      // but good practice to keep consistent if logic changes.
      final user = _checkLocalCompletion(userResult);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = AuthLoading();
      final userResult = await _repository.signInWithGoogle();
      final user = _checkLocalCompletion(userResult);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      // Try DB update
      try {
        await _repository.updateUserDetails(updatedUser);
      } catch (e) {
        debugPrint('AUTH_DEBUG: DB update failed, falling back to local: $e');
      }

      // Always Mark locally as completed for this user to stop nagging
      await _prefs.setBool('profile_completed_${updatedUser.id}', true);

      // Update local state with the new user data (force completed flag)
      state = AuthAuthenticated(updatedUser.copyWith(isProfileCompleted: true));
    } catch (e) {
      debugPrint('AUTH_DEBUG: Failed to update profile: $e');
      rethrow;
    }
  }

  /// Called when user explicitly enables biometrics
  Future<void> registerBiometrics(String email, String password) async {
    try {
      await _secureStorage.saveCredentials(email, password);
      await _secureStorage.setBiometricEnabled(true);
    } catch (e) {
      state = AuthError('Biometric registration failed: $e');
    }
  }

  /// Called from Biometric Login button
  Future<void> signInWithBiometrics({String? localizedReason}) async {
    try {
      state = AuthLoading();

      final isEnabled = await _secureStorage.isBiometricEnabled();
      if (!isEnabled) {
        state = AuthUnauthenticated();
        throw Exception('Biometrik giriş henüz bu cihazda aktif edilmemiş.');
      }

      // Step 1: Perform native biometric authentication
      final authenticated = await _biometricService.authenticate(
        localizedReason:
            localizedReason ?? 'Cüzdanınıza erişmek için doğrulama yapın.',
      );

      if (!authenticated) {
        state = AuthUnauthenticated();
        return; // User cancelled or failed
      }

      // Step 2: Retrieve saved credentials
      final creds = await _secureStorage.getCredentials();
      final email = creds['email'];
      final password = creds['password'];

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        state = AuthUnauthenticated();
        throw Exception(
            'Kayıtlı kimlik bilgisi bulunamadı. Lütfen bir kez şifrenizle giriş yapın.');
      }

      // Step 3: Sign in with the stored password
      final userResult = await _repository.signInWithEmail(email, password);
      final user = _checkLocalCompletion(userResult);
      state = AuthAuthenticated(user);
      await PushNotificationService().login(user.id);
    } catch (e) {
      debugPrint('AUTH_DEBUG (Biometric): Login failed: $e');
      final errorMsg = e.toString().contains('Invalid login credentials')
          ? 'Kayıtlı şifreniz değişmiş olabilir. Lütfen şifrenizle giriş yapıp biyometriyi tekrar aktif edin.'
          : e.toString();
      state = AuthError(errorMsg);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = AuthLoading();
      await _repository.signOut();
      await PushNotificationService().logout();
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _repository.sendPasswordResetEmail(email);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}

// Auth Notifier Provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final biometric = ref.watch(biometricServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(repository, secureStorage, biometric, prefs);
});
