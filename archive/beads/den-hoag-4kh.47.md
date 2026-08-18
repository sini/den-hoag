# den-hoag-4kh.47 — [ci] three fixture comments describe a corpus shape that does not exist, and one names a guard (errors.reservedClassInclude) that was never built

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.47` |
| status at evacuation | closed |
| priority | P2 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T17:59:42Z by Jason Bowman |
| last updated | 2026-07-31T00:40:49Z |
| closed | 2026-07-31T00:40:49Z |
| close reason | DISCHARGED at 2930c9c — and TWO OF THREE claims had turned TRUE since filing, verified rather than edited: (1) the corpus DOES name its shared-HM aspect home-manager-shared at the current pin 425f1d3 (re-measured at the OLD pin b0b20769: bare 'home-manager' key, zero '-shared' — the bead was right when filed; the corpus renamed since, at fddab954); (2) errors.reservedClassInclude EXISTS (built at e1f8a5e this session — defined errors.nix:197, fired from the ingest scan, with the generic-guard control test the comment claims). (3) The remaining fixture header (compat-settings-nav-hm-collision.nix) was HALF-true — its facet list is now accurate; its PREMISE (corpus authors a class-named aspect) is what expired — rewritten: the class-named spelling is the v1-legal shape the fixture authors inline. Suite 2044/2066 identical. |
| description bytes | 2429 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED — THREE den-hoag CI TESTS DESCRIBE THE CORPUS WRONGLY, AND ONE NAMES AN ERROR THAT DOES NOT EXIST.
Found while establishing the includes ruling (den-hoag-9xo.48); each verified against the pinned corpus rev
b0b207693ce66fb57acf2bb09cf9549e1dbddec7 with a positive control.

 1. `ci/tests/compat-nested-class-named-aspect.nix:8` states "the corpus follows this by naming the shared-HM
    aspect `home-manager-shared`". ★ FALSE — `home-manager-shared` = ZERO occurrences repo-wide at that rev.
    The corpus has `den.aspects.core.users.home-manager`
    (modules/den/aspects/core/users/home-manager.nix:5), included at modules/den/aspects/roles/default.nix:16.
    POSITIVE CONTROL: the same grep for `home-manager` matches 20 files under modules/den/.
 2. ★ `ci/tests/compat-nested-class-named-aspect.nix:132` says the reservation-include "fires the loud
    reservation error (`errors.reservedClassInclude`)". THERE IS NO SUCH ERROR. `reservedClassInclude` appears
    in den-hoag ONLY in that comment. POSITIVE CONTROL: the same grep enumerates 20+ real `errors.<name>` keys
    (errors.classAmbiguity, errors.attachRefUnresolved, …). WHAT ACTUALLY FIRES ON THE REAL CORPUS IS THE RAW
    gen-aspects THROW — which is precisely the diagnostics gap that makes ruling (B) unshippable as-is.
 3. `ci/tests/compat-settings-nav-hm-collision.nix:3` describes the corpus HM aspect as carrying "a `.settings`
    facet PLUS its own class content authored the v1 way (`os`, `nixos`, `darwin`, and `homeManager`
    camelCase)". The real file's keys are `os`, `nixos`, `darwin` — NO `settings`, NO `homeManager`. The
    fixture still exercises the mechanism; the DESCRIPTION of the corpus is wrong.

★ WHY THIS IS WORTH A BEAD RATHER THAN A COMMENT SWEEP: these are not stale line numbers, they are FIXTURES
JUSTIFYING THEMSELVES BY REFERENCE TO A CORPUS SHAPE THAT DOES NOT EXIST. A reader checking whether the suite
covers the real corpus reads item 1 and concludes it does. Item 2 is worse — it asserts a named guard exists,
so anyone reasoning about diagnostics quality for this collision class would conclude the loud error is
already shipped. It is not, and its absence is exactly what the includes ruling turns on.
NOT FIXED HERE: the investigation was read-only by instruction. Each comment needs re-anchoring to what the
corpus actually contains, and item 2 needs either the named error built or the claim withdrawn.


## Comments (0)

(none)
