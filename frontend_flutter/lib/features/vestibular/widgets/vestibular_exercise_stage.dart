import 'dart:math' as math;

import 'package:flutter/material.dart';

enum VestibularVisualMode {
  stationaryDot,
  stationaryLetter,
  horizontalMovingDot,
  verticalMovingDot,
  diagonalMovingDot,
  zigZagDot,
  figureEightDot,
  twoTargetSaccade,
  optokineticStripes,
  blankBalanceMode,
  headTurnCue,
  headNodCue,
  shoulderShrugCue,
  trunkRotationCue,
  sitToStandCue,
  marchingCue,
  walkingCue,
  bendingCue,
  rollingCue,
}

enum VestibularStageBackground {
  plain,
  grid,
  stripes,
}

class VestibularExerciseStage extends StatefulWidget {
  const VestibularExerciseStage({
    super.key,
    required this.visualMode,
    required this.isActive,
    required this.isStopped,
    this.targetText = 'X',
    this.targetSpeed = 1,
    this.targetSize = 1,
    this.background = VestibularStageBackground.plain,
    this.backgroundMotionEnabled = false,
    this.audioCueEnabled = false,
  });

  final VestibularVisualMode visualMode;
  final bool isActive;
  final bool isStopped;
  final String targetText;
  final double targetSpeed;
  final double targetSize;
  final VestibularStageBackground background;
  final bool backgroundMotionEnabled;
  final bool audioCueEnabled;

  @override
  State<VestibularExerciseStage> createState() =>
      _VestibularExerciseStageState();
}

class _VestibularExerciseStageState extends State<VestibularExerciseStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForSpeed(widget.targetSpeed),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant VestibularExerciseStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetSpeed != widget.targetSpeed) {
      _controller.duration = _durationForSpeed(widget.targetSpeed);
      if (_controller.isAnimating) {
        _controller.repeat();
      }
    }
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.isStopped != widget.isStopped ||
        oldWidget.visualMode != widget.visualMode) {
      _syncAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _durationForSpeed(double speed) {
    final safeSpeed = speed.clamp(0.6, 2.2);
    final milliseconds = (2600 / safeSpeed).round();
    return Duration(milliseconds: milliseconds);
  }

  void _syncAnimation() {
    final shouldAnimate = widget.isActive && !_isStaticMode(widget.visualMode);
    if (widget.isStopped) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (shouldAnimate) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  bool _isStaticMode(VestibularVisualMode mode) {
    return mode == VestibularVisualMode.stationaryDot ||
        mode == VestibularVisualMode.stationaryLetter ||
        mode == VestibularVisualMode.blankBalanceMode;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            try {
              return CustomPaint(
                painter: _VestibularStagePainter(
                  progress: _controller.value,
                  visualMode: widget.visualMode,
                  targetText: widget.targetText.trim().isEmpty
                      ? 'X'
                      : widget.targetText,
                  targetSize: widget.targetSize,
                  background: widget.background,
                  backgroundMotionEnabled: widget.backgroundMotionEnabled,
                  colorScheme: colorScheme,
                ),
                child: Semantics(
                  label: 'Vestibular exercise visual target',
                  child: const SizedBox.expand(),
                ),
              );
            } catch (_) {
              return Center(
                child: Text(
                  'Focus gently ahead',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _VestibularStagePainter extends CustomPainter {
  _VestibularStagePainter({
    required this.progress,
    required this.visualMode,
    required this.targetText,
    required this.targetSize,
    required this.background,
    required this.backgroundMotionEnabled,
    required this.colorScheme,
  });

  final double progress;
  final VestibularVisualMode visualMode;
  final String targetText;
  final double targetSize;
  final VestibularStageBackground background;
  final bool backgroundMotionEnabled;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    switch (visualMode) {
      case VestibularVisualMode.stationaryDot:
        _paintDot(canvas, size.center(Offset.zero));
      case VestibularVisualMode.stationaryLetter:
        _paintLetter(canvas, size.center(Offset.zero), targetText);
        _paintFixedTargetCaption(canvas, size);
      case VestibularVisualMode.horizontalMovingDot:
        _paintMovingTarget(canvas, _horizontalPoint(size));
      case VestibularVisualMode.verticalMovingDot:
        _paintMovingTarget(canvas, _verticalPoint(size));
      case VestibularVisualMode.diagonalMovingDot:
        _paintDot(canvas, _diagonalPoint(size));
      case VestibularVisualMode.zigZagDot:
        _paintDot(canvas, _zigZagPoint(size));
      case VestibularVisualMode.figureEightDot:
        _paintDot(canvas, _figureEightPoint(size));
      case VestibularVisualMode.twoTargetSaccade:
        _paintTwoTargetSaccade(canvas, size);
      case VestibularVisualMode.optokineticStripes:
        _paintOptokineticStripes(canvas, size);
        _paintOptokineticWarning(canvas, size);
      case VestibularVisualMode.blankBalanceMode:
        _paintBalanceInstruction(canvas, size);
      case VestibularVisualMode.headTurnCue:
        _paintHeadCue(canvas, size, horizontal: true);
      case VestibularVisualMode.headNodCue:
        _paintHeadCue(canvas, size, horizontal: false);
      case VestibularVisualMode.shoulderShrugCue:
        _paintShoulderShrugCue(canvas, size);
      case VestibularVisualMode.trunkRotationCue:
        _paintTrunkRotationCue(canvas, size);
      case VestibularVisualMode.sitToStandCue:
        _paintSitToStandCue(canvas, size);
      case VestibularVisualMode.marchingCue:
        _paintMarchingCue(canvas, size);
      case VestibularVisualMode.walkingCue:
        _paintWalkingCue(canvas, size);
      case VestibularVisualMode.bendingCue:
        _paintBendingCue(canvas, size);
      case VestibularVisualMode.rollingCue:
        _paintRollingCue(canvas, size);
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = colorScheme.surface;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    if (background == VestibularStageBackground.grid) {
      final paint = Paint()
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.55)
        ..strokeWidth = 1;
      const spacing = 36.0;
      for (double x = 0; x <= size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (background == VestibularStageBackground.stripes) {
      final paint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.08);
      const stripeWidth = 28.0;
      final offset = backgroundMotionEnabled ? progress * stripeWidth * 2 : 0;
      for (double x = -stripeWidth * 2 + offset;
          x < size.width + stripeWidth;
          x += stripeWidth * 2) {
        canvas.drawRect(Rect.fromLTWH(x, 0, stripeWidth, size.height), paint);
      }
    }
  }

  Offset _horizontalPoint(Size size) {
    final t = _pingPong(progress);
    return Offset(
        _lerp(size.width * 0.18, size.width * 0.82, t), size.height / 2);
  }

  Offset _verticalPoint(Size size) {
    final t = _pingPong(progress);
    return Offset(
        size.width / 2, _lerp(size.height * 0.18, size.height * 0.82, t));
  }

  Offset _diagonalPoint(Size size) {
    final t = _pingPong(progress);
    return Offset(
      _lerp(size.width * 0.18, size.width * 0.82, t),
      _lerp(size.height * 0.22, size.height * 0.78, t),
    );
  }

  Offset _zigZagPoint(Size size) {
    final segment = (progress * 4).floor().clamp(0, 3);
    final local = (progress * 4) - segment;
    final points = <Offset>[
      Offset(size.width * 0.16, size.height * 0.28),
      Offset(size.width * 0.38, size.height * 0.72),
      Offset(size.width * 0.60, size.height * 0.28),
      Offset(size.width * 0.82, size.height * 0.72),
      Offset(size.width * 0.16, size.height * 0.28),
    ];
    return Offset.lerp(points[segment], points[segment + 1], local)!;
  }

  Offset _figureEightPoint(Size size) {
    final angle = progress * math.pi * 2;
    return Offset(
      size.width / 2 + math.sin(angle) * size.width * 0.28,
      size.height / 2 + math.sin(angle * 2) * size.height * 0.18,
    );
  }

  void _paintTwoTargetSaccade(Canvas canvas, Size size) {
    final left = Offset(size.width * 0.25, size.height / 2);
    final right = Offset(size.width * 0.75, size.height / 2);
    final highlightLeft = progress < 0.5;
    _paintSaccadeTarget(canvas, left, 'LEFT', active: highlightLeft);
    _paintSaccadeTarget(canvas, right, 'RIGHT', active: !highlightLeft);
    _paintText(
      canvas,
      'Look at the bright target',
      Offset(size.width / 2, size.height * 0.82),
      size.width * 0.82,
      colorScheme.onSurface,
      20,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintOptokineticStripes(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.26);
    final altPaint = Paint()
      ..color = colorScheme.tertiary.withValues(alpha: 0.16);
    const stripeWidth = 34.0;
    final offset = progress * stripeWidth * 2;
    for (double x = -stripeWidth * 2 + offset;
        x < size.width + stripeWidth;
        x += stripeWidth * 2) {
      canvas.drawRect(
          Rect.fromLTWH(x, 0, stripeWidth, size.height), stripePaint);
      canvas.drawRect(
        Rect.fromLTWH(x + stripeWidth, 0, stripeWidth, size.height),
        altPaint,
      );
    }
  }

  void _paintOptokineticWarning(Canvas canvas, Size size) {
    _paintText(
      canvas,
      'May increase dizziness. Stop if symptoms are severe.',
      Offset(size.width / 2, size.height - 34),
      size.width * 0.86,
      colorScheme.onSurface,
      15,
      FontWeight.w700,
      TextAlign.center,
    );
  }

  void _paintBalanceInstruction(Canvas canvas, Size size) {
    _paintText(
      canvas,
      'Stand near support.\nKeep posture tall.\nStop if unsafe.',
      size.center(Offset.zero),
      size.width * 0.82,
      colorScheme.onSurface,
      24,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintFixedTargetCaption(Canvas canvas, Size size) {
    _paintText(
      canvas,
      'Fixed target: keep looking at this while moving your head.',
      Offset(size.width / 2, size.height * 0.78),
      size.width * 0.84,
      colorScheme.onSurfaceVariant,
      17,
      FontWeight.w700,
      TextAlign.center,
    );
  }

  void _paintSaccadeTarget(
    Canvas canvas,
    Offset center,
    String label, {
    required bool active,
  }) {
    final pulse =
        active ? 1 + math.sin(progress * math.pi * 8).abs() * 0.18 : 1.0;
    final radius = 30.0 * targetSize.clamp(0.75, 1.45) * pulse;
    final halo = Paint()
      ..color = active
          ? colorScheme.tertiary.withValues(alpha: 0.34)
          : colorScheme.outlineVariant.withValues(alpha: 0.18);
    final fill = Paint()
      ..color =
          active ? colorScheme.tertiary : colorScheme.surfaceContainerHighest;
    final stroke = Paint()
      ..color = active ? colorScheme.tertiary : colorScheme.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 5 : 2;
    canvas.drawCircle(center, radius * 1.65, halo);
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, stroke);
    _paintText(
      canvas,
      label,
      center,
      150,
      active ? colorScheme.onTertiary : colorScheme.onSurfaceVariant,
      18 * targetSize.clamp(0.75, 1.45),
      FontWeight.w900,
      TextAlign.center,
    );
  }

  void _paintHeadCue(
    Canvas canvas,
    Size size, {
    required bool horizontal,
  }) {
    final center = size.center(Offset.zero);
    final swing = math.sin(progress * math.pi * 2) * 0.32;
    final headOffset = horizontal
        ? Offset(math.sin(progress * math.pi * 2) * size.width * 0.09, 0)
        : Offset(0, math.sin(progress * math.pi * 2) * size.height * 0.06);
    _paintPersonBase(canvas, size,
        headOffset: headOffset, shoulderTilt: swing * 0.4);
    _paintText(
      canvas,
      horizontal ? 'Turn head left and right' : 'Nod head up and down',
      Offset(center.dx, size.height * 0.82),
      size.width * 0.86,
      colorScheme.onSurface,
      22,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintShoulderShrugCue(Canvas canvas, Size size) {
    final lift = math.sin(progress * math.pi * 2).abs() * size.height * 0.10;
    _paintPersonBase(canvas, size, shoulderLift: lift);
    _paintArrow(
      canvas,
      Offset(size.width * 0.36, size.height * 0.58),
      Offset(size.width * 0.36, size.height * 0.40 - lift),
    );
    _paintArrow(
      canvas,
      Offset(size.width * 0.64, size.height * 0.58),
      Offset(size.width * 0.64, size.height * 0.40 - lift),
    );
    _paintText(
      canvas,
      'Lift shoulders, hold briefly, relax down',
      Offset(size.width / 2, size.height * 0.84),
      size.width * 0.86,
      colorScheme.onSurface,
      22,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintTrunkRotationCue(Canvas canvas, Size size) {
    final angle = math.sin(progress * math.pi * 2) * 0.38;
    _paintPersonBase(canvas, size, torsoRotation: angle);
    _paintCurvedArrow(canvas, size.center(Offset(0, size.height * 0.06)));
    _paintText(
      canvas,
      'Rotate trunk gently side to side',
      Offset(size.width / 2, size.height * 0.84),
      size.width * 0.86,
      colorScheme.onSurface,
      22,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintSitToStandCue(Canvas canvas, Size size) {
    final rise = _pingPong(progress) * size.height * 0.16;
    _paintChair(canvas, Offset(size.width * 0.38, size.height * 0.67));
    _paintPersonBase(canvas, size,
        verticalShift: -rise, compactLegs: rise < size.height * 0.08);
    _paintArrow(
      canvas,
      Offset(size.width * 0.70, size.height * 0.70),
      Offset(size.width * 0.70, size.height * 0.42),
    );
    _paintText(
      canvas,
      'Stand up slowly, then sit down safely',
      Offset(size.width / 2, size.height * 0.86),
      size.width * 0.86,
      colorScheme.onSurface,
      21,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintMarchingCue(Canvas canvas, Size size) {
    final step = math.sin(progress * math.pi * 2);
    _paintPersonBase(canvas, size, marchingStep: step);
    _paintText(
      canvas,
      'March in place near support',
      Offset(size.width / 2, size.height * 0.84),
      size.width * 0.86,
      colorScheme.onSurface,
      22,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintWalkingCue(Canvas canvas, Size size) {
    final offset = math.sin(progress * math.pi * 2) * size.width * 0.08;
    _paintPersonBase(canvas, size,
        horizontalShift: offset,
        marchingStep: math.sin(progress * math.pi * 4));
    _paintArrow(
      canvas,
      Offset(size.width * 0.30, size.height * 0.70),
      Offset(size.width * 0.70, size.height * 0.70),
    );
    _paintText(
      canvas,
      'Walk slowly near support',
      Offset(size.width / 2, size.height * 0.86),
      size.width * 0.86,
      colorScheme.onSurface,
      22,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintBendingCue(Canvas canvas, Size size) {
    final bend = _pingPong(progress) * 0.48;
    _paintPersonBase(canvas, size,
        torsoRotation: bend, verticalShift: size.height * 0.04 * bend);
    _paintArrow(
      canvas,
      Offset(size.width * 0.68, size.height * 0.43),
      Offset(size.width * 0.62, size.height * 0.58),
    );
    _paintText(
      canvas,
      'Bend forward gently, return upright',
      Offset(size.width / 2, size.height * 0.86),
      size.width * 0.86,
      colorScheme.onSurface,
      22,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintRollingCue(Canvas canvas, Size size) {
    final center = size.center(Offset(0, -size.height * 0.02));
    final angle = progress * math.pi * 2;
    final paint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final pillow = Paint()..color = colorScheme.primary.withValues(alpha: 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + size.height * 0.10),
          width: size.width * 0.48,
          height: size.height * 0.22,
        ),
        const Radius.circular(24),
      ),
      pillow,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.sin(angle) * 0.7);
    canvas.drawCircle(Offset(0, -36), 26, Paint()..color = colorScheme.primary);
    canvas.drawLine(const Offset(0, -8), const Offset(0, 78), paint);
    canvas.drawLine(const Offset(-58, 30), const Offset(58, 30), paint);
    canvas.restore();
    _paintText(
      canvas,
      'Roll gently side to side',
      Offset(size.width / 2, size.height * 0.84),
      size.width * 0.86,
      colorScheme.onSurface,
      22,
      FontWeight.w800,
      TextAlign.center,
    );
  }

  void _paintPersonBase(
    Canvas canvas,
    Size size, {
    Offset headOffset = Offset.zero,
    double shoulderLift = 0,
    double shoulderTilt = 0,
    double torsoRotation = 0,
    double verticalShift = 0,
    double horizontalShift = 0,
    double marchingStep = 0,
    bool compactLegs = false,
  }) {
    final center = size
        .center(Offset(horizontalShift, -size.height * 0.01 + verticalShift));
    final paint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 9 * targetSize.clamp(0.75, 1.35)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = colorScheme.primary.withValues(alpha: 0.18);
    final headCenter =
        Offset(center.dx, center.dy - size.height * 0.20) + headOffset;
    canvas.drawCircle(headCenter, 30 * targetSize.clamp(0.75, 1.35), fill);
    canvas.drawCircle(headCenter, 20 * targetSize.clamp(0.75, 1.35),
        Paint()..color = colorScheme.primary);

    final neck = Offset(center.dx, center.dy - size.height * 0.12);
    final hip = Offset(
      center.dx + math.sin(torsoRotation) * size.width * 0.07,
      center.dy + size.height * 0.14,
    );
    canvas.drawLine(neck, hip, paint);

    final leftShoulder = Offset(center.dx - size.width * 0.09,
        center.dy - size.height * 0.08 - shoulderLift + shoulderTilt * 18);
    final rightShoulder = Offset(center.dx + size.width * 0.09,
        center.dy - size.height * 0.08 - shoulderLift - shoulderTilt * 18);
    canvas.drawLine(leftShoulder, rightShoulder, paint);
    canvas.drawLine(
        leftShoulder,
        Offset(leftShoulder.dx - size.width * 0.08,
            leftShoulder.dy + size.height * 0.10),
        paint);
    canvas.drawLine(
        rightShoulder,
        Offset(rightShoulder.dx + size.width * 0.08,
            rightShoulder.dy + size.height * 0.10),
        paint);

    final kneeLift = compactLegs ? size.height * 0.06 : 0;
    final leftFoot = Offset(
        center.dx - size.width * 0.10,
        center.dy +
            size.height * 0.30 -
            math.max(0, marchingStep) * size.height * 0.08 -
            kneeLift);
    final rightFoot = Offset(
        center.dx + size.width * 0.10,
        center.dy +
            size.height * 0.30 -
            math.max(0, -marchingStep) * size.height * 0.08 -
            kneeLift);
    canvas.drawLine(hip, leftFoot, paint);
    canvas.drawLine(hip, rightFoot, paint);
  }

  void _paintChair(Canvas canvas, Offset base) {
    final paint = Paint()
      ..color = colorScheme.outline
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(base, base + const Offset(80, 0), paint);
    canvas.drawLine(
        base + const Offset(6, 0), base + const Offset(6, -70), paint);
    canvas.drawLine(
        base + const Offset(12, 0), base + const Offset(12, 70), paint);
    canvas.drawLine(
        base + const Offset(72, 0), base + const Offset(72, 70), paint);
  }

  void _paintArrow(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = colorScheme.tertiary
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    final direction = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const headLength = 18.0;
    for (final delta in [math.pi * 0.82, -math.pi * 0.82]) {
      final angle = direction + delta;
      canvas.drawLine(
        end,
        end +
            Offset(math.cos(angle) * headLength, math.sin(angle) * headLength),
        paint,
      );
    }
  }

  void _paintCurvedArrow(Canvas canvas, Offset center) {
    final rect = Rect.fromCenter(center: center, width: 180, height: 110);
    final paint = Paint()
      ..color = colorScheme.tertiary
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi * 0.15, math.pi * 0.75, false, paint);
    canvas.drawArc(rect, math.pi * 1.1, math.pi * 0.75, false, paint);
  }

  void _paintDot(Canvas canvas, Offset center, {bool highlighted = true}) {
    final radius = 20.0 * targetSize.clamp(0.75, 1.45);
    final outer = Paint()
      ..color = highlighted
          ? colorScheme.primary.withValues(alpha: 0.20)
          : colorScheme.outlineVariant.withValues(alpha: 0.18);
    final inner = Paint()
      ..color = highlighted ? colorScheme.primary : colorScheme.outline;
    canvas.drawCircle(center, radius * 1.75, outer);
    canvas.drawCircle(center, radius, inner);
  }

  void _paintMovingTarget(Canvas canvas, Offset center) {
    if (targetText.toUpperCase() == 'CARD') {
      _paintCardTarget(canvas, center);
    } else {
      _paintDot(canvas, center);
    }
  }

  void _paintCardTarget(Canvas canvas, Offset center) {
    final scale = targetSize.clamp(0.75, 1.45);
    final rect = Rect.fromCenter(
      center: center,
      width: 96 * scale,
      height: 68 * scale,
    );
    final fill = Paint()..color = colorScheme.primary.withValues(alpha: 0.12);
    final border = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(16 * scale)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(16 * scale)),
      border,
    );
    _paintText(
      canvas,
      'X',
      center,
      rect.width,
      colorScheme.primary,
      36 * scale,
      FontWeight.w900,
      TextAlign.center,
    );
  }

  void _paintLetter(
    Canvas canvas,
    Offset center,
    String text, {
    bool small = false,
  }) {
    _paintText(
      canvas,
      String.fromCharCodes(text.runes.take(2)),
      center,
      140,
      colorScheme.primary,
      (small ? 24 : 58) * targetSize.clamp(0.75, 1.45),
      FontWeight.w900,
      TextAlign.center,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double maxWidth,
    Color color,
    double fontSize,
    FontWeight fontWeight,
    TextAlign textAlign,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.25,
        ),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  double _pingPong(double value) => math.sin(value * math.pi);

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  @override
  bool shouldRepaint(covariant _VestibularStagePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.visualMode != visualMode ||
        oldDelegate.targetText != targetText ||
        oldDelegate.targetSize != targetSize ||
        oldDelegate.background != background ||
        oldDelegate.backgroundMotionEnabled != backgroundMotionEnabled ||
        oldDelegate.colorScheme != colorScheme;
  }
}
