# Identity, progress commits, and PR delivery

Use authenticated GitHub API tools or `gh api`. These instructions are included directly; no other skills are needed. Use structured payloads or UTF-8 JSON/body files for untrusted text, never shell string interpolation. Paginate list endpoints. Check HTTP status/exit code before reporting success.

## Enforce the requested account

The default task identity is **TahmidAurelius**, unless the invoking user explicitly requests another identity. A remote repository owner is not automatically the authenticated user. `GET /user` must resolve to the requested login for every GitHub mutation. Repository access must permit the intended pushes and PR creation; a skill grants no account permissions.

Inspect configured accounts without printing tokens. When the expected account is logged in but inactive, prefer a process-scoped authenticated client using that account's credential. For GitHub CLI, capture `gh auth token --hostname github.com --user TahmidAurelius` directly into a private in-memory variable, never tool output/logs, then pass it as `GH_TOKEN` only to the task's child process. Never paste tokens into commands, remote URLs, files, commits, or chat. An authenticated connector is acceptable only when its current user is verified as the expected account. Do not assume changing `git config user.name` changes authentication.

For git transport, use a credential helper/transport proven to use the same account; with process-scoped GH_TOKEN, the GitHub CLI helper can be selected per git command using an empty `credential.helper` followed by `!gh auth git-credential`. Verify `GET /user` under those same credentials first. Avoid changing global helpers or active accounts. If scoped authentication is unsupported, an explicit account switch is allowed for this task; record the prior account, verify the selected identity, and restore the prior account after delivery. Do not restore it before the last task push/API write. Do not print secrets during diagnostic retries.

If the account is unavailable, stop the push/PR stages with a clear login requirement. Continue only independent safe local work. Never silently substitute another user, copy another person's credentials, or claim a PR was opened as the user based only on its commit author.

## Author and committer

Resolve the requested user's current GitHub numeric ID and display name from authenticated account metadata. Use a verified account email when known, or GitHub's account-specific `{numeric-id}+{login}@users.noreply.github.com` address. Do not guess an email or reuse unrelated global identity.

Set git author and committer for task-created commits with per-command config/environment, rather than changing global config or a common repository setting shared by worktrees. For example, supply `git -c user.name=<verified-name> -c user.email=<verified-email> commit ...` after clearing any stale author/committer identity environment overrides within that child process. Do not leak these changes into other agents' shells. After each commit inspect `git show -s --format=fuller HEAD` and verify author/committer correspond to the intended account before pushing. If a new unpublished task commit has the wrong identity, correct that commit before pushing; never rewrite already published history automatically.

## Progress pushes

Before committing, inspect the actual worktree path/branch, diff, staged diff, and relevant test results. Stage only reviewed task changes. Run `git diff --cached --check` and repository-required commit checks/hooks. Commit coherent milestones with concise intent-focused messages. Do not skip hooks or embed secrets in progress updates.

Select the head remote explicitly. Prefer a writable branch in the intended repository. If push access is unavailable, use an existing writable fork only when repository/task policy permits; otherwise report the access blocker. Do not create a fork or alter permissions implicitly. Keep the base repository and head repository distinct when using a fork.

For the first push use `git push -u <head-remote> <task-branch>` under the verified task credentials; later normal pushes must still target the recorded remote/branch. Check exit status and confirm remote head SHA equals local HEAD. A rejected push is a blocker to diagnose, never a reason for `--force`. Re-fetch/reconcile concurrent changes safely; never discard another contributor's commits. A pushed checkpoint does not end the implementation loop.

## PR API and body

Read repository metadata (`GET /repos/{base-owner}/{base-repo}`), the PR template, and any existing PR for the exact head. List candidates using `GET /repos/{base-owner}/{base-repo}/pulls?state=all&head={head-owner}:{encoded-branch}`; match base/head identities, not merely title. Reuse an open matching PR; a closed/merged prior PR requires determining whether this is genuinely new work before proceeding. Do not silently reopen an unrelated PR.

Create with `POST /repos/{base-owner}/{base-repo}/pulls` and structured fields:

```json
{
  "title": "Describe the resulting behavior",
  "head": "head-owner:task-branch",
  "base": "master",
  "body": "Actual Markdown description and verification results",
  "draft": false
}
```

Replace every example value with verified task data; use the actual base branch and draft status. Update through `PATCH .../pulls/{number}` with only changed fields. If converting a draft to ready is needed, use a supported API/CLI operation under the same verified account and re-read its status. Do not create a second PR just to change readiness.

Cover what, why, how, verification, ticket/issue links, and material risks/limitations in the body. Follow the repository template and preserve its required sections. Link a verified issue using an appropriate closing reference, including the repository when cross-repository ambiguity exists. A Plane ticket alone is not a GitHub issue number. Do not hand-create a makeplane mirror or invent a `Closes` reference. PR creation and body edits are authorized; GitHub comments, review impersonation, merge/admin bypass, or messages to other people are not added by this skill.

Finally re-read `GET .../pulls/{number}`. Confirm `user.login` matches TahmidAurelius (or the explicit override), `head.sha` matches the pushed commit, and the expected base/head repository, branch, URL, and draft state. A reused PR originally authored by another account cannot satisfy "open as me": report this discrepancy and resolve ownership rather than changing metadata to impersonate its author or opening an accidental duplicate. Read current checks/statuses on head and report pending/failing outcomes honestly. The PR remains open; merging belongs to a separate user instruction.
