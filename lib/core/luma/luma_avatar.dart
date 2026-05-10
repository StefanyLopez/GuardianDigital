import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'luma_state.dart';
import 'luma_painter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LumaAvatar — widget animado del personaje Luma
//
//  Orquesta 4 AnimationControllers independientes y los pasa como valores
//  al CustomPainter (LumaBlobPainter) y a los efectos de partícula/sparkle.
//
//  Parámetros:
//   lumaData  — snapshot visual calculado desde ProfileModel (ver luma_state.dart)
//   size      — tamaño del blob; si null, usa lumaData.blobSize o chatBlobSize
//   isChat    — modo compacto para la burbuja del chat (desactiva partículas)
//   onTap     — callback opcional para abrir el perfil de Luma
//
//  Animaciones:
//   _breathCtrl  — escala 1.0→1.06 (2s, loop reverse) — efecto respiración
//   _floatCtrl   — offset Y -4→+4px (3s, loop reverse) — efecto flotación
//   _shimmerCtrl — opacidad 0→1 (150ms, disparo puntual) — parpadeo de ojos
//   _particleCtrl— progreso 0→1 (2.5s, loop) — posición partículas orbitales
//
//  Notas de rendimiento:
//   - AnimatedBuilder escucha los 4 controllers en un Listenable.merge,
//     lo que minimiza rebuilds a un solo nodo.
//   - Las partículas y sparkles solo se generan cuando sus flags están activos
//     (hasParticles, hasStarSparkles), evitando cómputo innecesario.
//   - shouldRepaint en LumaBlobPainter filtra redraws sin cambios visuales.
// ─────────────────────────────────────────────────────────────────────────────
class LumaAvatar extends StatefulWidget {
  final LumaData lumaData;
  final double? size;
  final bool isChat;
  final VoidCallback? onTap;

  const LumaAvatar({
    super.key,
    required this.lumaData,
    this.size,
    this.isChat = false,
    this.onTap,
  });

  @override
  State<LumaAvatar> createState() => _LumaAvatarState();
}

class _LumaAvatarState extends State<LumaAvatar> with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _breathAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _particleAnim;

  final _random = math.Random();
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scheduleRandomBlink();
  }

  void _initAnimations() {
    // ── Respiración: escala uniforme del blob ────────────────────────────────
    // Velocidad se ajusta en didUpdateWidget si el estado cambia a sleeping.
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _breathAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );

    // ── Flotación: movimiento vertical suave ─────────────────────────────────
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // ── Shimmer: destello puntual para el parpadeo ───────────────────────────
    // No hace loop — se dispara manualmente en _doBlink().
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeOut),
    );

    // ── Partículas: ciclo continuo para el estado glowing ────────────────────
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _particleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_particleCtrl);
  }

  // ── Parpadeo aleatorio ─────────────────────────────────────────────────────
  // Intervalo aleatorio entre 4 y 8 segundos para que se sienta orgánico.
  // El ciclo es: forward shimmer → pausa 80ms → reverse shimmer → reprogramar.
  void _scheduleRandomBlink() {
    final delay = Duration(milliseconds: 4000 + _random.nextInt(4000));
    Future.delayed(delay, () {
      if (!mounted) return;
      _doBlink();
    });
  }

  Future<void> _doBlink() async {
    if (!mounted) return;
    setState(() => _isBlinking = true);
    await _shimmerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _shimmerCtrl.reverse();
    if (mounted) {
      setState(() => _isBlinking = false);
      _scheduleRandomBlink();
    }
  }

  // ── Ajuste de velocidad al cambiar estado ──────────────────────────────────
  // sleeping tiene respiración más lenta (4s) para reforzar la sensación
  // de inactividad sin tener que parar la animación.
  @override
  void didUpdateWidget(LumaAvatar old) {
    super.didUpdateWidget(old);
    if (widget.lumaData.state == LumaState.sleeping) {
      _breathCtrl.duration = const Duration(milliseconds: 4000);
    } else {
      _breathCtrl.duration = const Duration(milliseconds: 2000);
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ??
        (widget.isChat
            ? widget.lumaData.chatBlobSize
            : widget.lumaData.blobSize);

    // En estado tired la flotación es mínima (1.5px) en vez de 4px
    final floatRange = widget.lumaData.state == LumaState.tired ? 1.5 : 4.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_breathAnim, _floatAnim, _shimmerAnim, _particleAnim]),
        builder: (context, _) {
          final floatOffset = (_floatAnim.value / 4.0) * floatRange;

          return SizedBox(
            // El SizedBox es más grande que el blob para dar espacio
            // a partículas, sparkles y halo sin clipping.
            width:  size * 1.6,
            height: size * 1.7,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Partículas orbitales (solo glowing, no en chat) ──────────
                if (widget.lumaData.hasParticles && !widget.isChat)
                  ..._buildParticles(size, _particleAnim.value),

                // ── Blob principal con todos sus rasgos ──────────────────────
                CustomPaint(
                  size: Size(size, size),
                  painter: LumaBlobPainter(
                    lumaData:    widget.lumaData,
                    breathScale: _breathAnim.value,
                    floatOffset: floatOffset,
                  ),
                ),

                // ── Shimmer de parpadeo / estados brillantes ─────────────────
                // Overlay blanco semitransparente que pulsa en blink,
                // glowing y excited para dar sensación de destello.
                if (_isBlinking ||
                    widget.lumaData.state == LumaState.glowing ||
                    widget.lumaData.state == LumaState.excited)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _shimmerAnim.value * 0.15,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(size),
                        ),
                      ),
                    ),
                  ),

                // ── Destellos estrella (solo excited, no en chat) ────────────
                if (widget.lumaData.hasStarSparkles && !widget.isChat)
                  ..._buildSparkles(size, _breathAnim.value),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Partículas orbitales ───────────────────────────────────────────────────
  // 6 puntos que orbitan el blob en elipse (ratio 0.6 en Y para perspectiva).
  // La opacidad y el tamaño oscilan con seno para que se vean más orgánicos.
  List<Widget> _buildParticles(double size, double progress) {
    const count = 6;
    return List.generate(count, (i) {
      final angle = (i / count) * 2 * math.pi + progress * 2 * math.pi;
      final dist  = size * (0.70 + 0.18 * math.sin(progress * math.pi * 2 + i));
      final px    = size * 0.8 + dist * math.cos(angle);
      final py    = size * 0.85 + dist * math.sin(angle) * 0.6;
      final opacity = 0.4 + 0.5 * math.sin(progress * math.pi * 2 + i * 1.2).abs();
      final pSize = size * (0.04 + 0.03 * math.sin(i * 1.5));
      return Positioned(
        left: px, top: py,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: pSize, height: pSize,
            decoration: const BoxDecoration(
                color: Colors.amber, shape: BoxShape.circle),
          ),
        ),
      );
    });
  }

  // ── Destellos ✦ para estado excited ──────────────────────────────────────
  // 4 posiciones fijas alrededor del blob que pulsan con breathValue.
  // Usan el carácter ✦ en lugar de un CustomPaint para mantener
  // el código simple sin perder el efecto visual.
  List<Widget> _buildSparkles(double size, double breathValue) {
    const positions = [
      (-0.72, -0.42), (0.68, -0.38), (0.74, 0.20), (-0.10, -0.82),
    ];
    return positions.indexed.map((entry) {
      final i   = entry.$1;
      final pos = entry.$2;
      final pulse = (math.sin(breathValue * math.pi * 2 + i * 1.5) + 1) / 2;
      return Positioned(
        left: size * 0.8 + size * pos.$1,
        top:  size * 0.85 + size * pos.$2,
        child: Opacity(
          opacity: 0.5 + 0.5 * pulse,
          child: Text('✦',
              style: TextStyle(
                fontSize: size * (0.10 + 0.04 * pulse),
                color: const Color(0xFF9B7FE8),
              )),
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LumaStatusBanner — nombre de estado y evolución debajo del avatar
//
//  Widget separado para mantener LumaAvatar enfocado en la animación.
//  Usa Theme.of(context) directamente para adaptarse al modo claro/oscuro
//  sin depender de GDColors (puede usarse fuera del contexto de la app).
// ─────────────────────────────────────────────────────────────────────────────
class LumaStatusBanner extends StatelessWidget {
  final LumaData lumaData;
  const LumaStatusBanner({super.key, required this.lumaData});

  @override
  Widget build(BuildContext context) {
    final stateEmoji = switch (lumaData.state) {
      LumaState.tired    => '😴',
      LumaState.sleeping => '💤',
      LumaState.normal   => '🌿',
      LumaState.happy    => '😊',
      LumaState.excited  => '🎉',
      LumaState.glowing  => '✨',
    };

    return Column(children: [
      // ── Chip de estado ───────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(stateEmoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(lumaData.stateName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              )),
        ]),
      ),
      const SizedBox(height: 4),
      // ── Nombre de evolución ──────────────────────────────────────────────
      Text(lumaData.evolutionName,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          )),
    ]);
  }
}