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
import '../../features/guardian/presentation/guardian_home_screen.dart';
import '../../features/guardian/presentation/profile_detail_screen.dart';
import '../../features/guardian/presentation/family_settings_screen.dart';
import '../../features/demo/presentation/demo_panel_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../shell/main_shell.dart';
import '../../features/guardian/presentation/profile_form_screen.dart';
import '../../features/kid/providers/profile_provider.dart';

// ─────────────────────────────────────────────
//  RUTAS
// ─────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';

  // Kid — profileId va en la URL para no perder estado
  static String kidHome(String profileId) => '/kid/$profileId';
  static String chat(String profileId) => '/kid/$profileId/chat';
  static String achievements(String profileId) => '/kid/$profileId/achievements';
  static String stats(String profileId) => '/kid/$profileId/stats';

  // Atajos sin profileId (usan el último profileId activo en el shell)
  static const chatFallback = '/chat';
  static const achievementsFallback = '/achievements';
  static const statsFallback = '/stats';

  // Guardian
  static const guardianHome = '/guardian';
  static String profileDetail(String id) => '/guardian/profile/$id';
  static const familySettings = '/guardian/settings';

  // Demo
  static const demoPanel = '/demo';

  static const newProfile = '/guardian/new-profile';
  static String editProfile(String id) => '/guardian/edit-profile/$id';
  
}

// ─────────────────────────────────────────────
//  ROUTER PROVIDER — sin build_runner, sin @riverpod
// ─────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
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
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),

      // Kid shell — profileId en la URL
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
            ],
          ),
        ],
      ),

      // Guardian
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
              // Necesitamos el profile — lo cargamos desde el activeProfileProvider
              final profile = ref.read(activeProfileProvider);
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
      body: Center(
        child: Text('Ruta no encontrada: ${state.error}'),
      ),
    ),
  );
});

// Extrae el profileId de la URL actual para pasarlo al shell
String? _extractProfileId(GoRouterState state) {
  final uri = state.uri.toString();
  final match = RegExp(r'/kid/([^/]+)').firstMatch(uri);
  return match?.group(1);
}

// ─────────────────────────────────────────────
//  SPLASH
// ─────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
