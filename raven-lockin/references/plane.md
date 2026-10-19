# Optional Plane task setup and progress

This document includes ticket creation/assignment/progress mechanics directly. No other Plane skills, planning skills, or detritus tools are required. Prefer an authenticated Plane connector with inspected schemas; otherwise use the REST contract below. GitHub and Plane are separate account identities.

## Availability, config, and scope

Plane is optional. Missing/unconfigured/inaccessible Plane, an unresolved project/assignee, or ambiguous ticket linkage means `Plane: skipped (<actual reason>)`; continue independent repository work without requesting setup. No ticket existing is also acceptable: create one only under the explicit creation authorization and resolved scope below. Never claim no ticket exists when access failed.

Read `~/.config/plane/config.yaml` privately if using REST. Existing config uses `base_url`, `api_token`, `workspace_slug`, `my_user_id`, and optional `projects` entries mapping project identifier/UUID to GitHub repository and local path. Inspect the real mapping structure rather than assuming it. Resolve equivalent workspace/project/current-user data through a connector when used. Do not print or copy tokens/config into the skill, git, PR, or reports.

Use `{base_url}/api/v1/workspaces/{workspace_slug}` as the REST root, avoiding a duplicate `/api/v1` segment. Authenticate with an in-memory `X-API-Key` header. Serialize JSON and HTML-escape title/description/comment content. Check non-2xx responses, pagination, and service capabilities. If endpoints/expansions differ, inspect the supported schema and adapt rather than pretending the request worked. Stop repeated failing writes and continue independent task work with a reported Plane limitation.

| Resource | Workspace-relative REST endpoint |
| --- | --- |
| Projects | `/projects/` |
| Work-item list/create | `/projects/{project_id}/work-items/` |
| Work-item read/update | `/projects/{project_id}/work-items/{work_item_id}/` |
| States | `/projects/{project_id}/states/` |
| Members | `/projects/{project_id}/members/` |
| Modules | `/projects/{project_id}/modules/` |
| Work-item links | `/projects/{project_id}/work-items/{work_item_id}/links/` |
| Work-item comments | `/projects/{project_id}/work-items/{work_item_id}/comments/` |

## Reuse the corresponding ticket

Prioritize explicit ticket URL/handle, verified task links in conversation/issues/PRs, then repository project mapping. Resolve a handle such as XT-956 to its project identifier and integer sequence_id, not a UUID. Page the project's work items until the exact sequence/UUID is found. Confirm task scope and repository mapping; never choose the first fuzzy title match.

When resolving a GitHub mirror, the authoritative linkage is the ticket's recorded GitHub URL in detail/links. The fallback is a makeplane-owned `plane`-labeled issue whose HTML-unescaped title exactly matches a ticket in the mapped project. Reject ambiguity. The bot does not reliably write ticket handles into issue bodies. Do not edit the bot-owned issue body or create a second mirror.

Before creating anything, search relevant existing tickets/links for the same task and inspect previous lockin outcomes. A rerun must reuse the known ticket, not create another merely because its state changed. An exact unresolved supplied handle is not permission to create a replacement ticket silently.

## User assignment and state

Resolve "me" through the authenticated Plane user's verified UUID, using `my_user_id` and project membership data when available. Do not infer a Plane UUID from the GitHub username or assign a similarly named person. Confirm the user is a valid member of the intended project. If identity cannot be resolved, skip the assignment/creation with the specific reason rather than guessing.

Read the current ticket/state immediately before writes. Add the user to the existing assignee set, preserving other assignees unless explicitly told to replace them; PATCH with the full deduplicated set because `assignees` replaces the whole field. Send this and state fields in the JSON body, not query params.

For backlog/unstarted work, find the project's In Progress state by name within group `started`, or its unambiguous equivalent. PATCH `state` to that UUID. Do not move a ticket already in Code Review/In Review backwards or reset a completed/cancelled ticket. A terminal ticket with unclear new scope needs clarification; do not silently reopen it or create a duplicate to bypass its state. Re-read and verify changes.

## Create one ticket when appropriate

The invoking lockin request authorizes creating a scoped task ticket and assigning it to the user. No separate approval is needed when project, assignee, and intent are resolved. If the invoking prompt explicitly says no ticket/no creation, honor that. Announce the concrete title, project, assignee, state, and module choice before the write. Do not create modules, projects, or additional tickets speculatively.

Derive a clear title and description from the full request and repository evidence, covering intent, scope, acceptance criteria, and relevant links. Resolve a single matching project from explicit input or repository mapping. If it is ambiguous, skip ticket creation rather than guessing. Default priority is none unless the user specifies or evidence justifies another value; do not label everything urgent.

Reuse an existing applicable module when the user names it or it unambiguously matches a module the user leads/belongs to. Otherwise leave the ticket without a module and report that choice. Do not file into someone else's module without explicit direction or a configured all-modules scope. A missing module does not require creating one or stop implementation.

POST the work-item collection with structured fields `name`, `description_html`, `priority`, `state` (resolved In Progress UUID), and `assignees` containing the verified user's UUID. Omit unresolved optional fields; never send fake IDs. Capture returned `id` and `sequence_id`; the ticket handle is `{project-identifier}-{sequence_id}`. Verify the stored assignment/state before claiming success. If a POST times out with uncertain outcome, search by task identity/creation time and recorded links before retrying to avoid duplicates.

If a module was resolved, attach with `POST /projects/{project_id}/modules/{module_id}/module-issues/` and body `{"issues": ["{work_item_id}"]}`. A module attachment failure is reported without creating a second ticket or rolling back independent work.

Retain a verified canonical UI URL from the connector/returned data/existing UI links. For a confirmed Plane Cloud deployment, `https://app.plane.so/{workspace_slug}/projects/{project_id}/issues/{work_item_id}/` is the conventional work-item route; validate it against the actual deployment's links. Self-hosted URLs use the verified UI host, not blindly the API hostname. Do not present an API endpoint or unverified guessed route as a confirmed ticket link.

## Cross-links and PR progress

The makeplane integration owns GitHub mirror creation. Prefer a recorded Plane-side GitHub link, otherwise search the mapped repo for `plane` label plus HTML-unescaped exact title. If needed, retry a few times over at most two minutes with short supported waits while doing other useful work. An absent/late mirror never blocks implementation or PR creation. Do not hand-create a GitHub issue or apply a plane label to fabricate one.

Once a PR exists, POST a concise `comment_html` outcome with PR URL, actual task progress, verification summary, branch, and worktree. Include stable marker `raven-lockin: {PR_URL}`; read existing comments first and reuse/update an owned matching outcome on reruns. Preserve other users' content and avoid identical duplicate comments. Add a genuine mirror issue closing reference to the PR only when that issue was verified.

When the PR is ready for review, move an In Progress ticket to the project's unambiguous review state if one exists. For a draft/blocked implementation leave it In Progress and explain remaining work. Preserve higher or terminal states. Never mark Done just because a PR opened or checks passed; confirmed delivery/merge is outside lockin. Re-read the work item/comment and return its handle, verified URL, assignment, current state, and any failures to the main skill.
