# Melange Template ADRs

Architecture decisions made during the development of the Melange template itself. These
document WHY Melange is designed the way it is — they are NOT decisions belonging to any
project initialized from the template.

**These files are deleted from initialized projects during `/init`.**

If you are reading this in an initialized project, this directory should not be here.
Delete it and open an issue at the Melange repository.

## Index

| # | Title | Status | Date | Summary |
|---|-------|--------|------|---------|
| [0001](0001-discrete-adoption-modes.md) | Discrete Adoption Modes for Codebase Import | Accepted | 2026-04-30 | Three named flags (--full, --governance-only, --commands-only) over a continuous spectrum |
| [0002](0002-deterministic-first-codebase-analysis.md) | Deterministic-First Hybrid for Codebase Analysis | Accepted | 2026-04-30 | File-signature scanning as primary detector; LLM only for structurally ambiguous gaps |
| [0003](0003-secret-scan-opt-in-body-analysis.md) | Secret-Scan Guard and Opt-In File Body Analysis | Accepted | 2026-04-30 | Structural content only to LLM by default; file body requires opt-in + secret pre-scan |
