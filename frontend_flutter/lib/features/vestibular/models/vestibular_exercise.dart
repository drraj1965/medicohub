import '../widgets/vestibular_exercise_stage.dart';

class VestibularExercise {
  const VestibularExercise({
    required this.id,
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.fullInstructions,
    required this.precautions,
    required this.difficultyLevel,
    required this.recommendedDurationSeconds,
    required this.recommendedRepetitions,
    required this.youtubeUrl,
    required this.contraindications,
    required this.requiresSupervision,
    this.visualMode = VestibularVisualMode.stationaryDot,
    this.targetText = 'X',
    this.targetSpeed = 1,
    this.targetSize = 1,
    this.backgroundMotionEnabled = false,
    this.audioCueEnabled = false,
  });

  final String id;
  final String title;
  final String category;
  final String shortDescription;
  final String fullInstructions;
  final String precautions;
  final String difficultyLevel;
  final int recommendedDurationSeconds;
  final int recommendedRepetitions;
  final String youtubeUrl;
  final String contraindications;
  final bool requiresSupervision;
  final VestibularVisualMode visualMode;
  final String targetText;
  final double targetSpeed;
  final double targetSize;
  final bool backgroundMotionEnabled;
  final bool audioCueEnabled;
}

class VestibularSessionResult {
  const VestibularSessionResult({
    required this.exerciseId,
    required this.dateTime,
    required this.durationCompleted,
    required this.repetitionsCompleted,
    required this.dizzinessBefore,
    required this.dizzinessAfter,
    required this.nauseaScore,
    required this.imbalanceScore,
    required this.completed,
    required this.notes,
  });

  final String exerciseId;
  final DateTime dateTime;
  final int durationCompleted;
  final int repetitionsCompleted;
  final int dizzinessBefore;
  final int dizzinessAfter;
  final int nauseaScore;
  final int imbalanceScore;
  final bool completed;
  final String notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exerciseId': exerciseId,
        'dateTime': dateTime.toIso8601String(),
        'durationCompleted': durationCompleted,
        'repetitionsCompleted': repetitionsCompleted,
        'dizzinessBefore': dizzinessBefore,
        'dizzinessAfter': dizzinessAfter,
        'nauseaScore': nauseaScore,
        'imbalanceScore': imbalanceScore,
        'completed': completed,
        'notes': notes,
      };

  factory VestibularSessionResult.fromJson(Map<String, dynamic> json) {
    return VestibularSessionResult(
      exerciseId: json['exerciseId']?.toString() ?? '',
      dateTime: DateTime.tryParse(json['dateTime']?.toString() ?? '') ??
          DateTime.now(),
      durationCompleted: _intFromJson(json['durationCompleted']),
      repetitionsCompleted: _intFromJson(json['repetitionsCompleted']),
      dizzinessBefore: _intFromJson(json['dizzinessBefore']),
      dizzinessAfter: _intFromJson(json['dizzinessAfter']),
      nauseaScore: _intFromJson(json['nauseaScore']),
      imbalanceScore: _intFromJson(json['imbalanceScore']),
      completed: json['completed'] == true,
      notes: json['notes']?.toString() ?? '',
    );
  }

  static int _intFromJson(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
