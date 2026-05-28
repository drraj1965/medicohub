import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vestibular_exercise.dart';
import 'exercise_session_page.dart';

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({
    super.key,
    required this.exercise,
  });

  final VestibularExercise exercise;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                      exercise.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(exercise.category)),
                        Chip(label: Text(exercise.difficultyLevel)),
                        if (exercise.requiresSupervision)
                          const Chip(
                            avatar: Icon(Icons.supervisor_account_rounded),
                            label: Text('Supervision advised'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      exercise.shortDescription,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            _InfoCard(
              title: 'Instructions',
              icon: Icons.format_list_numbered_rounded,
              text: exercise.fullInstructions,
            ),
            _InfoCard(
              title: 'Precautions',
              icon: Icons.health_and_safety_rounded,
              text: exercise.precautions,
            ),
            _InfoCard(
              title: 'Do not perform if',
              icon: Icons.report_problem_rounded,
              text: exercise.contraindications,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session defaults',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${exercise.recommendedDurationSeconds} seconds • ${exercise.recommendedRepetitions} set(s)/repetition(s)',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: exercise.youtubeUrl.trim().isEmpty
                                ? null
                                : () => _openVideo(context),
                            icon: const Icon(Icons.play_circle_outline),
                            label: Text(
                              exercise.youtubeUrl.trim().isEmpty
                                  ? 'Video not available'
                                  : 'Open video',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _startExercise(context),
              icon: const Icon(Icons.timer_rounded),
              label: const Text('Start Exercise'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: exercise.requiresSupervision
                    ? colorScheme.tertiary
                    : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(exercise.youtubeUrl.trim());
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video link is not available.')),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open video link.')),
      );
    }
  }

  Future<void> _startExercise(BuildContext context) async {
    if (exercise.requiresSupervision) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Supervision advised'),
            content: const Text(
              'This exercise may provoke vertigo or imbalance. Start only if it was prescribed or reviewed by a clinician, and keep safe support nearby.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
      if (proceed != true || !context.mounted) {
        return;
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExerciseSessionPage(exercise: exercise),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.text,
  });

  final String title;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
