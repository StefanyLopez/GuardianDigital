import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/widgets/intervention_banner.dart';
import '../../../core/luma/luma_state.dart';
import '../../../core/luma/luma_avatar.dart';
import '../../kid/providers/profile_provider.dart';
import '../../kid/providers/chat_provider.dart';
import '../../kid/services/achievement_service.dart';
import '../../kid/models/profile_model.dart';

class DemoPanelScreen extends ConsumerStatefulWidget {
  const DemoPanelScreen({super.key});

  @override
  ConsumerState<DemoPanelScreen> createState() => _DemoPanelScreenState();
}

class _DemoPanelScreenState extends ConsumerState<DemoPanelScreen> {
  double _screenTimeMinutes = 20;
  String _lastAction = 'Ninguna acción aún';
  bool _isLoading = false;

  // ── Actualiza perfil en Supabase e invalida providers en tiempo real ───────
  Future<void> _updateProfile(
    ProfileModel profile,
    Map<String, dynamic> updates,
    String actionLabel,
  ) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client
          .from(AppConstants.tableProfiles)
          .update(updates)
          .eq('id', profile.id);

      // Invalida ambos providers para refrescar UI en tiempo real
      ref.invalidate(profileByIdProvider(profile.id));
      ref.invalidate(familyProfilesProvider);

      // Evaluar insignias con perfil actualizado
      final updatedProfile = profile.copyWith(
        streakDays:    updates['streak_days']     ?? profile.streakDays,
        autonomyLevel: updates['autonomy_level']  ?? profile.autonomyLevel,
        lumaPoints:    updates['luma_points']     ?? profile.lumaPoints,
        hadNightUsage: updates['had_night_usage'] ?? profile.hadNightUsage,
      );
      final unlocked = await AchievementService.evaluate(updatedProfile);

      setState(() {
        _lastAction = unlocked.isNotEmpty
            ? '$actionLabel ✅\n🏅 Insignia desbloqueada!'
            : '$actionLabel ✅';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastAction = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    final c = context.gd;

    final lumaData = profile != null
        ? calculateLumaData(profile)
        : const LumaData(
            state: LumaState.normal,
            evolution: LumaEvolution.sprout,
            bodyColor: LumaBodyColor.mint,
            accessory: LumaAccessory.none,
            eyes: LumaEyes.normal,
          );

    final overThreshold =
        _screenTimeMinutes >= AppConstants.screenTimeThresholdMinutes;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Row(children: [
          const Text('🧪', style: TextStyle(fontSize: 20)),
          const Gap(GDSpacing.sm),
          Text('Panel de demo', style: GDTypography.headlineMedium),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GDSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── AVISO ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(GDSpacing.md),
              decoration: BoxDecoration(
                color: c.warningLight,
                borderRadius: GDRadius.lgAll,
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: c.warning, size: 18),
                const Gap(GDSpacing.sm),
                Expanded(child: Text(
                  'Solo visible en modo desarrollo. Todos los cambios se guardan en Supabase y se reflejan en tiempo real.',
                  style: GDTypography.bodySmall.copyWith(color: c.warning),
                )),
              ]),
            ),

            const Gap(GDSpacing.lg),

            // ── PREVIEW DE LUMA EN TIEMPO REAL ─────────────────────────────
            const _SectionTitle(title: '✨ Estado actual de Luma'),
            const Gap(GDSpacing.md),
            Container(
              padding: const EdgeInsets.all(GDSpacing.lg),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: GDRadius.lgAll,
                border: Border.all(color: c.border),
              ),
              child: Column(children: [
                LumaAvatar(lumaData: lumaData, size: 110),
                const Gap(GDSpacing.md),
                LumaStatusBanner(lumaData: lumaData),
                const Gap(GDSpacing.md),
                if (profile != null) Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatChip(label: 'Racha',    value: '${profile.streakDays}d',      emoji: '🔥'),
                    _StatChip(label: 'Nivel',    value: '${profile.autonomyLevel}/5',  emoji: '⭐'),
                    _StatChip(label: 'Puntos',   value: '${profile.lumaPoints}',       emoji: '💎'),
                    _StatChip(label: 'Estado',   value: lumaData.stateName,            emoji: ''),
                  ],
                ),
              ]),
            ),

            const Gap(GDSpacing.lg),

            // ── PERFIL ACTIVO ───────────────────────────────────────────────
            const _SectionTitle(title: '👤 Perfil activo'),
            const Gap(GDSpacing.sm),
            Container(
              padding: const EdgeInsets.all(GDSpacing.md),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: GDRadius.lgAll,
              ),
              child: profile == null
                  ? Text(
                      'Sin perfil activo. Navega al home del menor primero.',
                      style: GDTypography.bodyMedium.copyWith(color: c.textSecondary),
                    )
                  : Row(children: [
                      Text(profile.avatarEmoji, style: const TextStyle(fontSize: 28)),
                      const Gap(GDSpacing.md),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name,
                              style: GDTypography.titleLarge.copyWith(color: c.textPrimary)),
                          Text('${profile.ageRange} · ${profile.isTeen ? "Adolescente" : "Niño/a"}',
                              style: GDTypography.bodySmall.copyWith(color: c.textSecondary)),
                        ],
                      )),
                    ]),
            ),

            if (profile != null) ...[
              const Gap(GDSpacing.lg),

              // ── RACHA ─────────────────────────────────────────────────────
              const _SectionTitle(title: '🔥 Racha de días'),
              const Gap(GDSpacing.sm),
              Text('Racha actual: ${profile.streakDays} días',
                  style: GDTypography.bodyMedium.copyWith(color: c.textPrimary)),
              const Gap(GDSpacing.sm),
              Row(children: [
                Expanded(child: _ActionButton(
                  label: '+1 día',
                  icon: Icons.add_rounded,
                  color: c.success,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'streak_days': profile.streakDays + 1,
                     'last_active': DateTime.now().toIso8601String()},
                    'Racha → ${profile.streakDays + 1} días'),
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: '+3 días',
                  icon: Icons.fast_forward_rounded,
                  color: c.success,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'streak_days': profile.streakDays + 3,
                     'last_active': DateTime.now().toIso8601String()},
                    'Racha → ${profile.streakDays + 3} días'),
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: 'Racha 7',
                  icon: Icons.star_rounded,
                  color: c.warning,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'streak_days': 7,
                     'last_active': DateTime.now().toIso8601String()},
                    'Racha → 7 días'),
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: 'Reset',
                  icon: Icons.refresh_rounded,
                  color: c.error,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'streak_days': 0}, 'Racha → 0'),
                )),
              ]),

              const Gap(GDSpacing.lg),

              // ── NIVEL DE AUTONOMÍA ────────────────────────────────────────
              const _SectionTitle(title: '⭐ Nivel de autonomía'),
              const Gap(GDSpacing.sm),
              Text(
                'Nivel actual: ${profile.autonomyLevel}/5 · ${AppConstants.autonomyLevelLabels[profile.autonomyLevel - 1]}',
                style: GDTypography.bodyMedium.copyWith(color: c.textPrimary),
              ),
              const Gap(GDSpacing.sm),
              Row(
                children: List.generate(5, (i) {
                  final lvl = i + 1;
                  final isActive = profile.autonomyLevel == lvl;
                  return Expanded(child: Padding(
                    padding: EdgeInsets.only(right: i < 4 ? GDSpacing.xs : 0),
                    child: _ActionButton(
                      label: 'N$lvl',
                      icon: isActive ? Icons.circle : Icons.circle_outlined,
                      color: isActive ? c.primary : c.textTertiary,
                      isLoading: _isLoading,
                      onTap: () => _updateProfile(profile,
                        {'autonomy_level': lvl}, 'Nivel → $lvl'),
                    ),
                  ));
                }),
              ),

              const Gap(GDSpacing.lg),

              // ── PUNTOS LUMA ───────────────────────────────────────────────
              const _SectionTitle(title: '💎 Puntos de Luma'),
              const Gap(GDSpacing.sm),
              Text('Puntos actuales: ${profile.lumaPoints}',
                  style: GDTypography.bodyMedium.copyWith(color: c.textPrimary)),
              const Gap(GDSpacing.sm),
              Row(children: [
                Expanded(child: _ActionButton(
                  label: '+10',
                  icon: Icons.add_rounded,
                  color: c.primary,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'luma_points': profile.lumaPoints + 10}, '+10 puntos'),
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: '+25',
                  icon: Icons.add_circle_rounded,
                  color: c.primary,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'luma_points': profile.lumaPoints + 25}, '+25 puntos'),
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: '+50',
                  icon: Icons.stars_rounded,
                  color: c.warning,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'luma_points': profile.lumaPoints + 50}, '+50 puntos'),
                )),
                const Gap(GDSpacing.sm),
                // +100 para llegar rápido a la tienda en demo
                Expanded(child: _ActionButton(
                  label: '+100',
                  icon: Icons.diamond_rounded,
                  color: c.gold,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'luma_points': profile.lumaPoints + 100}, '+100 puntos'),
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: 'Reset',
                  icon: Icons.refresh_rounded,
                  color: c.error,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile,
                    {'luma_points': 0}, 'Puntos → 0'),
                )),
              ]),

              const Gap(GDSpacing.lg),

              // ── ESTADOS DE LUMA ───────────────────────────────────────────
              // Cada botón combina los valores de perfil necesarios para
              // que calculateLumaData() devuelva el estado deseado.
              const _SectionTitle(title: '🌟 Forzar estado de Luma'),
              const Gap(GDSpacing.sm),
              Text(
                'Estado actual: ${lumaData.stateName} · ${lumaData.evolutionName}',
                style: GDTypography.bodyMedium.copyWith(color: c.textPrimary),
              ),
              const Gap(GDSpacing.sm),
              Wrap(
                spacing: GDSpacing.sm,
                runSpacing: GDSpacing.sm,
                children: [
                  _ActionButton(
                    label: '😴 Dormida',
                    icon: Icons.bedtime_rounded,
                    color: const Color(0xFF8BAAC0),
                    isLoading: _isLoading,
                    onTap: () => _updateProfile(profile, {
                      'last_active': DateTime.now()
                          .subtract(const Duration(hours: 50))
                          .toIso8601String(),
                      'had_night_usage': false,
                      'streak_days': 0,
                    }, '→ Luma sleeping'),
                  ),
                  _ActionButton(
                    label: '😪 Cansada',
                    icon: Icons.nightlight_rounded,
                    color: Colors.grey,
                    isLoading: _isLoading,
                    onTap: () => _updateProfile(profile, {
                      'had_night_usage': true,
                      'last_active': DateTime.now().toIso8601String(),
                    }, '→ Luma tired'),
                  ),
                  _ActionButton(
                    label: '🌿 Normal',
                    icon: Icons.sentiment_neutral_rounded,
                    color: c.success,
                    isLoading: _isLoading,
                    onTap: () => _updateProfile(profile, {
                      'had_night_usage': false,
                      'streak_days': 0,
                      'last_active': DateTime.now().toIso8601String(),
                    }, '→ Luma normal'),
                  ),
                  _ActionButton(
                    label: '😊 Contenta',
                    icon: Icons.sentiment_satisfied_rounded,
                    color: c.success,
                    isLoading: _isLoading,
                    onTap: () => _updateProfile(profile, {
                      'had_night_usage': false,
                      'streak_days': 1,
                      'last_active': DateTime.now().toIso8601String(),
                    }, '→ Luma happy'),
                  ),
                  _ActionButton(
                    label: '🎉 Emocionada',
                    icon: Icons.celebration_rounded,
                    color: c.secondary,
                    isLoading: _isLoading,
                    onTap: () => _updateProfile(profile, {
                      'had_night_usage': false,
                      'streak_days': 3,
                      'last_active': DateTime.now().toIso8601String(),
                    }, '→ Luma excited'),
                  ),
                  _ActionButton(
                    label: '✨ Brillando',
                    icon: Icons.auto_awesome_rounded,
                    color: c.gold,
                    isLoading: _isLoading,
                    onTap: () => _updateProfile(profile, {
                      'had_night_usage': false,
                      'streak_days': 7,
                      'autonomy_level': 3,
                      'last_active': DateTime.now().toIso8601String(),
                    }, '→ Luma glowing'),
                  ),
                ],
              ),

              const Gap(GDSpacing.lg),

              // ── EVOLUCIÓN DE LUMA ─────────────────────────────────────────
              const _SectionTitle(title: '🌱 Forzar evolución de Luma'),
              const Gap(GDSpacing.sm),
              Row(children: [
                Expanded(child: _ActionButton(
                  label: '🌱 Brote',
                  icon: Icons.eco_rounded,
                  color: c.success,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile, {
                    'autonomy_level': 1,
                    'streak_days': 0,
                  }, '→ Luma sprout'),
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: '✨ Pequeña',
                  icon: Icons.stars_rounded,
                  color: c.primary,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile, {
                    'autonomy_level': 3,
                    'streak_days': 3,
                  }, '→ Luma growing'),
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: '🌟 Guardian',
                  icon: Icons.auto_awesome_rounded,
                  color: c.gold,
                  isLoading: _isLoading,
                  onTap: () => _updateProfile(profile, {
                    'autonomy_level': 4,
                    'streak_days': 7,
                    'had_night_usage': false,
                    'last_active': DateTime.now().toIso8601String(),
                  }, '→ Luma guardian'),
                )),
              ]),

              const Gap(GDSpacing.lg),

              // ── INSIGNIAS ─────────────────────────────────────────────────
              const _SectionTitle(title: '🏅 Forzar evaluación de insignias'),
              const Gap(GDSpacing.sm),
              Text(
                'Evalúa todas las condiciones del perfil actual y desbloquea las que correspondan.',
                style: GDTypography.bodyMedium.copyWith(color: c.textSecondary),
              ),
              const Gap(GDSpacing.sm),
              _ActionButton(
                label: 'Evaluar insignias ahora',
                icon: Icons.emoji_events_rounded,
                color: c.gold,
                isLoading: _isLoading,
                fullWidth: true,
                onTap: () async {
                  setState(() => _isLoading = true);
                  final unlocked = await AchievementService.evaluate(profile);
                  ref.invalidate(profileByIdProvider(profile.id));
                  setState(() {
                    _isLoading = false;
                    _lastAction = unlocked.isEmpty
                        ? 'Evaluación completada — sin insignias nuevas'
                        : '🏅 ${unlocked.length} insignia(s) desbloqueada(s)!';
                  });
                },
              ),

              const Gap(GDSpacing.lg),

              // ── TRIGGER TIEMPO EN PANTALLA ────────────────────────────────
              const _SectionTitle(title: '📱 Trigger — Tiempo en pantalla'),
              const Gap(GDSpacing.sm),
              Text(
                'Simular: ${_screenTimeMinutes.round()} min ${overThreshold ? "⚠️ Umbral superado" : ""}',
                style: GDTypography.bodyMedium.copyWith(
                  color: overThreshold ? c.warning : c.textPrimary),
              ),
              Slider(
                value: _screenTimeMinutes,
                min: 0, max: 90, divisions: 18,
                label: '${_screenTimeMinutes.round()} min',
                onChanged: (v) => setState(() => _screenTimeMinutes = v),
              ),
              Row(children: [
                Expanded(child: _ActionButton(
                  label: 'Banner',
                  icon: Icons.notifications_outlined,
                  color: c.warning,
                  isLoading: false,
                  onTap: overThreshold ? () {
                    ref.read(interventionBannerProvider.notifier)
                        .triggerScreenTime(npcName: profile.name);
                    setState(() => _lastAction = '✅ Banner de intervención mostrado');
                  } : null,
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: 'Push',
                  icon: Icons.send_outlined,
                  color: c.primary,
                  isLoading: false,
                  onTap: overThreshold ? () async {
                    await NotificationService.sendScreenTimeAlert();
                    setState(() => _lastAction = '✅ Push enviado');
                  } : null,
                )),
              ]),

              const Gap(GDSpacing.lg),

              // ── CHAT ──────────────────────────────────────────────────────
              const _SectionTitle(title: '💬 Chat y sesión'),
              const Gap(GDSpacing.sm),
              Row(children: [
                Expanded(child: _ActionButton(
                  label: 'Desbloquear sesión',
                  icon: Icons.lock_open_rounded,
                  color: c.success,
                  isLoading: false,
                  onTap: () {
                    ref.read(chatNotifierProvider.notifier).unlockSession();
                    setState(() => _lastAction = '✅ Sesión de chat desbloqueada');
                  },
                )),
                const Gap(GDSpacing.sm),
                Expanded(child: _ActionButton(
                  label: 'Limpiar chat',
                  icon: Icons.delete_outline,
                  color: c.error,
                  isLoading: false,
                  onTap: () async {
                    await ref.read(chatNotifierProvider.notifier).clearHistory();
                    setState(() => _lastAction = '✅ Historial de chat limpiado');
                  },
                )),
              ]),

              const Gap(GDSpacing.lg),

              // ── RESET COMPLETO ────────────────────────────────────────────
              const _SectionTitle(title: '🗑️ Reset completo para demo limpia'),
              const Gap(GDSpacing.sm),
              _ActionButton(
                label: 'Reset a estado inicial',
                icon: Icons.restart_alt_rounded,
                color: c.error,
                isLoading: _isLoading,
                fullWidth: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('¿Reset completo?'),
                      content: const Text(
                          'Resetea racha, nivel, puntos y uso nocturno a cero. No borra el historial de chat.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Resetear',
                                style: TextStyle(color: context.gd.error))),
                      ],
                    ),
                  );
                  if (confirm != true || !mounted) return;
                  await _updateProfile(profile, {
                    'streak_days': 0,
                    'autonomy_level': 1,
                    'luma_points': 0,
                    'had_night_usage': false,
                    'last_active': DateTime.now().toIso8601String(),
                  }, 'Reset completo aplicado');
                  await ref.read(chatNotifierProvider.notifier).clearHistory();
                },
              ),
            ],

            const Gap(GDSpacing.xl),

            // ── LOG DE ÚLTIMA ACCIÓN ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GDSpacing.md),
              decoration: BoxDecoration(
                color: context.gd.textPrimary,
                borderRadius: GDRadius.lgAll,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Última acción',
                    style: GDTypography.labelSmall.copyWith(color: Colors.white54)),
                const Gap(4),
                Text(_lastAction,
                    style: GDTypography.bodyMedium.copyWith(color: Colors.white)),
              ]),
            ),

            const Gap(GDSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS AUXILIARES ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) =>
      Text(title, style: GDTypography.headlineMedium);
}

class _StatChip extends StatelessWidget {
  final String label, value, emoji;
  const _StatChip({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final c = context.gd;
    return Column(children: [
      if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 16)),
      Text(value, style: GDTypography.titleLarge.copyWith(color: c.textPrimary)),
      Text(label, style: GDTypography.bodySmall.copyWith(color: c.textTertiary)),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool fullWidth;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gd;
    final enabled = onTap != null && !isLoading;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
            vertical: GDSpacing.sm + 2, horizontal: GDSpacing.sm),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.12)
              : c.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: GDRadius.mdAll,
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: enabled ? color : c.textTertiary, size: 20),
          const Gap(2),
          Text(
            label,
            style: GDTypography.bodySmall.copyWith(
              color: enabled ? color : c.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}