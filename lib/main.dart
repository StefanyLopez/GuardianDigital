import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_extension.dart';

// ─────────────────────────────────────────────
//  SUPABASE READY SIGNAL
//  Completer que se resuelve cuando Supabase.initialize() termina.
//  app_router.dart lo escucha para saber cuándo puede leer currentSession.
// ─────────────────────────────────────────────
final _supabaseReadyCompleter = Completer<void>();

/// Future que se completa en cuanto Supabase (y las notificaciones)
/// terminan de inicializar. Usado por [appReadyProvider] en el router.
Future<void> get supabaseReady => _supabaseReadyCompleter.future;

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación solo portrait — rápido, sin I/O
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Variables de entorno — lectura local, rápida
  await dotenv.load(fileName: '.env');

  // Timezones — síncrono, sin I/O de red
  tz.initializeTimeZones();

  // ── Lanzar la app YA ──────────────────────────────────────────────────
  // El splash se muestra mientras Supabase despierta (cold start free tier).
  // appReadyProvider en el router queda en AsyncLoading hasta que el
  // completer se resuelva; redirect mantiene al usuario en splash.
  runApp(
    const ProviderScope(
      child: GuardianDigitalApp(),
    ),
  );

  // ── Inicializar en paralelo, en background ────────────────────────────
  await Future.wait([
    Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    ),
    NotificationService.initialize(),
  ]);

  // Señalizar que ya está todo listo — el router puede leer currentSession
  _supabaseReadyCompleter.complete();
}

// ─────────────────────────────────────────────
//  APP RAÍZ
// ─────────────────────────────────────────────
class GuardianDigitalApp extends ConsumerWidget {
  const GuardianDigitalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider); 

    return MaterialApp.router(
      title: 'Guardian Digital',
      debugShowCheckedModeBanner: false,
      theme: buildGDTheme(),
      darkTheme: buildGDDarkTheme(), 
      themeMode: themeMode,          
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
