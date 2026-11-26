# HANDOFF: where this repo stands and how to pick it up

Plain handoff for any coding AI (Claude, Grok, Codex, ChatGPT...) or person. Duff, Nov 26, 2026:
"keep logs for another ai to build where you stop". **Update this file in every PR.** Rules and
commands: AGENTS.md. Why things are the way they are: docs/DECISIONS.md.

A game made from this template keeps its own copy of this file (rename the sections to the game):
current state, live links, open PRs, the 8.5 plan + review scores, next steps, build/test, gotchas,
and a newest-first log.

## Current state (2026-11-26, main `77354bb`)
- This is the **starter template**, not a game. Godot 4.7.2 (4.7.x only; CI fails on drift),
  GDScript, portrait 540x960 base, Compatibility renderer, Android APK + web zip.
- Milestone 0 (foundation) is done: items 1-19 in docs/MILESTONE0.md. A new game starts at Milestone 1.
- Recent merges: #22-#24 Eyes (a cloud session drives the running game, docs/EYES.md), #25 Godot
  4.7-only CI gate, #26 Web export + itch-ready zip (`<repo>_web.zip` on the `dev` release), #27
  studio mascot rule (docs/MASCOT.md).
- Open PRs: none.
- Live: no Pages site (a template has nothing to play). APK + web zip: Releases -> `dev`.

## Standing rules every new game inherits (Duff, Nov 26)
- **8.5 rule:** before a round of work, write what it takes to reach an 8.5/10 blind first-time
  player review, get Duff's OK on one card, then build it in one pass. Blind reviews only when Duff
  asks (he cancelled them on Nov 26).
- **Handoff log:** keep `docs/HANDOFF.md` current in every PR (this file is the template).
- **Mascot:** the three-eyed fox is a rare cameo in every game, never a pal, never game-ruining. Duff
  OKs the art on a card first. docs/MASCOT.md.
- Anything green merges itself (game repos), after the fresh-eyes gate (docs/FRESH_EYES.md).

## Waiting on Duff
- Settings -> Template repository (tick it), and the keystone secret (docs/SIGNING.md). Until then
  CI signs with a throwaway key and warns.
- First real audio upload from his phone through `assets/audio/inbox/` (docs/AUDIO.md) proves the intake.

## Next steps, in order
1. Start a game from the template: docs/NEW_GAME.md. Milestone 1 = its core loop.
2. Copy Eyes (tools/eyes, docs/EYES.md) and the web export job into the game repos that lack them
   (Lethemoor already has Eyes).
3. Ideas waiting in QUEUE.md (Nov 22): installed-APK smoke test, bug-report replay, save migration test.

## Build and test (cloud sandbox)
- Godot 4.7.2-stable Linux zip from GitHub releases -> `/usr/local/bin/godot`; fresh clone:
  `godot --headless --path . --import`. Once per clone: `git config core.hooksPath .githooks`.
- Before every push: `tools/test.sh` -> `TESTS PASS`, then `tools/autoplay.sh` -> `AUTOPLAY PASS`.
- Eyes: `tools/eyes/setup.sh` once, then
  `xvfb-run -a -s "-screen 0 1080x1920x24" node tools/eyes/eyes.mjs tools/eyes/smoke.json` -> `EYES PASS`.
- CI: `gh api repos/duffpowell-commits/godot-game-starter/actions/runs?per_page=3` (GraphQL is blocked).

## Gotchas
- Docs-only pushes skip the test gate; any `.gd/.tscn/.tres/.cfg/.json/.txt` change needs a fresh
  `tools/test.sh` on that exact tree or the push guard blocks it.
- Rule-locked files (AGENTS.md, standards/, .claude/, .githooks/, CLAUDE.md top + rules sections)
  need Duff's `duff-ok` label. Agents never add it. Put rule changes in their own PR.
- Commit and push in separate commands. Never force push or push to main.
- After an engine upgrade delete `.godot/imported/` (stale cache = T-pose).

## Log (newest first)
- 2026-11-26 19:55 UTC Claude: wrote this file (handoff refresh across every project).
