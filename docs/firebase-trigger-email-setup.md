# Firebase Trigger Email setup

MedicoHub now queues email notification documents in the Firestore `mail`
collection when SMTP/SendGrid direct sending is not configured. The official
Firebase Trigger Email extension can watch that collection and send emails for
new questions, doctor replies, and thread comments.

## What this does not enable

- Mobile SMS OTP remains shelved. Firebase Phone Auth SMS is billed per message.
- Numeric email OTP is not part of this setup. Firebase Auth email/password and
  email verification remain the sign-in path.
- Fly.io remains the always-on backend.

## Option A: Firebase Console

1. Open Firebase Console.
2. Select project `mediconverse`.
3. Go to **Extensions**.
4. Search for **Trigger Email** / `firestore-send-email`.
5. Install the official Firebase extension.
6. Use collection path: `mail`.
7. Configure SMTP provider settings.
8. Keep the default message field path as `message`.
9. Finish installation and wait for deployment to complete.

## Option B: PowerShell with Firebase CLI

Run these commands from Windows PowerShell:

```powershell
npm install -g firebase-tools
firebase login
firebase projects:list
firebase use mediconverse
firebase ext:install firebase/firestore-send-email --project mediconverse
```

The installer is interactive. When prompted, use:

- Firestore collection path: `mail`
- SMTP connection URI: from your email provider
- Default FROM address: your verified sender address
- Message field path: `message`

## SMTP provider notes

The extension needs an SMTP account. Common options are SendGrid, Mailgun,
Amazon SES, Brevo, or Gmail/Google Workspace SMTP. Use a verified sender address
such as a support email for MedicoHub.

## Verification

After installation, create or answer a test question. In Firestore, you should
see a new document in `mail`. The extension will add delivery metadata fields
after it attempts to send.
