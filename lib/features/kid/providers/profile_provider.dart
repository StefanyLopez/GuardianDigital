import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/profile_model.dart';

// ─────────────────────────────────────────────
//  PERFIL ACTIVO (estado global)
// ─────────────────────────────────────────────
final activeProfileProvider = StateProvider<ProfileModel?>((ref) => null);

// ─────────────────────────────────────────────
//  LISTA DE PERFILES DE LA FAMILIA
// ─────────────────────────────────────────────
final familyProfilesProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final client = Supabase.instance.client;
  try {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('family_id', userId)
        .order('created_at');
    return data.map((e) => ProfileModel.fromJson(e)).toList();
  } catch (e, stack) {
    debugPrint('ERROR en familyProfilesProvider: $e\n$stack');
    throw Exception('Error al conectar con la base de datos');
  }
});

// ─────────────────────────────────────────────
//  PERFIL POR ID — sin build_runner
//  Family de providers parametrizados manualmente
// ─────────────────────────────────────────────
final profileByIdProvider = FutureProvider.family<ProfileModel?, String>(
  (ref, profileId) async {
    final client = Supabase.instance.client;
    try {
      final data = await client
          .from(AppConstants.tableProfiles)
          .select()
          .eq('id', profileId)
          .single();
      final profile = ProfileModel.fromJson(data);
      // Sincroniza el activeProfileProvider para el chat
      ref.read(activeProfileProvider.notifier).state = profile;
      return profile;
    } catch (e) {
      debugPrint('ERROR en profileById($profileId): $e');
      return null;
    }
  },
);

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
      ref.read(activeProfileProvider.notifier).state = profile;
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
      ref.invalidate(familyProfilesProvider);
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
    } catch (e) {
      debugPrint('Error actualizando autonomía: $e');
    }
  }
}
