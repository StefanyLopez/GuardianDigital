import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/profile_model.dart';

// ─────────────────────────────────────────────
//  SERVICIO DE INSIGNIAS
//  Evalúa todas las condiciones y desbloquea
//  automáticamente. Se llama cada vez que el
//  perfil cambia (racha, nivel, retos, puntos).
// ─────────────────────────────────────────────
class AchievementService {
  AchievementService._();

  static final _client = Supabase.instance.client;

  /// Evalúa todas las condiciones del perfil y
  /// desbloquea las insignias que correspondan.
  /// Retorna la lista de IDs recién desbloqueados.
  static Future<List<String>> evaluate(ProfileModel profile) async {
    final newlyUnlocked = <String>[];

    try {
      // Obtener todas las insignias del catálogo
      final all = await _client
          .from(AppConstants.tableAchievements)
          .select('id, condition');

      // Obtener las ya desbloqueadas
      final existing = await _client
          .from(AppConstants.tableAchievementUnlocks)
          .select('achievement_id')
          .eq('profile_id', profile.id);

      final existingIds = (existing as List)
          .map((e) => e['achievement_id'] as String)
          .toSet();

      // Evaluar cada condición
      for (final achievement in all as List) {
        final id        = achievement['id'] as String;
        final condition = achievement['condition'] as String;

        if (existingIds.contains(id)) continue;

        final shouldUnlock = _evaluateCondition(condition, profile);

        if (shouldUnlock) {
          await _client
              .from(AppConstants.tableAchievementUnlocks)
              .upsert({'profile_id': profile.id, 'achievement_id': id});
          newlyUnlocked.add(id);
          debugPrint('🏅 Insignia desbloqueada: $condition (${profile.name})');
        }
      }
    } catch (e) {
      debugPrint('Error evaluando insignias: $e');
    }

    return newlyUnlocked;
  }

  static bool _evaluateCondition(String condition, ProfileModel profile) {
    switch (condition) {
      case 'first_chat':
        // Se desbloquea desde chat_provider, no aquí
        return false;
      case 'streak_3':
        return profile.streakDays >= 3;
      case 'streak_7':
        return profile.streakDays >= 7;
      case 'streak_30':
        return profile.streakDays >= 30;
      case 'challenge_1':
        return profile.lumaPoints >= 10;
      case 'challenge_5':
        return profile.lumaPoints >= 50;
      case 'challenge_10':
        return profile.lumaPoints >= 100;
      case 'night_free_3':
        return !profile.hadNightUsage && profile.streakDays >= 3;
      case 'offline_5':
        return profile.lumaPoints >= 25;
      case 'autonomy_3':
        return profile.autonomyLevel >= 3;
      case 'autonomy_5':
        return profile.autonomyLevel >= 5;
      case 'points_50':
        return profile.lumaPoints >= 50;
      case 'points_100':
        return profile.lumaPoints >= 100;
      default:
        return false;
    }
  }

  /// Suma puntos al perfil y reevalúa insignias
  static Future<ProfileModel?> addPoints(
    ProfileModel profile,
    int points,
  ) async {
    try {
      final newPoints = profile.lumaPoints + points;
      await _client
          .from(AppConstants.tableProfiles)
          .update({'luma_points': newPoints})
          .eq('id', profile.id);

      final updated = profile.copyWith(lumaPoints: newPoints);
      await evaluate(updated);
      return updated;
    } catch (e) {
      debugPrint('Error sumando puntos: $e');
      return null;
    }
  }
}
