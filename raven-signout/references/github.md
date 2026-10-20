# GitHub merge and blocker workflow

This document provides the workflow directly. No other skills or knowledge-base tools are required. Use `gh api` below or equivalent authenticated API tools. Bind all repository names, branch names, and payload values as data, never interpolated shell code. Check exit codes and HTTP responses; paginate list endpoints.

## Identify and read

Resolve the repository from explicit input or the verified git remote, including fork/base distinctions. `GET /user` identifies the caller; `GET /repos/{owner}/{repo}` provides repository permissions and allowed merge methods. Missing push/merge access is a blocker, not permission to change access settings.

Resolve a branch's PR with `GET /repos/{owner}/{repo}/pulls?state=all&head={head-owner}:{encoded-branch}`. Accept only a unique relevant match, or the exact PR identified in the conversation. Never take the first of several matches silently. Record original branch/head before cleanup so reruns can still identify an already merged PR.

For each initial check and each wake, read live data:

| Resource | REST endpoint under `/repos/{owner}/{repo}` |
| --- | --- |
| PR state, head, mergeability, body, base | `/pulls/{number}` |
| PR commits and diff | `/pulls/{number}/commits` and `/pulls/{number}` with diff Accept header |
| Reviews | `/pulls/{number}/reviews` |
| Inline review comments | `/pulls/{number}/comments` |
| Issue-thread comments | `/issues/{number}/comments` |
| Check runs on current head | `/commits/{sha}/check-runs` |
| Combined commit statuses | `/commits/{sha}/status` |

Read required-check/branch-rule metadata when needed and accessible; never treat a failed query as an empty list or passing check. `mergeable == true` only means no content conflict. Use GitHub's composite mergeability and the explicit review/feedback gates below. A mergeability value of null/unknown can be transient: wait briefly and refresh before deciding.

## Feedback and fixes

Inspect all feedback sources before merging, regardless of approval state. Initially account for unresolved actionable earlier feedback as well as new items; use current code/diff and discussion evidence to determine what is already addressed. During watching, track head SHA, last-commit time, and handled feedback IDs in session state. New inline/issue comments and COMMENTED/CHANGES_REQUESTED review bodies are candidates. Exclude the caller's own routine status updates, but do not dismiss an explicit known blocker merely because the caller described it.

An APPROVED review's own body is a merge signal and does not trigger a fix loop by itself. Read its concrete non-blocking observations and surface them after merge; a bare LGTM needs no action. Accompanying inline comments remain candidate feedback. A known unresolved blocker in any source prevents merging.

For each candidate, classify it from the evidence:

- Already addressed or informational: record the disposition. Answer necessary factual clarification in the PR body rather than posting a GitHub comment. Mark its ID handled even if no commit was necessary, so it does not loop forever.
- In-scope actionable feedback: use a clean task-owned checkout of the PR head. Preserve unrelated changes. Implement the smallest correct fix, run relevant tests and repository-required checks, and inspect the full resulting diff against the feedback and task intent. Correct any problems before committing. Commit and push only this task's changes with a normal push; never force-push or skip hooks. If a clean owned checkout cannot be used safely, report the blocker. Refresh the body with final behavior and actual test results, then reset the approval gate against the new remote head.
- Out-of-scope request or an unresolved requirement needing a human decision: report it and stop signout as blocked. Do not mark it informational to permit merging, expand the task, or create a follow-up issue automatically.

Do not create GitHub issues/comments, post reviews as a substitute for independent approval, or change CI configuration just to unblock signout. Failing required CI is a settled blocker; pending CI is a waiting state. If an in-scope requested code fix also resolves a failing test, perform the relevant verification as part of that fix.

## Merge gate and write

Evaluate each reviewer's latest verdict by submission time considering APPROVED, CHANGES_REQUESTED, and DISMISSED. COMMENTED/PENDING reviews do not clear a verdict. A standing CHANGES_REQUESTED blocks regardless of its commit SHA. Require at least one current, non-dismissed approval whose commit_id equals the current head SHA and whose reviewer has no later superseding verdict. Never reuse pre-fix approval after pushing.

Merge only after all feedback reads succeeded, actionable blockers are resolved, approval covers the head, no standing changes request exists, and `mergeable_state` is `clean` or `has_hooks` with no known unmet required check/rule. Never use admin bypass. Re-fetch the PR immediately before merging and recompute if head/state changed.

Select an allowed merge method from repository configuration and existing conventions. Submit `PUT /repos/{owner}/{repo}/pulls/{number}/merge` with JSON `sha` equal to the inspected head and `merge_method` equal to the selected `merge`, `squash`, or `rebase`. Use typed JSON/structured arguments (for gh, a UTF-8 JSON file with `--input` is suitable). A 409/head mismatch requires re-inspection, never a blind retry without `sha`.

For body edits, use `PATCH /repos/{owner}/{repo}/pulls/{number}` with a structured `body` field. Preserve useful content and required template/footer material. For a behind branch, `PUT .../pulls/{number}/update-branch` with `expected_head_sha` may update it; refresh head, feedback, CI, and approval afterwards. Repeated base thrash or conflicts is a blocker. Never perform a local force rebase.

Confirm `merged == true`, merge commit, and merge time with a fresh PR read, then return to the main skill's Plane stage. Closed without merge is a terminal incomplete outcome; do not reopen or cancel a ticket implicitly.

## Description style and review updates

Follow the explanatory style of Raven's [bulk #2383](https://github.com/idnerdidx/bulk/pull/2383), [bulk #2324](https://github.com/idnerdidx/bulk/pull/2324), and [bundle #356](https://github.com/idnerdidx/bundle/pull/356). These private PRs are examples, not runtime dependencies; the rules here are sufficient. Preserve repository template requirements and useful attribution.

Keep the title specific to the affected board/component and resulting change, with a verified ticket handle when available. Keep `## What`, `## Why`, `## How`, and `## Testing` (or equivalent template headings) current: visible before/after behavior and scope; the requirement/defect; the relevant implementation mechanism and compatibility implications; and actual validation commands/harnesses, outcomes, and limitations. Explain concrete changes rather than listing files alone. A small visual change needs only a few focused paragraphs; complex review fixes need enough evidence for another reviewer to assess them.

For one review finding, add/update a concise `## Review feedback addressed` explanation with reviewer, concern, fix, commit SHA, and regression evidence. For several, use `## Review response` and a `Finding | Fix | Commit | Verification / status` table. Carry unresolved findings forward. Distinguish **implemented; awaiting re-review** from reviewer-confirmed acceptance; report each review round's actual outcome without claiming all findings resolved prematurely. Do not paste whole review transcripts.

Refresh the same body after each pushed review-fix milestone or material change in scope or verification, and reconcile it again before merge. Rewrite stale claims throughout the body: adding a saved-layout migration changes a "pure rename" description, and a later failing reproduction supersedes an earlier "all blockers addressed" statement. Update obsolete test counts and remaining-check lists instead of stacking contradictory progress notes.

Keep automated tests, static inspection, local/headless renders, and live-device checks distinct. Include available visual evidence without inventing attachments. Attribute reviewer-run tests to the reviewer and tested SHA; do not claim they were run by this workflow or passed on a later head. Keep unrun live-feed, restart, export, or deployment checks unchecked in `## Remaining before merge` when applicable. Explain any evidence that a failure predates the change; otherwise leave that classification unconfirmed. Approval does not complete outstanding validation or override a known blocker; report whether an unrun check is a required gate or a disclosed follow-up based on task/repository requirements. Do not check it off merely to finish signout.

Use the body PATCH procedure above and re-read the saved body plus head SHA to verify the update. Reconcile concurrent head changes before calling it current. Keep ticket links and useful commit references. These updates do not authorize GitHub comments or reviews.

## Watching when not ready

Default cadence is 60 seconds, with no default idle timeout. Honor a user-supplied cadence or silence budget; reset a silence budget on each actual change in checks/reviews/comments/head/mergeability. Report meaningful changes concisely.

Prefer an available host event monitor that wakes the agent on changes to this PR. Otherwise use an in-session shell watcher or repeated supported waits and fresh reads at the effective cadence. Keep individual blocking waits at most 60 seconds so the user can steer. This fallback requires no external workflow package. Never claim a process exists before launching and verifying it.

At every wake, re-fetch live data and evaluate in order: merged/closed, feedback, merge gate, behind update, settled blocker, then waiting. Pending checks, missing/stale approval, and transient mergeability are waiting states. Conflicts, denied permissions, failing required checks, and unresolved out-of-scope requests stop the watch and report a specific blocker. Do not wait forever on a known permission denial or repeatedly submit a failing mutation.

Continue in-session until merged, closed unmerged, a settled blocker, an explicit user halt, or an explicitly supplied silence budget expires. Stop task-owned watch processes at these exits. If this host cannot keep a watch or in-session waits running, report `Pending: monitoring unavailable; invoke raven-signout again to recheck` rather than pretending automatic continuation. Session closure/sleep can terminate an in-session watch; no cross-session schedule is installed automatically. While pending, do not complete the ticket or clean away the task checkout.
