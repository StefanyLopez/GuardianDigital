import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

// ─────────────────────────────────────────────
//  ESTADO DEL BANNER
// ─────────────────────────────────────────────
class InterventionBannerState {
  final bool visible;
  final String message;
  final InterventionType type;

  const InterventionBannerState({
    this.visible = false,
    this.message = '',
    this.type = InterventionType.screenTime,
  });

  InterventionBannerState copyWith({
    bool? visible,
    String? message,
    InterventionType? type,
  }) {
    return InterventionBannerState(
      visible: visible ?? this.visible,
      message: message ?? this.message,
      type: type ?? this.type,
    );
  }
}

enum InterventionType { screenTime, challenge, offline, inactivity }

// ─────────────────────────────────────────────
//  PROVIDER DEL BANNER
// ─────────────────────────────────────────────
final interventionBannerProvider =
    StateNotifierProvider<InterventionBannerNotifier, InterventionBannerState>(
  (ref) => InterventionBannerNotifier(),
);

class InterventionBannerNotifier
    extends StateNotifier<InterventionBannerState> {
  InterventionBannerNotifier() : super(const InterventionBannerState());

  Timer? _autoDismissTimer;

  void show({
    required String message,
    required InterventionType type,
    Duration autoDismiss = const Duration(seconds: 6),
  }) {
    _autoDismissTimer?.cancel();
    state = state.copyWith(visible: true, message: message, type: type);

    _autoDismissTimer = Timer(autoDismiss, dismiss);
  }

  void dismiss() {
    _autoDismissTimer?.cancel();
    state = state.copyWith(visible: false);
  }

  // Disparadores por tipo de trigger
  void triggerScreenTime({String npcName = 'Luma'}) {
    show(
      message: 'Llevas un rato en pantalla. ¿Hablamos un momento?',
      type: InterventionType.screenTime,
    );
  }

  void triggerChallenge({String npcName = 'Luma'}) {
    show(
      message: 'Tengo un reto para ti. ¿Te animas?',
      type: InterventionType.challenge,
    );
  }

  void triggerOffline({String npcName = 'Luma'}) {
    show(
      message: '¿Qué tal descansar un momento de la pantalla?',
      type: InterventionType.offline,
    );
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
//  WIDGET DEL BANNER
// ─────────────────────────────────────────────
class InterventionBanner extends ConsumerWidget {
  const InterventionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerState = ref.watch(interventionBannerProvider);

    if (!bannerState.visible) return const SizedBox.shrink();

    return Animate(
      effects: const [
        SlideEffect(
          begin: Offset(0, -1),
          end: Offset(0, 0),
          duration: Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        ),
        FadeEffect(duration: Duration(milliseconds: 300)),
      ],
      child: _BannerContent(state: bannerState),
    );
  }
}

class _BannerContent extends ConsumerWidget {
  final InterventionBannerState state;
  const _BannerContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(interventionBannerProvider.notifier);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        GDSpacing.md,
        GDSpacing.sm,
        GDSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        color: GDColors.surface,
        borderRadius: GDRadius.lgAll,
        border: Border.all(
          color: GDColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: GDShadows.md,
      ),
      child: Padding(
        padding: const EdgeInsets.all(GDSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar NPC
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: GDColors.gradientPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: GDSpacing.sm),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Luma',
                    style: GDTypography.labelLarge.copyWith(
                      color: GDColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.message,
                    style: GDTypography.bodyMedium.copyWith(
                      color: GDColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: GDSpacing.sm),
                  Row(
                    children: [
                      _ActionChip(
                        label: 'Hablar con Luma',
                        isPrimary: true,
                        onTap: () {
                          notifier.dismiss();
                          // Navigate to chat - profileId handled by shell
                          final uri = GoRouterState.of(context).uri.toString();
                          final match = RegExp(r'/kid/([^/]+)').firstMatch(uri);
                          final pid = match?.group(1) ?? '';
                          if (pid.isNotEmpty) context.go(AppRoutes.chat(pid));
                        },
                      ),
                      const SizedBox(width: GDSpacing.sm),
                      _ActionChip(
                        label: 'Ahora no',
                        isPrimary: false,
                        onTap: notifier.dismiss,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cerrar
            GestureDetector(
              onTap: notifier.dismiss,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: GDColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GDSpacing.md,
          vertical: GDSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? GDColors.primary : GDColors.surfaceVariant,
          borderRadius: GDRadius.fullAll,
        ),
        child: Text(
          label,
          style: GDTypography.labelSmall.copyWith(
            color: isPrimary ? Colors.white : GDColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
