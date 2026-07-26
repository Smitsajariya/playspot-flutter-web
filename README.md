# PlaySpot — Flutter Port (UI shell, v1)

This is the **first pass**: visual screens only, no backend wiring yet (per your call — UI first, Socket.io later).

## What's built
- **Theme** (`lib/theme/playspot_theme.dart`) — every CSS color/spacing/radius variable from your HTML, ported 1:1 as Dart constants
- **Home / landing screen** — sticky header, stories row, quick actions, filter chips, games feed (grid/list toggle), events list
- **Sport picker screen** — the grid you tap through when hosting
- **Events screen**
- **Leaderboard screen**
- **Floating bottom nav pill** — including the raised gold "HOST" button
- Demo/placeholder data in `lib/models/ps_models.dart` so everything renders without a backend

## What's NOT built yet (next passes)
- Map screen (Leaflet → `flutter_map`)
- Host form, Join screen, In-game screen, Postgame/share, Event detail, Profile-view, Onboarding (3-step profile creation)
- Socket.io connection, REST calls, Google sign-in, photo upload, localStorage equivalents

## How to run this on your machine

1. **Copy this whole folder** into your own Flutter workspace (or just copy the `lib/` folder and `pubspec.yaml` into a project you `flutter create`'d already)

2. **Download the fonts** (one-time):
   - [Space Grotesk](https://fonts.google.com/specimen/Space+Grotesk) — get Regular, Medium, SemiBold, Bold
   - [Space Mono](https://fonts.google.com/specimen/Space+Mono) — get Regular, Bold
   - [Syne](https://fonts.google.com/specimen/Syne) — get Bold, ExtraBold, Black
   - Drop the `.ttf` files into `assets/fonts/` (create that folder)
   - Filenames must match what's in `pubspec.yaml` exactly (e.g. `SpaceGrotesk-Regular.ttf`)

   **Shortcut:** if you don't want to deal with font files manually, swap to the `google_fonts` package instead — add `google_fonts: ^6.2.1` to pubspec.yaml, then in `playspot_theme.dart` replace the `fontFamily: 'SpaceGrotesk'` strings with `GoogleFonts.spaceGrotesk().fontFamily` etc. Tell me and I'll make that swap for you.

3. **Install dependencies:**
   ```
   flutter pub get
   ```

4. **Run it:**
   ```
   flutter run -d chrome
   ```
   (or your Android emulator/device — same command works, just `-d <device>`)

## Next step suggestion
Once you confirm this looks right on your screen, the natural next pieces are either:
- **Map screen** (since MAP is a main nav tab) using `flutter_map` + `latlong2` as the Leaflet replacement
- **Host form + sport picker → host form flow**, since that's the core "create a game" loop

Let me know which one and I'll build it next.
