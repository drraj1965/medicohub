import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/vestibular_exercise_library.dart';
import '../models/vestibular_exercise.dart';
import '../services/vestibular_progress_service.dart';

class VestibularProgressPage extends StatefulWidget {
  const VestibularProgressPage({super.key});

  @override
  State<VestibularProgressPage> createState() => _VestibularProgressPageState();
}

class _VestibularProgressPageState extends State<VestibularProgressPage> {
  final VestibularProgressService _progressService =
      VestibularProgressService();
  late Future<List<VestibularSessionResult>> _future;

  @override
  void initState() {
    super.initState();
    _future = _progressService.getAllSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vestibular Progress'),
        actions: [
          IconButton(
            tooltip: 'Export progress',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _exportProgress,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<VestibularSessionResult>>(
          future: _future,
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? <VestibularSessionResult>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (sessions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No vestibular sessions saved yet. Complete an exercise to start your local progress history.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final grouped = <String, List<VestibularSessionResult>>{};
            for (final session in sessions) {
              grouped.putIfAbsent(session.exerciseId, () => []).add(session);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Progress is stored locally on this device. Firebase sync can be added later.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final entry in grouped.entries)
                  _ProgressGroupCard(
                    exerciseId: entry.key,
                    sessions: entry.value,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportProgress() async {
    try {
      final sessions = await _progressService.getAllSessions();
      if (!mounted) {
        return;
      }
      if (sessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No progress to export yet.')),
        );
        return;
      }
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/vestibular_progress.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(
          sessions.map((item) => item.toJson()).toList(growable: false),
        ),
      );
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Vestibular exercise progress',
          files: [XFile(file.path)],
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export progress.')),
      );
    }
  }
}

class _ProgressGroupCard extends StatelessWidget {
  const _ProgressGroupCard({
    required this.exerciseId,
    required this.sessions,
  });

  final String exerciseId;
  final List<VestibularSessionResult> sessions;

  @override
  Widget build(BuildContext context) {
    VestibularExercise? exercise;
    for (final item in vestibularExerciseLibrary) {
      if (item.id == exerciseId) {
        exercise = item;
        break;
      }
    }
    final sorted = [...sessions]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final latest = sorted.first;
    final completedCount = sessions.where((item) => item.completed).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(exercise?.title ?? exerciseId),
        subtitle: Text(
          '$completedCount completed session(s) • latest dizziness ${latest.dizzinessBefore} -> ${latest.dizzinessAfter}',
        ),
        children: [
          for (final session in sorted.take(10))
            ListTile(
              title: Text(_formatDate(session.dateTime)),
              subtitle: Text(
                'Duration ${session.durationCompleted}s • nausea ${session.nauseaScore}/10 • imbalance ${session.imbalanceScore}/10${session.notes.isEmpty ? '' : '\n${session.notes}'}',
              ),
              trailing: Icon(
                session.completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
