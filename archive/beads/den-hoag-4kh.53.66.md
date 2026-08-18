# den-hoag-4kh.53.66 — [DECISION 1] merge or distinct — is a host seen as cluster member and environment member one resolved view or two? Merge is only viable once G6 is fixed

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.66` |
| status at evacuation | open |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:16:01Z by Jason Bowman |
| last updated | 2026-07-29T00:16:01Z |
| description bytes | 913 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ OWNER DECISION 1 -- MERGE OR DISTINCT. The audit calls this the one that changes the most
downstream.
WHEN `axon-01` IS SEEN AS A CLUSTER MEMBER AND AS AN ENVIRONMENT MEMBER, IS THAT ONE
RESOLVED VIEW OR TWO?
· MERGE -> the RBAC pattern applies (containment in P, cluster as a LABELLED EDGE, ONE
  node, ONE memo entry), AVAILABLE TODAY WITH NO GEN EXTENSION, and it DROPS 11 HOST SCOPES
  TO 8.
· DISTINCT -> two nodes, and ★ v1's CONTEXT-KEYED SCOPES ARE CORRECT AND STAY.
nix-config's data HINTS at merge; ★ NOT VERIFIED.
★★ PREREQUISITE THE DECISION DEPENDS ON: the audit's own corrections ledger refuted "one
node, several inherited views beats v1's context-keyed scopes" -- single-valued-per-node is
what makes gen-scope's `_eval` SOUND, and ★ `paramAttr` WITH A PER-PARAMETER MEMO *IS* v1's
DESIGN, CURRENTLY WORSE (G6). ⇒ MERGE IS ONLY VIABLE ONCE G6 IS FIXED. Decide G6 first or
decide this knowing it.

## Comments (0)

(none)
