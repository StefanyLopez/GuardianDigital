import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/profile_provider.dart';
import '../../../core/theme/theme_extension.dart';

final _wellnessProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return [];
  final client = Supabase.instance.client;
  final scores = await client
      .from(AppConstants.tableWellnessScores)
      .select()
      .eq('profile_id', profile.id)
      .order('week_start', ascending: false)
      .limit(4);
  return List<Map<String, dynamic>>.from(scores);
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final wellnessAsync = ref.watch(_wellnessProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Mi semana', style: GDTypography.headlineMedium)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: GDSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(GDSpacing.md),

            // Racha y puntuación actual
            if (profile != null) _buildCurrentCard(context,profile)
                .animate().fadeIn().slideY(begin: -0.2),

            const Gap(GDSpacing.lg),

            Text('Últimas 4 semanas', style: GDTypography.headlineMedium)
                .animate().fadeIn(delay: 200.ms),
            const Gap(GDSpacing.md),

            wellnessAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(GDSpacing.xl),
                  child: CircularProgressIndicator(color: context.gd.primary),
                ),
              ),
              error: (_, __) => Text('Error al cargar estadísticas', style: GDTypography.bodyMedium),
              data: (scores) {
                if (scores.isEmpty) return _buildEmptyStats(context);
                return Column(
                  children: [
                    // Gráfico de barras simple
                    _buildBarChart(context, scores),
                    const Gap(GDSpacing.lg),
                    // Detalle por semana
                    ...scores.asMap().entries.map((e) =>
                      _buildWeekCard(context, e.value)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 300 + e.key * 100))
                          .slideX(begin: -0.1),
                    ),
                  ],
                );
              },
            ),

            const Gap(GDSpacing.lg),

            // Sección de hábitos
            Text('Resumen de hábitos', style: GDTypography.headlineMedium)
                .animate().fadeIn(delay: 400.ms),
            const Gap(GDSpacing.md),

            if (profile != null) _buildHabitsGrid(context, profile)
                .animate().fadeIn(delay: 500.ms),

            const Gap(GDSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCard(BuildContext context, dynamic profile) {
    final streak = profile.streakDays as int;
    final level = profile.autonomyLevel as int;
    return Container(
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        gradient: context.gd.gradientPrimary,
        borderRadius: GDRadius.lgAll,
        boxShadow: context.gd.shadowMd,
      ),
      child: Row(
        children: [
          Expanded(child: _StatPill(
            emoji: '🔥',
            label: 'Racha',
            value: '$streak días',
            light: true,
          )),
          Container(width: 1, height: 50, color: Colors.white24),
          Expanded(child: _StatPill(
            emoji: '⭐',
            label: 'Autonomía',
            value: 'Nivel $level',
            light: true,
          )),
          Container(width: 1, height: 50, color: Colors.white24),
          Expanded(child: _StatPill(
            emoji: AppConstants.autonomyLevelEmojis[level - 1],
            label: 'Estado',
            value: AppConstants.autonomyLevelLabels[level - 1],
            light: true,
          )),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<Map<String, dynamic>> scores) {
    const maxScore = 10.0;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        color: context.gd.surface,
        borderRadius: GDRadius.lgAll,
        border: Border.all(color: context.gd.primary.withValues(alpha: 0.1)),
        boxShadow: context.gd.shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: scores.reversed.toList().asMap().entries.map((e) {
          final score = (e.value['score'] as num?)?.toDouble() ?? 0;
          final weekStart = e.value['week_start'] as String? ?? '';
          final label = weekStart.isNotEmpty
              ? DateFormat('d MMM', 'es').format(DateTime.parse(weekStart))
              : 'Sem ${e.key + 1}';
          final isLatest = e.key == scores.length - 1;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: GDTypography.bodySmall.copyWith(
                    color: isLatest ? context.gd.primary : context.gd.textTertiary,
                    fontWeight: isLatest ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                const Gap(4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: score / maxScore,
                      child: AnimatedContainer(
                        duration: 600.ms,
                        decoration: BoxDecoration(
                          color: isLatest ? context.gd.primary : context.gd.primaryLight,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(6),
                Text(label, style: GDTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekCard(BuildContext context, Map<String, dynamic> data) {
    final score = (data['score'] as num?)?.toDouble() ?? 0;
    final challengesDone = data['challenges_done'] as int? ?? 0;
    final weekStart = data['week_start'] as String? ?? '';
    final summaryText = data['summary_text'] as String?;
    final interventions = data['interventions'] as Map<String, dynamic>? ?? {};
    final attended = interventions['attended'] as int? ?? 0;
    final triggered = interventions['triggered'] as int? ?? 0;

    String weekLabel = 'Semana';
    if (weekStart.isNotEmpty) {
      final date = DateTime.parse(weekStart);
      weekLabel = 'Semana del ${DateFormat('d MMM', 'es').format(date)}';
    }

    final scoreColor = score >= 7 ? context.gd.success : score >= 4 ? context.gd.warning : context.gd.error;

    return Container(
      margin: const EdgeInsets.only(bottom: GDSpacing.md),
      padding: const EdgeInsets.all(GDSpacing.md),
      decoration: BoxDecoration(
        color: context.gd.surface,
        borderRadius: GDRadius.lgAll,
        border: Border.all(color: context.gd.primary.withValues(alpha: 0.1)),
        boxShadow: context.gd.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(weekLabel, style: GDTypography.titleLarge)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: GDSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: GDRadius.fullAll,
                ),
                child: Text(
                  '${score.toStringAsFixed(1)} / 10',
                  style: GDTypography.labelLarge.copyWith(color: scoreColor),
                ),
              ),
            ],
          ),
          if (summaryText != null) ...[
            const Gap(GDSpacing.sm),
            Text(summaryText, style: GDTypography.bodyMedium),
          ],
          const Gap(GDSpacing.sm),
          Row(
            children: [
              _MiniStat(emoji: '🎯', label: 'Retos', value: '$challengesDone'),
              const Gap(GDSpacing.md),
              if (triggered > 0)
                _MiniStat(
                  emoji: '💬',
                  label: 'Intervenciones',
                  value: '$attended/$triggered',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsGrid(BuildContext context, dynamic profile) {
    final streak = profile.streakDays as int;
    final level = profile.autonomyLevel as int;

    final habits = [
      {'emoji': '🌙', 'label': 'Noches sin pantalla', 'value': streak > 3 ? 'Bien' : 'En progreso', 'good': streak > 3},
      {'emoji': '📱', 'label': 'Uso consciente', 'value': level >= 3 ? 'Sí' : 'Aprendiendo', 'good': level >= 3},
      {'emoji': '🎯', 'label': 'Retos completados', 'value': 'Ver logros', 'good': true},
      {'emoji': '🤝', 'label': 'Autonomía digital', 'value': '${(level / 5 * 100).round()}%', 'good': level >= 2},
    ];

    return GridView.builder( 
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: GDSpacing.md,
        crossAxisSpacing: GDSpacing.md,
        childAspectRatio: 1.4,
      ),
      itemCount: habits.length,
      itemBuilder: (_, i) {
        final h = habits[i];
        final isGood = h['good'] as bool;
        return Container(
          padding: const EdgeInsets.all(GDSpacing.md),
          decoration: BoxDecoration(
            color: isGood ? context.gd.successLight : context.gd.surfaceVariant,
            borderRadius: GDRadius.lgAll,
            border: Border.all(
              color: isGood ? context.gd.success.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(h['emoji'] as String, style: const TextStyle(fontSize: 24)),
              const Gap(4),
              Text(h['label'] as String, style: GDTypography.bodySmall),
              Text(
                h['value'] as String,
                style: GDTypography.titleLarge.copyWith(
                  color: isGood ? context.gd.success : context.gd.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GDSpacing.xl),
      decoration: BoxDecoration(
        color: context.gd.surfaceVariant,
        borderRadius: GDRadius.lgAll,
      ),
      child: Column(
        children: [
          const Text('📊', style: TextStyle(fontSize: 40)),
          const Gap(GDSpacing.md),
          Text(
            'Aún no hay estadísticas.\nUsá la app unos días para verlas aquí.',
            style: GDTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji, label, value;
  final bool light;
  const _StatPill({required this.emoji, required this.label, required this.value, this.light = false});

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : context.gd.textPrimary;
    final subColor = light ? Colors.white70 : context.gd.textSecondary;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const Gap(4),
      Text(value, style: GDTypography.titleLarge.copyWith(color: textColor)),
      Text(label, style: GDTypography.bodySmall.copyWith(color: subColor)),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji, label, value;
  const _MiniStat({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const Gap(4),
      Text('$label: ', style: GDTypography.bodySmall),
      Text(value, style: GDTypography.bodySmall.copyWith(
        fontWeight: FontWeight.w600, color: context.gd.textPrimary)),
    ]);
  }
}
