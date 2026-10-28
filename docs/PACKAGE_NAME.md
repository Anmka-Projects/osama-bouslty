# Package / Bundle Identifier

Current identifier for the **Bouslty** app:

```
com.anmka.boustlyacademy
```

Previous identifiers (do not reuse):

- `com.anmka.dralaasubscription`
- `com.anmka.stpnew` (older still, only appears in legacy docs)

## Where it lives

| Platform | File | Setting |
|----------|------|---------|
| Android | `android/app/build.gradle` | `namespace` + `applicationId` |
| Android | `android/app/src/main/kotlin/com/anmka/boustlyacademy/MainActivity.kt` | `package` + dir path |
| iOS | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` (Runner + RunnerTests) |
| Firebase | `android/app/google-services.json` | `package_name` |
| Firebase | `ios/Runner/GoogleService-Info.plist` | `BUNDLE_ID` |
| Firebase | `lib/firebase_options.dart` | `iosBundleId` / `androidAppId` |

## Renaming

Android package was renamed with `change_app_package_name`; iOS + Firebase
files were edited manually. After any rename run:

```bash
flutter clean && flutter pub get
```

## Firebase console checklist (required after rename)

The Firebase project must have apps registered for
`com.anmka.boustlyacademy`, otherwise Google Sign-In / FCM / Auth will fail:

1. Add Android app `com.anmka.boustlyacademy`, register **SHA-1**
   (`cd android && ./gradlew signingReport`), download fresh `google-services.json`.
2. Add iOS app `com.anmka.boustlyacademy`, download fresh `GoogleService-Info.plist`.
3. Update `appId` values in `lib/firebase_options.dart` from the new config files.
4. Apple Sign-In / push: APNs key stays project-level, no change needed.

See `GOOGLE_SIGNIN_FIX.md` for the Google Sign-In setup steps.
