import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// ─────────────────────────────────────────────
//  SERVICIO DE NOTIFICACIONES
//  Usa flutter_local_notifications para el MVP
//  No requiere servidor externo — funciona offline
// ─────────────────────────────────────────────
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  // IDs de canales Android
  static const _channelId = 'guardian_digital_channel';
  static const _channelName = 'Guardian Digital';
  static const _channelDesc = 'Mensajes de Luma, tu compañero digital';

  // IDs de notificaciones
  static const int idScreenTimeAlert = 1;
  static const int idNightUsageAlert = 2;
  static const int idInactivityAlert = 3;
  static const int idChallengeReminder = 4;

  // ── Inicialización
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear canal Android
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // ── Handler cuando el usuario toca la notificación
  static void _onNotificationTap(NotificationResponse response) {
    // TODO: navegar al chat cuando se toca la notificación
    // Se conecta con el router en el siguiente módulo
  }

  // ── Detalles de notificación Android/iOS
  static NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ─────────────────────────────────────────────
  //  DISPARADORES PÚBLICOS
  //  Cada uno corresponde a un trigger del motor de fricción
  // ─────────────────────────────────────────────

  /// Trigger 1 — Tiempo de pantalla superado
  static Future<void> sendScreenTimeAlert({String npcName = 'Luma'}) async {
    await _plugin.show(
      idScreenTimeAlert,
      npcName,
      'Llevas un rato en pantalla. ¿Cómo te sientes? 👀',
      _details,
      payload: 'screen_time',
    );
  }

  /// Trigger 3 — Uso nocturno (se envía a la mañana siguiente)
  static Future<void> scheduleNightUsageFollowUp({
    String npcName = 'Luma',
  }) async {
    final tomorrow = tz.TZDateTime.now(tz.local).add(const Duration(hours: 8));
    await _plugin.zonedSchedule(
      idNightUsageAlert,
      npcName,
      '¿Cómo dormiste anoche? Quiero saber cómo estás 🌙',
      tomorrow,
      _details,
      payload: 'night_usage',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Trigger 5 — Inactividad 48 horas
  static Future<void> sendInactivityAlert({String npcName = 'Luma'}) async {
    await _plugin.show(
      idInactivityAlert,
      npcName,
      '¡Hola! ¿Todo bien por ahí? Hace tiempo que no pasas 👋',
      _details,
      payload: 'inactivity',
    );
  }

  /// Recordatorio de reto pendiente
  static Future<void> sendChallengeReminder({
    required String challengeTitle,
    String npcName = 'Luma',
  }) async {
    await _plugin.show(
      idChallengeReminder,
      npcName,
      '¿Cómo va "$challengeTitle"? Cuéntame 💪',
      _details,
      payload: 'challenge',
    );
  }

  /// Cancelar todas las notificaciones
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancelar una notificación específica
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Solicitar permisos (necesario en Android 13+ e iOS)
  static Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }
}
