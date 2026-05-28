import 'package:flutter/material.dart';

import 'data/vestibular_exercise_library.dart';
import 'pages/exercise_detail_page.dart';
import 'pages/vestibular_progress_page.dart';

class VestibularExerciseHomePage extends StatelessWidget {
  const VestibularExerciseHomePage({super.key});

  static const String safetyWarning =
      'Do not perform these exercises if you have new weakness, slurred speech, double vision, severe headache, inability to walk, fainting, chest pain, or sudden hearing loss. Seek urgent medical care.';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vestibular Exercises'),
        actions: [
          IconButton(
            tooltip: 'Progress history',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VestibularProgressPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        safetyWarning,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Educational module only. Vestibular rehabilitation should ideally be prescribed or reviewed by a clinician, especially if symptoms are new, severe, or worsening.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose a category',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            for (final category in vestibularExerciseCategories)
              _CategoryTile(
                title: category.title,
                description: category.description,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final exercises = exercisesForCategory(title);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text('${exercises.length}'),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(description),
        children: [
          for (final exercise in exercises)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              leading: Icon(
                exercise.requiresSupervision
                    ? Icons.supervisor_account_rounded
                    : Icons.self_improvement_rounded,
              ),
              title: Text(exercise.title),
              subtitle: Text(
                '${exercise.difficultyLevel} • ${exercise.recommendedDurationSeconds}s • ${exercise.recommendedRepetitions} set(s)',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExerciseDetailPage(exercise: exercise),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
