import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/luma/luma_state.dart';
import '../../../core/luma/luma_avatar.dart';
import '../models/profile_model.dart';
import '../providers/profile_provider.dart';
import '../providers/chat_provider.dart';
import '../../../core/theme/theme_extension.dart';

class KidHomeScreen extends ConsumerWidget {
  final String profileId;
  const KidHomeScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(profileId));

    return profileAsync.when(
      loading: () => Scaffold(
          body: Center(
              child:
                  CircularProgressIndicator(color: context.gd.primary))),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const Gap(GDSpacing.md),
                  Text('Perfil no encontrado',
                      style: GDTypography.headlineMedium),
                  const Gap(GDSpacing.lg),
                  ElevatedButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Volver')),
                ],
              ),
            ),
          );
        }

        final lumaData = calculateLumaData(profile);
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
              // Botón de settings — abre Parental Gate antes
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Configuración',
                onPressed: () =>
                    context.push(AppRoutes.kidSettings(profileId)),
              ),
              if (kDebugMode)
                IconButton(
                  icon: const Icon(Icons.science_outlined),
                  onPressed: () => context.push(AppRoutes.demoPanel),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: GDSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(GDSpacing.md),

                  // Header
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$greeting, ${profile.name}!',
                              style: GDTypography.headlineLarge),
                          Text('Luma está aquí contigo.',
                              style: GDTypography.bodyMedium),
                        ],
                      ),
                    ),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: context.gd.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: context.gd.primary.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: Center(
                          child: Text(profile.avatarEmoji,
                              style: const TextStyle(fontSize: 22))),
                    ),
                  ]).animate().fadeIn().slideY(begin: -0.2),

                  const Gap(GDSpacing.xl),

                  // Luma central
                  _LumaCentralCard(profile: profile, lumaData: lumaData)
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .scale(begin: const Offset(0.9, 0.9)),

                  const Gap(GDSpacing.lg),

                  _StreakCard(streak: profile.streakDays)
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.2),

                  const Gap(GDSpacing.lg),

                  _LumaPointsCard(points: profile.lumaPoints)
                      .animate()
                      .fadeIn(delay: 380.ms)
                      .slideY(begin: 0.2),

                  const Gap(GDSpacing.lg),

                  _AutonomyCard(level: profile.autonomyLevel)
                      .animate()
                      .fadeIn(delay: 450.ms)
                      .slideY(begin: 0.2),

                  const Gap(GDSpacing.lg),

                  Text('Accesos rápidos', style: GDTypography.titleLarge)
                      .animate().fadeIn(delay: 500.ms),
                  const Gap(GDSpacing.md),

                  // Fila 1: logros + semana
                  Row(children: [
                    Expanded(child: _QuickCard(
                      emoji: '🏆',
                      label: 'Mis logros',
                      color: context.gd.gold,
                      onTap: () => context
                          .go(AppRoutes.achievements(profileId)),
                    )),
                    const Gap(GDSpacing.md),
                    Expanded(child: _QuickCard(
                      emoji: '📊',
                      label: 'Mi semana',
                      color: context.gd.secondary,
                      onTap: () =>
                          context.go(AppRoutes.stats(profileId)),
                    )),
                  ]).animate().fadeIn(delay: 600.ms),

                  const Gap(GDSpacing.md),

                  // Fila 2: focus (pomodoro + respiración)
                  _QuickCard(
                    emoji: '🧘',
                    label: 'Concentración y calma',
                    color: context.gd.success,
                    onTap: () =>
                        context.push(AppRoutes.focus(profileId)),
                  ).animate().fadeIn(delay: 650.ms),

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

// ── Widgets internos — sin cambios respecto al original ──────────────────────

class _LumaCentralCard extends ConsumerWidget {
  final ProfileModel profile;
  final LumaData lumaData;
  const _LumaCentralCard(
      {required this.profile, required this.lumaData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(chatNotifierProvider.notifier).initialize();
        context.go(AppRoutes.chat(profile.id));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: GDSpacing.xl, horizontal: GDSpacing.lg),
        decoration: BoxDecoration(
          gradient: context.gd.gradientPrimary,
          borderRadius: GDRadius.xlAll,
          boxShadow: context.gd.shadowLg,
        ),
        child: Column(children: [
          LumaAvatar(
              lumaData: lumaData,
              onTap: () {
                ref.read(chatNotifierProvider.notifier).initialize();
                context.go(AppRoutes.chat(profile.id));
              }),
          const Gap(GDSpacing.md),
          LumaStatusBanner(lumaData: lumaData),
          const Gap(GDSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: GDSpacing.lg, vertical: GDSpacing.sm + 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: GDRadius.fullAll,
            ),
            child: Text('Hablar con Luma →',
                textAlign: TextAlign.center,
                style: GDTypography.labelLarge
                    .copyWith(color: Colors.white, fontSize: 15)),
          ),
        ]),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        color: context.gd.streakLight,
        borderRadius: GDRadius.lgAll,
        border: Border.all(
            color: context.gd.streak.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Text(streak > 0 ? '🔥' : '💤',
                style: const TextStyle(fontSize: 36))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
                begin: 1.0,
                end: streak > 0 ? 1.15 : 1.0,
                duration: 800.ms),
        const Gap(GDSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              streak > 0
                  ? '$streak días seguidos'
                  : 'Sin racha activa',
              style: GDTypography.headlineMedium
                  .copyWith(color: context.gd.streak),
            ),
            Text(
              streak > 0
                  ? '¡Sigue así, vas genial!'
                  : 'Abre la app mañana para empezar',
              style: GDTypography.bodySmall.copyWith(
                  color: context.gd.streak.withValues(alpha: 0.8)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _LumaPointsCard extends StatelessWidget {
  final int points;
  const _LumaPointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        color: context.gd.successLight,
        borderRadius: GDRadius.lgAll,
        border: Border.all(
            color: context.gd.success.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Text('⭐', style: TextStyle(fontSize: 32)),
        const Gap(GDSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$points puntos',
                style: GDTypography.headlineMedium
                    .copyWith(color: context.gd.success)),
            Text('Completa retos para personalizar a Luma',
                style: GDTypography.bodySmall.copyWith(
                    color:
                        context.gd.success.withValues(alpha: 0.8))),
          ]),
        ),
        Icon(Icons.chevron_right_rounded,
            color: context.gd.success.withValues(alpha: 0.6)),
      ]),
    );
  }
}

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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: GDRadius.lgAll,
        border: Border.all(
            color: context.gd.primary.withValues(alpha: 0.12)),
        boxShadow: context.gd.shadowSm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const Gap(GDSpacing.sm),
          Text('Nivel de autonomía', style: GDTypography.titleLarge),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: GDSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
                color: context.gd.primaryLight,
                borderRadius: GDRadius.fullAll),
            child: Text('$level / 5',
                style: GDTypography.labelSmall.copyWith(
                    color: context.gd.primary, fontSize: 11)),
          ),
        ]),
        const Gap(GDSpacing.sm),
        Text(label,
            style: GDTypography.bodyMedium
                .copyWith(color: context.gd.primary)),
        const Gap(GDSpacing.sm),
        ClipRRect(
          borderRadius: GDRadius.fullAll,
          child: LinearProgressIndicator(
            value: level / 5.0,
            minHeight: 8,
            backgroundColor: context.gd.primaryLight,
            valueColor:
                AlwaysStoppedAnimation<Color>(context.gd.primary),
          ),
        ),
      ]),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;
  const _QuickCard(
      {required this.emoji,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GDSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: GDRadius.lgAll,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const Gap(GDSpacing.md),
          Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GDTypography.titleLarge.copyWith(color: color),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,)),
        ]),
      ),
    );
  }
}