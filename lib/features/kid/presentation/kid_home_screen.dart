import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../models/profile_model.dart';
import '../providers/profile_provider.dart';
import '../providers/chat_provider.dart';

class KidHomeScreen extends ConsumerWidget {
  final String profileId;
  const KidHomeScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(profileId));

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: GDColors.primary)),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const Gap(GDSpacing.md),
              Text('Error al cargar el perfil', style: GDTypography.headlineMedium),
              const Gap(GDSpacing.sm),
              Text('$e', style: GDTypography.bodySmall),
              const Gap(GDSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const Gap(GDSpacing.md),
                  Text('Perfil no encontrado', style: GDTypography.headlineMedium),
                  const Gap(GDSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Volver al inicio'),
                  ),
                ],
              ),
            ),
          );
        }

        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? '¡Buenos días'
            : hour < 18
                ? '¡Buenas tardes'
                : '¡Buenas noches';

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: 'Panel familiar',
              onPressed: () => context.go(AppRoutes.guardianHome),
            ),
            actions: [
              if (kDebugMode)
                IconButton(
                  icon: const Icon(Icons.science_outlined),
                  onPressed: () => context.push(AppRoutes.demoPanel),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: GDSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(GDSpacing.lg),

                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting, ${profile.name}!',
                              style: GDTypography.headlineLarge,
                            ),
                            Text(
                              'Luma está aquí contigo.',
                              style: GDTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: GDColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: GDColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            profile.avatarEmoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideY(begin: -0.2),

                  const Gap(GDSpacing.xl),

                  // Tarjeta NPC
                  _NpcCard(profile: profile, profileId: profileId)
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2),

                  const Gap(GDSpacing.lg),

                  // Racha
                  _StreakCard(streak: profile.streakDays)
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.2),

                  const Gap(GDSpacing.lg),

                  // Autonomía
                  _AutonomyCard(level: profile.autonomyLevel)
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.2),

                  const Gap(GDSpacing.lg),

                  Text('Accesos rápidos', style: GDTypography.titleLarge)
                      .animate()
                      .fadeIn(delay: 500.ms),

                  const Gap(GDSpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: _QuickCard(
                          emoji: '🏆',
                          label: 'Mis logros',
                          color: GDColors.gold,
                          onTap: () => context.go(AppRoutes.achievements(profileId)),
                        ),
                      ),
                      const Gap(GDSpacing.md),
                      Expanded(
                        child: _QuickCard(
                          emoji: '📊',
                          label: 'Mi semana',
                          color: GDColors.secondary,
                          onTap: () => context.go(AppRoutes.stats(profileId)),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const Gap(GDSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  TARJETA NPC
// ─────────────────────────────────────────────
class _NpcCard extends ConsumerWidget {
  final ProfileModel profile;
  final String profileId;
  const _NpcCard({required this.profile, required this.profileId});

  String _getNpcMessage(int streakDays) {
    if (streakDays == 0) return '¿Listo para empezar? Cuéntame cómo estás.';
    if (streakDays < 3) return '¡Llevas $streakDays día(s)! Buen comienzo.';
    if (streakDays < 7) return '¡$streakDays días seguidos! Estás en racha 🔥';
    return '¡$streakDays días! Eso es compromiso de verdad.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(chatNotifierProvider.notifier).initialize();
        context.go(AppRoutes.chat(profileId));
      },
      child: Container(
        padding: const EdgeInsets.all(GDSpacing.lg),
        decoration: BoxDecoration(
          gradient: GDColors.gradientPrimary,
          borderRadius: GDRadius.xlAll,
          boxShadow: GDShadows.lg,
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 32)),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.06,
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            const Gap(GDSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.npcName,
                    style: GDTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _getNpcMessage(profile.streakDays),
                    style: GDTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const Gap(GDSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GDSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: GDRadius.fullAll,
                    ),
                    child: Text(
                      'Hablar con Luma →',
                      style: GDTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TARJETA DE RACHA
// ─────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        color: GDColors.streakLight,
        borderRadius: GDRadius.lgAll,
        border: Border.all(color: GDColors.streak.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(streak > 0 ? '🔥' : '💤', style: const TextStyle(fontSize: 36))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: streak > 0 ? 1.15 : 1.0,
                duration: 800.ms,
              ),
          const Gap(GDSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak > 0 ? '$streak días seguidos' : 'Sin racha activa',
                  style: GDTypography.headlineMedium.copyWith(
                    color: GDColors.streak,
                  ),
                ),
                Text(
                  streak > 0
                      ? '¡Sigue así, vas genial!'
                      : 'Abre la app mañana para empezar',
                  style: GDTypography.bodySmall.copyWith(
                    color: GDColors.streak.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TARJETA DE AUTONOMÍA
// ─────────────────────────────────────────────
class _AutonomyCard extends StatelessWidget {
  final int level;
  const _AutonomyCard({required this.level});

  @override
  Widget build(BuildContext context) {
    final label = AppConstants.autonomyLevelLabels[level - 1];
    final emoji = AppConstants.autonomyLevelEmojis[level - 1];

    return Container(
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        color: GDColors.surface,
        borderRadius: GDRadius.lgAll,
        border: Border.all(color: GDColors.primary.withValues(alpha: 0.12)),
        boxShadow: GDShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const Gap(GDSpacing.sm),
              Text('Nivel de autonomía', style: GDTypography.titleLarge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: GDSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: GDColors.primaryLight,
                  borderRadius: GDRadius.fullAll,
                ),
                child: Text(
                  '$level / 5',
                  style: GDTypography.labelSmall.copyWith(
                    color: GDColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Gap(GDSpacing.sm),
          Text(
            label,
            style: GDTypography.bodyMedium.copyWith(color: GDColors.primary),
          ),
          const Gap(GDSpacing.sm),
          ClipRRect(
            borderRadius: GDRadius.fullAll,
            child: LinearProgressIndicator(
              value: level / 5.0,
              minHeight: 8,
              backgroundColor: GDColors.primaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(GDColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TARJETA DE ACCESO RÁPIDO
// ─────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(GDSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: GDRadius.lgAll,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const Gap(GDSpacing.sm),
            Text(label, style: GDTypography.titleLarge),
          ],
        ),
      ),
    );
  }
}
