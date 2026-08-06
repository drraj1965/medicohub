# Social Publishing Integration

## Implemented

MedicoHub now stores content derivatives for approved/published articles. These are draft promotional assets, not auto-published social posts.

Rules:

- Derivatives must trace to a source article ID and version.
- Derivatives store review and publication status.
- Source article updates mark unsent derivatives as `review_required`.
- No social post is published from MedicoHub without a future provider adapter and explicit approval flow.

## Provider Boundary

Use `SocialPublishingProvider` adapters for Postiz, Mixpost, or official platform APIs. Do not use password sharing, scraping, unofficial cookies, or browser automation that violates platform terms.
