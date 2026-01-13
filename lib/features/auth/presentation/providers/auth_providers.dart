import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:invest_guide/features/auth/domain/repositories/auth_repository.dart';

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

  AuthNotifier(this._repository) : super(AuthInitial()) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    state = AuthLoading();
    final user = await _repository.getCurrentUser();
    if (user != null) {
      state = AuthAuthenticated(user);
    } else {
      state = AuthUnauthenticated();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = AuthLoading();
      final user = await _repository.signInWithEmail(email, password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      state = AuthLoading();
      final user = await _repository.signUpWithEmail(email, password, displayName);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = AuthLoading();
      final user = await _repository.signInWithGoogle();
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      state = AuthLoading();
      await _repository.signOut();
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
  return AuthNotifier(repository);
});
