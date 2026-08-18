# den-hoag-4kh.53.7 — [D5] cases (a)/(b) still have no selector equivalent and are now REFUSED BY NAME at registration (refusedTags coord/has/when, reasons in-file) — ctxExt is NOT the extension point (landed { }); live question: is the refusal permanent posture or does unrefusal ride q1's fixture-fleet settle

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.7` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:06:12Z by Jason Bowman |
| last updated | 2026-08-01T19:58:29Z |
| description bytes | 575 |
| notes bytes | 0 |
| comments | 2 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

[D7] MEASURED. Three cases with NO selector equivalent today:
(a) PER-COORDINATE scoping needs the PRODUCT context, unreachable through the scope
    adapter -- the path is `matchIdWith`'s existing `ctxExt` seam, UNEXERCISED.
(b) A gate on an ENRICH-INJECTED ctx key: selectors see scope accessors, not enriched
    bindings. SAME SEAM.
(c) Multi-coordinate gates off the parent/child line need `sel.when`.
⇒ (a) and (b) are one seam that already exists and has never been driven. That is the
extension point D1's resolution needs for anything beyond kind-position selection.

## Comments (2)

### 1 — 2026-07-29T01:53:09 · Jason Bowman

★★ THE KEY CLAIM IS REFUTED — 'the ctxExt seam is UNEXERCISED / has never been driven'. Retitled to the surviving claim rather than closed.

MEASURED: lib/scope-adapter.nix names the second formal LITERALLY ctxExt, and lib/default.nix:1975 DRIVES IT: scopeAdapter.matchIdWith structural { classOf = classNameOf; }. ★ AND THE FILE'S OWN COMMENT CITES THAT EXACT classOf CASE AS THE SEAM'S MOTIVATION — so the seam is not merely exercised, it is exercised by the use it was built for, and the code says so.
Anchor by expression: lib/scope-adapter.nix matchIdWith and lib/default.nix matchIdStructural.

NOT REFUTED, and this is what survives: that cases (a) and (b) have NO SELECTOR EQUIVALENT. That is the live gap.

Same family as den-hoag-4kh.53.4 — both refuted at the audit's own baseline c42df53 by a single grep, both labelled MEASURED. See that bead's method note.

### 2 — 2026-08-01T19:58:29 · Jason Bowman

Retitle witnessed at 693919f (closure scout): refusedTags = { coord; has; when; } at concern-policies.nix:174-179 with per-tag reasons in-file (:166-173 — coord needs a __coords projection the scope ctx lacks = case (a); has reads ctx.children upstream of dispatch; when's payload is a function the walk cannot descend = case (b), taking hasClass/hasSetting with it). D1's resolution landed ctxExt = { } (attributes/default.nix:56) — the seam this bead called the needed extension point is empty by design; the only non-empty ctxExt is matchIdStructural (default.nix:2118), not a dispatch site.
