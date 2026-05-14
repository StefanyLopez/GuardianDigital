import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/profile_model.dart';

// ─────────────────────────────────────────────
//  PERFIL ACTIVO — arquitectura reactiva
//
//  Solo se escribe el ID (liviano). El perfil completo se DERIVA
//  automáticamente del ID sin ningún side-effect en providers.
//
//  Escritura:  ref.read(activeProfileIdProvider.notifier).state = id;
//  Lectura:    ref.watch(activeProfileProvider) → ProfileModel?
// ─────────────────────────────────────────────

/// ID del perfil actualmente seleccionado. Es la única fuente de verdad
/// que se escribe desde fuera. Nunca contiene el objeto completo.
final activeProfileIdProvider = StateProvider<String?>((ref) => null);

/// Perfil activo derivado reactivamente del ID. Lee de [profileByIdProvider]
/// sin ningún side-effect. Expone [ProfileModel?] para que las pantallas
/// existentes no necesiten cambiar su API de lectura.
final activeProfileProvider = Provider.autoDispose<ProfileModel?>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  if (profileId == null) return null;
  // Lee el valor cacheado del FutureProvider sin causar rebuilds de async
  return ref.watch(profileByIdProvider(profileId)).valueOrNull;
});

// ─────────────────────────────────────────────
//  LISTA DE PERFILES DE LA FAMILIA
//
//  FutureProvider.autoDispose: se destruye cuando GuardianHomeScreen
//  no está en pantalla, liberando recursos. Se re-fetcha con una query
//  .select() normal en lugar de un WebSocket Realtime permanente.
//
//  Invalidación: los métodos de ProfileNotifier que modifican datos
//  llaman ref.invalidate(familyProfilesProvider) para forzar re-fetch.
// ─────────────────────────────────────────────
final familyProfilesProvider =
    FutureProvider.autoDispose<List<ProfileModel>>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from(AppConstants.tableProfiles)
      .select()
      .eq('family_id', userId)
      .order('created_at');

  return (data as List).map((e) => ProfileModel.fromJson(e)).toList();
});

// ─────────────────────────────────────────────
//  PERFIL POR ID — provider puro, sin side-effects
//  Solo fetcha y retorna. No escribe en ningún otro provider.
//  Invalidación: ProfileNotifier llama ref.invalidate(profileByIdProvider(id))
//  después de updateProfile, updateStreak, updateAutonomyLevel.
// ─────────────────────────────────────────────
final profileByIdProvider =
    FutureProvider.family<ProfileModel?, String>((ref, profileId) async {
  final client = Supabase.instance.client;
  try {
    final data = await client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', profileId)
        .single();
    return ProfileModel.fromJson(data);
  } catch (e) {
    debugPrint('ERROR en profileById($profileId): $e');
    return null;
  }
});

// ─────────────────────────────────────────────
//  PROFILE NOTIFIER — CRUD
// ─────────────────────────────────────────────
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>(
  (ref) => ProfileNotifier(ref),
);

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;
  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  Future<ProfileModel?> createProfile({
    required String name,
    required String ageRange,
    required int avatarId,
    required List<String> goals,
  }) async {
    if (_userId == null) return null;
    state = const AsyncValue.loading();
    try {
      final data = await _client
          .from(AppConstants.tableProfiles)
          .insert({
            'family_id': _userId,
            'name': name,
            'age_range': ageRange,
            'avatar_id': avatarId,
            'goals': goals,
          })
          .select()
          .single();
      final profile = ProfileModel.fromJson(data);
      ref.read(activeProfileIdProvider.notifier).state = profile.id;
      ref.invalidate(familyProfilesProvider);
      state = const AsyncValue.data(null);
      return profile;
    } catch (e, st) {
      debugPrint('Error creando perfil: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateStreak(String profileId, int newStreak) async {
    try {
      await _client
          .from(AppConstants.tableProfiles)
          .update({
            'streak_days': newStreak,
            'last_active': DateTime.now().toIso8601String(),
          })
          .eq('id', profileId);
      // Invalida tanto la lista como el perfil individual para refrescar la UI
      ref.invalidate(familyProfilesProvider);
      ref.invalidate(profileByIdProvider(profileId));
    } catch (e) {
      debugPrint('Error actualizando racha: $e');
    }
  }

  Future<void> updateAutonomyLevel(String profileId, int level) async {
    try {
      await _client
          .from(AppConstants.tableProfiles)
          .update({'autonomy_level': level})
          .eq('id', profileId);
      ref.invalidate(familyProfilesProvider);
      ref.invalidate(profileByIdProvider(profileId));
    } catch (e) {
      debugPrint('Error actualizando autonomía: $e');
    }
  }

  Future<void> updateProfile({
  required String profileId,
  required String name,
  required String ageRange,
  required int avatarId,
  required List<String> goals,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _client
          .from(AppConstants.tableProfiles)
          .update({
            'name': name,
            'age_range': ageRange,
            'avatar_id': avatarId,
            'goals': goals,
          })
          .eq('id', profileId);
      // Invalida lista y perfil individual para refrescar GuardianHome y KidHome
      ref.invalidate(familyProfilesProvider);
      ref.invalidate(profileByIdProvider(profileId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('Error actualizando perfil: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProfile(String profileId) async {
    state = const AsyncValue.loading();
    try {
      await _client
          .from(AppConstants.tableProfiles)
          .delete()
          .eq('id', profileId);

      final activeId = ref.read(activeProfileIdProvider);
      if (activeId == profileId) {
        ref.read(activeProfileIdProvider.notifier).state = null;
      }

      ref.invalidate(familyProfilesProvider); // ← agregar esto

      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('Error borrando perfil: $e');
      debugPrint('Stacktrace: $st');
      state = AsyncValue.error(e, st);
    }
  }
}
