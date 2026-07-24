# Plan — flake-output classes as an opt-in feature (`den.features.flakeOutputClasses`, default OFF)

Branch: `fix/nested-aspect-nav` (off main @f1c2a96). den v2 = TERMINAL classes; v1's navigable-classes CUT;
flake-output classes opt-in (owner verdict D; RELEASE-NOTES-den-v2.md / memory project_den_v2_terminal_classes).

## 0. Problem (recap) + owner decision

The corpus role `roles/darwin-workstation` navigates `with den.aspects; [ macos.apps.karabiner ]`.
`apps` is one of five v1 flake-SYSTEM-OUTPUT names (`packages`/`apps`/`checks`/`devShells`/`legacyPackages`)
registered UNCONDITIONALLY as den classes by `lib/compat/builtins.nix:536-550` (faithful to v1
`modules/policies/flake.nix:41`, which v1's `nix/flakeModule.nix` loads on every fleet — verified: NOT a
den-hoag over-reservation). gen-aspects types a class-named nested key as an opaque `deferredModule`
(TERMINAL — correct for a class), so `macos.apps` drops `karabiner`/`raycast` → `attribute 'karabiner' missing`.

Owner decision **D** (den v2 diverges from v1, deliberately): flake-output classes become an OPT-IN
feature, default OFF. OFF ⇒ the 5 names are NOT classes ⇒ `macos.apps` is a plain NAMESPACE ⇒
`macos.apps.karabiner` navigates NATIVELY (no splice, no `looksLike`, no terminal workaround). This is a
conscious v1-behavior-change, output-neutral because the 5 classes are corpus-INERT (no aspect emits to
them; no routes/members; den-hoag can't emit anyway — emission is board #51, unbuilt).

## 1. The gate (compat-only, no kernel touch)

### 1a. `lib/compat/builtins.nix` — gate the 5 flake-output class registrations

- Add a curry arg alongside `fleetContext`: `flakeOutputClasses ? true` (module-intrinsic default true,
  mirroring `fleetContext ? true`; the FLEET default is set OFF in `defaultFeatures`, §1c). Doc-comment it
  as the `den.features.flakeOutputClasses` gate (the `fleetContext` precedent, `:50-54`).
- Split the `classes = { … }` literal (`:495-559`): keep `flake-parts`/`wsl`/`maid`/`hjem`/`k8s-manifests`
  ALWAYS registered; move ONLY the five `packages`/`apps`/`checks`/`devShells`/`legacyPackages` behind the
  gate. Because the block must force `config.den.classes` WITHOUT `prelude` (the dummy-args unit,
  `compat-builtin-classes.nix`), gate with a prelude-free literal merge:
  ```nix
  classes = {
    flake-parts = { … }; wsl = { … }; maid = { … }; hjem = { … }; k8s-manifests = { … };
  } // (if flakeOutputClasses then {
    packages = { … }; apps = { … }; checks = { … }; devShells = { … }; legacyPackages = { … };
  } else { });
  ```
- Comment cites the MECHANISM (v1 flake-output classes are opt-in in den v2; OFF ⇒ the name is a plain
  aspect namespace, ON ⇒ registered for classification + the board-#51 emission when that lands). NO
  corpus names (karabiner/macos) in `builtins.nix`.
- The ON-path EMISSION (v1's `mkOutputPolicy` route `fromClass=<output> intoClass=flake`, gated by
  `has-flake-output`) is board #51 / UNBUILT — NOT provisioned here. ON only re-registers the classes for
  classification (inert, exactly like today). Note as latent in the register.

### 1b. `lib/compat/default.nix` — thread the feature

- `mkBuiltinsModule` (`:168-174`): `inherit (feat) fleetContext flakeOutputClasses;`.

### 1c. `lib/compat/default.nix` — `defaultFeatures` + totality

- Add `flakeOutputClasses = false;` to `defaultFeatures` (`:248-258`). ★ This is the FIRST opt-in
  (default-OFF) feature; it DELIBERATELY breaks the "all-on ≡ today byte-identical" invariant (§2.1 comment
  at `:206-211`) because choice D CHANGES the default (de-registration). Update that comment block to carve
  out `flakeOutputClasses` as the documented opt-in exception (default-off; ON restores the v1 registration).
- Totality known-set: `mkWiringWith`'s `unknown` check (`:265`) reads `attrNames defaultFeatures`, so adding
  the key AUTO-extends the abort boundary — no separate list. (Confirm: `mkWiringWith { flakeOutputClasses = true; }` is accepted, a typo `flakeOutputClass` aborts named.)

### Effect

`mkWiring`/`mkDen`/`mkDenWith`/`mkWiringWith { }` → `flakeOutputClasses = false` → the 5 classes absent →
`macos.apps` native namespace → karabiner navigates. `mkWiringWith { flakeOutputClasses = true; }` →
registers them (today's inert behavior).

## 2. Unit: `ci/tests/compat-builtin-classes.nix` — reflect the new default

The unit imports `builtins.nix` with dummy args and asserts the FULL v1 built-in class set present
(`builtinClassNames` incl. the 5). Update:

- Split `builtinClassNames` into `alwaysClassNames` (flake-parts/wsl/maid/hjem/k8s-manifests) and
  `gatedFlakeOutputNames` (the 5).
- Read TWO views: `builtinsModOff = import … { …; flakeOutputClasses = false; }` (the FLEET default) and
  `builtinsModOn = import … { …; flakeOutputClasses = true; }`.
- Assert: `alwaysClassNames` present in BOTH; `gatedFlakeOutputNames` ABSENT in `…Off`, PRESENT in `…On`.
- Keep the existing synthetic wsl-emit / corpus-companion / §2.2-abort witnesses (unaffected — wsl stays
  always-registered).
- Dummy-args note: the `classes` values stay literals; `flakeOutputClasses` is a bare bool, forces without
  prelude/errors/declare — the prelude-free-read invariant holds.

## 3. Removability gate row: `ci/tests/compat-feature-severed.nix`

Add a `flakeOutputClasses` block. Semantics INVERT the usual (default-OFF opt-in), so `full = denCompat`
(`mkWiringWith { }`) has the feature OFF; drive an explicit-ON wiring for the register side:

```nix
onFlakeOutput = denCompat.mkWiringWith { flakeOutputClasses = true; };
classPresent = w: (w.builtinsModule.config.den.classes or { }) ? apps;   # builtinsModule is an attrset module
```

- `test-flakeOutputClasses-default-off-absent`: `classPresent full` == false (default OFF ⇒ not a class).
- `test-flakeOutputClasses-on-present`: `classPresent onFlakeOutput` == true (opt-in registers — non-vacuous).
- ★ CONTENT-COMPILATION teeth (the ambientBatteries lesson; ABSENCE-assert, NOT tryEval-on-native-miss —
  the S2 lesson): drive a content-bearing fixture that uses a flake-output NAME as a NAMESPACE dir through
  the DEFAULT-OFF wiring and prove it (i) compiles clean and (ii) navigates:
  ```nix
  nsFixture = {
    hosts.x86_64-linux.axon.class = "nixos";
    quirks.q = { };
    aspects.parent.apps.leaf = { q = [ "x" ]; nixos.environment.variables.FROM_LEAF = "yes"; };
    aspects.carrier.includes = [ "parent.apps.leaf" ];   # or a `with den.aspects` include shape
    schema.host.includes = [ "carrier" ];
  };
  ```
  - `test-flakeOutputClasses-off-namespace-compiles`: `deepSeq (full.compileFull nsFixture).aspects` via
    tryEval → success (compiles clean; mirrors `compilesCleanContent`).
  - `test-flakeOutputClasses-off-namespace-navigates`: a POSITIVE assertion the leaf content lands with OFF
    (e.g. the host binding carries `FROM_LEAF`, or `(full.evalV1 [nsFixture]).aspects.parent.apps ? leaf`
    == true). Positive/absence style — never tryEval a native miss.
  - Mutation-proof (no tryEval-on-miss): `test-flakeOutputClasses-on-reserves` = `classPresent onFlakeOutput`
    (the re-registration that WOULD break the namespace nav — the mutation witness, asserted structurally).

## 4. Witness: `ci/tests/den-behavioral/flakeoutput-namespace-nav.nix`

Co-locate with `deep-nested-separate-imports.nix`, on the `_lib/den-compat-test.nix` scaffold (which uses
`mkDen` ⇒ `flakeOutputClasses` OFF by default). Depth-3 `a.apps.c` where `apps` is a flake-output NAME used
as a NAMESPACE and `c`'s content keys are REGISTERED (a quirk + a class — mirror the karabiner shape):

```nix
den.quirks.q = { };
den.aspects.a.apps.c = { q = [ "x" ]; nixos.environment.variables.FROM_C = "yes"; };
den.hosts.x86_64-linux.igloo.class = "nixos";
den.aspects.igloo.includes = [ den.aspects.a.apps.c ];   # navigate a.apps.c
expr = { hasC = igloo.environment.variables ? FROM_C; };
expected = { hasC = true; };
```

Navigates with the feature OFF (default). Mutation-provable: the coupled removability row (§3) proves ON ⇒
`apps` reserved ⇒ the namespace nav breaks. (Use the scaffold's registered class `nixos`; `q` a declared
quirk — both give `c` recognized content keys so it is unmistakably an aspect, mirroring karabiner's
`homebrew-cask`/`darwin`.)

## 5. Register + release notes (v1-divergence honesty)

- `papers/den-architecture/specs/compat-feature-register.md`: add the `flakeOutputClasses` entry — Tier
  (compat built-in class registration), trigger (a fleet emitting to a flake system output), removability
  (default OFF; opt-in ON restores v1's global registration), coupling (none — the 5 classes are inert;
  ON-emission is board #51/unbuilt, note as latent), v1-DIVERGENCE (v1 registers the 5 unconditionally;
  den v2 gates them, output-neutral because inert). Follow the sibling-entry format (Tier/trigger/removability
  rows). Docs live in the papers repo per project convention (not committed to den-hoag).
- RELEASE-NOTES-den-v2.md: record "flake-output classes (packages/apps/checks/devShells/legacyPackages) are
  opt-in via `den.features.flakeOutputClasses` (default off); `den.classes` no longer carries them by
  default (v1 did) — output-neutral (inert)." (Owner already recorded the terminal-classes decision there.)

## 6. Gate (all, SEE exit 0)

- `nix build ./ci#checks.x86_64-linux.default` → CI=0
- `nix build ./parity#checks.x86_64-linux.default` → PARITY=0
- `nix eval --impure --json --expr '(import ./parity/ship-gate.nix { flakePath = toString ./parity; }).allEqual'`
  → true. (`allEqual = (v1DrvPath == shimDrvPath) && channels.*` on igloo/bare fixtures — none use
  flake-output classes ⇒ expected NEUTRAL.)
- Parity goldens: expected NEUTRAL — the 5 classes are corpus-inert (no member ⇒ no edge/node); ship-gate +
  parity-structural fixtures (topologies.nix/pipe-stages.nix) don't declare a flake-output-class member
  (verified). If any structural golden shifts, RE-DERIVE per `parity-structural.nix:9-11` convergence-bump
  with the single-edge guardrail (only the intended change).
- ★ REAL corpus: `cd ../nix-config && nix eval '.#darwinConfigurations.patch.config.system.build.toplevel.drvPath' --override-input den ../den-hoag --impure --show-trace` → PAST `karabiner missing` (later
  darwin-materialization errors are a separate out-of-scope gap; confirm karabiner resolved).
- `just fmt` (127 → `nix fmt`) before committing.

## 7. Scope + LOC + v1-faithfulness

- Compat-only: `builtins.nix` (+curry arg, gate 5 classes), `default.nix` (mkBuiltinsModule inherit +
  defaultFeatures entry + comment carve-out), `compat-builtin-classes.nix` (split + two views),
  `compat-feature-severed.nix` (one block), the witness, the register, the release notes. NO kernel touch,
  NO gen-aspects touch, NO nav-typing/splice (choice D supersedes the A-splice/D-1/looksNested work — noted,
  not pursued).
- Est. LOC: ~25 (builtins.nix + default.nix) + ~25 (compat-builtin-classes.nix) + ~35 (severed rows) + ~40
  (witness) + docs. Small, mechanical, well-precedented (the fleetContext/battery gate pattern).
- v1-faithfulness: this is a DELIBERATE v1-divergence (den v2 terminal-classes model), output-neutral for
  the corpus. den.classes lacks the 5 by default; documented in the register + release notes. If a future
  fleet opts IN and also uses one of the 5 names as a namespace, the collision returns and would need the
  v1-style navigable-class mechanism — out of scope, ledgered.

## Deviations / notes for the reviewer

- `flakeOutputClasses` is the first default-OFF feature — it breaks the `defaultFeatures` all-on invariant
  by design; the §2.1 comment must be updated to carve it out (else the invariant reads as violated).
- `compat-builtin-classes.nix` currently asserts the 5 present unconditionally — it MUST be updated, else it
  reddens once the fleet default is OFF.
- The removability teeth use POSITIVE/structural assertions (namespace navigates OFF; class present ON), NOT
  tryEval over the ON native-miss (the S2 lesson) — the nav-break on ON is the uncatchable ceiling, witnessed
  via the clean structural `classPresent onFlakeOutput` fact.
