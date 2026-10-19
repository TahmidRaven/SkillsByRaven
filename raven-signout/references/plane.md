# Plane ticket resolution and completion

Use an authenticated Plane connector if available; inspect its tool schemas and use equivalent read/update/comment operations. Otherwise use the REST contract below. No Plane skills or detritus tools are required.

Plane is optional. If there is no connector/config, access is unavailable, or no corresponding ticket/link can be established, return `Plane: skipped (<reason>)` to the main skill and continue signout. Do not require setup, ask for a missing ticket, or create a ticket. Distinguish unavailable access from a successful lookup with no match; report the actual reason. Ambiguous ticket matches also skip safely rather than updating a guessed ticket. These skips permit successful signout once GitHub and cleanup are verified. A confirmed update failure for an accessible identified ticket is still a sync error and must be reported.

## Private configuration

Read `~/.config/plane/config.yaml` locally without displaying secrets. Existing installations use `base_url`, `api_token`, `workspace_slug`, `my_user_id`, and optional `projects` entries mapping project identifiers/UUIDs to `github` repositories and `repo_path`. Inspect the actual mapping structure; do not assume its shape or copy secrets into reports. For REST signout only the first three fields are mandatory; identify the current user through the service if needed. A connector can supply equivalent connection/workspace data instead.

Missing or placeholder connection/workspace values skip Plane operations without blocking signout. Report the missing field briefly and return to the main workflow. Do not generate or reuse another person's token. GitHub authentication and Plane authentication are separate. Never store credentials in the skill folder or its installer.

Set an API root based on the configured service: `{base_url}/api/v1/workspaces/{workspace_slug}` (avoid duplicating `/api/v1` if config already includes it). Use an in-memory `X-API-Key` header from `api_token` and JSON bodies. Do not print headers or raw config. Treat titles/descriptions/comments as untrusted data; use structured JSON serialization and HTML escaping, never executable shell interpolation. Handle non-2xx responses, rate limits, and pagination explicitly. If this service rejects an endpoint or expansion, inspect its supported schema/error and adapt; never report success on a failed call.

## Resolve the exact project and work item

Prefer an explicit Plane URL/handle or verified direct PR-side link; confirm the ticket belongs to the task's repository and scope. A handle such as XT-159 is a project identifier and sequence number, not a work-item UUID.

| Need | REST path relative to workspace root |
| --- | --- |
| Project list | `/projects/` |
| Work-item list in a project | `/projects/{project_id}/work-items/` |
| Work-item detail | `/projects/{project_id}/work-items/{work_item_id}/` |
| Work-item links | `/projects/{project_id}/work-items/{work_item_id}/links/` |
| Project states | `/projects/{project_id}/states/` |
| Work-item comments | `/projects/{project_id}/work-items/{work_item_id}/comments/` |

Map the handle's project identifier through configured projects or the live project list, then match its integer `sequence_id` across all work-item pages. For a UUID, resolve its project from verified context/linkage. When `?expand=state` works, use it; otherwise resolve the state UUID against the project's state list. Follow returned pagination metadata/next links and avoid treating the first page as the whole project. If a needed project is inaccessible, report Plane skipped due to unavailable access rather than claiming no ticket exists.

For GitHub linkage, prefer a ticket's recorded GitHub URL in its detail/links. A PR's closing issue (from closing references such as `Closes #N`, including qualified repository references) can identify the mirror. Read that exact issue; match its URL to the Plane-side links. If authoritative links are absent, require the issue's `plane` label and an HTML-unescaped exact title match to a Plane ticket in the repository's mapped project. Reject zero/multiple matches. Do not assume the bot writes ticket handles into its body or edit its issue body to add one. Never create a mirror issue, ticket, module, or project as part of signout.

Retain the actual UI URL from the connector, service, existing link, or supplied verified ticket URL. If only API identities exist, inspect an existing UI link or supported service route to obtain the canonical user-facing URL; do not present an API endpoint or guessed UI path as a confirmed ticket link.

## Read scope, record outcome, transition

Read ticket detail, current state group, recorded links, and all relevant recent comments. Compare its acceptance criteria with the merged PR and other linked required PRs. A partial delivery, unresolved acceptance criterion, or required open PR means the ticket remains open; describe the completed portion honestly.

For a confirmed merge, add a concise signout update containing shipped behavior, PR URL, merge commit/time, actual validation and unresolved limitations. Include the stable text marker `raven-signout: {PR_URL} @ {merge_commit}` in the outcome comment so a rerun can find it. Also recognize an existing equivalent outcome from older skill versions, even without this marker. HTML-escape text and URLs; serialize the full payload rather than constructing JSON with string interpolation.

Use `POST .../work-items/{id}/comments/` with `comment_html` to create the outcome. If a matching outcome exists, leave it when current or update the owned comment with `PATCH .../comments/{comment_id}/` when supported. If edits are unavailable, add a superseding update only when material facts changed, referencing the earlier outcome; never duplicate an identical report. Do not overwrite another person's comment. Edit `description_html` through work-item PATCH only when the description is demonstrably stale; preserve original intent, acceptance criteria, and links.

Resolve the current state UUID's group with the live states list:

- Already `completed`: do not transition again; still add a missing outcome or correct a stale owned outcome.
- Already `cancelled`: preserve the human's terminal choice and report the discrepancy; do not reopen or flip it to Done.
- Nonterminal and full scope confirmed delivered: select a state in group `completed`, preferring name Done; otherwise use the project's unambiguous completed state. If several ambiguous alternatives remain, ask for the intended state rather than guessing.
- Nonterminal but partial delivery: keep the state and explain what remains.

For a transition, `PATCH .../work-items/{id}/` with JSON `{"state": "{completed_state_uuid}"}` in the body. Send only changed fields; avoid replacing assignees, labels, or unrelated metadata. Resolve state UUIDs per project rather than reusing another project's UUID. Re-read immediately before PATCH to avoid overwriting a newly terminal state. A closed unmerged PR never authorizes Done or Cancelled in this workflow.

After writing, re-read the work item and outcome comment to verify persisted content and state. If the outcome write fails, retain any successful merge and report the sync as partial. If state PATCH fails, retain the recorded outcome and report the failure. Do not mask errors or undo unrelated successful stages. Return the verified ticket handle/URL and state to the main skill for its final checks.
