import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/kid/presentation/kid_home_screen.dart';
import '../../features/kid/presentation/chat_screen.dart';
import '../../features/kid/presentation/achievements_screen.dart';
import '../../features/kid/presentation/stats_screen.dart';
import '../../features/kid/presentation/kid_settings_screen.dart';
import '../../features/kid/presentation/focus_screen.dart';
import '../../features/guardian/presentation/guardian_home_screen.dart';
import '../../features/guardian/presentation/profile_detail_screen.dart';
import '../../features/guardian/presentation/family_settings_screen.dart';
import '../../features/demo/presentation/demo_panel_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../shell/main_shell.dart';
import '../../features/guardian/presentation/profile_form_screen.dart';
import '../../features/kid/providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_extension.dart';
import '../../main.dart' show supabaseReady;

// ─────────────────────────────────────────────
//  RUTAS
// ─────────────────────────────────────────────
class AppRoutes {
  static const splash    = '/';
  static const login     = '/login';
  static const register  = '/register';
  static const onboarding = '/onboarding';

  // Kid
  static String kidHome(String profileId)     => '/kid/$profileId';
  static String chat(String profileId)        => '/kid/$profileId/chat';
  static String achievements(String profileId)=> '/kid/$profileId/achievements';
  static String stats(String profileId)       => '/kid/$profileId/stats';
  static String kidSettings(String profileId) => '/kid/$profileId/settings';
  static String focus(String profileId)       => '/kid/$profileId/focus';

  // Guardian
  static const guardianHome    = '/guardian';
  static const familySettings  = '/guardian/settings';
  static const newProfile      = '/guardian/new-profile';
  static String profileDetail(String id) => '/guardian/profile/$id';
  static String editProfile(String id)   => '/guardian/edit-profile/$id';

  // Demo
  static const demoPanel = '/demo';
}

// ─────────────────────────────────────────────
//  APP READY PROVIDER
//  Se resuelve cuando Supabase.initialize() y NotificationService
//  terminan. Mientras está en AsyncLoading, el redirect mantiene
//  al usuario en el splash (cold start de Supabase free tier).
// ─────────────────────────────────────────────
final appReadyProvider = FutureProvider<bool>((ref) async {
  await supabaseReady;
  return true;
});

// ─────────────────────────────────────────────
//  ROUTER PROVIDER
// ─────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  // Observa solo si el usuario está logueado o no (true/false).
  // isLoggedInProvider usa .distinct() y solo emite cuando el valor
  // cambia de verdad — el token refresh silencioso (cada hora) NO
  // dispara la recreación del GoRouter ni el "flash" de navegación.
  ref.watch(isLoggedInProvider);
  // Escucha el estado de inicialización para salir del splash cuando esté listo
  ref.watch(appReadyProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // ── 1. Esperar inicialización — quedarse en splash mientras carga
      final appReady = ref.read(appReadyProvider);
      if (appReady.isLoading) return null;

      // ── 2. Inicialización completa — leer sesión (síncrono, ya restaurada
      //       desde flutter_secure_storage por Supabase.initialize)
      final isLoggedIn =
          Supabase.instance.client.auth.currentSession != null;
      final loc = state.matchedLocation;
      final isOnAuth =
          loc == AppRoutes.login || loc == AppRoutes.register;
      final isOnSplash = loc == AppRoutes.splash;

      if (isOnSplash) {
        return isLoggedIn ? AppRoutes.guardianHome : AppRoutes.login;
      }
      if (!isLoggedIn && !isOnAuth) return AppRoutes.login;
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),

      // Auth
      GoRoute(path: AppRoutes.login,    builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),

      // ── Kid shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(
          profileId: _extractProfileId(state),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/kid/:profileId',
            builder: (_, state) => KidHomeScreen(
              profileId: state.pathParameters['profileId']!,
            ),
            routes: [
              GoRoute(
                path: 'chat',
                builder: (_, state) => const ChatScreen(),
              ),
              GoRoute(
                path: 'achievements',
                builder: (_, state) => const AchievementsScreen(),
              ),
              GoRoute(
                path: 'stats',
                builder: (_, state) => const StatsScreen(),
              ),
              // Settings del menor — protegida por Parental Gate interno
              GoRoute(
                path: 'settings',
                builder: (_, state) => KidSettingsScreen(
                  profileId: state.pathParameters['profileId']!,
                ),
              ),
              // Pantalla de concentración y mindfulness
              GoRoute(
                path: 'focus',
                builder: (_, state) => FocusScreen(
                  profileId: state.pathParameters['profileId']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Guardian ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.guardianHome,
        builder: (_, __) => const GuardianHomeScreen(),
        routes: [
          GoRoute(
            path: 'profile/:id',
            builder: (_, state) => ProfileDetailScreen(
              profileId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'new-profile',
            builder: (_, __) => const ProfileFormScreen(),
          ),
          GoRoute(
            path: 'edit-profile/:id',
            builder: (_, state) {
              final profileId = state.pathParameters['id']!;
              // Lee el valor cacheado del FutureProvider (disponible porque
              // guardian_home_screen ya seteó activeProfileIdProvider antes de navegar)
              final profile =
                  ref.read(profileByIdProvider(profileId)).valueOrNull;
              return ProfileFormScreen(profile: profile);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (_, __) => const FamilySettingsScreen(),
          ),
        ],
      ),

      // Demo
      GoRoute(
        path: AppRoutes.demoPanel,
        builder: (_, __) => const DemoPanelScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.error}')),
    ),
  );
});

String? _extractProfileId(GoRouterState state) {
  final match = RegExp(r'/kid/([^/]+)').firstMatch(state.uri.toString());
  return match?.group(1);
}

// ─────────────────────────────────────────────
//  SPLASH SCREEN
//  Visible durante el cold start de Supabase (free tier puede tardar
//  5-15s). Muestra branding en lugar de un spinner sin contexto.
//  appReadyProvider re-evalúa appRouterProvider cuando se resuelve,
//  lo que dispara el redirect y sale del splash automáticamente.
// ─────────────────────────────────────────────
class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo / ícono de la app ──────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  size: 56,
                  color: context.gd.primary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Nombre de la app ────────────────────────────────────
              Text(
                'Guardian Digital',
                style: GDTypography.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Bienestar digital para toda la familia',
                style: GDTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 64),

              // ── Indicador de carga ──────────────────────────────────
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.gd.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}