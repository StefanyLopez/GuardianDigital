import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../kid/providers/profile_provider.dart';
import '../../kid/models/profile_model.dart';
import '../../auth/providers/auth_provider.dart';

class GuardianHomeScreen extends ConsumerWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(familyProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panel familiar', style: GDTypography.headlineMedium),
            Text('Vista del cuidador', style: GDTypography.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: GDColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profiles) {
          if (profiles.isEmpty) {
            return _buildEmpty(context);
          }
          return ListView(
            padding: const EdgeInsets.all(GDSpacing.lg),
            children: [
              // Aviso de privacidad
              _buildPrivacyBanner().animate().fadeIn(),
              const Gap(GDSpacing.lg),

              Text('Perfiles activos', style: GDTypography.headlineMedium)
                  .animate().fadeIn(delay: 100.ms),
              const Gap(GDSpacing.md),

              ...profiles.asMap().entries.map((e) =>
                _ProfileCard(profile: e.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 200 + e.key * 100))
                    .slideY(begin: 0.2),
              ),

              const Gap(GDSpacing.lg),

              // Botón para cambiar a vista de menor
              if (profiles.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(activeProfileProvider.notifier).state = profiles.first;
                    context.go(AppRoutes.kidHome(profiles.first.id));
                  },
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: Text('Ver app de ${profiles.first.name}'),
                ).animate().fadeIn(delay: 400.ms),

              const Gap(GDSpacing.md),

              // Demo panel
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.demoPanel),
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text('Panel de demo 🧪'),
              ).animate().fadeIn(delay: 500.ms),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrivacyBanner() {
    return Container(
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        color: GDColors.primaryLight,
        borderRadius: GDRadius.lgAll,
        border: Border.all(color: GDColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: GDColors.primary, size: 20),
          const Gap(GDSpacing.sm),
          Expanded(
            child: Text(
              'Solo ves el resumen de bienestar. Las conversaciones con Luma son privadas.',
              style: GDTypography.bodySmall.copyWith(color: GDColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GDSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👨‍👩‍👧', style: TextStyle(fontSize: 64)),
            const Gap(GDSpacing.lg),
            Text('No hay perfiles aún', style: GDTypography.headlineLarge),
            const Gap(GDSpacing.sm),
            Text(
              'Crea un perfil de menor para empezar.',
              style: GDTypography.bodyLarge.copyWith(color: GDColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const Gap(GDSpacing.xl),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.onboarding),
              child: const Text('Crear perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final ProfileModel profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.kidHome(profile.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: GDSpacing.md),
        padding: const EdgeInsets.all(GDSpacing.md),
        decoration: BoxDecoration(
          color: GDColors.surface,
          borderRadius: GDRadius.lgAll,
          border: Border.all(color: GDColors.primary.withValues(alpha: 0.1)),
          boxShadow: GDShadows.sm,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: GDColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: GDColors.primary.withValues(alpha: 0.2), width: 2),
                  ),
                  child: Center(child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 26))),
                ),
                const Gap(GDSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: GDTypography.headlineMedium),
                      Text(
                        profile.ageRange == '8-12' ? '8–12 años' : '13–17 años',
                        style: GDTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: GDColors.textTertiary),
              ],
            ),
            const Gap(GDSpacing.md),
            // Stats del panel de sincronización
            Row(
              children: [
                Expanded(child: _SyncStat(
                  emoji: '🔥',
                  label: 'Racha',
                  value: '${profile.streakDays} días',
                )),
                Expanded(child: _SyncStat(
                  emoji: AppConstants.autonomyLevelEmojis[profile.autonomyLevel - 1],
                  label: 'Autonomía',
                  value: 'Nivel ${profile.autonomyLevel}',
                )),
                Expanded(child: _SyncStat(
                  emoji: '✅',
                  label: 'Estado',
                  value: profile.streakDays > 0 ? 'Activo' : 'Sin racha',
                  valueColor: profile.streakDays > 0 ? GDColors.success : GDColors.textTertiary,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStat extends StatelessWidget {
  final String emoji, label, value;
  final Color? valueColor;
  const _SyncStat({required this.emoji, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const Gap(2),
      Text(value, style: GDTypography.titleLarge.copyWith(
        color: valueColor ?? GDColors.textPrimary, fontSize: 13)),
      Text(label, style: GDTypography.bodySmall.copyWith(fontSize: 10)),
    ]);
  }
}
