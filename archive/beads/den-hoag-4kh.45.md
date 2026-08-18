# den-hoag-4kh.45 — [ci] no fixture exercises a DIVERGENT declared slice firing through the staged pre-pass — green cannot distinguish 'never fires' from 'cannot fire'

> Evacuated from the beads payload on 2026-08-17 by strip-back **P10**.
> The bead still exists: id, title, status, priority, labels, parent and every dependency
> edge are unchanged. Only its description was replaced by a pointer stub naming this file.

| field | value |
| --- | --- |
| id | `den-hoag-4kh.45` |
| status at evacuation | open |
| priority | P2 |
| type | task |
| labels | (none) |
| parent | `den-hoag-4kh` |
| created | 2026-07-28T07:08:47Z by Jason Bowman |
| last updated | 2026-08-04T19:48:52Z |
| description bytes | 6433 |
| notes bytes | 0 |
| comments | 1 |
| dependencies | `None` (None) |

## Description

<!-- verbatim; restoring this bead means pasting exactly the block between this marker
     and the next `## ` heading back into the description. -->

MEASURED COVERAGE GAP — NO TEST FORCES A `mkSlice`-BUILT DECLARED SLICE'S PRODUCE THROUGH THE STAGED PRE-PASS.
NOT EVEN INERTLY. The gap is TOTAL.

FOUR `ci/tests/` fixtures use any of the five `producesByName` key names (measured over all 205 files at
`a40cc96`, non-comment lines; positive control same run: `policies\.` → 59 files). EVERY ONE IS STOPPED SHORT
OF THE GUARD, EACH AT A DIFFERENT POINT:
  · `compat-entity-fields.nix:180` — genuinely declared (value-conditional `hubBody`, gated on
    `host.settings.core.network.syncthing.isHub or false`, so the probe is empty → `mkDeclaredSlices` →
    `mkSlice`). ★ But its family is `pipeOp` ⇒ COLLECTION, and the feed admits only `group == "structural"`
    (`lib/concern-policies.nix:420-421`), so IT NEVER ENTERS THE FEED. This is the only `ci/tests/` site where
    the kernel's `producesByName.${name}` lookup (`:357`) supplies a family.
  · `compat-hm-battery.nix:80` — NOT a declared slice. Its body emits unconditionally (`:80-90`), so
    `probeActs` is non-empty ⇒ `expanded = false` ⇒ the `!expanded` branch ⇒ `mkSingle`, and the table is
    NEVER READ. It is the design's own D11. It does still carry `produces = ["member"]` (PROBE-EXTRACTED, not
    declared), is tagged `__resolveFamily` off `rfOf`'s `!expanded` arm (`:377-382`), is structural, enters
    the feed and IS fired by `runPrePass` — ★ but as `mkSingle`, whose produce is `checkedProduce`
    (`:234`→`:160-162`), while the guard under design sits in `mkSlice` (`:250-270`).
  · `compat-resolve.nix:463` — `kiFeedIds` (`:223-225`) runs `denHoag.internal.compilePolicies` IN ISOLATION.
    No fleet, therefore NO `runPrePass` AT ALL — not merely an unforced produce.
  · `compat-feature-severed.nix:430` — wires `env-to-hosts` as a `rack.includes` kind-include
    (`kiResolveFixture` `:422-441`), value-conditional, family via the compat `__produces` stamp. Reads only
    `compileFull … .__resolveFamily` (`:442-445`), and `compileFull` is the compat compile stage
    (`lib/compat/default.nix:492-496`) — so IT NEVER BUILDS A RULE AT ALL. Stopped earliest of the four.
BOTH PRE-PASS FEEDS CHECKED, not just the first: `excludeRules = policiesRules.excludeFamily`
(`lib/default.nix:1111`, `staged-resolution.nix:204`) applies the same `group == "structural"` filter, and
none of the four sites emits `suppress`.

★ WHY IT MATTERS: with the design's core applied, a named abort becomes raisable FROM INSIDE the construct
tracked for retirement at `den-hoag-4kh.18`, and the 1914/1914 green suite is the ONLY evidence that path is
inert. GREEN CANNOT DISTINGUISH "the guard never fires here" FROM "the guard cannot fire here."

ACCEPTANCE: one fixture authoring a declared `structural` policy inside a `mkDen` fleet whose body emits a key
OUTSIDE its declaration, asserted to abort NAMED through the pre-pass path — red before the design's core,
green after, with a positive control on an aligned declaration that must NOT abort.
★ THE FIXTURE MUST BE VALUE-CONDITIONAL, AND THIS IS PROVEN, NOT ADVISORY: a probe-emitting body takes the
`!expanded` branch, compiles to `mkSingle`, never consults the table, and would silently exercise D11 —
PASSING WHILE MEASURING NOTHING. That is the same shape as the gap itself.
INSTRUMENT LIMIT: `mkCi`'s asserter has NO message-text channel (`ci/tests/_lib/den-compat-test.nix:27`) and
`builtins.tryEval` yields only a bool, so the NAMING must be pinned out-of-suite — the same constraint that
forced `den-hoag-4kh.13`'s naming witness out of the suite. Tracked as `den-hoag-9mo`.

★ THIS BODY WAS REWRITTEN 2026-07-28. Its first version asserted that `compat-hm-battery.nix:80` DOES fire a
declared slice and is "inert only because the body emits exactly the declared member" — BOTH SENTENCES FALSE.
That came from an agent's self-correction which was itself wrong and which the orchestrator propagated without
re-deriving. Corrected by execution; full case at `den-hoag-4kh.20`. Recorded here because the earlier version
understated the gap as partial when it is total, and because A CORRECTION BELONGS IN THE BODY, NOT ONLY IN A
COMMENT — a comment is a supplement for a reader who reaches it; the body is what a dispatch quotes.


════ ★★ RE-ANCHOR 2026-08-04 — EVERY ANCHOR IN THIS BODY IS DEAD AT HEAD. ★ THIS IS NOT A CLOSE. ════
Orchestrator-reproduced by command, both revs in one run:
  for s in mkSlice mkDeclaredSlices checkedProduce probeActs mkSingle; do
    git grep -c "$s" <rev> -- lib/ ci/ ; done
  at a40cc96 (THIS BEAD'S OWN MEASUREMENT REV) → 1 file each, all lib/concern-policies.nix
  at ffaafb8  (HEAD)                           → 0, 0, 0, 0, 0
  `git merge-base --is-ancestor a40cc96 ffaafb8` → YES (so the comparison is along history, not across it)
SOLE REMOVING COMMIT: `git log -S"mkSlice" --oneline a40cc96..ffaafb8 -- lib/ ci/` → e6c8edc, one hit,
"feat(kernel): a policy declares what it emits, and the kernel checks it" — whose own message declares the
dissolution: "the probe, its sentinel, the three-way expansion fan, `strip`, and four kernel options all
dissolve."
SUCCESSOR, positive control same run: `conformingProduce` is present at ffaafb8 (lib/compat/compile.nix,
lib/compat/policy-recover.nix, lib/compat/exclude-family-names.nix, lib/compat/resolve-family-names.nix).

★★★ ABSENCE OF THE ANCHOR IS NOT DISCHARGE OF THE QUESTION. This bead's question — that a green result cannot
distinguish "never fires" from "cannot fire" — is about a PROPERTY OF THE ORACLE, not about the five deleted
bindings. The mechanism was replaced; whether the successor reproduces the blind spot is UNMEASURED, and it
must be RE-MEASURED against `conformingProduce`, never inherited. A weak lead offered as a lead and not as a
finding: the ci-side `conformingProduce` hits read as comment lines, which would suggest a fixture gap — but a
fixture can exercise a construct without naming it, so that observation cannot settle anything on its own.
⇒ The re-anchoring is done; the bead stays OPEN on its unmoved question.

★ HOW THIS WAS MISSED, recorded because it is a general defect in the sweep instrument rather than an
accident here: this bead was created 2026-07-28T07:08:47Z and e6c8edc landed the SAME DAY, ~17 hours later,
naming no bead id in its subject. The bead was correct when filed and was mooted by a landing that left no
trace on it. A marker-in-title sweep cannot see this class at all — see den-hoag-4kh.20 for the case.


## Comments (1)

### 1 — 2026-07-28T07:25:58 · Jason Bowman

★ CORRECTION — THIS BEAD'S PREMISE WAS BUILT ON A REFUTED SELF-CORRECTION, AND THE FINDING IS NOW STRONGER, NOT WEAKER.

I recorded that ci/tests/compat-hm-battery.nix:80 DOES fire a declared structural slice through runPrePass, inert only because its body emits exactly the declared `member`. MEASURED FALSE by an independent confirmation pass: `env-users` there is NOT a declared slice at all. Its body emits at the VALUE-LESS PROBE, so `mkRules` takes the `!expanded` branch → `mkSingle`, and `producesByName` IS NEVER READ. It is the design's own D11 case. Established with a four-way branch discriminator whose same-run control proves the instrument can see the table being consulted (see den-hoag-4kh.20).

⇒ THE CORRECTED AND STRONGER BOUND, measured at a40cc96: only TWO ci/tests/ fixtures use any of the five table-key names — compat-entity-fields.nix:180 and compat-hm-battery.nix:80 (positive control same run: `policies\.` → 70 files). The FIRST declares `pipeOp` ⇒ collection, so it NEVER ENTERS THE FEED (concern-policies.nix:420-421 admits only `group == "structural"`). The SECOND is `mkSingle`. And compat-resolve.nix:463 puts a real declared structural rule in the feed but forces only `r.identity`.
★ SO NO TEST FORCES A `mkSlice`-BUILT DECLARED SLICE'S PRODUCE THROUGH `runPrePass` — NOT EVEN INERTLY. The gap this bead tracks is TOTAL, not partial. My original framing understated it by claiming an inert-but-exercised path exists; there is none.

THE ACCEPTANCE CRITERION IS UNCHANGED AND NOW BETTER MOTIVATED: a fixture authoring a declared `structural` policy inside a mkDen fleet whose body emits outside its declaration, asserted to abort NAMED through the pre-pass path, red before the core and green after, with a positive control on an aligned declaration that must NOT abort.
★ AND ONE CONSTRAINT IS NOW PROVEN RATHER THAN ASSUMED: the fixture MUST be value-conditional. A probe-emitting body takes the `!expanded` branch and never consults the table, so a fixture written the obvious way would silently test D11 instead of the declared path — passing while measuring nothing. That is the same shape as the coverage gap itself.
