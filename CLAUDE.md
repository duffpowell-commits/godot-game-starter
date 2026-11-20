# Starter Game (godot-game-starter)

Template for every new Duff game: Godot 4.5, GDScript, portrait phone, Android APK. **Milestone 0
(foundation) is already done here**, so a new game starts at Milestone 1. Owner: Duff. Read this
first; it is the handoff between sessions.

## Where things stand
- Pitch: docs/PITCH.md. Queue (what to work on): QUEUE.md. Progress: tasks/todo.md.
- Latest build: Releases -> `dev` -> `<repo>.apk` (rebuilt on every push to main). Template's own: https://github.com/duffpowell-commits/godot-game-starter/releases/tag/dev (first green CI Nov 19, build 2).
- Waiting on Duff: tick Settings -> Template repository; make the keystone (docs/SIGNING.md: `KEYSTONE_PASS` secret here, then Actions -> make keystone). Until then CI signs with a throwaway key and warns.
- Done: Milestone 0, items 1-14 (Nov 19) + 15 full movement + 16 the twelve standards (Nov 20). List below.
- **GROK_STANDARDS.md is the rulebook** for every Duff game, for any coding AI. Keep it in sync when a rule changes.
- Next: start a game from this template (docs/NEW_GAME.md), then Milestone 1 = the game's core loop.

## Milestone 0: what's already built (Duff approved items 1-14, Nov 19 2026)
1. Repo files: this CLAUDE.md, QUEUE.md, docs/PITCH.md, docs/style-guide.md, tasks/todo.md + lessons.md.
2. CI (`.github/workflows/build.yml`): parse every script (with autoloads), rule tests, autoplay
   flow, signed APK; on main uploads the APK + version.json to the `dev` release.
3. One signing key for every game except Lethemoor, the **keystone** (Nov 20): `signing/keystone.keystore.enc` + `keystone.sha256`, `KEYSTONE_PASS` secret, made once by `make_keystone.yml`; `signing/unlock.sh` picks the key in CI (docs/SIGNING.md). Lethemoor keeps its own key: never sign another game with it.
4. In-app updater (`scripts/updater.gd`) + version number on the title (`v0.1.<build>`).
5. REPORT A BUG on title + pause (`scripts/bug_report.gd`): GitHub issue or copy-to-text, build/device/state added.
6. Scene flow: boot -> intro (once, skippable) -> title -> game -> pause -> GAME OVER -> title.
   Pauses + saves when the app loses focus (call, home button); Android back pauses, never quits.
7. Autosave/resume (`scripts/save_game.gd`): checkpoint + pause saves, CONTINUE on title, GAME OVER clears.
8. Settings (`scripts/settings.gd`, sheet in `settings_sheet.gd`): music, SFX, brightness, vibration,
   text size, subtitles, high contrast, colorblind colours, left-handed, invert look, sensitivity, low graphics.
9. Touch: buttons >= 72 base units (~56 dp), 18 apart (`ui.gd MIN_TOUCH/GAP`); left-handed mirrors the controls.
10. Audio buses Music + SFX in `default_bus_layout.tres` (must exist at boot for web); `Audio.sfx/music`.
11. Subtitles + sound captions (`Subs.say/cue`), high contrast theme, colorblind-safe key colours
    (`UI.key("good"|"bad"|"info"|"warn")`, Okabe-Ito) plus shape cues.
12. Dev menu (debug builds only; the dev APK is one): 5 taps on the version, 3-finger tap, or F1.
    FPS, god mode, skip level (`debug_skip_level()` on the scene), clear save.
13. Autoplay bot (`scripts/autoplay.gd`, `tools/autoplay.sh`): plays the whole flow with real taps,
    screenshots to docs/renders/, one PASS line per check. CI fails on any FAIL.
14. Placeholder art drawn in code + Foxboard/Forge hookup (docs/ART.md, `foxboard_decode.yml`).
15. **Full range of movement** (Duff, Nov 20; docs/MOVEMENT_3D.md): characters use the full range of
    movement the current engine supports, never faked with bobbing/tilting stills; standard humanoid
    skeleton + glTF so it carries to another engine. Godot today: 8-way + strafe/backpedal, turn in
    place, jump/fall/land, crouch, foot IK, look-at, hit reactions + root-motion knockback, ragdoll,
    climb/vault/swim. `Character3D` (`scripts/character3d.gd`); playground `scenes/character_test.tscn`.
16. **The twelve game standards** (Duff, Nov 20), all in **GROK_STANDARDS.md** (the rulebook any coding AI
    reads; AGENTS.md points to it; copy it into every game repo): game feel (`Feel` autoload), camera
    (`camera_rig.gd`), frame budget (CI `PERF PASS` + dev menu PHONE SPEED TEST), responsive controls
    (buffer, coyote, dodge-cancel in `Character3D`), readability (hero light), audio (footsteps per
    surface, combat layer, ducking in `Audio`), first 60 s (`coach.gd`, `BOOT PASS`), portable assets,
    telemetry + crash hook (`Telemetry`, offline, opt-in), haptics, gamepad + remap (`Controls`,
    Settings -> CONTROLS), offline-first.
Cut by Duff: playtest link + feedback sheet. (Phone frame-rate check came back as standard 3.)

## Layout
- `scenes/` boot, intro, title, game (each a Control + script; UI is built in code).
- `scripts/` autoloads: Settings, Save, Audio, Subs, Updater, DebugMenu, Autoplay. Helpers:
  `ui.gd` (theme, buttons, sheets, colours), `config.gd` (build number, repo), `bug_report.gd`,
  `settings_sheet.gd`. `game.gd` = placeholder "Orb Catch": replace its PLAY section, keep the rest.
- `tests/run_tests.gd` rule tests. `tools/` check_scripts.gd, autoplay.sh, gen_audio.py (placeholder sounds).
- `assets/audio/` (list every clip in SOURCES.md), `assets/art/`. `grok_art/` art drops, never ships.
- `scripts/character3d.gd` 3D character standard (+ `foot_ik.gd`, `aim_twist.gd`, `ragdoll.gd`), `shaders/` toon
  + outline, `assets/models/` shared skeleton + clips (sources in SOURCES.md), `scenes/character_test.tscn` playground.
- Autoloads also: Controls (actions + remaps), Feel (hit feel), Telemetry (local events, crash flag).
  `camera_rig.gd` (3D camera), `coach.gd` (teach-by-doing hints).
- `signing/` the keystone (encrypted) + `unlock.sh` (CI) + `make_keystone.sh` (once). `docs/renders/` autoplay screenshots.

## Commands
- Godot in the cloud sandbox: 4.5-stable Linux zip from GitHub releases -> `/usr/local/bin/godot`.
  Fresh clone: `godot --headless --path . --import`.
- Parse check (autoload-aware): `godot --headless --path . --script tools/check_scripts.gd` -> `SCRIPTS OK`.
- Tests (before every push): `XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tests/run_tests.gd` -> `ALL PASS`.
- Flow + screenshots: `tools/autoplay.sh` -> docs/renders/flow_*.png, last line `AUTOPLAY PASS`.
- CI: `gh api repos/<owner>/<repo>/actions/runs?per_page=3` (gh GraphQL is blocked in sessions).

## Rules for building on this
- Every new screen: build UI with `ui.gd` helpers (gets text size, contrast, touch size for free).
- Every new sound a player must notice: `Subs.cue("[what]")`. Every gameplay colour: `UI.key()` + a shape cue.
- Save at every checkpoint (`Save.write(state())`); bump `Save.VERSION` + migrate when the format changes.
- New scene with gameplay: handle `NOTIFICATION_APPLICATION_FOCUS_OUT` (pause + save) and
  `NOTIFICATION_WM_GO_BACK_REQUEST` (close sheet / pause), deferred, like `game.gd`.
- Extend the autoplay bot when the game grows: one PASS line per thing that must keep working.
- 3D characters: the full range of movement the engine supports (docs/MOVEMENT_3D.md). `Character3D` on the
  shared skeleton, real clips only; a move with no clip doesn't exist yet. Keep every movement PASS line
  in autoplay green for every character.
- Renderer is Compatibility everywhere (runs on phones and in iPhone Safari).

## House rules
- Duff works phone-only (Godot Android editor). No desktop-only tools. GDScript only.
- Push after every chunk of work; merge to main at the end of every milestone.
- Up to three milestones per session, merged and handed off after each. Save renders to files, not chat.
- Visual decisions need real engine renders.
