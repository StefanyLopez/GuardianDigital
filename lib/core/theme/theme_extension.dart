import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  EXTENSIÓN DE TEMA — context.gd
//  Todos los colores leen el tema activo.
//  Úsalo así: context.gd.surface, context.gd.textPrimary, etc.
//  Esto reemplaza los GDColors hardcodeados en los widgets.
// ─────────────────────────────────────────────
extension GDThemeExtension on BuildContext {
  GDThemeColors get gd => GDThemeColors(this);
}

class GDThemeColors {
  final BuildContext _context;
  const GDThemeColors(this._context);

  ThemeData get _theme => Theme.of(_context);
  bool get isDark => _theme.brightness == Brightness.dark;

  // ── Fondos
  Color get background => _theme.colorScheme.surface;
  Color get surface    => isDark ? const Color(0xFF1E1E30) : const Color(0xFFFFFFFF);
  Color get surfaceVariant => isDark ? const Color(0xFF252540) : const Color(0xFFF2F1FA);
  Color get card       => isDark ? const Color(0xFF252538) : const Color(0xFFFFFFFF);

  // ── Textos
  Color get textPrimary   => isDark ? const Color(0xFFEEEEFF) : const Color(0xFF1A1A2E);
  Color get textSecondary => isDark ? const Color(0xFFAAAACC) : const Color(0xFF6B6B8A);
  Color get textTertiary  => isDark ? const Color(0xFF6666AA) : const Color(0xFFAAABC0);

  // ── Bordes
  Color get border        => isDark ? const Color(0xFF333355) : const Color(0xFFE8E6F0);
  Color get borderSubtle  => isDark
      ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
      : const Color(0xFF6C63FF).withValues(alpha: 0.08);

  // ── Primarios (constantes, iguales en ambos modos)
  Color get primary      => const Color(0xFF6C63FF);
  Color get primaryLight => isDark
      ? const Color(0xFF6C63FF).withValues(alpha: 0.18)
      : const Color(0xFFEDECFF);
  Color get primaryDark  => const Color(0xFF4B44CC);

  // ── Secundario
  Color get secondary      => const Color(0xFFFF6584);
  Color get secondaryLight => isDark
      ? const Color(0xFFFF6584).withValues(alpha: 0.15)
      : const Color(0xFFFFEDF1);

  // ── Semánticos
  Color get success      => const Color(0xFF22C55E);
  Color get successLight => isDark
      ? const Color(0xFF22C55E).withValues(alpha: 0.15)
      : const Color(0xFFDCFCE7);
  Color get warning      => const Color(0xFFF59E0B);
  Color get warningLight => isDark
      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
      : const Color(0xFFFEF3C7);
  Color get error        => const Color(0xFFEF4444);
  Color get errorLight   => isDark
      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
      : const Color(0xFFFEE2E2);

  // ── Racha
  Color get streak      => const Color(0xFFFF6B35);
  Color get streakLight => isDark
      ? const Color(0xFFFF6B35).withValues(alpha: 0.15)
      : const Color(0xFFFFF0EB);
  
  // Dorado — para logros/trofeos
  Color get gold      => const Color(0xFFFFB700);
  Color get goldLight => isDark
      ? const Color(0xFFFFB700).withValues(alpha: 0.15)
      : const Color(0xFFFFF8E1);

  // ── Chat burbujas
  Color get npcBubble  => isDark ? const Color(0xFF2A2A45) : const Color(0xFFEDECFF);
  Color get npcText    => isDark ? const Color(0xFFEEEEFF) : const Color(0xFF1A1A2E);
  Color get userBubble => const Color(0xFF6C63FF);
  Color get userText   => const Color(0xFFFFFFFF);

  // ── Sombras adaptadas
  List<BoxShadow> get shadowSm => isDark
      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
      : [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))];

  List<BoxShadow> get shadowMd => isDark
      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]
      : [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))];

  List<BoxShadow> get shadowLg => isDark
      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8))]
      : [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.16), blurRadius: 24, offset: const Offset(0, 8))];

  // ── Bottom nav
  Color get bottomNavBackground => isDark ? const Color(0xFF16162A) : const Color(0xFFFFFFFF);
  Color get bottomNavSelected   => const Color(0xFF6C63FF);
  Color get bottomNavUnselected => isDark ? const Color(0xFF6666AA) : const Color(0xFFAAABC0);

  // ── Input fill
  Color get inputFill => isDark ? const Color(0xFF252540) : const Color(0xFFF2F1FA);

  // ── Gradiente primario (igual en ambos modos)
  LinearGradient get gradientPrimary => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)],
  );
}
