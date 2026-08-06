class SponsoredContentItem {
  const SponsoredContentItem({
    required this.id,
    required this.title,
    required this.body,
    required this.context,
    this.callToActionLabel = 'Learn more',
    this.url,
  });

  final String id;
  final String title;
  final String body;
  final String context;
  final String callToActionLabel;
  final String? url;
}

class SponsoredContentService {
  const SponsoredContentService();

  Future<List<SponsoredContentItem>> loadSafePlaceholders({
    required String context,
  }) async {
    return [
      SponsoredContentItem(
        id: 'placeholder-$context',
        title: 'Sponsored educational resource',
        body:
            'A future reviewed sponsor can appear here. No private medical details are used for targeting.',
        context: context,
      ),
    ];
  }
}
