# den-hoag-4kh.53.19 — [S3] three derived kind lists are proved identities — plus two traps a spec must carry as do-not-do lines (rootScopeKinds, dimKinds)

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.19` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:07:51Z by Jason Bowman |
| last updated | 2026-07-29T00:07:51Z |
| description bytes | 1182 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None), `None` (None), `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[S3] ARGUED, WITH PROOFS. Three of ten derived lists are PROVED IDENTITIES:
· `parentKinds` = allKinds \ `_leaves`  -- proved from `childrenMap`'s construction
· `candidateKinds` = `_leaves` \ `_roots`
· `nonCandidateKinds` = `parentKinds` union `_roots`
`_roots` is ALREADY PLUMBED AND UNUSED at `entity.nix`; `_leaves` needs one line.
★★ S4 -- A TRAP WITH A DO-NOT-DO LINE THE SPEC MUST CARRY: `rootScopeKinds` is
`allKinds \ cellKinds` -- "everything that is not a cell", INCLUDING CHAIN-MIDDLE KINDS
WITH BOTH PARENT AND CHILDREN. `_roots` is only the PARENTLESS kinds. On the corpus
topology `_roots` is approximately {flake} while `rootScopeKinds` is EVERY KIND EXCEPT
`user`. ⇒ SUBSTITUTING `_roots` FOR `rootScopeKinds` DELETES MOST OF THE FLEET'S ROOT
SCOPE NODES. Write this as an explicit do-not-do in any spec.
★ S6 -- ANOTHER TRAP ON THE SAME CHAIN: `dimKinds` gaining an EMPTY-REGISTRY kind ZEROES
THE PRODUCT (silent empty fleet). `default.nix` states it in its own comment. Any change
touching that chain needs this as an EXPLICIT ASSERTION, not a comment.
⇒ THE CORRESPONDENCE PROOF MUST LAND STEP BY STEP, and S5's fixture must exist BEFORE
`candidateKinds` moves.

## Comments (0)

(none)
