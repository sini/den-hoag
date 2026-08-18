# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

## ★ Current arc (2026-08-05)

**GEN-FIRST consolidation; den-hoag is FROZEN** (ADR-0002 — breaking it is acceptable; its kernel/compat
work is parked and deferred out of `bd ready`). Boot from
`~/Documents/repos/sini/den-ag-design/STATUS/RESUME-PROMPT-ARCH.md`, not from `bd ready`: the ready list
serves the live gen arc only, and the law lives in `~/Documents/repos/sini/den-ag-design/specs/adr/`.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:1105d646 -->

## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

★ **THE BEADS WORKSPACE IS NOT IN THIS REPO.** It moved to `~/Documents/repos/sini/den-ag-design/.beads`
on 2026-08-18, beside the ADRs and specs it cites — this repository is frozen (ADR-0002) and the tracker
serves the live gen arc. `BEADS_DIR` is set globally, so `bd` works from any directory; pass `bd -C <path>`
when a command has already `cd`'d elsewhere. The issue prefix stays `den-hoag`: it names the PROJECT, not
this repository.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**

- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.

<!-- END BEADS INTEGRATION -->

## Working Mode — read this before acting

Standing owner directives. They outrank convenience, precedent, and effort estimates.

**The decision bar, every role:** decisions align against **proper theory**. NOT v1-compat convenience.
NEVER least effort. **Everything must be defensible as a theory-based expression.** A design justified by
"v1 did it this way" or "this is the smaller change" fails the bar regardless of whether it works.

**Spec before development — always.** Write the spec and file the bead *before* touching code, including for
one-line changes to a gen library, and including when a probe already proves the mechanism works. "Small and
measured green" is not an exemption; skipping this cost a public revert on `github:sini/gen-schema`.

### If you are the ORCHESTRATOR (driving the session)

- **Orchestrate, do not implement.** Run the work through independent **fresh-context** agents — scouts,
  research assistants, reviewers, authors. A reviewer that inherits the author's framing is not independent.
- **Beads must hold a graph of VALIDATED CORRECT work.** An unshipped finding does **not** become a bead — it
  becomes a review candidate, and enters the graph only after adversarial architecture-alignment review
  against pure-gen criteria **and** the academic result the design claims. Rejections are recorded *with their
  reason*; a rejected design that leaves no trace gets re-proposed.
- `arch-validated` is a **positive** label. Absence means not-yet-validated — labelling the unvalidated ones
  instead fails open, and silence must never read as success.
- **Bead bodies are self-contained.** Markdown does not survive compaction; the graph does. A task may
  explicitly request a **user-guided design spike** rather than resolving an owner-level question alone.

### If you are a SUBAGENT (dispatched for a specific task)

- Your dispatch prompt is your specification. Stay inside it.
- **Do not create or modify beads.** Findings return to the orchestrator for the review gate.
- **Do not fix what you are auditing.** An audit that edits as it goes cannot report what it found.
- Report coverage honestly. A partial result reported as partial is useful; reported as complete it is worse
  than nothing.
- An **absence** claim needs a positive control on the same predicate in the same run. Several false "clean"
  results in this project came from predicates that could not have matched.

### Architecture invariant — PARKED WITH THE FREEZE, not live

The den-hoag **kernel must be a pure graph representation** before the full backwards-compat layer
materializes. `ci/tests/boundary.nix` guards the kernel⟂compat line **lexically only** (token scan, import
direction, seam enumeration) — it cannot observe representation, so a v1-shaped state accumulator wearing
gen-native naming passes every guard.

★ **This audit is PARKED.** It belongs to the attempt-1 kernel track, frozen under ADR-0002 and deferred
out of `bd ready`; its carrier `den-hoag-4kh` is a pointer stub since the 2026-08-18 tracker evacuation,
with the record at `archive/beads/den-hoag-4kh.md`. Do not resume it. **The live arc is the gen-first
consolidation — `bd show den-hoag-pdlh`** (the phase map), entered through
`~/Documents/repos/sini/den-ag-design/STATUS/RESUME-PROMPT-ARCH.md`.

## Build & Test

_Add your build and test commands here_

```bash
# Example:
# npm install
# npm test
```

## Architecture Overview

_Add a brief overview of your project architecture_

## Conventions & Patterns

_Add your project-specific conventions here_
