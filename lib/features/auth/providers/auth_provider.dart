import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
//  ESTADO DE SESIÓN
// ─────────────────────────────────────────────

/// Stream completo de eventos de auth. Emite en CADA evento técnico de
/// Supabase: token refresh, user updated, sesión restaurada, etc.
/// Úsalo solo cuando necesites reaccionar a eventos específicos de AuthState.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Estado de login reducido a true/false.
/// Solo cambia de valor cuando el usuario realmente inicia o cierra sesión.
/// Token refreshes y otros eventos técnicos NO lo modifican.
/// El GoRouter lo observa para no recrearse en cada refresh de token.
final isLoggedInProvider = StreamProvider<bool>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((authState) => authState.session != null)
      .distinct(); // solo emite cuando el valor bool cambia
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// ─────────────────────────────────────────────
//  AUTH NOTIFIER
// ─────────────────────────────────────────────
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signUp(email: email, password: password);
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _client.auth.signOut();
    });
  }
}
