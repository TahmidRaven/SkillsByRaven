---
name: raven-signout
description: Finish Raven's completed task when asked to sign out with /raven-signout or $raven-signout. Merge its PR when eligible, handle review blockers, sync its Plane ticket, clean up task worktrees, update master, and verify the final status. Includes its own GitHub and Plane workflows.
---

# Raven Signout

Run when the user invokes `/raven-signout`, `$raven-signout`, or explicitly asks for this workflow. Creating, installing, or discussing this skill does not run it.

Invocation authorizes merging the identified task PR, necessary PR body edits, in-scope review fixes, updating the corresponding Plane ticket, and safe task cleanup. Do not ask for the same authorization again. Actual GitHub and Plane access must still be verified; this skill cannot grant account permissions or bypass repository rules.

Accept an optional PR URL or `owner/repo#number` and optional Plane handle/URL. Without arguments, use the task in the conversation, then the current branch's PR. Scope is one task; handle several PRs only when the user explicitly identifies them as that task. Ask only if the target PR remains ambiguous; unavailable or ambiguous Plane linkage is skipped.

## Included workflows and required access

This skill is self-contained. Do not load or invoke other skills, detritus KB documents, or external workflow packages to carry out signout. Its supporting instructions are bundled here:

- Read [references/github.md](references/github.md) for PR inspection, feedback fixes, approval gates, watching, and merging.
- Read [references/plane.md](references/plane.md) for config, ticket resolution, linkage, outcome updates, and completed-state transitions.

The host needs git, authenticated GitHub access (`gh` or an equivalent API tool), and shell/file tools. Plane is optional: use an authenticated connector or the private local config described in the bundled reference when available. If Plane is absent, unconfigured, inaccessible, or no corresponding ticket can be found, report `Plane: skipped` with the reason and continue without asking the user to configure it or supply a ticket. Such a skip does not block successful signout. Missing required GitHub/git access still blocks its affected stages. Never print tokens, copy credentials into this skill, install tools, or create external resources implicitly.

## 1. Resolve and inspect

Record repository identity, target PR URL/number, head SHA, base branch, merge state, task branch, original checkout path, and `git worktree list --porcelain`. Read `git status --short --branch` for every checkout that may be changed. Check for staged, unstaged, untracked, unpushed, or unrelated work and active git operations before switching or deleting anything.

Use live GitHub REST reads (`gh api`) for PR metadata, reviews, inline comments, issue-thread comments, checks, and repository merge settings. Verify authenticated access. Prefer REST over `gh pr view`/`gh pr edit`, which can fail on older Projects integrations.

Resolve the Plane ticket from explicit input, a verified PR-side ticket link/handle, or the PR's closing issue and authoritative Plane-side GitHub link. Use the configured repository mapping; paginate searches. The makeplane bot does not reliably put ticket handles in issue bodies. Its fallback signal is the `plane` label plus an HTML-unescaped exact title match within the mapped project. Reject multiple matches. Never create a duplicate mirror issue or guess a ticket from a loose title match.

When a corresponding ticket is accessible, read its scope and linked PRs. If Plane is unavailable or linkage is missing, skip Plane and continue the PR and cleanup stages; do not request a ticket or create one. Ambiguous matches must never trigger a guessed update: report Plane skipped because linkage is ambiguous. Never invent a ticket URL or mark an unrelated ticket Done.

## 2. Reconcile the PR and merge

Read the current PR description Markdown and final diff. Update the body in place only if its scope, resulting behavior, validation evidence, or ticket/issue links are stale or missing. Preserve useful links, attribution, and required repository template/footer content. Do not invent passing tests or rewrite the bot-owned mirror issue. No GitHub comments are needed for signout. Use structured API input or a temporary body file, with correct shell quoting.

Follow the bundled GitHub reference's **What / Why / How / Testing** description style and review-update rules. After each pushed fix, reconcile the full body with the latest head, including commit-linked review responses, actual verification, and remaining manual/device checks. Remove stale claims of completion or unchanged behavior when subsequent fixes invalidate them. An approval does not establish that an unrun check passed.

If already merged, skip the merge call and proceed to Plane sync. A closed unmerged PR is an incomplete signout: report it, do not reopen it or mark the ticket Done.

For an open PR, follow the bundled GitHub reference even when it appears immediately mergeable: read feedback first, require approval on the current head SHA, no standing changes-requested verdict, and merge-ready state. Bind the merge to the inspected head SHA and use the repository's permitted merge method; never admin-override protections, force-merge, or dismiss reviews to get through. If the head changes, re-read and re-evaluate.

If the gate is not met, execute the bundled feedback-and-watch workflow on this exact PR. Fix in-scope review feedback, verify the fixes, refresh the PR body, update an eligible behind branch, and wait for fresh approval as described there. A pushed fix invalidates old approvals. Use the host's actual watch/wait capabilities; never claim an unattended watch exists without arming one.

On a settled blocker (for example missing permissions, conflicts, failing required CI, or an out-of-scope request), report it accurately. Do not mark the ticket Done or remove the task checkout. A live watch or degraded manual continuation means signout is pending, not complete. After a successful merge, resume at Plane sync; merging is not the end of signout.

Re-fetch the PR and confirm `merged == true`, its merge commit, and merge time before proceeding. Check API exit status and response; an attempted merge or enabled auto-merge is not a confirmed merge.

## 3. Update the corresponding Plane ticket

Use the bundled Plane reference for config, linkage, API requests, and forward-only terminal transitions. Read existing ticket description, state, links, and recent comments first.

This stage is optional. If Plane or a corresponding ticket is unavailable, record the skip reason and proceed directly to cleanup. Do not retry indefinitely, request setup, or count that skip as an incomplete signout. A confirmed write failure on an accessible identified ticket remains a reported sync error, not a successful update.

Post or update a concise Plane outcome with the PR URL, shipped behavior, actual validation results, merge commit/time, and any unresolved limitations. Preserve the ticket's original intent and acceptance criteria; edit its description only when demonstrably stale. On reruns, reuse an existing signout outcome for that PR and merge commit rather than posting duplicates. An already Done ticket may still need its missing outcome update.

Move to the project's completed-group state (prefer Done) only when the PR is confirmed merged and the ticket's full scope is delivered. A partial PR or other required open PR keeps the ticket open; record the delivered portion and report what remains. Preserve a human-set Cancelled state and report the discrepancy. Already completed means no redundant transition. Never cancel a ticket merely because its PR closed unmerged.

Re-read the ticket and verify both its outcome update and resulting state. If an API request fails, report the failure; do not undo a successful merge or pretend the ticket update succeeded. Independent safe cleanup can still proceed after a confirmed merge.

## 4. Clean up the task and update master, including worktrees

Refresh worktree inventory and status after any fixes. Select `master` if it exists for this repository; otherwise use the verified remote default branch and report that choice. Verify the chosen base remote belongs to the target repository. Do not create a fictitious master or assume a fork's origin is the merge target.

For a normal checkout, require no staged or unstaged tracked changes and no active git operation before switching. Untracked files alone do not block a normal `git switch`: record their paths and content hashes, attempt the ordinary switch without force, and let Git refuse any overwrite collision. Preserve these files; do not delete, ignore, commit, or stash them just to switch. Verify their contents remain unchanged afterwards. If the selected branch is already checked out in another worktree, use that checkout instead of forcing a second checkout.

For a task worktree, locate the main/base checkout, verify it belongs to this repository, and move the shell's working directory there before removing the task worktree. Use the existing selected-branch checkout when present. Do not switch unrelated feature worktrees, disturb other agents' work, or remove the main checkout.

Fetch the verified base remote with pruning, then pull the selected branch with `--ff-only` and explicit remote/branch. Nonconflicting untracked files may remain during the pull; verify their recorded content afterwards. If there is local divergence, tracked changes, an active operation, an untracked-file overwrite collision, or a branch occupied by unrelated work, leave it intact and report cleanup as partial. Do not stash automatically, reset hard, force-switch, or discard files to achieve a clean report.

Remove only a task-owned worktree whose PR is confirmed merged, whose current head matches the merged PR head, whose status is completely clean (including untracked files), and which has no unpushed work or active owner/process. Verify the resolved absolute path against the recorded task worktree before `git worktree remove`; never use `--force` or recursive filesystem deletion. If ownership/activity is uncertain, keep it and report why.

After a safe switch/removal, delete the local task branch only with `git branch -d`, provided no worktree uses it and no unique work would be lost. Squash/rebase merges can make `-d` refuse; leave the branch and report it instead of forcing deletion. Do not delete remote branches or unrelated worktrees as incidental cleanup. Do not delete plans, checkpoints, stashes, or user files.

## 5. Check status again and report

Perform fresh reads after all mutations:

- GitHub: target PR is merged; record its current URL and merge commit.
- Plane, when applicable: correct ticket URL, verified outcome update, current state, and scope completeness. Otherwise retain the explicit skip reason; do not require a ticket link.
- Git: current final checkout path and branch, `git status --short --branch`, and worktree inventory. Fetch the selected base branch again and compare local HEAD with its remote-tracking ref. Fast-forward again only if safe; otherwise report divergence or newer remote work honestly.

Report preserved untracked files separately from tracked changes. They do not prevent successful branch switching and synchronization when preserved without collision, but never describe the checkout as completely clean while they remain. Worktree removal still requires a completely clean checkout, including no untracked files. Confirm the branch in the user's original checkout explicitly; changing the agent's shell directory to a different checkout alone does not change that original checkout's branch. If it must remain on the task branch, say so and why.

Return the PR link and, when available, the Plane ticket link, their verified states, and the final branch/path and synchronization status. Mention any retained task branch/worktree and exact outstanding blocker. Say signout is complete when merge and safe checkout update are verified, and Plane is either verified complete or explicitly skipped because it/ticket linkage is unavailable. A missing ticket or unavailable Plane alone does not make signout partial. A known incomplete ticket scope, preserved Cancelled state discrepancy, or confirmed ticket write/verification error remains partial; report it honestly.

## Installation and reuse

Keep this entire directory, including `references/`, as the single source of truth. Run `./install.ps1` from PowerShell to register it for local Codex and Claude Code via directory junctions. On another Windows desktop, copy or clone this entire directory (without credentials), then run its installer there; junctions are machine-local and must be recreated. No other skills or detritus tools are required. Configure GitHub authentication separately on that desktop; Plane authentication is optional.

If the machine requires signed scripts, use a process-only override from this directory (no permanent execution-policy change):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Use `/raven-signout` in Claude Code. In Codex, select the skill or type `$raven-signout`; the literal `/raven-signout` text is also an invocation request when slash-command UI registration is unavailable. A new agent session or reload may be needed to refresh discovery.
