# Schema processing at the flake-parts boundary (ship-gate M1.75). v1's `options.den.schema` is a gen-schema
# `mkSchemaOption` that turns raw kind DECLARATIONS (`den.schema.<K> = { parent; options; isEntity; … }`) into
# gen-schema KIND-VALUES `{ kind; strict; refs; options; validators; refinements }`. A corpus module reads that
# processed value at declaration time (`options.den.clusters = mkInstanceRegistry den.schema.cluster`), so the
# bridge reproduces the processing (else the corpus's own mkInstanceRegistry throws `attribute 'refs' missing`).
# The bridge does it as an `apply` on `options.den.schema` running the shim's OWN gen-schema in a NESTED eval
# (gen-schema types never enter the consumer's nixpkgs eval — the type-crossing dodge), with the RAW
# declarations stashed under `__rawSchema` for the SHIM (definitions-vs-value split: corpus ← processed,
# shim ← raw, since the shim re-processes and would double-declare `_kindNames`).
#
# This witness reproduces the corpus's schema/cluster.nix pattern as close as den-hoag CI can WITHOUT the
# corpus's own gen-schema input: it asserts the bridge PRODUCES a contract-shaped kind-value at
# config.den.schema.<K>, and stashes the raw. FIDELITY LIMIT: it does not run the corpus's exact
# mkInstanceRegistry rev — that consumption is re-proven by every ship-gate probe (a produced kind-value
# missing a contract field surfaces there as a named `attribute '<f>' missing`, the M1.75 loudness).
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  mkCrossNixos =
    npkgs:
    (import "${denHoagSrc}/lib/output/terminal.nix" {
      inherit (denHoag.internal) bind flake;
    } { nixpkgs = npkgs; }).crossNixos;
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    inherit mkCrossNixos;
    schema = denHoag.internal.schema;
    denLib = denHoag;
  };
  # The SAME bridge with the opaque pass-through SEAM severed (`passThrough = false`) — the processed
  # kind-value path. Its severability is the belt-and-suspenders isolation guarantee: the seam is one flag.
  bridgeSevered = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    inherit mkCrossNixos;
    schema = denHoag.internal.schema;
    denLib = denHoag;
    passThrough = false;
  };
  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
  # A custom `rack` kind declared corpus-style ACROSS FOUR MODULES: `options.slots` in one, `parent` in
  # another, and `includes` in TWO more. The includes case is the fix-A regression: two modules each append
  # a kind-attached include to `den.schema.rack.includes`. Under the old `lazyAttrsOf anything` pre-merge
  # those two lists CONFLICTED (types.anything never concatenates lists); fix A collects the raw defs and
  # lets the nested mkSchemaOption's OWN merge (a list-default collection) concatenate them, as v1 does.
  # A `widget` kind exercises OPAQUE PASS-THROUGH: its option (`marker`) is declared corpus-style through a
  # nixpkgs `imports` module, and `isEntity` is set — the kind-value must ride the RAW nixpkgs option module
  # through (so the corpus's own gen-schema builds the instance type at its pin), not a gen-schema transform.
  incl = name: { inherit name; };
  fixtureModules = [
    {
      den.schema.rack = {
        options.slots = lib.mkOption {
          type = lib.types.int;
          default = 0;
        };
      };
    }
    { den.schema.rack.parent = null; }
    { den.schema.rack.includes = [ (incl "i1") ]; }
    { den.schema.rack.includes = [ (incl "i2") ]; }
    {
      den.schema.widget = {
        isEntity = true;
        imports = [
          (_: {
            options.marker = lib.mkOption {
              type = lib.types.str;
              default = "M";
            };
          })
        ];
      };
    }
    # A SYNTHETIC kind declaring a METHOD (u8 path 1) — the corpus's `den.schema.cluster.methods.*`
    # declaration shape (`schemaFn <desc> <type> <fn>`; the fn takes its arg-names off the INSTANCE
    # config). The bridge re-injects gen-schema's methods module into the belt's `__functor`, so a
    # mounted `greeter` instance carries `greet`, computed KIND-GENERICALLY from its OWN `who` field —
    # NO cluster/method knowledge in the shim.
    {
      den.schema.greeter = {
        isEntity = true;
        imports = [
          (_: {
            options.who = lib.mkOption {
              type = lib.types.str;
              default = "world";
            };
          })
        ];
        methods.greet =
          denHoag.internal.schema.schemaFn "greet helper" (lib.types.functionTo lib.types.str)
            (
              { who, ... }:
              suffix: "hi-${who}-${suffix}"
            );
      };
    }
  ];
  ev = lib.evalModules {
    modules = [
      flakeStub
      bridge
    ]
    ++ fixtureModules;
  };
  # The severed (passThrough = false) eval — same fixture, the processed kind-value path.
  evSevered = lib.evalModules {
    modules = [
      flakeStub
      bridgeSevered
    ]
    ++ fixtureModules;
  };
  kv = ev.config.den.schema.rack;
  rawRack = ev.config.den.schema.__rawSchema.rack or { };
  widgetKv = ev.config.den.schema.widget;
  widgetKvSevered = evSevered.config.den.schema.widget;
  # Mount the kind-value as a module exactly as the corpus's gen-schema mkInstanceType does (imports = [ kv ]),
  # in a NIXPKGS evalModules — the option-crossing that threw `deprecationMessage missing` before.
  widgetMounted = lib.evalModules { modules = [ widgetKv ]; };

  # ── u8 path 1: METHODS re-injection through the belt ────────────────────────────────────────────────
  greeterKv = ev.config.den.schema.greeter;
  # Mount the greeter instance (NIXPKGS evalModules, as the corpus's mkInstanceType does): the re-injected
  # methods module must cross the strict eval and compute `greet` from the instance's OWN `who` field.
  greeterMounted = lib.evalModules { modules = [ greeterKv ]; };
  greeterMountedOverride = lib.evalModules {
    modules = [
      greeterKv
      { who = "moon"; }
    ];
  };
  # NO-METHODS byte-identity: widget declares no methods ⇒ its `__functor` imports = `rawImportsOf` ALONE
  # (no methods module appended); greeter declares one method ⇒ exactly ONE extra import (the methods module).
  widgetFunctorImports = (widgetKv.__functor null null).imports;
  greeterFunctorImports = (greeterKv.__functor null null).imports;
  # readOnly posture: a method option is readOnly, so a consumer def colliding with the method name is
  # REJECTED by the module system (two definitions of a read-only option).
  greeterCollision = builtins.tryEval (
    let
      e = lib.evalModules {
        modules = [
          greeterKv
          { greet = _: "override"; }
        ];
      };
    in
    builtins.seq (e.config.greet) true
  );
in
{
  flake.tests.compat-schema-processing = {
    # the apply produces a gen-schema KIND-VALUE carrying the contract fields a mkInstanceRegistry reads,
    # deep-merged across modules (options.slots from one, kind/parent processed from others).
    test-kind-value-contract = {
      expr = {
        kind = kv.kind or "<none>";
        hasRefs = kv ? refs;
        hasOptions = (kv.options or { }) ? slots;
        hasValidators = kv ? validators;
      };
      expected = {
        kind = "rack";
        hasRefs = true;
        hasOptions = true;
        hasValidators = true;
      };
    };
    # FIX A — the includes CONFLICT flips to a CONCAT: two modules' `den.schema.rack.includes` concatenate
    # via gen-schema's own collection merge, on BOTH the processed kind-value (corpus-facing) and the shim's
    # extracted raw. Order = definition order (v1 parity: i1 before i2).
    test-includes-concatenated = {
      expr = {
        processed = map (i: i.name) (kv.includes or [ ]);
        rawForShim = map (i: i.name) (rawRack.includes or [ ]);
      };
      expected = {
        processed = [
          "i1"
          "i2"
        ];
        rawForShim = [
          "i1"
          "i2"
        ];
      };
    };
    # the shim's raw schema (definitions-vs-value split) carries exactly what the shim reads — kinds
    # (attrNames), `parent` (buildSchema) and concatenated `includes` (kindIncludesOf) — EXTRACTED from the
    # processed kind-values (fix-A wrinkle (i): single source of truth, no second merge). `options` ride the
    # processed value (test-kind-value-contract), not the shim's raw.
    test-raw-schema-shape = {
      expr = {
        stashed = ev.config.den.schema.__rawSchema ? rack;
        hasParent = rawRack ? parent;
        hasIncludes = rawRack ? includes;
      };
      expected = {
        stashed = true;
        hasParent = true;
        hasIncludes = true;
      };
    };
    # OPAQUE PASS-THROUGH (owner ruling): the kind-value's option MODULE is the corpus's RAW nixpkgs decl,
    # not a gen-schema transform. Mounting it into a nixpkgs evalModules (as the corpus's mkInstanceType does)
    # yields `marker` at its raw default AND with a NIXPKGS type — `type ? deprecationMessage` is TRUE for a
    # nixpkgs type and FALSE for a gen-schema (gen-types) type, so it witnesses the option crossed opaque (the
    # exact crossing that threw `deprecationMessage missing`). `isEntity` survives on the kind-value.
    test-opaque-option-passthrough = {
      expr = {
        isEntitySurvives = widgetKv.isEntity or false;
        markerDefault = widgetMounted.config.marker or "<none>";
        markerIsNixpkgsType = (widgetMounted.options.marker.type or { }) ? deprecationMessage;
      };
      expected = {
        isEntitySurvives = true;
        markerDefault = "M";
        markerIsNixpkgsType = true;
      };
    };
    # SEVERABILITY (belt-and-suspenders isolation): the opaque pass-through is ONE flag. `passThrough = false`
    # toggles it off cleanly, yielding the PROCESSED kind-value path (same kind + structure). The two paths
    # are DISTINCT today: the belt carries the corpus's RAW nixpkgs option (mounts with a nixpkgs type — the
    # cross-pin gap the belt covers), which the processed path does not reproduce for us. SECOND HALF —
    # corpus-result EQUIVALENCE (severed + protocol-complete pins → same result) — activates with the types
    # work, once the processed options also carry the nixpkgs protocol. Retirement then deletes the seam.
    test-passthrough-seam-severable = {
      expr = {
        # the seam toggles cleanly — the severed (processed) path yields a valid kind-value that keeps the
        # BASE structure (kind + isEntity, which rides both paths).
        severedYieldsKind = (widgetKvSevered.kind or "<none>") == "widget";
        severedKeepsStructure = widgetKvSevered.isEntity or false;
        beltKeepsStructure = widgetKv.isEntity or false;
        # the seam's ONLY effect: the belt carries the corpus's RAW nixpkgs option (mounts with a nixpkgs
        # type — the cross-pin gap the belt covers, which the processed path does not reproduce for us today).
        beltCarriesRawNixpkgsOption = (widgetMounted.options.marker.type or { }) ? deprecationMessage;
      };
      expected = {
        severedYieldsKind = true;
        severedKeepsStructure = true;
        beltKeepsStructure = true;
        beltCarriesRawNixpkgsOption = true;
      };
    };

    # u8 PATH 1 — the METHODS SEAM: a mounted instance carries the kind's method, computed KIND-GENERICALLY
    # from the instance's OWN field. `greet` reads `who` off the instance config; the default instance sees
    # `who = "world"`, an override module sees `who = "moon"` — the drop that threw `getAssignment missing`.
    test-method-injected-computes-from-instance-field = {
      expr = {
        default = greeterMounted.config.greet "x";
        overridden = greeterMountedOverride.config.greet "x";
      };
      expected = {
        default = "hi-world-x";
        overridden = "hi-moon-x";
      };
    };
    # NO-METHODS byte-identity: widget (no methods) → `__functor` imports = rawImportsOf ALONE (1 module,
    # unchanged from pre-fix); greeter (one method) → exactly ONE extra import (the injected methods module).
    test-no-methods-kind-functor-byte-identical = {
      expr = {
        widget = builtins.length widgetFunctorImports;
        greeter = builtins.length greeterFunctorImports;
      };
      expected = {
        widget = 1;
        greeter = 2;
      };
    };
    # readOnly posture: a method option is readOnly, so a consumer definition colliding with the method
    # name is rejected by the module system (the injected `config.greet` + the user def = two defs).
    test-method-readonly-collision-rejected = {
      expr = greeterCollision.success;
      expected = false;
    };
  };
}
