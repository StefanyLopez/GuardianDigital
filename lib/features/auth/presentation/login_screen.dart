import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/theme_extension.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(state.error.toString()))),
      );
    }
  }

  String _friendlyError(String error) {
    if (error.contains('Invalid login')) return 'Correo o contraseña incorrectos.';
    if (error.contains('network')) return 'Sin conexión. Intenta de nuevo.';
    return 'Algo salió mal. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: GDSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(GDSpacing.xxl),

                // Logo / NPC
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: context.gd.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: context.gd.shadowLg,
                    ),
                    child: const Center(
                      child: Text('✨', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

                const Gap(GDSpacing.xl),

                Text(
                  'Bienvenido de vuelta',
                  style: GDTypography.displayMedium,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                const Gap(GDSpacing.xs),

                Text(
                  'Luma te estaba esperando.',
                  style: GDTypography.bodyLarge.copyWith(
                    color: context.gd.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const Gap(GDSpacing.xl),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                const Gap(GDSpacing.md),

                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                const Gap(GDSpacing.lg),

                // Botón login
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Entrar'),
                ).animate().fadeIn(delay: 600.ms),

                const Gap(GDSpacing.md),

                // Ir a registro
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: RichText(
                      text: TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: GDTypography.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Créala aquí',
                            style: GDTypography.bodyMedium.copyWith(
                              color: context.gd.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
