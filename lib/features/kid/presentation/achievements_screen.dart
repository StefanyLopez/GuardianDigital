import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/profile_provider.dart';
import '../../../core/theme/theme_extension.dart';

final _achievementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return [];
  final client = Supabase.instance.client;
  final all = await client.from(AppConstants.tableAchievements).select();
  final unlocked = await client
      .from(AppConstants.tableAchievementUnlocks)
      .select('achievement_id, unlocked_at')
      .eq('profile_id', profile.id);
  final unlockedIds = {
    for (final u in unlocked as List)
      u['achievement_id'] as String: u['unlocked_at'] as String
  };
  return (all as List)
      .cast<Map<String, dynamic>>()
      .map((a) => {
            ...a,
            'unlocked': unlockedIds.containsKey(a['id']),
            'unlocked_at': unlockedIds[a['id']],
          })
      .toList();
});

final _challengesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return [];
  final client = Supabase.instance.client;
  final progress = await client
      .from(AppConstants.tableChallengeProgress)
      .select('*, challenges(*)')
      .eq('profile_id', profile.id)
      .order('started_at', ascending: false)
      .limit(10);
  return List<Map<String, dynamic>>.from(progress);
});

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final achievementsAsync = ref.watch(_achievementsProvider);
    final challengesAsync = ref.watch(_challengesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Mis logros', style: GDTypography.headlineMedium)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: GDSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile != null) ...[
              const Gap(GDSpacing.md),
              _buildAutonomyHeader(context, profile),
              const Gap(GDSpacing.lg),
            ],
            Text('Retos activos', style: GDTypography.headlineMedium),
            const Gap(GDSpacing.md),
            challengesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.gd.primary)),
              error: (_, __) => Text('Error al cargar retos', style: GDTypography.bodyMedium),
              data: (challenges) {
                final active = challenges.where((c) => c['status'] == 'active').toList();
                if (active.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(GDSpacing.md),
                    decoration: BoxDecoration(color: context.gd.surfaceVariant, borderRadius: GDRadius.lgAll),
                    child: Row(children: [
                      const Text('🎯', style: TextStyle(fontSize: 24)),
                      const Gap(GDSpacing.md),
                      Expanded(child: Text('Habla con Luma para un reto.', style: GDTypography.bodyMedium)),
                    ]),
                  );
                }
                return Column(
                  children: active.map((c) => _buildChallengeCard(context, c)).toList(),
                );
              },
            ),
            const Gap(GDSpacing.lg),
            Text('Insignias', style: GDTypography.headlineMedium),
            const Gap(GDSpacing.md),
            achievementsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.gd.primary)),
              error: (_, __) => Text('Error al cargar insignias', style: GDTypography.bodyMedium),
              data: (achievements) {
                final unlockedCount = achievements.where((a) => a['unlocked'] == true).length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$unlockedCount de ${achievements.length} desbloqueadas', style: GDTypography.bodyMedium),
                    const Gap(GDSpacing.md),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: GDSpacing.md,
                        crossAxisSpacing: GDSpacing.md,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: achievements.length,
                      itemBuilder: (_, i) => _buildAchievementCard(context, achievements[i])
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 100 + i * 60))
                          .scale(begin: const Offset(0.8, 0.8)),
                    ),
                  ],
                );
              },
            ),
            const Gap(GDSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAutonomyHeader(BuildContext context, dynamic profile) {
    final level = profile.autonomyLevel as int;
    final label = AppConstants.autonomyLevelLabels[level - 1];
    final emoji = AppConstants.autonomyLevelEmojis[level - 1];
    return Container(
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(gradient: context.gd.gradientPrimary, borderRadius: GDRadius.lgAll),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const Gap(GDSpacing.md),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GDTypography.headlineMedium.copyWith(color: Colors.white)),
            Text('Nivel $level de 5', style: GDTypography.bodySmall.copyWith(color: Colors.white70)),
            const Gap(GDSpacing.sm),
            ClipRRect(
              borderRadius: GDRadius.fullAll,
              child: LinearProgressIndicator(
                value: level / 5.0, minHeight: 6,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        )),
      ]),
    );
  }

  Widget _buildChallengeCard(BuildContext context, Map<String, dynamic> data) {
    final challenge = data['challenges'] as Map<String, dynamic>? ?? {};
    final title = challenge['title'] as String? ?? 'Reto';
    final category = challenge['category'] as String? ?? 'offline';
    final points = challenge['points'] as int? ?? 10;
    final emoji = {'offline':'🌿','mindfulness':'🧘','social':'👥','sleep':'🌙','focus':'🎯'}[category] ?? '⭐';
    return Container(
      margin: const EdgeInsets.only(bottom: GDSpacing.sm),
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        color: context.gd.surface, borderRadius: GDRadius.lgAll,
        border: Border.all(color: context.gd.primary.withValues(alpha: 0.12)),
        boxShadow: context.gd.shadowSm,
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: context.gd.primaryLight, borderRadius: GDRadius.mdAll),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
        const Gap(GDSpacing.md),
        Expanded(child: Text(title, style: GDTypography.titleLarge)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: GDSpacing.sm, vertical: 4),
          decoration: BoxDecoration(color: context.gd.successLight, borderRadius: GDRadius.fullAll),
          child: Text('+$points pts', style: GDTypography.labelSmall.copyWith(color: context.gd.success, fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _buildAchievementCard(BuildContext context, Map<String, dynamic> data) {
    final isUnlocked = data['unlocked'] as bool? ?? false;
    final emoji = data['emoji'] as String? ?? '🏅';
    final title = data['title'] as String? ?? '';
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(borderRadius: GDRadius.xlAll),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(GDSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const Gap(GDSpacing.md),
            Text(title, style: GDTypography.headlineLarge),
            const Gap(GDSpacing.sm),
            Text(data['description'] as String? ?? '',
              style: GDTypography.bodyLarge.copyWith(color: context.gd.textSecondary),
              textAlign: TextAlign.center),
            const Gap(GDSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: GDSpacing.md, vertical: GDSpacing.sm),
              decoration: BoxDecoration(
                color: isUnlocked ? context.gd.successLight : context.gd.surfaceVariant,
                borderRadius: GDRadius.fullAll,
              ),
              child: Text(isUnlocked ? '✓ Desbloqueada' : 'Aún no desbloqueada',
                style: GDTypography.labelLarge.copyWith(
                  color: isUnlocked ? context.gd.success : context.gd.textTertiary)),
            ),
            const Gap(GDSpacing.xl),
          ]),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(GDSpacing.sm),
        decoration: BoxDecoration(
          color: isUnlocked ? context.gd.primaryLight : context.gd.surfaceVariant,
          borderRadius: GDRadius.lgAll,
          border: Border.all(color: isUnlocked ? context.gd.primary.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ColorFiltered(
            colorFilter: isUnlocked
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : const ColorFilter.matrix([
                    0.2126,0.7152,0.0722,0,0,
                    0.2126,0.7152,0.0722,0,0,
                    0.2126,0.7152,0.0722,0,0,
                    0,0,0,1,0,
                  ]),
            child: Text(emoji, style: TextStyle(fontSize: isUnlocked ? 32 : 26)),
          ),
          const Gap(GDSpacing.xs),
          Text(title,
            style: GDTypography.bodySmall.copyWith(
              color: isUnlocked ? context.gd.textPrimary : context.gd.textTertiary,
              fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.w400),
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (isUnlocked) ...[
            const Gap(4),
            Container(width: 8, height: 8,
              decoration: BoxDecoration(color: context.gd.primary, shape: BoxShape.circle)),
          ],
        ]),
      ),
    );
  }
}
