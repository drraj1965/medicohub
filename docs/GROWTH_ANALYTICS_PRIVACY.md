# Growth Analytics Privacy

MedicoHub is healthcare-adjacent, so growth analytics must stay separate from clinical or private discussion content.

## Implemented

- First-party event endpoint stores identifiers and coarse categories, not question text or medical notes.
- Sensitive metadata keys are rejected server-side.
- Pseudonymous analytics key is derived from user ID with an environment salt.
- Admin Growth Studio access is restricted to admin/growth roles.
- Growth changes emit audit events.

## Required Before Third-Party Analytics

- Document user consent by region.
- Add analytics opt-out and deletion/anonymisation workflows.
- Prevent third-party session replay on authenticated medical screens.
- Redact names, email addresses, phone numbers, messages, uploaded reports, diagnoses, medications, and symptom text.
- Maintain an admin export audit log and retention policy.
