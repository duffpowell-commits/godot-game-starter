# AGENTS.md

Any coding AI working in this repo (Grok, Claude, Copilot, Codex...): open **GROK_STANDARDS.md**
first. It is the index of Duff's rulebook, split into small files in `standards/`. Always read
`standards/00-core.md` (phone-only, "green merges itself", what done means), then only the topic
files your task touches (movement, controls, performance, art, build/signing...).

Then read **CLAUDE.md** (this repo's handoff: what's built, commands, layout). Repo-specific rules
in CLAUDE.md win where they are more specific.

Before every push:
- `godot --headless --path . --script tools/check_scripts.gd` prints `SCRIPTS OK`
- `XDG_DATA_HOME=$(mktemp -d) godot --headless --path . --script tests/run_tests.gd` prints `ALL PASS`
- `tools/autoplay.sh` prints `AUTOPLAY PASS`
