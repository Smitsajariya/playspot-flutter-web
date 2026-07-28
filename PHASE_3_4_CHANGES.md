# PlaySpot — Phase 3 & 4 Changes

This delivery is the **full merged project** (Phase 1 + Phase 2 + Phase 3 + Phase 4 all applied), so you can drop it in as-is instead of layering zips.

## Phase 3 — needs real backend work (implemented client-side where possible, flagged where not)

1. **Marker clustering** (`map_screen.dart`)
   - Grid-based clustering (no new dependency — `flutter_map_marker_cluster` isn't in `pubspec.yaml`, so this is a manual pass over the existing `MarkerLayer`).
   - Cluster radius shrinks as you zoom in; tapping a cluster zooms in, or opens a list sheet once already zoomed in.
   - New: `_GameCluster`, `_buildClusters()`, `_singleGameMarker()`, `_clusterMarker()`, `_showClusterSheet()`.

2. **Live "players near me" presence** (`services/presence_service.dart`, wired into `map_screen.dart`)
   - Estimates nearby player/game counts from the games list already loaded — a proxy, not true presence (PlaySpot's socket server has no heartbeat event yet). Flagged in the file's doc comment with the exact seam (`user:heartbeat` + `presence:nearby`) to wire later.

3. **Friends screen + sports map** (`services/friends_service.dart`, `screens/friends_screen.dart`)
   - "Friends" = players you follow (`follow_service.dart` + seeded `mock_data.dart`), with mutual sport-tag chips vs. your own profile interests.
   - "Sports Map" toggle shows friend pins — positions are a deterministic placeholder (not real venue check-ins) until that data exists server-side; the UI says so.
   - Wired in via a new 👥 icon on the home header (`ps_home_screen.dart`, `ps_app_shell.dart`).

4. **Post-game rating / MVP vote** (`services/mvp_vote_service.dart`, `group_chat_screen.dart`)
   - Host gets an "End Game & Start MVP Vote" option in the group menu (game groups only).
   - Anyone can then vote: star rating + MVP pick from players seen posting in the chat (no member-roster endpoint exists yet, so this is the practical stand-in).
   - Vote tally is local per-device right now — flagged that a real shared tally needs a `game:end` / `vote:cast` backend pair.

5. **Recurring games** (`host_form_screen.dart`)
   - "Repeat" selector: One-time / Weekly / Bi-weekly, enabled once a date/time is picked.
   - The rule is sent with the game payload (`recurrence: {freq, weekday, time}`) and also saved locally (`ps_recurring_games`) plus confirmed via a notification, since there's no scheduler/cron to actually materialize future instances yet — flagged clearly for backend follow-up.

## Phase 4 — differentiators

6. **Waitlist auto-promote** (`services/waitlist_service.dart`, `map_screen.dart`)
   - Full games show "Join Waitlist" instead of a dead "Game Full" button.
   - Listens to the same `games:update` socket stream `NotificationService` already uses; when a waitlisted game's roster drops below capacity, auto-joins (best-effort) and sends a "A spot opened up! 🎉" notification.
   - Attached once per session in `ps_home_screen.dart`, same pattern as `NotificationService`.

7. **Skill-level matching nudge** (`profile_screen.dart` + `map_screen.dart`)
   - Added "My Skill Level" (Beginner/Intermediate/Advanced) to the profile, next to Interests.
   - Joining a game pitched above your level now shows a confirm dialog ("This game is Advanced, you're marked Beginner — join anyway?") before proceeding; matching/lower/"any" games join immediately as before.
   - This also fixed the previously-unwired "Join Game" button (it was a `// TODO`) — it now actually calls `socket.joinGame(...)`.

8. **Weather widget on game detail** (`services/weather_service.dart`, `map_screen.dart`)
   - Free, no-API-key lookup via Open-Meteo (same "no key needed" pattern as the CartoDB map tiles already in use).
   - Shown in the game bottom sheet: emoji + condition + temp, with a rain-risk highlight for outdoor games.
   - Fails soft — any network/parse error just hides the widget instead of blocking the sheet.

## Notes for next steps
Every item above that's flagged "local-only" or "placeholder" works fully client-side today and degrades gracefully, but will look and feel more correct once matching backend events exist:
- `user:heartbeat` / `presence:nearby` (real presence)
- `friends:list` / venue check-ins (real sports map)
- `game:end` / `vote:cast` (shared MVP tally)
- a scheduler for recurring games (materializing future instances)
- server-ordered waitlist queue (fair promotion across multiple waitlisted users)
