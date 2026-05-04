# Implementation Plan: Adopt-Codebase

**Feature:** Enhance Retrofit Mode in `/init` to auto-analyze existing codebases  
**Branch:** main  
**Complexity:** M (revised from initial L estimate — all changes are skill markdown edits, not code)

---

## Overview

Enhance the Melange `/init` skill's Retrofit Mode to replace the blank 13-question interview with a
pre-populated confirmation screen built from deterministic manifest analysis and constrained LLM
inference. Add three discrete adoption modes (`--full`, `--governance-only`, `--commands-only`) to
give developers control over how much of CLAUDE.md gets populated.

All changes are to skill instruction files — no shell scripts, no application code.

---

## ADR Candidates

Three ADRs required — author these with `/adr` **before Phase 1 implementation begins**:

1. **Discrete modes vs. adoption spectrum** — choosing 3 explicit modes over a continuous slider
   has UX and maintenance implications. Research showed discrete flags (`--config-only`,
   `--migrate`, `--dry-run`) are the pattern production tools converge on; record why.

2. **Deterministic-first, LLM-for-gaps hybrid** — the choice to use file-signature scanning as
   primary detector and LLM only for structurally ambiguous questions (which npm script is
   canonical? which directory is auth?) is architecturally significant and should be recorded.

3. **Secret-scan guard: opt-in file body analysis** — the privacy rationale for excluding file
   body content from LLM context by default (Samsung 2023 credentials incident) should be recorded
   so future contributors know why the default is restrictive.

---

## Phase 1 — Deterministic Detection Layer + Confirmation Screen

**Goal:** Retrofit Mode reads manifests, lock files, and CI configs to pre-fill all six command
slots before showing a confirmation screen. Nothing writes to CLAUDE.md until confirmed.

### Files modified
- `.claude/skills/init/SKILL.md` — expand the Retrofit Mode section

### Changes

**Expand manifest detection to lock files (higher confidence):**
- `yarn.lock`, `package-lock.json`, `pnpm-lock.yaml` → lock file type identifies the exact
  package manager (locks are ground truth per Renovate/Dependabot pattern)
- `poetry.lock`, `Pipfile.lock` → Python with Poetry/Pipenv
- `Gemfile.lock` → Ruby
- `Cargo.lock` → Rust

**Add CI config detection as supplemental signal:**
- `.github/workflows/*.yml` — parse `run:` lines to surface canonical commands
- `.gitlab-ci.yml`, `Jenkinsfile`, `Makefile` — additional signal sources
- Label CI-sourced values as `DETECTED (CI config)`

**Per-stack extraction rules (deterministic, no LLM):**

| Stack | Build | Test | Lint | Format |
|-------|-------|------|------|--------|
| Node.js | `scripts.build` from package.json | `scripts.test` | `scripts.lint` | `scripts.format` or `scripts.prettier` |
| Python (pyproject) | `[tool.taskipy]` build task | test task | lint task | format task |
| Python (requirements) | INFERRED `python -m build` | INFERRED `pytest` | INFERRED `flake8` / `ruff` | INFERRED `black` |
| Go | INFERRED `go build ./...` | INFERRED `go test ./...` | INFERRED `golangci-lint run` | INFERRED `gofmt -l .` |
| Rust | INFERRED `cargo build` | INFERRED `cargo test` | INFERRED `cargo clippy` | INFERRED `cargo fmt` |
| Ruby (Rails) | INFERRED `bundle exec rails assets:precompile` | INFERRED `bundle exec rspec` | INFERRED `bundle exec rubocop` | INFERRED `bundle exec rubocop -A` |
| JVM/Gradle | INFERRED `./gradlew build` | INFERRED `./gradlew test` | INFERRED `./gradlew checkstyleMain` | N/A |
| JVM/Maven | INFERRED `mvn package` | INFERRED `mvn test` | INFERRED `mvn checkstyle:check` | N/A |

**Label discipline:**
- `DETECTED (source)` — value read directly from a file; evidence source shown (e.g., `package.json scripts.test`)
- `INFERRED` — LLM-reasoned default for this stack; no file evidence

**Monorepo ambiguity resolution protocol:**
- If workspace config files exist (`pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`),
  show the detected workspace files in the confirmation screen and ask a single targeted question:
  "Which workspace is the primary application? (e.g., `apps/web` or `packages/api`)"
- Halt at this question — do not proceed to write commands until the user responds
- Do not attempt partial auto-detection across workspaces; treat the answer as the root for all
  subsequent command extraction

**Updated Phase 2 confirmation screen (Retrofit Mode):**

Replace the blank 13-question interview with a pre-filled confirmation table:

```
I analyzed your codebase and pre-filled the following values. Correct anything that's wrong
and add N/A for anything that doesn't apply.

DETECTED / INFERRED values — confirm or correct:

1. Language and stack:      [value] [DETECTED from package.json / INFERRED]
2. Build command:           [value] [DETECTED from package.json scripts.build]
3. Test command:            [value] [DETECTED from package.json scripts.test]
4. Lint command:            [value] [DETECTED from package.json scripts.lint]
5. Format command:          [value] [INFERRED]
6. Deploy command:          [value or N/A] [DETECTED from .github/workflows/deploy.yml / INFERRED]
7. Docs command:            N/A [INFERRED — no docs tooling detected]
8. Auth/session code path:  [see protected files section below]
9. Core data model path:    [see protected files section below]
10. Privacy-sensitive path: [see protected files section below]
11. Hot path:               [see protected files section below]
12. Migration path:         [see protected files section below]
13. Git remote URL:         [DETECTED from git remote -v / skip if none]

Reply with corrections. Use "ok" to accept the pre-filled values as-is.
```

### Completion signal
Running `/init` on a Node.js project with `package.json` shows pre-filled command values labeled
with their source. Developer can reply "ok" without re-typing any commands they already have.

### Estimate
2–3 hours (instruction writing for 8 stack paths + confirmation screen redesign)

---

## Phase 2 — Protected Files Inference + Adoption Modes

**Goal:** Seed the protected files table from git history + constrained LLM, and implement the
three adoption modes with scope-enforcement.

### Files modified
- `.claude/skills/init/SKILL.md` — protected files inference + mode-gate logic + all flag enforcement
  (all flag behavior lives here — `init.md` remains a pure router per existing architectural contract)
- `.claude/commands/init.md` — one-line flag reference only: "Supported flags: --full (default),
  --governance-only, --commands-only. See SKILL.md for behavior." No scope tables, no enforcement.

### Changes: protected files inference

Add a pre-Phase-2 analysis step in Retrofit Mode:

1. **Shallow-clone fallback:** check commit depth with `git rev-list --count HEAD`. If fewer than
   10 commits exist, skip the most-modified-files step entirely — shallow clones produce misleading
   churn signals. Label all protected file suggestions as `INFERRED (directory listing only)`.
2. Otherwise, run `git log --diff-stat --format="" | grep " | " | awk '{print $1}' | sort | uniq -c | sort -rn | head -20`
   to surface the 20 most-modified files (structural content only — no file body sent to LLM)
3. Present to LLM: top-level directory listing + most-modified file names
4. Ask LLM to classify each directory by semantic role: auth, data model, privacy-sensitive,
   hot path, migrations — or "no signal" if unclear
5. Label all output `INFERRED` — present as explicit draft:

```
Protected files — INFERRED draft (review carefully):

Tier 1 (ask before any change):
  - src/auth/           [INFERRED: auth — high git churn, directory name]
  - src/models/user.ts  [INFERRED: data model — most-modified file]

Tier 2 (explain why alternatives are insufficient):
  - src/api/search.ts   [INFERRED: hot path — highest churn]
  - migrations/         [INFERRED: migrations — directory name]

⚠️  This is a draft. Add any files you know are security-critical that are not listed.
    Remove any that are misclassified.
```

6. Do not write the protected files table to CLAUDE.md until developer explicitly confirms it

### Changes: adoption modes

**All flag logic lives in `SKILL.md` — `init.md` is a router only:**
- `/init` or `/init --full` → run all phases, populate all CLAUDE.md sections
- `/init --governance-only` → skip Commands table; skip Phase 3 (roadmap); skip README update;
  write only: protected files, quality requirements, privacy requirements
- `/init --commands-only` → populate only the Commands table in CLAUDE.md; skip protected files,
  roadmap, README changes

**Mode-scope enforcement table (added to SKILL.md):**

| CLAUDE.md section | `--full` | `--governance-only` | `--commands-only` |
|-------------------|----------|--------------------|--------------------|
| Commands table    | ✓ write  | ✗ skip             | ✓ write            |
| Protected files   | ✓ write  | ✓ write            | ✗ skip             |
| README update     | ✓ write  | ✗ skip             | ✗ skip             |
| MEMORY.md         | ✓ write  | ✓ write (partial)  | ✗ skip             |
| Roadmap           | ✓ write  | ✗ skip             | ✗ skip             |
| Settings.json     | ✓ write  | ✗ skip             | ✓ write            |

**Phase 5 gate updated:** Verification gate checks are mode-aware — missing Commands table does
not FAIL when mode is `--governance-only`.

### Completion signal
`/init --governance-only` on a Go project: skips Commands table and roadmap, writes inferred
protected files as draft, passes Phase 5 gate without flagging missing commands.
`/init --commands-only`: writes only Commands table and settings.json; all other sections untouched.

### Estimate
3–4 hours (protected files inference instructions + three mode gates + Phase 5 gate update)

---

## Phase 3 — Secret-Scan Guard

**Goal:** Ensure no file body content reaches LLM context without secret-pattern pre-screening.

### Files modified
- `.claude/skills/init/SKILL.md` — add secret-scan instruction block before any LLM file analysis

### Changes

**Pre-check instruction (fires before any file body enters LLM context):**

Before including any file body (not file names, not manifest keys) in LLM context during
codebase analysis, check each file for:

| Pattern | Example |
|---------|---------|
| AWS access key | `AKIA[0-9A-Z]{16}` |
| GitHub token | `ghp_[a-zA-Z0-9]{36}` or `github_pat_` |
| Generic secret indicators | Lines matching `SECRET=`, `TOKEN=`, `PASSWORD=`, `API_KEY=`, `PRIVATE_KEY` |
| High-entropy strings | Any 40+ character alphanumeric string on a single line |

**Behavior on match:**
- Exclude the file from LLM context entirely
- Add a warning to the confirmation screen showing **only the filename and match category** —
  never the matched string, matched line, or surrounding context:
  `⚠️  .env.example excluded from analysis — AWS key pattern detected. Review manually.`
- Do NOT log matched content, matched strings, or any characters from the matched line

**Default policy (added to SKILL.md):**
- Send only structural content to LLM by default: file names, manifest key names, directory
  listings, script command strings (not values)
- File body analysis (reading actual source) requires explicit user opt-in, which must be
  prompted before the analysis begins

### Completion signal
A codebase containing a file with `API_KEY=AKIA[fakevalue]` shows `⚠️ .env.example excluded`
in the confirmation screen. The file's content does not appear in any LLM context.

### Estimate
1–2 hours (pattern list + exclusion instruction + warning format + default policy statement)

---

## Simplicity Challenge

Could this be one phase? All changes are to two markdown skill files. The simplest approach
would be to write all three changes in one edit.

More phases are needed because:
1. Phase 1 (detection) provides standalone value and is the highest-churn section — wrong command
   inferences write directly to CLAUDE.md. Verifying detection in isolation before adding modes
   reduces defect surface.
2. Phase 3 (secret-scan) is a security control. A privacy reviewer must audit it as a discrete
   unit, not buried in an adoption-modes diff.
3. Adoption modes (Phase 2) depend on knowing which sections Phase 1 populates — logical ordering,
   not arbitrary splitting.

---

## Protected Files Check

No files in this plan are in the Protected Files list. CLAUDE.md's protected file placeholders
(`{{AUTH_FILE}}` etc.) have not been initialized — there are no guarded project files yet.

The skill files being modified (`.claude/skills/init/SKILL.md`, `.claude/commands/init.md`) are
template governance files, not listed as protected.
