# SkillsByRaven

Personal agent skills for Codex and Claude Code.

## raven-lockin

Start a task from the full prompt and its links, update master (or the verified default branch), and implement in a separate task worktree. Use a supplied branch name or generate `ravenfeatFix/<ticket-handle>-<task-slug>`; without a ticket, use a descriptive task slug. Reuse or optionally create a Plane ticket, assign it to the user, and track progress when Plane is available.

The skill verifies task commits, pushes, and PR creation as **TahmidAurelius**, makes meaningful progress commits, runs relevant verification, and opens a PR explaining what changed, why, how, and validation results. It returns the ticket/PR links and active branch/worktree. It leaves the PR open and the task worktree available for follow-up. It includes all workflow instructions and requires no other skills. Plane is optional; the TahmidAurelius GitHub account must be authenticated separately on each desktop.

## raven-signout

Finish a task by merging its PR when eligible, handling in-scope review feedback, updating its Plane ticket when available, switching back to master (or the repository's default branch), pulling, and verifying the final status. The workflow preserves local work and respects merge protections. Plane is optional; missing access or ticket linkage is reported as skipped.

The skill includes its own GitHub and Plane workflow instructions. It needs no other installed skills or detritus tools. Git and authenticated GitHub access are required; configure Plane authentication separately only if wanted. Never commit account tokens or private configuration here.

## Install on a Windows desktop

Clone this repository to a permanent local folder, then run the included installer:

```powershell
git clone https://github.com/TahmidRaven/SkillsByRaven.git
cd SkillsByRaven
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\raven-signout\install.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\raven-lockin\install.ps1
```

The installer creates directory junctions in the current user's `.codex\skills` and `.claude\skills` folders. It refuses to overwrite an unrelated existing registration. Keep the repository in place after installation; moving it requires repairing the junctions. The execution-policy override applies only to that installer process.

Reload the agent or start a new session, then invoke:

- Codex: `$raven-lockin` to start/deliver a task; `$raven-signout` to finish/merge it.
- Claude Code: `/raven-lockin` to start/deliver a task; `/raven-signout` to finish/merge it.

Optionally provide a PR URL and Plane ticket handle. Invoke signout only when ready to authorize its task completion actions. See [the skill instructions](raven-signout/SKILL.md) for the workflow.

For lockin, provide the task description and any ticket/requirement links, repository, and preferred branch name. Example: `/raven-lockin XT-956 implement the linked requirements; branch ravenfeatFix/xt956-paigow`. See [the lockin instructions](raven-lockin/SKILL.md). Creating or installing either skill does not execute its workflow. The owner of this personal skills repository is independent of the account used by lockin for task delivery.

## Update on another desktop

Run `git pull --ff-only` in this repository. The installed junctions read the updated files directly. Each desktop needs its own installation and account authentication.
