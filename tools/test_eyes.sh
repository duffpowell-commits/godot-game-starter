#!/usr/bin/env bash
# Self-test for tools/eyes: the smoke run must pass, and two broken runs must fail.
# A tool that can't fail proves nothing (eval E4). Prints EYES TEST PASS at the end.
set -uo pipefail
cd "$(dirname "$0")/.."
run() { timeout 280 xvfb-run -a -s "-screen 0 1080x1920x24" node tools/eyes/eyes.mjs "$1" 2>&1; }
fail() { echo "EYES TEST FAIL: $1"; exit 1; }

out=$(run tools/eyes/smoke.json); echo "$out" | tail -3
echo "$out" | grep -q "^EYES PASS" || fail "smoke run did not pass"
[ -s docs/renders/eyes/game.png ] || fail "smoke run wrote no game.png"

out=$(run '[{"click": "NO SUCH BUTTON"}]'); echo "$out" | tail -1
echo "$out" | grep -q "^EYES FAIL no visible button" || fail "missing button was not caught"

out=$(run '[{"gd": "return scene_tree.no_such_property.name"}]'); echo "$out" | tail -1
echo "$out" | grep -qE "^EYES FAIL run_script" || fail "broken GDScript was not caught"

echo "EYES TEST PASS"
