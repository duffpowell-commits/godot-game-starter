# Save-as-you-go and AI handoff protocol

Applies to GPT, Claude, Codex, Grok, and any other agent working in this repository. Its purpose is to reduce loss of progress when a chat, tool session, or model usage allowance ends unexpectedly.

## Mandatory checkpoints
1. At session start, read the repo's rules and current handoff, inspect the working branch and open PRs, and check for concurrent edits. Never assume the previous AI's description is current.
2. Before any long or risky operation (large edit, generation, refactor, test suite, deployment), commit the last **completed, safe** chunk to the appropriate feature branch. Do not commit broken or secret-bearing work merely to create a checkpoint.
3. After each meaningful chunk, save source and assets in the corresponding repository and record the commit SHA. Preserve incomplete work on a clearly labeled WIP branch only when safe, with its untested status explicit.
4. Update `NEXT_AI_HANDOFF.md` (or the repository's established handoff file) on the working branch with: UTC timestamp; task and goal; branch and latest SHA; files changed; completed/unfinished; tests actually run and results; blockers; exact next action; PR and artifact links. Mark unknown or inaccessible state as unknown.
5. Before ending a session or handing off to another AI, save a final checkpoint and verify the remote commit or file exists. Never claim a save until verified.
6. If repository writes are unavailable, write a dated handoff to the user's authorized Google Drive project folder when possible, and report its link. Otherwise give the complete handoff in chat for manual preservation. Never overwrite newer work.
7. Respect CI, independent reviews, branch protection, secrets policy, and approval gates. A handoff commit is not permission to merge or deploy.

## Limits
ChatGPT cannot read its own remaining usage quota, reliably anticipate a usage-limit error, or capture another agent's unsaved editor buffer. Scheduled backups are supplemental, not a substitute for checkpoints during work.

## Minimal handoff template
```md
# Next AI handoff
Updated (UTC):
Repository:
Goal:
Branch / commit:
PR:
Completed:
In progress:
Changed files:
Tests actually run:
Blockers:
Next exact steps:
Links:
```
