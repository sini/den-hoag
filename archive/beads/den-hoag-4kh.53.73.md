# den-hoag-4kh.53.73 — [compat] 8 of 8 comparable den templates are GREEN on v1 and FAIL on den-hoag at e6c8edc — six named blockers, so the template suite is not a live gate and nix-config is the only witness

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.53.73` |
| status at evacuation | deferred |
| priority | P1 |
| type | bug |
| labels | (none) |
| parent | `den-hoag-4kh.53` |
| created | 2026-07-29T00:35:52Z by Jason Bowman |
| last updated | 2026-08-05T20:48:41Z |
| description bytes | 3456 |
| notes bytes | 0 |
| comments | 0 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★★ MEASURED AT e6c8edc, BOTH ARMS, 2026-07-29. THE SINGLE CONCRETE WORK LIST BETWEEN
den-hoag AND ANY TEMPLATE-BASED GATE.

METHOD: each template evaluated on den v1 (clone at 99cc0c5a) AND on den-hoag e6c8edc,
with `--override-input den` applied to BOTH ARMS -- never a template's own pin, which is
unmaintained and is not an oracle. Templates copied to scratch; the den repo was not
touched.

★ 8 OF 8 COMPARABLE TEMPLATES: GREEN ON v1, FAIL ON den-hoag. Arm A passes and arm B
fails on every one, SO EVERY ONE IS A REAL den-hoag BLOCKER RATHER THAN TEMPLATE ROT.

  template              v1 arm                        den-hoag e6c8edc
  default               ["igloo"]                     fleet-context enrichment: environment `prod`
                                                      not in registry, available: []
  example               ["igloo"]                     attribute 'name' missing
  fleet-demo            [4 hosts]                     surface totality (C1): unknown `den.systems`
  minimal               ["igloo"]                     The option `flake' does not exist
  microvm               ["server"]                    attribute 'microvm' missing
  diagram-demo          [3 hosts]                     `lib.capture.captureFleet` retired-fx fleet diagnostic
  flake-parts-modules   ["igloo"]                     attribute 'packages-to-flake-parts' missing
  scoped-import-tree    ["igloo"]                     attempt to call something which is not a function
                                                      but a set { __findFile ... }
  (noflake FAILS ON BOTH ARMS with the same path error -- HARNESS, NOT A den-hoag BLOCKER.
   EXCLUDED AND NOT COUNTED.)

★ THE POLICY-RECORD MIGRATION FIXED NONE OF THEM. All FOUR blockers named by the
2026-07-28 design audit reproduce VERBATIM at e6c8edc -- the environments registry, the
`name` attribute, `den.systems`, and `packages-to-flake-parts` -- PLUS TWO THE AUDIT DID
NOT NAME: `captureFleet` and the `__findFile` call error.

⇒ ★★ THE TEMPLATE SUITE IS NOT A LIVE GATE ON THE COMPAT LAYER, AND THAT IS THE POINT OF
THIS BEAD. nix-config is the ONLY fleet in the corpus that evaluates, which means:
· every compat finding is currently witnessed by ONE fleet;
· nix-config is immune to den-hoag-4kh.53.2's A1 SOLELY by an accident of its own topology
  file, so the corpus cannot show that defect at all;
· any claim of the form "the corpus is green" covers a single witness, not a suite.
Several children of den-hoag-4kh.53 are written assuming templates are not a gate. THEY
REMAIN CORRECT TO ASSUME SO until this bead closes.

★ AND A METHOD NOTE WORTH MORE THAN THE LIST: THE CONTROL CORRECTED THE MEASURER
MID-RUN. `minimal` and `microvm` fail with `The option 'flake' does not exist` and
`attribute 'microvm' missing` -- both of which READ LIKE TEMPLATE ROT and would have been
discounted as such. The v1 arm shows BOTH GREEN. ⇒ WITHOUT THE TWO-ARM CONTROL, TWO REAL
den-hoag BLOCKERS WOULD HAVE BEEN DISMISSED AS SOMEONE ELSE'S PROBLEM. A one-arm template
run is not evidence about den-hoag.

SCOPE: this bead is the CENSUS, not the fixes. Each blocker is its own diagnosis -- some
may share a cause and the list must not be treated as six independent items until one
instance is chased to a mechanism. That method (one instance, chased, then ask whether the
class shares it) is what worked across the whole policy-record migration and what failed
every time it was skipped.

## Comments (0)

(none)
