import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_extension.dart';

class FamilySettingsScreen extends ConsumerWidget {
  const FamilySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración', style: GDTypography.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GDSpacing.lg),
        children: [
          // Sección apariencia
          Text('Apariencia', style: GDTypography.headlineMedium),
          const Gap(GDSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: GDRadius.lgAll,
              border: Border.all(
                color: context.gd.primary.withValues(alpha: 0.12),
              ),
            ),
            child: SwitchListTile(
              title: Text('Modo oscuro', style: GDTypography.titleLarge),
              subtitle: Text(
                isDark ? 'Activo' : 'Inactivo',
                style: GDTypography.bodySmall,
              ),
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: context.gd.primary,
              ),
              value: isDark,
              activeColor: context.gd.primary,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),

          const Gap(GDSpacing.lg),

          // Sección del sistema
          Text('Sistema', style: GDTypography.headlineMedium),
          const Gap(GDSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: GDRadius.lgAll,
              border: Border.all(
                color: context.gd.primary.withValues(alpha: 0.12),
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.info_outline, color: context.gd.primary),
              title: Text('Versión', style: GDTypography.titleLarge),
              trailing: Text('1.0.0 MVP', style: GDTypography.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}