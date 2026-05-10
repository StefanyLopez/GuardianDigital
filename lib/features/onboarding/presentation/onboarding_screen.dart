import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../kid/providers/profile_provider.dart';
import '../../../core/theme/theme_extension.dart';

// ─────────────────────────────────────────────
//  ONBOARDING SCREEN — 5 pasos
//  Paso 1: Bienvenida + NPC
//  Paso 2: ¿Eres papá/mamá o el menor?
//  Paso 3: Nombre del menor
//  Paso 4: Edad y avatar
//  Paso 5: Metas iniciales
// ─────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Datos recolectados
  bool _isGuardian = true;
  final _nameCtrl = TextEditingController();
  String _ageRange = AppConstants.ageRangeKid;
  int _selectedAvatar = 0;
  final Set<String> _selectedGoals = {};

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    final profile = await ref.read(profileNotifierProvider.notifier).createProfile(
      name: _nameCtrl.text.trim(),
      ageRange: _ageRange,
      avatarId: _selectedAvatar,
      goals: _selectedGoals.toList(),
    );

    if (!mounted) return;
    if (profile == null) return;
    context.go(_isGuardian ? AppRoutes.guardianHome : AppRoutes.kidHome(profile.id));
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 2:
        return _nameCtrl.text.trim().isNotEmpty;
      case 4:
        return _selectedGoals.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _ProgressBar(current: _currentPage, total: 5),

            // Páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _UserTypePage(
                    isGuardian: _isGuardian,
                    onChanged: (v) => setState(() => _isGuardian = v),
                    onNext: _nextPage,
                  ),
                  _NamePage(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    onNext: _canProceed() ? _nextPage : null,
                  ),
                  _AgeAvatarPage(
                    ageRange: _ageRange,
                    selectedAvatar: _selectedAvatar,
                    onAgeChanged: (v) => setState(() => _ageRange = v),
                    onAvatarChanged: (v) => setState(() => _selectedAvatar = v),
                    onNext: _nextPage,
                  ),
                  _GoalsPage(
                    selectedGoals: _selectedGoals,
                    onToggle: (id) => setState(() {
                      if (_selectedGoals.contains(id)) {
                        _selectedGoals.remove(id);
                      } else if (_selectedGoals.length < 3) {
                        _selectedGoals.add(id);
                      }
                    }),
                    onFinish: _canProceed() ? _finish : null,
                  ),
                ],
              ),
            ),

            // Botón atrás (excepto primera página)
            if (_currentPage > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: GDSpacing.md),
                child: TextButton(
                  onPressed: _prevPage,
                  child: const Text('← Atrás'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BARRA DE PROGRESO
// ─────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          GDSpacing.lg, GDSpacing.md, GDSpacing.lg, 0),
      child: Row(
        children: List.generate(total, (i) {
          final isActive = i <= current;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? context.gd.primary : context.gd.surfaceVariant,
                borderRadius: GDRadius.fullAll,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PASO 1 — BIENVENIDA
// ─────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GDSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: context.gd.gradientPrimary,
              shape: BoxShape.circle,
              boxShadow: context.gd.shadowLg,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 56)),
            ),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .shimmer(delay: 800.ms, duration: 1200.ms),

          const Gap(GDSpacing.xl),

          Text(
            'Hola, soy Luma',
            style: GDTypography.displayLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

          const Gap(GDSpacing.md),

          Text(
            'Soy tu compañero digital.\nEstoy aquí para acompañarte, no para vigilarte.',
            style: GDTypography.bodyLarge.copyWith(
              color: context.gd.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),

          const Gap(GDSpacing.xxl),

          ElevatedButton(
            onPressed: onNext,
            child: const Text('Conocerte 👋'),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PASO 2 — TIPO DE USUARIO
// ─────────────────────────────────────────────
class _UserTypePage extends StatelessWidget {
  final bool isGuardian;
  final ValueChanged<bool> onChanged;
  final VoidCallback onNext;

  const _UserTypePage({
    required this.isGuardian,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GDSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Quién va a usar Guardian Digital?',
            style: GDTypography.headlineLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn().slideY(begin: 0.3),

          const Gap(GDSpacing.xl),

          _TypeCard(
            emoji: '👨‍👩‍👧',
            title: 'Soy papá, mamá o cuidador',
            subtitle: 'Quiero acompañar a mi hijo/a',
            isSelected: isGuardian,
            onTap: () => onChanged(true),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),

          const Gap(GDSpacing.md),

          _TypeCard(
            emoji: '🧒',
            title: 'Soy yo quien lo va a usar',
            subtitle: 'Quiero mejorar mis hábitos digitales',
            isSelected: !isGuardian,
            onTap: () => onChanged(false),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),

          const Gap(GDSpacing.xl),

          ElevatedButton(
            onPressed: onNext,
            child: const Text('Continuar'),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(GDSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? context.gd.primaryLight : context.gd.surface,
          borderRadius: GDRadius.lgAll,
          border: Border.all(
            color: isSelected ? context.gd.primary : context.gd.surfaceVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? context.gd.shadowSm : [],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const Gap(GDSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GDTypography.titleLarge),
                  Text(subtitle, style: GDTypography.bodyMedium),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: context.gd.primary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PASO 3 — NOMBRE DEL MENOR
// ─────────────────────────────────────────────
class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onNext;

  const _NamePage({
    required this.controller,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GDSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo se llama?',
            style: GDTypography.displayMedium,
          ).animate().fadeIn().slideY(begin: 0.3),

          const Gap(GDSpacing.xs),

          Text(
            'Solo el nombre, nada más.',
            style: GDTypography.bodyLarge.copyWith(
              color: context.gd.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms),

          const Gap(GDSpacing.xl),

          TextField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onNext?.call(),
            style: GDTypography.headlineLarge,
            decoration: const InputDecoration(
              hintText: 'Nombre',
              prefixIcon: Icon(Icons.person_outline),
            ),
            autofocus: true,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const Gap(GDSpacing.xl),

          ElevatedButton(
            onPressed: onNext,
            child: const Text('Continuar'),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PASO 4 — EDAD Y AVATAR
// ─────────────────────────────────────────────
class _AgeAvatarPage extends StatelessWidget {
  final String ageRange;
  final int selectedAvatar;
  final ValueChanged<String> onAgeChanged;
  final ValueChanged<int> onAvatarChanged;
  final VoidCallback onNext;

  const _AgeAvatarPage({
    required this.ageRange,
    required this.selectedAvatar,
    required this.onAgeChanged,
    required this.onAvatarChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final avatarEmojis = ['🦁', '🐼', '🦊', '🐬', '🦋', '🌟'];

    return Padding(
      padding: const EdgeInsets.all(GDSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cuántos años tiene?',
                  style: GDTypography.displayMedium)
              .animate()
              .fadeIn()
              .slideY(begin: 0.3),

          const Gap(GDSpacing.xl),

          Row(
            children: [
              Expanded(
                child: _AgeChip(
                  label: '8–12 años',
                  isSelected: ageRange == AppConstants.ageRangeKid,
                  onTap: () => onAgeChanged(AppConstants.ageRangeKid),
                ),
              ),
              const Gap(GDSpacing.md),
              Expanded(
                child: _AgeChip(
                  label: '13–17 años',
                  isSelected: ageRange == AppConstants.ageRangeTeen,
                  onTap: () => onAgeChanged(AppConstants.ageRangeTeen),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const Gap(GDSpacing.xl),

          Text('Elige un avatar',
                  style: GDTypography.headlineMedium)
              .animate()
              .fadeIn(delay: 300.ms),

          const Gap(GDSpacing.md),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: GDSpacing.md,
              crossAxisSpacing: GDSpacing.md,
              childAspectRatio: 1,
            ),
            itemCount: avatarEmojis.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onAvatarChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selectedAvatar == i
                      ? context.gd.primaryLight
                      : context.gd.surfaceVariant,
                  borderRadius: GDRadius.lgAll,
                  border: Border.all(
                    color: selectedAvatar == i
                        ? context.gd.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    avatarEmojis[i],
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const Gap(GDSpacing.xl),

          ElevatedButton(
            onPressed: onNext,
            child: const Text('Continuar'),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AgeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: GDSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? context.gd.primary : context.gd.surfaceVariant,
          borderRadius: GDRadius.lgAll,
        ),
        child: Center(
          child: Text(
            label,
            style: GDTypography.titleLarge.copyWith(
              color: isSelected ? Colors.white : context.gd.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PASO 5 — METAS INICIALES
// ─────────────────────────────────────────────
class _GoalsPage extends StatelessWidget {
  final Set<String> selectedGoals;
  final ValueChanged<String> onToggle;
  final VoidCallback? onFinish;

  const _GoalsPage({
    required this.selectedGoals,
    required this.onToggle,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GDSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(GDSpacing.md),

          Text('¿Qué quieres lograr?',
                  style: GDTypography.displayMedium)
              .animate()
              .fadeIn()
              .slideY(begin: 0.3),

          const Gap(GDSpacing.xs),

          Text(
            'Elige hasta 3. Luma te ayudará con estos.',
            style: GDTypography.bodyLarge.copyWith(
              color: context.gd.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms),

          const Gap(GDSpacing.lg),

          Expanded(
            child: ListView.separated(
              itemCount: AppConstants.onboardingGoals.length,
              separatorBuilder: (_, __) => const Gap(GDSpacing.sm),
              itemBuilder: (_, i) {
                final goal = AppConstants.onboardingGoals[i];
                final id = goal['id']!;
                final isSelected = selectedGoals.contains(id);
                final isDisabled =
                    selectedGoals.length >= 3 && !isSelected;

                return GestureDetector(
                  onTap: isDisabled ? null : () => onToggle(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: GDSpacing.md,
                      vertical: GDSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.gd.primaryLight
                          : isDisabled
                              ? context.gd.surfaceVariant.withValues(alpha: 0.5)
                              : context.gd.surfaceVariant,
                      borderRadius: GDRadius.lgAll,
                      border: Border.all(
                        color: isSelected
                            ? context.gd.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.gd.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? context.gd.primary
                                  : context.gd.textTertiary,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const Gap(GDSpacing.md),
                        Expanded(
                          child: Text(
                            goal['label']!,
                            style: GDTypography.bodyLarge.copyWith(
                              color: isDisabled
                                  ? context.gd.textTertiary
                                  : context.gd.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 + i * 60));
              },
            ),
          ),

          const Gap(GDSpacing.md),

          ElevatedButton(
            onPressed: onFinish,
            child: const Text('¡Empecemos! 🚀'),
          ).animate().fadeIn(delay: 600.ms),

          const Gap(GDSpacing.md),
        ],
      ),
    );
  }
}
