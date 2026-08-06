# Campaign and Attribution Model

## Implemented

Growth campaigns require:

- name
- objective
- hypothesis
- target audience
- value offered
- primary CTA
- primary metric
- channels
- minimum observation period

The backend rejects `registration_completed` as the activation metric because registration alone is not activation.

Events can carry campaign and UTM fields. Campaign counters increment when ingested events include `campaign_id`.

## Next

- Persist UTM/deep-link parameters from first landing visit through signup.
- Merge anonymous IDs into user IDs after registration.
- Add aggregate jobs for daily campaign and funnel reporting.
