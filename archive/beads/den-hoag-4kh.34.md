# den-hoag-4kh.34 — [meta] dedup proposal for the feedback corpus: 4 true duplicates + 2 near-dup clusters — needs owner taste, deliberately NOT applied

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.34` |
| status at evacuation | open |
| priority | P3 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:35:23Z by Jason Bowman |
| last updated | 2026-07-28T05:35:23Z |
| description bytes | 3363 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

DEDUPLICATION PROPOSAL — needs OWNER TASTE, not measurement. Filed rather than applied, because deciding
which of two overlapping rules survives is a judgement about what the owner actually holds, and an agent
merging them silently would erase the distinction if it turns out to be real.

MEASURED by reading all 69 feedback memories end-to-end (the first read-as-a-set ever performed).

★ TRUE DUPLICATES — subsumption verified by reading both files in full. Recommend merge + delete.
  (a) feedback_agent_idle_reports (14 lines) is a STRICT SUBSET of feedback_agent_dispatch_discipline para 1.
      Same rule, same remedy ("ping once, do not re-dispatch"); dispatch_discipline additionally says "check
      the scratchpad first". Nothing is lost by deleting idle_reports.
  (b) feedback_no_coauthor + feedback_no_pr_byline — ONE rule (no AI attribution footer), two surfaces
      (commit trailer, PR body). Merge to feedback_no_ai_bylines; collapses two index lines to one.
  (c) feedback_delegate_spec_plan_authoring (14 lines) is fully subsumed by
      feedback_orchestrator_theory_first §1.
  (d) feedback_format_before_commit + feedback_format_cmd — format_cmd already carries the "when" as well as
      the per-repo "which". Cross-linked for now; merging is the cleaner end state.

NEAR-DUPLICATES — do NOT auto-merge. Each carries a distinct TRIGGER, and the trigger is the load-bearing
part of a feedback memory: the rule fires when you notice the trigger, so two rules with the same conclusion
and different triggers are two rules.
  - The six-file REJECT-YAGNI cluster: no_half_measures · no_deferral · architecture_first ·
    by_construction_over_repair · best_framework_first · improve_api.
    Distinct triggers genuinely exist — architecture_first fires at "3+ workarounds";
    by_construction_over_repair fires at "a construction exists where the defect cannot arise".
    BUT: improve_api is fully inside no_half_measures, and no_deferral/no_half_measures overlap on "fix debt
    as discovered, reject YAGNI" with the same owner-quote lineage.
    SUGGESTED: fold improve_api in; keep no_deferral ONLY if relabelled as the TEMPORAL/scheduling rule
    against no_half_measures as the DESIGN-QUALITY rule. If that distinction is not one the owner draws,
    they should be one file.
  - ORCHESTRATION cluster: orchestrator_theory_first · agent_dispatch_discipline · plan_then_subagent_pattern
    · review_dispatch_prompts · no_parallel_agents. "An auditor must not fix what it audits" and "a reviewer
    must not inherit the author's framing" EACH appear in two files.

RULES STATED WITHOUT A REASON — a feedback memory whose Why is a restatement degrades into a rule nobody can
apply to a NEW case, and gets re-litigated:
  - feedback_no_coauthor: "Why: Standing user preference across repositories." That is the rule again.
  - feedback_worktree_location: "Why: User preference for keeping worktrees colocated." Circular.
  - feedback_no_pr_byline: "User considers them noise" — thin, but at least a preference.
  If (b) above merges, ONE real reason would serve both.

★ NOT APPLIED. Deletion is irreversible here — ~/.claude/memory has NO git history. All 85 files are archived
verbatim at the feedback/reference archive bead, so any merge is recoverable, but the DECISION is the owner's.

PROVENANCE: mem-feedback audit 2026-07-28.


## Comments (0)

(none)
