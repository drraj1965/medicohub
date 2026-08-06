# Firestore Monetization Schema Proposal

## `monetizationSettings/global`

```json
{
  "adsEnabled": false,
  "sponsoredContentEnabled": false,
  "doctorSubscriptionsEnabled": false,
  "paidCoursesEnabled": false,
  "updatedAt": "timestamp",
  "updatedBy": "adminUserId"
}
```

## `ads/{adId}`

```json
{
  "title": "string",
  "body": "string",
  "label": "Sponsored",
  "ctaLabel": "Learn more",
  "targetUrl": "https://example.com",
  "allowedContexts": ["neurology", "vestibular", "education"],
  "blockedContexts": ["privateQuestions", "reports", "messages"],
  "status": "draft|active|paused|rejected",
  "createdBy": "adminUserId",
  "createdAt": "timestamp"
}
```

## `sponsoredContent/{contentId}`

Similar to `ads`, but for reviewed educational sponsorships that may appear as article-like cards.

## `adPreferences/{userId}`

```json
{
  "personalizedSuggestionsEnabled": false,
  "updatedAt": "timestamp"
}
```

## `subscriptions/{subscriptionId}`

```json
{
  "userId": "doctorUserId",
  "planId": "doctorPremium",
  "status": "inactive|trial|active|pastDue|cancelled",
  "provider": "placeholder",
  "updatedAt": "timestamp"
}
```

## `purchases/{purchaseId}`

Reserved for future courses, webinars, or second-opinion payment flows.

## `doctorPlans/{planId}`

Defines future doctor subscription features.

## Security Rule Recommendations

- Patients can read their own ad preferences and update only their own preference document.
- Only admins can create/update ad and monetization settings.
- Sponsored content must be active and approved before patient users can read it.
- Never allow clients to write purchase/subscription status directly.
- Payment provider webhooks or backend admin endpoints should be the only writers for payment status.
