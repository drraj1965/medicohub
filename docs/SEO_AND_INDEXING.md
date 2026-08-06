# SEO and Indexing

## Implemented

- Public web shell title and meta description.
- Canonical URL: `https://mediconverse.web.app/`.
- Open Graph and Twitter card metadata.
- Conservative `WebSite` JSON-LD.
- `robots.txt` blocking likely private/admin routes.
- `sitemap.xml` for public shell and legal/support pages.

## Indexability Rules

- Index: public home shell, privacy, terms, disclaimer, content policy, support.
- Future index after prerender/static export: public published articles, public doctor profiles, public educational videos, approved public Q&A summaries.
- Do not index: drafts, private questions, account pages, patient dashboards, diaries, admin pages, Growth Studio, uploads, private messages.

## Required Next

Flutter web does not yet provide crawlable per-article HTML. Add static article export, prerendering, or SSR-backed public article pages before expecting strong article SEO.
