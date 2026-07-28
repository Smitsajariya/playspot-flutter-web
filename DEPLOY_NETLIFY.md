# Deploying PlaySpot to Netlify

This project already has `netlify.toml` configured and a `web/` platform
folder — Netlify just needs the repo/zip; you don't need to build locally.

## Option A — Netlify UI (drag & drop or Git)
1. Unzip this project.
2. Push it to a GitHub repo (or use Netlify's "Deploy manually" drag-and-drop
   with a folder — see Option B if you want to skip Git).
3. In Netlify: **New site from Git** → pick the repo.
4. Netlify reads `netlify.toml` automatically:
   - Build command: clones Flutter stable, runs `flutter pub get` and
     `flutter build web --release`
   - Publish directory: `build/web`
5. Deploy. First build takes a few minutes (cloning Flutter itself).

## Option B — Build locally, drag the output folder in
If you'd rather not give Netlify a full Flutter build step:
```bash
flutter pub get
flutter build web --release
```
Then drag the generated **`build/web`** folder (not the whole project) into
Netlify's manual-deploy drop zone.

## Known web-compatibility caveats
- **Video attachments in Create Post** (`create_post_screen.dart`) use
  `dart:io`'s `File` to preview picked videos — this doesn't work on web.
  The screen will still load, but attaching/previewing a video specifically
  (not photos) will error out on the web build. Fine for a first Netlify
  preview; worth swapping to `image_picker`'s web-safe bytes API before a
  real web launch if video posts matter there.
- **Google Sign-In** needs a web OAuth client ID configured in Google Cloud
  Console (separate from the Android/iOS client IDs) and added to
  `web/index.html`, or sign-in will fail silently on web.
- **Geolocator** on web requires the browser's own location permission
  prompt — works, but behaves a little differently than mobile (no
  background location, HTTPS required — Netlify serves HTTPS by default so
  this is already satisfied).
- Everything else (map, chat, host form, profile, friends, notifications,
  weather, waitlist, MVP vote) is pure Dart/Flutter UI and socket calls, so
  it should work the same on web as it does on mobile.
