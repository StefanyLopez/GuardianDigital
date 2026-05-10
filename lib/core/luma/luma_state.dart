import '../../features/kid/models/profile_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LUMA STATE — Enums, modelo de datos y lógica de cálculo
//
//  Este archivo define todo el estado conceptual del avatar Luma:
//  qué aspecto tiene, cómo se llama y cómo se calcula a partir del perfil.
//
//  Flujo de datos:
//    ProfileModel  →  calculateLumaData()  →  LumaData
//    LumaData      →  LumaAvatar (widget)  →  LumaBlobPainter (canvas)
// ─────────────────────────────────────────────────────────────────────────────

// ── Estados emocionales ────────────────────────────────────────────────────
// Determinan animaciones, tinte de color y expresión facial.
// Prioridad de cálculo (mayor a menor): sleeping > tired > glowing >
//   excited > happy > normal
enum LumaState {
  tired,    // Luma usó pantalla por la noche — ojos semicerrados, tinte gris
  sleeping, // Sin actividad 48+ horas — ojos cerrados, tinte azul frío
  normal,   // Estado base — expresión neutra
  happy,    // Racha de 1+ días — sonrisa suave
  excited,  // Racha de 3+ días — sonrisa amplia, destellos estrella
  glowing,  // Racha 7+ días y nivel 3+ — partículas doradas, tinte amarillo
}

// ── Etapas de evolución ────────────────────────────────────────────────────
// Determinan la forma del blob, el tamaño base y si tiene halo.
// Dependen del nivel de autonomía y la racha acumulada.
enum LumaEvolution {
  sprout,   // Nivel 1-2, racha < 3 — blob pequeño (120px), forma redondeada
  growing,  // Nivel 3 o racha 3+ — blob mediano (150px), forma más orgánica
  guardian, // Nivel 4+ — blob grande (180px), forma fluida + halo exterior
}

// ── Colores de cuerpo desbloqueables ──────────────────────────────────────
// Se mapean 1:1 con el índice equippedBodyColor del perfil.
// Costos en la tienda: mint=0, lilac=30, sky=50, pink=50, gold=100
enum LumaBodyColor { mint, lilac, sky, pink, gold }

// ── Accesorios desbloqueables ──────────────────────────────────────────────
// Se pinta encima del blob. none es el estado por defecto (costo 0).
enum LumaAccessory { none, flower, antennas, cap, headphones, crown }

// ── Tipos de ojos desbloqueables ──────────────────────────────────────────
// Cambian el dibujo de los ojos en LumaBlobPainter.
enum LumaEyes { normal, sunglasses, stars, rainbow, diamond }

// ─────────────────────────────────────────────────────────────────────────────
//  LumaData — snapshot inmutable del estado visual de Luma
//
//  Se recalcula cada vez que cambia el perfil. Es const-friendly para
//  pasarlo por constructores sin riesgo de mutación.
// ─────────────────────────────────────────────────────────────────────────────
class LumaData {
  final LumaState state;
  final LumaEvolution evolution;
  final LumaBodyColor bodyColor;
  final LumaAccessory accessory;
  final LumaEyes eyes;

  const LumaData({
    required this.state,
    required this.evolution,
    required this.bodyColor,
    required this.accessory,
    required this.eyes,
  });

  // ── Tamaños del blob ───────────────────────────────────────────────────────
  // blobSize: vista completa (Home screen, perfil)
  // chatBlobSize: vista compacta (burbuja en ChatScreen)
  double get blobSize {
    switch (evolution) {
      case LumaEvolution.sprout:   return 120;
      case LumaEvolution.growing:  return 150;
      case LumaEvolution.guardian: return 180;
    }
  }

  double get chatBlobSize {
    switch (evolution) {
      case LumaEvolution.sprout:   return 52;
      case LumaEvolution.growing:  return 60;
      case LumaEvolution.guardian: return 68;
    }
  }

  // ── Flags de efectos visuales ──────────────────────────────────────────────
  bool get hasHalo         => evolution == LumaEvolution.guardian;
  bool get hasParticles    => state == LumaState.glowing;
  bool get hasStarSparkles => state == LumaState.excited;

  // ── Nombres para UI ────────────────────────────────────────────────────────
  String get evolutionName {
    switch (evolution) {
      case LumaEvolution.sprout:   return 'Luma Brote 🌱';
      case LumaEvolution.growing:  return 'Pequeña Luma ✨';
      case LumaEvolution.guardian: return 'Luma Guardiana 🌟';
    }
  }

  String get stateName {
    switch (state) {
      case LumaState.tired:    return 'Cansada';
      case LumaState.sleeping: return 'Dormida';
      case LumaState.normal:   return 'Tranquila';
      case LumaState.happy:    return 'Contenta';
      case LumaState.excited:  return 'Emocionada';
      case LumaState.glowing:  return 'Brillando';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  calculateLumaData — convierte ProfileModel → LumaData
//
//  Punto de entrada principal. Los cosmetics se leen por índice y se
//  clampean para no romper si la BD tiene un valor fuera de rango.
// ─────────────────────────────────────────────────────────────────────────────
LumaData calculateLumaData(ProfileModel profile) {
  return LumaData(
    state:     _calculateState(profile),
    evolution: _calculateEvolution(profile),
    bodyColor: LumaBodyColor.values[
        profile.equippedBodyColor.clamp(0, LumaBodyColor.values.length - 1)],
    accessory: LumaAccessory.values[
        profile.equippedAccessory.clamp(0, LumaAccessory.values.length - 1)],
    eyes:      LumaEyes.values[
        profile.equippedEyes.clamp(0, LumaEyes.values.length - 1)],
  );
}

// ── Lógica de estado emocional ─────────────────────────────────────────────
// Jerarquía de prioridad (primera condición que se cumpla gana):
//   1. sleeping  — inactividad prolongada (≥48h): Luma "se apaga"
//   2. tired     — uso nocturno detectado: Luma está cansada
//   3. glowing   — racha larga + nivel alto: Luma en su mejor momento
//   4. excited   — racha media: Luma emocionada
//   5. happy     — racha corta: Luma contenta
//   6. normal    — sin racha activa
LumaState _calculateState(ProfileModel profile) {
  final now = DateTime.now();

  // Prioridad 1 — inactividad ≥48h
  if (profile.lastActive != null &&
      now.difference(profile.lastActive!).inHours >= 48) {
    return LumaState.sleeping;
  }

  // Prioridad 2 — uso nocturno detectado
  if (profile.hadNightUsage) return LumaState.tired;

  final streak = profile.streakDays;
  final level  = profile.autonomyLevel;

  // Prioridad 3-6 — basadas en progreso
  if (streak >= 7 && level >= 3) return LumaState.glowing;
  if (streak >= 3)               return LumaState.excited;
  if (streak >= 1)               return LumaState.happy;
  return LumaState.normal;
}

// ── Lógica de evolución ────────────────────────────────────────────────────
// guardian: nivel 4+ (maestría digital)
// growing:  nivel 3 o racha activa de 3+ días
// sprout:   estado inicial, aún aprendiendo
LumaEvolution _calculateEvolution(ProfileModel profile) {
  if (profile.autonomyLevel >= 4)                               return LumaEvolution.guardian;
  if (profile.autonomyLevel >= 3 || profile.streakDays >= 3)   return LumaEvolution.growing;
  return LumaEvolution.sprout;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CATÁLOGO DE COSMÉTICOS
//
//  Define todos los ítems disponibles en la tienda de personalización.
//  El campo `index` mapea directamente a la posición en el enum correspondiente
//  (LumaBodyColor, LumaAccessory, LumaEyes) y es lo que se guarda en Supabase.
//
//  Estructura de costos:
//   - Costo 0   → desbloqueado por defecto
//   - Costo 25-60 → gama media, alcanzable en 1-2 semanas de uso
//   - Costo 80-120 → gama alta, requiere constancia prolongada
// ─────────────────────────────────────────────────────────────────────────────
class LumaCosmeticItem {
  final String id, name, emoji, type;
  final int cost, index;
  const LumaCosmeticItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.type,
    required this.index,
  });
}

const List<LumaCosmeticItem> lumaCatalog = [
  // ── Colores de cuerpo ──────────────────────────────────────────────────────
  LumaCosmeticItem(id: "body_mint",  name: "Verde menta", emoji: "🟢", cost: 0,   type: "body", index: 0),
  LumaCosmeticItem(id: "body_lilac", name: "Lila",        emoji: "🟣", cost: 30,  type: "body", index: 1),
  LumaCosmeticItem(id: "body_sky",   name: "Azul cielo",  emoji: "🔵", cost: 50,  type: "body", index: 2),
  LumaCosmeticItem(id: "body_pink",  name: "Rosa",        emoji: "🩷", cost: 50,  type: "body", index: 3),
  LumaCosmeticItem(id: "body_gold",  name: "Dorado",      emoji: "🟡", cost: 100, type: "body", index: 4),

  // ── Accesorios ─────────────────────────────────────────────────────────────
  LumaCosmeticItem(id: "acc_none",       name: "Sin accesorio", emoji: "—",  cost: 0,  type: "accessory", index: 0),
  LumaCosmeticItem(id: "acc_flower",     name: "Flor",          emoji: "🌸", cost: 25, type: "accessory", index: 1),
  LumaCosmeticItem(id: "acc_antennas",   name: "Antenas",       emoji: "⚡", cost: 35, type: "accessory", index: 2),
  LumaCosmeticItem(id: "acc_cap",        name: "Birrete",       emoji: "🎓", cost: 40, type: "accessory", index: 3),
  LumaCosmeticItem(id: "acc_headphones", name: "Auriculares",   emoji: "🎧", cost: 60, type: "accessory", index: 4),
  LumaCosmeticItem(id: "acc_crown",      name: "Corona",        emoji: "👑", cost: 80, type: "accessory", index: 5),

  // ── Ojos ───────────────────────────────────────────────────────────────────
  LumaCosmeticItem(id: "eyes_normal",     name: "Normal",        emoji: "👀", cost: 0,   type: "eyes", index: 0),
  LumaCosmeticItem(id: "eyes_sunglasses", name: "Gafas de sol",  emoji: "😎", cost: 45,  type: "eyes", index: 1),
  LumaCosmeticItem(id: "eyes_stars",      name: "Ojos estrella", emoji: "🌟", cost: 70,  type: "eyes", index: 2),
  LumaCosmeticItem(id: "eyes_rainbow",    name: "Arco iris",     emoji: "🌈", cost: 90,  type: "eyes", index: 3),
  LumaCosmeticItem(id: "eyes_diamond",    name: "Diamante",      emoji: "💎", cost: 120, type: "eyes", index: 4),
];