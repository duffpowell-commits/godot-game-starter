@AGENTS.md

# Starter Game (godot-game-starter)

Template for every new Duff game: Godot 4.7.2, GDScript, portrait phone, Android APK. Milestone 0
(foundation) is done here, so a new game starts at Milestone 1. Owner: Duff. This is the handoff.
Commands, standing rules, guards and layout: AGENTS.md (imported above), shared by every coding AI.
Why the import (Nov 21): Claude Code skips AGENTS.md when CLAUDE.md exists unless it's imported.
Catch-up log: docs/DECISIONS.md.

## Where things stand
- Rulebook for every game and every coding AI: **AGENTS.md** (commands + standing rules) ->
  **GROK_STANDARDS.md** -> `standards/*.md` (one topic each, <= 60 lines). Change rules here, then
  copy them into the game repos (list at the bottom of AGENTS.md).
- What Milestone 0 built (items 1-19, Nov 19-21): `docs/MILESTONE0.md`. Queue: QUEUE.md. Progress: tasks/todo.md.
- Latest build: Releases -> `dev` -> `<repo>.apk`, rebuilt on every push to main.
- Waiting on Duff: tick Settings -> Template repository; make the keystone (docs/SIGNING.md). Until
  then CI signs with a throwaway key and warns.
- Nov 21: live tuning sliders (DEV MENU -> TUNE), push-guard hooks, fresh-eyes review gate.
- Nov 21 (Grok): Git pre-push hook for every agent (`.githooks/pre-push`, same rules as guard.py);
  rules moved into AGENTS.md, which this file imports.
- Nov 24: audio intake. Real sound goes in from Duff's phone through `assets/audio/inbox/`
  (docs/AUDIO.md); CI converts, levels, logs it and rebuilds. `Audio` plays .ogg/.mp3 before the
  placeholder .wav. Not yet proven on a real upload from his phone (first one is the test).
- Next: start a game from this template (docs/NEW_GAME.md); Milestone 1 = the game's core loop.

## Claude-only notes
- `.claude/settings.json` runs `.claude/hooks/guard.py` before every Bash/Write/Edit call. A blocked
  call comes back with the reason; fix the cause, don't work around it.
- In that hook `--force-with-lease` is allowed; the Git pre-push hook still blocks any push that
  rewrites the remote branch, so plan on merging, not rewriting.
- Commit and push in separate Bash calls: a commit and push in one line is checked before the commit exists.
