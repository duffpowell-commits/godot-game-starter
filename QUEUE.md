# Queue
Work only on NOW. New asks go under IDEAS with a date until Duff swaps them into NOW.

## NOW
- (template) Nothing: this repo is the starter. Make a game from it (docs/NEW_GAME.md).

## NEXT
- Audio intake (Duff said yes in chat, Nov 24, 2026): built (PR #19), docs/AUDIO.md. Not done until
  Duff's first real upload from his phone converts and lands in a dev APK. Then move to DONE and
  copy it into the game repos.
- In a new game: Milestone 1 = the core loop from docs/PITCH.md, replacing the PLAY section of scripts/game.gd.

## DONE
- Eyes (Nov 24, 2026): Claude drives the running game, docs/EYES.md. Copy into game repos next.
- Milestone 0: foundation, items 1-14 (Nov 19, 2026). See CLAUDE.md.

## IDEAS

### 2026-11-22 — Android playtest and build evidence

- **Installed APK smoke test.** Pilot on the Duff Quest porch encounter using the exact CI APK. Hold a touch action, send the app to the background with Android system navigation, reopen it, and check that the held action clears, a fresh touch works, and the encounter resumes as designed. Capture failure screenshots and Android logs in the same run. Keep a Galaxy playtest for two-finger drag and touch cancellation. [Android UI Automator](https://developer.android.com/reference/androidx/test/uiautomator/UiDevice) · [Godot touch-cancellation issue](https://github.com/godotengine/godot/issues/99647)
- **Replay a phone bug report.** Extend the existing report with an optional bounded trace of gameplay actions, scene or checkpoint, and last available autoplay assertion. Keep raw typed text and unrelated device activity out of the trace. Use the build identifier to replay the report against the matching build.
- **Save migration smoke test.** On a save schema change, load a small previous-version fixture or update a test install in place. Check that the prior checkpoint and settings survive and that the migrated save reloads. Include the result with build evidence.
- **Verify the APK itself.** Publish the APK file's SHA-256, full commit, and CI run ID in the playtest manifest alongside the screenshot and replay. Distinguish the APK file hash from the Actions artifact archive digest. [GitHub artifact digests](https://github.blog/changelog/2025-03-18-github-actions-now-supports-a-digest-for-validating-your-artifacts-at-runtime/)

- 2026-11-22 — **Acceptance criteria and reproducible runtime evidence.** Put the player outcome and observable pass criteria in the issue before coding. For the Porch Pirate pilot, verify that a player can finish an encounter with touch and see a clear result. Extend existing autoplay with a one-command replay and versioned JSON evidence (commit, scene, input sequence or replay path, expected and actual outcomes, links to screenshots and matching build). Use the existing fresh-eyes gate to review against the issue. [Harness design](https://www.anthropic.com/research/harness-design-long-running-apps) · [Reusable CPU procedures](https://arxiv.org/abs/2611.09891)
- 2026-11-22 — **Creative reference and approvals.** Keep approved names, dialogue examples, asset revisions, and scene-specific constraints with each game. For Duff Quest record the approved Dolores voice and Duff outfit and hair rules, and keep Duff, Madison, and Britney approvals explicit.
- 2026-11-22 — **Check instructions for drift.** Pilot a small CI check for shared rulebook paths and command entry points. Keep AGENTS.md canonical and have tool-specific instructions point to it. [Caliber approach](https://github.com/caliber-ai-org/ai-setup)
- 2026-11-22 — **Phone interruption replay.** Add one playtest that leaves gameplay mid-encounter, resumes, and checks that touch input returns and progress is preserved as designed. Include an exact-build link and a one-tap route into the scene when the dev build supports it.

- 2026-11-22 — **GitHub task handoff.** Keep one handoff in each task's GitHub issue or PR with the branch and exact commit, status, next action, open decisions, and links to CI and the build. Point to active tasks from `QUEUE.md`. Use one branch per independently assigned task. [Community example](https://news.ycombinator.com/item?id=47267105)
- 2026-11-22 — **Runtime evidence for the exact build.** Extend autoplay to publish a short replay, key screenshots, and a small game-state report. Link the matching APK when available. Put the commit SHA in the artifact names and an in-game build label so Duff can verify the build from his phone. [Godot community demo](https://www.reddit.com/r/ClaudeCode/comments/1rc82kp/mcp_server_that_gives_claude_49_tools_to_control/)
- 2026-11-22 — **Art approvals by revision and scene.** Link the approved reference, asset revision, scene or outfit constraints, and an in-engine screenshot. For Duff Quest, begin with Duff, Madison, and Britney when their assets are ready for approval.
- 2026-11-22 — **Pilot on one Duff Quest playable scene.** Codex handles implementation and build, Claude resumes from the GitHub handoff, and Grok can provide fresh-eyes review of the exact PR commit using the existing review process. Give Duff one PR link with the build and runtime evidence.

## CUT
- Playtest link + feedback sheet in Milestone 0 (Duff, Nov 19): set up per game when it's playable.
- Phone frame-rate check in Milestone 0 (Duff, Nov 19).
