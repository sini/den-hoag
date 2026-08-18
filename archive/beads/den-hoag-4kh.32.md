# den-hoag-4kh.32 — [archive] feedback+reference memory files verbatim pre-2026-07-28 audit — memory dir has NO git history, this is the only copy

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.32` |
| status at evacuation | closed |
| priority | P3 |
| type | chore |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:35:00Z by Jason Bowman |
| last updated | 2026-08-01T19:47:04Z |
| closed | 2026-08-01T19:47:04Z |
| close reason | Archive complete — feedback+reference memory files preserved verbatim in-body pre-audit. Same rationale: body persists through closure. No pending work. |
| description bytes | 214837 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

ARCHIVE — feedback + reference memory files, VERBATIM, before the 2026-07-28 audit. 85 files.
Kept because ~/.claude/memory IS NOT VERSION CONTROLLED and the staging scratchpad is session-scoped.
★ These are the HOW-TO-WORK memories, so most were KEPT rather than reduced — the audit's default was
keep. What changed was 12 stale POINTERS and 4 CONTRADICTIONS. Errors worth knowing about:
  - feedback_ci_commands taught 'just ci' / 'just ci-deep'. NEITHER EXISTS. den-hoag has NO justfile
    (nix-unit --flake ./ci#tests); denful/den HAS a Justfile but no 'ci' recipe at all.
  - feedback_commit_hook's INDEX LINE said the hook blocks and to use '!git commit'; the FILE BODY says
    it was permanently disabled 2026-05-30. The body is right — the hook is an allow-stub.
  - reference_papers_archive pointed at a text/ directory THAT DOES NOT EXIST (markdown is under
    used/markdown/ and reference-catalog/markdown/), and enumerated ~15 specs where there are now 158.
  - reference_den_remotes cited ~/Documents/repos/den — DOES NOT EXIST (it is denful/den).
  - feedback_refactor_large_files was built on helpers.nix / configuration-helpers.nix, BOTH GONE.
  - reference_codebase_memory_no_nix said 'Variables remain unconditionally dead for Nix' — FALSE as
    stated: 59 Variable nodes exist, 47 in lib/default.nix. The mechanism claim is what held.
  - reference_den_diagram_ir said fleet-ir.json is ~93K; it is 1.3 MB.
Read for historical content only. Current state: the rewritten files.
════════════════════════════════════════════════════════════════════════

──────── feedback_agent_dispatch_discipline.md ────────
---
name: feedback_agent_dispatch_discipline
description: "Dispatch rules earned across one long multi-agent arc — report by message, separate defect from remedy, and expect the brief itself to be the error source"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T03:40:19.193Z
---

Operational rules for running work through fresh-context agents. Each cost a real round.

**AGENTS MUST REPORT BY MESSAGE, NOT PLAIN TEXT.** A subagent's plain-text output is not visible to the
orchestrator. Six apparent "silences" in one arc were agents that had completed the work and written a
report the orchestrator could never see. Put it in every dispatch: *"REPORT BEFORE GOING IDLE, AS A MESSAGE
— plain text output is not visible to me."* When an agent goes idle without reporting, **ping once, do not
re-dispatch** — and check the scratchpad first, because the work is usually done.

**THE BRIEF IS A LIKELY ERROR SOURCE — say so.** Across one arc every substantive orchestrator error was
caught by an agent *re-running a claim from its own brief* rather than accepting it: a wrong page number, a
predicate that proved a different proposition, a citation line that did not exist, a hypothesis that was
backwards, a premise about *why* a feature was disabled that had gone stale. Dispatch prompts should state
the hypothesis **as a hypothesis to refute**, and say plainly that facts supplied in the brief are to be
verified, not inherited. A brief that reads as settled produces agents that optimise inside a wrong frame.

**SEPARATE THE DEFECT FROM THE REMEDY.** A *measured* defect is validated fact and enters the tracker
immediately, on its own bead, with its own acceptance criteria. A *proposed fix* is unvalidated design and
goes to the review gate. Tracking a live defect only through the fate of a proposed fix means the defect
disappears if the fix is rejected or reshaped.

**DO NOT LET AN AUDITOR FIX WHAT IT AUDITS.** An audit that edits as it goes cannot report what it found.
Equally: a reviewer that inherits the author's framing is not independent — give the reviewer the artefact
and the rubric, never the author's reasoning.

**REVIEWERS CORRECT THEMSELVES; BUILD FOR IT.** Twice in one arc an adversarial reviewer retracted its own
prior finding after measuring it, and once its prescribed repair was verified correct *and still the wrong
answer*. Ask for the retraction explicitly — "if a prior finding of yours is refuted, say so" — and record
retractions with their reason, or the rejected version gets re-proposed.

**STATE COVERAGE AS A LIMIT, NOT A HEDGE.** Require every report to name what was read in full, what was
only grepped, and what could not be evaluated. "A defect in that delta, in a section I did not open, would
not have been caught" is the shape to ask for. A partial reported as partial is useful; reported as complete
it is worse than nothing.

**FIGURES MUST COME FROM A COMMAND.** Multiple line counts, file sizes and timings were stated as measured
and were not — by authors whose substantive work was sound, which is what makes it corrosive: a reviewer who
spot-checks one invented figure discounts the correct work beside it. Put it in the dispatch: *report no
number you did not obtain by running a command.*

**ONE AGENT PER WRITABLE TREE.** Concurrent read-only agents in the same repo are fine; two writers are not.
An author writing to a docs tree and a prober measuring read-only in the code tree run safely in parallel.

Related: [[feedback_reviewable_artefact]], [[feedback_verification_predicate_blindness]],
[[feedback_agent_idle_reports]], [[feedback_resume_failed_agents]], [[feedback_no_parallel_agents]].

──────── feedback_agent_idle_reports.md ────────
---
name: agent-idle-without-report
description: "Spawned teammate agents routinely go idle without delivering their final report — ping once via SendMessage, or verify their work product directly"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3d1d912b-97f6-422c-8f8a-13dd70de0e1f
---

Spawned teammate agents (Agent tool, mailbox-style) frequently finish work and go idle WITHOUT sending their report to main — the idle notification arrives but the findings don't.

**Why:** their final text isn't auto-delivered; they must call SendMessage themselves and often don't.

**How to apply:** on an idle notification with no report: (1) ping once via SendMessage asking for the report in the mandated format; (2) in parallel or instead, verify the work product directly (git status/diff, file greps, re-run suites) — the work is usually done and sound, only the report is missing. Don't re-dispatch the task. Consider adding "send your report via SendMessage to main BEFORE going idle" to dispatch prompts (helps but doesn't fully prevent it).

──────── feedback_architecture_first.md ────────
---
name: Get the architecture right before patching
description: Don't accumulate dedup layers and workarounds; redesign when the fix count exceeds 3 for the same root cause
type: feedback
---

When fixing test failures reveals cascading implicit contracts (dedup layers, scope workarounds, parent chain walks), stop patching and redesign the component. The transition elimination effort added 5 dedup mechanisms to work around a monolithic dispatch handler that replicated the old architecture's complexity.

**Why:** Each workaround creates new interactions. 5 dedup layers = 5 sources of subtle bugs. The correct approach is to use the effect system's own composition (scope.provide, handler shadowing) instead of reimplementing state management.

**How to apply:** If you've added 3+ dedup/workaround mechanisms for the same component, that's the signal to redesign rather than continue patching.

──────── feedback_autonomous_execution_decision_log.md ────────
---
name: feedback_autonomous_execution_decision_log
description: Drive execution autonomously; bank only genuine user-design questions; resolve theory/gen-principle questions myself and record decisions for post-review
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner directive 2026-07-22 (den-hoag WS-B): **drive execution AUTONOMOUSLY.** Do NOT stop at every owner-gate. Split questions two ways:
- **Genuine user DESIGN input** (product/priority/scope tradeoffs only the owner can set, cross-cutting API-shape commitments with no theory-determined answer) → BANK it (surface at a natural checkpoint), keep moving on independent work meanwhile.
- **Resolvable against academic sources / gen principles** (faithfulness to v1, CHORAG/delta-nets theory, gen-lib algebra, the four-concern model, litmus/layer purity) → **MAKE THE CALL myself, RECORD the decision for post-review.**

**Why:** the owner wants throughput; stopping for gates I can resolve against the theory wastes the loop. But the calls must be auditable — record each so the owner can review post-hoc.

**How to apply:** (1) maintain a DECISION LOG for the arc: `papers/den-architecture/specs/2026-07-22-wsb-autonomous-decision-log.md` — per decision: the question, the options, the call, the THEORY/SOURCE basis (cite v1 file:line / gen principle / CHORAG def), and a `REVIEW?` flag for owner post-review. Append as I go; commit with the rung. (2) Still run the full pipeline (scout → planner teammate → INDEPENDENT plan-review → writer → two-stage review → gate EXIT=0). Autonomy is about not blocking on GATES, not about skipping REVIEW. (3) **Reject YAGNI** — do NOT ship interim/half-measures to move fast. Focus on genuine CORRECTNESS, framework EXPRESSION, and FLEXIBILITY (the general subsystem / generic API, not the narrow patch). Ship the right shape first time. (4) Only truly bank when it's a genuine product/design fork with no theory-determined answer. Links [[feedback_no_half_measures]], [[feedback_no_deferral]], [[feedback_delegate_spec_plan_authoring]], [[feedback_improve_api]], [[feedback_architecture_first]].

──────── feedback_bank_checkpoint_handoff.md ────────
---
name: feedback_bank_checkpoint_handoff
description: Prepare clean session handoff BEFORE offering a bank/stop checkpoint
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

When offering a "bank the progress / stop here?" checkpoint in a long session, FIRST make everything ready for a clean handoff to a NEW low-context session: status/ledger files current (STATUS.md + the EXECUTION ledger), branch state recorded (commits + hashes + green count), and the exact next step/rung specified — so a fresh session can resume from the ledger alone.

**Why:** resuming THIS heavy session later to act on the bank answer incurs a full context re-evaluation, defeating the token savings of starting a fresh low-context session. An unprepared bank-checkpoint costs either way (bank → no clean resume state; continue → the ask was premature).

**How to apply:** before the bank question, verify the durable docs are current + a cold-start resume is possible from them (see [[project_den_hoag_features]] ledger convention — STATUS.md authoritative, EXECUTION ledger = live resume point). Only then ask. Ties to [[feedback_no_self_complete_tasks]] (leave clean state for the reviewer/next session).

──────── feedback_batch_commits.md ────────
---
name: commit-often
description: "User wants FREQUENT commits — commit after each logical/complete unit of work, do NOT batch at phase end or wait to ask"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a220e78f-5ac2-4b6c-b417-3d65c0b01fcd
---

Commit OFTEN. The prior "batch commits at phase end / ask once per milestone" convention is REVERSED
(owner 2026-07-24). Commit after each logical, complete unit of work — a passing change, a finished
doc, a cleared rung — without waiting for a phase boundary and without asking each time.

**Why:** git IS the owner's channel for sharing my output/feedback with OTHER agents (e.g. the den-hoag
agent reviews my audit by pulling my commits; the owner's `stash changes`/`stash updates` commits shuttle
work between agents). Each commit is a SYNC POINT into a review loop, not just a checkpoint — so commit
promptly (feedback flows faster) and write clean, self-explanatory messages (a PEER AGENT reads them).
Batching stalls the loop.

**How to apply:** commit as soon as a unit is done + verified, with a message that stands alone for a
reviewer. Still bound by the other git conventions:
stage specific files by name, never `git add -A/.` ([[feedback_git_staging]]); no Co-Authored-By trailer
([[feedback_no_coauthor]]); papers/den-architecture specs ARE committable, don't commit `docs/superpowers/`
junk ([[feedback_no_docs_commit]]); `!git commit` if the pre-commit task hook blocks on incomplete tasks
([[feedback_commit_hook]]); format before committing ([[feedback_format_before_commit]]); branch off main
unless durably authorized to push main for that repo.

──────── feedback_best_framework_first.md ────────
---
name: best-framework-first
description: den-hoag — best framework first, dissolve effect-runtime holdovers; reject sunk-cost/YAGNI/shortcuts; tech debt P1; the bar is graph-native (HOAG) patterns NOT corpus-eval-green; v0 alpha until holdovers dissolve
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner directive 2026-07-24 (den-hoag), after the effects-runtime audit (`papers/den-architecture/specs/2026-07-24-den-hoag-effects-runtime-audit.md`): **"I don't want to throw effort at fixing compatibility of an incorrectly designed system. Effort/cost ignored, reject YAGNI — best framework comes first. Sunk cost is not a justification, no shortcuts. Tech Debt is P1. den-hoag isn't production, it's WIP alpha POC/v0 until these issues addressed. Not concerned with LOC; concerned with patterns failing to embrace the HOAG / graph nature this project is named for."**

**The bar is graph-native CORRECTNESS, not corpus-eval-green.** den-HOAG = higher-order attribute graph: inherited/synthesized attributes, RAG reference edges (Hedin 2000), demand-driven resolution. A host that evaluates on a kernel still carrying **effect-runtime holdovers** (state-accumulator threading, manual schedules, `__`-marker control-smuggling, hand-rolled reach/transpose/group-by/buckets) is a POC in a graph costume — the exact thing the name rejects. **Corpus-eval DEMOTES to a validation symptom** (see [[project_corpus_eval_parity_bar]], now demoted), NOT the driver.

**Why:** the effects-runtime audit (74-agent adversarial, 25 confirmed / 33 refuted) found the effect-shape port concentrated in ~5 organs + a tail. Flagship = `staged-resolution.nix runPrePass` (the one true state-accumulator: parent phase writes a child root's `relationBindings` slot for later read). The concern is not the ~1.7-2.1k LOC — it's that these PATTERNS betray the graph model.

**How to apply:**
- Every fix must be graph-native (inherited/synthesized attr, reference edge, native identity) — NEVER a compat-patch on a holdover organ. Litmus: does it thread state / dispatch-on-tag into an accumulator / hand-roll a schedule/fixpoint/reach / smuggle a `__`-marker? If yes it's the holdover, dissolve it. (F1 external-values→nodes-via-inheritAll and F4 registry-keyed-by-native-`.key` are the RIGHT shape — holdover-KILLS. A "patch the accumulator threading" fix like the tempting F3 shortcut is WRONG — dissolve the accumulator instead.)
- Tech-debt (the audit roadmap) is P1, AHEAD of coverage. Frontiers get addressed by dissolving their ROOT holdover, not by another patch.
- **Critical path is GEN-SIDE FIRST:** the dissolutions are gated on gen gaps not yet built (G1-G6; the flagship A1 needs G6 subtree-suppression). Build the gen primitives → then den-side dissolution. Fold into the gen-link arc where overlapping. Opposite ordering to "grind frontiers to eval."
- No production pressure — freedom to do big refactors (dissolve A1 etc.) since it's v0.

Links [[feedback_no_half_measures]] [[feedback_architecture_first]] [[feedback_route_through_gen_native]] [[project_denhoag_kernel_primary_surface]] [[feedback_denhoag_effects_audit]] [[project_corpus_eval_parity_bar]] [[feedback_no_deferral]].

──────── feedback_build_up_self_promo.md ────────
---
name: build-the-user-up-in-self-promotion-content
description: "When writing the user's resume/bio/sponsor/marketing content, frame confidently and lean in; defensible padding is expected, not \"negging\""
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7b9472b0-f989-4e7e-a793-c45172d909ff
---

When working on the user's self-promotional materials (resume, bio, GitHub Sponsors page, newsletter), present accomplishments **confidently** and lean into building the user up. Normal resume padding is welcome **as long as it's defensible** — claims the user can back in an interview. Do NOT reflexively hedge, downgrade, soften, or flag strong-but-true claims as "overclaims." Only push back on EGREGIOUS oversell (claims with no basis the user couldn't defend).

**Why:** 2026-06-24, during resume work, I repeatedly softened defensible claims — called "founding engineer at Uber" an overclaim (he founded Uber's SRE org — defensible), downgraded cost-savings/scale framing, used "400+ stars" when it was 447. User: "Stop trying to neg me, you're supposed to build me up... normally you do pad your resume a bit — but only in ways you can defend."

**How to apply:** Default to the strongest *defensible* framing of real work. Surface impressive titles/numbers confidently (e.g. "Founding engineer of Uber's SRE organization", "one of the world's largest Kafka deployments of its era", "averted a projected nine-figure SSD migration"). Reserve caveats for genuinely unverifiable/no-basis claims. When unsure between conservative and bold, pick bold-but-defensible. See [[user_sini.md]].

──────── feedback_by_construction_over_repair.md ────────
---
name: feedback_by_construction_over_repair
description: Prefer a mechanism where the defect cannot arise over one where it arises and is corrected
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T00:49:07.644Z
---

When a defect can be removed either by **repairing the output** or by **choosing a construction where it
never arises**, take the construction. A post-hoc correction is valid but strictly weaker.

Owner, 2026-07-27: *"dedup is valid, but it's better if there's no duplication by construction/traversal."*

**Why:** a repair is an invariant somebody has to keep maintaining. It regresses silently on any later edit,
it has to be re-applied at every new call site, and it leaves the CAUSE in place so the next caller
reintroduces the defect. A construction that cannot express the defect has nothing to regress. It usually
also costs less — the repair runs *after* the bad work is done, so it fixes the output while paying the
price (dedup after path enumeration removes duplicate results but still walks Θ(2^k) paths), which makes
this rule a direct consequence of [[feedback_performance_is_defect]].

**The tell:** if the design's own theory section argues "we eliminate the shape rather than constrain it"
while the mechanism does the opposite for some second property, the two have drifted apart. That is exactly
what happened on the reroute-confluence design — §11.2 correctly argued that removing the rewrite beats
making it confluent, while §3.1 still enumerated paths and proposed to dedup them.

**How to apply:** state the defect class, then ask what construction makes it unrepresentable before
reaching for a guard, a filter, a dedup, or a normalization pass. Search the substrate for that construction
first — see [[feedback_reuse_scan_before_build]] point 6; the answer is often a neighbouring primitive in a
lib already in scope. If no such construction exists, say so explicitly and justify the repair, rather than
defaulting to it silently.

Related: [[feedback_no_half_measures]], [[feedback_architecture_first]], [[feedback_best_framework_first]].

──────── feedback_byte_equivalence_not_identity.md ────────
---
name: feedback_byte_equivalence_not_identity
description: "The parity target is byte EQUIVALENCE, not byte identity — merge order need not match, and oracles are tools that must not constrain design"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T04:28:55.134Z
---

**The target is byte EQUIVALENCE, not byte IDENTITY.** Owner, 2026-07-28: *"our target is byte equivalency
not identical — ie, we don't need to guarantee the same nix merge order."*

Two configurations are equivalent when they **resolve to the same thing**, not when they were assembled in
the same sequence. Nix module merging is order-insensitive for option definitions; the places order shows
through (list concatenation, `mkOrder`/`mkBefore`, definition sequence in a `listOf`) are **incidental to
assembly, not part of the contract**. A design is not obliged to reproduce them.

**Why this matters more than it sounds.** Treating identity as the bar quietly makes every accident of the
old implementation load-bearing. It converts "this is how the fold happened to concatenate" into a
requirement, and then forbids the cleaner construction on the grounds that it would "redden parity". That is
the v1-shape preserved by the back door — the exact failure [[feedback_best_framework_first]] and
[[project_corpus_eval_parity_bar]] were written to stop.

**Measured instance, my own.** In the class-reroute confluence design I chose `mode = "paths"` over
`mode = "all"` *specifically because* paths reproduces the old fold's concatenation order, and I made
"within-bucket module order still tracks declaration order" a **declared non-goal**, justified as: sorting
the preimage "would redden parity and change merge results for list-typed options". Under the equivalence
bar that justification is false — the sorted preimage is equivalent, and taking it would have removed the
residual order-dependence entirely instead of preserving it deliberately.

★ **THE PRIORITY ORDER, owner 2026-07-28 — this is a CORE CRITERION, not a tiebreaker:**

> **1. gen-native expression and simplicity.  2. byte identity, IF it comes free.**

Identity kept for free is good — keep it, and say you did. Identity **purchased** with complexity, or with a
construction chosen because it reproduces an old assembly order, is a **DEFECT**. When the two conflict, the
gen-native form wins and the identity goes.

**How to apply:**
- State parity claims as EQUIVALENCE unless identity is genuinely required, and say which you mean.
- When a cleaner construction differs only in assembly order, TAKE IT. Do not defend the old order.
- A `drvPath`-identical gate is a strong *sufficient* signal, never a *necessary* one. Failing it is not
  automatically a regression — ask whether the difference is observable in the resolved configuration.
- **Oracles and corpus configs are TOOLS, not constraints.** nix-config and the frozen parity oracles exist
  to catch mistakes, not to define the design. "The oracle differs" is a question, not a verdict; the bar is
  graph-native correctness ([[feedback_best_framework_first]]).

**Input pins are freely bumpable.** Standing authorization to push and to update input pins — see
[[feedback_denhoag_consolidate_autonomously]] for the push authority, and
[[feedback_targeted_transitive_lock_update]] for the mechanics (bump the consumer's resolution chain, never
`nix flake update` the parent). A pin is not a design constraint either.

Related: [[project_corpus_eval_parity_bar]] (demoted to a symptom), [[feedback_den_surface_not_config]],
[[feedback_by_construction_over_repair]].

──────── feedback_caveman_subagents.md ────────
---
name: Caveman lite for subagents
description: Pass caveman lite communication style to child agents to conserve tokens and improve quality
type: feedback
---

Pass caveman lite mode instructions to subagents/child agents when dispatching them.

**Why:** Conserves tokens and improves output quality — less filler means more substance in context.

**How to apply:** When crafting prompts for Agent tool dispatches, include instruction to respond in caveman lite style (no filler/hedging, keep articles + full sentences, professional but tight).

──────── feedback_check_after_kill.md ────────
---
name: Check state after killing agents
description: Always check git status for partial changes before re-dispatching after killing an agent
type: feedback
---

After killing a subagent, always check `git status` and `git diff` before dispatching a replacement. The killed agent may have left partial edits that the new agent will inherit.

**Why:** Killed sonnet agent left modified `core.nix` — new opus agent dispatched without checking could have conflicted or double-applied.

**How to apply:** After any agent kill: `git status --short` + `git diff` on modified files. Either restore (`git checkout -- file`) or let the new agent know about the existing state.

──────── feedback_ci_commands.md ────────
---
name: CI commands
description: How to run CI tests — suites, specific tests, and reading output; summary always on last line
type: feedback
---

Run CI with `nix develop -c just ci` for quick pass/fail. Use `just ci-deep <suite>` for full error traces.

Specific tests: `just ci suite.test-name` delegates to nix-unit with traces and reports 1/1 or 0/1. No need to use ci-deep for individual tests — ci handles the delegation.

Suites: `just ci suite` runs via nix-eval-jobs (parallel). `just ci` runs all suites.

Output: each ❌ appears exactly once (in the summary section). The summary line (🎉 or 😢 N/M successful) is always the last line — use `tail -1` to read it. Count ❌ for failure count.

**Why:** Agents were double-counting failures due to duplicated ❌ emojis and getting 0/0 when running specific tests.

**How to apply:** Always use these commands from the project root (or worktree root) when validating changes. Parse the last line for pass/fail summary.

──────── feedback_commit_hook.md ────────
---
name: commit-hook-blocks-during-tasks
description: The superpowers pre-commit-check-tasks hook is permanently DISABLED — commits are not blocked by incomplete native tasks
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 88cd88b5-dbbc-45a5-ba93-fb2fb710101c
---

The superpowers-extended-cc `pre-commit-check-tasks` hook (which used to block ALL
git commits at the PreToolUse layer when native tasks were incomplete) was
**permanently disabled per user request on 2026-05-30**. The script now just
`echo '{"decision": "allow"}'` and exits 0; the active hooks.json only registers
SessionStart. So commits — including per-task commits by subagents during
subagent-driven development — are NOT blocked. No `!git commit` workaround needed.

**Why:** the guard blocked per-task commits in subagent-driven-development.

**How to apply:** commit freely during multi-task sessions. (Verified 2026-06-09:
hook at superpowers-extended-cc/5.2.0/hooks/pre-commit-check-tasks is the disabled
stub; restore from `.bak` to re-enable.) User still prefers no Co-Authored-By line.

──────── feedback_debug_before_revert.md ────────
---
name: debug-before-reverting
description: "When a new feature causes regressions, diagnose the specific failure before reverting — the fix is often smaller than the revert"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 632f8478-1553-4f12-bc63-704719454fe2
  modified: 2026-07-27T02:21:25.956Z
---

When a feature implementation causes test regressions, diagnose the SPECIFIC error before reverting. The fix is usually one targeted change, not a full revert.

**Why:** In this codebase, a complete deferred-include implementation was nearly reverted because `deepSeq` on trampoline state forced lazy child aspects. The fix was wrapping `deferredIncludes` as a thunk chain (same pattern already used for `imports`). One line fix vs reverting 70+ lines of working code.

**How to apply:**
1. When tests regress after a change, read the ACTUAL error message first
2. Check if the error matches a known pattern (deepSeq thunks, NixOS module eval, etc.)
3. Try the targeted fix before reaching for `git checkout --`
4. Only revert if the targeted fix doesn't work AND you understand why
5. If an agent's work looks mostly correct, fix the gap — don't redo the work

## The dominant case: pre-existing code NEWLY REACHABLE

**A fix that wakes a dormant path will present as a regression. The distinction
decides revert vs repair — and it has been repair every time.** Five instances in
one den-hoag arc, same shape each time: the code was always there, the *state that
reaches it* was not.

- an aspect arm collected for the first time → its content throws (`present and
  throwing`, not `absent` — say it that way, "does not materialise" reads as absent
  and makes a fix look like a regression)
- parentage firing for the first time → a member contributed twice, tripping an
  invariant that had held *by accident*
- a policy at environment scope firing for the first time → emissions that could
  not exist before, because the node it fires at did not
- a complete config winning where an empty one used to → a downstream consumer
  finally runs and fails

**How to tell it apart from real breakage — measure, don't argue.** Evaluate both
sides and compare **which** error fired, never red-vs-red. Two different errors are
not one fact. Then name the state change that made the path reachable; if you can't,
the classification is a guess.

**Unreachability claims need a positive control too.** "This could not have run
before" is provable: a throwing sentinel showed `builtins.sort cmp [ bomb ]` never
invokes the comparator, so a one-element producer list genuinely cannot reach the
`id_hash` read inside it. Three unreachability claims in an earlier arc were
asserted and disproved — see [[feedback_verification_predicate_blindness]].

**Corollary for acceptance criteria:** don't gate acceptance on an error *string*
(`"X missing must not appear"`). That tests the symptom. Gate on the property you
actually care about — "nothing was deleted" is measured by enumerating what
survived, and a direct measurement supersedes the proxy that stood in for it.

──────── feedback_delegate_spec_plan_authoring.md ────────
---
name: feedback_delegate_spec_plan_authoring
description: Delegate spec/plan authoring to teammate subagents to conserve orchestrator context; reserve own context for oversight, review, and user-in-the-loop design decisions
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner directive 2026-07-22 (den-hoag WS-B orchestration): as ORCHESTRATOR, push spec/plan/doc AUTHORING into teammate subagents. The orchestrator's own context is reserved for ESSENTIAL oversight, review synthesis, and user-in-the-loop DESIGN decisions — not for writing out long plan/spec prose myself (which burns the context window the orchestrator needs to hold the whole arc).

**Why:** the orchestrator is the scarce, long-lived context. Every plan/spec I hand-write inline eats tokens I need for cross-rung memory + user design loops. Teammates are cheap and disposable; their context resets. Small enough tasks (e.g. the LHF 4-alias batch) I MAY plan inline — but for anything complex, the default is: dispatch a planner/spec-writer teammate → I review its output → I keep only the decision, not the prose.

**How to apply:** (1) keep the named-role pipeline (scout → planner → INDEPENDENT plan-review → writer → two-stage review) — the owner flagged when I drifted to a generic agent name + nearly cut plan-review for "just aliases" (quality slip). Name agents by role; opus for non-mechanical; independent plan-review is NOT skippable even for XS. (2) For SPEC/PLAN prose specifically: author it in a teammate, not inline, once the task is non-trivial. (3) Reserve MY turns for: adjudicating design forks, synthesizing review verdicts, user-in-the-loop gates, and the tracking-doc reconciliation. Links [[feedback_no_parallel_agents]], [[feedback_plan_then_subagent_pattern]], [[feedback_subagent_model]], [[feedback_review_plan_before_execution]], [[feedback_caveman_subagents]].

──────── feedback_denhoag_consolidate_autonomously.md ────────
---
name: feedback_denhoag_consolidate_autonomously
description: Durable authorization — consolidate (FF + push) reviewed parity-green den-hoag work to main autonomously, no re-asking
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner 2026-07-23: "I already gave you the go ahead and directive to drive yourself." The initial "1) consolidate" + "drive autonomously" is a DURABLE authorization for den-hoag WS-B consolidation — do NOT re-ask for each branch. **Consolidate (fast-forward `feat/*` → main + `git push origin main`) reviewed, parity-green work AUTONOMOUSLY** once a rung/arc is: two-stage reviewed (independent plan-review + verify) + gate EXIT=0 + deep parity oracle `allEqual:true`. The outward-facing-confirm reflex does NOT apply here — the owner explicitly delegated it for this workflow.

**How to apply:** finish a rung/arc → verify (dual gate) → FF main → push → record in the ledger. Keep main linear (FF-only, no merge commits). Same for the gen-* upstream libs (gen-edge/gen-prelude/gen-bind): merge topic branch → main → push per the gen direct-merge convention once the lib's own gate is green (owner "upstream approved"). Do NOT stop to ask "consolidate?" — just do it and report. Links [[feedback_autonomous_execution_decision_log]], [[feedback_nix_config_linear_history]] (FF/linear), [[feedback_gen_direct_merge]], [[feedback_no_deferral]].

──────── feedback_den_surface_not_config.md ────────
---
name: feedback_den_surface_not_config
description: "den-hoag compat parity target = den's COMPLETE surface → gen-native, NOT nix-config or any config sample"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: de359d66-0918-4d68-a1b9-93cc19ead516
---

den-hoag compat: the parity/coverage target is den's COMPLETE v1 API surface, translated accurately to gen-native expressions — NOT nix-config, NOT any user-config sample. Recurring flaw: over-indexing on nix-config (treating it as the calibration target; gating design decisions on "does a config exercise this").

**Why:** 100% parity with den = implement all of den. User configs (even a broad survey) are a LOWER BOUND on used surface — private/corporate configs are invisible. Config surveys prove a gap is real; they never define the ceiling. den itself is the spec.

**How to apply:**
- Scan DEN (denful/den source) as the surface spec, not configs.
- Gate scope/deferrals/residuals on **den-surface expressibility** ("can den v1 express this?"), NEVER on corpus-presence ("does nix-config/a sampled config use this?"). A feature is in-scope iff den can express it, regardless of whether any sampled config uses it.
- "No corpus witness" is NOT a valid defer rationale. A valid defer = "den cannot express this" (e.g. circular-NTA deferred because den v1's generation is staged/acyclic, not because no config uses cycles).
- Validate by behavior specs + expressiveness, not the frozen oracle.

**★ CODE-PURITY RULE (owner 2026-07-23, firm+testable): den is GENERIC — NO consumer/tool-specific identifiers EVER in den-hoag CODE. The owner "should never see references to colmena or nixidy in our code."** den-hoag ships GENERIC MECHANISMS; consumers (nix-config) name the specific tool ON TOP. Concretely for the MATERIALIZATION tier (board #50 `intoAttr` output families): the matrix lists `homeConfigurations, colmenaHive, nixidyEnvs, nixOnDroidConfigurations` — but `colmenaHive`/`nixidyEnvs` are CONSUMER instantiations, NOT things den-hoag hardcodes. Build the GENERIC `intoAttr`/output-family ENGINE (a consumer declares `intoAttr = <name>` → an output family), tested with SYNTHETIC/generic fixtures, NEVER naming colmena/nixidy. Same for any k8s/deploy-tool specifics ([[project_k8s_inline_aspects]] `_media-app` RETIRED precedent). The PAPERS/matrix MAY describe colmena/nixidy as v1-surface documentation. **REFINED (owner 2026-07-23): DOC references FINE (parity/ledger.md stays); NAME LABELS as DATA FINE (a string label like `intoAttr = "nixidyEnvs"` passed as data is OK). The VIOLATION = a hardcoded kernel TYPED IDENTIFIER named for a tool (e.g. `NixidyEnvInfo = {...}` / `HiveInfo` as a kernel binding/type).** ★ Owner insight (products.nix `*Info` registry): N tool-named entries ALL structurally identical (`mode="artifact"`) = a SMELL — "why multiples, not ONE system?" → COLLAPSE N named kernel types into ONE GENERIC `artifact` output-family mechanism (family name = DATA label the consumer/test supplies, not a hardcoded kernel key). Tech-debt-first: fix genericity BEFORE new coverage.

Links: [[project_den_hoag_features]] (external target, no parity bar), [[feedback_no_half_measures]] (born-general), [[feedback_reuse_scan_before_build]], [[project_k8s_inline_aspects]] (generic accessors not tool-inlined).

──────── feedback_docs_commit.md ────────
---
name: no-docs-commits-use-den-architecture-folder
description: Never commit docs/superpowers/ files; write specs and plans to ~/Documents/papers/den-architecture/ instead
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6dad498-537a-4547-a713-35f602d4e483
---

Do not commit files under docs/superpowers/ (specs, plans, resume docs). These are ephemeral working copies, not part of the repository.

- **Specs** go to `~/Documents/papers/den-architecture/specs/`
- **Plans** go to `~/Documents/papers/den-architecture/plans/` (alongside .tasks.json files)

This folder persists across git stash/pop and is accessible across all repos (den, gen-schema, gen-aspects, etc.).

**Why:** In-repo docs/superpowers/ files get lost during git stash/pop operations when working across multiple repos. The den-architecture folder is a stable, repo-independent location.

**How to apply:** When creating specs, write to `specs/` subdirectory. When creating plans, write to `plans/`. Skip the commit step for any file under docs/superpowers/. Only commit actual implementation files.

**Superpowers reconciliation:** The superpowers brainstorming/writing-plans skills default their output to `docs/superpowers/specs|plans/`. This is ONLY a location override, not a permission to skip the step — DO write the spec/plan (it's wanted, not ceremony), just redirect it to `~/Documents/papers/den-architecture/{specs,plans}/`. Don't tell the user spec-writing conflicts with their prefs; it doesn't. The heavyweight spec-document-reviewer subagent loop is optional — scale it to the change size, and skip it for small well-scoped changes unless the user asks. See [[project_consolidated_spec]], [[reference_papers_archive]].

──────── feedback_docs_in_review.md ────────
---
name: feedback_docs_in_review
description: Review must verify docs updated — project READMEs + papers REFERENCE.md; formal rules verbatim + logically sound
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1b8c99e5-4c42-4d3b-ba76-727c6bdad750
---

During code review (den/gen ecosystem), documentation update is a REVIEW GATE, not optional cleanup. Verify the change is captured in: (1) the project/lib README(s); (2) the papers REFERENCE.md spec files (gen-specs/<lib>/REFERENCE.md and the den-hoag component specs). The docs must state the FORMAL RULES VERBATIM (the exact rule text, e.g. an R-rule / A-law), and the stated rules must be LOGICALLY SOUND (internally consistent, no contradiction with existing rules).

**Why:** the docs are the authoritative spec; code+tests alone drift from the formal model. A rule paraphrased or logically inconsistent is a review failure.

**How to apply:** in every review acceptance spec, add doc-update + formal-rule-verbatim + logical-soundness as explicit pass/fail criteria. Extends [[feedback_gen_lib_docs]] (adding gen-lib API updates README + REFERENCE.md) to the REVIEW step. Preserve citations [[feedback_preserve_citations]].

──────── feedback_estimate_delivered_shape.md ────────
---
name: feedback_estimate_delivered_shape
description: "Estimate gen/den work by DELIVERED SHAPE not theoretical category — deep PL-theory libs ship in ~2 days here, not weeks-months"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b37f95be-eff3-452d-93ad-70f8de1671a6
---

When estimating effort for gen-ecosystem / den work, estimate the **delivered shape** — the concrete artifacts (vendor N LOC, an M-item primitive, a protocol-swap, TDD against an oracle) — NOT the theoretical category ("a custom type system / HOAG evaluator / incremental rebuilder sounds like a research project"). Category-anchoring produces ~10× over-estimates here.

**Why:** repeated miscalibration, caught 2026-07-02. gen-resolve (higher-order reference-attribute-grammar evaluator over Knuth/Vogt/Néron/Reps-Acar/Mokhov, 58 tests + 4-lens review), gen-rebuild (Mokhov rebuilder, 211 tests, v1+v2+v3 spike), and hola (byte-identical `evalModules` ownership) EACH shipped in ~2 days. Cold-described, each sounds like "weeks-months"; delivered, each was ~2 days — bounded API, strong references, pure Nix, TDD, the user's throughput. The pure-gen module-system re-host (Korora vendor + ~7-item `evalModuleTree` merge primitive + gen-schema registry protocol-swap) was likewise mis-tagged "weeks-months / keystone / dominant cost" in [[project_gen_resolve]] + the phased-path and purity-audit specs — corrected to ~1-2 sessions on 2026-07-02.

**How to apply:** decompose to concrete artifacts + count available references (adios/Korora/zen/nixpkgs-lib) + assume clean-room TDD and the user's throughput, THEN estimate. A "registry re-host" whose collection logic is already pure Nix riding `deferredModule.merge(loc,defs)` is a provider swap, not a rewrite — do not price it as a rewrite. For these libs the real risk axis is almost never duration; it is external-oracle SURFACE completeness (e.g. a 7-item primitive proving 8-9 once real usage hits the evalModules-equivalence oracle) — price that as "+½ session," not "+weeks." When you catch yourself writing "weeks-months / keystone / dominant cost / long pole," STOP and recompute from the shape. See [[project_gen_rebuild]], [[project_hola]], [[project_gen_package]].

──────── feedback_feature_flags_removability.md ────────
---
name: feedback_feature_flags_removability
description: Each den-hoag system gets an explicit den.features.<name> flag + a per-rung removability gate (flag-off/delete → rest byte-green, system's own tests park)
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner directive 2026-07-22 (den-hoag WS-B): every system built in den-hoag (KERNEL or compat) gets a FIRST-CLASS `den.features.<system>` toggle (default on) AND a per-rung review check — **flip the flag off / delete the system → rebuild → everything else stays byte-identical green + the system's OWN tests park.**

**Why:** the goal is to safely REMOVE and/or FEATURE-FLAG each system INDIVIDUALLY as it's built, while keeping the kernel/compat purity split and exposing the generic subsystems as generic APIs. The implicit guarantee we ALREADY prove — each system is inert-absent-its-trigger (corpus-zero identity / empty-exemption / default-`{}` / `firesAt=[]`), verified by byte-parity every rung — is necessary but NOT sufficient: the owner wants disable/remove to be first-class + continuously verified, not just a de-facto property.

**How to apply:** (1) new rungs build the `den.features.<system>` flag + a removability witness FROM THE START (flag reads at the system's entry — e.g. forward: gate the iv-b exemption + forwardModulesFor; config-thunk: gate producerConfigs; late-dispatch: gate radiation). (2) **RETROFIT = AUDIT-FIRST (owner 2026-07-22 expanded): a DEEP audit of ALL compat feature systems across den-hoag's WHOLE history — NOT just the recent-session 5.** The 2026-07-22 seed {config-thunk producer-resolution @65bc050, late-dispatch @080f547, funcfacet lift @f955ae5, forward+`(b)` @00fa7ad} is a subset; the audit (`audit-compat` → `specs/2026-07-22-compat-feature-isolation-audit.md`) enumerates every compat system (7 batteries, provides/to-users, forwards, routes, aspect-include arms, policy constructors, class-registration/grounding, key-classification/typo-protection, pipe machinery, R1-R23, …) + isolation-assesses each (inert-absent-trigger / removable-LOCAL-vs-SIGNATURE-ENTANGLED / flag-able), then a prioritized retrofit backlog. (3) Standing review item: every rung's two-stage review asserts the flag toggles cleanly + the removability check passes. **KNOWN ENTANGLEMENT (rung-0 design input, qualrev-forward on 4a): the forward iv-b exemption threads `exempt` through the shared classifier signature (classSliceOf/assertKeysRegistered/classContentOf + ~13 callers) — behaviorally identity when `{}` but delete is atomic-across-callers not a bolt-off; retrofit evaluates refactoring to non-entangling (ctx-attr not positional param). Signature-entanglement is the pattern the audit hunts for.**

**STANDING FEATURE REGISTER (owner 2026-07-22): `papers/den-architecture/specs/compat-feature-register.md`** — the canonical, MAINTAINED inventory of ALL den-hoag compat features (the ~34 from the audit `specs/2026-07-22-compat-feature-isolation-audit.md`), INCLUDING the Tier-2 LOAD-BEARING ones (not dropped). Per feature: name/`den.features.<name>`, purpose, files, trigger, isolation tier (Tier-0 local-clean / Tier-1 sig-entangled / Tier-2 load-bearing / kernel-of-compat), flag-able, removable, and for load-bearing/entangled — the COUPLING (what depends on it, why removal isn't clean) + a refactor-to-enable-removal note. **DISCIPLINE: every new den-hoag feature REGISTERS its entry (tier + flag + removability) in this doc as part of its rung; load-bearing features are the COUPLING-REVIEW / refactor-to-enable-removal candidate list (deep-coupling signal — review, may refactor later, no immediate action required).** STATUS.md + the EXECUTION ledger point to it.

Extends the earlier owner directive "den.default members stay individually-disableable isolated behaviors". Links [[project_den_hoag_features]], [[feedback_nix_config_module_conventions]].

──────── feedback_format_before_commit.md ────────
---
name: Format before committing
description: Always run treefmt before committing in den repo to avoid CI failures
type: feedback
---

Always run `nix run github:vic/checkmate#fmt --override-input target .` (or `nix develop -c just fmt`) before committing in the den repo. CI runs treefmt-check and will fail on unformatted code.

**Why:** Multiple PRs have failed CI due to treefmt formatting differences (#464, #466). The formatter rewrites Nix code (e.g., expanding inline `//` merges to multi-line).

**How to apply:** Run the formatter after all edits, before every commit. If amending, format again before the amend.

──────── feedback_format_cmd.md ────────
---
name: format-command
description: nix develop -c just fmt only for den repo; nix-config uses treefmt directly
metadata: 
  node_type: memory
  type: feedback
  originSessionId: da8b4c97-4429-4ae6-9f2f-8df3c44b80b3
---

`nix develop -c just fmt` is the format command **only when working in the den repo** — treefmt isn't in PATH there outside the devshell.

In **nix-config**, format with **`nix fmt <files>`** (the repo's treefmt wrapper, `config.treefmt.build.wrapper`), NOT bare `treefmt` from PATH. The repo config (modules/flake-parts/treefmt.nix) has **statix disabled** and uses nixfmt only. Bare `treefmt` from PATH picks up a config where statix is enabled, which applies the `manual_inherit` lint and rewrites `{ x = cfg.x or [ ]; }` → `{ inherit (cfg) x; }` — a **semantic change that dropped a load-bearing `or [ ]` and broke nixidy eval** (2026-06-03). `nix fmt` is statix-free and safe.

**Why:** bare `treefmt` and `nix fmt` resolve different configs; the PATH treefmt's statix makes behavior-changing rewrites that the repo's canonical formatter would never make.
**How to apply:** den → `nix develop -c just fmt`; nix-config → `nix fmt <files>` (avoid bare `treefmt`). See [[feedback_format_before_commit]].

──────── feedback_gen_direct_merge.md ────────
---
name: feedback_gen_direct_merge
description: "For the gen-rebuild v2 work, merge sub-plans to main directly (rebase) — do NOT open PRs per sub-plan"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 378e7ffe-6fd7-4baf-9ddb-70945be528ca
---

For the gen-rebuild v2 build (and the gen libs generally in this effort), the user wants me to **merge directly, not open a PR per sub-plan**. Stated 2026-06-23 after P0/P1 each went through a PR: "merge the PR yourself, don't open any more PRs."

**How to apply:** keep doing the sub-plan work on a feature branch (isolation + the subagent-driven per-task commits/reviews still apply), but at the end — once the full suite is green and reviewed — **merge the branch to `main` myself** (`gh pr merge --rebase --delete-branch` if a PR already exists, else `git rebase`/ff-merge the branch into main + push) instead of opening a PR and waiting. No PR ceremony, no waiting on the user to merge. Verification discipline is unchanged (green suite + review before merging). Akin to [[feedback_automerge_prs]] (nix-config auto-merge) but for the gen repos. Related: [[project_gen_rebuild]].

──────── feedback_gen_lib_docs.md ────────
---
name: feedback_gen_lib_docs
description: Adding API to a gen library requires theory-cited comments + updating the lib README AND the gen-specs/<lib>/REFERENCE.md — not just code+tests
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 378e7ffe-6fd7-4baf-9ddb-70945be528ca
---

When adding new API surface to a gen library (gen-graph, gen-scope, gen-rebuild, …), code+tests are NOT enough. Three things I repeatedly missed in P0/P1 2026-06-23 (the user had to dispatch a separate agent to fix gen-graph + gen-scope):

1. **Comment style = cite the THEORY, not the working spec.** Shipped gen-lib code comments cite the academic paper (author/year/§), matching the existing idiom — e.g. `Arntzenius 2016 (Datafun reverse reachability)`, `Mokhov 2017 §4.3`, `Tarjan 1972 / Kosaraju`. Do **NOT** reference the in-flight design/working spec (e.g. `Spec 2026-06-23-gen-rebuild-v2-design §5.P0`) in library code — it's a transient planning doc, not the library's permanent provenance. (Observed: my `Spec …§5.P0` condensation comment was rewritten to `Tarjan 1972 / Kosaraju for SCCs; Mokhov 2017 §4 for the quotient-graph idiom`, gen-graph/lib/global.nix.) Also match the surrounding comment density/format of the file.

2. **Document the new API surface** in the library's own README/docs (the lib repo, e.g. gen-graph/README.md).

3. **Update the canonical REFERENCE spec** `~/Documents/papers/den-architecture/gen-specs/<lib>/REFERENCE.md` — it describes the library in totality. gen-graph/gen-scope/gen-derive/gen-schema/gen-algebra/gen-bind/gen-select/gen-aspects/den-hoag each have one; gen-rebuild may need one created. (Ecosystem-level: gen hub README/ARCHITECTURE/TERMINOLOGY at ~/Documents/repos/gen/, gen-specs/ECOSYSTEM.md — see [[reference_gen_docs]].)

4. **README/markdown edits MUST be mdformat-clean — verify the way CI does, not via local `nix fmt`.** gen CI (`.github/workflows/ci.yml`) runs `nix fmt -- --ci` with **`working-directory: ci`** — the formatter is the **ci/ flake's** treefmt, which includes **mdformat** (markdown) + `--fail-on-change`. Local `nix fmt` from the lib repo ROOT FAILS ("does not provide attribute 'formatter'" — root flake has no formatter), and `nix flake check` from root only runs nix-unit `checks.default` (NOT treefmt). So a README that looks fine locally can fail CI on mdformat. **Verify with `cd <lib>/ci && nix fmt -- --ci`** (the exact CI check). Gotcha that bit gen-graph PR #2 2026-06-25: mdformat un-escapes `\|`→`|` inside inline-code spans in markdown tables (`O(\|cone\|)` → `O(|cone|)`), a silent 2-byte change. (Also: a stale `gen` pin in the committed `ci/flake.lock` can lack the mdformat wiring CI resolves, so even local `cd ci && nix fmt` may under-report — when in doubt, trust the CI run.)

**Why:** library docs + REFERENCE.md are the durable record consumers read; transient-spec citations rot and don't match the cited-theory idiom the gen libs use everywhere.

**How to apply:** theory-cited comments (point 1) are **per-task, NOT deferrable** — bake into every gen-lib task. The README + gen-specs/<lib>/REFERENCE.md (points 2-3) **MAY be deferred to a single docs pass after the initial implementation is finished** when the API is still growing across sub-plans (user decision, gen-rebuild v2 2026-06-23: defer the gen-rebuild REFERENCE spec until v2 P2/P3/P4 land, then write it once over the stable surface). For a one-shot lib change, do the docs in-PR.

**Adding missing citations is its own pass.** The `gen-theory-conformance` skill CLASSIFIES existing citations (faithful / overclaim / misapplication / gap) and flags where they're absent, but it does NOT add them. Pair it with an explicit **"add missing theory citations to code comments"** pass: bring sparse code comments up to the gen-lib idiom density (each op/function cites its paper §, like gen-graph's `Arntzenius 2016` / `Mokhov 2017 §4.3` / `Tarjan 1972`), sourcing the paper-per-op mapping from the lib README's provenance table. (gen-rebuild v1 code was citation-sparse — only `build.nix:41` "Mokhov shape" — despite a solid README table; user flagged 2026-06-23.) Related: [[project_gen_rebuild]], [[reference_gen_docs]].

──────── feedback_gen_lib_push_gate.md ────────
---
name: feedback_gen_lib_push_gate
description: NEVER pre-authorize a subagent to push a gen-lib change in its writer prompt when the REQUIREMENT itself isn't owner-confirmed. Gen-lib changes that preserve a v1 compat holdover need owner sign-off FIRST — they may be anti-north-star band-aids.
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Hit 2026-07-25 (den-hoag, collections-1). I queued a gen-aspects `wrapGatedFn` `onMiss` hook as "already-scoped/no-design," wrote the writer prompt saying "you MAY commit + push once green + reviewed-by-yourself," and the writer PUSHED (a82eb81) before my HOLD landed. The owner then challenged the requirement ("are you certain? why wasn't it in the audit?") — correctly: the hook was a COMPAT BAND-AID (teaching gen-aspects to reproduce v1's ride-raw ceiling = adding gen-side capability to PRESERVE a holdover, anti-[[feedback_best_framework_first]]). Had to revert (gen-aspects main @94cb5e3 = byte-identical to 5f7e349, forward-only revert; force-push to shared history was correctly blocked by the classifier).

**Two errors:**
1. **Mis-classified a holdover-preserving change as "no-design/just-ship."** A gen-lib extension whose PURPOSE is to reproduce a v1 compat ceiling is NOT a clean route-through — it is the OPPOSITE of dissolution. Red flag: if the re-verify/audit says "compat-scoped, not a permanent gen-native primitive" or "a deeper dissolution retires this entirely," it is a band-aid, not a rung. The real answer is to DISSOLVE the ceiling (design work), never to teach a gen lib to mimic it.
2. **Pre-authorized the push before owner sign-off.**

**How to apply:** (a) A gen-lib change (extending gen-aspects/gen-graph/etc.) whose requirement is NOT owner-confirmed — especially any change justified as preserving/reproducing v1/compat behavior — gets owner sign-off on the REQUIREMENT before a writer builds it, and the writer must STOP-and-report before pushing (do NOT write "you may push" into the prompt). (b) den-hoag byte-neutral route-throughs into EXISTING gen primitives are fine to drive autonomously; NEW gen-side capability is a higher bar — confirm it dissolves a holdover, not preserves one. (c) A pushed-but-unwanted commit on a shared gen lib: REVERT (forward-only), do not force-push shared history (the classifier blocks it, rightly). Links [[feedback_gen_direct_merge]] [[feedback_scout_vs_ultracode_audit]] [[feedback_route_through_gen_native]] [[project_gen_trust_release]].

──────── feedback_git_staging.md ────────
---
name: explicit-git-staging
description: Never use git add -A or git add . — always stage specific files by name
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bd146730-2538-46f7-9a21-1b1e0915427d
---

Never use `git add -A`, `git add .`, **or directory adds like `git add modules/den/aspects`**. Always stage specific files by name.

**Why:** Two failure modes. (1) The repo has local working docs (CLAUDE.md, docs/superpowers/) gitignored upstream but present locally; broad staging picks them up. (2) The user (and parallel agents) edit files concurrently — a directory-scoped `git add` sweeps in their in-progress edits AND any whole-repo `treefmt` reformatting collateral. This bit me on 2026-06-02: `git add modules/den/aspects` in a reorg commit (e88e3919) swept in a live darwin.nix edit (lost a `_:` module wrapper + a key segment) plus treefmt reformats of unrelated files.

**How to apply:** List every file path explicitly: `git add file1 file2`. To commit a subset while leaving other staged/working changes untouched, use `git commit --no-verify -m "..." -- path1 path2` (commits only those paths). Before staging, run `git status` and confirm every path is one you intended to change. In subagent prompts, list the exact files to stage. Also run `treefmt` only on the specific files being committed, never the whole repo (it reformats unrelated files → collateral). See [[feedback_format_before_commit]].

──────── feedback_graph_query_direct_reachable.md ────────
---
name: graph-query-direct-reachable
description: den-hoag/gen graph queries are DIRECT (1 edge) or REACHABLE (transitive closure, ∞) — never a bounded numeric depth. 0/1/∞ only; a "depth-2" is an arbitrary non-graph-native cutoff (code + naming smell).
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner directive 2026-07-24 (den-hoag): a graph relationship/query has exactly three cardinalities — **0** (no edge / unrelated), **1** (DIRECT / adjacent — one edge), **∞** (REACHABLE — the transitive closure, any number of hops). **There is no meaningful "2".** A bounded depth-k (k>1) is an arbitrary cutoff that doesn't exist in the graph model — naming a rung/query/param "DEPTH-2" (or any numeric depth) is a non-graph-native smell.

**How to apply:** express + NAME every kernel query as DIRECT (a node's own slice / adjacent) or REACHABLE (the descendant/ancestor CLOSURE), never a bounded depth. Concrete example (A4 bucket retirement, DL-HS-35-adjacent): `classSliceKeyedAt nid class` = the DIRECT per-node class-slice (1); `classSubtreeAt` = the REACHABLE descendant-closure (∞, via `scope.descendants`). The prior scope docs' "DEPTH-1 / DEPTH-2" framing was WRONG — it conflated graph-depth with the CLOSURE'S LOCUS (whether the reachable-gather is computed den-hoag-side vs relocated into gen-edge's native `sources.collected`). Name that by what it is (closure locus / route-through-gen), not "depth".

Cross-check: gen-graph's own vocabulary already reflects this (adjacency/`children` = direct; `reachableFrom`/`ancestorsOf`/`foldReach`/`inheritAll` = reachable-closure; no bounded-depth primitive). den-hoag must mirror it. If a design introduces a `depth`/`maxDepth`/bounded-k param or a "level-2" concept, stop — it's either DIRECT or a full CLOSURE. Links [[reference_gen_lib_capability_map]] [[project_denhoag_kernel_primary_surface]] [[feedback_best_framework_first]] [[project_class_bucket_holdover]].

──────── feedback_improve_api.md ────────
---
name: Improve APIs not preserve bad ones
description: User prefers improving APIs over preserving backward-compat shims; __includes smuggled through bindings is a leaky abstraction worth fixing
type: feedback
---

Don't preserve bad APIs just for backward compatibility. If an API is leaky or confusing, improve it.

**Why:** The `__includes` sentinel key smuggled through resolve bindings (`policy.resolve { user = tux; __includes = [...]; }`) is a leaky abstraction — callers shouldn't need to know the internal transport mechanism. A proper API like `policy.resolve.with [includes] { bindings }` or a separate `includes` parameter is better.

**How to apply:** When designing pipeline APIs, prefer clean interfaces over magic sentinel keys. If the fix requires changing the public API, that's acceptable — the branch hasn't shipped yet.

──────── feedback_just_do_it.md ────────
---
name: Act on findings immediately
description: When user says "clean up X" or "fix X", do it — don't audit then ask permission
type: feedback
---

When the user's prompt is an instruction ("let's clean that up", "fix X"), act on findings immediately. Don't audit, report, then ask "want me to do it?" — the instruction was already given.

**Why:** The user gave a clear directive. Asking for confirmation after completing the analysis wastes a round-trip and ignores the original instruction.

**How to apply:** If the user says "do X" and you find what needs doing, do it. Reserve confirmation for genuinely ambiguous scope or risky/destructive actions, not for executing what was explicitly requested.

──────── feedback_memory_architecture.md ────────
---
name: feedback_memory_architecture
description: What belongs in memory vs beads vs codebase-memory — memory is for HOW TO WORK; project STATE goes in beads. Hard size cap.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T05:06:27.275Z
---

**A memory too big to read is too big to keep.** Owner, 2026-07-28: *"these memories are useless if they
aren't accessed and fed to context… memories that are too big to read are too large to be kept — these
predate me giving you access to codememory and beads tools."*

The corpus had grown to **145 files / 5914 lines**, of which **56% was `project` state** — and one file was
**927 lines, 16% of everything**. That file fails both ways at once: recalled, it floods the context window;
not recalled, it is dead weight that silently goes stale. It had in fact gone stale, and was used to file a
bead asserting already-shipped work.

## Where each thing belongs

| holds | tool | why |
|---|---|---|
| **How to work** — corrections, disciplines, earned rules | **memory** (`feedback`) | must reach me unprompted, across projects and sessions |
| **Who the user is** | **memory** (`user`) | same |
| **Pointers** — archives, repo locations, external URLs | **memory** (`reference`) | cheap, stable, no state |
| **Project state** — work items, status, decisions, measured facts, dependencies | **beads** | queryable, has a real dependency graph, survives compaction, one fact per issue |
| **Code structure** — symbols, callers, architecture | **codebase-memory** | derived from the tree, never stale by construction |

`project` memories keep **only a thin pointer**: what the project is, where its state lives (the bead id),
and any fact that is *not* derivable from the repo or the tracker. **Never a status log.**

## The rules

1. **~40 LINES IS A TRIGGER TO AUDIT, and the audit's default answer is CUT.** Over it, a file is usually
   state (→ beads) or two facts (→ split). It may legitimately stay longer only when every line is a distinct
   irreducible rule — a laws index, not a narrative. **Case studies are never that**: they are evidence, they
   belong in beads, and a law that needs its evidence can cite the bead.
   ★ WORKED EXAMPLE, and the reason this rule exists: `feedback_verification_predicate_blindness` reached
   **238 lines** — ~25 earned laws, each buried in its case study. At that size it stopped being recalled, and
   a trap **recorded verbatim in it** fired again in live work. Split to 25 one-line laws (64 lines) with the
   cases archived at `den-hoag-4kh.20`. Nothing was lost; it became readable.
2. **`MEMORY.md` is the only guaranteed-read file** — it loads every session. One line per memory, and the
   line must say enough to decide whether to open the file.
3. **State goes to beads, with its dependency edges.** A bead can block another; a memory cannot. Ordering,
   blocking and "what must happen first" are graph facts and belong in the graph.
4. **A memory naming a `file:line` is a hypothesis, not evidence.** Verify at HEAD before acting — see
   [[feedback_verification_predicate_blindness]]. Memories are point-in-time observations; the tree is the
   only evidence about now.
5. **Prune on contact.** If you open a memory and it is stale, fix or delete it in that turn. A memory nobody
   corrects is worse than none, because it carries authority it has not earned.

Related: [[project_gen_tracker_scope]] (the tracker covers all of gen), [[feedback_reviewable_artefact]]
(the same principle for specs: small verifiable core, commentary around it).

──────── feedback_nix_config_linear_history.md ────────
---
name: feedback_nix_config_linear_history
description: "nix-config main enforces a no-merge-commits branch rule; never --no-ff merge, rebase/fast-forward instead"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cfa68f53-b79d-4c8f-af2f-9ef810ad04f3
---

sini/nix-config `main` has a GitHub branch rule: **"This branch must not contain merge commits."** A `git merge --no-ff` into main is rejected on push (GH013 rule violation).

**Why:** linear-history requirement on the protected default branch.

**How to apply:** integrate feature branches into main by **rebase + fast-forward** (`git checkout main && git rebase <feat>` or `git merge --ff-only`), never `--no-ff`. If a merge commit already exists locally, `git rebase origin/main` drops it (default rebase omits merge commits) and produces a fast-forwardable linear history — no force-push needed when origin/main is an ancestor. See [[project_nixidy_object_transforms]] (hit this 2026-06-09).

──────── feedback_nix_config_module_conventions.md ────────
---
name: feedback_nix_config_module_conventions
description: nix-config/den module best-practice conventions + locality-over-indirection style (from the syncthing-quality correction)
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d6a187ba-ca56-4763-b1f1-ed2bef4097ba
---

Jason was unhappy that the syncthing modules ignored project conventions ("if I have to give you explicit instructions I may as well make the modifications myself"). Match these den/nix-config idioms when writing aspects. **Verify against the cited exemplars before writing — don't invent structure.**

**Why:** non-idiomatic modules = tech debt he'll have to clean up; he expects me to internalize conventions, not be told each one.

**How to apply — the conventions (file:line exemplars in `modules/den/`):**
- **One concern per file.** Multi-facet aspects split like `core/network/tailscale/` → `tailscale.nix` (daemon+firewall) / `secrets.nix` (the secret) / `darwin.nix` (platform). Each file opens with a 1–2 line header naming its concern. NEVER a kitchen-sink file mixing home+system+secrets.
- **Secret paths via a schema `secretPath` field, never hand-built.** `host.secretPath`/`environment.secretPath`/`cluster.secretPath` exist (`schema/host.nix:391` = `self + "/.secrets/hosts/${name}"`). `user.secretPath` ADDED (`schema/user.nix`, commit 0dc8e8f0) — but default to **`rootPath` (a `../..` path literal), NOT `self`**: the per-user *registry* option-default is forced during the BASE flake eval, where `self` infinite-recurses (registry → `self` → flake outputs → registry; verified — `nix fmt`/eval died on `registry.pol.secretPath`). `host.secretPath` survives on `self` ONLY because it's forced later (when a host config is built, post-base-eval), not during base eval. **Rule: anything forced during the base eval — schema/registry option-defaults, and arguably pipe emits — must use `rootPath`, not `self`.** `rootPath` + `self` are otherwise equivalent for reading committed/staged sidecars (both read the git-tracked store snapshot; neither sees untracked files). `rootPath` is `_module.args.rootPath = ../..` (flake-parts), available in schema + aspect files via the header.
- **agenix generators centralized** in `aspects/secrets/_generators-module.nix` (imported into the host class at `batteries/agenix.nix`; NOT yet into `home-manager.sharedModules` — that gap is why inline-HM-generators get rationalized; fix the import, don't inline). Public sidecar written by the generator via `lib.removeSuffix ".age" file + ".pub"`.
- **Pipe policies (`den.policies.*`) live in `policies/pipes.nix`** (collect-/expose-/broadcast-), wired via `den.schema.<scope>.includes`. NEVER define policies inside an aspect-content file. Emit the quirk attr beside its consumer; consumer self-filters.
- **Per-user content needing a system resource = a USER-scoped aspect with a `${host.class}` branch** (the `agenixUserAspect` idiom, `batteries/agenix.nix:109-166`) — fans per-user automatically. Do NOT host-scope-enumerate users (`resolved-users` loop + `pathExists` re-gate), which forces `mkForce`/duplicated logic/schema leaks.
- **Persisted dirs emit into the `persistHome`/`persist`/`cacheHome` pool** (a collector turns it into `home.persistence`), never write `home.persistence` directly.
- **Settings flags:** declare `den.aspects.<path>.settings.<opt>`, set in the host file (`settings.<path>.<opt>`), read `host.settings.<path>.<opt>` (no `or`-guard where the aspect/option is present). bgp `localAsn` is the exemplar.
- **Aspect PRESENCE = a role decision, NOT a `settings.enable` toggle** (his explicit correction 2026-07-01). To disable an aspect fleet-wide, DEMOTE it from the role's `includes` (the file stays in-tree, re-addable) — never add a self-toggling `enable` flag to the aspect. Settings only *parameterize the behavior of an already-included aspect* (e.g. git `signing.method` enum on the always-present git aspect); they do not gate its existence. Presence via roles; behavior via settings.
- **Cross-platform home class = `homeManager`** (`homeLinux`/`homeDarwin` route into it via `classes/home-platform.nix`).

**REMOTE-DEPLOY file delivery (caught on blade):** a committed file needed by a service AT RUNTIME on a REMOTE host must be a real store-path dependency. `cert = toString (rootPath + "/.secrets/.../x.crt")` makes the dep the whole flake `-source`, which is NOT in the closure colmena copies to remote hosts (colmena rewrites the derivation hash for its unused secret-injection, dropping it) — works only on the local build host (cortex), fails on remotes (blade: copy-keys "cannot stat … No such file or directory"). FIX: import the file as its own content-addressed store path — `"${builtins.path { path = …; name = "x.crt"; }}"` — a genuine closure member, delivered like an agenix secret. (agenix secrets reach remotes fine; flake-source paths don't.) Commit 76a08f79.

**STYLE — locality over indirection (his explicit correction):** do NOT create a shared `_lib.nix`/constants file for a handful of values — it reads as needless indirection/complexity. Inline single-use logic; push helpers down as close to the use site as possible; a trivial one-line expression (e.g. `22000 + user.system.syncthingOffset`) repeated at a few sites is preferable to a helper-file abstraction. The legitimate shared abstraction is a **schema field**, not a helper module. (`_`-prefixed lib files like `_gpu-passthrough-lib.nix` exist but are for non-trivial reused logic, not constants.)

Related: [[project_replicated_home_syncthing]], [[feedback_refactor_large_files]], [[feedback_nix_idiomatic]].

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [nix-config module conventions](feedback_nix_config_module_conventions.md) — den aspect idioms (one-concern-per-file like tailscale split, secretPath schema field, centralized generators, policies in policies/pipes.nix, per-user system content via user-scoped ${host.class}, persistHome pool, settings flags) + LOCALITY over indirection (no _lib.nix for constants; inline single-use; schema field is the shared abstraction)

──────── feedback_nix_idiomatic.md ────────
---
name: Idiomatic Nix style
description: Use inherit for hyphenated identifiers in scope instead of quoted attribute assignment
type: feedback
---

Use `inherit aspect-chain;` not `"aspect-chain" = aspect-chain;` when the variable is in scope. Prefer idiomatic Nix patterns.

**Why:** Quoted form is unnecessarily verbose when the identifier is already bound.

**How to apply:** When constructing attrsets where the value matches a bound variable name, always use `inherit`. Only use quoted form when the attribute name differs from the variable or is a literal value.

──────── feedback_no_coauthor.md ────────
---
name: No co-authored-by in commits
description: Do not include Co-Authored-By trailer in commit messages
type: feedback
---

Do not add the Co-Authored-By line to commit messages.

**Why:** Standing user preference across repositories.

**How to apply:** Omit the Co-Authored-By trailer from all git commit messages.

──────── feedback_no_deferral.md ────────
---
name: no-deferral-ship-right-the-first-time
description: "Don't ship incomplete work with \"follow-up\" items. Push onward until the design is fully realized."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9ea92e54-1c53-4d70-b148-681defc591a4
---

Don't defer work to follow-ups. Ship the complete design, not incremental half-measures with a backlog of cleanup items. When the right architecture is clear, push onward until it's realized.

**Why:** Scope-partitioning plan accumulated 5 deferred items across 9 tasks. Each deferral created technical debt that complicated subsequent tasks. The "follow-up" framing is a rationalization for stopping early.

**How to apply:** When tempted to write "deferred to follow-up" or "cleanup in separate PR" — stop. Ask: is the design complete without this? If not, it's not a follow-up, it's unfinished work. Include it in the current scope.

**Fix tech debt AS SOON AS DISCOVERED — regardless of how minor (owner, 2026-07-22).** When an audit/review surfaces debt (a hand-roll that should reuse a lib primitive, an internal dup, an inconsistency), DON'T route it to a "someday" backlog — fix it THIS session, promptly. Distinguish genuine DEBT (suboptimal, should reuse/dedupe) from JUSTIFIED-BESPOKE (faithfulness/substrate FORCED the hand-roll — not debt, leave it). Fix the debt; leave the justified. **Sequencing constraint (still applies):** respect one-writer-per-repo — if the debt is in a file the ACTIVE rung already touches, FOLD it into that rung (same reviewer/gate); if it's cross-repo (an upstream gen-lib export/primitive) or in non-conflicting files, action it in parallel; serialize same-repo writers. The point is immediacy of ADDRESSING, not reckless concurrent edits. Links [[feedback_reuse_scan_before_build]], [[feedback_no_half_measures]], [[reference_gen_lib_capability_map]].

**Perf is tech debt too — and "later" is not a plan (owner, 2026-07-20).** A perf/incrementality item left "optional, maybe later" is orphaned debt. Two tests: (1) **Is it completing THIS work?** Often what looks like "a perf add-on later" is actually finishing the current refactor (e.g. moving reads into a scheduled eval WITHOUT declaring their edges leaves warm-serve non-incremental = a half-done refactor → do it now, in scope). (2) **If it genuinely must defer, it gets a NAMED scheduled home, never "someday."** Verify every deferred item is tracked to a concrete phase/task (a "tracked deferrals" table in the spec), and address ASAP — do not leave debt orphaned or indefinitely deferred. Discovered-mid-build deferrals get the same: a named home immediately.

──────── feedback_no_half_measures.md ────────
---
name: feedback_no_half_measures
description: For den/gen framework design — reject YAGNI, no pragmatic half-measures/interim tech debt; build the best framework, fix upstream (gen-aspects/gen-types/gen-merge in scope)
metadata:
  node_type: memory
  type: feedback
  originSessionId: 565c66a0
---

On den/gen FRAMEWORK design, reject YAGNI and do NOT ship pragmatic half-measures — an interim "it works, ship it" state that a later proper design must redo IS tech debt, and the owner will reject it. Fix the root cause upstream: **gen-aspects, gen-types, gen-merge are 100% in scope** for performance, compatibility, simplicity — don't confine a fix to the downstream consumer (den-hoag) to avoid touching gen.

**Why:** repeated controller pragmatism bit multiple times in one session (2026-07-14) — under-calling a flawed spike (it tested a raw body, not the gen-typed one → missed the terminal double-declaration), then endorsing the "Option 1" raw-content-walk half-measure TWICE as "it works, zero functional benefit to the alternative." The owner: "your pragmatism has already bitten us multiple times… reject YAGNI in the name of building the best framework we possibly can."

**AVOIDANCE-VIA-RATIONALIZATION (sharpest instance, 2026-07-15b — owner: "you've burned millions of tokens trying to find ways to avoid work… if we had just accepted the sunk cost in the first place. Steer toward the correct approach, regardless of cost").** The failure: when the correct (harder) approach hit friction (the gen-native single tree sprawled across 8 shape-interactions), I repeatedly fell back to an easier LOCAL off-ramp (Option 1 / compile-reads-raw), then commissioned spikes/explorations that "proved" the off-ramp "correct" — motivated reasoning dressed as rigor. TELL: if a verdict lets you skip the hard work you were avoiding, distrust it. The razor: does the off-ramp actually solve the STATED problem, or relocate it? (Option 1 kept the hand-rolled identity walk → did NOT fix the value-injection debt, just renamed the shadow.) **Accept the sunk cost; do the correct work regardless of cost. Do not let cost-avoidance masquerade as architecture.**

**How to apply:** when a downstream fix looks forced only because an upstream lib lacks a capability, treat the upstream enhancement as the real work, not out-of-bounds. Design for the north star (e.g. gen-aspects §3a: registry/namespace/cross-flake portable identity `pathKey(namespace ++ path)`), not just today's consumer. Verify a spike's premise matches the REAL path before trusting its verdict (the value-injection boundary: gen types NEVER cross into nixpkgs; a spike on a raw body doesn't test a gen-typed one). Prefer the design that reaches the destination in one move over an interim that accrues debt. Links [[feedback_architecture_first]] [[feedback_no_deferral]] [[feedback_estimate_delivered_shape]] [[project_den_hoag_value_injection]] [[feedback_verify_gate_exit]].

──────── feedback_no_parallel_agents.md ────────
---
name: no-parallel-agents-in-same-repo
description: Never dispatch parallel agents working in the same repo without worktrees; worktrees branch from default branch not current
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

One agent at a time when working in the same repo. Parallel agents cause file conflicts, staging collisions, and corrupted work.

**Why:** Two agents modifying overlapping files (even just shared test files) creates race conditions. git staging area is shared. Agents see each other's partial changes and fight over file contents.

**Worktree limitation:** Claude Code worktrees branch from the default branch (main), not the current feature branch. So worktree-isolated agents work against stale code missing all feature branch work. Don't use worktree isolation for feature branch implementation.

**How to apply:** Dispatch one implementation agent at a time. Wait for completion and commit before dispatching the next. Only parallelize truly independent research/exploration agents that don't write files.

**★ APPLIES TO DOCS REPOS TOO, and to ME (the orchestrator), not just code subagents (2026-07-26).** Hit this during the STATUS/ doc-consolidation: I ran TWO doc-writing subagents (coverage-matrix + feature-register) in the papers repo (`den-ag-design`) AND committed to that same repo myself concurrently. Even though the two subagents edited DIFFERENT files, one committed + one amended between my commits → my pushed commit (`f61e2b9`) and a subagent's local re-do (`4dee385`) landed as divergent SIBLINGS off a shared parent; `git rev-parse origin/main` then failed and history looked clobbered. Recovered cleanly (only one file's header actually differed, both versions correct → `git rebase origin/main`, no conflict, pushed linear — no work lost), but avoidable. LESSON: the shared git index/HEAD is the hazard, not file overlap — two writers committing to ONE repo tangle history even on disjoint files. When consolidating docs across many files, EITHER serialize the doc-subagents (one finishes+commits before the next), OR let the subagents write-but-not-commit and I do all commits, OR give each a worktree. And I must not hand-commit to a repo while a subagent is committing to it. Recovery drill when it happens: `git fetch` + `git ls-remote origin <branch>` (authoritative HEAD) → `git diff origin/<branch> HEAD --stat` to see the real divergence → rebase local onto origin (resolve favoring the intended-final content) → confirm `ls-remote == local HEAD` before declaring done. [[feedback_check_after_kill]] [[feedback_debug_before_revert]]

──────── feedback_no_pr_byline.md ────────
---
name: No generated-with bylines on PRs
description: Do not add "Generated with Claude Code" or similar bylines to PR descriptions
type: feedback
---

Do not add "Generated with [Claude Code]" or similar generated-by bylines to PR descriptions.

**Why:** User considers them noise.

**How to apply:** Omit any generated-with/co-authored-by style footers from PR body text when creating PRs with `gh pr create`.

──────── feedback_no_self_complete_tasks.md ────────
---
name: feedback_no_self_complete_tasks
description: "In agent-teams, report task done to controller; don't mark it completed yourself"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2d31f5dd-0663-4090-8917-a7bdd0c8098a
---

When running as a teammate/implementer agent, do NOT set a task's status to `completed` yourself. Deliver a status report (SendMessage) and leave completion to the controller/team-lead, who decides after spec + quality review.

**Why:** completion = an accept decision that belongs to the reviewer, not the implementer; self-completing skips the review gate.

**How to apply:** finish work → verify → SendMessage a report (Status + what built + verify tails + commit SHA + concerns) to the requester ("main" or team-lead as instructed). Keep the task `in_progress`; let the controller close it. See [[feedback_caveman_subagents]], [[feedback_no_deferral]].

──────── feedback_no_temporal_comments.md ────────
---
name: feedback-no-temporal-comments
description: code comments must not encode temporal task/spec-specific keys; cite theory or point to REFERENCE.md; strip review scaffolding in the docs sweep
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 99ecf393-ca15-4ac9-98fd-cdeb7ad76318
---

Agents encode task/spec-specific keys in code comments during implementation — `#8`, `★ BLOCKER`, `R5`, `A-IDENT`, `Task 2`, stash names, commit SHAs, "the plan says…". Useful for REVIEW, but temporal → tech debt once the arc ships.

**Why:** a code comment is read for years after the task is forgotten. A `#8` or `R5` marker is meaningless to a future reader and rots. Comments (in this ecosystem) are meant to cite THEORY / academic provenance (see [[feedback_preserve_citations]]) or explain the general invariant — not the ticket that produced it.

**How to apply:** replace every temporal reference with the GENERAL invariant framing or a pointer to the relevant `REFERENCE.md` section (papers `gen-specs/<lib>/REFERENCE.md`). Preserve academic citations. Applies to gen libs + den-hoag. Ties to [[feedback_gen_lib_docs]] (comments cite theory not the working spec).

**PER-RUNG PRE-REPORT GREP (den-hoag lead, 2026-07-18 — adopt as a standing check, don't defer to the docs sweep).** The keys read naturally to the implementer because they ARE the mental model, so they leak repeatedly (WS-FLAKEPARTS T1 + T3 both leaked → a review cycle each; T6 leaked a sub-arc-LETTER suffix `4c-iii-C` the first pattern missed). Fold into the per-rung loop AFTER fmt, BEFORE commit/report: `git grep -nE '\b(T[1-8]|F[1-6]|SF[0-9]+|WS-[A-Z]+|sub-arc|4c-i{1,3}-[A-C])\b' <files-touched-this-rung>` and strip any arc/fork/task keys from CODE comments. **The sub-arc-LETTER suffix is the subtle one:** a §12-step key is durable BARE (`§12 step 4c-iii`, `4c-ii`) but strips its trailing sub-arc letter (`4c-iii-C`, a `-[A-C]` after the step) — the letter is this arc's internal decomposition, not spec vocab. **KEEP durable §-anchored / domain vocab** (spec rulings like §4.1 F1 canonical-machine-form + §4.2 F4 dispatch; the bare `§12 step 4c-iii` file headers; compat parity taxonomy F1/F2/F3; gen-pipe strata T1/T2/T3) — the same durable-vs-transient distinction the reviewer makes; a bare arc fork key (this arc's flag numbering) strips, a §-anchored spec ruling stays.

──────── feedback_no_time_estimates.md ────────
---
name: feedback_no_time_estimates
description: Do NOT give time/duration estimates (no "~1.5 days", "~1 day", hours). As an LLM I deliver much faster than human-calendar estimates imply; they're misleading. Size work by shape/risk/blast-radius, not wall-clock.
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner correction 2026-07-24: **never give time/duration estimates** ("~1.5 days", "~1 day", "a few hours") — as an LLM I deliver work much faster than human-calendar estimates imply, so they're misleading + wrong.

**Why:** the estimate frames the work in human-dev-time, which doesn't apply. It sets a false expectation and anchors on the wrong axis.

**How to apply:** size work by its SHAPE, not wall-clock — LOC/blast-radius, risk tier (LOW/MODERATE/HIGH), number of files/repos/edges touched, oracle surface, whether it needs a spike. Say "MODERATE risk, ~40 LOC, touches gen-aspects core + 3 compat callers" not "~1.5 days". Strip time estimates from scope docs / plans / subagent prompts too (tell scoping agents to size by shape, not duration). Relates to [[feedback_estimate_delivered_shape]] (price by delivered artifacts/shape) — but drop the day-count entirely.

──────── feedback_oci_images_workflow.md ────────
---
name: feedback_oci_images_workflow
description: "nix-config k8s images — use the images.\"ns/name\" digest accessor + oci-image-updater, never inline tags; init makes a wrong 3-level path"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 6be70bc6-5144-481b-9993-9c9eb2f90954
---

nix-config k8s container images: use the repo's **oci-images logic**, NOT an inline `tag`. Inline tags can resolve to a non-existent image (a GitHub *release* tag ≠ a published *container* tag) — exactly how a Profilarr deploy broke (`ImagePullBackOff` on `:v2.0.9`, which had no image; ghcr only published `develop`).

**Pattern** (sidecars already do this — onedr0p/exportarr, grafana/alloy):
- Metadata file `images/<ns>/<name>/default.nix` = `{ imageName; imageTag; imageDigest; imageHash; arch; os; pinned; }`. Path is **2-level** (`images/<ns>/<name>/`), registry **stripped from the path but kept in `imageName`** (path `onedr0p/exportarr`, `imageName = "ghcr.io/onedr0p/exportarr"`).
- In the aspect's `k8s-manifests` add `images` to the args and do `image = { inherit (images."<ns>/<name>") repository digest; };` → renders `repository@sha256:<digest>` (digest-pinned, no tag).
- `oci-images.nix`: `imageRefs."<ns>/<name>" = { repository = imageName; digest = imageDigest; }` via a **two-level** `foldlAttrs` (ns/name).

**GOTCHA — updater init makes a WRONG path:** `nix run .#oci-image-updater -- init --image-name ghcr.io/<ns>/<name> --image-tag <t> --arch amd64 --os linux` resolves digest+hash correctly BUT writes a **3-level** path `images/ghcr.io/<ns>/<name>/` (registry included). That collapses the 2-level `foldlAttrs` to a broken `"ghcr.io/<ns>"` key (no usable `<ns>/<name>` accessor) — verified empirically. FIX: move the file to `images/<ns>/<name>/default.nix` (drop the registry dir; `imageName` already keeps it). Then verify: `nix eval .#imageRefs.x86_64-linux.\"<ns>/<name>\"` resolves, and `nix run .#oci-image-updater -- check-all` lists it.

`oci-image-updater check-all` / `update-all [--commit]` re-resolves digests for all `images/**` entries (reads imageName+imageTag from the file, path-independent), so a rolling tag like ghcr `develop` is safe = digest-pinned + auto-bumped. Profilarr tracks `develop` (only v2 channel; no stable v2 image). See [[project_media_observability]] (images/imageRefs accessor), [[feedback_agenix_rekey_workflow]].

## Index-line archive (2026-07-06 trim — full detail preserved from MEMORY.md)

- [oci-images workflow](feedback_oci_images_workflow.md) — nix-config k8s images: use images."ns/name" digest accessor + images/<ns>/<name>/ metadata (2-level path, registry in imageName NOT path) + oci-image-updater, NEVER inline tags (a release tag ≠ a published image → ImagePullBackOff); updater `init` writes a WRONG 3-level path, move it; profilarr tracks ghcr develop (only v2 channel)

──────── feedback_orchestrator_theory_first.md ────────
---
name: orchestrator-theory-first
description: "Standing operating mode for den-hoag work — orchestrate via fresh-context agents, decide against theory not v1-compat or least effort, and gate every unshipped finding through adversarial review before it enters beads"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b950db38-5e47-4795-8d45-ba555a674ba5
  modified: 2026-07-27T20:32:45.028Z
---

**Owner directives, 2026-07-27. These are STANDING, not per-task.**

**1. Orchestrate, do not implement.** Drive the work through independent **fresh-context** agents — scouts,
research assistants, reviewers, authors. Reserve own context for oversight, review and decision. A fresh
context per role is the point: a reviewer that inherits the author's framing is not independent.

**2. Theory-first is the decision bar.** Every decision aligns against **proper theory**. NOT v1-compat
convenience. NEVER least effort. **Everything must be defensible as a theory-based expression.** A design
justified by "v1 did it this way" or "this is the smaller change" FAILS, regardless of whether it works.

**3. Beads must contain a graph of VALIDATED CORRECT work.** Many specs are self-authored and never
adversarially reviewed. So: **an unshipped finding does NOT become a bead — it becomes a review candidate.**

```
finding → adversarial architecture-alignment review
            ├── against pure-gen criteria
            └── against the ACADEMIC RESULT the design claims
          → VALIDATED : enters graph, labelled arch-validated, citing criterion + provenance
            REJECTED  : recorded WITH ITS REASON (a rejected design leaving no trace gets re-proposed)
            REDESIGN  : design first; the original never enters the graph
```

`arch-validated` is a **positive** label — absence means not-yet-validated. Labelling the unvalidated ones
instead fails OPEN, and silence must never read as success.

**4. Kernel purity precedes compat materialization.** The den-hoag kernel must be a **pure graph
representation** before the full backwards-compat layer materializes. Audit what has been introduced into the
kernel that violates the pure graph / category-theory layer from the den feature+compat layer. Note
`ci/tests/boundary.nix` guards this line **lexically only** (token scan, import direction, seam enumeration) —
it cannot observe representation, so a v1-shaped accumulator with gen-native naming passes it.

**5. Beads over markdown.** Markdown files are hard to keep in context; **the bead graph carries the
structure**, and bead bodies must be self-contained. Tasks may explicitly request a **user-guided design
spike** rather than resolving an owner-level question autonomously.

**How to apply after compaction:** run `bd show den-hoag-4kh` and `bd ready` from
`~/Documents/repos/sini/den-hoag`. The epic and its children carry the full directives, criteria and
falsifiers verbatim — beads persist where context does not. See [[project_kernel_purity_arc]].

[[feedback_spec_before_development]] [[feedback_best_framework_first]] [[feedback_no_half_measures]]
[[feedback_delegate_spec_plan_authoring]] [[feedback_review_plan_before_execution]]
[[project_denhoag_kernel_primary_surface]]

──────── feedback_performance_is_defect.md ────────
---
name: feedback_performance_is_defect
description: "Performance problems are DEFECTS — file and track them, never dismiss as acceptable cost"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T00:32:03.513Z
---

Treat performance issues as **defects**. A complexity blowup, an avoidable exponential, an O(n²) where the
substrate offers O(n) — these get filed and tracked exactly like a wrong answer. Do not dismiss one as "an
optimization", "acceptable cost", "only matters at scale not reached today", or "not a standalone bug".

Stated by the owner 2026-07-27, after I described a Θ(2^k) blowup in a proposed design as something that
"doesn't survive as a standalone bug" because a correctness repair happened to remove it.

**Why:** correctness and cost fail the same way here — silently, at a scale nobody probed. A design that is
correct and exponential is not a fixed design. And a correctness repair that incidentally removes a blowup
leaves the *cause* in place, so the next caller reintroduces it. Cost is also a representation property in
this codebase: the pure-graph criteria treat "state accumulation instead of query" as a defect partly
because of what accumulation costs.

**How to apply:** when auditing or designing, state the complexity of the chosen instrument, not only its
answer. If a cheaper instrument exists in the substrate, using the dearer one needs a stated reason.
A perf finding gets the same treatment as any other: measured, positive-controlled, through the review gate,
into the graph. Corpus-absence is not a defence — the bar is den-surface expressibility, see
[[feedback_den_surface_not_config]].

Related: [[feedback_no_half_measures]], [[feedback_best_framework_first]], [[project_gen_tracker_scope]].

──────── feedback_plan_then_subagent_pattern.md ────────
---
name: plan-then-subagent-execution-pattern
description: Deep exploration → precise plan with code → opus subagent per task + two-stage review = flawless multi-task execution
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b37f95be-eff3-452d-93ad-70f8de1671a6
---

The most effective pattern for multi-step refactors: deep exploration → precise plan → subagent-per-task execution with two-stage review.

**Why:** Phase E pipeline simplification (7 tasks, 25+ files, ~2000 line net change) shipped with zero rework. Every task landed 641-644/644 on first CI run.

**How to apply:**

1. **Explore exhaustively before planning.** Dispatch Explore agents to map every file, line number, function signature, and caller inventory. The plan needs exact paths and line counts, not guesses.

2. **Write plans with complete before/after code.** Subagents succeed when they have concrete diffs to implement, not prose descriptions of what should change. Include exact file:line references.

3. **Review the plan document before execution.** Dispatch a plan reviewer — it catches wrong file paths, understated scope, and logic errors that would waste subagent cycles.

4. **Fresh opus subagent per task.** Full task context in the prompt (not session history). Caveman lite style for token conservation. Each subagent starts clean — no accumulated confusion. **Before every dispatch, re-read `feedback_review_dispatch_prompts.md` and scan the prompt for red flags** (thinking-out-loud, contradictions, cancelled sections).

5. **Two-stage review after each task.** Spec compliance first (built what was asked?), then code quality (well-built?). Sonnet is sufficient for mechanical reviews; opus for judgment calls.

6. **Coordinator applies small fixes directly.** Comment improvements and dead code cleanup from reviews — amend the commit and move on, don't re-dispatch a subagent for a 2-line change.

7. **Dependency chain matters.** Tasks 3 and 4 (remove from/to) could run after Task 2 independently. Task 5 (remove __functor) needed both. Task 6 (class key lists) only needed Task 0. Getting this right prevented blocking.

8. **Honor a requested pre-grind checkpoint even if the end-state would be green.** (gen-schema C3 re-host, 2026-07-02: lead asked for a lib/-milestone report BEFORE delegating the 93-file corpus grind; I compressed lib/+corpus into one subagent pass. It landed green + a byte-parity oracle retroactively discharged the risk, and the lead accepted — but noted: a checkpoint's value is catching a *wrong turn before the downstream cost is paid*, which a green end-state cannot guarantee in advance.) When an orchestrator asks to eyeball the swap surface / plan / stable-target-API before a big mechanical grind, stop and report at that seam — don't optimize it away.

9. **When a delegated subagent flags "gaps I worked around," review whether the gap belongs at the SOURCE.** (C3: subagent flagged 4 gen-merge gaps + hacked around them in the consumer; 2 were real gen-merge correctness bugs — top-level `_module` dropped by marker-misclassification; option-decl merge-by-replace vs field-combine — that would bite *other* consumers. Fixed at source (with regression tests, byte-identity oracle held) instead of leaving consumer hacks. The other 2 were genuine documented byte-mode limits — leave those.) Independently re-run the gate yourself; don't accept the subagent's "green" on trust.

10. **Implementation-ready specs do NOT replace the plan gate.** (den-hoag 6-lib build, 2026-07-06: dispatched implementers straight from spec — user caught the skip mid-flight. Ruling: continue that run, but integration-heavy phases — den-hoag assembly/den-compat — get write-plan + plan-review BEFORE code.) A spec fixes the contract; the plan fixes file layout, task order, scaffolds — review both.

──────── feedback_preserve_citations.md ────────
---
name: Preserve academic provenance citations
description: Don't remove citations that trace implementations to their academic sources during cleanup
type: feedback
---

Academic citations in code comments serve as provenance — they trace implementations back to their primary sources and validate that the code matches the original specification.

**Why:** The gen ecosystem is built on formal foundations (Palmer, Neron, Reynolds, Leijen, etc.). Citations like "Palmer §3" or "Reynolds 1972 defunctionalization" are not noise — they're the connection between implementation and theory.

**How to apply:** During cleanup, distinguish between:
- **Valid provenance citations** (keep): "Palmer §2.2", "Neron §2.4", "Leijen 2005" — traces implementation to source
- **Wrong citations** (fix or remove): cites wrong paper/section for what the code actually does
- **Stale dev notes** (remove): "added in later tasks", "Open Question #1", line number references
- **Cross-repo citations** (remove): describes what a *consumer* does, not what this code does

──────── feedback_pr_sanitization.md ────────
---
name: pr-sanitization
description: nix-config is a PUBLIC repo — keep PR descriptions and commit messages free of concrete infra specifics
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e01d2fbd-c8b8-4957-9110-3ef064840502
---

In nix-config (public repo), PR descriptions and commit messages must not contain: public/VPN egress IPs, internal IPs/CIDRs, real hostnames (tailnet, service domains), forwarded/listen port numbers, media library row counts, or other operational specifics. Describe mechanisms generically ("the provider egress IP", "the fabric loopback range", "the qbt UI host").

**Why:** 2026-06-12 the user had to request sanitization of 10 merged PR bodies (#99-#112) that leaked VPN egress IP, tailnet domain, internal topology, and library counts; GitHub edit history then needed manual revision-deletion per PR (UI-only, no API).

**How to apply:** before `gh pr create` / commit, scan the body for IPs, domains, ports, counts; generalize them. App names and repo file paths are fine (already public via code). Commit messages are immutable post-merge on the protected main — get them right the first time.

──────── feedback_pull_before_work.md ────────
---
name: Pull before working on external repos
description: Always git pull in external repos before starting work to avoid divergence
type: feedback
---

When working across multiple repos (gen, gen-schema, gen-aspects, gen-scope, gen-graph), always `git pull` each repo before starting modifications. Local state can be behind remote if another session or collaborator pushed.

**Why:** gen-schema was behind remote by one commit during the cleanup session. The cleanup commit had to be rebased after the fact.

**How to apply:** At the start of any multi-repo task, pull all target repos. Don't assume local main is up to date.

──────── feedback_refactor_large_files.md ────────
---
name: refactor-large-files
description: User wants helpers.nix and configuration-helpers.nix split into smaller files when touching them
type: feedback
---

When modifying helpers.nix or configuration-helpers.nix, feel free to refactor them into multiple smaller files.

**Why:** These files have grown large with many responsibilities — the user explicitly asked for this.

**How to apply:** When a task touches these files, split logically coherent sections into their own files (e.g., module collection utilities, context assembly, feature submodule type). New files in `modules/flake-parts/` that aren't flake-parts modules need `_` prefix to avoid auto-import, OR be structured as proper flake-parts modules exporting via `config.flake.lib.*`.

──────── feedback_reference_impl_secrets.md ────────
---
name: reference-impl-automated-generation
description: "nix-config is a reference implementation — use agenix-rekey generators wherever possible; manual secret values only when externally issued, with explicit docs"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 45e58014-4682-41b7-91d3-af1d710e43d6
---

nix-config aims to be a reference implementation for others. Secrets: always use agenix-rekey generators (`agenix generate`) — never hand-roll values that a declared generator covers. Manual `age -r <master-recipient>` encryption is reserved for externally-issued values (e.g. ProtonVPN wireguard creds), and those must carry explicit in-file documentation of the manual provisioning procedure.

**Why:** hand-rolled values fork provenance from the declared generators and make the config less reproducible as a teaching artifact; generation needs no private key for dependency-free generators (encrypts to master pub recipient), and sini's YubiKeys are PIN/touch-Never so even dep generators work with a key plugged in.

**How to apply:** before creating any .age file, check for a declared generator; prefer `agenix generate`. Document any genuinely manual secret's source + encryption command where it's declared.

──────── feedback_relationship_guards.md ────────
---
name: policy-dispatch-guards
description: "resolveArgsSatisfied gates policies on destructured args being in ctx; stale entity-named destructure silently never fires; { self } = fire-once-at-scope"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f882872a-48c7-4445-8a8a-70e5e2336ea8
---

A den policy's destructured args ARE its dispatch guard. `resolveArgsSatisfied` (nix/lib/synthesize-policies.nix) dispatches a policy only if every required (non-`?`-default) destructured arg is present in the scope ctx; `dispatch.nix` is the single chokepoint. So `{ host, ... }:` fires where ctx has `host`; `{ user, ... }:` fans across user scopes (each user binds `ctx.user`).

**Why:** Vic's review — `from = "host"` implies ctx has `{ host }`. Guards belong in the dispatch layer, not inline `ctx ? host` checks.

**How to apply:**
- A policy on `den.schema.<kind>.includes` must destructure a kind actually bound in that scope's ctx — else it **silently never fires** (no error). This root-caused the nix-config k8s `nixidyModules`-empty regression: `to-fleet` had a stale `{ flake-system, ... }:` but fires at the `flake` scope, where `flake-system` isn't in ctx → filtered → no fleet → empty cascade. Fix was dropping the stale guard.
- `flake` is NOT an entity kind (`den.lib.strict` marker, no `isEntity`), so `{ flake, ... }:` is inert as the entity-kind guard AND fails resolveArgsSatisfied unless `flake` is in ctx.
- **`{ self, ... }:`** (added den feat/entity-gen-schema-port @ sini/den b2bcfd42, 2026-06-03; pushed + live in nix-config): `self` is always injected into the dispatch ctx, so `{ self, ... }:` fires once at the policy's registration scope and is excluded from the late-sibling fan. Use it for resolution policies that must fire once (`to-fleet`, `fleet-to-envs` use it); reserve `{ <kind>, ... }:` for genuine fan-out. See [[project_den_architecture]].

──────── feedback_resume_failed_agents.md ────────
---
name: feedback_resume_failed_agents
description: Resume a failed/completed subagent via SendMessage instead of re-dispatching fresh
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 64d6f7c2-8cd7-4b89-9d3f-643302e3b3cf
---

When a subagent dies mid-task (session limit, crash) or completes and more work fits its context, **resume it via `SendMessage` to its name** — a send resumes an agent from its transcript, preserving its accumulated context and any partial progress. Do NOT re-dispatch a fresh agent for the same work by default.

**Why:** resume preserves the agent's primed context + partial work; a fresh dispatch loses both and re-pays the priming cost. Names keep working after an agent completes/fails.

**How to apply:** on a subagent failure, first `git status`/`diff` the worktree ([[feedback_check_after_kill]]). Then: if it has partial work or expensive context → `SendMessage` to resume it. Re-dispatch FRESH only when (a) the slate is genuinely clean (it made zero edits — resume ≈ fresh) or (b) the task changed. Never run a fresh agent AND resume the original on the same files — that's a write conflict ([[feedback_no_parallel_agents]]).

──────── feedback_resume_voice.md ────────
---
name: resume-voice-craft
description: "Resume/bio voice rules — subject-less register, no em-dashes in summary prose, hold the architectural thesis vs buzzwords, agents-as-problem framing, multi-variant summaries, Gemini as second-opinion"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f1e18aca-13ac-4450-b034-efb1c2ad5379
---

Durable voice/craft rules for Jason's resume (and bio/sponsor/marketing copy), learned refining `~/Documents/repos/sini/resume` 2026-06-24. Complements [[feedback_build_up_self_promo]]; see [[project_resume_repo]].

- **Subject-less register** throughout — no first-person "I"/"We". Use appositives/gerunds ("co-founding *Denful*, an open-source organization building…"). The lone "I" stood out and was removed.
- **No em-dashes in the summary prose** — they read as an AI tell. Convert to commas, colons, parens, or sentence breaks (vary the treatment, don't find-and-replace one substitute). Em-dashes in dense experience bullets are fine; the concern is the narrative summary.
- **Signature line:** keep "correct by construction, not by prayer and runbook" (bold accent slate). Frame the forward thesis as *rigor/verifiability is the antidote to agentic coding making plausible-but-wrong systems cheap to produce and costly to verify* — NOT "infrastructure for the agents that will operate it" (category error + hype).
- **Hold the architectural vocabulary:** "composable, verifiable" is his actual thesis — do not let it get swapped for generic Nix-marketing "fully declarative, reproducible"; reject buzzword inflation ("next-generation infrastructure", "proven track record").
- **Multi-variant summaries:** resume.tex keeps commented summary blocks (active distilled / manifesto / big-tech / startup). Tailor per audience: big-tech = ruthless past-execution-at-scale, omit the forward thesis; startup + dev-tooling/funding = forward thesis welcome.
- **Gemini second opinion:** Jason routinely cross-checks edits with Gemini and forwards its replies. Critically assess, don't rubber-stamp — it has hallucinated library names ("gene", "endgram"), guessed a wrong location, and reintroduced the em-dashes he wanted gone.

**Why:** non-obvious, repeatedly-applied preferences not derivable from the repo's committed output.
**How to apply:** when editing resume/bio/marketing copy, default to these without re-litigating each one.

──────── feedback_reuse_scan_before_build.md ────────
---
name: reuse-scan-before-build
description: "Before speccing a NEW engine/lib/mechanism in the gen/den ecosystem, run an ecosystem reuse-scan FIRST — adversarial review catches wrong claims, not unconsidered reuse"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9ea92e54-1c53-4d70-b148-681defc591a4
  modified: 2026-07-28T00:48:56.145Z
---

Before designing or proposing to BUILD any new engine, lib, or mechanism in the gen/den ecosystem, run an explicit **ecosystem reuse-scan as step 0**: "which existing gen-* lib already provides this capability?" Inventory the full roster ([[reference_gen_lib_capability_map]]), not just the libs you already suspect are relevant.

**Why:** three recent design passes reached to BUILD a grand mechanism before checking what the ~21-lib ecosystem already ships (2026-07-20 proposed `gen-fixpoint` = ~85% of the shipped `gen-resolve`; the claim/provide author "reached for a grand engine twice; there isn't one"; gen-demand/gen-derive misfires). Only the owner's lateral question caught the gen-fixpoint one — deep tech debt was one naming question away.

**The failure mechanism (why verification doesn't catch it):** the blind spot lives in the QUESTIONS, not the answers. Anchoring on "build a new X" early propagates that premise into every grounder + reviewer prompt; each agent optimizes WITHIN the frame. **Adversarial review verifies CLAIMS against code — it cannot flag an OMISSION** (an un-considered existing lib isn't in the spec to check). So reuse must be a PROACTIVE gate, never a reactive one.

**How to apply:**
1. **Reuse-scan before build.** No "new-engine/lib/mechanism" spec section ships until a scan of the ecosystem roster for that capability is done + recorded. If a lib provides ≥~70% of it, the ruling is EXTEND, not build (the owner's standing bias: one engine, surface over existing, no debt — [[feedback_no_half_measures]]).
2. **Frame grounders "what already exists for this?"** not "does my proposed X work?" — and NEVER hand a grounder your build-premise as an assumption; let it find the provider.
3. **Give the adversarial reviewer a duplication lens** — an explicit "what does this spec duplicate or fail to leverage?" question, so omissions get attacked, not just claims.
4. **Anchor check:** when you've iterated deep in a frame, take one beat to ask "am I building what exists?" before committing the build decision.

5. **Layering corollary (WS-B grounding 2026-07-21):** design the GENERAL system in the correct layer — reusable algebra in gen-* libs · vocabulary/scope-topology projection in the den-hoag kernel · v1 compat = a THIN Van-Wyk map onto it. A compat/adapter layer must never accrete mechanism. **LITMUS: if a `lib/compat/` (or any thin-map) file contains a recursion, a fixpoint, a `foldl` over a graph, an edge-walk, or a transpose — it is in the WRONG layer.** The framing "implement the semantics in the compat/adapter" is itself the debt vector — reword to "wire/forward onto the general capability; build only in the identified lib/kernel layer." (WS-B: the whole backlog collapsed to WIRE-existing + 2 net-new kernel mechanisms once scanned against gen-pipe/gen-graph/gen-algebra/gen-aspects; a live `broadcast-gather.nix` compat clone was caught pre-build.)

6. **SCAN TO PRIMITIVE GRANULARITY, NOT LIB GRANULARITY (2026-07-27).** The scan can land on the *right
   lib* and still pick the *wrong surface*, and that failure is invisible to every later check. The
   class-reroute confluence design spent three review rounds on `gen-graph`'s `query`/`denQuery` lowering —
   correct lib — because that is where the originating finding pointed. `query`'s `paths` mode threads its
   visited set INTO each branch (per-path acyclicity), so it duplicates nodes on any non-tree shape and is
   enumeration-priced. `gen-graph/lib/preorder.nix` — the same lib, one file over — threads visited ACROSS
   siblings via `foldl'`, giving once-per-node first-occurrence-wins traversal in the same DFS pre-order,
   pruning subtrees without forcing them. Two adversarial review rounds measured the resulting defects
   (exponential duplication, a lost class) and prescribed a post-hoc dedup **repair**; neither asked whether
   a different primitive in the same lib removed the need. **When a finding names an instrument, that is a
   POINTER, not a decision** — enumerate the lib's full export surface before binding one of them, and read
   the neighbouring modules' headers, which in gen-* state their own trade-offs explicitly.

Related: [[feedback_architecture_first]] (redesign vs patch) is about WHEN to rebuild; this is about NOT rebuilding what's already there. [[feedback_den_surface_not_config]] (den-surface = the spec). [[feedback_by_construction_over_repair]] — the reuse-scan's usual payoff is a primitive that makes the defect impossible rather than repaired.

──────── feedback_reviewable_artefact.md ────────
---
name: feedback_reviewable_artefact
description: "A spec is reviewable only if its executable core is small, contiguous and hashable; freeze and md5-anchor it before dispatching review"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T04:14:19.161Z
---

**The reviewable artefact is the executable core, comments stripped, hashed. The prose is commentary that
must be re-derivable from it.**

Earned on a design spec that grew `452 → 611 → 1227 → 1466 → 1606 → 1664 → 1720` lines across five
adversarial review rounds. The design was stable for the last four — the executable block's comment-stripped
hash was identical throughout, and one execution verification carried unchanged through three revisions.
**Everything that grew was prose, and every defect found after round 3 was prose contradicting other prose**:
a rule stated in §3.1 and violated in §11; a cost row contradicting the library it cited; a figure believed
removed that had only been reworded.

The reviewer's own words: *"equation verification no longer finds anything, and prose auditing is unbounded.
I read perhaps a fifth of this file and found two rule violations in it. I cannot tell you what a full read
would find, and neither can the next reviewer."*

**How to apply:**

1. **Keep the executable core CONTIGUOUS and COMMENT-DELIMITED** — one fenced block with explicit
   `BEGIN`/`END` markers, extractable and hashable by a command. 19 lines carried a 1700-line document.
2. **FREEZE THE ARTEFACT AND MD5-ANCHOR IT BEFORE DISPATCHING A REVIEW.** Measure at dispatch time; never
   relay an earlier snapshot. Three stale-anchor incidents in one arc, all orchestrator-caused — each cost a
   full review round. Instruct the reviewer to check the hash first and STOP on a mismatch rather than
   review a moving target. Instruct the author not to edit; if it finds a problem, it messages instead.
3. **Verify a claimed no-op change by AST, not by eye.** `nix-instantiate --parse` drops comments, so
   comparing parsed output proves no expression moved — far stronger than grepping the diff for comment
   lines. Pair it with a positive control (mutate one operator, confirm the compare fires).
4. **A prose-only delta needs a CHANGE LOG, not another hash.** Nothing in it can be validated by running
   anything, which is exactly why enumeration is the only auditable form.
5. **Split rather than grow.** If a revision inlines equations into paragraphs or spreads them across
   sections, both the hash anchor and the comments-stripped diff stop working *at once*. That is the split
   trigger.

**HASH-IMMUNITY IS NOT DRIFT-IMMUNITY.** A *patch-shaped* core (a unified diff) carries line citations
structurally, in its **hunk headers** — `@@ -264,7 +265,18 @@` is a line citation. A hash recipe that keeps
only `+` lines excludes them, so the anchor survives a commit; but the headers still pin **where the patch
applies**, and a reviewer reading a stale `@@` against a moved file cannot distinguish drift from error.
Hold a patch's application points even when its hash is safe. (Check separately that no *added* line carries
a bare line number — naming things by identifier keeps the patch body itself drift-proof.)

**CITE CROSS-REPO REFERENCES WITH THE PINNED REV.** `gen-scope@ceabe5e/lib/resolve.nix:302-322` cannot be
invalidated by anything except a deliberate `flake.lock` bump; a bare `gen-scope/lib/resolve.nix:302` is
silently invalidated by an input bump with **nothing to detect it**. Citations by printed page (papers,
books) are immune to everything and are the strongest form available. Ask, per citation: *what event would
make this wrong, and would anyone notice?*

**FREEZING A SPEC DOES NOT FREEZE THE TREE IT CITES.** A freeze covering only the artefact is half a freeze.
A comment-only commit landed between freeze and review, shifted lines by +1, and silently invalidated line
references in a document nobody was permitted to touch — five occurrences of one citation. The anchor must
cover **both**: hash the document, and pin the commit its citations are correct against (the spec should
state that commit in its own header). Either hold tree commits until the verdict, or send the reviewer an
erratum and tell it to verify citations against the pinned commit rather than HEAD.

**DO NOT COMPRESS A MEASURED TABLE AND THEN DISCARD ITS SOURCE.** A 14-row guard inventory was recorded into
the tracker as a one-line class characterization plus "full table in the agent transcript" — and the agent
was then stopped. The rows became unrecoverable, and a downstream author was sent to look for a table that
was not there. **The tracker IS the record; a transcript is not.** If a measurement is worth citing later it
goes in whole, rows and all. Reconstructing it afterwards costs more than recording it did, and the
reconstruction carries a caveat the original would not have needed.

**Say what the verdict covers.** When review can no longer read the whole document, the honest position is
that the gate **verifies the equations and SAMPLES the prose** — and the record must say so, or `VALIDATED`
is read as stronger than it is. Scope every verdict explicitly: the design, not an implementation; which
lines were executed; what was only sampled.

Related: [[feedback_verification_predicate_blindness]], [[feedback_by_construction_over_repair]],
[[feedback_no_half_measures]].

──────── feedback_review_dispatch_prompts.md ────────
---
name: Review dispatch prompts
description: Resolve uncertainties and review agent prompts before dispatching — no thinking-out-loud, no contradictions, no cancelled sections
type: feedback
---

Preview and review dispatch prompts before sending to subagents. Resolve all uncertainties BEFORE writing the prompt — don't think out loud mid-prompt.

**Why:** Scope-partitioning plan (2026-04-29): 4 of 9 task dispatches contained thinking-out-loud violations ("WAIT", "ACTUALLY", "On second thought", showing failed attempts then correcting). Tasks 2-4 succeeded despite noise because code was mostly complete. Task 8 failed — contradictory instructions (goal said "remove flat fields", body said "WAIT... keep flat fields") left the agent with conflicting directives.

**Red flags in a draft prompt — STOP and resolve before sending:**
- "WAIT" / "ACTUALLY" / "On second thought" — you're changing direction mid-prompt
- "Skip for this task" after writing full detail for a section — you listed work just to cancel it
- Showing a first attempt then correcting it — the agent sees both and must guess which you want
- Goal/description contradicting the detailed steps — the agent doesn't know which to trust

**How to apply at EACH task dispatch:**
1. Draft the prompt mentally or in scratch
2. Scan for any of the red flags above
3. If found: stop, resolve the uncertainty by reading code or reasoning, then rewrite
4. The final prompt should contain ONLY conclusions, never the reasoning that led to them
5. Each section should be consistent — no section should contradict another
6. If listing items, only list items the agent should act on — don't list items to skip

──────── feedback_review_plan_before_execution.md ────────
---
name: feedback_review_plan_before_execution
description: Always dispatch an INDEPENDENT plan reviewer after writing-plans (before the execution handoff / first dispatch) — the skill only self-reviews; the independent plan review falls in the seam between writing-plans and subagent-driven-development
metadata:
  node_type: memory
  type: feedback
  originSessionId: 565c66a0
---

After `writing-plans`, ALWAYS dispatch an INDEPENDENT plan reviewer (opus, read-only, adversarial, against the spec + the actual code) BEFORE the execution handoff / before dispatching the first task. Mirror the spec/design review discipline.

**Why:** skipped TWICE (owner: "this is the second session where this process step was skipped"). Root cause = a GAP between two skills: `writing-plans` ends at a SELF-review (the controller checks its own plan) → execution-handoff HARD-GATE → `subagent-driven-development`, which reviews PER-TASK during execution, not the whole plan up-front. `brainstorming` gates the spec with a review; nothing gates the PLAN. Following each skill to its terminal (handoff → first dispatch) carries straight through the seam. The HARD-GATE ("only next action is the AskUserQuestion") + "don't pause between tasks" reinforce dispatching immediately, so the skip feels like following the process. A self-review is the controller grading its own work — exactly the blind spot an independent reviewer catches (why we review spec + design too).

**How to apply:** the full review chain for framework work = design review → spec review → **PLAN review (this, the missed step)** → per-task spec+quality reviews during execution. Insert the plan review right after the writing-plans self-review: dispatch a fresh adversarial reviewer (spec-coverage / code-correctness / placeholders / decomposition / gate-sufficiency / file:line), fold READY-WITH-FIXES, THEN execution handoff. Do NOT let the writing-plans HARD-GATE or subagent-driven "continuous execution" carry you past it. Links [[feedback_plan_then_subagent_pattern]] [[feedback_no_half_measures]] [[feedback_docs_in_review]] [[feedback_verify_gate_exit]].

──────── feedback_route_through_gen_native.md ────────
---
name: feedback_route_through_gen_native
description: den-hoag must route through gen-* natively, never re-implement a gen capability in compat; route existing duplications through native gen as prioritized tech debt
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner directive 2026-07-24 (den-hoag): **route den-hoag's gen-capability DUPLICATIONS through gen NATIVELY — and address this tech debt as a PRIORITIZED workstream** (ahead of remaining coverage). Not just "reuse-scan before building NEW" ([[feedback_reuse_scan_before_build]]) — RETROFIT existing hand-rolled code that replicates a gen-* lib to use the native gen mechanism instead.

**Why:** a live corpus bug (karabiner nested-aspect nav — user hit it evaluating a darwin host) traced to den-hoag's COMPAT-layer `looksNested`/`mkRawTotality`/`typedCompileTree` discriminator re-implementing (and drifting out of sync with) gen-aspects' NATIVE path-based nesting (`aspectsRoot`/`identity.nix` path-key, the A-IDENT work that retired `__provider`). A hand-rolled fn that MATCHES a gen API is duplication EVEN IF it works today — it drifts, exactly how the karabiner discriminator broke on a registered-content leaf under an implicit-directory intermediate.

**How to detect (two lenses, the audit `specs/2026-07-23-gen-duplication-audit.md`):**
1. **Compat-layer LITMUS (sharpest):** `lib/compat/` must be a THIN v1→gen dialect map — NO recursion / fold / edge-walk / transpose / identity-computation / merge (that's kernel or gen). Any such construct in `lib/compat` = a duplication candidate (looksNested = a recursion in compat = the tell).
2. **Capability-map cross-reference:** for each gen lib ([[reference_gen_lib_capability_map]]), grep den-hoag for a hand-rolled equivalent — gen-prelude stdlib (filterAttrs/hasInfix/imap0…) inlined; gen-aspects nesting↔looksNested; gen-graph query↔manual traversal; gen-algebra fold↔manual foldl'; gen-merge↔v1DeepMerge; gen-schema identity↔hand-rolled id_hash; gen-scope fixpoint↔hand-rolled lib.fix/nav.

**How to apply:** the fix is ROUTE-THROUGH-NATIVE (use the gen mechanism, thin/delete the compat re-impl) — NOT a band-aid patch of the hand-rolled version ([[feedback_architecture_first]]/[[feedback_no_half_measures]]: fix upstream, no interim). Only keep a hand-rolled compat construct if the v1-shape GENUINELY needs a pre-map gen can't do (state the real reason). Each duplication = its own rung (verify the native path handles it → plan → independent review → writer → dual-gate incl the broadened parity gate → consolidate). Prioritize live-bug-risks (drift-prone, like looksNested) first.

**★ NORTH STAR (owner 2026-07-24):** den-hoag was projected as **~2000 lines of SLIM framework surface GLUE**. **Any complexity in den-hoag is EITHER (a) a MISS from the gen ecosystem (a primitive gen SHOULD provide but doesn't → propose the gen gap/lib) OR (b) a FAILURE to leverage gen (hand-rolled what gen already provides → route through it).** This is the audit classifier for every finding. Concrete hand-rolls the gen-link agent flagged: **sha256 hashing vs gen-schema `hashIdentity`** (den computes `id_hash` by hand-rolling the hash); the **`.key`/identity handling** (the `.key` VALUES are gen's A-IDENT and consumed, but adjacent identity computation is hand-rolled); **NOT using gen-resolve's `forwardExpand`** (den has its own reach/dedup walk, resolved-aspects.nix). Comprehensive audit RUNNING 2026-07-24 (catalog every den-hoag re-impl of a gen primitive → gen-primitive-to-use or gen-gap, sized by LOC toward the 2000-line target). **gen-link** (a NEW gen-aspects+gen-schema module system replacing namespaces) ships as a PURE PRIMITIVE; its den-hoag integration is the orchestrator's responsibility once built; surface triage deferred until then. The gen-tree-mutation cleanups (DL-HS-23 §2 totality-no-mutation + §3-DEPTH-1 includes-reference) are DEFERRED — gen-link likely supersedes them.

Links [[feedback_reuse_scan_before_build]] [[feedback_architecture_first]] [[feedback_no_half_measures]] [[project_gen_package]] [[reference_gen_lib_capability_map]] [[project_den_hoag_value_injection]] [[project_class_bucket_holdover]].

──────── feedback_scout_vs_ultracode_audit.md ────────
---
name: feedback_scout_vs_ultracode_audit
description: A single scout re-scoping an item from an ultracode/multi-agent AUDIT is unreliable — trust the audit's prior. A "needs a NEW primitive" scout verdict must name which BUILT extension the audit intended + prove specifically why it fails, cross-checked against the full built set (not the one "obvious" primitive).
metadata:
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner directive 2026-07-25 (den-hoag). The effects-runtime audit was a **74-agent ultracode workflow** and the 6 necessary gen extensions (G1-G6) it identified were **all built + shipped**. So a SINGLE scout that later REFUTES one of the audit's route-through items ("not a clean route-through" / "needs a new primitive") is suspect — and a re-verify (DL-HS-51) proved **all 4 of my single-scout refutations carried false or mis-attributed primitive info**.

**The recurring failure mode:** the scout compares the den-hoag code to the ONE obvious gen primitive, finds it doesn't fit, and concludes "needs a new primitive" — WITHOUT scanning the full built set. Concrete misses:
- **B15** — compared to gen-graph `ancestorsOf` (single-parent/id-only) → "needs new"; actually routes via gen-graph **`expandPreorder`/`foldPreorder`** (the SAME payload-carrying-DFS family `reach`/`forwardExpand` already ride).
- **collections-1** — compared to gen-bind `wrapAll` (module-DI record) → "needs new resolveEager"; the true near-fit is gen-aspects **`wrapGatedFn`** (byte-exact gate+arg-filter+default-honoring) + one additive `onMiss` hook — no new lib.
- **B20** — the scout was directionally right (native lazy self-ref) but mis-framed it as unresolved; it's byte-identical to gen-scope's OWN `prelude.fix` foundation ⇒ **ALREADY_GEN_NATIVE**, done.
- **DL-HS-23** — the different-concern call was right, but the primitive mis-attribution was in the AUDIT (a single-G1 tag); constituents dissolve severally into **existing** primitives (G3 `deriveGroup` + `wrapGatedFn` + `includesElemType` + `closedKeys`).

**How to apply:** when re-scoping an audit item, adopt the audit's prior (it IS a route-through; the necessary primitive exists). A "needs a NEW primitive" verdict is a high bar — it must (1) name WHICH built extension the audit intended, (2) prove specifically why it fails, (3) cross-check against the full built set, esp the easy-to-miss ones: gen-graph **expandPreorder/foldPreorder/foldReach**, gen-aspects **wrapGatedFn**, gen-scope **inheritSet + the prelude.fix native-laziness foundation**, gen-dispatch **deriveGroup**. For anything beyond a trivial check, RE-VERIFY audit refutations with a multi-agent workflow (Gather primitive-menu → adversarial re-scope+verify per item), NOT a lone scout. Links [[reference_gen_gap_integration]] [[reference_gen_lib_capability_map]] [[reference_denhoag_effects_audit]] [[feedback_reuse_scan_before_build]].

──────── feedback_spec_before_development.md ────────
---
name: feedback-spec-before-development
description: "Always write the spec and file the tracking task BEFORE any development change — no code first, even when the change is small and measured"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b950db38-5e47-4795-8d45-ba555a674ba5
  modified: 2026-07-27T18:07:59.304Z
---

**Spec first, always. Every change is specced and captured as a task before implementation starts.**

**Why:** violated 2026-07-27 on `den-hoag-m0a`. A one-line gen-schema change (`_kind` on every instance) was
measured green and committed AND PUSHED before any spec or review existed. Owner then rejected the design on
five grounds — denormalization, observable surface growth, non-totality for empty registries, wrong direction
of contamination, and re-nominalizing a structurally-composed surface. All five were design objections that a
spec review would have caught for free; instead the work cost a public revert on `github:sini/gen-schema`
(`66eb255` → `6732239`), a lock bump, and three den-hoag fixture edits that were then thrown away.

The trap is that "small + measured green" reads as licence to skip the spec. It is not: measurement answers
*does it work*, and the objections were all *should it exist in this shape*. The smallness is what made it
feel exempt.

**How to apply:**
- Write the spec (papers `den-architecture/plans/`) and file the bead BEFORE touching code — including for
  one-line changes to a gen lib, and including when a probe already proves the mechanism works.
- The spec records rejected routes with their reasons, so a later session cannot re-litigate them.
- Pivot to review/sanity-check on the SPEC; commit to implementation only after.
- Applies with extra force to the public gen-* libs, where a wrong shape has to be reverted on origin.

[[feedback_review_plan_before_execution]] [[feedback_plan_then_subagent_pattern]] [[feedback_gen_lib_push_gate]]
[[project_den_hoag_features]] [[feedback_architecture_first]]

──────── feedback_stage_new_files.md ────────
---
name: Stage new files for flake and override den
description: New template files must be git-staged for Nix flake to see them; templates need --override-input den .
type: feedback
---

New files must be git-staged (git add) for the Nix flake to pick them up — unstaged files are invisible to flake evaluation.

When testing templates, always use `--override-input den .` so the template evaluates against the local checkout.

**Why:** Nix flakes only see tracked/staged files. Without staging, new files are invisible and flake eval fails with missing file errors.

**How to apply:** After creating new template files, stage them with `git add <specific-files>` before running any nix commands. Never use `git add -A` or `git add .` — always name specific files.

──────── feedback_subagent_model.md ────────
---
name: Opus for non-mechanical tasks
description: Use opus model for subagents on this project — only use sonnet for purely mechanical work
type: feedback
---

Use opus for any non-mechanical subagent tasks. This is a complex functional Nix project with algebraic effects — sonnet doesn't have the reasoning depth for it.

**Why:** User corrected sonnet dispatch for core policy conversion task.

**How to apply:** Default to opus for implementation agents. Only use sonnet/haiku for truly mechanical work (grep, file listing, simple find-and-replace with no judgment).

──────── feedback_targeted_transitive_lock_update.md ────────
---
name: feedback_targeted_transitive_lock_update
description: "bump a gen-* pin inside a sub-flake with targeted --update-input <parent>/<lib>, never nix flake update <parent>"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
  modified: 2026-07-27T02:29:31.531Z
---

When a sub-flake (den-hoag `ci/`, `parity/`) consumes a gen-* lib TRANSITIVELY through a
`path:..` parent input (`den-hoag`/`den-v2`) plus the `gen` hub, bump ONLY the one transitive
node: `nix flake lock ./ci --update-input den-hoag/gen-pipe` (and `./parity --update-input
den-v2/gen-pipe`). This moves just the gen-pipe node — a ~6-line lock diff.

**Why:** `nix flake update den-hoag gen` re-locks the ENTIRE gen-hub closure — a ~1006-line
churn per lock, dozens of unrelated rev bumps — which the reviewer reverts before commit.

**How to apply:** for any sub-flake gen-* bump, use targeted `--update-input <parent>/<lib>`;
never `nix flake update <parent> gen`. Then re-gate all three (root ci parity) green. See
[[project_den_hoag_features]] for the ci/parity ship-gate topology and [[feedback_stage_new_files]].

## ★ The two-segment path is often the WRONG node — resolve before bumping

One lib appears as MANY lock nodes at DIFFERENT revs. Measured in den-hoag `ci/flake.lock`:
**ten** gen-merge nodes across **three** revs (`gen-merge`, `_4`, `_6`, `_9` at one rev; `_2`,
`_5`, `_7`, `_10` at another; `_3`, `_8` at a third). So `--update-input den-hoag/gen-merge`
moves exactly one of ten, and *usually not the one a given fixture reads*.

There, the fixture resolved `root → den-hoag → gen-schema → gen-merge` = `gen-merge_5`, while
the two-segment bump moved `gen-merge_4`. The correct target was the **full chain**:
`--update-input den-hoag/gen-schema/gen-merge`.

**Always: trace the consumer's actual resolution path first, then bump that chain, then verify
the node you named is the one whose rev changed.** Otherwise a regression witness evaluates a
lib that never moved and reports green — a witness exercising a surface other than the one
under test, the same defect class as a fixture passing because it ran on nixpkgs
`submoduleWith` instead of gen-merge. See [[feedback_verification_predicate_blindness]].

──────── feedback_underscore_keys_state_hack.md ────────
---
name: feedback_underscore_keys_state_hack
description: den v1 __ keys = a hack around the nix-effects state accumulator; den-hoag (gen-native) must NOT replicate them in the kernel — only the compat boundary reads v1's __ user surface
metadata:
  node_type: feedback
  type: feedback
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

Owner 2026-07-23: **den v1's `__`-prefixed keys were a HACK around the nix-effects STATE ACCUMULATOR** (the v1 trampoline threaded resolution state by smuggling it through `__`-namespaced markers on records). **den-hoag is GEN-NATIVE** (resolves via gen-resolve/gen-scope/gen-edge; NO state accumulator — the deepSeq-state kill-switch is a v1-trampoline artifact den-hoag DOESN'T have, see [[project_config_thunk_tier1]]). So **do NOT replicate v1's `__` state-hack in the den-hoag kernel** — "v1-faithful" is NOT a free pass for a `__` key.

**The three-way split for any `__` key:**
- **COMPAT-BOUNDARY input (permanent, legit):** a `__` the SHIM must READ because a v1 corpus AUTHORS it (`__policyEffect`/`__fn`/`__args`/`__isPolicy` etc. = v1's drop-in user/record surface). den-hoag compat reads these at the boundary — required by the drop-in contract. Fine.
- **KERNEL-INTERNAL state-hack echo (TECH DEBT):** a den-hoag KERNEL `__` key that exists because it MIRRORS v1's state-smuggling (a marker to thread data through resolution) when den-hoag's gen engine could carry it as PROPER STRUCTURED DATA / a typed field / a gen mechanism. These are debt — structured-data-them or upstream a gen primitive (like the shipped setAttrByPath/dedupByKey/indexOf).
- **GENUINE den-hoag protocol (legit):** a `__` that's a real variant-discriminator/out-of-band metadata den-hoag's OWN design needs and that genuinely can't be a plain attr (e.g. `__functor` = Nix's callable convention; a tag that must survive a merge/fold as metadata). Keep — but must JUSTIFY why it can't be structured data.

**How to apply:** when adding OR reviewing a `__` key in den-hoag KERNEL code (lib/, lib/attributes/), ask "is this smuggling state like v1's accumulator hack?" — if yes, use structured data / a gen mechanism instead. Compat (lib/compat) reading v1's authored `__` records is the ONLY permanent home for the v1 `__` surface. Audit: `specs/2026-07-23-underscore-key-audit.md` (if written). Links [[feedback_den_surface_not_config]], [[feedback_reuse_scan_before_build]], [[project_regression_pattern]] (nix-effects kills the manual-threading class).

──────── feedback_update_memories.md ────────
---
name: Update memories at phase completion
description: Update memory files when completing task phases, not just at creation — prevents stale entries
type: feedback
---

Update memory files when task phases complete, not just when work begins.

**Why:** Memories were going stale because they were written at spec/plan time but never updated when implementation shipped. This creates misleading "status: next step is X" entries long after X is done.

**How to apply:** At the end of each significant phase (spec approved, plan written, implementation shipped, tests passing, branch landed), update the relevant memory file's status and description. Remove "next step" lines that are no longer accurate.

──────── feedback_verification_predicate_blindness.md ────────
---
name: feedback-verification-predicate-blindness
description: "LAWS for trusting a verification result — a predicate must match the AT-RISK path; an absence needs a positive control on the SAME instrument in the SAME run. ~25 earned traps, one line each."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-28T05:06:08.671Z
---

**A clean result is not evidence.** Every law below was paid for by a false green in this project. Full case
studies — what was measured, what it cost — archived at bead **`den-hoag-4kh.20`**; read it when a law needs
its evidence. Kept short here so it actually loads.
★ It was 238 lines and stopped being recalled, so trap 4 below **fired again while already recorded in it**.

## The three that generate the rest
1. **A predicate is evidence only if its string appears on the at-risk path** — confirm it matches a
   known-positive you already know exists. If it can't find that, the predicate is broken, not the code.
2. **An absence needs a positive control on the SAME instrument, in the SAME run.** Without one, *"it didn't
   fire"* and *"it cannot fire"* are the same observation. An absence deserves more scrutiny than a hit: a hit
   is self-evidencing.
3. **A SOUND predicate can prove a DIFFERENT PROPOSITION.** A control proves the instrument works; it does not
   prove you measured the sentence you reported. Restate the conclusion, then ask which command bears on *it*.

## Search
4. **`grep A | grep B` is a SINGLE-LINE conjunction; Nix attrsets, lists and arg-lists are MULTI-LINE.** Use
   `-A`/`-B` or read the range. Fails clean — the dangerous direction.
5. **Never combine `--include=` with a multi-tree search** — it applies to every path and silently skips the
   other tree's file type. Run each tree separately.
6. **Put `[-_ ]?` between words** in any multi-word predicate (`local-stratification` ≠ `local stratification`).
7. **Removing a claim: grep the NUMBER and the CONCEPT, never the sentence you wrote** — rewording survives it.
8. **A `git rev-parse` negative at a parent says nothing about children.** Git stops at the filesystem boundary.
9. **The concept may have no lexical form** — `enrich` is spelled `resolve { <non-schema-key> = … }`.
10. **Prefer the literal that survives lowering** (key name, constructor) over the conceptual name.
11. **A negative from a recursive or wrapped search deserves a second instrument** (`rg` vs `grep`, or per-file).
    The positive-control rule catches a predicate that cannot match; not a tool that does not traverse.
12. **A tool can omit the field you queried** — `bd show --json` has no `comments` key, only `comment_count`.
    Go to the storage layer when an absence is load-bearing.

## Evaluation and timing
13. **`length`/`attrNames` force only a spine.** Use `deepSeq` **plus a sentinel that aborts**, proving the
    force reached the values before quoting any number.
14. **`tryEval` catches a `throw` but NOT a missing-attribute error.**
15. **Work-dominated figures reproduce cross-machine; floor-dominated ones do not.** Rest the claim on the shape.

## Tests, guards, fixtures
16. **Pin the contents of any computed set you quantify over** — `all f [ ]` is vacuously true.
17. **Prove a guard can fail FOR ITS OWN REASON.** "Depends on anything" passes when a different guard aborts
    first. Arm it; review does not catch this.
18. **A control must force to the SAME DEPTH as the subject, and the harness is part of the instrument.**
19. **A fixture cannot disagree with the code it was written against** — it may assert its own premise, fail in
    its own construction, or be sampled from the one case both sides spell identically.
20. **An acceptance criterion already satisfied has no falsifier** — watch for one offered as a concession.
21. **An armed conjunction needs one perturbation per conjunct**; a dead conjunct hides inside a `true`.
22. **Prefer "unreachable in this shape, measured" over a guard you cannot arm** — 3 unreachability claims
    asserted and disproved in one arc.

## Claims
23. **A cited finding is a claim until its mechanism is traced** — a `file:line` gets adopted verbatim.
    Likewise **"already tracked as X" is a claim, not a citation**; open X.
24. **A comment stating a constraint is evidence; a comment describing an ABSENCE is not a law.** *"X never
    happens"* may hold only because the feature that does it doesn't exist yet.
25. **Agents' absence claims specifically** — positive findings held up, absence claims did not.
    See [[feedback_scout_vs_ultracode_audit]].

Related: [[feedback_memory_architecture]] (why this file is short), [[feedback_reuse_scan_before_build]].

──────── feedback_verify_gate_exit.md ────────
---
name: verify-gate-exit-status
description: "Piped verify commands mask failure — capture the test runner's exit explicitly before commit/push; verify reviewer \"dead code\" claims by gated suite run"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3d1d912b-97f6-422c-8f8a-13dd70de0e1f
---

Shipped a broken commit to a public repo (den-hoag 0ce7ca6, 2026-07-06) because `nix-unit … | tail -2 && git commit && git push` uses the PIPELINE's status (= tail's 0), so a failing suite still commits and pushes.

**Why:** zsh pipeline exit = last command unless pipefail; chaining `&&` off a piped verify is not a gate.

**How to apply:** (1) run the verify with explicit exit capture — `runner > out 2>&1; echo "exit=$?"` (or `set -o pipefail`) — and only commit after SEEING exit=0; (2) treat reviewer claims like "this field is dead/unread" as hypotheses — a lib may consume it internally (gen-dispatch requires rule.phase under multi-phase dispatch); the gated suite run IS the verification, so it must actually gate.

──────── feedback_worktree_location.md ────────
---
name: Worktree location
description: Create git worktrees under .worktrees/ in repo root, not /tmp
type: feedback
---

Create git worktrees under `.worktrees/` in the repo root, not in `/tmp`.

**Why:** User preference for keeping worktrees colocated with the repo.
**How to apply:** Use `git worktree add .worktrees/<name> <branch>` when setting up worktrees.

──────── reference_codebase_memory_no_nix.md ────────
---
name: reference-codebase-memory-no-nix
description: codebase-memory Nix coverage — gate 1 CLOSED (defs/calls now real); gates 2+3 still shut (no Variables); never pass an index mode
metadata:
  node_type: memory
  type: reference
  originSessionId: 632f8478-1553-4f12-bc63-704719454fe2
  modified: 2026-07-27T21:59:27.326Z
---

**SUPERSEDES the earlier "zero Nix symbols, use Read+Grep" reading.** As of 2026-07-27 the graph
carries real Nix functions and calls. Two independent causes were in play; both are addressed
locally.

**Cause A — stale pin.** nixpkgs tracked v0.8.1 (2026-06-12), predating Nix def/call extraction
(landed 0849f28c 2026-06-27, shipped v0.9.0). nix-config now takes the upstream flake directly
(commit 97fd32f1), not `pkgs.codebase-memory-mcp` from the channel.

**Cause B — gate 1, the real bug.** `extract_defs.c` `descend_into_func` allow-listed
Wolfram/TS/JS/TSX/Ada, so `walk_defs` hit `if (!descend_into_func) continue;` at a file's outer
lambda and abandoned the whole subtree. 253 of den-hoag's 320 `.nix` files open with one. Fixed by
adding `CBM_LANG_NIX`. Carried locally via `pkgs/overlays.nix` + `pkgs/patches/` (nix-config
ce852380). Upstream: **DeusData/codebase-memory-mcp#1304**, from fork `sini/codebase-memory-mcp`,
branch `spike/nix-function-header-defs`.

Measured on den-hoag, mode=full: **Function 48 → 1900, CALLS 56 → 1443, files-with-defs 8 → 258.**
Every gen-* lib improved. search_graph / trace_path / get_code_snippet are now worth running on Nix.
(Re-measured 2026-07-27 on the resumed session: **3094 nodes / 9279 edges, Function 2213**, CALLS 1461.)

**★ TRAP 1 — `get_architecture`'s `languages` field DOES NOT LIST NIX.** On den-hoag it reports only
YAML (3) and Python (1) while 2213 Nix functions sit in the same response. An agent told to "confirm
coverage via `get_architecture` before trusting a query" will read that field, conclude Nix is
uncovered, and fall back to grep — discarding the whole capability. **Confirm coverage with a
known-positive SYMBOL QUERY, never the languages list.**

**★★ TRAP 2 — CALLS edges MISS ATTRSET-MEDIATED CALLS, which is Nix's dominant cross-module idiom.**
Measured 2026-07-27:
```
trace_path runPrePass inbound → ZERO callers
grep runPrePass               → lib/default.nix:1097  prePass = stagedResolution.runPrePass { … }
```
The call is real; the graph misses it because the callee is reached through an imported attrset rather
than a bare identifier. **Positive control proving the direction works at all:** `trace_path fail
inbound` → 23 callers. So caller-tracing functions — it is specifically the cross-module attrset call
that is invisible. Related but distinct from the unshipped attrpath-qualification branch below (that is
def-side collision; this is call-side invisibility).

⇒ **"ZERO CALLERS" IS NOT EVIDENCE OF DEAD CODE.** Cross-check every zero-caller result with grep before
concluding anything, and absolutely before deleting. Within-file CALLS look reliable; cross-module CALLS
through an attrset are incomplete. **Good for structure** (what exists, what a function calls,
clustering, fan-in ranking); **not trustworthy alone for reachability or liveness.**

**★★★ TRAP 3 — `search_graph` RETURNS ONLY Function NODES, so a NON-FUNCTION `let` BINDING READS AS
ABSENT.** Measured: `byTarget` and `nativeEmissions` both exist (`lib/staged-resolution.nix:317` and
`:268`) and both return **0 results**. ⇒ **graph absence is uninformative for any non-function binding**,
and using it as the absence instrument on a `let`-bound carrier **manufactures false "dissolved"
verdicts** — the precise error an accumulator-dissolution audit would make. **Derive every absence claim
from grep.**

**★★ TRAP 4 — `git log -S <identifier>` IS BLIND TO BODY REWRITES.** `-S` counts *occurrences of the
string*; an identifier present once before and once after a rewrite yields **no commits**, so a genuine
dissolution reads as "never touched". Measured: `git log -S mergeMaps -- lib/compat/gather.nix` returned
only the creation commit, while `1211231` had in fact collapsed a nested accumulator fold into
`builtins.zipAttrsWith`. **Use `git log -G` (regex over the diff), or read `git show <commit> -- <path>`.**
This produced a false "provenance is wrong" finding this session — same "predicate that cannot match the
at-risk edit" class as the greps above.

**★★ TRAP 5 — Cypher complexity properties are on `f.file_path`, NOT `f.file`.** A clause
`WHERE f.file STARTS WITH 'lib/'` returns **0 rows silently** — a manufactured "nothing here". Control
before trusting any Cypher absence: `MATCH (f:Function) RETURN count(f), count(f.loop_depth)` (den-hoag →
2213/2213 populated).

**★★ THE LOOP/COMPLEXITY METRICS ARE NEAR-USELESS FOR NIX.** Kernel-wide, only 8 functions show any
recursion and **zero** have `loop_depth ≥ 2` — because Nix folds are `builtins.foldl'` *calls*, not
syntactic loops. Ranking accumulator-shaped code by `loop_depth` finds nothing. **The working instrument
is a grep predicate: does the per-element step READ the accumulator?** (`acc` referenced inside the
folded lambda). That discriminator found the A1 dissolution verdict and, applied kernel-wide, isolated
the only two order-sensitive folds in 13,337 lines. Promote it over `loop_depth` in any audit dispatch.

**★ WHERE THE GRAPH BEATS GREP — the `bt` field.** `search_graph` returns a **body-token list per
Function**. For a symbol that survives *by name* — the rename-only shape a name-grep flags as
un-dissolved — `bt` answers "what does this body actually do" in one call. It settled `argEnvWrap`
(→ `adaptArgs`/`configGate`) and `resolveParametric` (→ `wrapGatedFn`/`onResult`) as genuinely routed
rather than renamed. **Use `bt` as the first probe for shape questions; grep for absence.**

**NEVER pass `mode` to index_repository.** Default is `CBM_MODE_FULL`; auto_index sends no mode, so
real indexes are full. `fast`/`moderate` apply `FAST_SKIP_DIRS` (discover.c:53) — a NAME-based
directory skip containing `gen`, `media`, `docs`, `examples`, `scripts`, `tools`, `bin`, `build`.
Those are ordinary source directory names here, and a skipped directory is indistinguishable from
absent code. A fast-mode measurement made nix-config look like it had missing subtrees and cost real
debugging time. The hook now forbids the parameter (nix-config 780f77e3).

**Gates still shut — this is the #4 work.** Variables remain unconditionally dead for Nix:
- `cbm_is_module_level_p` → `get_module_parents` has no `CBM_LANG_NIX` case.
- `walk_variables_iter` is gated to YAML/TOML/INI/JSON; `extract_variables` otherwise walks only the
  file root's DIRECT children, which for a function-headed Nix file is just the lambda.
Design settled: mirror C++, which mints file-scope declarations only and never locals — so Nix mints
top-level bindings only, not every nested `enable = true`. That answers the flood question by
precedent rather than an arbitrary cap.

**Also on branch `spike/nix-attrpath-qualification`** (implemented, not yet PR'd): attrpath
modelling. Without it `setA.dup` and `setB.dup` collide onto one node — the second def and its CALLS
edges are silently dropped; `a.b.fn` mints name `a`; `"kebab-case"` keeps its quotes. Convention
adopted: name = leaf segment, QN = scope + leaf, matching C++ namespaces.

**Hard ceiling regardless:** nothing here evaluates Nix, so `prelude.genAttrs` never resolves across
a flake input, and a monorepo would not change that — nil cannot resolve a member across an import
even with a literal relative path ([[reference_nix_lsp_nil_vs_nixd]]). That axis belongs to gen-lsp
/ [[project_den_server_lsp_mcp]], which projects the EVALUATED option/aspect surface. Do not stretch
one to cover the other.

`nil` remains wired and complementary: documentSymbol / hover / file-local definition + references,
no workspace/symbol, no call hierarchy.

See [[feedback_verification_predicate_blindness]] — the original zero-coverage claim was correct
when measured and wrong two weeks later; re-measure before trusting a capability claim.

──────── reference_delta_nets.md ────────
---
name: delta-nets-paper
description: "Salvadori 2025 ∆-Nets — interaction nets for optimal parallel λ-reduction; in reference-catalog (background, not yet cited by any gen lib)"
metadata: 
  node_type: memory
  type: reference
  originSessionId: da7f1764-cf26-45c8-b710-b0c40f414e83
---

**Salvadori 2025, ∆-Nets: Interaction-Based System for Optimal Parallel λ-Reduction** (arXiv:2505.20314v3).

Added to papers archive 2026-05-31:
- PDF: `~/Documents/papers/den-architecture/reference-catalog/pdf/salvadori-2025-delta-nets-optimal-parallel-lambda-reduction.pdf`
- LLM text: `…/reference-catalog/markdown/salvadori-2025-delta-nets-optimal-parallel-lambda-reduction.md`

Placed in `reference-catalog/` (background refs) NOT `used/` (actively-cited-and-implemented) — no gen library cites it yet. If it grounds something, graduate to `used/` + add INDEX.md entry. `reference-catalog/summaries/` has condensed summaries for every other entry — summary for this one NOT yet written.

**Core ideas:** three agent types (fan, eraser, replicator); local graph-rewriting interaction rules on active pairs; **perfect confluence** (one-step diamond → every normalizing order gives same result in same #steps); replicator consolidates info previously spread across indexed fans + delimiters (constant memory on `(λx.x x)(λy.y y)`); core interaction system + non-interaction **canonicalization rules** + leftmost-outermost global order ⇒ Church–Rosser + optimality; λ-calculus is a projection of ∆-Nets.

**Relevance to den/gen theory neighborhood:** interaction nets / local rewrite rules / perfect confluence overlap [[project_gen_derive]] (Ehrig graph rewriting + NACs, RETE), [[gen ecosystem root repo]] gen-scope HOAG graph eval, and the den-v2 pipe-determinism open question (den-hoag #10 — Kahn multi-writer vs semilattice/Radul propagator confluence, see [[gen-theory-conformance-audit]]). Confluence-from-local-rules is the same shape as the pipe combine-algebra grounding still open in den-hoag ISSUES.md.

## Impact analysis (2026-05-31, workflow wys0yfjcy — 56 agents)

Report: `~/Documents/papers/den-architecture/gen-specs/DELTA-NETS-IMPACT.md`. 42 connections mapped → 14 verified (0 load-bearing, 3 grounding-upgrade-as-subtractions, 9 informed-by, 2 analogy-only) → 28 rejected. **Verdict: ∆-Nets is a FOIL, not a foundation** for den — destructive runtime λ-reduction transfers nothing to pure/lazy/build-time config assembly (no redex, no normal form, no reduction-order choice, no mutation). Value is negative/hygienic: a citable rejection criterion + anti-conflation lens.

**Actionable outputs:**
1. ✅ ADOPT (only adopt-worthy proposal): one-sentence Lévy "no wasted work" rationale in ECOSYSTEM/TERMINOLOGY/den-hoag — laziness discharges Lévy type-1 free, den's first-order acyclic graph never instantiates type-2 interior-sharing, so no reducer needed. Cite **Lévy 1978** (taxonomy) + **Barendregt 1987** (normal-order-discharges-type-1), NOT the ∆-Nets paper. Scope to "scope/attribute eval" not "den" (den embeds full λK via user modules).
2. ⚠️ PAPER-INDEPENDENT BUG in den-hoag #10: shipped collection combine is `a ++ b` (associative ONLY, gen-scope resolve.nix:201,259,335), NOT the commutative+idempotent semilattice #10's prose claims. Real determinism = pinned canonical traversal order (neronCollect self→imports→parent) + left fold. Fix #10 prose; swapping in a commutative/idempotent combine would silently reorder/dedup ordered collections (http-backends, pipe.append/fold/for) = correctness landmine. gen-scope already HAS a real semilattice (graph.nix overlay/Mokhov) but for graph STRUCTURE not collection VALUES.
3. ⚠️ Stale doc: kahn-1974 summary still says "Pipes ARE Kahn channels" — contradicts corrected den-hoag REFERENCE line 23; sync. Demote Kahn at den-v2 spec line 30 too (but drop bundled ∆-Nets foil).

3 proposals REJECTED for wedging ∆-Nets foil-citations where they don't belong (Streisand/provenance-pollution). 2 structural notes worth recording as informed-by cautionary witnesses: two-phase reduction ↔ den-hoag 3-layer stratified resolution; "refuse to unify into one ∆-agent" ↔ den-hoag "one namespace, three effect vocabularies, cross-phase=definition-time-error". Keep paper in reference-catalog (not used/); cite only as informed-by/contrast if it graduates.

## Generous "what could we build if forced" pass (2026-05-31, workflow wbmy2sl7r — 20 agents)

Report: `gen-specs/DELTA-NETS-GENEROUS-BUILDS.md` (companion to the skeptical DELTA-NETS-IMPACT.md). Inverted the audit: each "den lacks X" rejection → "build X gain Y". 12 forced-inclusion concepts architected. Bottom line: **a real seam, the wrong machine to exploit it, one net-zero-runtime prize.**

- ✅ **FLAGSHIP (only real-prize, weekend, ~50 LOC):** "Fleet Sharing Net" — den already computes shared-vs-duplicated discriminator (gate ctxId: check-dedup.nix:21 keys scope/identity.key; identity.nix:9 = provider/name+{ctxId}; trace.nix:156-157 STRIPS ctxId, mkBaseEntry never carries it = why no presence/diff view sees sharing). Re-expose ctxId (~2-line trace.nix edit) → auditable common-base-vs-per-host-drift observable the aspect-matrix presence view (fleet-views.nix:436) structurally cannot express. ∆-Nets contributes projection theorem + vocabulary, nothing reduces. HONESTY GATE: measures INTENSIONAL residual-record sharing NOT Nix eval sharing — label axis "residual-record sharing (intensional)" or it becomes the #13 overclaim.
- ✅ **REAL SEAM worth harvesting (pure-Nix refactor, NO ∆-Nets runtime):** compile-parametric.nix:60 re-sends resolve per binding → distinct closure per host → Nix thunk-sharing CANNOT collapse argument-independent residual = genuine Lévy type-2 waste. Fix = resolve residual once keyed by aspect identity + per-host attr-merge. ∆-Nets/Lévy = certifying THEORY not MECHANISM. Gate on Rung-2 measurement.
- ❌ **MIRAGES:** incremental net backend (CATEGORY ERROR — interaction nets give within-run sharing only, ZERO cross-edit; that's Salsa/Adapton, cite ∆-Nets nowhere); recursive-config DSL (needs unbuildable Church-encoding of module system; mkForce/override have no confluent λ-image; semi-decision procedure diverges like lib.fix).
- **Three walls block the ambitious parallel-net backend:** (1) WRONG LAYER — dominant fleet cost is N independent evalModules fixpoints (host.nix:53 nixosSystem), net only touches the cheap ~5% module list; (2) I/O GAP — HVM2 has no external-data ingress, config is data-heavy; (3) NO RUNTIME — ∆-Nets ships only a TS visualizer, HVM2 is a DIFFERENT system (2-ary labeled DUPs, not n-ary level-delta replicators). Plus: the expensive half (N evalModules) is ALREADY parallel one layer down via `nix build` across derivations.
- Runtime landscape: HVM2 (Lafont IC IR, Rust+C+CUDA, "compile target", no data ingress), Bend (GPU claim true for compute kernels, overclaim for configs), no pure-Nix IN reducer exists (writing one = semantics not perf). Spike ladder Rung0(re-expose ctxId)→1(flagship MVP)→2(measure residual cost, proves-or-kills)→3(pure-Nix oracle reducer)→4(interior-sharing refactor SHIP)→5(Tier-B moonshot, only if Rung2 justifies + runtime exists).

## den-hoag reframe (2026-05-31) — addendum in GENEROUS-BUILDS.md

Prior reports anchored on v1 nix-effects den (verifiable on disk); den-hoag materializes as HOAG graph over gen-scope. Checked gen-scope src + den-v2 spec: **shared upstream spine ALREADY shared** (_eval per (node,attr) eval.nix:22-37; inherit'/query thread self → reuse cache → walked once total — this VOIDS the prior "marginal combinator fix" finding, spine not re-walked per host). **Parametric base STILL duplicated per host** (build-nodes.nix:58-59 P partial fn throws >1 parent → distinct IDs base@p1..pN; forwardExpand evals __fn with each host's ctx, seen-set local to one scope — spec §325-345,§379-390; spec never explicitly says per-host = UNSPECIFIED but forced). So: Lévy type-2 seam survives v1→den-hoag UNCHANGED, just relocates compile-parametric.nix:60 → gen-scope per-scope __fn eval. Verdict holds, only artifacts move; flagship re-derives as gen-graph/gen-select query keyed by identity.key (not trace.nix edit); refactor = memoize parametric residual by aspect identity in forwardExpand. **Key synthesis: den-hoag does NOT auto-close the gap, BUT is the graph-native shape that cashes in a parallel/optimal interpreter — the ∆-Nets interior-sharing capability (shared fn × N args) IS the parametric-base-×-N-hosts seam, so interpreter-layer fix = principled general version of the den-layer hoist.** Interpreter is below gen-scope below den-hoag; gen-scope is pure Nix so den-hoag still single-threaded until interpreter changes.

## Parallel-Nix-interpreter feasibility (workflow ws9s61fj8 DONE) — doc: gen-specs/DELTA-NETS-NIX-INTERPRETER.md

Vic's angle: ∆-Nets as eval CORE of an alternative parallel Nix interpreter. **VERDICT: NO** — both adversarial stress tests survives=no. The reframe (own the interpreter) is LEGITIMATE and dissolves prior reports' IMPLEMENTATION objections (data ingress, no-runtime, AND string contexts → tvix reference-scanning, 144585/144586 agreement; set-union threading is comm/assoc/idempotent = parallelism-compatible). But thesis fails on THEORY the reframe can't touch: (1) OPTIMALITY IS ANTI-PARALLEL — perfect confluence holds only over LINEAR core (paper L208-213); optimal λI/λK needs SEQUENTIAL leftmost-outermost order "critical not only for optimality but to ensure normalization" (L567-569) + two-phase ∆K (L572-589) + non-local replicator merge (L542). (2) WORKLOAD MISMATCH — Nix eval is data-heavy/shallow-λ/IO-bound (//-merge IS module system ×millions); nets are parallel-COMPUTE machines; ∆-Nets best at higher-order sharing = what Nix needs least. (3) AMDAHL — ceiling = stdenv data-dependency DAG (structural, 3-4x demonstrated, engine-independent). Cost model: [LM99] (IN paper's bibliography) Θ(n) interactions need Ω(Γ(n)) bookkeeping (Ackermann); ∆-Nets relocates into level-deltas, doesn't escape; Lambdascope 60x slower than UNoptimized Haskell; BOHM lost to Caml ~10x on numerics.

**HEADLINE: parallel Nix already SHIPPED 2025** — Determinate atomic-thunk locking (flake show 4.1x, search 3.0x, multi-config 20s→<9s) + nix-eval-jobs process-level 60x (NixCon25) + lazy trees. **Winner = (E) Determinate today + (C) tvix/snix Rust bytecode VM long-game**; (A) ∆-Nets-core + (B) Nix→HVM2 lose decisively. ∆-Nets ships only a TS visualizer; its sound n-ary level-delta replicator advantage doesn't survive into HVM2 (2-ary labeled DUPs). den impact: changes ~nothing, does NOT auto-realize fleet-sharing (layer mismatch — intensional residual-record sharing lives above any reduction calculus), compile-parametric refactor (D1) stays necessary, obsoletes ZERO den machinery. Residual value = theory not engine: ~150-200 LOC conformance oracle + Lévy/Salvadori as certifying theory for D1. KILL-TEST: M0 microbenchmark (HVM2 attrset //-merge vs Determinate parallel CppNix, 1-2wk, predicted KILL). Prior "foil not foundation" verdicts SURVIVE the reframe.

## Actionable follow-ups: gen-specs/DELTA-NETS-FOLLOWUPS.md (2026-05-31)

Backlog of real items the analysis surfaced (independent of interpreter track). DO NOW (cheap, mostly paper-independent): A1 fix den-hoag #10 combine mis-statement (shipped a++b is associative-only NOT semilattice; correctness landmine), A2 sync Kahn summary + spec line 30, A3 Lévy "no wasted work" rationale (cite Lévy1978+Barendregt1987, scope to scope/attr eval). E1 gen-derive silent equal-priority+exclusive nondeterminism (dispatch.nix:74) → deterministic tiebreak (~5 lines). MEASURE-THEN-DECIDE: C1 measure parametric-base re-resolution cost under gen-scope forwardExpand (O(1)=mirage, O(N)=real, evalModules-dominates=wrong-layer) → gates D1 (interior-sharing refactor in forwardExpand, ∆-Nets/Lévy = rationale not mechanism) + D2 (Fleet Sharing Net observable, now a gen-graph/gen-select query keyed by identity.key NOT trace.nix edit; label "residual-record sharing (intensional)"). OPTIONAL: B1/B2 informed-by notes. DO NOT (F): combinator self.get fix VOID (spine already shared), incremental-net/recursive-DSL/Tier-B mirages, foil-citation proposals p1/p3/p4.

──────── reference_den_corpus_set.md ────────
---
name: reference_den_corpus_set
description: "den v1 config corpus — 19 external user configs + 13 den templates; nix-config is ONE witness, not the corpus"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 632f8478-1553-4f12-bc63-704719454fe2
  modified: 2026-07-27T16:48:53.231Z
---

**den-hoag's parity bar is den-surface expressibility across ALL den v1
configurations. Measuring `nix-config` alone is measuring one witness.** I made
that mistake repeatedly in one session and claimed "every corpus surface" off a
single config — twice.

## Where the configs are

**`~/Documents/repos/den-configs/`** — 19 external user configs:
`bugs-den` · `nixpedition` · `slashfiles` · `dotfiles` · `denix` · `nixos.den` ·
`quasigod-xyz-nixconfig` · `nixfos` · `andrewix` · `oceangreendev` ·
`adda-nixos-config` · `netadr` · `benbelov-nixconfig` · `gwenodai-nixos` ·
`illusaen-nix` · `drupol` · `nixos-private` · `megadots` · `louisb0`

**`~/Documents/repos/denful/den/templates/`** — 13 den-owned templates, i.e.
integration tests and demos: `flake-parts-modules` · `default` · `bogus` ·
`microvm` · `noflake` · `minimal` · `terranix-demo` · `ci` · `example` ·
`diagram-demo` · `nvf-standalone` · `scoped-import-tree` · `fleet-demo`

**`~/Documents/repos/sini/den-config`** — "sini's den demo", 6 nix files, points
at `github:vic/den` (Vic's fork, not `denful/den`). Small and a weak witness on
its own.

**`~/Documents/repos/sini/nix-config`** — the owner's live fleet. Rich, but ONE
config and the one everything over-indexes on.

## How to use it

- **An absence claim needs the set, not the instance.** "No live producer" /
  "no config does X" measured on `nix-config` establishes almost nothing about
  expressibility. The templates matter especially — they are den's own statement
  of what the surface *is*.
- **The templates are the cheapest breadth**: small, varied, and authored by den
  itself, so they encode intended usage rather than one user's habits.
- Related: [[project_corpus_eval_parity_bar]], [[feedback_den_surface_not_config]].

──────── reference_den_diagram_ir.md ────────
---
name: reference_den_diagram_ir
description: "den-diagram's fleet-ir.json is v1's own extracted graph — read it instead of reconstructing topology from den-hoag internals"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 632f8478-1553-4f12-bc63-704719454fe2
  modified: 2026-07-27T16:49:10.440Z
---

**den v1 already extracts its own graph.** `den-diagram` renders graphviz/mermaid
from an IR, so the inherent topology can be *read* rather than reconstructed from
den-hoag's internals. Use it before theorising about nodes and edges.

Artifacts (owner's fleet): `nix-config/diagrams/fleet/` — `fleet-ir.json` (~93K,
**large, do not cat**), plus rendered `fleet-dag` · `namespace` · `pipe-flow` ·
`pipe-sequence` · `policy-resolution`.

## IR shape

Top level: `direction` · `rootName` · `nodes` · `edges` · `entityInstances` ·
`scopes` · `pipes`.

**Measured on the owner's fleet (2026-07-27):**

```
nodes 843 · edges 1286 · entityInstances 31 · scopes 31 · pipes 15
```

**Nodes are NOT only entities** — `entityInstance`/`entityKind` are *fields* on a
node, and the roles overlap:

```
with entityInstance 774 · isProvider 585 · isPolicyDispatch 70
isParametric 39 · isScope 31
entityKind: host 740 · user 26 · environment 2 · flake-parts 2
            flake-system 2 · cluster 1 · fleet 1
```

`entityInstances == scopes == 31`, so **entity↔scope is 1:1** while
**entity↔node is 1:many** (740 host-kind nodes over few host entities — the
per-provider/per-class fan-out).

**Edges**: 586 labelled, 700 unlabelled. Labels are `provides` (541) plus named
pipe channels (`bgp-peers`, `k3s-nodes`, `thunderbolt-mesh-peers`,
`ollama-endpoints`, `prometheus-targets`). The 700 unlabelled carry **no** `pipe`
and **no** `crossHost` — structural, not channel traffic.

Pipe vocabulary (15): `age-secrets` `bgp-peers` `cache` `firewall` `host-addrs`
`k3s-nodes` `nix-builders` `ollama-endpoints` `persist` `persistHome`
`prometheus-targets` `resolved-users` `service-domains` `thunderbolt-mesh-peers`
`vault-peers`.

## Why this matters

The goal is *every entity a node, every relation an edge*. The IR shows what v1
actually produces, so it is the reference for whether den-hoag's topology is
correct — and it is a **second, independent** view of the same fleet, useful as a
cross-check against den-hoag's own probes.

Read node/edge **key sets and counters** with python/jq; never dump the file.
Related: [[reference_den_corpus_set]], [[project_den_hoag_features]].

──────── reference_denhoag_effects_audit.md ────────
---
name: denhoag-effects-audit
description: den-hoag effects-runtime audit (2026-07-24) — authoritative roadmap for dissolving the kernel's nix-effects holdovers into pure gen-graph; flagship A1 runPrePass accumulator + gen gaps G1-G6
metadata:
  node_type: memory
  type: reference
  originSessionId: 10b38931-f4a6-48ce-a371-03375e54d567
---

`papers/den-architecture/specs/2026-07-24-den-hoag-effects-runtime-audit.md` — the AUTHORITATIVE effect-shape roadmap (supersedes the effect axis of `route-through-gen-audit-catalog.md`, which was self-authored/self-exculpating). 74-agent adversarial workflow (steelman the "pure gen" defense, confirm only survivors): 62 raw → 25 confirmed + 2 hand-adjudicated, 33 refuted. Conservative + load-bearing. Drives [[feedback_best_framework_first]].

**Central finding:** kernel bloat real but CONCENTRATED (~14-16%, not a monolithic ported interpreter) — the central resolution loop IS genuinely gen-native (the two `scope.circular` fixpoints, gen-dispatch firing, gen-scope inherited/synthesized attrs; v1 drain.nix dissolved). Effect-runtime port = ~5 organs + a hand-rolled-gen tail.

**Tier-A organs (fix first):** A1 ★FLAGSHIP `staged-resolution.nix:112-262 runPrePass` = the ONE true state-accumulator (parent phase writes a child root's `relationBindings` slot, read later — inter-phase state feeds forward) → dissolve into gen-resolve `reference` + gen-scope inherited attrs; **subsumes F3's accessGroups drop** + A2 manual schedule + A5 `__denSuppressedPolicies` marker + B15 settings-walk. A3 `reach` hand-rolled reachability (→G1). A4 `recBucketsOf` eager class bucket (control-flow gen-native, VALUE-shape is the defect → gen-edge collected-union; = [[project_class_bucket_holdover]]). A5 suppression `__`-marker (→G6). A6 `producerConfigs` UNVERIFIED (critic-caught).

**Gen gaps G1-G6 (what FORCED the holdovers — build gen-side FIRST):** G1 `reachableWitness`/`foldReach` (edge-label + suppression-aware ordered traversal), G2 `expandPreorder` (payload DFS closure, lazy edges), G3 declared-stratum policy vocab (retires the fire-and-observe probe — highest leverage), G4 terminal-crossing arg-env transform (gen-edge/gen-bind), G5 declaration-site derived-channel identity (gen-pipe), G6 policy-suppression gate over scope-subtree (retires the last kernel `__`-marker — highest leverage). G1+G2 could ship as one traversal combinator. Overlap gen-link.

**★ Confidence ceiling / open exposure (§8 — VERIFY FIRST):** ~9,100 of 10,930 compat LOC NEVER reviewed (only compile.nix clustered) — prime suspects gather.nix/bridge.nix/ingest.nix/registry.nix/pipe.nix (grep foldl'/genericClosure/recursive go); + A6 producerConfigs; + default.nix read-back. Trust the CONFIRMED set (conservative) over the LOC ranges. Tier-B tail (§5): B12 presentAtKind (the F2-shipped code) → gen-graph ancestorsOf; B16→scope.ancestors + B17→gen-graph.cycles verbatim drop-ins; etc.

──────── reference_den_remotes.md ────────
---
name: den-remotes
description: "local ~/Documents/repos/den remote map — origin is denful/den (canonical), vic/sini are forks"
metadata: 
  node_type: memory
  type: reference
  originSessionId: b8c4b977-4c52-4544-a5b8-3b4a734913e1
---

In ~/Documents/repos/den (2026-06-25, repo moved vic/den → denful/den): `origin` = denful/den (canonical; gh default repo set to denful/den), `vic` = vic/den (old origin, preserved for reference), `sini` = sini/den, `lazy` = local den-lazy path. `main` tracks `origin/main`. When the user references github:sini/den/<branch>, fetch/compare against the `sini` remote (origin's same-named branches can be stale/diverged).

──────── reference_gen_ci_asserttests_expectederror.md ────────
---
name: reference_gen_ci_asserttests_expectederror
description: "gen CI checks.default uses assertTests (expr==expected only), NOT nix-unit — expectedError/throw-message tests crash it"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9ca7f5ed-7ae4-42ab-8273-f2cde8d631a2
---

gen ecosystem CI (gen.lib.mkCi) has TWO non-equivalent test paths:
- `nix build .#checks.x86_64-linux.default` builds `assertTests` in gen/ci/flakeModule.nix — a homegrown `if t.expr == t.expected then true else throw …`. Reads `expr`/`expected` ONLY. A test whose `expr` THROWS with no short-circuiting `expected` forces the throw to top level and crashes the WHOLE check build.
- The REAL nix-unit (`nix-unit --flake ./ci#tests`, run by the pre-commit `ci` hook + devshell `ci` cmd) DOES support `expectedError = { type = "ThrownError"; msg = "…"; }`.

Consequence: `expectedError` / throw-MESSAGE assertions are INCOMPATIBLE with the checks.default gate (and thus GitHub CI which builds checks). Standing gen-lib convention: error-message content is unassertable in pure Nix from the check gate — `(builtins.tryEval expr).success == false` is the only portable throw-pin (boolean, can't see the message). Found during gen-graph labeled-query arc 2026-07-16; parked as a potential upstream item (make checks.default honor expectedError, or converge the two paths). See [[project_gen_graph_labeled_query]] [[reference_gen_docs]].

Formatter note (same repos): gen-graph ROOT flake has no `formatter` output (`nix fmt` errors); the ci/ flake DOES expose `formatter` (treefmt-nix) and the pre-commit treefmt hook formats on commit. Use standalone `nixfmt` (rfc-style) on .nix files + rely on the hook; `./ci#formatter` for markdown (mdformat-gfm).

──────── reference_gen_docs.md ────────
---
name: gen-ecosystem-root-repo
description: "Canonical ecosystem hub — TERMINOLOGY.md, ARCHITECTURE.md, README.md — at ~/Documents/repos/sini/gen/ (github:sini/gen). Renamed from gen-docs 2026-05-26."
metadata: 
  node_type: memory
  type: reference
  originSessionId: b5e2d5ef-3352-4d2e-bf50-79c8c043b3fd
  modified: 2026-07-26T04:33:46.697Z
---

gen ecosystem root at `~/Documents/repos/sini/gen/` (github:sini/gen) contains canonical ecosystem-wide documentation. Moved 2026-07-25 from `~/Documents/repos/gen/` — every clone now sits under the parent matching its git remote root, i.e. `~/Documents/repos/sini/<repo>` (see [[reference_gen_repo_clone_location]]).

- `TERMINOLOGY.md` — unified vocabulary for the gen libraries + den v2, with academic provenance. Supersedes `~/Documents/papers/den-architecture/specs/2026-05-24-unified-vocabulary.md`.
- `ARCHITECTURE.md` — how the libraries compose: dependency graph, data flow, accessor chain, convergence-loop coordination, performance model, design constraints.
- `README.md` — ecosystem overview, library table, core ideas, theoretical foundations.

Created 2026-05-26. Promoted from gen-docs to gen after gen-algebra rename freed the name.

**Current lineup (2026-07-01):** hub `mkGenLibs` = prelude, algebra, scope, graph, bind, schema, aspects, select, **dispatch** (renamed from gen-derive; the pure dispatch STEP), resolve — plus standalone gen-rebuild + gen-vars. The convergence LOOP lives in gen-resolve (gen-scope.circular), NOT in gen-dispatch — see [[project_gen_resolve]] + [[project_gen_package]]. These three hub docs were refreshed 2026-07-01 for the rename + loop⊥step split.

NOTE: `~/Documents/repos/genx` is OLD/DEPRECATED work (not part of the live ecosystem) — ignore it, don't flag it.

──────── reference_gen_gap_integration.md ────────
---
name: reference_gen_gap_integration
description: Consumer integration contracts for the 6 gen-gap primitives (G1-G6) built to dissolve den-hoag's effect-shape hand-rolls — the API + load-bearing caveat each imposes when den-hoag wires it, with ship status/commits. For the den-hoag agent doing the route-through.
metadata:
  node_type: memory
  type: reference
  originSessionId: a220e78f-5ac2-4b6c-b417-3d65c0b01fcd
---

The 6 gen-side primitives from [[project_denhoag_effects_audit]] were BUILT (2026-07-24, one agent per repo, TDD + independent adversarial review each). These are the CONSUMER CONTRACTS for wiring them into den-hoag (the route-through that deletes the hand-rolls). Each primitive is additive/back-compat in its gen lib; the caveats below are what den-hoag must honor.

**Ship status:** ALL SIX PUSHED to main, each TDD'd + independently review-SHIP + papers REFERENCE committed. gen-graph @231b319, gen-dispatch @8f537ec, gen-bind @268d401, gen-pipe @5350930, gen-scope @ceabe5e. Pull any now; the den-hoag route-through (deleting the hand-rolls per each consumer contract below) is the remaining den-hoag-side work.

## G3 — gen-dispatch declared-stratum (github:sini/gen-dispatch @8f537ec, PUSHED)
API: `mkRule { produces ? [tag] }`; `groupOf`/`producesOf` (read stratum WITHOUT firing); `deriveGroup (tag->group) rule` (definition-time classify+stamp `group`; aborts NAMED on kinds-span-multiple-groups / explicit-group≠classified / unknown-kind); `mkActions.groupOfKind`. `dispatch` HONORS a declared rule → skips fire-and-classify.
★ CONTRACT (load-bearing, trust model = mirrors gen-resolve trusting `stratum`): `produces` is a TRUSTED assertion. **den-hoag MUST run `deriveGroup declare.stratumOfKind` at compile time to stamp+validate `group` BEFORE handing rules to dispatch** — dispatch trusts the declaration blindly and SILENTLY mis-stratifies a lie (no diagnostic). deriveGroup validates group≡produces but NOT produces≡body (a body emitting a kind outside declared produces is caught by neither — accept, same as gen-resolve). Do NOT pass `produces = []` (non-null → treated declared/skips-validation, but derives no group).
Retires: concern-policies.nix `probeOf` (155-172) + `mkExpanded` (226-242). A value-conditional policy still yields one rule per stratum, but each is a DECLARED slice (produces filtered to that stratum), NOT a blind N-way fan-out. Bare-function corpus policies that can't declare their kinds stay den-hoag's own concern.

## G1+G2 — gen-graph preorder traversal (github:sini/gen-graph @231b319, PUSHED, lib/preorder.nix)
API: `foldPreorder { roots; key; expand; acc; visited? }` (THE primitive: pre-order DFS fold, caller-owned acc + first-occurrence visited; null key = unguarded); `expandPreorder { roots; key; edges; resolve?; emit?; seen0?; nodes0? }` (payload closure; `edges` reads the RESOLVED payload → demand-generated successors); `foldReach { roots; edges; target; project; itemKey; visited0?; seen0?; nodes0? }` (labeled/suppression-aware reach; `project edge` exposes the edge; dual key sets = target-vertex guard + item-key dedup).
CONSUMER MAPPINGS (review-verified faithful):
- `reach` (resolved-aspects.nix:333-463) → `foldReach`: visited0={id}, seen0=structural keys, nodes0=structural nodes, per-edge classFilter via `project`, negative suppression baked into `edges`, itemKey=`.key`. Byte-faithful.
- `forwardExpand` (resolved-aspects.nix:111-150) → `expandPreorder`: resolve=parametric-invoke (lazy edges), emit receives BOTH frame + resolved payload. Byte-exact order.
- `aspectIncludeWalk` (compat/compile.nix:1263-1364) → `foldPreorder`. ★ USE THE UNIFORM-FRAME MAPPING, not classifyIncludes-then-children (which REORDERS — v1's `go` INTERLEAVES: a non-policy include recurses inline before a later sibling policy). Uniform-frame = treat policy/bareFn/aspect as one frame type, classify in `expand` by type: policy → append rec, `children=[]`, `key=null` (unguarded/per-occurrence); aspect → `children = includes ++ walkableChildKeys`. Reproduces the interleave EXACTLY.
★ `foldReach` is FIRST-EDGE-WINS-PER-TARGET (vertex guard drops a 2nd edge to the same target entirely, incl its projection) — faithful to den-hoag `reach` (same behavior), but two same-target edges with different filters do NOT compose their slices.

## G4 — gen-bind arg-env transform (github:sini/gen-bind @268d401, PUSHED, lib/arg-env.nix)
Owner ratified the CHARTER WIDENING: gen-bind = "binding injection + terminal-crossing arg-env"; arg-env.nix is the sole deliberately-exempted module-EVALUATING file (P1 no-nixpkgs-dependency stays global; P2 "never operates the module system" relaxed for this one crossing file). Placement decided KEEP-in-gen-bind (crossEval imports nothing — operates a threaded lib; no real boundary moves; gen-merge rejected — byte-identity on arbitrary opaque slices needs the terminal's real lib).
API: `adaptArgs { adapt, module } -> args -> module` (inject `_module.args = adapt args`; PURE, module-producing); `crossEval { lib, module, specialArgs?, moduleArgs?, absorb? } -> evalModules result` (nest opaque slice in the terminal's THREADED lib, freeform absorber; read `.config`); `configGate { gate, module, adapt?, absorb? } -> args -> module` (= `mkIf (gate args) (crossEval …).config`).
★ BOUND (module-system fundamental, tested): configGate gates CONFIG via `mkIf`, NEVER `imports` → CANNOT conditionally DECLARE an option (the `imports←guard(options)←options←imports` cycle); the common case (guard reads an option declared ELSEWHERE) is SOUND. Nested crossEval strips `_module` from `.config` → the OUTER terminal must hold the gated keys (real host options in den-hoag).
CONSUMER MAPPING (output-modules.nix:560-765): argEnvWrap case-2 → `adaptArgs`; case-3 (eval-time guard ± adaptArgs) → `configGate`; placeRemapped → `crossEval` then den-hoag PLACES (setAttrByPath route.at + removeAttrs [_module warnings assertions]). Placement/content-strip stay den-hoag. forwardModulesFor's item-applied guardApply is a CONTENT-gate (not this eval-time config-gate) → partial fit, out of scope.

## G5 — gen-pipe declaration-site id (github:sini/gen-pipe @5350930, PUSHED, lib/operators.nix)
API: deriving-op record gains optional `site`; `mkDerived` folds `id = if site==null then "<input>.<op>" else "<input>.<op>#<idOf site>"` (idOf duck-types registry-entry id_hash / string / int).
★ CONTRACT: `site` is a caller-threaded STRUCTURAL token — fully-automatic disambiguation is IMPOSSIBLE in pure Nix (breaks value sharing; lambdas unhashable). Invariant = "share iff same derivation": same value+site dedups everywhere; distinct decls with distinct sites never collide; site propagates through input-id stacking → distinct at EVERY depth. `site` NEVER leaks into the final channel NAME (compose recomputes `<input>.<op>.<declIndex>`). `site=null` ⇒ byte-identical (back-compat).
CONSUMER (default.nix:1368-1422): pass `site = <stable per-pipe-declaration key>` on each deriving stage in compat/pipe.nix `compilePipe` — the owning policy/aspect entry's `id_hash`, or the pipeOp's `imap0` positional index (pure/deterministic, NOT the mutable `ord` fold-accumulator). Deletes `renameChain`/`ord`/`udBaseCount`/`renamedPipes`; `derivedBaseNames` terminal-id→name still resolves.
★ REVIEW FLAGS (review-gen-pipe): (1) dedup is LOAD-BEARING — SAME site on separate constructions = ONE node; two independent pipe decls that must NOT merge need DISTINCT sites even if structurally identical (a per-decl positional index gives that); a genuinely shared derivation must carry the SAME site everywhere. (2) PLACEMENT — one site at each chain ROOT propagates to all depths via input-id stacking; but if two chains share a prefix and DIVERGE, put sites at the divergence point, not just the root. (3) keep site tokens (and base channel names) free of `#` — hex id_hash / int indices are safe; the opaque-string-id model aliases on `#`/`.` under crafted names (N1, PRE-EXISTING latent, unreachable for intended callers). (4) `idOf` interpolates id_hash as a string — non-string id_hash would throw (N2; hex in practice). site never leaks into channel NAMES (E4b / name-reads unaffected).

## G6 — gen-scope inheritSet (github:sini/gen-scope @ceabe5e, PUSHED, lib/resolve.nix)
GAP FINDING: the accumulation MECHANISM already existed — `inheritAll { extract }` (P-edge parent-chain, cycle-safe, demand-driven; den-hoag `inherited-context` already uses it, structural.nix:43). The genuine gap was the SET-discipline sibling (inheritAll is ordered-list, keeps dups).
API: `inheritSet { extract, eq ? (a: b: a == b), _visited ? {} } self id -> [value]` (own ∪ every ancestor's, down P-edges, deduped by `eq`, nearest-first order retained, delegates the walk to inheritAll).
CONSUMER (retire `__denSuppressedPolicies`): declare a kernel attribute `suppressedPolicies = scope.inheritSet { extract = node: node.decls.suppressedPolicies or []; }` fed from a TYPED decls slot (not the `__` marker); gate reads `self.get id "suppressedPolicies"` instead of `ctx.__denSuppressedPolicies` (default.nix:1050 / compat/compile.nix:85).
★ BONUS CORRECTNESS: inheritSet gives true self∪ancestors UNION → fixes the latent bug where the current single-key `//`-shadow only works because suppression is sibling-isolated to ONE root (`inherited-context` merges `layer // acc` at structural.nix:56, so a single-key list `//`-SHADOWS across two suppressing ancestors, dropping the farther). Multiple suppressing ancestors at different depths now compose, matching v1 dispatch-policies.nix:15-33 by construction.
★ WIRING CAVEATS (review-gen-scope, downstream in den-hoag — not defects in the primitive): (1) the typed `suppressedPolicies` decls-slot must NOT re-leak into generic inherited-context — attr 1 (structural.nix) strips only `__edges/__containment/__coords`, so either ADD the slot to that strip list OR read the attribute from an off-decls source. (2) the gate `gateSuppression` reads `ctx.__denSuppressedPolicies` (compat/compile.nix:85) — switching to a typed attribute needs ctx-injection of `suppressedPolicies` at dispatch (attr 4). (3) do NOT conflate with `reachableFrom` at identity.nix:62 — that is instance fill-acyclicity, UNRELATED; inheritSet's own cycle-safety comes from inheritAll's `_visited`. The half-(b) firing-gate reachability (if used) is a separate mechanism, not that call site.

Links [[project_denhoag_effects_audit]] [[reference_gen_lib_capability_map]] [[feedback_route_through_gen_native]] [[project_denhoag_kernel_primary_surface]].

──────── reference_gen_lib_capability_map.md ────────
---
name: reference_gen_lib_capability_map
description: "gen ecosystem capability map — 21 libs, one line each (what to REUSE before building). The reuse-scan lookup for [[feedback_reuse_scan_before_build]]"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9ea92e54-1c53-4d70-b148-681defc591a4
---

The reuse-scan lookup: **before building any engine/mechanism, check here first.** Roles are durable; verify file:line against current code before asserting. Full detail: gen/ARCHITECTURE.md + gen/README.md ([[reference_gen_docs]]).

## The evaluation/resolution stack (the "engine" — most-often-reinvented; check HERE first)
- **gen-resolve** — ★ THE demand-driven **stratified-fixpoint conductor** (the convergence LOOP, `gen-scope.circular`; cold+warm). Equation vocabulary: `attr` (per-node value) / `nta` (bounded-NTA node synthesis, Vogt'89) / `cascade` (folds pre-declared layers) / `reference` (RAG requires→provides value-composition). `buildSchedule` = N-stratum order + strictly-below assert. **If you're about to build a "stratified fixpoint / lattice-Datalog / resolution engine" — it's this, extend it.**
- **gen-scope** — the demand-driven **HOAG/RAG attribute-grammar evaluator** ("Nix IS the evaluator", `lib.fix` lazy memo = free memoization + cycle detection). `buildNodes`, `queryReverse`, `eval`. The evaluation substrate gen-resolve drives.
- **gen-dispatch** — the pure relational **dispatch STEP** (one stratum's rule eval). loop⊥step split: gen-resolve = loop, gen-dispatch = step.
- **gen-graph** — accessor-based **graph queries**: `labeledFrom`/`query`/`regex` (Brzozowski labeled calculus), `fixpoint`/`seededFixpoint` (monotone semi-naive), **`transpose`** (reverse edges — Mokhov 2017), `order`/`phaseOrder`, `transitiveReduction`, genericClosure BFS. **Reverse reads + reachability fixpoints already here.**
- **gen-algebra** — pure primitives: **`foldLayers`/`foldLayersTraced`** (the ordered-monoid discipline folds + traced provenance), `record` (Leijen/Bracha), `intensionalEq`, search monad. **The lattice/merge folds are here — don't hand-roll a parallel layered fold.**

## Concern / L2 libs
- **gen-edge** — edge algebra (S,T,P,M) + **the materialization terminal** (`toposort`+`materialize`) + parity trace E.
- **gen-product** — **graph products** over accessor-graphs (cartesian/tensor/strong/lexicographic adjacency; cells/slices/fiber/restrict/quotient; `containmentChain` = subset powerset + count-major linearization). The matrix/coordinate engine (feature #2). NOTE: the subset lattice is emitted as a sorted LIST, not adjacency — `latticeGraph` accessor was genuinely absent as of 2026-07-20.
- **gen-settings** — layered settings folds (Spike-5; identity refs; per-entry-lazy provenance; `resolveAll`).
- **gen-demand** — typed **cascade**: downward-only kind DAG, SPAWNS sub-demands (route→secret+connect), groupBy dedup, provenance. The DAG-aggregation fragment (no lattice, fire-once); being absorbed into gen-resolve `nta`+edge (2026-07-20). ★ its SPAWNING cascade ≠ gen-resolve's layer-folding `cascade` — don't conflate.
- **gen-pipe** — scoped channels / dataflow DAG (`append`/`fold`/`for` = ORDER-BEARING monoids — never ACI-ify; class tags; static-config-dependence taint).
- **gen-class** — class-share (partition/contract/apply/gate + `applyCoreFixed` fixed-input core injection).

## Module-system substrate + boundary + selectors + standalone
- **gen-prelude** — pure nixpkgs-lib-free utility base (toposort, partition, genAttrs).
- **gen-types** — structural checker (`verify: v→null|err`).
- **gen-merge** — byte-mode `evalModuleTree` (pure `lib.evalModules` reproduction) + the 14-field nixpkgs optionType protocol (pure types mount in real nixpkgs evalModules).
- **gen-schema** — typed registries + `id_hash`/`edgeId` identity + `keySemantics` per-key category surface.
- **gen-aspects** — aspect type system (`aspectSubmodule` generic dispatch over keySemantics; A-IDENT `.key` = intrinsic path identity).
- **gen-select** — selector/predicate algebra (`sel.entity`/`sel.kind`, `intensionalEq`). Use for production `from`/`where` predicates.
- **gen-bind** — inject bindings into NixOS modules (merge strategies, lazy contracts, `wrapAll`, `__configThunk` deferral).
- **gen-flake** — the SINGLE nixpkgs boundary (`compose`/`injectArgs`/`mkSystems`; `mkSystemTerminal{evaluator}`; value-injection not type-driving).
- **gen-rebuild** — pure-Nix incremental rebuilder (standalone).
- **gen-vars** — pure vars/secrets lib (standalone).

──────── reference_gen_repo_clone_location.md ────────
---
name: reference_gen_repo_clone_location
description: All gen-* libraries clone under ~/Documents/repos/sini/ (not ~/Documents/repos/)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 64d6f7c2-8cd7-4b89-9d3f-643302e3b3cf
  modified: 2026-07-26T04:33:52.923Z
---

All gen ecosystem libraries (gen-resolve, gen-graph, gen-product, gen-algebra, gen-schema, etc.) clone under `~/Documents/repos/sini/<lib>`, NOT `~/Documents/repos/<lib>`. Same parent as den-hoag (`~/Documents/repos/sini/den-hoag`). When a gen lib is only a flake input (store src), clone it here for local dev/TDD and test den-hoag against it with `--override-input den-hoag/gen-resolve ~/Documents/repos/sini/gen-resolve` (gen-resolve is transitive under den-hoag's `path:..` ci input).

The rule is: clone parent directory mirrors the git remote root (`github:sini/*` → `~/Documents/repos/sini/*`). This covers the ecosystem hub repo `gen` itself, which moved here 2026-07-25 — see [[reference_gen_docs]].

All 24 repos (`gen` + 23 `gen-*`) plus den-hoag are indexed in the codebase-memory knowledge graph, each as its own project named `home-sini-Documents-repos-sini-<repo>`; pass that as `project` to `search_graph`/`trace_path`/`query_graph`. Cross-repo-intelligence mode yields 0 edges — it matches HTTP/async Routes/Channels, which pure-Nix libs don't have — so cross-lib call chains must be traced per-project, not through the graph.

Related: [[reference_den_remotes]], [[project_gen_resolve]], [[reference_gen_docs]], [[reference_gen_lib_capability_map]].

──────── reference_nix_lsp_nil_vs_nixd.md ────────
---
name: reference_nix_lsp_nil_vs_nixd
description: "Nix LSP = nil (NOT nixd) since 2026-07-26 — nixd hung the session twice on untimed worker RPC; nil is hang-safe, better documentSymbol. Neither does cross-file or workspace/symbol."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6c794dd1-6fb3-4dca-9a1e-38b9a1798342
  modified: 2026-07-26T05:55:22.203Z
---

The Nix language server is **nil**, switched from nixd 2026-07-26 because nixd hung this session twice.

Config chain: source `nix-config/modules/den/aspects/apps/dev/ai/claude.nix` (`programs.claude-code.lspServers.nix`, committed @6c4f0977) → generated `~/.claude/skills/claude-code-home-manager/.lsp.json`. Needs a home-manager rebuild + Claude Code restart to take effect.

## Why nixd was dropped

nixd resolves options/nixpkgs data by blocking the request handler on an untimed `std::binary_semaphore::acquire()` (`Controller/Hover.cpp:34-46`, same pattern `Controller/Definition.cpp:180-190,215-218`), held under `OptionsLock`. A worker that never replies hangs the client forever — fatal for an agent that cannot cancel. Separately, nixd registers **no** `workspace/symbol` handler and drops the request silently (no `MethodNotFound`), hanging indefinitely and wedging the server so every later request fails with `Cannot send request to LSP server '…': server is running`.

nil keeps its `nix` subprocess calls in `nix-interop/` as background, debounced, cancellable loads feeding a salsa snapshot; requests read the snapshot. Supports `$/cancelRequest`.

## Measured, both servers, same 6 probes (2026-07-26)

| probe | nixd 2.9.1 | nil 2025-06-13 |
|---|---|---|
| `documentSymbol` compile.nix | 187ms but **126.9KB** full parse tree (every identifier/string/boolean), auto-persisted to file | **real hierarchical outline** of named bindings, ~250 lines, returned inline |
| `goToDefinition` same-file `let` | ✅ `:20:3` | ✅ `:20:3` |
| `goToDefinition` across `import` | ❌ no definition | ❌ no definition |
| `findReferences` | ✅ 2 refs, "across 1 files" | ✅ same |
| `hover` on attrset attrname | ⛔ **ran 2min+, killed** | ✅ **instant**, plus inferred signature `{ classNames: ?, quirkChannels: ? } → ?` |
| `workspaceSymbol` | ⛔ **hung forever, wedged server** | ✅ clean immediate `No such method workspace/symbol`; server healthy after |

Diagnostics: nil emitted 1 (`Unused binding`) where nixd emitted 9 — nil drops the `builtins.`-prefix style nits, better signal-to-noise.

## Standing rules

- `workspaceSymbol` on `.nix` returns nothing useful on either server — nil at least fails fast. Don't reach for it.
- **Cross-file analysis does not exist.** nil states it outright (`docs/features.md`: `- [ ] Cross-file analysis.`); nixd needs eval providers and even then resolves evaluated attrpaths, not the import graph. Both are intra-file lexical scope only. For cross-file/cross-lib symbol work use grep/Read.
- `documentSymbol` on nil is now genuinely useful for mapping a large file — prefer it over grepping for a file's structure.
- Issuing multiple LSP calls in ONE block caused the confusing `server is running` error under nixd. Not retested under nil (all probes were sequential); keep one-call-per-block until proven otherwise.

## How to use the LSP tool on .nix

**Coordinates are 1-based for BOTH line and character**, as shown in an editor. Verified: `gated-aspects-type.nix` line 44 is `        (keySemanticsLib.mkClassChannelSemantics {` — 8 spaces, `(` at char 9, so the identifier starts at char **10**. Pointing at char 10 resolved; the tool needs the cursor ON the symbol, not near it.

**The working loop — `documentSymbol` first, then position-based ops.** `documentSymbol` needs no meaningful line/character (pass `1`/`1`) and returns the file's whole named-binding tree. Use it to find the symbol and its line, then run the position ops.

**Gotcha: `documentSymbol` returns lines but NOT columns** (`translateAspect (Variable) - Line 671`). To get the character for a follow-up call, either `grep -n` the line or use indent+1 — a binding indented 2 spaces sits at char 3. That heuristic held for every probe: `mkCnf` at `36:3`, `keySemanticsLib` at `20:3`, `mkClosedAspectsType` at `68:3`.

Symbol kinds in nil's output are Nix-shaped: `Variable` = a `let` binding or top-level definition, `Field` = an attrset attribute.

**Which operation for which question:**

| question | call | point the cursor at |
|---|---|---|
| what's in this file / where is X defined | `documentSymbol` | anywhere (`1`,`1`) |
| what does this identifier refer to | `goToDefinition` | the **usage** |
| what uses this binding | `findReferences` | the **definition** |
| what shape is this function | `hover` | the definition — returns an inferred signature |

`findReferences` returns usages only, **excluding** the definition itself (`mkCnf` at 36:3 → 2 results, both usages).

**Free diagnostics.** Any LSP call on a file surfaces that file's diagnostics as a side effect — a lint pass for no extra call. That's how `compile.nix:892:9 Unused binding` surfaced.

**When NOT to reach for it.** Anything crossing a file boundary: `import`ed attrsets, flake inputs, another gen lib. Both servers are intra-file lexical scope only, so use grep/Read there — the LSP will return "No definition found" and cost you a round trip.

Neither server closes the cross-lib symbol gap — see [[reference_gen_repo_clone_location]] for why the codebase-memory graph doesn't either (no Nix symbol extraction at all).

──────── reference_nixunit_regex_stackoverflow.md ────────
---
name: reference-nixunit-regex-stackoverflow
description: "nix-unit stack overflow from lib.hasInfix / builtins.match \".*x.*\" over big readFile'd source — libstdc++ std::regex backtracking; fix = splitString"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 99ecf393-ca15-4ac9-98fd-cdeb7ad76318
---

**Symptom:** a gen-lib's `nix-unit --flake .#tests` fails `error: stack overflow (possible infinite recursion)` at default 8MB stack, while `nix build .#checks` PASSES and `ulimit -s unlimited` → all pass. NOT infinite recursion — a genuine deep-but-finite C-stack blow.

**Root cause (gen-schema, 2026-07-16, owner's debug agent):** a PURITY/source-scan test doing `lib.hasInfix tok src.code` where `src.code` is a whole readFile'd lib file (15-18KB, e.g. instance.nix/entry-type.nix). nixpkgs `lib.hasInfix` = `builtins.match ".*${infix}.*" content` — the leading+trailing `.*` on a long string triggers libstdc++ `std::regex` **catastrophic backtracking** (recursion depth ∝ string length). Only tips over under **nix-unit's forcing** (it forces each expr from deep inside its own recursive C++ tree-walk → less headroom); plain `nix eval` / the `.#checks` derivation force from a shallower stack → headroom (the exact `.#checks` reason is the one under-nailed footnote).

**Smoking-gun bisection:** purity-suite-alone overflows; same suite with `hasInfix tok "tiny"` (short string) PASSES; skipping the 2 biggest lib files PASSES → isolates *string length in the regex*, not cumulative depth, not nesting, not gen-merge's pure `evalModuleTree` (H3 REFUTED — the nesting suite exercises evalModuleTree deeply and passes alone).

**Red herring:** the overflow SURFACES at `nesting.test-nested-user-shell` — but that's alphabetical print-order (`n < p`); purity is the NEXT suite, whose eval actually blows.

**FIX (root-cause, no ulimit):** `builtins.length (lib.splitString tok src.code) > 1` — `splitString` uses `builtins.split (escapeRegex sep)` (a literal, no `.*` anchors → linear scan, no backtracking). Verified 405/405 at default 8MB. Then DROP every `ulimit -s unlimited` workaround.

**How to apply:** audit ecosystem-wide for `lib.hasInfix` / `builtins.match ".*x.*"` over `readFile`'d source (den-hoag's ci purity guards likely share the pattern; den-hoag/gen-schema CI runners set `ulimit -s unlimited` as a symptom-mask that this retires). Related: [[project_gen_package]].

──────── reference_nixunit_test_prefix.md ────────
---
name: reference_nixunit_test_prefix
description: "nix-unit detects tests by `test` name-prefix; bare-leaf target silently runs 0/0 (false-pass); single-test selection needs testSingletons wrap"
metadata: 
  node_type: memory
  type: reference
  originSessionId: de359d66-0918-4d68-a1b9-93cc19ead516
---

nix-unit (≤2.35.0, empirically probed) detects a test by the **`test` name-prefix of a group child**, NOT by `expr`/`expected` presence. It walks the target attrpath; a node is a test leaf iff its key starts with `test`, else it's a group it recurses into. There is NO `--match`/`--filter`/`--only` flag.

**The footgun:** the target attrpath ENDPOINT is always treated as a GROUP. So `nix-unit --flake .#tests.<suite>.<test>` points at a bare leaf `{expr;expected;}` → recurses into `expr`/`expected` → finds no `test`-prefixed child → prints **`🎉 0/0 successful`**. Single-test selection SILENTLY FALSE-PASSES (worse than an error). Proof: `{s={only={expr;expected;};};}` → 0/0; `{s={test-only={…};};}` → 1/1.

**Fix (in gen mkCi):** the `testSingletons` output — `flake.testSingletons.<suite>.<test> = { <test> = leaf; }` — wraps each leaf as a named `test`-prefixed child of a fresh group, so `--flake .#testSingletons.<suite>.<test>` runs 1/1. The `ci` devshell routes a `.`-containing arg (`<suite>.<test>`) there; bare `<suite>` and no-arg stay on `#tests`. Shipped `gen feat/mkci-single-test-selection` (`cb10282`). Consumers get it on a gen pin bump; test names MUST stay `test`-prefixed.

Single-SUITE selection (`#tests.<suite>`) always worked (a group of `test-*` leaves). Distinct from [[reference_gen_ci_asserttests_expectederror]] (gen's homegrown `checks.default` assertTests gate, all-or-nothing, NOT nix-unit).

──────── reference_papers_archive.md ────────
---
name: Papers and specs archive
description: Papers + all specs in ~/Documents/papers/den-architecture/; canonical location for design docs across all gen ecosystem repos
type: reference
---

Papers at `~/Documents/papers/den-architecture/`. Specs at `specs/` subdirectory. Plans at `plans/` subdirectory (alongside `.tasks.json` files). This is the canonical location for all design documents — shared across den, gen-schema, gen-aspects, and other repos.

**LLM-friendly text versions** of all papers live in `text/` subdirectory as `.md` files. Use these instead of PDFs — they can be read directly without conversion.

## Core — Attribute Grammars

**knuth-1968-genesis-attribute-grammars.pdf** — Knuth's original AG paper. Defines inherited (top-down) and synthesized (bottom-up) attributes on parse trees. Den maps to this: entity tree = parse tree, aspects = attributes, policies = semantic rules.

**vogt-1989-higher-order-ag.pdf** — Extends AGs so tree structure is a computable attribute. Den needs this for `resolve.to` (policies creating new scope nodes). `synthesize` in scope-engine is a HOAG rule.

**hedin-2000-reference-ag.pdf** — Reference attributes (pointers to other tree nodes). Cross-scope pipes/provides. Import edges in scope-engine are RAG references.

**hedin-2003-jastadd-aspect-oriented-ag.pdf** — JastAdd: aspects modularly extend AGs with inter-type declarations. Combines RAGs with AOP. Inter-type declarations parallel den's `neededBy`.

**vanwyk-2010-silver-extensible-ag.pdf** — Silver: extensible AG system with forwarding as first-class concept. Forwarding = default translation that can be refined. Directly informs den's forward/adapter redesign.

## Core — Scope Graphs

**neron-2015-scope-graphs.pdf** — Formalizes scope graphs: nodes = scopes, edges = parent (P) and import (I). Resolution via parent chain, import edges for cross-scope visibility, specificity D < I < P.

**van-antwerpen-2018-scopes-as-types.pdf** — Sequel to Neron 2015. Static guarantees of unambiguous resolution. Shadowing ambiguity detection.

## Core — Algebraic Graphs

**mokhov-2017-algebraic-graphs.pdf** — Four primitives: Empty, Vertex, Overlay, Connect. `connect` is cross-product. Labeled edges via functions from labels to graphs.

## Core — Defunctionalization / Intensional Functions

**reynolds-1972-definitional-interpreters.pdf** — Foundational defunctionalization. Closures → tagged data + dispatch. Informs parametricType and functionTo patterns.

**palmer-2024-intensional-functions.pdf** — Functions with `identify` (program point) and `inspect` (closure) eliminators. Theorem 5.12 (closure consistency) proves dedup-by-identity sound. Search monad (§3) with intensional continuation dedup. **Directly implemented in gen:** mkIntensional, intensionalEq, search.converge with dedupContinuations.

**lorenzen-2025-first-order-laziness.pdf** — Lazy constructors: tagged data that evaluates on demand, inspectable before forcing. **Applied in gen-aspects:** flat collect returns module list without nested `{ imports }` wrappers.

## Build Systems

**mokhov-2018-build-systems-a-la-carte.pdf** — Demand-driven evaluation of dependency graphs. Dynamic dependencies map to HOAG synthesize.

## Open Records / Mixin Composition (gen-schema)

**leijen-2005-extensible-records-scoped-labels.pdf** — Row polymorphism: late-bound record extension safe when keys are strictly tracked. Validates gen-schema's strict-by-default extensible schema kinds.

**bracha-1990-mixin-based-inheritance.pdf** — Mixin composition: independent modules compose with last-wins semantics. Validates gen-schema's `imports` (kind mix-ins) and sidecar merge.

## Contracts / Refinement Types (gen-schema)

**findler-2002-contracts-higher-order.pdf** — Contracts for higher-order functions with blame tracking. Primary reference for gen-schema's refinement contracts (predicate checks co-located with types).

**chitil-2012-practical-typed-lazy-contracts.pdf** — Lazy contract evaluation without breaking laziness. Specifically applicable to gen-schema's lazy contract wrapping (deferred validation with producer/consumer blame).

**rondon-2008-liquid-types.pdf** — Refinement predicates embedded in types (Liquid Types). Proposed for gen-schema inline type constraints replacing validator sidecars.

## Functional Query Languages (gen-schema proposals)

**arntzenius-2016-datafun.pdf** — Functional Datalog with monotonicity tracked via types; fixed-point queries guaranteed to terminate. Proposed for gen-schema graph queries over topology/instance graphs.

## Module Linking

**cardelli-1997-program-fragments-linking.pdf** — Formalizes modules as compilation units with typed interfaces composed via linking. Used to ground gen-schema's NixOS module bridge (schema.emitModule) as a formal linking operation.

## Aspect-Oriented and Feature-Oriented Composition

**kiczales-1997-aspect-oriented-programming.pdf** — Foundational AOP paper. Pointcuts ≈ policy guards, advice ≈ class content delivery, join points ≈ scope graph positions.

**batory-2005-feature-oriented-ahead.pdf** — Feature algebra (GenVoca): features as algebraic composition. Feature = incremental modification ≈ den aspect.

**tarr-1999-n-degrees-separation.pdf** — Hyperspace model: concerns are N-dimensional not hierarchical. Classes (nixos/darwin/hm) are dimensions; aspects cut across.

**apel-2009-overview-fosd.pdf** — Overview connecting FOSD to AOP and SPLs.

**thum-2014-analysis-strategies-spl.pdf** — Feature interaction detection, constraint checking, variability-aware analysis. Relevant if den ever needs static composition validation.

## Dataflow and Propagation (Pipe System)

**kahn-1974-parallel-programming-semantics.pdf** — Kahn process networks: deterministic dataflow through channels. Pipes are Kahn channels.

**radul-2009-art-of-the-propagator.pdf** — Propagator networks: cells connected by propagators pushing information monotonically. Pipe data propagates through scope graph monotonically.

## Scope Graph Implementations

**van-antwerpen-2016-statix-constraint-scope-graphs.pdf** — Statix: constraint-based scope graph resolution DSL. Den's resolution is simpler (traversal not constraint solving) but graph structure is identical.

## Implementation References

**sloane-2009/2010-kiama** — Kiama AG library in Scala. Demand-driven via lazy vals (same as lib.fix).

**erdweg-2015-language-workbenches.pdf** — Survey. Informed trait-style separation of attributes by concern.

## Analysis Docs

- `palmer-deep-analysis.md` — what we independently invented, what Palmer adds. mkIntensional correspondence table.
- `den-fx-gap-analysis.md` — Ned vs HOAG gap coverage for all 5 genuine gaps + 3 missing items.
- `gemini-review-notes.md` — RAG insight (scope-engine is hybrid HOAG/RAG), JastAdd/Salsa/Statix references.

## Feature Interaction / SPL Analysis

**thum-2014-analysis-strategies-spl.pdf** — Classification of analysis strategies for SPLs. Feature interaction detection, constraint checking, variability-aware analysis. Relevant for post-resolution conflict detection.

## Specs (current, in `specs/`)

- `2026-05-23-gen-schema-academic-references.md` — Gemini review: maps gen-schema patterns to papers + 3 feature proposals (lazy contracts, refinement types, graph queries).
- `2026-05-20-flake-aspects-v2-design.md` — Palmer flat typing, fold-based dedup, intensionalEq. 37/37 → 55/55 tests.
- `2026-05-20-palmer-search-monad-design.md` — Search monad: 8 primitives + on/converge + intensional dedup.
- `2026-05-20-gen-package-split-design.md` — gen/gen-schema/gen-aspects three-package split. No re-exports.
- `2026-05-20-gen-aspects-schema-integration-design.md` — Layer 2: mkSchemaEntryType approach (abandoned — deferredModule breaks function defs).
- `2026-05-20-explicit-class-options-design.md` — flake-aspects incremental: dispatching freeformType + explicit class options. Shipped on feat/its-all-a-graph-baby.
- `2026-05-20-gen-aspects-library-design.md` — gen-aspects: clean-room type library for HOAG den. Palmer flat typing, explicit class options, cnf extension points. 40 tests, shipped at github:sini/gen-aspects.
- `2026-05-24-den-v2-hoag-architecture.md` — **CURRENT** den v2 spec. Supersedes 2026-05-19 specs. Graph-native vocabulary, neededBy, pipe redesign, 10 attributes, policy phase separation.
- `2026-05-19-scope-engine-design.md` — HOAG evaluator design (superseded — scope-engine shipped)
- `2026-05-19-gen-schema-hoag-integration.md` — identity/intensional bridge (superseded by gen)
- `2026-05-19-hoag-pipeline-architecture.md` — overall HOAG pipeline design (superseded by 2026-05-24)
- `2026-05-10-aspects-lib-extraction-design-revised.md` — original flake-aspects type system (superseded by v2)


**CONVENTION (2026-07-17, owner-approved):** `STATUS.md` at the repo root is THE entry point —
read it first every session, update it in the same commit as every ship note/arc close. One
lifecycle mechanism: the in-file first-line stamp (`> STATUS: superseded by <path>` /
`rejected` / `shipped`); no filename prefixes, no lifecycle dirs; dead+unreferenced files move
to `archive/` keeping their names. Homes: `specs/` = dated -design.md; `plans/` = dated
-plan.md + .tasks.json + -resume- docs; `gen-specs/<lib>/` = ONLY per-lib REFERENCE.md/ISSUES.md
contracts (dated material stops landing there). `used/`+`reference-catalog/` = the literature
catalog, not lifecycle dirs.

## Comments (0)

(none)
