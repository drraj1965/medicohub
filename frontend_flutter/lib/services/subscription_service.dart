class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.description,
    this.isEnabled = false,
  });

  final String id;
  final String title;
  final String description;
  final bool isEnabled;
}

class SubscriptionService {
  const SubscriptionService();

  Future<List<SubscriptionPlan>> getDoctorPlans() async {
    return const [
      SubscriptionPlan(
        id: 'doctor-premium-placeholder',
        title: 'Doctor Premium',
        description:
            'Future optional tools for doctors. Payments are intentionally disabled until provider and policy review are complete.',
      ),
    ];
  }
}
