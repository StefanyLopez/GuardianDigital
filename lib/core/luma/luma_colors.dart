import 'package:flutter/material.dart';
import 'luma_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LUMA COLORS
//
//  Paleta de colores del sistema de avatar Luma. Centraliza todos los valores
//  cromáticos para que LumaBlobPainter no tenga colores hardcodeados dispersos.
//
//  Estructura:
//   • bodyBase()    → color principal del blob según customización del perfil
//   • bodyShadow()  → versión saturada/oscura para sombras y mejillas
//   • stateTint()   → capa de tinte semitransparente según estado emocional
//   • haloColor()   → resplandor exterior para evolución Guardian
//   • particleColor()→ partículas flotantes en estado Glowing
//
//  Paleta de cuerpos:
//   mint  #7ECFB3 — verde menta (color por defecto, costo 0)
//   lilac #9B7FE8 — lila       (30 pts)
//   sky   #85B7EB — azul cielo  (50 pts)
//   pink  #F09DC0 — rosa        (50 pts)
//   gold  #F4B942 — dorado      (100 pts, raro)
// ─────────────────────────────────────────────────────────────────────────────
class LumaColors {
  LumaColors._();

  // ── Color base del blob ────────────────────────────────────────────────────
  // Se usa como fill principal y como referencia para derivar halo y partículas.
  static Color bodyBase(LumaBodyColor color) {
    switch (color) {
      case LumaBodyColor.mint:  return const Color(0xFF7ECFB3);
      case LumaBodyColor.lilac: return const Color(0xFF9B7FE8);
      case LumaBodyColor.sky:   return const Color(0xFF85B7EB);
      case LumaBodyColor.pink:  return const Color(0xFFF09DC0);
      case LumaBodyColor.gold:  return const Color(0xFFF4B942);
    }
  }

  // ── Sombra / acento oscuro ─────────────────────────────────────────────────
  // Versión más saturada y oscura del color base. Se usa en:
  //   - sombra proyectada debajo del blob (oval borroso)
  //   - mejillas sonrojadas del personaje
  static Color bodyShadow(LumaBodyColor color) {
    switch (color) {
      case LumaBodyColor.mint:  return const Color(0xFF5DBFA0);
      case LumaBodyColor.lilac: return const Color(0xFF7B5FCC);
      case LumaBodyColor.sky:   return const Color(0xFF5A96CC);
      case LumaBodyColor.pink:  return const Color(0xFFE06090);
      case LumaBodyColor.gold:  return const Color(0xFFE09030);
    }
  }

  // ── Tinte de estado emocional ──────────────────────────────────────────────
  // Capa semitransparente que se pinta sobre el blob para reflejar
  // el estado actual de Luma. Valores bajos de alpha para no opacar
  // el color base del usuario.
  //
  //   tired    → gris desaturado   (Luma usó pantalla de noche)
  //   sleeping → azul frío         (sin actividad 48+ horas)
  //   normal   → sin tinte         (estado neutro)
  //   happy    → blanco suave      (racha de 1+ días)
  //   excited  → blanco más fuerte (racha de 3+ días)
  //   glowing  → amarillo dorado   (racha 7+ días y nivel 3+)
  static Color stateTint(LumaState state) {
    switch (state) {
      case LumaState.tired:    return Colors.grey.withValues(alpha: 0.35);
      case LumaState.sleeping: return const Color(0xFF8BAAC0).withValues(alpha: 0.40);
      case LumaState.normal:   return Colors.transparent;
      case LumaState.happy:    return Colors.white.withValues(alpha: 0.08);
      case LumaState.excited:  return Colors.white.withValues(alpha: 0.12);
      case LumaState.glowing:  return const Color(0xFFFFEA80).withValues(alpha: 0.20);
    }
  }

  // ── Halo de evolución Guardian ─────────────────────────────────────────────
  // Resplandor exterior visible solo en LumaEvolution.guardian (nivel 4+).
  // Se pinta como dos círculos concéntricos antes del blob:
  //   - círculo exterior α=0.30 (más visible)
  //   - círculo interior α=0.15 (transición suave)
  static Color haloColor(LumaBodyColor color) =>
      bodyBase(color).withValues(alpha: 0.30);

  // ── Partículas flotantes ───────────────────────────────────────────────────
  // Puntos orbitales visibles en estado LumaState.glowing.
  // Usan el color sombra con alpha alto para contrastar con el blob.
  // Solo se renderizan en vista completa (isChat: false).
  static Color particleColor(LumaBodyColor color) =>
      bodyShadow(color).withValues(alpha: 0.70);
}