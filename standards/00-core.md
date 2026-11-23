# Core rules (always read this one)

Owner: Duff. These rules apply to every Duff game repo, for any coding AI.
If a repo's own README/CLAUDE.md/AGENTS.md says something more specific, that wins for that repo.
Rules are engine-agnostic: they stay true if a game moves from Godot to Unity or Unreal.
"Godot today" lines say how the template already does it.

## How Duff works
- **Duff is phone-only.** Phone browser, GitHub on the phone, the Godot Android editor. Never give
  him desktop steps. If something can't be done from a phone, say so up front.
- **Do the work, then tell him.** Ask first only if it costs money, can't be undone, or a wrong
  guess is expensive. Ask once, with tappable choices.
- **Green merges itself.** In game repos a pull request with all checks passing gets merged without
  asking Duff. Red CI never merges. Never skip, disable or delete a test to get green.
- **Nothing is "done" until it's checked**: merged to main, CI green, the build installed or live.
- **Show, don't describe.** Visual changes need real engine screenshots saved in `docs/renders/`.
- **Never put secrets in the repo, commits, logs or chat.** Duff adds secrets himself.
- One AI session per repo at a time. `git fetch` before starting and before pushing. Push after
  every chunk of work. Merge to `main` at the end of every milestone.
- Plain words for Duff: short sentences, no jargon, lead with the result.

## Tech rules
- Godot 4.6 (4.6.3 today), GDScript only (no C#, no native plugins), Compatibility renderer
  everywhere (runs on phones and iPhone Safari). Portrait 540x960 base unless the game says otherwise.
- Build all UI with the template's `ui.gd` helpers (text size, contrast and touch size come free).
- Every sound a player must notice gets a caption (`Subs.cue`). Every gameplay colour comes from
  `UI.key()` plus a shape cue.
- Every gameplay scene pauses + saves on focus loss and handles the back button (close sheet / pause).
- Save at every checkpoint; bump the save version and migrate when the format changes.
- Change scenes with `Loader.go(path)` (background load), not a blocking load.
- Every feature serves the game's pitch, or it gets cut.

## Done means
A change is done when: it's on `main`, CI is green, the bot has a PASS line for it, screenshots are
in `docs/renders/` if it's visual, the handoff file says what changed, and the build is in the
`dev` release for Duff to install.

## Finished-game quality

- Finish one representative playable slice before expanding production. Include clean launch, how a new
  player learns the controls, a complete core interaction, its outcome, and retry or return. Use the
  finished slice as the reference for later scenes.
- Keep in-engine references for normal play, a busy encounter, and dialogue or menus. Record the
  camera, scale, lighting, palette and UI conventions. Review new work beside those references.
- For character and outfit changes, review the turnaround, in-game camera view, and phone capture in
  motion. Link the approved reference, asset revision and build. Keep Duff's approval for Duff,
  Madison and Britney in Duff Quest, including scene-specific outfit and hair constraints.
- Read the game at actual phone size. The player, threat and next action should be clear in a busy
  frame. Use shape, contrast or motion to reinforce color. Check readable dialogue, touch targets,
  consistent button states, back behavior and transitions.
- Make important actions readable from setup through impact and recovery. Distinguish hits, misses,
  blocks and pickups visually and in audio. Review short captures muted and with sound.
- Profile frame time on Android in a busy scene, through effects and transitions, and after a longer
  play session. Validate broader compatibility claims on a device below Duff's current Galaxy tier.
- Watch a new player attempt one realistic task without coaching. Record the first hesitation,
  incorrect action or request for help, fix repeatable issues, and retest the same moment.
- For a release candidate, play the exact APK from launch to result using touch. Verify background and
  resume, save and reload, and an in-place update from the last compatible signed build when that path
  exists. Record the commit, APK or CI link, device, pass/fail evidence and any checks still pending.
- Capture a short, unedited gameplay clip from that build. Show the player's action and the game's
  response. Attach it with the playtest report so the next AI can review the same evidence.

### First slices to use as references

- **Duff Quest** — Porch Pirate approach, touch-controlled encounter, clear result and retry.
- **The Devil You Owe** — One hunt from first clue to confrontation and consequence.
- **Chaos Is the Mother of Order** — One rail-yard tactical sequence with readable movement, cover and enemy response.
- **Wildmade** — Create and preview a starter, including a tailless design, then complete one battle with consistent combat rules across cosmetic shapes.
- **Lethemoor** — One full 3D room with movement, interaction, a transition, and a legible camera near walls and doors.
