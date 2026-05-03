import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(state.error.toString()))),
      );
    } else {
      // Registro exitoso → onboarding
      context.go(AppRoutes.onboarding);
    }
  }

  String _friendlyError(String error) {
    if (error.contains('already registered')) return 'Ese correo ya tiene cuenta. Inicia sesión.';
    if (error.contains('weak')) return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
    if (error.contains('network')) return 'Sin conexión. Intenta de nuevo.';
    return 'Algo salió mal. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: GDSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(GDSpacing.lg),

                Text(
                  'Crea tu cuenta',
                  style: GDTypography.displayMedium,
                ).animate().fadeIn().slideY(begin: 0.3),

                const Gap(GDSpacing.xs),

                Text(
                  'Es para toda la familia. Un solo registro.',
                  style: GDTypography.bodyLarge.copyWith(
                    color: GDColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const Gap(GDSpacing.xl),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Correo de la familia',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa un correo';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const Gap(GDSpacing.md),

                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                    if (v.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                const Gap(GDSpacing.md),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: InputDecoration(
                    hintText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                    if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                const Gap(GDSpacing.lg),

                // Info de privacidad
                Container(
                  padding: const EdgeInsets.all(GDSpacing.md),
                  decoration: BoxDecoration(
                    color: GDColors.primaryLight,
                    borderRadius: GDRadius.mdAll,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: GDColors.primary, size: 18),
                      const Gap(GDSpacing.sm),
                      Expanded(
                        child: Text(
                          'Las conversaciones con Luma son privadas y nunca salen de tu dispositivo.',
                          style: GDTypography.bodySmall.copyWith(
                            color: GDColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const Gap(GDSpacing.lg),

                ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear cuenta'),
                ).animate().fadeIn(delay: 600.ms),

                const Gap(GDSpacing.md),

                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        text: '¿Ya tienes cuenta? ',
                        style: GDTypography.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Inicia sesión',
                            style: GDTypography.bodyMedium.copyWith(
                              color: GDColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),

                const Gap(GDSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
