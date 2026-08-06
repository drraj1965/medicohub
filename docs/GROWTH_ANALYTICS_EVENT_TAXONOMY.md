# Growth Analytics Event Taxonomy

## Implemented Endpoint

`POST /api/growth/events`

Core fields:

- `event_name`
- `anonymous_id`
- `user_id`
- `session_id`
- `campaign_id`
- `source`, `medium`, `platform`
- `content_id`, `specialty_id`, `language`, `region`
- UTM fields
- `experiment_id`, `variant_id`
- `app_version`, `device_category`
- bounded `metadata`

## Activation Definition

Registration alone is not activation. Activation events currently include:

- `article_saved`
- `specialty_followed`
- `doctor_followed`
- `question_submitted`
- `article_comment_created`
- `comment_created`
- `migraine_entry_created`
- `vestibular_module_started`
- `digest_subscribed`
- `patient_profile_completed`
- `article_shared`
- `referral_created`

## Privacy Controls

The event endpoint rejects obvious sensitive metadata keys such as diagnosis, symptoms, medication, email, phone, name, and free-text medical notes. User IDs are stored with a pseudonymous hash key for analytics aggregation.
