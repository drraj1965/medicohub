import 'package:flutter/material.dart';

import '../../services/sponsored_content_service.dart';
import 'ad_disclosure.dart';

class SponsoredCard extends StatelessWidget {
  const SponsoredCard({
    super.key,
    required this.item,
    this.onOpen,
  });

  final SponsoredContentItem item;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdDisclosure(),
            const SizedBox(height: 10),
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(item.body),
            if (onOpen != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onOpen,
                child: Text(item.callToActionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
