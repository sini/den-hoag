# den-hoag-4kh.54 — Dispatch-discipline case log (orchestration traps)

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.54` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-29T19:37:36Z by Jason Bowman |
| last updated | 2026-07-29T19:37:36Z |
| description bytes | 552 |
| notes bytes | 0 |
| comments | 14 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

Case archive backing the LAWS in memory feedback_agent_dispatch_discipline (16 laws, one line each). Full measured case studies live here as comments — same convention as den-hoag-4kh.20 (instrument-trap cases). CANONICAL-HOME CONVENTION, settled 2026-07-29: verification/instrument-trap cases -> den-hoag-4kh.20; orchestration/dispatch-discipline cases -> this bead. A case goes to exactly ONE of the two, never both; the memory laws files carry pointers only. New dispatch-discipline traps land here as comments in the same session they are measured.

## Comments (14)

### 1 — 2026-07-29T19:37:46 · Jason Bowman

---
name: feedback_agent_dispatch_discipline
description: "Dispatch rules earned across one long multi-agent arc — report by message, separate defect from remedy, and expect the brief itself to be the error source"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f6c27718-974a-4179-927b-1bf76de4c2c6
  modified: 2026-07-29T17:37:51.802Z
---

Operational rules for running work through fresh-context agents. Each cost a real round.

★★★ **AGENT-TO-AGENT MESSAGING RETURNED SUCCESS AND DELIVERED NOTHING — TWICE, WITH MESSAGE IDS. THE
ORCHESTRATOR MUST BE THE RELAY HUB.** Measured 2026-07-29: a reviewer sent two findings directly to the author
revising against them, both `SendMessage` calls returned `success` with distinct ids, and the author received
**neither**. The same content relayed through me arrived. ⇒ **A `success` return is not evidence of receipt.**
Never let two subagents coordinate on a fact you need; route it, and when the content is load-bearing, ask the
recipient to **echo it back**. The failure is silent on both ends — the sender believes it delivered, the
recipient never knows a message existed — so nothing surfaces it except a third party comparing notes.
★ Corollary, and it nearly shipped a false record: the author, seeing no F8/F10 anywhere, was about to write
*"the reviewer confirms the count was wrong."* **A missing relay does not read as missing — it reads as a
refutation of whoever is named in the record.**

★★ **AND THE ORCHESTRATOR'S OWN ABRIDGEMENT IS THE SAME CLASS OF DEFECT.** My bead comment said "9 non-blocking"
under a header reading *"THE FOUR THAT MATTER"* — so five were a count with no trace. Measured on my own text
with a positive control: `F10` **0** occurrences, `F8` **1** and only inside `except F5-F8`. ⇒ **Never record a
cardinality you do not enumerate.** A counted-but-unrecorded finding is worse than a dropped one: dropping is
visible, counting-without-recording looks complete and makes the *next* reader's correct observation ("only four
are here") into a false conclusion about the source. When compressing a report into the graph, compress the
*prose*, never the *set*.

**AGENTS MUST REPORT BY MESSAGE, NOT PLAIN TEXT.** A subagent's plain-text output is not visible to the
orchestrator. Six apparent "silences" in one arc were agents that had completed the work and written a
report the orchestrator could never see. Put it in every dispatch: *"REPORT BEFORE GOING IDLE, AS A MESSAGE
— plain text output is not visible to me."* When an agent goes idle without reporting, **ping once, do not
re-dispatch** — and check the scratchpad first, because the work is usually done.
★ **BUT AN IDLE IS NOT EVIDENCE EITHER WAY — MEASURE THE ARTEFACT.** The inverse case also happened: an agent
went idle having applied round 1 and *silently not applied round 2*, with the follow-up message apparently
arriving as it finished. Six silences were completed work; this one was not, and the two are
indistinguishable from the notification. So never infer done-ness *or* failure from an idle — go look at the
file: `md5sum`, line count, and a `grep` for the specific string the round was supposed to change. That check
costs one command and is the only thing that separates the two cases.

★★★ **THE ORCHESTRATOR'S OWN PREMISES ARE THE LEAST-CHECKED FACTS IN THE SYSTEM — MEASURE EVERY CLAIM YOU PUT
IN A BRIEF, INCLUDING THE HEADER.** Four instances in one session, **every one caught by the recipient and
none by me**:
1. `grep -c 'monotone'` returned 0, so I told an author it had not taken an argument and asked why. It had —
   the spec wrote `MONOTONE` and `monotonicity`, defeating the predicate by case *and* by stem. **I sent a
   false absence as a premise**, which asks the recipient to explain something that did not happen.
2. I widened a reviewer's absence finding to a neighbouring claim it had never tested. The claim was in fact
   discharged two revisions earlier.
3. Every dispatch header read "papers `<sha>`" — **that directory is not a git repository**, and the sha
   belonged to a subdirectory whose HEAD moved under every dispatch because several agents commit there.
4. I promoted a finding's severity on "all six declarations route through this path". **They did not** —
   measured with a positive control by the next reviewer. Right verdict, wrong reason, and the reason was
   mine.
5. ★ I declared a bead unblocked from `dependent_count` — **the count of things depending on IT** — while
   `dependency_count` was also 3. Then declared it *blocked* on two defects whose edges pointed **backwards**:
   the spec *delivered* both remedies. All three of its edges were mine and all three were wrong.
   ★★ **THE ONE THAT COULD NEVER HAVE CLEARED: a `blocks` edge to a STANDING CONSTRAINT.** The chain ran
   `bead → directive → "STANDING: must scale to thousands of hosts"`. A standing constraint has **no completion
   condition**, so no work could ever clear it, and the dead leg propagated to a third bead. ⇒ When a tracker
   offers one edge type for both *"this gates me"* and *"I was dispatched under this"*, **provenance gets typed as
   sequencing** and the graph is permanently, invisibly wrong — every individual row well-formed, `bd blocked`
   listing correct dependencies, and only the question *can this chain terminate?* exposing it. The remedy already
   existed (`parent-child`, 221 uses vs 83 `blocks`) and was simply not chosen. Case `den-hoag-efz`.
⇒ **A BRIEF CARRIES AUTHORITY THE ORCHESTRATOR HAS NOT EARNED PER-CLAIM.** An agent will act on a stated
premise, and a careless one will *invent* the explanation for a fact that is not true. Before dispatching:
re-run every count, `git cat-file -e` / `rev-parse --git-dir` every coordinate, and mark any inference of
yours as **inference, not measurement**.
★ Two shapes that recur: **a stale freeze sha manufactures false mismatches inside the very mechanism built
to catch real ones** ("STOP on a mismatch"); and **a document's layout can invite an inference its own data
refutes** — if two facts sit adjacent and suggest a third, measure the third.

★★★ **AND THE MOST EXPENSIVE SUB-SHAPE: RELAYING A REVIEWER'S *SEVERITY ARGUMENT* WITHOUT MEASURING IT.**
A gate's findings and its *reasons for their importance* are different artefacts, and only the findings come
with evidence. Twice in one session I forwarded a reviewer's licence sentence as my own premise and a later
gate refuted it by measurement:
· "all six declarations this design exists to make route through the broken arm" — **they did not**; the
  spec's own data refuted it.
· "the two call sites read different evals, so the fail-open is architectural, not hypothetical" — **both
  sites are the same one-line binding**; they differ in traversal adapter, not in what they read.
★ **BOTH TIMES THE REMEDY WAS RIGHT AND THE ARGUMENT WAS WRONG**, which is the dangerous combination: the
work lands, nobody re-examines it, and a false claim about *why* becomes load-bearing prose in the artefact —
in one case repeated verbatim across two revisions.
⇒ **RELAY THE MEASUREMENT AND ATTRIBUTE THE INFERENCE.** Write "the reviewer concludes X; I have not measured
it" rather than restating X in your own voice. An escalation you did not measure is not yours to assert, and
a design that needs a severity argument to justify it should get one that was executed.

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

★★ **A RULING RECORDED IN THE GRAPH DOES NOT REACH AN AGENT ALREADY RUNNING — RELAY IT, DO NOT MERELY RECORD
IT.** Measured 2026-07-29, and the timestamps are exact: an author raised a scope question, the orchestrator
ruled on it at **03:05:53Z** and wrote the ruling as a comment on the very bead the spec cites — and the spec
committed at **04:45:25Z**, one hour forty minutes later, **still shipping the resolved question to the
owner**. The gate then spent a finding on it.
**Agents do not poll the tracker.** A ruling made *after* dispatch is invisible to exactly the work it was
made for, and the graph looks completely correct the whole time — which is why nothing catches it.
⇒ When you resolve something an agent raised: **`SendMessage` the ruling to that agent in the same turn you
record it.** Recording is for the graph and for whoever comes next; the message is for the work in flight.
If the agent has already finished, the ruling becomes an input to the *next* dispatch — carry it into the
brief explicitly rather than assuming the successor will re-read the bead.
★ Corollary: **an agent's brief is a snapshot.** Anything decided after it was written must be pushed, not
pulled — this is the same shape as [[feedback_reviewable_artefact]]'s freeze problem, where the tree moved
under a document nobody was permitted to touch.

★★ **AND THE INSTRUMENT WARNINGS IN A BRIEF ARE HYPOTHESES TOO — AN OVER-APPLIED HAZARD IS A REAL FAILURE
MODE AND NOTHING IS LOOKING FOR IT.** Measured 2026-07-29: a genuine measurement ("`diff` on PATH is a
wrapper emitting no `<`/`>` lines") was relayed into a reviewer's brief as an instrument warning. **In that
session `type diff` resolved to the real binary** — the reviewer checked instead of adopting, with a positive
control on the warning's own predicate, and its earlier result stood. Had it accepted the warning it would
have retracted a sound sanity check.
**A trap log is a set of CONDITIONAL hazards; shipping them as unconditional creates a new failure mode
pointing the other way.** A missed hazard yields a false green, which every review process hunts. An
over-applied hazard yields a false red — work redone, correct results distrusted — and nothing in the process
is looking for it. The direction that *feels* safe is not free.
⇒ **State the ENVIRONMENT PREDICATE with the warning, never just the remedy**: not "use the absolute `diff`"
but "`type diff` may resolve to a wrapper — check, and use the absolute path if it does." The rule above that
a brief's facts must be verified rather than inherited **applies to its warnings too**.
★★ **TWICE IN TWO DAYS NOW, AND THE SECOND FAILED DIFFERENTLY — SO STATE THE PREMISE AND THE INFERENCE
SEPARATELY.** Case 1: the `diff`-wrapper warning was *true elsewhere and not live in that session*. Case 2: I
relayed "`tryEval` does not catch `attribute … missing`" — **true** — and inferred that a core's
`x.a.b.c or "ABSENT"` wrappers were therefore broken. **The inference is false**: `or` binds the whole select
path and fires *before* `tryEval` ever sees it (measured, with the no-`or` control failing at exit 1). So a
relayed hazard can be sound in its premise and wrong in what it licenses.
⇒ Relay the **measurement**, and mark any inference from it as *mine and unverified*. A warning bundled with
its conclusion invites the agent to act on the conclusion, and the conclusion is the part that did not travel.

★★★ **RELAYING IS NECESSARY AND NOT SUFFICIENT — VERIFY THE RELAY LANDED IN THE ARTEFACT, NOT IN THE REPORT.**
The sequel to the rule above, measured 2026-07-29 and caught by a gate rather than by me. I relayed two extra
conditions (9 and 10) to a running author. The relay was delivered. Its report then enumerated **the original
eight**, claimed "all eight conditions discharged" — and **conditions 9 and 10 were never addressed**. I
accepted it. A grep of the artefact found **zero** occurrences of every marker they required, against a
positive control of 25.
★ **THE FAILURE MODE IS THAT THE REPORT'S OWN STRUCTURE BECOMES THE CHECKLIST.** A report organised around
the brief looks complete when read against the brief — and a condition added *after* the brief has no slot in
that structure, so its absence is invisible. Nothing is missing from the report; the report is missing an
item, which reads identically.
⇒ **After relaying, add the relayed item to YOUR OWN return checklist and grep the artefact for it** — one
command, with a positive control so a mis-typed predicate cannot read as compliance. Do not accept an
"all N discharged" claim whose N is the pre-relay count.

Related: [[feedback_reviewable_artefact]], [[feedback_verification_predicate_blindness]],
[[feedback_agent_idle_reports]], [[feedback_resume_failed_agents]], [[feedback_no_parallel_agents]].


### 2 — 2026-07-29T23:26:17 · Jason Bowman

CASE (2026-07-29, 4kh.11 landing): SWEEP-DISCHARGE BY THE WRONG PREDICATE. Orchestrator told the worker 'you have already verified :123 is the ONLY remaining old-primitive line — that discharges the class sweep.' It does not: the class had TWO predicates with DIFFERENT extensions — A: names the dead primitives; B: asserts strictly-below over a RUNTIME READ — and REFERENCE.md line 87 sat in B minus A (stated the stale rule while naming no primitive). Predicate A returns zero on it however carefully run. The worker had already run B and fixed :87, so nothing shipped stale — but a fresh worker taking the discharge at face value would have shipped it. Law-3 instance (a sound predicate proves a different proposition), committed IN A DISPATCH MESSAGE, where it becomes the recipient's premise. Rule: when discharging a CLASS sweep, restate the class's predicates and check the cited verification covers EACH extension, not the intersection.

### 3 — 2026-07-30T16:17:53 · Jason Bowman

ORCHESTRATION TRAP (2026-07-30): a READ-ONLY scout evaluating path:-flake expressions against the LIVE repo raced the session's writer — nix copied the DIRTY tree to the store mid-edit and the scout's first measurement round hit the writer's in-flight partial state ('error: undefined variable', from a half-applied deletion), with the store hash changing between two runs seconds apart. One-writer-per-repo protects the git index, not read-side eval reproducibility. RULE: a scout that EVALUATES (not just reads) must pin its input — git archive HEAD to a frozen snapshot and evaluate that (the scout self-recovered exactly this way and re-measured everything on the frozen copy). Dispatches for evaluating scouts should say so up front; mine did not.

### 4 — 2026-07-30T19:34:34 · Jason Bowman

ORCHESTRATION TRAP, MINE (2026-07-30): 'git add <one file>; git commit' COMMITS THE WHOLE INDEX — my batched beads-export commit (c5bf9f0) swept in a concurrent writer's staged iteration probe (zz-akj-probe.nix, staged only to make a path:.. flake see the new file). Stage-by-name protects against MY over-adding; it does not protect against foreign pre-staged content, and the one-writer rule exists precisely because the index is shared — a beads-export commit IS a writer action. RULE: before any commit while an agent is active, read git status and verify the index holds only what you staged (or commit with explicit pathspecs). Removed at e987cee; it contributed no tests (totals confirm). Second half of the same incident: a writer that must STAGE a scratch file for flake visibility should say so at the moment of staging, so the orchestrator knows the index is dirty.

### 5 — 2026-07-31T01:22:44 · Jason Bowman

WORKTREE-ERA DISPATCH RULE (owner flag, 2026-07-30/31, the moment parallel worktree writers went live): REPO-ROOT SWEEPS CAPTURE .worktrees/ COPIES — plain grep -r and find from the repo root descend into local worktrees and silently DOUBLE-COUNT every file they hold (an importer census, a token count, a duplication check all inflate). The gitignore-honouring wrapper excludes them; /run/current-system/sw/bin/grep — the mandated instrument for REPORTED counts — does not. RULES, effective immediately in every dispatch: (1) repo-root sweeps use git grep / git ls-files (tracked-only, naturally safe) OR scope to lib/ ci/ parity/ explicitly OR carry --exclude-dir=.worktrees; (2) a count taken in the MAIN checkout while any worktree exists is suspect until its instrument's worktree posture is stated; (3) a WORKTREE-resident agent is naturally safe (its checkout contains no nested .worktrees) — main-resident agents are the exposed ones; (4) mid-flight agents dispatched before a worktree's creation get a relay warning (done for the live case). Prior art: PIN.md's census excluded .worktrees for exactly this inflation; project memory records that an exclusion PROVES nothing about staleness — the two lessons compose: exclude for counts, never cite the exclusion as evidence.

### 6 — 2026-07-31T01:33:05 · Jason Bowman

WORKTREE-INTEGRATION TRAP, MINE (first worktree merge, 2026-07-31): I ran the ff-merge + push FROM INSIDE THE WORKTREE — the merge no-op'd ('Already up to date': the worktree IS the branch) and the push CREATED origin/wt/4kh25, violating the no-new-remote-ref-namespaces limit; the subsequent worktree remove then orphaned the shell's cwd. Recovered inside a minute (main ff-merged from the MAIN checkout, remote ref deleted, ls-remote wt/* verified 0). RULE: integration steps (merge, push, worktree remove) run from the MAIN checkout, ALWAYS — a worktree is for the writer's edits and the merge-gate suite run only; and after any worktree-era push, verify ls-remote for stray wt/* refs. The gate suite HAD been run correctly on the rebased branch before the botched merge — the error was purely in where the git commands executed.

### 7 — 2026-08-01T14:50:06 · Jason Bowman

CASE (orchestrator, 2026-08-01, self-charged): INTEGRATION COMMANDS RAN INSIDE THE WORKTREE — the exact law this log already carries, violated by the orchestrator on a one-commit doc branch. Chain: cd .worktrees/migration-emits && rebase (fine, branch checkout) THEN merge --ff-only + push + worktree remove in the SAME compound command. Consequences, each predicted by the law: (1) the 'merge' was a silent NO-OP ('Already up to date' — the worktree's HEAD IS the branch, so main never moved); (2) the push CREATED remote ref wt/migration-emits — violating the wt/*-never-push rule AND the no-new-remote-ref-namespaces limit of the durable consolidate authorization; (3) worktree remove orphaned the shell cwd and the branch delete failed on 'Unable to read current working directory'. REPAIR (from the main checkout): push origin :wt/migration-emits (ref deleted), merge --ff-only, push main (d1ee769→ef51171), branch -d, worktree list verified. SHARPENING: the trap was the COMPOUND COMMAND — the rebase legitimately needs the worktree (branch is checked out there), and && carried the integration steps into the same cwd. Rule restated operationally: rebase in the worktree is the LAST command that runs there; everything after it starts with cd to the main checkout. Second observation, same session: worktree commits fail pre-commit load ('No .pre-commit-config.yaml') — the symlink exists only in the main checkout; workers need PRE_COMMIT_ALLOW_NO_CONFIG=1 (z72's observation, worktree flavour; put it in dispatches, both writers hit it).

### 8 — 2026-08-01T15:58:50 · Jason Bowman

CASE (orchestrator, 2026-08-01, self-charged — SECOND occurrence of the worktree-integration trap in one session, new mechanism + a law-30 violation compounding it): (1) The integration merge refused with 'local changes to ci/tests/projection.nix would be overwritten'. I inspected with git status/diff — EMPTY — and CONCLUDED a stale-stat false positive, INVENTING a mechanism (index staleness) to explain it. WRONG: my inspection had run in the WORKTREE (whose tree was clean); the failed cd belonged to a && chain whose earlier member failed, and cwd was not where I believed. The retry then ran in the worktree: no-op merge, stray remote ref wt/144-row3 created, worktree remove destroyed my own cwd — the exact incident from earlier the same day. (2) THE LAW-30 SHAPE: given a contradiction (merge says dirty, status says clean) I manufactured a mechanism that dissolved the contradiction instead of RE-ESTABLISHING WHERE I WAS. The two observations were about TWO DIFFERENT TREES. Before explaining a contradiction, verify the frame (pwd + git rev-parse --show-toplevel) — a contradiction between two commands is only meaningful if they ran in the same frame. (3) OPERATIONAL RULE SHARPENED (the earlier case's rule was insufficient — I followed its letter and still failed): EVERY integration command block BEGINS with cd <main-checkout> INSIDE THE SAME COMMAND STRING; never rely on cwd surviving from a previous call, especially across a failed && chain and across worktree removals that reset the shell. (4) The REAL dirt existed: four session-landed files reformatted in the MAIN checkout by a formatter arm nobody ran there (filed separately with the evidence) plus legitimate beads-export churn — the phantom and the real overlapped, which is what made the invented mechanism plausible.

### 9 — 2026-08-01T17:10:01 · Jason Bowman

CASE ADDENDUM (orchestrator, 2026-08-01, third occurrence of the integration-frame trap, NEW FLAVOR): gen's checkout was sitting ON the feature branch (the implementer worked in the main checkout — single-repo branch flow, legitimate); I verified main's REV and origin sync but never WHICH BRANCH was checked out, then ran merge --ff-only <branch> — self-merge no-op, push published the branch ref. Repair: switch main, FF, push, delete both refs. RULE COMPLETED (third clause): every integration block begins with cd <checkout> AND verifies git branch --show-current — a rev check does not establish the frame; 'main is at X' and 'HEAD is main' are different facts. (Flavors so far: cwd-in-worktree ×2, checkout-on-branch ×1 — all three produced a stray remote ref first caught by the push output.)

### 10 — 2026-08-02T00:07:30 · Jason Bowman

CASE (law 6's edge sub-class, THIRD instance): provenance-typed-as-sequencing, 2026-08-01. den-hoag-3w6→53.64 and den-hoag-c3m→53.64 carried blocks edges with NO rationale in either body (the rationale — masking, i.e. REACHABILITY — lived only in 1kd). A read-only scout re-executed both beads' own witnesses at 04d55d6: both reproduce at their anchors with 53.64 wholly unresolved; the masker was a one-line data entry the refusal message itself dictates (den-hoag-a8a). Edges dropped; the P0 critical path shortened by one arc-sized false dependency. INSTANCES NOW: i5m→53.64 (sweep 2026-08-01a), the efz blocks-to-standing-constraint (original), these two. TELL, consistent across all four: the EDGE'S rationale is absent from the BLOCKED bead's body — a bead that cannot say why it is blocked probably is not. Sweep rule candidate: every blocks edge whose rationale is not in the blocked body gets re-derived on contact.


### 11 — 2026-08-02T00:41:26 · Jason Bowman

CASE (integration-frame, 4th incident, 2026-08-02): after  the MAIN CHECKOUT stays on the wt branch; the next compound ran main — show-current PRINTED wt/rung-3w6 but the && chain reads only EXIT CODES, so the push minted a remote wt/rung-3w6 ref (no-new-ref-namespaces violation; repaired same minute: checkout main, FF, push main, delete local+remote ref, ls-remote grep wt/ = 0). RULE SHARPENED: a frame-verify must ASSERT, never print —  so the chain dies on the wrong frame. A printed truth nothing reads is the silent-vanish shape inside the orchestrator's own shell.

### 12 — 2026-08-02T00:41:52 · Jason Bowman

CORRECTION — the previous comment is GARBLED (its backtick spans were executed by the recording shell, deleting the command texts; meta-instance of its own lesson). CLEAN RECORD, integration-frame 4th incident, 2026-08-02: after "git rebase main wt/rung-3w6" the MAIN CHECKOUT stays checked out on the wt branch. The next compound ran: git branch --show-current && git merge --ff-only wt/rung-3w6 && git push. show-current PRINTED "wt/rung-3w6", but a && chain reads only EXIT CODES — the print succeeded, the merge was a no-op ("Already up to date", merging the branch into itself), and the push published the CURRENT branch, minting a remote wt/rung-3w6 ref (no-new-ref-namespaces violation). Repaired same minute: git checkout main; assert-then-merge; push main; delete local branch; push origin :wt/rung-3w6; ls-remote heads grep wt/ returns 0 matches. RULE SHARPENED (two halves): (1) a frame-verify must ASSERT, never print — spell it [ "$(git branch --show-current)" = main ] so the chain dies on a wrong frame; a printed truth nothing reads is the silent-vanish shape inside the orchestrator's own shell. (2) bd comment text with shell-metacharacter content must go through --file, never a double-quoted inline string — this correction is itself the witness.


### 13 — 2026-08-03T23:05:07 · Jason Bowman

DISPATCH-DISCIPLINE CASE (2026-08-03, dpuk gate rounds 13-16): I RELAYED A REVIEWER'S TRACKER-STATE CLAIM ('den-hoag-r7l's dispositions are UNRULED') THROUGH THREE REVISION DISPATCHES WITHOUT OPENING THE TRACKER'S COMMENT THREAD MYSELF. The r13 reviewer inferred unruled from r7l's BODY ('DO NOT resolve autonomously') + the dpuk ruling's 'changes no r7l row disposition'; the actual owner ruling (2026-08-03T01:20:30Z, five comments deep: sheet CONFIRMED AS DEFAULTED, 10/9/9, binding execution constraints) was visible only in bd comments — bd show surfaces comment_count, not comments (law 12's shape). The spec's author then wrote 'UNRULED' into an authority table on my instruction; the r16 reviewer read all nine comments and refuted it with a firing control proving the spec HAD read the same thread selectively (it quoted a different comment). COST: one wrong authority table shipped through two gate rounds; a ruled execution constraint (env-to-clusters does-NOT-ride-dcx) missing from the landing order it governs. LAWS THIS COMPOUNDS: law 6 (orchestrator premises least-checked), law 23/'already tracked as X' (a tracker citation is a claim — and OPENING a tracker means its COMMENTS, not its body; rulings live in threads), law 4 (never relay a reviewer's conclusion unmeasured). NEW EDGE: for any bead named as an AUTHORITY (not just a tracker), the orchestrator reads bd comments --json BEFORE relaying its state — body + title + status are not the record; the thread is.

### 14 — 2026-08-03T23:38:59 · Jason Bowman

DISPATCH-DISCIPLINE CASE (2026-08-03, dpuk gate r1-r17, owner-flagged): A STANDING AUTHOR REVIVED ACROSS 17 REVISION ROUNDS REACHED ~1M TOKENS — the bounded-addendum revival mechanism (law 17) stretched into a de facto permanent writer, against the standing policy (workers fresh-context, RETIRED on report). WHY IT DRIFTED: author continuity was carrying real value (accumulated discharge-the-class lessons; by late rounds the author self-caught its own drift classes before dispatch), and each single revival was locally cheap. WHY IT WAS STILL WRONG: (1) per-round context for a FRESH author is BOUNDED (the artefact is self-contained by rule, every verdict is a banked file, the dispatch carries complete conditions — rotation was always cheap), while a standing author's context grows monotonically and never sheds dead rounds — the crossover came ~r8-r10 and was never re-examined; (2) near the context ceiling the failure is SILENT — compaction degrades exactly the accumulated judgment that justified continuity; (3) the orchestrator tracked artefact state (md5s, freeze hashes, finding counts) and never the agent budget — nothing surfaces teammate token counts, but 17 rounds x 2k-line revisions was inferable and was not inferred. THE RULE: a revived writer carries a ROUND BUDGET (~3-4 revivals) or a size tripwire; at the budget it retires and a fresh author takes (artefact + newest verdict + the distilled class-lessons list — which the revision dispatches should be accumulating in writing precisely so continuity is never load-bearing). The reviewers rotated correctly every round throughout; only the author slot drifted.
