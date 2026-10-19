# SkillsByRaven

Personal, self-contained skills for Codex and Claude Code: start a task with **raven-lockin**, then finish it with **raven-signout**.

| Skill | Purpose | Result |
| --- | --- | --- |
| [raven-lockin](raven-lockin/SKILL.md) | Understand, implement, verify, and deliver a task | An open PR, progress pushed, and a dedicated task worktree |
| [raven-signout](raven-signout/SKILL.md) | Merge eligible work, sync Plane, and clean up | A verified merge and updated master/default checkout, with cleanup limitations reported |

Both include their own workflow instructions. **No other skills or detritus tools are required.** Creating or installing a skill does not execute it.

## raven-lockin

Start a task from the full prompt and its links, update master (or the verified default branch), and implement in a separate task worktree. Use a supplied branch name or generate `ravenfeatFix/<ticket-handle>-<task-slug>`; without a ticket, use a descriptive task slug. Reuse or optionally create a Plane ticket, assign it to the user, and track progress when Plane is available.

The skill verifies task commits, pushes, and PR creation as **TahmidAurelius**, makes meaningful progress commits, runs relevant verification, and opens a PR explaining what changed, why, how, and validation results. It returns the ticket/PR links and active branch/worktree. It leaves the PR open and the task worktree available for follow-up. It includes all workflow instructions and requires no other skills. Plane is optional; the TahmidAurelius GitHub account must be authenticated separately on each desktop.

The workflow:

1. Read the complete prompt, linked requirements, repository instructions, and task acceptance criteria.
2. Fetch the base remote and safely update master, or the verified default branch. Preserve a busy/dirty base checkout and report when its local pull must be skipped; use the fresh remote base for the task.
3. Respect an explicit branch name. Otherwise generate `ravenfeatFix/<ticket-handle>-<task-slug>` or `ravenfeatFix/<task-slug>` without inventing a ticket number.
4. Create and enter a separate worktree, normally `<repository-parent>/<repository-name>-worktrees/<short-task-name>`.
5. Reuse a corresponding Plane ticket, or optionally create one when project, scope, and user identity are clear. Assign the user and move eligible work to In Progress. Skip unavailable or ambiguous Plane setup.
6. Implement all in-scope tasks, run relevant verification, and commit/push coherent progress as the verified task account.
7. Open or update a PR describing what, why, how, verification results, and material risks/limitations. Use a clearly identified draft when useful for incomplete work.
8. Return the PR link, ticket link or skip reason, verification summary, branch, and absolute worktree path.

Lockin stays in the task worktree for follow-up. It does not merge or mark a ticket Done merely because a PR opened.

## raven-signout

Finish a task by merging its PR when eligible, handling in-scope review feedback, updating its Plane ticket when available, switching back to master (or the repository's default branch), pulling, and verifying the final status. The workflow preserves local work and respects merge protections. Plane is optional; missing access or ticket linkage is reported as skipped.

The skill includes its own GitHub and Plane workflow instructions. It needs no other installed skills or detritus tools. Git and authenticated GitHub access are required; configure Plane authentication separately only if wanted. Never commit account tokens or private configuration here.

The workflow:

1. Inspect the PR, feedback/checks, and local checkout/worktrees. Refresh stale PR description content when needed.
2. Merge only when eligible, including approval on the current head and no standing change request. Address in-scope review feedback and watch for fresh approval when appropriate. Already merged PRs skip the merge call.
3. Update the corresponding Plane ticket with the actual delivery outcome, marking it Done only after its full scope is confirmed delivered. If Plane or a ticket is unavailable, report **Plane: skipped** and continue.
4. Return to master/default checkout, fetch, and pull with `--ff-only`. Preserve nonconflicting untracked files; report tracked changes, collisions, divergence, or busy checkouts instead of discarding work.
5. Remove only verified, clean, task-owned worktrees and safely deletable local branches. Retain anything that cannot be removed safely and explain why.
6. Recheck the PR, applicable ticket, checkout branch, and synchronization. Return links and verified final status, including any partial or pending stage.

Signout does not force-merge, force-push, automatically stash, or delete local files to manufacture a clean result. In-session watching may stop when the session closes; no cross-session schedule is installed automatically.

## Accounts and tools

- Git, shell/file access, and authenticated GitHub access are required. Implementation tasks also need the repository's build and verification tools.
- Lockin uses **TahmidAurelius** for task commits, pushes, and PR creation unless the invoking prompt explicitly requests another identity. GitHub authentication and commit author/committer identity are verified separately.
- **TahmidRaven owns this skills repository.** That does not change the account used for task delivery.
- Plane can use an authenticated connector or private local `~/.config/plane/config.yaml`. Missing Plane access or ticket linkage does not prevent GitHub work.
- Each desktop needs its own authentication. Keep tokens and private configuration outside this repository.

## Install on a Windows desktop

Clone this repository to a permanent local folder, then run the included installer:

```powershell
git clone https://github.com/TahmidRaven/SkillsByRaven.git
cd SkillsByRaven
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\raven-signout\install.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\raven-lockin\install.ps1
```

The installer creates directory junctions in the current user's `.codex\skills` and `.claude\skills` folders. It refuses to overwrite an unrelated existing registration. Keep the repository in place after installation; moving it requires repairing the junctions. The execution-policy override applies only to that installer process.

To register only one agent, append `-Agents Codex` or `-Agents ClaudeCode` to the corresponding installer command. Each installer can be rerun for an existing registration pointing to the same folder.

Reload the agent or start a new session, then invoke:

- Codex: `$raven-lockin` to start/deliver a task; `$raven-signout` to finish/merge it.
- Claude Code: `/raven-lockin` to start/deliver a task; `/raven-signout` to finish/merge it.

Optionally provide a PR URL and Plane ticket handle. Invoke signout only when ready to authorize its task completion actions. See [the skill instructions](raven-signout/SKILL.md) for the workflow.

For lockin, provide the task description and any ticket/requirement links, repository, and preferred branch name. Example: `/raven-lockin XT-956 implement the linked requirements; branch ravenfeatFix/xt956-paigow`. See [the lockin instructions](raven-lockin/SKILL.md). Creating or installing either skill does not execute its workflow. The owner of this personal skills repository is independent of the account used by lockin for task delivery.

Example prompts (use `$raven-lockin` or `$raven-signout` in Codex):

```text
/raven-lockin Implement the requirements in XT-956 and the linked design.
Use branch ravenfeatFix/xt956-paigow.
```

Without a ticket:

```text
/raven-lockin Fix dealer login losing the selected layout. Verify the regression.
```

When ready to merge and clean up:

```text
/raven-signout https://github.com/OWNER/REPO/pull/123 XT-956
```

With no signout arguments, the skill resolves the task from conversation or the current branch. Invoke it only when ready to authorize merge, applicable ticket updates, and safe cleanup.

## Update on another desktop

Run `git pull --ff-only` in this repository. The installed junctions read the updated files directly; a new agent session may be needed to refresh discovery. If a pull adds another skill folder, run its installer to register it.

On another desktop, clone this repository and run both installers there. Junctions and authentication are machine-local. If you move or rename a clone, repair its old junctions before reinstalling; installers intentionally refuse to overwrite registrations pointing elsewhere.
