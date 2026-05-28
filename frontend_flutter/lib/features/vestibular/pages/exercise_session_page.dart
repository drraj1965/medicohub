import 'dart:async';

import 'package:flutter/material.dart';

import '../models/vestibular_exercise.dart';
import '../services/vestibular_progress_service.dart';
import '../widgets/vestibular_exercise_stage.dart';

class ExerciseSessionPage extends StatefulWidget {
  const ExerciseSessionPage({
    super.key,
    required this.exercise,
  });

  final VestibularExercise exercise;

  @override
  State<ExerciseSessionPage> createState() => _ExerciseSessionPageState();
}

class _ExerciseSessionPageState extends State<ExerciseSessionPage> {
  final VestibularProgressService _progressService =
      VestibularProgressService();
  final TextEditingController _notesController = TextEditingController();
  Timer? _timer;
  late int _secondsRemaining;
  bool _running = false;
  bool _saved = false;
  int _dizzinessBefore = 0;
  int _dizzinessAfter = 0;
  int _nauseaScore = 0;
  int _imbalanceScore = 0;
  bool _completed = true;
  String _targetSpeedSetting = 'medium';
  String _targetSizeSetting = 'medium';
  VestibularStageBackground _background = VestibularStageBackground.plain;

  int get _durationCompleted =>
      widget.exercise.recommendedDurationSeconds - _secondsRemaining;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.exercise.recommendedDurationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _start() {
    if (_secondsRemaining <= 0) {
      setState(() {
        _secondsRemaining = widget.exercise.recommendedDurationSeconds;
      });
    }
    _timer?.cancel();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _running = false;
        });
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _secondsRemaining = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final stageHeight = (MediaQuery.sizeOf(context).height * 0.38).clamp(
      260.0,
      420.0,
    );
    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guided session',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      exercise.fullInstructions,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: stageHeight,
                      child: VestibularExerciseStage(
                        visualMode: exercise.visualMode,
                        isActive: _running,
                        isStopped: _secondsRemaining == 0,
                        targetText: exercise.targetText,
                        targetSpeed:
                            exercise.targetSpeed * _targetSpeedMultiplier,
                        targetSize: exercise.targetSize * _targetSizeMultiplier,
                        background: _effectiveBackground,
                        backgroundMotionEnabled:
                            exercise.backgroundMotionEnabled ||
                                _effectiveBackground ==
                                    VestibularStageBackground.stripes,
                        audioCueEnabled: exercise.audioCueEnabled,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keep symptoms mild to moderate. Stop if severe dizziness, headache, weakness, double vision, chest pain, fainting, or inability to walk occurs.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (_showVisualSettings) ...[
                      const SizedBox(height: 14),
                      _StageSettings(
                        speed: _targetSpeedSetting,
                        size: _targetSizeSetting,
                        background: _background,
                        onSpeedChanged: (value) =>
                            setState(() => _targetSpeedSetting = value),
                        onSizeChanged: (value) =>
                            setState(() => _targetSizeSetting = value),
                        onBackgroundChanged: (value) =>
                            setState(() => _background = value),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '$minutes:$seconds',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: _running ? null : _start,
                          icon: Icon(
                            _secondsRemaining ==
                                    exercise.recommendedDurationSeconds
                                ? Icons.play_arrow_rounded
                                : Icons.replay_rounded,
                          ),
                          label: Text(
                            _secondsRemaining ==
                                    exercise.recommendedDurationSeconds
                                ? 'Start'
                                : 'Resume',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _running ? _pause : null,
                          icon: const Icon(Icons.pause_rounded),
                          label: const Text('Pause'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _secondsRemaining ==
                                  exercise.recommendedDurationSeconds
                              ? null
                              : _stop,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Stop'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record symptoms',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _ScoreSlider(
                      label: 'Dizziness before',
                      value: _dizzinessBefore,
                      onChanged: (value) =>
                          setState(() => _dizzinessBefore = value),
                    ),
                    _ScoreSlider(
                      label: 'Dizziness after',
                      value: _dizzinessAfter,
                      onChanged: (value) =>
                          setState(() => _dizzinessAfter = value),
                    ),
                    _ScoreSlider(
                      label: 'Nausea',
                      value: _nauseaScore,
                      onChanged: (value) =>
                          setState(() => _nauseaScore = value),
                    ),
                    _ScoreSlider(
                      label: 'Imbalance',
                      value: _imbalanceScore,
                      onChanged: (value) =>
                          setState(() => _imbalanceScore = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Completed exercise'),
                      value: _completed,
                      onChanged: (value) => setState(() => _completed = value),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saved ? null : _saveSession,
                      icon: Icon(
                        _saved ? Icons.check_rounded : Icons.save_rounded,
                      ),
                      label: Text(_saved ? 'Saved' : 'Save session'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSession() async {
    final session = VestibularSessionResult(
      exerciseId: widget.exercise.id,
      dateTime: DateTime.now(),
      durationCompleted: _durationCompleted.clamp(
        0,
        widget.exercise.recommendedDurationSeconds,
      ),
      repetitionsCompleted: widget.exercise.recommendedRepetitions,
      dizzinessBefore: _dizzinessBefore,
      dizzinessAfter: _dizzinessAfter,
      nauseaScore: _nauseaScore,
      imbalanceScore: _imbalanceScore,
      completed: _completed,
      notes: _notesController.text.trim(),
    );
    await _progressService.saveSession(session);
    if (!mounted) {
      return;
    }
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vestibular session saved locally.')),
    );
  }

  double get _targetSpeedMultiplier {
    switch (_targetSpeedSetting) {
      case 'slow':
        return 0.65;
      case 'fast':
        return 1.55;
      case 'medium':
      default:
        return 1;
    }
  }

  double get _targetSizeMultiplier {
    switch (_targetSizeSetting) {
      case 'small':
        return 0.78;
      case 'large':
        return 1.32;
      case 'medium':
      default:
        return 1;
    }
  }

  VestibularStageBackground get _effectiveBackground {
    if (widget.exercise.visualMode == VestibularVisualMode.optokineticStripes) {
      return VestibularStageBackground.stripes;
    }
    return _background;
  }

  bool get _showVisualSettings {
    switch (widget.exercise.visualMode) {
      case VestibularVisualMode.stationaryDot:
      case VestibularVisualMode.stationaryLetter:
      case VestibularVisualMode.horizontalMovingDot:
      case VestibularVisualMode.verticalMovingDot:
      case VestibularVisualMode.diagonalMovingDot:
      case VestibularVisualMode.zigZagDot:
      case VestibularVisualMode.figureEightDot:
      case VestibularVisualMode.twoTargetSaccade:
      case VestibularVisualMode.optokineticStripes:
        return true;
      case VestibularVisualMode.blankBalanceMode:
      case VestibularVisualMode.headTurnCue:
      case VestibularVisualMode.headNodCue:
      case VestibularVisualMode.shoulderShrugCue:
      case VestibularVisualMode.trunkRotationCue:
      case VestibularVisualMode.sitToStandCue:
      case VestibularVisualMode.marchingCue:
      case VestibularVisualMode.walkingCue:
      case VestibularVisualMode.bendingCue:
      case VestibularVisualMode.rollingCue:
        return false;
    }
  }
}

class _StageSettings extends StatelessWidget {
  const _StageSettings({
    required this.speed,
    required this.size,
    required this.background,
    required this.onSpeedChanged,
    required this.onSizeChanged,
    required this.onBackgroundChanged,
  });

  final String speed;
  final String size;
  final VestibularStageBackground background;
  final ValueChanged<String> onSpeedChanged;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<VestibularStageBackground> onBackgroundChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual target settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DropdownShell(
              label: 'Target speed',
              child: DropdownButton<String>(
                value: speed,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'slow', child: Text('Slow')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'fast', child: Text('Fast')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onSpeedChanged(value);
                  }
                },
              ),
            ),
            _DropdownShell(
              label: 'Target size',
              child: DropdownButton<String>(
                value: size,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Small')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'large', child: Text('Large')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onSizeChanged(value);
                  }
                },
              ),
            ),
            _DropdownShell(
              label: 'Background',
              child: DropdownButton<VestibularStageBackground>(
                value: background,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: VestibularStageBackground.plain,
                    child: Text('Plain'),
                  ),
                  DropdownMenuItem(
                    value: VestibularStageBackground.grid,
                    child: Text('Grid'),
                  ),
                  DropdownMenuItem(
                    value: VestibularStageBackground.stripes,
                    child: Text('Stripes'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onBackgroundChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DropdownShell extends StatelessWidget {
  const _DropdownShell({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 240),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: child,
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '$value/10',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$value',
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}
