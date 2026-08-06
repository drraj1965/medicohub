# Monetization Plan

Priority: Store approval first, monetization second.

## Modes

### A. Free Patient Access

Keep basic patient signup, questions, article reading, and vestibular exercise access free while the user base grows.

### B. Doctor Premium Subscription

Future optional plan for doctors:

- publishing tools
- advanced dashboard
- notification workflows
- analytics
- larger media limits

No payment provider is hard-coded yet.

### C. Sponsored Educational Content

Allow reviewed sponsor cards inside education areas only. They must be clearly labeled and medically safe.

### D. Minimal Contextual Advertising

Use broad page context only, such as `neurology education`, `vestibular rehabilitation`, or `stroke awareness`. Do not use private patient questions or reports for ad targeting.

### E. Paid Courses/Webinars

Future module for doctor-created courses, webinars, or structured rehabilitation programs.

### F. Future Second-Opinion Payment Flow

Keep this disabled until legal, payment, refund, medical liability, and jurisdiction rules are reviewed.

## Services Added

- `frontend_flutter/lib/services/monetization_service.dart`
- `frontend_flutter/lib/services/subscription_service.dart`
- `frontend_flutter/lib/services/ad_service.dart`
- `frontend_flutter/lib/services/sponsored_content_service.dart`

These are placeholders/interfaces so payment and ad providers can be added later without entangling the clinical flows.
