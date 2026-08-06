import 'package:flutter/material.dart';

import '../../services/ad_service.dart';
import '../../services/sponsored_content_service.dart';
import 'sponsored_card.dart';

class AdSlot extends StatelessWidget {
  const AdSlot({
    super.key,
    required this.placement,
    required this.contextLabel,
    this.globalAdsEnabled = false,
    this.userAllowsSuggestions = false,
    this.isSensitiveArea = false,
    this.adService = const AdService(),
  });

  final String placement;
  final String contextLabel;
  final bool globalAdsEnabled;
  final bool userAllowsSuggestions;
  final bool isSensitiveArea;
  final AdService adService;

  @override
  Widget build(BuildContext context) {
    final decision = adService.canShowAd(
      globalAdsEnabled: globalAdsEnabled,
      userAllowsSuggestions: userAllowsSuggestions,
      isSensitiveArea: isSensitiveArea,
      placement: placement,
    );
    if (!decision.canShow) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<SponsoredContentItem>>(
      future: adService.loadSponsoredContent(context: contextLabel),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <SponsoredContentItem>[];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return SponsoredCard(item: items.first);
      },
    );
  }
}
