import 'package:flutter/material.dart';

class AdDisclosure extends StatelessWidget {
  const AdDisclosure({
    super.key,
    this.label = 'Sponsored',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label content disclosure',
      child: Chip(
        label: Text(label),
        avatar: const Icon(Icons.info_outline_rounded, size: 18),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
