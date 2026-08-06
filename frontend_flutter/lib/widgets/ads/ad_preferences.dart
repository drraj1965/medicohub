import 'package:flutter/material.dart';

class AdPreferences extends StatelessWidget {
  const AdPreferences({
    super.key,
    required this.personalizedSuggestionsEnabled,
    required this.onChanged,
  });

  final bool personalizedSuggestionsEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: personalizedSuggestionsEnabled,
        onChanged: onChanged,
        title: const Text('Personalized content suggestions / ads'),
        subtitle: const Text(
          'Default is off. If enabled later, MedicoHub will use only broad page context, not private medical details.',
        ),
      ),
    );
  }
}
