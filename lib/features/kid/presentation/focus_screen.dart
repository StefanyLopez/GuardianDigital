import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/luma/luma_state.dart';
import '../../../core/luma/luma_avatar.dart';
import '../providers/profile_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FOCUS SCREEN
//  Selector entre Timer Pomodoro y Respiración guiada con Luma.
//  Ruta: /kid/:profileId/focus
// ─────────────────────────────────────────────────────────────────────────────
class FocusScreen extends ConsumerWidget {
  final String profileId;
  const FocusScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileByIdProvider(profileId)).valueOrNull;
    final lumaData = profile != null
        ? calculateLumaData(profile)
        : const LumaData(
            state: LumaState.happy,
            evolution: LumaEvolution.sprout,
            bodyColor: LumaBodyColor.mint,
            accessory: LumaAccessory.none,
            eyes: LumaEyes.normal,
          );
    final c = context.gd;

    return Scaffold(
      appBar: AppBar(
        title: Text('Concentración y calma', style: GDTypography.headlineMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GDSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Luma y mensaje
            Center(
              child: Column(children: [
                LumaAvatar(lumaData: lumaData, size: 90),
                const Gap(GDSpacing.md),
                Text(
                  '¿Qué necesitas ahora mismo?',
                  style: GDTypography.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const Gap(GDSpacing.xs),
                Text(
                  'Elige una técnica y Luma te acompaña.',
                  style: GDTypography.bodyMedium
                      .copyWith(color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ]),
            ).animate().fadeIn().slideY(begin: -0.1),

            const Gap(GDSpacing.xl),

            // ── POMODORO ────────────────────────────────────────────────
            _FocusCard(
              emoji: '🍅',
              title: 'Timer Pomodoro',
              description:
                  '25 minutos de enfoque total, 5 de descanso. Sin distracciones.',
              color: const Color(0xFFE74C3C),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _PomodoroScreen(),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

            const Gap(GDSpacing.md),

            // ── RESPIRACIÓN ─────────────────────────────────────────────
            _FocusCard(
              emoji: '🌬️',
              title: 'Respiración 4-7-8',
              description:
                  'Inhala 4s, retén 7s, exhala 8s. Reduce la ansiedad en minutos.',
              color: const Color(0xFF3498DB),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _BreathingScreen(lumaData: lumaData),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),

            const Gap(GDSpacing.md),

            // ── RESPIRACIÓN BOX ─────────────────────────────────────────
            _FocusCard(
              emoji: '⬜',
              title: 'Respiración cuadrada',
              description:
                  '4s inhala · 4s retén · 4s exhala · 4s retén. Usada por atletas.',
              color: const Color(0xFF9B59B6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      _BreathingScreen(lumaData: lumaData, mode: BreathingMode.box),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),

            const Gap(GDSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String emoji, title, description;
  final Color color;
  final VoidCallback onTap;

  const _FocusCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(GDSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: GDRadius.lgAll,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: GDRadius.mdAll,
            ),
            child:
                Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const Gap(GDSpacing.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GDTypography.titleLarge),
              const Gap(2),
              Text(description,
                  style: GDTypography.bodySmall
                      .copyWith(color: context.gd.textSecondary)),
            ],
          )),
          Icon(Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  POMODORO SCREEN
// ─────────────────────────────────────────────────────────────────────────────
enum PomodoroPhase { work, shortBreak, longBreak }

class _PomodoroScreen extends StatefulWidget {
  const _PomodoroScreen();

  @override
  State<_PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<_PomodoroScreen> {
  static const _workSeconds      = 25 * 60;
  static const _shortBreakSeconds = 5 * 60;
  static const _longBreakSeconds  = 15 * 60;

  PomodoroPhase _phase = PomodoroPhase.work;
  int _secondsLeft = _workSeconds;
  int _completedPomodoros = 0;
  bool _isRunning = false;
  Timer? _timer;

  int get _totalSeconds {
    switch (_phase) {
      case PomodoroPhase.work:       return _workSeconds;
      case PomodoroPhase.shortBreak: return _shortBreakSeconds;
      case PomodoroPhase.longBreak:  return _longBreakSeconds;
    }
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft <= 0) {
          _onPhaseComplete();
        } else {
          setState(() => _secondsLeft--);
        }
      });
      setState(() => _isRunning = true);
    }
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_phase == PomodoroPhase.work) {
        _completedPomodoros++;
        _phase = _completedPomodoros % 4 == 0
            ? PomodoroPhase.longBreak
            : PomodoroPhase.shortBreak;
      } else {
        _phase = PomodoroPhase.work;
      }
      _secondsLeft = _totalSeconds;
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsLeft = _totalSeconds;
    });
  }

  void _setPhase(PomodoroPhase phase) {
    _timer?.cancel();
    setState(() {
      _phase = phase;
      _isRunning = false;
      _secondsLeft = _totalSeconds;
    });
  }

  String get _timeLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _phaseColor {
    switch (_phase) {
      case PomodoroPhase.work:       return const Color(0xFFE74C3C);
      case PomodoroPhase.shortBreak: return const Color(0xFF27AE60);
      case PomodoroPhase.longBreak:  return const Color(0xFF2980B9);
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case PomodoroPhase.work:       return '🍅 Concentración';
      case PomodoroPhase.shortBreak: return '☕ Descanso corto';
      case PomodoroPhase.longBreak:  return '🌿 Descanso largo';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_secondsLeft / _totalSeconds);
    final c = context.gd;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pomodoro', style: GDTypography.headlineMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(GDSpacing.lg),
        child: Column(
          children: [
            // Selector de fase
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PhaseChip(
                  label: 'Trabajo',
                  active: _phase == PomodoroPhase.work,
                  color: const Color(0xFFE74C3C),
                  onTap: () => _setPhase(PomodoroPhase.work),
                ),
                const Gap(GDSpacing.sm),
                _PhaseChip(
                  label: 'Descanso',
                  active: _phase == PomodoroPhase.shortBreak,
                  color: const Color(0xFF27AE60),
                  onTap: () => _setPhase(PomodoroPhase.shortBreak),
                ),
                const Gap(GDSpacing.sm),
                _PhaseChip(
                  label: 'Largo',
                  active: _phase == PomodoroPhase.longBreak,
                  color: const Color(0xFF2980B9),
                  onTap: () => _setPhase(PomodoroPhase.longBreak),
                ),
              ],
            ),

            const Spacer(),

            // Círculo de progreso + tiempo
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 240, height: 240,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: _phaseColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(_phaseColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_timeLabel,
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary)),
                Text(_phaseLabel,
                    style: GDTypography.bodyMedium
                        .copyWith(color: c.textSecondary)),
              ]),
            ]),

            const Gap(GDSpacing.xl),

            // Pomodoros completados
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < _completedPomodoros % 4
                      ? Icons.circle
                      : Icons.circle_outlined,
                  color: _phaseColor,
                  size: 14,
                ),
              )),
            ),
            const Gap(GDSpacing.xs),
            Text('$_completedPomodoros pomodoro${_completedPomodoros != 1 ? "s" : ""} completado${_completedPomodoros != 1 ? "s" : ""}',
                style: GDTypography.bodySmall
                    .copyWith(color: c.textTertiary)),

            const Spacer(),

            // Controles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 32,
                  color: c.textSecondary,
                ),
                const Gap(GDSpacing.xl),
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: _phaseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _phaseColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const Gap(GDSpacing.xl),
                IconButton(
                  onPressed: _onPhaseComplete,
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 32,
                  color: c.textSecondary,
                ),
              ],
            ),

            const Gap(GDSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _PhaseChip(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: GDSpacing.md, vertical: GDSpacing.xs),
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.08),
          borderRadius: GDRadius.fullAll,
        ),
        child: Text(label,
            style: GDTypography.labelMedium.copyWith(
                color: active ? Colors.white : color)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BREATHING SCREEN — Luma anima el ritmo respiratorio
// ─────────────────────────────────────────────────────────────────────────────
enum BreathingMode { breathing478, box }

class _BreathingScreen extends StatefulWidget {
  final LumaData lumaData;
  final BreathingMode mode;

  const _BreathingScreen({
    required this.lumaData,
    this.mode = BreathingMode.breathing478,
  });

  @override
  State<_BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<_BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late Animation<double> _scaleAnim;

  int _currentStep = 0;  // 0=inhala 1=retén 2=exhala 3=retén(box)
  int _secondsLeft = 0;
  bool _isRunning = false;
  Timer? _timer;
  int _cycles = 0;

  // Duraciones por modo
  List<int> get _durations => widget.mode == BreathingMode.breathing478
      ? [4, 7, 8]     // 4-7-8
      : [4, 4, 4, 4]; // box

  List<String> get _stepLabels => widget.mode == BreathingMode.breathing478
      ? ['Inhala', 'Retén', 'Exhala']
      : ['Inhala', 'Retén', 'Exhala', 'Retén'];

  String get _title => widget.mode == BreathingMode.breathing478
      ? 'Respiración 4-7-8'
      : 'Respiración cuadrada';

  @override
  void initState() {
    super.initState();
    _secondsLeft = _durations[0];

    _breathCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: _durations[0]),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _currentStep = 0;
      _secondsLeft = _durations[0];
      _cycles = 0;
    });
    _breathCtrl.duration = Duration(seconds: _durations[0]);
    _breathCtrl.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _nextStep();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _nextStep() {
    final next = (_currentStep + 1) % _durations.length;
    if (next == 0) setState(() => _cycles++);

    final dur = _durations[next];
    _breathCtrl.duration = Duration(seconds: dur);

    // Inhala → expand, exhala/retén → contracta o pausa
    if (next == 0) {
      _breathCtrl.forward(from: 0);
    } else if (_stepLabels[next] == 'Exhala') {
      _breathCtrl.reverse();
    }
    // En retén no animamos (se queda donde está)

    setState(() {
      _currentStep = next;
      _secondsLeft = dur;
    });
  }

  void _stop() {
    _timer?.cancel();
    _breathCtrl.stop();
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathCtrl.dispose();
    super.dispose();
  }

  Color get _stepColor {
    final label = _stepLabels[_currentStep];
    if (label == 'Inhala') return const Color(0xFF3498DB);
    if (label == 'Exhala') return const Color(0xFF27AE60);
    return const Color(0xFF9B59B6);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gd;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title, style: GDTypography.headlineMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(GDSpacing.lg),
        child: Column(children: [
          const Spacer(),

          // Círculo animado con Luma adentro
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (_, __) {
              final scale = _isRunning ? _scaleAnim.value : 0.85;
              return Stack(alignment: Alignment.center, children: [
                // Círculo exterior pulsante
                Container(
                  width: 220 * scale, height: 220 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _stepColor.withValues(alpha: 0.08),
                    border: Border.all(
                        color: _stepColor.withValues(alpha: 0.3),
                        width: 2),
                  ),
                ),
                // Luma en el centro
                LumaAvatar(lumaData: widget.lumaData, size: 80),
              ]);
            },
          ),

          const Gap(GDSpacing.xl),

          // Instrucción actual
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Column(
              key: ValueKey(_currentStep),
              children: [
                Text(
                  _isRunning ? _stepLabels[_currentStep] : 'Listo para empezar',
                  style: GDTypography.headlineLarge
                      .copyWith(color: _isRunning ? _stepColor : c.textPrimary),
                ),
                const Gap(GDSpacing.xs),
                Text(
                  _isRunning ? '$_secondsLeft segundos' : _title,
                  style: GDTypography.bodyLarge
                      .copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),

          const Gap(GDSpacing.md),

          // Indicadores de paso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_durations.length, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: i == _currentStep && _isRunning ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentStep && _isRunning
                      ? _stepColor
                      : _stepColor.withValues(alpha: 0.25),
                  borderRadius: GDRadius.fullAll,
                ),
              ),
            )),
          ),

          if (_cycles > 0) ...[
            const Gap(GDSpacing.sm),
            Text('$_cycles ciclo${_cycles != 1 ? "s" : ""} completado${_cycles != 1 ? "s" : ""}',
                style: GDTypography.bodySmall
                    .copyWith(color: c.textTertiary)),
          ],

          const Spacer(),

          // Botón principal
          GestureDetector(
            onTap: _isRunning ? _stop : _start,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _isRunning ? c.error : const Color(0xFF3498DB),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRunning ? c.error : const Color(0xFF3498DB))
                        .withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),

          const Gap(GDSpacing.xxl),
        ]),
      ),
    );
  }
}