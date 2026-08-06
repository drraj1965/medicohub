# PWABuilder Package Steps

1. Build Flutter Web:

```powershell
cd D:\Rajshekher-Projects\Aster\doctor_forum_app\frontend_flutter
flutter clean
flutter pub get
flutter build web --release
```

2. Host the `build/web` output on a stable HTTPS URL.

3. Open PWABuilder:

https://www.pwabuilder.com/

4. Enter the hosted URL.

5. Confirm:

- Manifest detected.
- Service worker detected.
- Icons detected.
- HTTPS works.
- App name is MedicoHub Connect.
- Display mode is standalone.

6. Generate Windows package.

7. Download package.

8. Upload package in Microsoft Partner Center.

## If PWABuilder Flags Offline Support

Flutter generates service worker files during `flutter build web`. The app also includes `offline.html`, but a future improvement may wire the generated service worker to route failed navigations to `offline.html`.
