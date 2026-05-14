import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/profile_provider.dart';
import '../../../core/router/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PARENTAL GATE
//  Reto matemático simple que bloquea acciones críticas.
//  Uso: ParentalGate.show(context, onUnlocked: () { ... })
// ─────────────────────────────────────────────────────────────────────────────
class ParentalGate {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onUnlocked,
    String message = 'Esta acción requiere verificación de un adulto.',
  }) async {
    final passed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ParentalGateDialog(message: message),
    );
    if (passed == true && context.mounted) onUnlocked();
  }
}

class _ParentalGateDialog extends StatefulWidget {
  final String message;
  const _ParentalGateDialog({required this.message});

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  final _ctrl = TextEditingController();
  late int _a, _b, _answer;
  String? _error;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    final rng = Random();
    _a = rng.nextInt(40) + 10; // 10–49
    _b = rng.nextInt(40) + 10;
    _answer = _a + _b;
    _ctrl.clear();
    _error = null;
  }

  void _verify() {
    final input = int.tryParse(_ctrl.text.trim());
    if (input == _answer) {
      Navigator.pop(context, true);
      return;
    }
    _attempts++;
    setState(() {
      if (_attempts >= 3) {
        _attempts = 0;
        _newQuestion();
        _error = 'Demasiados intentos. Nueva pregunta generada.';
      } else {
        _error = 'Incorrecto. Quedan ${3 - _attempts} intentos.';
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verificación de adulto 🔒'),
      // 1. Usamos Scrollable para que el teclado no rompa el diseño
      content: SingleChildScrollView( 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message,
                style: GDTypography.bodyMedium
                    .copyWith(color: context.gd.textSecondary)),
            const Gap(GDSpacing.lg),
            Text('¿Cuánto es $_a + $_b?', style: GDTypography.titleLarge),
            const Gap(GDSpacing.sm),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Escribe el resultado',
                errorText: _error,
              ),
              // 2. Mejorar la experiencia: que el botón "Done" del teclado verifique
              onSubmitted: (_) => _verify(), 
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _verify,
          child: const Text('Verificar'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  KID SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class KidSettingsScreen extends ConsumerWidget {
  final String profileId;
  const KidSettingsScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(profileId));
    final themeMode = ref.watch(themeModeProvider);
    final c = context.gd;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración', style: GDTypography.headlineMedium),
      ),
      body: profileAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: c.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(GDSpacing.lg),
          children: [

            // ── APARIENCIA ──────────────────────────────────────────────
            const KidSectionLabel('Apariencia'),
            KidSettingsTile(
              icon: Icons.dark_mode_rounded,
              label: 'Modo oscuro',
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (v) => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),

            const Gap(GDSpacing.lg),

            // ── PERFIL — requiere gate ──────────────────────────────────
            const KidSectionLabel('Perfil  ·  Requiere verificación de adulto'),
            KidSettingsTile(
              icon: Icons.badge_outlined,
              label: 'Cambiar nombre',
              onTap: () => ParentalGate.show(
                context,
                message:
                    'Para cambiar el nombre, un adulto debe responder la pregunta.',
                onUnlocked: () =>
                    _showEditName(context, ref, profile?.name ?? ''),
              ),
            ),
            KidSettingsTile(
              icon: Icons.child_care_rounded,
              label: 'Cambiar rango de edad',
              onTap: () => ParentalGate.show(
                context,
                message:
                    'Para cambiar la edad, un adulto debe responder la pregunta.',
                onUnlocked: () =>
                    _showAgeRangePicker(context, ref, profile?.ageRange),
              ),
            ),

            const Gap(GDSpacing.lg),

            // ── ACERCA DE ───────────────────────────────────────────────
            const KidSectionLabel('Acerca de'),
            KidSettingsTile(
              icon: Icons.info_outline_rounded,
              label: 'Versión',
              trailing: Text('1.0.0 MVP',
                  style: GDTypography.bodySmall
                      .copyWith(color: c.textTertiary)),
            ),

            const Gap(GDSpacing.lg),

            // ── CERRAR SESIÓN — requiere gate ───────────────────────────
            KidSettingsTile(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              color: c.error,
              onTap: () => ParentalGate.show(
                context,
                message:
                    'Para cerrar sesión, un adulto debe responder la pregunta.',
                onUnlocked: () => _logout(context, ref),
              ),
            ),
            const Gap(GDSpacing.lg),

            const KidSectionLabel('Zona de peligro'),
            KidSettingsTile(
              icon: Icons.delete_forever_rounded,
              label: 'Eliminar perfil',
              color: c.error,
              onTap: () => ParentalGate.show(
                context,
                message: 'Para eliminar el perfil, un adulto debe responder la pregunta.',
                onUnlocked: () => _deleteProfile(context, ref),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.invalidate(familyProfilesProvider);
    ref.read(activeProfileIdProvider.notifier).state = null;
    await Supabase.instance.client.auth.signOut();
    // GoRouter detecta el cambio de sesión y redirige al login
  }

  Future<void> _deleteProfile(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar perfil?'),
        content: const Text(
          'Se borrarán todos los datos, logros y progreso. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.gd.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Esperar a que el diálogo cierre completamente antes de continuar
    await Future.delayed(const Duration(milliseconds: 200));

    if (!context.mounted) return;

    await ref
        .read(profileNotifierProvider.notifier)
        .deleteProfile(profileId);

    if (!context.mounted) return;

    ref.read(activeProfileIdProvider.notifier).state = null;
    ref.invalidate(familyProfilesProvider);

    context.go(AppRoutes.guardianHome);
  }

  void _showEditName(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar nombre'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Nombre del perfil'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              await Supabase.instance.client
                  .from(AppConstants.tableProfiles)
                  .update({'name': name}).eq('id', profileId);
              ref.invalidate(profileByIdProvider(profileId));
              ref.invalidate(familyProfilesProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAgeRangePicker(
      BuildContext context, WidgetRef ref, String? current) {
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Rango de edad'),
        children: ['8-12', '13-17'].map((range) {
          return SimpleDialogOption(
            onPressed: () async {
              await Supabase.instance.client
                  .from(AppConstants.tableProfiles)
                  .update({'age_range': range}).eq('id', profileId);
              ref.invalidate(profileByIdProvider(profileId));
              ref.invalidate(familyProfilesProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(range,
                style: GDTypography.bodyLarge.copyWith(
                    fontWeight: current == range
                        ? FontWeight.w700
                        : FontWeight.w400)),
          );
        }).toList(),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class KidSectionLabel extends StatelessWidget {
  final String text;
  const KidSectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: GDSpacing.sm),
        child: Text(text,
            style: GDTypography.labelLarge
                .copyWith(color: context.gd.textTertiary)),
      );
}

class KidSettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const KidSettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gd;
    final tileColor = color ?? c.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: GDSpacing.xs),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: GDRadius.lgAll,
        border: Border.all(color: c.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: tileColor, size: 20),
        title: Text(label,
            style: GDTypography.bodyMedium.copyWith(color: tileColor)),
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right_rounded,
                    color: c.textTertiary, size: 20)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: GDRadius.lgAll),
      ),
    );
  }
}

