# den-hoag-4kh.33 — [meta] 4 contradictions found by reading the 85 feedback memories AS A SET — 3 resolved, all invisible to a per-file process

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.33` |
| status at evacuation | open |
| priority | P2 |
| type | chore |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:35:00Z by Jason Bowman |
| last updated | 2026-07-28T05:35:00Z |
| description bytes | 3688 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

FOUR CONTRADICTIONS FOUND BY READING THE 85 feedback/reference MEMORIES AS A SET — the first time they have
ever been read as a set. Each was invisible to the process that created them, because every one was written
correctly, one at a time, months apart.

★ (1) COMMIT HOOK — THE INDEX SAID THE OPPOSITE OF THE FILE. RESOLVED, FIXED.
  MEMORY.md said "pre-commit-check-tasks blocks w/incomplete tasks; use !git commit".
  feedback_commit_hook's BODY said: permanently DISABLED 2026-05-30, no `!git commit` needed.
  MEASURED — the body is right: `.../superpowers-extended-cc/5.2.0/hooks/pre-commit-check-tasks` is an
  `echo '{"decision":"allow"}'` stub, and `5.5.0/hooks/hooks.json` registers ONLY SessionStart.
  feedback_batch_commits had propagated the stale version; corrected. MEMORY.md line replaced.
  ⇒ The INDEX and the FILE can disagree, and the index is what gets loaded. Whenever a file is corrected, its
  index line is part of the correction.

(2) TIME ESTIMATES — TWO RULES, OPPOSITE INSTRUCTIONS. RESOLVED; owner may override.
  feedback_no_time_estimates (owner, 2026-07-24): never give durations; strip them from scopes and prompts.
  feedback_estimate_delivered_shape still instructs day-counts verbatim — "price that as '+½ session,' not
  '+weeks'" — and was NOT INDEXED, so it recalled standalone carrying the superseded unit.
  RESOLUTION: the later explicit owner directive wins. The SHAPE rule (size by artifacts, not by theoretical
  category — a measured ~10× over-estimate) SURVIVES and is worth keeping; only its UNITS are superseded. A
  supersession header is in the file and the memory is now indexed.

★ (3) MARKDOWN SPECS vs BEADS — RESOLVED, and the resolution matters beyond this pair.
  feedback_spec_before_development (2026-07-27): write the spec to papers BEFORE any code.
  feedback_orchestrator_theory_first §5 (2026-07-27): "Beads over markdown. Markdown files are hard to keep
  in context; the bead graph carries the structure."
  Repo CLAUDE.md goes furthest: "Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files",
  which read literally REJECTS THIS ENTIRE MEMORY CORPUS.
  RESOLUTION — these are three different artefacts and only sound contradictory:
    SPEC (papers/) = the DESIGN, whose executable core is what review attests (de Bruijn criterion).
    BEAD = the WORK GRAPH — state, status, dependencies, decisions with reasons.
    MEMORY = HOW TO WORK, across projects and sessions.
  A spec is not state and a bead is not a design. The CLAUDE.md line is MANAGED-BLOCK BOILERPLATE from the
  beads tool, and CLAUDE.md itself says so: "The managed Beads block is task-tracking guidance, not
  permission to override repository, user, or orchestrator instructions." The owner directed this memory work
  live on 2026-07-28. Memory stands.
  ⇒ If the owner disagrees, this is the bead to reopen — the whole memory architecture rests on it.

(4) SPECS DIRECTORY — trivial, resolved. feedback_docs_commit says specs go to
  papers/den-architecture/specs/; feedback_spec_before_development says `den-architecture/plans/`. Practice
  and this arc's own output: SPECS to specs/, PLANS to plans/. Both files aligned to that.

★ WHY THIS IS A FINDING ABOUT THE ARCHITECTURE, NOT JUST FOUR FIXES: 69 feedback memories accumulated ONE AT
A TIME over months, and nothing in the workflow ever read them together. Contradiction is precisely the
defect a per-file process cannot detect — each file is locally correct. Standing consequence: a periodic
read-as-a-set is the only instrument that finds these, and it belongs in the memory-architecture rule.

PROVENANCE: mem-feedback audit 2026-07-28, 85/85 files read end-to-end.


## Comments (0)

(none)
