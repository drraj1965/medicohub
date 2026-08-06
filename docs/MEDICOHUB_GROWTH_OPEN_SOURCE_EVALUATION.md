# MedicoHub Growth Open Source Evaluation

Date checked: 2026-08-05

## Summary Recommendation

Do not vendor any external repository directly into MedicoHub. Integrate through replaceable provider adapters after security, licence, OAuth, and hosting review.

## Candidates

| Candidate | Official project | Licence / notes | Hosting and cost | MedicoHub decision |
|---|---|---|---|---|
| OpenSEO / every-app/open-seo | `https://github.com/every-app/open-seo`, `https://openseo.so/` | Open-source SEO alternative; uses paid data sources such as DataForSEO-style keys for useful metrics. | Self-host or hosted subscription; expect server, data API, monitoring, and maintenance costs. | INTEGRATE as optional `SEOProvider`; do not copy source. |
| Postiz | `https://github.com/gitroomhq/postiz-app`, `https://postiz.com/` | Current docs/search describe AGPL-3.0 and official OAuth-oriented publishing. | Self-host with storage/database plus platform API requirements, or hosted service. | INTEGRATE as optional `SocialPublishingProvider` after OAuth and medical approval workflow. |
| Mixpost | `https://github.com/inovector/mixpost`, `https://mixpost.app/` | Lite is free/open-source; Pro/Enterprise require paid licence for more features. | Self-hosted Laravel-style app; server, queue, database, backups, and licence cost for advanced features. | DEFER; useful concept/reference, evaluate if Postiz is unsuitable. |
| PostHog | `https://posthog.com/` | Product analytics with cloud/self-host options; session replay must be disabled/redacted for medical screens. | Cloud or self-host; event volume and feature costs matter. | INTEGRATE only after privacy review; keep first-party taxonomy canonical. |
| Plausible | `https://plausible.io/` | Privacy-focused public web analytics. | Cloud or self-host; best for marketing/public pages, not product funnels. | BORROW/INTEGRATE for public pages only if needed. |
| n8n | `https://github.com/n8n-io/n8n`, `https://n8n.io/` | Fair-code workflow automation with many integrations. | Self-host or cloud; monitor workflow credentials and execution logs. | DEFER as `WorkflowProvider`; useful for internal ops, not canonical growth data. |
| listmonk | `https://listmonk.app/`, `https://github.com/knadh/listmonk` | Self-hosted newsletter manager with Postgres dependency. | Server, Postgres, email provider, bounce/complaint handling. | INTEGRATE as optional `NewsletterProvider` after consent/unsubscribe mapping. |
| Fider | `https://fider.io/`, `https://github.com/getfider/fider` | Feedback/voting system. | Self-host or cloud; needs identity and moderation mapping. | BORROW CONCEPT or integrate via `FeedbackProvider`. |
| Discourse | `https://www.discourse.org/` | Mature community platform. | Higher ops/community moderation overhead. | DEFER; strengthen MedicoHub Q&A first. |

## Cost Reminder

Self-hosted does not mean free. Budget for VPS/database/storage, backups, monitoring, data providers, email delivery, OAuth app reviews, social API restrictions, and maintenance time.
