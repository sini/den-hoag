# den-hoag-4kh.21 — [decision] posture for a DECLARED kernel surface the engine does not honour — deps / provision / excludes must land ONE posture, not three

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.21` |
| status at evacuation | deferred |
| priority | P1 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T05:08:10Z by Jason Bowman |
| last updated | 2026-08-05T20:48:31Z |
| description bytes | 2359 |
| notes bytes | 0 |
| comments | 2 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

★ DECISION NODE — OWNER RULING REQUIRED. What POSTURE does the kernel take toward a DECLARED SURFACE IT DOES
NOT HONOUR? This must be answered ONCE, before any of its three instances is fixed.

MEASURED (memory-reconcile audit, 2026-07-28, every site verified at HEAD a40cc96):
Three kernel surfaces are DECLARED, ACCEPTED BY THE ENGINE, AND NOT HONOURED — each currently failing in a
DIFFERENT WAY:
  (i)  `deps`      — THROW-ON-READ. lib/concern-derived.nix:88-90 depsPlaceholderMessage, :156
                     `deps = throw depsPlaceholderMessage;`, passed :158 `spec.derive node deps`.
  (ii) `provision`/`adapt` — SILENT NULL. lib/renders.nix:35 "stored SHAPE-ONLY here", :40
                     `provision = raw.provision or null;`; lib/nest.nix:181 same for renderRow.
  (iii) `excludes` — INERT (tracked at den-hoag-9xo.28).

★ WHY THIS IS A DECISION NODE AND NOT THREE TASKS: fixed independently they will land THREE INCOMPATIBLE
POSTURES in one kernel — throw-on-read, silent-null, and inert — for the SAME defect class. The user-visible
contract of "I declared it and the engine took it" would then mean three different things depending on which
field you touched. THIS IS CONTRACT CONSISTENCY, NOT EFFORT. The ruling is cheap; the divergence is not, and
it is not detectable from any one of the three sites.

THE RULING NEEDED — one of:
  (a) HONOUR the surface (wire it, with a witness that composes it), or
  (b) NAMED-REJECT AT DEFINITION TIME — a loud, named error when the field is set, not a throw when it is
      read and not a null when it is consumed, plus a REFERENCE row declaring it out of the facet.
Silent acceptance is not on the menu under either answer: it is the shape that let all three persist.
★ Note (b) is the BY-CONSTRUCTION option — a field that cannot be set cannot be half-honoured — and (a) is
the repair option. See the standing preference for construction over repair, but the surfaces may differ:
the ruling may legitimately split (honour one, reject another) PROVIDED the split is stated as a rule.

CHILDREN / INSTANCES: the `deps` bead, the `provision`/`adapt` bead, and den-hoag-9xo.28. All three BLOCK on
this. Do not work any of them first.

PROVENANCE: proposed by the memory-reconcile audit as its dependency-edge 4, the one structural insight a
flat task list could not have held. Not yet owner-ruled.


## Comments (2)

### 1 — 2026-07-28T10:30:32 · Jason Bowman

★★ THIS BEAD'S PREMISE IS WRONG — THE THREE SURFACES ARE NOT ONE DEFECT CLASS, AND ONLY TWO OF THEM ARE A POSTURE QUESTION. Measured 2026-07-28 when the owner asked for the actual user impact.

★ `excludes` IS A PARITY DEFECT, NOT AN UNHONOURED ASPIRATION. DEN V1 CONSUMES IT: nix/lib/resolve-entity.nix:22 `schemaExcludes = schemaEntry.excludes or [ ]` and :72 `excludes = schemaExcludes`. den-hoag does not (den-hoag-9xo.28, measured with a four-arm eval and a positive control).
AND THE CORPUS USES IT WITH STATED INTENT — nix-config/modules/den/policies/fleet.nix:
  :85-88  `den.schema.flake-system.excludes = [ system-to-os-outputs, system-to-hm-outputs ]`
          comment: 'Fleet handles host instantiation -- exclude default walking policies.'
  :91     `den.schema.host.excludes = [ den.policies.host-to-users ]`
          comment: 'Exclude den's built-in host-to-users (fleet user policies replace it).'
  plus den-configs/slashfiles/modules/schemas/flake-system.nix:5.
⇒ UNDER den-hoag THOSE THREE POLICIES ARE RUNNING WHILE THE CONFIG EXPLICITLY DISABLES THEM, and the author wrote a comment for each explaining why. That is a LIVE PARITY BREAK on a real fleet, not a declared-and-unconsumed surface. THERE IS NO POSTURE CHOICE HERE — named-rejecting it would reject a construct v1 honours and the corpus depends on. It must be HONOURED.

`deps` AND `provision` ARE THE ACTUAL POSTURE QUESTION, AND BOTH ARE INVISIBLE TO USERS TODAY:
  `deps` — corpus `derive` functions take ONE argument. Measured: nix-config/modules/den/schema/cluster.nix:99 is `derive = clusters:`; den-configs/nixfos/.../stylix.nix:36 is `derive = { hm, ... }:`. NOBODY TAKES A SECOND `deps` ARG, so the throwing placeholder is unreachable from the corpus.
  `provision` — ZERO den render-row usage. ★ The corpus `provision =` hits are NIXPKGS' OWN service options (services.grafana.provision at nix-config/.../grafana.nix:81, blocky, noise-station-server) — A DIFFERENT SURFACE THAT MERELY SHARES THE NAME. I had counted them as evidence this surface is used; they are not.

⇒ CORRECTED SPLIT: den-hoag-9xo.28 (`excludes`) LEAVES THIS DECISION NODE and becomes a compat/parity bug with one answer. This bead retains `deps` and `provision`, where the posture question is real and the stakes are low — no user is affected either way today, which makes it a good place to SET the rule rather than discover it under pressure.
★ WHY I GOT IT WRONG, and it generalises: I classified three surfaces by their SYMPTOM — declared, accepted, not honoured — and treated the shared symptom as a shared cause. It is not. One is a missing v1 behaviour with live consumers; two are unbuilt surfaces with none. A defect class must be defined by its CAUSE and its BLAST RADIUS, not by how it looks from the outside.

### 2 — 2026-07-28T10:33:13 · Jason Bowman

★ OWNER RULING, 2026-07-28: NAMED-REJECT AT DEFINITION TIME. Owner: 'we can change the decision later, lets go with that posture for now.'

SCOPE — this covers `deps` and `provision` ONLY. `excludes` LEFT this node: it is a parity defect with live consumers (den-hoag-9xo.28, now P0), and named-rejecting it would reject a construct den v1 honours and nix-config depends on.

THE POSTURE: a declared kernel surface the engine does not honour is REJECTED AT DEFINITION TIME with a loud named error, plus a REFERENCE row declaring it out of the facet. Not a throw when read, not a null when consumed, not silent acceptance. A field that CANNOT BE SET cannot be half-honoured — by construction rather than repair.
CONSEQUENTLY: `deps` loses its parameter from the derive signature entirely rather than remaining a throwing placeholder (lib/concern-derived.nix:88-90, :156, :158), and `provision`/`adapt` are rejected where they are set rather than stored as null (lib/renders.nix:35, :40; lib/nest.nix:181). ★ NOTE renders.nix:35 names FIVE fields — `provision`/`adapt`/`face`/`extendsVia`/`compatibleWith` — and they must be triaged together under this ruling rather than leaving three behind as the next silent residue.

★ EXPLICITLY REVISABLE, AND RECORDED AS SUCH SO NOBODY TREATS IT AS SETTLED THEORY. The owner ruled it as a working posture, not a permanent one. USER IMPACT TODAY IS ZERO, which is what makes it safe to set now and cheap to revisit: measured, no corpus `derive` takes a second argument (nix-config/modules/den/schema/cluster.nix:99 is `derive = clusters:`; den-configs/nixfos/.../stylix.nix:36 is `derive = { hm, ... }:`), and den's render-row `provision` has ZERO corpus usage — the `provision =` hits in the corpus are nixpkgs' own service options sharing the name.
⇒ IF A REAL CONSUMER APPEARS FOR EITHER SURFACE, THAT IS THE SIGNAL TO REOPEN, and the ruling should be read as 'reject until someone needs it' rather than 'these capabilities are refused'. Whoever implements should say so in the rejection message: name the surface, say it is not honoured, and point at this bead — a named error that explains itself is the difference between a closed door and a locked one.
