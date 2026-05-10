import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  SPACING
// ─────────────────────────────────────────────
class GDSpacing {
  GDSpacing._();
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

// ─────────────────────────────────────────────
//  RADIUS
// ─────────────────────────────────────────────
class GDRadius {
  GDRadius._();
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  static const BorderRadius smAll   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  static const BorderRadius userBubble = BorderRadius.only(
    topLeft:     Radius.circular(lg),
    topRight:    Radius.circular(lg),
    bottomLeft:  Radius.circular(lg),
    bottomRight: Radius.circular(4),   // esquina "cola" del usuario
  );

  static const BorderRadius npcBubble = BorderRadius.only(
    topLeft:     Radius.circular(4),   // esquina "cola" del NPC
    topRight:    Radius.circular(lg),
    bottomLeft:  Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );
}

// ─────────────────────────────────────────────
//  TYPOGRAPHY  (colores neutros — usa .copyWith
//  para sobreescribir con context.gd en widgets)
// ─────────────────────────────────────────────
class GDTypography {
  GDTypography._();

  static TextStyle get displayLarge => GoogleFonts.nunito(
    fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get displayMedium => GoogleFonts.nunito(
    fontSize: 28, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get headlineLarge => GoogleFonts.nunito(
    fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle get headlineMedium => GoogleFonts.nunito(
    fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get headlineSmall => GoogleFonts.nunito(
    fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get titleLarge => GoogleFonts.nunito(
    fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle get titleMedium => GoogleFonts.nunito(
    fontSize: 15, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get bodyMedium => GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get bodySmall => GoogleFonts.nunito(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get labelLarge => GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle get labelMedium => GoogleFonts.nunito(
    fontSize: 12, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle get labelSmall => GoogleFonts.nunito(
    fontSize: 11, fontWeight: FontWeight.w600, height: 1.4);

    // Mensajes de chat
  static TextStyle get userMessage => GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.4,
  );

  static TextStyle get npcMessage => GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    // sin color hardcodeado — lo hereda del tema
  );
}

ThemeData buildGDTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF),
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: GDRadius.lgAll,
        side: BorderSide(color: Color(0xFFE8E6F0)),
      ),
      margin: EdgeInsets.zero,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F7FF),
  );
}
// ─────────────────────────────────────────────
//  TEMA OSCURO COMPLETO v2
//  Reemplaza el buildGDDarkTheme() anterior
// ─────────────────────────────────────────────
ThemeData buildGDDarkTheme() {
  const bg      = Color(0xFF0F0F1A);
  const surface = Color(0xFF1E1E30);
  const surfaceVariant = Color(0xFF252540);
  const primary = Color(0xFF6C63FF);
  const onPrimary = Colors.white;
  const textPrimary   = Color(0xFFEEEEFF);
  const textSecondary = Color(0xFFAAAACC);
  const textTertiary  = Color(0xFF6666AA);
  const border        = Color(0xFF333355);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary:          primary,
      onPrimary:        onPrimary,
      secondary:        Color(0xFFFF6584),
      onSecondary:      Colors.white,
      surface:          surface,
      onSurface:        textPrimary,
      surfaceContainerHighest: surfaceVariant,
      outline:          border,
      error:            Color(0xFFEF4444),
    ),
    scaffoldBackgroundColor: bg,

    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      iconTheme: const IconThemeData(color: textPrimary),
    ),

    cardTheme: const CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: GDRadius.lgAll,
        side: BorderSide(color: border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: const RoundedRectangleBorder(borderRadius: GDRadius.lgAll),
        textStyle: GoogleFonts.nunito(
            fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: const RoundedRectangleBorder(borderRadius: GDRadius.lgAll),
        textStyle: GoogleFonts.nunito(
            fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.nunito(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(  // ← sin const
      filled: true,
      fillColor: surfaceVariant,
      border: const OutlineInputBorder(          // estos sí pueden tener const
          borderRadius: GDRadius.lgAll, borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(
          borderRadius: GDRadius.lgAll, borderSide: BorderSide.none),
      focusedBorder: const OutlineInputBorder(
          borderRadius: GDRadius.lgAll,
          borderSide: BorderSide(color: primary, width: 2)),
      errorBorder: const OutlineInputBorder(
          borderRadius: GDRadius.lgAll,
          borderSide: BorderSide(color: Color(0xFFEF4444))),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: GDSpacing.md, vertical: GDSpacing.md),
      hintStyle: GoogleFonts.nunito(fontSize: 16, color: textTertiary),
      labelStyle: GoogleFonts.nunito(color: textSecondary),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF16162A),
      indicatorColor: primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: selected ? primary : textTertiary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
            color: selected ? primary : textTertiary, size: 24);
      }),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF16162A),
      selectedItemColor: primary,
      unselectedItemColor: textTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    dividerTheme: const DividerThemeData(color: border, thickness: 1),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : textTertiary),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.4)
              : surfaceVariant),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: surfaceVariant,
      thumbColor: primary,
      overlayColor: primary.withValues(alpha: 0.15),
    ),

    popupMenuTheme: const PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: border,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2A2A45),
      contentTextStyle: GoogleFonts.nunito(
          fontSize: 14, color: textPrimary),
      shape: const RoundedRectangleBorder(borderRadius: GDRadius.mdAll),
      behavior: SnackBarBehavior.floating,
    ),

    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      textColor: textPrimary,
      iconColor: textSecondary,
    ),

    iconTheme: const IconThemeData(color: textPrimary),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
