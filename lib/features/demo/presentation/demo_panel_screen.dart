import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/widgets/intervention_banner.dart';
import '../../kid/providers/profile_provider.dart';
import '../../kid/providers/chat_provider.dart';

class DemoPanelScreen extends ConsumerStatefulWidget {
  const DemoPanelScreen({super.key});

  @override
  ConsumerState<DemoPanelScreen> createState() => _DemoPanelScreenState();
}

class _DemoPanelScreenState extends ConsumerState<DemoPanelScreen> {
  double _screenTimeMinutes = 20;
  bool _nightUsageSimulated = false;
  String _lastAction = 'Ninguna acción aún';

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    const screenTimeThreshold = 45.0;
    final overThreshold = _screenTimeMinutes >= screenTimeThreshold;

    return Scaffold(
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
            // Info
            Container(
              padding: const EdgeInsets.all(GDSpacing.md),
              decoration: BoxDecoration(
                color: GDColors.warningLight,
                borderRadius: GDRadius.lgAll,
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: GDColors.warning, size: 18),
                const Gap(GDSpacing.sm),
                Expanded(child: Text(
                  'Solo visible en modo desarrollo. Simula triggers de fricción para la demo.',
                  style: GDTypography.bodySmall.copyWith(color: GDColors.warning),
                )),
              ]),
            ),
            const Gap(GDSpacing.lg),

            // Perfil activo
            const _SectionTitle(title: '👤 Perfil activo'),
            const Gap(GDSpacing.sm),
            Container(
              padding: const EdgeInsets.all(GDSpacing.md),
              decoration: BoxDecoration(
                color: GDColors.surfaceVariant,
                borderRadius: GDRadius.lgAll,
              ),
              child: Row(children: [
                Text(profile?.avatarEmoji ?? '?', style: const TextStyle(fontSize: 28)),
                const Gap(GDSpacing.md),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile?.name ?? 'Sin perfil', style: GDTypography.titleLarge),
                  Text('${profile?.ageRange ?? '-'} · Nivel ${profile?.autonomyLevel ?? 1} · Racha ${profile?.streakDays ?? 0} días',
                    style: GDTypography.bodySmall),
                ]),
              ]),
            ),

            const Gap(GDSpacing.lg),

            // ── TRIGGER 1: Tiempo en pantalla
            const _SectionTitle(title: '📱 Trigger 1 — Tiempo en pantalla'),
            const Gap(GDSpacing.sm),
            Text(
              'Simula minutos de uso: ${_screenTimeMinutes.round()} min ${overThreshold ? "⚠️ Umbral superado" : ""}',
              style: GDTypography.bodyMedium.copyWith(
                color: overThreshold ? GDColors.warning : GDColors.textPrimary,
              ),
            ),
            Slider(
              value: _screenTimeMinutes,
              min: 0, max: 90,
              divisions: 18,
              activeColor: overThreshold ? GDColors.warning : GDColors.primary,
              label: '${_screenTimeMinutes.round()} min',
              onChanged: (v) => setState(() => _screenTimeMinutes = v),
            ),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: overThreshold ? () {
                    ref.read(interventionBannerProvider.notifier).triggerScreenTime(
                      npcName: profile?.name ?? 'Luma',
                    );
                    setState(() => _lastAction = '✅ Banner de tiempo de pantalla activado');
                  } : null,
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  label: const Text('Mostrar banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GDColors.warning,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const Gap(GDSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: overThreshold ? () async {
                    await NotificationService.sendScreenTimeAlert();
                    setState(() => _lastAction = '✅ Push de tiempo de pantalla enviado');
                  } : null,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Enviar push'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ]),

            const Gap(GDSpacing.lg),

            // ── TRIGGER 3: Uso nocturno
            const _SectionTitle(title: '🌙 Trigger 3 — Uso nocturno'),
            const Gap(GDSpacing.sm),
            Text(
              'Simula que el usuario usó el celular después de las 10pm.',
              style: GDTypography.bodyMedium,
            ),
            const Gap(GDSpacing.sm),
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService.scheduleNightUsageFollowUp();
                setState(() {
                  _nightUsageSimulated = true;
                  _lastAction = '✅ Push nocturno programado para mañana temprano';
                });
              },
              icon: const Icon(Icons.bedtime_outlined, size: 18),
              label: const Text('Programar push de seguimiento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B48FF),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            if (_nightUsageSimulated) ...[
              const Gap(GDSpacing.sm),
              Text('📅 Push programado para mañana',
                style: GDTypography.bodySmall.copyWith(color: GDColors.success)),
            ],

            const Gap(GDSpacing.lg),

            // ── TRIGGER 5: Inactividad
            const _SectionTitle(title: '😴 Trigger 5 — Inactividad 48h'),
            const Gap(GDSpacing.sm),
            Text(
              'Simula que el usuario no abrió la app en 2 días.',
              style: GDTypography.bodyMedium,
            ),
            const Gap(GDSpacing.sm),
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService.sendInactivityAlert();
                setState(() => _lastAction = '✅ Push de reencuentro enviado');
              },
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: const Text('Enviar push de inactividad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GDColors.secondary,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),

            const Gap(GDSpacing.lg),

            // ── Avanzar día
            const _SectionTitle(title: '📅 Simular avance de tiempo'),
            const Gap(GDSpacing.sm),
            Text('Incrementa la racha del perfil activo en 1 día.',
              style: GDTypography.bodyMedium),
            const Gap(GDSpacing.sm),
            OutlinedButton.icon(
              onPressed: profile == null ? null : () async {
                await ref.read(profileNotifierProvider.notifier)
                    .updateStreak(profile.id, profile.streakDays + 1);
                ref.invalidate(familyProfilesProvider);
                setState(() => _lastAction = '✅ Racha incrementada a ${profile.streakDays + 1} días');
              },
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Avanzar 1 día'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),

            const Gap(GDSpacing.lg),

            // ── Limpiar chat
            const _SectionTitle(title: '🗑️ Utilidades'),
            const Gap(GDSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(chatNotifierProvider.notifier).clearHistory();
                setState(() => _lastAction = '✅ Historial de chat limpiado');
              },
              icon: const Icon(Icons.delete_outline, color: GDColors.error),
              label: const Text('Limpiar historial de chat',
                style: TextStyle(color: GDColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: GDColors.error),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),

            const Gap(GDSpacing.xl),

            // ── Log de última acción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GDSpacing.md),
              decoration: BoxDecoration(
                color: GDColors.textPrimary,
                borderRadius: GDRadius.lgAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Última acción',
                    style: GDTypography.labelSmall.copyWith(color: Colors.white54)),
                  const Gap(4),
                  Text(_lastAction,
                    style: GDTypography.bodyMedium.copyWith(color: Colors.white)),
                ],
              ),
            ),

            const Gap(GDSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: GDTypography.headlineMedium);
  }
}
