# AGENTS.md

Any coding AI working in this repo (Grok, Claude, Copilot, Codex...): read **GROK_STANDARDS.md**
first and follow it. It is the full rulebook for Duff's games: Milestone 0 (copy the template, don't
rebuild it), full-range 3D movement, the twelve game standards, the keystone signing key, the in-app
updater and REPORT A BUG, "green merges itself", and phone-only (no desktop steps for Duff).

Then read **CLAUDE.md** (this repo's handoff: what's built, commands, layout). Repo-specific rules
in CLAUDE.md win where they are more specific.

Before every push:
- `godot --headless --path . --script tools/check_scripts.gd` prints `SCRIPTS OK`
- `XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tests/run_tests.gd` prints `ALL PASS`
- `tools/autoplay.sh` prints `AUTOPLAY PASS`
