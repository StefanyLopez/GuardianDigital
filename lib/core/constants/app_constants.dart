// ─────────────────────────────────────────────
//  CONSTANTES GENERALES
// ─────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  static const String appName = 'Guardian Digital Kids';
  static const String npcName = 'Luma';

  // Groq
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.1-8b-instant'; // capa gratuita
  static const int groqMaxTokens = 300; // respuestas cortas para UX móvil

  // Umbrales de fricción (en minutos, para el slider de demo)
  static const int screenTimeThresholdMinutes = 45;
  static const int maxInterventionsPerDay = 2;
  static const int inactivityThresholdHours = 48;
  static const int nightUsageHour = 22; // 10pm

  // Gamificación
  static const int streakBonusPoints = 10;
  static const int challengeCompletePoints = 25;
  static const int firstChatPoints = 15;

  // Niveles de autonomía
  static const List<String> autonomyLevelLabels = [
    'Explorador',
    'Viajero',
    'Navegante',
    'Piloto',
    'Capitán de tu tiempo',
  ];

  static const List<String> autonomyLevelEmojis = [
    '🌱', '🚶', '⛵', '✈️', '🚀',
  ];

  // Metas del onboarding
  static const List<Map<String, String>> onboardingGoals = [
    {'id': 'sleep', 'label': 'Quiero dormir mejor'},
    {'id': 'family', 'label': 'Quiero más tiempo con mi familia'},
    {'id': 'focus', 'label': 'Quiero concentrarme mejor en el colegio'},
    {'id': 'hobbies', 'label': 'Quiero tiempo para mis hobbies'},
    {'id': 'anxiety', 'label': 'Quiero sentir menos ansiedad sin celular'},
    {'id': 'social', 'label': 'Quiero pasar menos tiempo en redes'},
    {'id': 'intentional', 'label': 'Quiero usar el celular con intención'},
    {'id': 'trust', 'label': 'Quiero que confíen más en mí'},
  ];

  // Avatares NPC (índices de assets)
  static const List<String> kidAvatars = [
    'assets/images/avatar_1.png',
    'assets/images/avatar_2.png',
    'assets/images/avatar_3.png',
    'assets/images/avatar_4.png',
    'assets/images/avatar_5.png',
    'assets/images/avatar_6.png',
  ];

  // Rangos de edad
  static const String ageRangeKid = '8-12';
  static const String ageRangeTeen = '13-17';

  // Supabase tablas
  static const String tableProfiles = 'profiles';
  static const String tableChallenges = 'challenges';
  static const String tableChallengeProgress = 'challenge_progress';
  static const String tableAchievements = 'achievements';
  static const String tableAchievementUnlocks = 'achievement_unlocks';
  static const String tableWellnessScores = 'wellness_scores';
  static const String tableEvents = 'events';
  static const String tableSyncReports = 'sync_reports';

  // SQLite local
  static const String localDbName = 'guardian_local.db';
  static const String tableChatMessages = 'chat_messages';
  static const int localChatHistoryLimit = 30; // últimos N mensajes al NPC
}
