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

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación solo portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Variables de entorno
  await dotenv.load(fileName: '.env');

  // Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Timezones (para notificaciones programadas)
  tz.initializeTimeZones();

  // Notificaciones locales
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: GuardianDigitalApp(),
    ),
  );
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
