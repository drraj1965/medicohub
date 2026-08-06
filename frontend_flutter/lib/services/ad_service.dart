import 'sponsored_content_service.dart';

class AdPolicyDecision {
  const AdPolicyDecision({
    required this.canShow,
    required this.reason,
  });

  final bool canShow;
  final String reason;
}

class AdService {
  const AdService({
    this.sponsoredContentService = const SponsoredContentService(),
  });

  final SponsoredContentService sponsoredContentService;

  AdPolicyDecision canShowAd({
    required bool globalAdsEnabled,
    required bool userAllowsSuggestions,
    required bool isSensitiveArea,
    required String placement,
  }) {
    if (!globalAdsEnabled) {
      return const AdPolicyDecision(
        canShow: false,
        reason: 'Ads are globally disabled by admin settings.',
      );
    }
    if (!userAllowsSuggestions) {
      return const AdPolicyDecision(
        canShow: false,
        reason: 'User has not enabled personalized content suggestions or ads.',
      );
    }
    if (isSensitiveArea) {
      return const AdPolicyDecision(
        canShow: false,
        reason:
            'Ads are blocked in sensitive clinical or private communication areas.',
      );
    }
    if (placement.trim().isEmpty) {
      return const AdPolicyDecision(
        canShow: false,
        reason: 'Ad placement was not specified.',
      );
    }
    return const AdPolicyDecision(
      canShow: true,
      reason: 'Broad-context sponsored content may be shown.',
    );
  }

  Future<List<SponsoredContentItem>> loadSponsoredContent({
    required String context,
  }) {
    return sponsoredContentService.loadSafePlaceholders(context: context);
  }
}
