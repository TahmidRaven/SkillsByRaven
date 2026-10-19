# SkillsByRaven

Personal agent skills for Codex and Claude Code.

## raven-signout

Finish a task by merging its PR when eligible, handling in-scope review feedback, updating its Plane ticket when available, switching back to master (or the repository's default branch), pulling, and verifying the final status. The workflow preserves local work and respects merge protections. Plane is optional; missing access or ticket linkage is reported as skipped.

The skill includes its own GitHub and Plane workflow instructions. It needs no other installed skills or detritus tools. Git and authenticated GitHub access are required; configure Plane authentication separately only if wanted. Never commit account tokens or private configuration here.

## Install on a Windows desktop

Clone this repository to a permanent local folder, then run the included installer:

```powershell
git clone https://github.com/TahmidRaven/SkillsByRaven.git
cd SkillsByRaven
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\raven-signout\install.ps1
```

The installer creates directory junctions in the current user's `.codex\skills` and `.claude\skills` folders. It refuses to overwrite an unrelated existing registration. Keep the repository in place after installation; moving it requires repairing the junctions. The execution-policy override applies only to that installer process.

Reload the agent or start a new session, then invoke:

- Codex: `$raven-signout`
- Claude Code: `/raven-signout`

Optionally provide a PR URL and Plane ticket handle. Invoke signout only when ready to authorize its task completion actions. See [the skill instructions](raven-signout/SKILL.md) for the workflow.

## Update on another desktop

Run `git pull --ff-only` in this repository. The installed junctions read the updated files directly. Each desktop needs its own installation and account authentication.
