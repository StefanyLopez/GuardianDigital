import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  COLORES
// ─────────────────────────────────────────────
class GDColors {
  GDColors._();

  // Primarios
  static const primary = Color(0xFF6C63FF);       // Violeta NPC
  static const primaryLight = Color(0xFFEDECFF);
  static const primaryDark = Color(0xFF4B44CC);

  // Secundarios
  static const secondary = Color(0xFFFF6584);     // Rosa cálido
  static const secondaryLight = Color(0xFFFFEDF1);

  // Neutros
  static const background = Color(0xFFF8F7FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF2F1FA);

  // Texto
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B6B8A);
  static const textTertiary = Color(0xFFAAABC0);

  // Estado
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);

  // NPC específicos
  static const npcBubble = Color(0xFFEDECFF);
  static const userBubble = Color(0xFF6C63FF);
  static const npcText = Color(0xFF1A1A2E);
  static const userText = Color(0xFFFFFFFF);

  // Racha
  static const streak = Color(0xFFFF6B35);
  static const streakLight = Color(0xFFFFF0EB);

  // Gamificación
  static const gold = Color(0xFFFFBF00);
  static const silver = Color(0xFFC0C0C0);
  static const bronze = Color(0xFFCD7F32);

  // Gradientes
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)],
  );

  static const gradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6584), Color(0xFFFF9A9E)],
  );

  static const gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F7FF), Color(0xFFEDECFF)],
  );
}

// ─────────────────────────────────────────────
//  TIPOGRAFÍA
// ─────────────────────────────────────────────
class GDTypography {
  GDTypography._();

  static TextStyle get displayLarge => GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: GDColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.nunito(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: GDColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineLarge => GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: GDColors.textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: GDColors.textPrimary,
  );

  static TextStyle get titleLarge => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: GDColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: GDColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GDColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: GDColors.textTertiary,
    height: 1.4,
  );

  static TextStyle get labelLarge => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: GDColors.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle get labelSmall => GoogleFonts.nunito(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: GDColors.textTertiary,
    letterSpacing: 0.5,
  );

  // NPC chat
  static TextStyle get npcMessage => GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: GDColors.npcText,
    height: 1.5,
  );

  static TextStyle get userMessage => GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: GDColors.userText,
    height: 1.5,
  );
}

// ─────────────────────────────────────────────
//  ESPACIADO
// ─────────────────────────────────────────────
class GDSpacing {
  GDSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─────────────────────────────────────────────
//  RADIOS
// ─────────────────────────────────────────────
class GDRadius {
  GDRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get fullAll => BorderRadius.circular(full);

  // Chat bubbles
  static BorderRadius get npcBubble => const BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );

  static BorderRadius get userBubble => const BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );
}

// ─────────────────────────────────────────────
//  SOMBRAS
// ─────────────────────────────────────────────
class GDShadows {
  GDShadows._();

  static List<BoxShadow> get sm => [
    BoxShadow(
      color: GDColors.primary.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: GDColors.primary.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: GDColors.primary.withValues(alpha: 0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

// ─────────────────────────────────────────────
//  TEMA PRINCIPAL
// ─────────────────────────────────────────────
ThemeData buildGDTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: GDColors.primary,
      background: GDColors.background,
      surface: GDColors.surface,
    ),
    scaffoldBackgroundColor: GDColors.background,
    textTheme: GoogleFonts.nunitoTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: GDColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GDTypography.headlineMedium,
      iconTheme: const IconThemeData(color: GDColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GDColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: GDRadius.lgAll),
        textStyle: GDTypography.labelLarge.copyWith(fontSize: 16),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GDColors.primary,
        side: const BorderSide(color: GDColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: GDRadius.lgAll),
        textStyle: GDTypography.labelLarge.copyWith(fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: GDColors.primary,
        textStyle: GDTypography.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GDColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: GDRadius.lgAll,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: GDRadius.lgAll,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: GDRadius.lgAll,
        borderSide: const BorderSide(color: GDColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: GDRadius.lgAll,
        borderSide: const BorderSide(color: GDColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GDSpacing.md,
        vertical: GDSpacing.md,
      ),
      hintStyle: GDTypography.bodyLarge.copyWith(color: GDColors.textTertiary),
    ),
    cardTheme: CardThemeData(
      color: GDColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: GDRadius.lgAll,
        side: BorderSide(color: GDColors.primary.withValues(alpha: 0.08)),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: GDColors.surface,
      selectedItemColor: GDColors.primary,
      unselectedItemColor: GDColors.textTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: GDColors.textPrimary,
      contentTextStyle: GDTypography.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: GDRadius.mdAll),
      behavior: SnackBarBehavior.floating,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

// ─────────────────────────────────────────────
//  TEMA OSCURO
// ─────────────────────────────────────────────
ThemeData buildGDDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: GDColors.primary,
      brightness: Brightness.dark,
      background: const Color(0xFF0F0F1A),
      surface: const Color(0xFF1A1A2E),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0F0F1A),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GDTypography.headlineMedium.copyWith(
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GDColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: GDRadius.lgAll),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E30),
      border: OutlineInputBorder(
        borderRadius: GDRadius.lgAll,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: GDRadius.lgAll,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: GDRadius.lgAll,
        borderSide: const BorderSide(color: GDColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: Color.fromARGB(255, 206, 206, 235)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A2E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: GDRadius.lgAll,
        side: BorderSide(color: GDColors.primary.withValues(alpha: 0.15)),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A2E),
      selectedItemColor: GDColors.primary,
      unselectedItemColor: Color.fromARGB(255, 206, 206, 235),
    ),
  );
}
