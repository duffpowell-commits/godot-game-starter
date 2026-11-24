#!/usr/bin/env python3
"""Rule lock (Duff, Nov 24, 2026): a PR that changes the rules needs Duff's `duff-ok` label.

Usage: tools/rule_lock.py BASE HEAD   (git revisions; run inside the repo)
Prints each locked change, one per line. Exit 1 if there are any, else 0.
.github/workflows/rule_lock.yml runs it and sets the `rule-lock` commit status: failure until the
PR carries the `duff-ok` label. Agents never add that label (guard.py blocks Claude from it).
Why: on Nov 21 an agent rewrote Foxboard's no-likeness rule on its own, inside an art PR, and
wrote "Duff okayed it" into the PR. Rules are Duff's; a rule change has to be something he sees.

Locked: the rulebook files below, and in CLAUDE.md only the sections whose heading names rules,
guards, signing or Claude-only notes (the handoff sections stay free; every milestone edits them).
"""
import re, subprocess, sys

LOCKED_FILES = re.compile(
    r"^(AGENTS\.md|GROK_STANDARDS\.md|standards/.*|\.claude/.*|\.githooks/.*|docs/FRESH_EYES\.md"
    r"|\.github/workflows/(fresh_eyes|rule_lock)\.yml|tools/rule_lock\.py)$")
LOCKED_HEADING = re.compile(r"rule|guard|signing|claude-only", re.I)


def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def sections(text):
    """{heading: body} for every '## ' section whose heading is locked."""
    out, cur, buf = {}, None, []
    for line in text.splitlines():
        if line.startswith("## "):
            if cur is not None:
                out[cur] = "\n".join(buf).strip()
            cur, buf = (line[3:].strip() if LOCKED_HEADING.search(line) else None), []
        elif cur is not None:
            buf.append(line)
    if cur is not None:
        out[cur] = "\n".join(buf).strip()
    return out


def locked_changes(base, head):
    found = []
    for path in git("diff", "--name-only", base, head).split():
        if LOCKED_FILES.match(path):
            found.append(path)
        elif path.endswith("CLAUDE.md"):
            a = sections(git("show", "%s:%s" % (base, path)))
            b = sections(git("show", "%s:%s" % (head, path)))
            for h in sorted(set(a) | set(b)):
                if a.get(h) != b.get(h):
                    found.append("%s (## %s)" % (path, h))
    return found


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: tools/rule_lock.py BASE HEAD")
    hits = locked_changes(sys.argv[1], sys.argv[2])
    for h in hits:
        print(h)
    sys.exit(1 if hits else 0)
