# Init Skill

Initialize a Melange template for a specific project. Run once, on an uninitialized
repository. The end state is identical to completing the manual path in SETUP.md.

## When to Invoke

- First session on a freshly cloned Melange template
- When `{{PLACEHOLDER}}` strings are still present in CLAUDE.md
- Retrofit: when adopting the template on an existing codebase (see Retrofit Mode below)

## Guard: already initialized?

Before doing anything, check CLAUDE.md for `{{` strings. If none exist, report:

```
This project appears to already be initialized — no {{PLACEHOLDER}} values found in CLAUDE.md.
If something looks wrong, open CLAUDE.md directly and check for any remaining placeholders.
```

Then exit the skill. Do not proceed.

## Retrofit Mode

Detect whether this is an existing codebase vs. a greenfield project before Phase 1.

Check for any of the following in the working directory:
- `go.mod` (Go)
- `package.json` (Node.js / frontend)
- `requirements.txt` or `pyproject.toml` (Python)
- `Cargo.toml` (Rust)
- `pom.xml` or `build.gradle` (JVM)
- `*.csproj` or `*.sln` (C#/.NET)
- `Gemfile` (Ruby)

If any of these exist, this is a **retrofit** — an existing codebase is adopting the
template. In retrofit mode:

1. **Skip Phase 1 (Ideation)** — the project already exists. Instead, ask once:
   > "I see this is an existing project. In one or two sentences, describe what it does
   > and who uses it. I'll use that as the project description."
2. Proceed directly to Phase 2 (Technical Interview). Notify the user:
   ```
   Retrofit mode: existing codebase detected. Skipping ideation — proceeding to
   technical interview to capture your stack and commands.
   ```
3. For commands in Phase 2, scan the detected project files for likely defaults before
   asking (e.g., if `package.json` exists and has a `build` script, pre-fill it and
   confirm rather than asking from scratch). Mark pre-filled answers clearly.
4. Continue with Phases 3–5 as normal.

---

## Phase 1 — Ideation

Accept the project description from the `/init` argument. If no argument was provided,
ask once:

> "Describe what you want to build in one or two sentences. Include the domain, who uses
> it, and the primary capability."

Then follow the ideation skill process (`.claude/skills/ideation/SKILL.md`) on that
description. Work through all six questions: problem, success criteria, scope, dependencies,
complexity estimate, and risks.

Extract from the ideation output:
- **Project description** — synthesize a single clean paragraph: what the project is, who
  uses it, and its primary capability. This is `{{PROJECT_DESCRIPTION}}`. Do not paste the
  entire scope document — write one paragraph that a contributor could read in 10 seconds.
- **Complexity estimate** — used in Phase 3 to determine roadmap depth (S → 2 phases, M →
  3, L → 4, XL → 4–5)
- **Risks and non-obvious constraints** — captured in MEMORY.md rules section

If the ideation process identifies technical unknowns (stack choice, auth pattern, data
model approach), dispatch the researcher agent per the ideation skill's instructions and
include the summaries inline before moving to Phase 2.

---

## Phase 2 — Technical Interview

Ask ONLY the questions ideation cannot answer. Ask them all at once in a single message —
never one at a time.

If the stack was clearly stated in the project description (e.g., "in Go", "using React"),
skip question 1 or pre-fill it and confirm.

```
To finish initialization I need a few technical specifics. Answer what you know — use
"N/A" or "skip" for anything that doesn't apply yet.

1. Language and stack (e.g., "Go 1.22 + PostgreSQL 15", "Node.js 20 + React 18 + SQLite")
2. Build command (exact shell command, e.g., `go build ./...` or `npm run build`)
3. Test command (exact, e.g., `go test ./...` or `npm test`)
4. Lint command (exact, e.g., `golangci-lint run` or `npm run lint`)
5. Format command (exact, e.g., `gofmt -l .` or `npm run format`)
6. Deploy command (exact, or "N/A")
7. Docs command (exact, or "N/A")
8. Path to authentication/session code (e.g., `src/auth/`, or "N/A")
9. Path to core data model (e.g., `src/models/`, or "N/A")
10. Path to privacy-sensitive code (e.g., `src/user/`, or "N/A")
11. Path to performance hot path (e.g., `src/handlers/search.go`, or "N/A")
12. Path to schema migrations (e.g., `migrations/`, or "N/A")
13. Git remote URL (e.g., `git@github.com:org/repo.git`, or "skip")
```

Wait for the user's response. Do not proceed to Phase 3 until the user replies.

If any command is ambiguous (e.g., "I'll use Jest but haven't set it up yet"), record it
as N/A and note it in the verification gate output so the user knows to revisit it.

---

## Phase 3 — Generate Roadmap Phases

From the ideation scope and complexity estimate, derive roadmap phases:

- Phase 00 is always "Foundation — project setup, CI, core types" (pre-filled in the template)
- Add 2–4 more phases based on complexity: what must be built, in what order, at what granularity
- Each phase name is one line: capability delivered, not implementation detail
- S complexity → 2 total phases; M → 3; L → 4; XL → 4–5

Examples:
- "Phase 01 — Core API — CRUD endpoints for primary resources, authentication"
- "Phase 02 — Data pipeline — ingestion, validation, storage layer"
- "Phase 03 — UI — dashboard views, user-facing query interface"

---

## Phase 4 — Fill Placeholders

Fill every `{{PLACEHOLDER}}` across the files below. Never leave a `{{PLACEHOLDER}}`
string in any tracked file — either fill it with a real value or remove the row/section.

### CLAUDE.md

- `{{PROJECT_NAME}}` — short name, extracted from description or asked once if ambiguous
- `{{PROJECT_DESCRIPTION}}` — synthesized paragraph from Phase 1
- All six command placeholders — exact values from Phase 2; if N/A, remove that table row
- Protected file placeholders:
  - If a path was provided: fill the placeholder
  - If N/A: **remove the entire table row** — do not write "N/A" in the table, as agents
    interpret every row as a real, guarded file path
- Delete the template instruction comment block (the `<!-- TEMPLATE INSTRUCTIONS ... -->` block). The gate will fail if any `<!-- TEMPLATE` string remains in a tracked file.

### README.md

- `{{PROJECT_NAME}}` h1
- `{{PROJECT_DESCRIPTION}}` paragraph
- Remove the `> **Initializing this template?**` notice line

### `.claude/memory/MEMORY.md`

- `{{LANGUAGE_AND_STACK}}` — from Phase 2, question 1
- `{{CURRENT_PHASE}}` — "Phase 00 — Foundation (not started)"
- `**Template version:**` — read `TEMPLATE_VERSION` from the repo root and add the value
  to Core Facts (e.g., `**Template version:** 0.1.0`). This records the baseline for
  future upgrade comparisons.
- Add any non-obvious constraints from ideation risks to the Non-Negotiable Rules section
  (constraints a future agent must not violate — not implementation notes)

### `docs/planning/PROJECT_ROADMAP.md`

- `{{PHASE_01}}` through available phase slots — phase descriptions from Phase 3
- `{{CURRENT_FOCUS}}` — "Phase 00 — Foundation"
- Remove any `{{PHASE_XX}}` rows that were not filled

### `.claude/settings.json`

Add a `permissions` block. Merge with the existing `hooks` block — do not overwrite it.

```json
{
  "permissions": {
    "allow": [
      "Bash(<build command>)",
      "Bash(<test command>)",
      "Bash(<lint command>)",
      "Bash(<format command>)"
    ]
  },
  "hooks": { ...existing hooks content unchanged... }
}
```

Include only non-N/A commands. Use exact command strings — no wildcards, no prefixes.

### Git remote (if provided)

If a git remote URL was given in Phase 2:
```bash
git remote remove origin 2>/dev/null || true
git remote add origin <url>
```

Do NOT push — pushing requires explicit user approval and is outside init scope.

---

## Phase 5 — Init Verification Gate

Run each check. Read the actual file content to determine pass/fail — do not infer.

```
INIT GATE

Placeholders:      [PASS | FAIL] — no {{ strings in CLAUDE.md, README.md, MEMORY.md, PROJECT_ROADMAP.md
Template comments: [PASS | FAIL] — no <!-- TEMPLATE blocks remaining in any tracked file
Permissions:       [PASS | FAIL] — .claude/settings.json has non-empty permissions.allow array
Memory:            [PASS | FAIL] — MEMORY.md Core Facts has real stack and phase values
Template version:  [PASS | FAIL] — MEMORY.md Core Facts includes "Template version:" matching TEMPLATE_VERSION
Roadmap:           [PASS | FAIL] — PROJECT_ROADMAP.md has no {{PHASE_XX}} placeholders remaining
Git remote:        [PASS | SKIP] — git remote -v shows a remote (SKIP if user chose to skip)

RESULT: [INIT COMPLETE | BLOCKED]

Blocking Issues:
[List each FAIL with the specific file, line, or value that must be fixed]
```

Do not report INIT COMPLETE with any FAIL items. If blocked, list exactly what is
unresolved and the precise edit needed to fix it.

If INIT COMPLETE:

```
Initialization complete.

Next steps:
1. Delete SETUP.md — it is no longer needed (`rm SETUP.md` or delete in your editor)
2. Run /ideate [first feature or first phase goal] to begin development
3. Run /quality before your first commit

The project roadmap is at docs/planning/PROJECT_ROADMAP.md.
ADRs live in docs/adr/ — use /adr for any architectural decision.
```

---

## Rules

- Ask all technical questions in one batch (Phase 2) — never piecemeal
- Never guess commands — if a command is unclear, accept N/A and flag it in the gate
- Never write "N/A" into a protected files table row — remove the row entirely
- Never push to git remote during init — report the remote was set, let the user push
- Do not invoke `/plan` during init — the roadmap is generated from ideation output,
  not from a feature planning run
- Do not begin Phase 4 until the user has answered Phase 2's questions
