# Melange Framework Manifest

Current framework version: see `TEMPLATE_VERSION`

## Universal files

These files are owned by the framework and remain identical to their framework-repo
counterparts after `/init`. They are safe to overwrite when pulling in a framework
upgrade — they contain no project-specific content.

```
AGENTS.md
ETHOS.md
TEMPLATE.md
TEMPLATE_VERSION
.gitignore
.mcp.json
.claude/agents/performance-profiler.md
.claude/agents/planner.md
.claude/agents/researcher.md
.claude/agents/validator.md
.claude/commands/adr.md
.claude/commands/benchmark.md
.claude/commands/canary.md
.claude/commands/careful.md
.claude/commands/changelog.md
.claude/commands/configure.md
.claude/commands/context-restore.md
.claude/commands/context-save.md
.claude/commands/debug.md
.claude/commands/ideate.md
.claude/commands/init.md
.claude/commands/plan.md
.claude/commands/quality.md
.claude/commands/research.md
.claude/commands/retro.md
.claude/commands/review.md
.claude/commands/security.md
.claude/commands/ship.md
.claude/commands/test.md
.claude/hooks/check-careful.sh
.claude/hooks/inject_claude_md.sh
.claude/hooks/post-stop-reminder.sh
.claude/skills/adr-authoring/SKILL.md
.claude/skills/benchmark/SKILL.md
.claude/skills/canary/SKILL.md
.claude/skills/careful/SKILL.md
.claude/skills/changelog/SKILL.md
.claude/skills/configure/SKILL.md
.claude/skills/context-restore/SKILL.md
.claude/skills/context-save/SKILL.md
.claude/skills/debugging/SKILL.md
.claude/skills/deploy/SKILL.md
.claude/skills/dev-loop/SKILL.md
.claude/skills/ideation/SKILL.md
.claude/skills/init/SKILL.md
.claude/skills/planning/SKILL.md
.claude/skills/quality-check/SKILL.md
.claude/skills/research/SKILL.md
.claude/skills/retro/SKILL.md
.claude/skills/review/SKILL.md
.claude/skills/review/specialists/api-contract.md
.claude/skills/review/specialists/maintainability.md
.claude/skills/review/specialists/migration.md
.claude/skills/review/specialists/performance.md
.claude/skills/review/specialists/red-team.md
.claude/skills/review/specialists/security.md
.claude/skills/review/specialists/testing.md
.claude/skills/security/SKILL.md
.claude/skills/testing/SKILL.md
```

## Project files

These files are modified during `/init` and diverge from the framework immediately.
Do not overwrite them during a framework upgrade — merge changes manually.

```
CLAUDE.md
README.md
CHANGELOG.md
SETUP.md                          (deleted after init)
.claude/memory/MEMORY.md
.claude/settings.json
docs/planning/PROJECT_ROADMAP.md
docs/adr/
docs/security/
```

## Upgrading an initialized project

To pull in improvements from a newer framework version:

1. Identify the version your project was initialized from (`MEMORY.md` → Core Facts →
   `Framework version`)
2. Find the framework repo tag for that version and the target version
3. Run `git diff <old-tag>..<new-tag> -- <universal-file>` for each universal file you
   want to review
4. Apply changes to universal files — they contain no project-specific content, so a
   direct overwrite is safe
5. For project files (especially `CLAUDE.md`), review the diff and merge manually —
   your project-specific content must be preserved
6. Update `Framework version` in `MEMORY.md` to the new version
