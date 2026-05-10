import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'luma_state.dart';
import 'luma_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LumaBlobPainter — CustomPainter del cuerpo de Luma
//
//  Recibe LumaData + valores de animación y dibuja todo el personaje en canvas.
//  No tiene estado propio — es puro y predecible dado los mismos inputs.
//
//  Orden de capas (de abajo hacia arriba):
//   1. Halo exterior     (solo Guardian)
//   2. Sombra proyectada (oval borroso debajo del blob)
//   3. Blob base         (forma orgánica coloreada)
//   4. Tinte de estado   (capa semitransparente encima del blob)
//   5. Highlight especular (gradiente radial blanco, efecto 3D)
//   6. Mejillas          (ovals rosados)
//   7. Ojos              (varía según LumaEyes y LumaState)
//   8. Boca              (varía según LumaState)
//   9. Accesorio         (varía según LumaAccessory)
//
//  Animaciones que recibe del widget padre (LumaAvatar):
//   breathScale  — escala uniforme 1.0→1.06, ciclo 2s (respiración)
//   floatOffset  — desplazamiento Y -4→+4px, ciclo 3s (flotación)
// ─────────────────────────────────────────────────────────────────────────────
class LumaBlobPainter extends CustomPainter {
  final LumaData lumaData;
  final double breathScale;
  final double floatOffset;

  const LumaBlobPainter({
    required this.lumaData,
    this.breathScale = 1.0,
    this.floatOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + floatOffset;
    final r  = (size.width / 2) * breathScale;

    // Colores derivados del perfil actual
    final bodyColor   = LumaColors.bodyBase(lumaData.bodyColor);
    final shadowColor = LumaColors.bodyShadow(lumaData.bodyColor);
    final tintColor   = LumaColors.stateTint(lumaData.state);

    // ── 1. Halo (solo evolución Guardian) ─────────────────────────────────
    if (lumaData.hasHalo) {
      canvas.drawCircle(Offset(cx, cy), r * 1.28,
          Paint()
            ..color = LumaColors.haloColor(lumaData.bodyColor)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(cx, cy), r * 1.14,
          Paint()
            ..color = LumaColors.haloColor(lumaData.bodyColor).withValues(alpha: 0.15)
            ..style = PaintingStyle.fill);
    }

    // ── 2. Sombra proyectada ───────────────────────────────────────────────
    // Oval borroso debajo del blob para sensación de profundidad/elevación.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + r * 0.72),
          width: r * 1.4,
          height: r * 0.36),
      Paint()
        ..color = shadowColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── 3. Blob base ───────────────────────────────────────────────────────
    canvas.drawPath(
        _blobPath(cx, cy, r, lumaData.evolution),
        Paint()..color = bodyColor..style = PaintingStyle.fill);

    // ── 4. Tinte de estado ─────────────────────────────────────────────────
    if (tintColor != Colors.transparent) {
      canvas.drawPath(
          _blobPath(cx, cy, r, lumaData.evolution),
          Paint()..color = tintColor..style = PaintingStyle.fill);
    }

    // ── 5. Highlight especular ─────────────────────────────────────────────
    // Gradiente radial centrado en la esquina superior-izquierda
    // del blob para simular iluminación volumétrica.
    canvas.drawPath(
        _blobPath(cx, cy, r, lumaData.evolution),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.5),
            radius: 0.7,
            colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // ── 6-9. Rasgos faciales y accesorio ───────────────────────────────────
    _paintCheeks(canvas, cx, cy, r, shadowColor);
    _paintEyes(canvas, cx, cy, r, lumaData.eyes, lumaData.state);
    _paintMouth(canvas, cx, cy, r, lumaData.state);
    if (lumaData.accessory != LumaAccessory.none) {
      _paintAccessory(canvas, cx, cy, r, lumaData.accessory);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  _blobPath — forma orgánica del cuerpo según evolución
  //
  //  Cada evolución tiene una silueta distinta construida con cúbicas Bézier.
  //  Los puntos de control están expresados como múltiplos de `r` para que
  //  escalen correctamente con breathScale.
  //
  //   sprout   → más simétrico y compacto (forma de huevo)
  //   growing  → asimetría leve, más fluido
  //   guardian → más alto y expansivo, preparado para llevar el halo
  // ─────────────────────────────────────────────────────────────────────────
  Path _blobPath(double cx, double cy, double r, LumaEvolution evo) {
    final path = Path();
    switch (evo) {
      case LumaEvolution.sprout:
        path.moveTo(cx, cy - r * 0.90);
        path.cubicTo(cx + r*0.60, cy - r*0.90, cx + r*0.90, cy - r*0.45, cx + r*0.90, cy);
        path.cubicTo(cx + r*0.90, cy + r*0.52, cx + r*0.55, cy + r*0.80, cx, cy + r*0.80);
        path.cubicTo(cx - r*0.55, cy + r*0.80, cx - r*0.92, cy + r*0.50, cx - r*0.92, cy);
        path.cubicTo(cx - r*0.92, cy - r*0.48, cx - r*0.60, cy - r*0.90, cx, cy - r*0.90);
        break;
      case LumaEvolution.growing:
        path.moveTo(cx, cy - r * 0.92);
        path.cubicTo(cx + r*0.55, cy - r*0.92, cx + r*0.95, cy - r*0.50, cx + r*0.88, cy + r*0.05);
        path.cubicTo(cx + r*0.80, cy + r*0.60, cx + r*0.45, cy + r*0.88, cx, cy + r*0.85);
        path.cubicTo(cx - r*0.60, cy + r*0.88, cx - r*0.95, cy + r*0.52, cx - r*0.90, cy - r*0.05);
        path.cubicTo(cx - r*0.85, cy - r*0.58, cx - r*0.55, cy - r*0.92, cx, cy - r*0.92);
        break;
      case LumaEvolution.guardian:
        path.moveTo(cx, cy - r * 0.95);
        path.cubicTo(cx + r*0.50, cy - r*0.95, cx + r*0.98, cy - r*0.52, cx + r*0.92, cy);
        path.cubicTo(cx + r*0.86, cy + r*0.58, cx + r*0.50, cy + r*0.90, cx, cy + r*0.88);
        path.cubicTo(cx - r*0.52, cy + r*0.90, cx - r*0.88, cy + r*0.56, cx - r*0.94, cy - r*0.02);
        path.cubicTo(cx - r*1.00, cy - r*0.58, cx - r*0.50, cy - r*0.95, cx, cy - r*0.95);
        break;
    }
    path.close();
    return path;
  }

  // ── Mejillas ───────────────────────────────────────────────────────────────
  // Dos ovals semitransparentes a ±40% del centro horizontal.
  void _paintCheeks(Canvas canvas, double cx, double cy, double r, Color shadowColor) {
    final p = Paint()
      ..color = shadowColor.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - r*0.40, cy + r*0.18), width: r*0.32, height: r*0.18), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + r*0.40, cy + r*0.18), width: r*0.32, height: r*0.18), p);
  }

  // ── Ojos ───────────────────────────────────────────────────────────────────
  // El estado tiene prioridad sobre el tipo de ojo:
  //   sleeping → ojos cerrados (arco curvo hacia abajo)
  //   tired    → ojos a medio abrir (mitad del blob tapa el ojo)
  //   demás    → se respeta el tipo equipado (LumaEyes)
  void _paintEyes(Canvas canvas, double cx, double cy, double r, LumaEyes eyes, LumaState state) {
    const eyeColor = Color(0xFF2C3E50);
    final eyeOffX  = r * 0.28;
    final eyeY     = cy - r * 0.08;

    if (state == LumaState.sleeping) {
      _drawClosedEye(canvas, cx - eyeOffX, eyeY, r*0.16, eyeColor);
      _drawClosedEye(canvas, cx + eyeOffX, eyeY, r*0.16, eyeColor);
      return;
    }
    if (state == LumaState.tired) {
      _drawHalfEye(canvas, cx - eyeOffX, eyeY, r*0.14, eyeColor, LumaColors.bodyBase(lumaData.bodyColor));
      _drawHalfEye(canvas, cx + eyeOffX, eyeY, r*0.14, eyeColor, LumaColors.bodyBase(lumaData.bodyColor));
      return;
    }

    switch (eyes) {
      case LumaEyes.normal:
        _drawNormalEye(canvas, cx - eyeOffX, eyeY, r*0.14, eyeColor);
        _drawNormalEye(canvas, cx + eyeOffX, eyeY, r*0.14, eyeColor);
        break;
      case LumaEyes.sunglasses:
        _drawSunglasses(canvas, cx, eyeY, r, eyeColor);
        break;
      case LumaEyes.stars:
        _drawStarEye(canvas, cx - eyeOffX, eyeY, r*0.16);
        _drawStarEye(canvas, cx + eyeOffX, eyeY, r*0.16);
        break;
      case LumaEyes.rainbow:
        _drawRainbowEye(canvas, cx - eyeOffX, eyeY, r*0.15);
        _drawRainbowEye(canvas, cx + eyeOffX, eyeY, r*0.15);
        break;
      case LumaEyes.diamond:
        _drawDiamondEye(canvas, cx - eyeOffX, eyeY, r*0.15);
        _drawDiamondEye(canvas, cx + eyeOffX, eyeY, r*0.15);
        break;
    }
  }

  // Ojo normal: oval + punto de luz especular
  void _drawNormalEye(Canvas canvas, double x, double y, double s, Color c) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: s*1.4, height: s*1.8),
        Paint()..color = c..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(x + s*0.3, y - s*0.4), s*0.35,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  // Ojo cerrado: arco con bezier cuadrado (sonrisa invertida)
  void _drawClosedEye(Canvas canvas, double x, double y, double s, Color c) {
    final p = Paint()
      ..color = c
      ..strokeWidth = s*0.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
        Path()..moveTo(x - s, y)..quadraticBezierTo(x, y + s*0.8, x + s, y), p);
  }

  // Ojo semicerrado: el rectángulo del color del blob tapa la mitad superior
  void _drawHalfEye(Canvas canvas, double x, double y, double s, Color c, Color blobColor) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + s*0.3), width: s*1.6, height: s),
        Paint()..color = c..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromLTWH(x - s, y - s*0.5, s*2, s*0.8),
        Paint()..color = blobColor..style = PaintingStyle.fill);
  }

  // Gafas de sol: dos rectángulos redondeados conectados por un puente
  void _drawSunglasses(Canvas canvas, double cx, double y, double r, Color c) {
    final fill  = Paint()..color = const Color(0xFF1A1A2E)..style = PaintingStyle.fill;
    final frame = Paint()..color = const Color(0xFF2C3E50)..style = PaintingStyle.stroke..strokeWidth = r*0.04;
    final eyeW  = r*0.24;
    final eyeH  = r*0.18;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - r*0.28, y), width: eyeW, height: eyeH), const Radius.circular(4)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + r*0.28, y), width: eyeW, height: eyeH), const Radius.circular(4)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - r*0.28, y), width: eyeW, height: eyeH), const Radius.circular(4)), frame);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + r*0.28, y), width: eyeW, height: eyeH), const Radius.circular(4)), frame);
    canvas.drawLine(Offset(cx - r*0.16, y), Offset(cx + r*0.16, y), frame); // puente
  }

  // Ojo estrella: polígono de 5 puntas con radio interior al 40%
  void _drawStarEye(Canvas canvas, double x, double y, double s) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final oa = (i * 72 - 90) * math.pi / 180;
      final ia = ((i * 72 + 36) - 90) * math.pi / 180;
      if (i == 0) path.moveTo(x + s*math.cos(oa), y + s*math.sin(oa));
      else        path.lineTo(x + s*math.cos(oa), y + s*math.sin(oa));
      path.lineTo(x + s*0.4*math.cos(ia), y + s*0.4*math.sin(ia));
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF4B942)..style = PaintingStyle.fill);
  }

  // Ojo arco iris: círculos concéntricos de 6 colores + especular
  void _drawRainbowEye(Canvas canvas, double x, double y, double s) {
    const colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Color(0xFF4488FF), Colors.purple];
    for (int i = 0; i < colors.length; i++) {
      canvas.drawCircle(Offset(x, y), s*(1 - i*0.14),
          Paint()..color = colors[i]..style = PaintingStyle.fill);
    }
    canvas.drawCircle(Offset(x + s*0.28, y - s*0.32), s*0.22,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  // Ojo diamante: rombo con punto de luz
  void _drawDiamondEye(Canvas canvas, double x, double y, double s) {
    canvas.drawPath(
      Path()
        ..moveTo(x, y - s)
        ..lineTo(x + s*0.7, y)
        ..lineTo(x, y + s*0.6)
        ..lineTo(x - s*0.7, y)
        ..close(),
      Paint()..color = const Color(0xFF88DDFF)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(x + s*0.2, y - s*0.4), s*0.25,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  // ── Boca ───────────────────────────────────────────────────────────────────
  // Varía según estado emocional:
  //   tired/sleeping → línea recta (neutral/dormida)
  //   normal/happy   → sonrisa suave (curva cuadrática)
  //   excited/glowing→ sonrisa amplia + diente blanco rectangular
  void _paintMouth(Canvas canvas, double cx, double cy, double r, LumaState state) {
    final p = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = r*0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mY = cy + r*0.30;
    final mW = r*0.30;

    switch (state) {
      case LumaState.tired:
      case LumaState.sleeping:
        canvas.drawLine(Offset(cx - mW*0.6, mY), Offset(cx + mW*0.6, mY), p);
        break;
      case LumaState.normal:
      case LumaState.happy:
        canvas.drawPath(
            Path()..moveTo(cx - mW, mY)..quadraticBezierTo(cx, mY + r*0.18, cx + mW, mY), p);
        break;
      case LumaState.excited:
      case LumaState.glowing:
        canvas.drawPath(
            Path()..moveTo(cx - mW*1.1, mY - r*0.04)..quadraticBezierTo(cx, mY + r*0.28, cx + mW*1.1, mY - r*0.04), p);
        // Diente blanco
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(cx, mY + r*0.10), width: r*0.20, height: r*0.14),
                const Radius.circular(2)),
            Paint()..color = Colors.white..style = PaintingStyle.fill);
        break;
    }
  }

  // ── Accesorios ─────────────────────────────────────────────────────────────
  // Se anclan a topY = cy - r*0.88 (parte superior del blob).
  // Escalan con r para mantener proporciones en todas las evoluciones.
  void _paintAccessory(Canvas canvas, double cx, double cy, double r, LumaAccessory acc) {
    final topY = cy - r * 0.88;
    switch (acc) {
      case LumaAccessory.none:        break;
      case LumaAccessory.flower:      _drawFlower(canvas, cx + r*0.42, topY - r*0.04, r*0.22); break;
      case LumaAccessory.antennas:    _drawAntennas(canvas, cx, topY, r); break;
      case LumaAccessory.cap:         _drawCap(canvas, cx, topY, r); break;
      case LumaAccessory.headphones:  _drawHeadphones(canvas, cx, cy, r); break;
      case LumaAccessory.crown:       _drawCrown(canvas, cx, topY, r); break;
    }
  }

  // Flor: 5 pétalos rosas + centro amarillo
  void _drawFlower(Canvas canvas, double x, double y, double s) {
    final pp = Paint()..color = const Color(0xFFF090B0)..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final a = i * 72 * math.pi / 180;
      canvas.drawCircle(Offset(x + s*0.55*math.cos(a), y + s*0.55*math.sin(a)), s*0.38, pp);
    }
    canvas.drawCircle(Offset(x, y), s*0.38,
        Paint()..color = const Color(0xFFF4D03F)..style = PaintingStyle.fill);
  }

  // Antenas: dos varillas con bola dorada en la punta
  void _drawAntennas(Canvas canvas, double cx, double topY, double r) {
    final lp = Paint()..color = const Color(0xFF2C3E50)..strokeWidth = r*0.05..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final bp = Paint()..color = const Color(0xFFF4B942)..style = PaintingStyle.fill;
    canvas.drawLine(Offset(cx - r*0.28, topY + r*0.04), Offset(cx - r*0.44, topY - r*0.34), lp);
    canvas.drawCircle(Offset(cx - r*0.44, topY - r*0.34), r*0.09, bp);
    canvas.drawLine(Offset(cx + r*0.28, topY + r*0.04), Offset(cx + r*0.44, topY - r*0.34), lp);
    canvas.drawCircle(Offset(cx + r*0.44, topY - r*0.34), r*0.09, bp);
  }

  // Birrete: ala + cuerpo rectangular + borla
  void _drawCap(Canvas canvas, double cx, double topY, double r) {
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, topY + r*0.06), width: r*0.90, height: r*0.18),
        Paint()..color = const Color(0xFF1A1A2E)..style = PaintingStyle.fill);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, topY - r*0.14), width: r*0.68, height: r*0.34), const Radius.circular(3)),
        Paint()..color = const Color(0xFF2C3E50)..style = PaintingStyle.fill);
    canvas.drawLine(Offset(cx, topY - r*0.30), Offset(cx + r*0.26, topY - r*0.44),
        Paint()..color = const Color(0xFFF4B942)..strokeWidth = r*0.04..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    canvas.drawCircle(Offset(cx + r*0.28, topY - r*0.46), r*0.08,
        Paint()..color = const Color(0xFFF4B942)..style = PaintingStyle.fill);
  }

  // Auriculares: arco semicircular + dos cojinetes morados
  void _drawHeadphones(Canvas canvas, double cx, double cy, double r) {
    canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy - r*0.30), width: r*1.0, height: r*0.70),
        math.pi, math.pi, false,
        Paint()..color = const Color(0xFF2C3E50)..strokeWidth = r*0.10..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    final cp = Paint()..color = const Color(0xFF9B7FE8)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - r*0.50, cy - r*0.30), r*0.16, cp);
    canvas.drawCircle(Offset(cx + r*0.50, cy - r*0.30), r*0.16, cp);
  }

  // Corona: silueta con 3 puntas + gemas rojas
  void _drawCrown(Canvas canvas, double cx, double topY, double r) {
    canvas.drawPath(
      Path()
        ..moveTo(cx - r*0.44, topY + r*0.08)
        ..lineTo(cx - r*0.44, topY - r*0.30)
        ..lineTo(cx - r*0.22, topY - r*0.12)
        ..lineTo(cx, topY - r*0.44)
        ..lineTo(cx + r*0.22, topY - r*0.12)
        ..lineTo(cx + r*0.44, topY - r*0.30)
        ..lineTo(cx + r*0.44, topY + r*0.08)
        ..close(),
      Paint()..color = const Color(0xFFF4B942)..style = PaintingStyle.fill);
    final gp = Paint()..color = const Color(0xFFE74C3C)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, topY - r*0.36), r*0.07, gp);
    canvas.drawCircle(Offset(cx - r*0.36, topY - r*0.18), r*0.055, gp);
    canvas.drawCircle(Offset(cx + r*0.36, topY - r*0.18), r*0.055, gp);
  }

  // ── shouldRepaint ──────────────────────────────────────────────────────────
  // Solo repinta si cambió algo visual. Evita redraws innecesarios en frames
  // donde el AnimationController avanzó pero los valores son idénticos.
  @override
  bool shouldRepaint(LumaBlobPainter old) =>
      old.breathScale   != breathScale        ||
      old.floatOffset   != floatOffset        ||
      old.lumaData.state      != lumaData.state      ||
      old.lumaData.evolution  != lumaData.evolution  ||
      old.lumaData.bodyColor  != lumaData.bodyColor  ||
      old.lumaData.accessory  != lumaData.accessory  ||
      old.lumaData.eyes       != lumaData.eyes;
}