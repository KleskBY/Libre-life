# Building and signing the ObjectN release for Google Play

Upload format is an **Android App Bundle** (`.aab`). Only the **objectn** flavor goes to Play.
Never upload the **quake** flavor: it is a local test build that reads id Software's Quake data.

Package name: `by.quake.zircon` · min Android 8.0 · target SDK 36 · arm64-v8a + x86_64.

## 1. Create your upload key (once, you do this)

Pick a password and keep it safe. If this key is lost you can ask Google to reset the upload key,
but do not lose the password before that.

```bash
"D:/Android/jdk-21.0.12.1+1/bin/keytool" -genkeypair -v -keystore <key folder>/objectn-upload.jks -alias objectn -keyalg RSA -keysize 4096 -validity 10000
```

`keytool` asks for the keystore password and your name/organization. Store the `.jks` outside the
repo or rely on `.gitignore` (already covers `*.jks`, `*.keystore`, `keystore.properties`).

## 2. Tell Gradle about the key

Either create `android/keystore.properties` (gitignored):

```properties
storeFile=<key folder>/objectn-upload.jks
storePassword=<your keystore password>
keyAlias=objectn
keyPassword=<your key password, same as above unless you set another>
```

…or set environment variables instead, which keeps the password out of any file:

```bash
set UPLOAD_KEYSTORE=<key folder>/objectn-upload.jks
set UPLOAD_KEYSTORE_PASSWORD=...
set UPLOAD_KEY_ALIAS=objectn
set UPLOAD_KEY_PASSWORD=...
```

With neither present the release build still runs but stays **unsigned**, which Play rejects.

## 3. Build the bundle

Every upload needs a higher `versionCode` than the last one:

```bash
cd <repo>/android
./gradlew.bat bundleObjectnRelease -Pzircon.versionCode=1 -Pzircon.versionName=0.1.0
```

Output:

```
<zircon.buildRoot>/app/outputs/bundle/objectnRelease/app-objectn-release.aab
```

Native debug symbols are included (`debugSymbolLevel = FULL`), so Play Console shows readable
native crash stacks.

## 4. Check it is really signed

```bash
"D:/Android/jdk-21.0.12.1+1/bin/jarsigner" -verify -verbose:summary <zircon.buildRoot>/app/outputs/bundle/objectnRelease/app-objectn-release.aab
```

Expect `jar verified`. To see which key was used:

```bash
"D:/Android/jdk-21.0.12.1+1/bin/keytool" -list -v -keystore <key folder>/objectn-upload.jks -alias objectn
```

The SHA-256 fingerprint shown here must match the "upload key certificate" fingerprint that Play
Console displays under Test and release → Setup → App signing.

## 5. Upload to Play Console

1. Play Console → Create app (or open the existing ObjectN app). Type: game, free.
2. Test and release → choose a track. Start with **Internal testing**: it has no review wait and
   takes any number of testers you add by email.
3. Create a release → upload the `.aab`.
4. **Play App Signing** is on by default: Google keeps the real app signing key and your `.jks` is
   only the *upload* key. Losing the upload key is recoverable; that is why this split exists.
5. Fill in the release notes and roll out to the track.

Before a production release Play requires declarations only you can make, as they are legal
statements about your game: content rating questionnaire, data safety form, privacy policy,
target audience, ads declaration, and US export compliance. A personal developer account also
needs a closed test with 12 testers running for 14 days before production access opens.

## 6. Updating later

```bash
./gradlew.bat bundleObjectnRelease -Pzircon.versionCode=2 -Pzircon.versionName=0.2.0
```

Same key every time. A different key on an existing app is rejected.

## Notes

- Bundle size is about 147 MB, most of it `assets/objectn.pk3` (the shrunk game data). Play's limit
  for the generated download is 200 MB, and the console shows the estimated download size per device.
- If you ever need an installable file instead of a bundle (sideloading, itch.io), build
  `assembleObjectnRelease` and sign the APK with the same key using `apksigner`.
- The engine tree used for a release build is whatever `engine_source` points at; see
  `ENGINE_UPGRADE.md` for upgrading it.
- Asset licensing is still open for some sounds and models (see the project notes); Play's content
  declarations assume you have the rights to everything you ship.
