# den-hoag-4kh.28 — [hygiene] untracked stash residue: stash@{0} 9218b02 'Fix flake-module instantiate metadata plumbing' — inspect, then land or drop

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.28` |
| status at evacuation | closed |
| priority | P3 |
| type | chore |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:11:35Z by Jason Bowman |
| last updated | 2026-07-30T19:20:38Z |
| closed | 2026-07-30T19:20:38Z |
| close reason | CLOSED 2026-07-30: all three stash entries INSPECTED (read-only triage, every .nix hunk read in full — 653/254/202 diff lines) and DROPPED BY IDENTITY (ad056ca, a8e1550, 26a14a5 — hash verified at each index immediately before each drop; stash list now empty). ZERO LIVE HUNKS existed.

THE SINGLE-TREE ARC (stash@{1}/@{2}): completed VIA REDESIGN, recorded in git only (never in the bead graph — bd search for its vocabulary returns nothing, control 'kernel' → 37): d44a521 (2026-07-16) re-landed the sound half AND rejected Task 4a by name in its body ("the single-typed compile tree is NOT adopted — it double-delivered nested-path aspects, leaked structural options into class buckets, and positionally re-keyed bare delivery refs"); 0d5d8d3 landed the corrected single-tree; 6d3df1b deleted __provider and the annotate test file. Every sound stash hunk verified SUBSUMED at HEAD by binding name + line (wrapGatedFn compile.nix:620/:642, grndDispatch :537, fnArgsOf :1164, native-.key :1476, the batteries or-{ } fix evolved through the genPrelude.hasInfix migration, ledger row L7 verbatim, resolvedFamilies gate rows verbatim); HEAD is strictly AHEAD in places (bare `if v ? key` — the transitional __provider fallback the stash carried was later deleted exactly as the stash's own comment predicted). Rejected-by-design constructs (spliceRawPolicies/compileClassSet/malformed-detect) measure 0 at HEAD with the replacement stated in-tree (gated-aspects-type closedKeys — "the type is the sole validator") and the one coverage question (malformed fn-attrset loud abort) is held by test-malformed-fn-attrset-still-aborts. APPLYING would have: reverted the FROZEN golden hoagHash and deleted the Law A15 user-as-cell edge from parity/golden/traces.nix; rolled gen-aspects back 11 days in three lockfiles to a rev that was NEVER adopted; resurrected a deliberately deleted test file; and dangled on errors.parametricListUnsupported (no longer exists — survives only as ledger prose). stash@{2} was a strict content subset of @{1} (diff-of-diffs: 13 lines, all shifts).

stash@{0}: NOT a trivial beads export — mode-flips on five .beads files (junk) + the deletion of plans/2026-07-24-flakeoutput-class-gate-plan.md. That deletion was correct cleanup abandoned mid-flight: the file was byte-identical (md5 2b14a67d) to its canonical papers-repo copy and its subject shipped at 6bfe930. LANDED SEPARATELY as 9165f9f (its own one-file commit — never applying a stash that also chmods tracked files); plans/ is now empty.

TRIAGE INSTRUMENT NOTE: the inspector's first grep sweep produced 15 false zeros from an unquoted --include glob (zsh expansion), caught by its own positive control and re-run quoted — the false-clean direction, self-disclosed. |
| description bytes | 825 |
| notes bytes | 0 |
| comments | 2 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED 2026-07-28: `git stash list` in /home/sini/Documents/repos/sini/den-hoag has exactly ONE entry —
stash@{0}, base 9218b02, "Fix flake-module instantiate metadata plumbing".

It is untracked residue: nothing in the bead graph or any memory refers to it. The features memory's stash
paragraph names TWO DIFFERENT stashes (base 192be55, "task-B-WIP" and "single-tree-classcontent-half") and
BOTH ARE GONE — so the only record that mentioned stashes gives no guidance on the one that actually exists.

ACCEPTANCE: inspect the diff, then either land it (if the flake-module instantiate metadata fix is real and
absent from main) or drop it. Either outcome recorded here. A stash is the one place work can sit indefinitely
without appearing in status, diff, or log.

PROVENANCE: memory-reconcile audit 2026-07-28, item C8.


## Comments (2)

### 1 — 2026-07-28T05:39:28 · Jason Bowman

★ ADDENDUM — THE ARCHIVED LOG CONTAINS AN INSTRUCTION THAT WOULD DESTROY THIS BEAD'S SUBJECT. Do not follow it.

The 927-line historical log (archived verbatim at den-hoag-4kh.27), lines 353-354, reads:
  "the 2 stashes on the worktree (base 192be55, 'task-B-WIP' + 'single-tree-classcontent-half') … DROP them (git stash clear), never restore."

MEASURED at HEAD 2026-07-28: `git stash list` = EXACTLY ONE entry — stash@{0}, 9218b02, 'Fix flake-module instantiate metadata plumbing'. Both stashes the log names are GONE.
⇒ `git stash clear` today would destroy the ONE stash that exists, which is precisely what THIS bead tracks (inspect, then land or drop). The log's instruction was correct when written and is now actively destructive — it names no stash by hash, so it reads as 'clear the stashes' rather than 'clear those two'.

★ GENERAL FORM, worth more than the incident: A DESTRUCTIVE INSTRUCTION SCOPED BY A DESCRIPTION RATHER THAN AN IDENTITY RE-TARGETS ITSELF AS THE WORLD CHANGES. 'Drop the stashes' aged into 'drop a different stash'. When recording a destructive action, pin it to the identity (hash, rev, exact path) so it becomes a NO-OP rather than a hazard once the subject is gone.

### 2 — 2026-07-30T17:21:09 · Jason Bowman

STASH CENSUS UPDATE 2026-07-30 at e1fac60 — the body's cited stash@{0} (9218b02 'Fix flake-module instantiate metadata plumbing') NO LONGER EXISTS; the live list is THREE entries, none from today's session: stash@{0} 'c42df53 chore(beads): export the issue graph'; stash@{1} 'task-B-WIP: single-tree wiring + spliceRawPolicies + malformed-detect + normalize-wrapGatedFn migration + :637/:1177 repoints + fnArgsOf + 3 parity re-baselines + R5 + 2 gated-accessor fixes + drvPath probe — 7 sound fixes, blocked at #8 module-fn class content'; stash@{2} 'single-tree-classcontent-half: wiring + 3 rebaselined parity artifacts (golden/hoagHash/L4-resolved) + homeManager fix + bucket-equivalence + drvPath probe — for the parametric-include phase'. stash@{1} and stash@{2} describe SUBSTANTIAL parked implementation work (the single-tree arc) with parity re-baselines — inspection should establish whether those fixes were independently landed since, before dropping. The bead's original inspect-then-land-or-drop acceptance stands, now over three entries.
