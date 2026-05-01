# MedicoHub Architecture Pack

## Product position

MedicoHub is a doctor-patient communication and education platform, not a telemedicine or emergency care system.

## Day 1 to Day 14 plan

### Day 1
- Freeze scope and safety requirements
- Scaffold Flutter and FastAPI workspaces
- Add consent gate and dummy auth

### Day 2
- Define Firestore schema and local JSON mirror
- Create patient and doctor dashboard models
- Add audit event pipeline

### Day 3
- Build Q&A forum thread list and ask-question form
- Add tags, bookmarks, and upvote counters

### Day 4
- Build second-opinion structured submission flow
- Add premium flagging and doctor priority ordering

### Day 5
- Add upload metadata flow with expiry presets and revoke support
- Prepare Google Drive adapter boundary

### Day 6
- Add doctor response composer with structured template
- Force educational/opinion labels on every response

### Day 7
- Add patient-friendly AI summary service abstraction
- Show summary cards for long threads

### Day 8
- Build education library categories, article cards, and watch/read actions
- Add multilingual content placeholders

### Day 9
- Integrate payment abstraction and premium unlock state
- Prepare Stripe and Razorpay adapters

### Day 10
- Add settings, update-check flow, consent review, and language preferences
- Add support links for emergency disclaimer

### Day 11
- Connect Firebase Auth and Firestore in dev environment
- Add doctor verification workflow flags

### Day 12
- Add Google Drive upload implementation and signed-link revocation
- Add background expiry cleanup job

### Day 13
- Seed dummy data, run regression checks, and test on Windows + Android + Web
- Review analytics and audit trail completeness

### Day 14
- Polish UI, packaging, docs, and release workflow
- Prepare APK, Windows installer, and web hosting checklist

## Firestore schema

### `users/{userId}`
- `role`: `patient | doctor | admin`
- `displayName`
- `email`
- `phone`
- `languages`: string[]
- `doctorProfile`: map
- `consentAcceptedAt`
- `verificationStatus`
- `createdAt`
- `updatedAt`

### `questions/{questionId}`
- `authorId`
- `type`: `forum | second_opinion`
- `title`
- `body`
- `tags`: string[]
- `language`
- `symptomsSummary`
- `currentDiagnosisText`
- `premium`
- `paymentStatus`
- `status`
- `bookmarkCount`
- `upvoteCount`
- `lastActivityAt`
- `createdAt`
- `updatedAt`

### `questions/{questionId}/responses/{responseId}`
- `doctorId`
- `doctorName`
- `responseMode`: `text | voice`
- `labels`: string[]
- `keyPoints`
- `meaning`
- `doctorDiscussionPoints`
- `fullText`
- `createdAt`

### `questions/{questionId}/attachments/{attachmentId}`
- `ownerId`
- `fileName`
- `mimeType`
- `storageProvider`
- `storagePath`
- `temporaryUrl`
- `expiresAt`
- `revokedAt`
- `createdAt`

### `education_library/{itemId}`
- `title`
- `category`
- `type`: `article | video`
- `summary`
- `language`
- `durationMinutes`
- `url`
- `createdAt`

### `payments/{paymentId}`
- `userId`
- `questionId`
- `provider`: `stripe | razorpay`
- `amount`
- `currency`
- `status`
- `createdAt`

### `audit_logs/{eventId}`
- `entityType`
- `entityId`
- `action`
- `actorId`
- `payloadHash`
- `payload`
- `createdAt`

## Flutter wireframes

### Main shell
```text
+-----------------------------------------------------------+
| MedicoHub                               Search  Alerts    |
| "Educational only. No diagnosis or prescriptions."       |
+----------------------+------------------------------------+
| My role              | Priority feed                      |
| Patient / Doctor     | - Paid second opinion             |
| Language             | - Recent forum activity           |
| Consent status       | - Saved articles                  |
+----------------------+------------------------------------+
| Thread summary cards                                      |
| Ask button floating over bottom nav                       |
+-----------------------------------------------------------+
| Home | Ask Question | My Questions | Education | Settings |
+-----------------------------------------------------------+
```

### Ask Question
```text
Title
Category chips
Question body
Symptoms summary
Current diagnosis text
Attach files / links
Expiry preset
Language
Premium second opinion toggle
Submit
```

### Doctor response template
```text
Labels: Educational / General guidance / Opinion only
Key points
What it means
What to discuss with your doctor
Voice note optional
```

## UAE monetization strategy

- Free tier: public educational questions, bookmarks, and education library
- Premium patient tier: paid second-opinion posting, faster placement, expanded attachment quota
- Doctor tier: verified doctor profile, premium response analytics, featured education content
- Clinic partnerships: sponsor multilingual education libraries and specialty forums
- Recommended launch pricing:
  - AED 0 for basic Q&A
  - AED 49 to AED 99 per premium second-opinion thread
  - AED 199 to AED 499 monthly for verified doctor tools depending on usage
- Payment rails:
  - Stripe for international cards
  - Razorpay fallback if regional onboarding or payout terms fit better

## Compliance notes

- Always show explicit non-diagnostic disclaimer before content entry
- Never allow prescription generation in UI or backend routes
- Keep expiry on all uploaded files
- Make audit log append-only and time stamped
- Surface emergency redirection on consent and in every response flow
