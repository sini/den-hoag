# The OUTPUT BRIDGE (ship-gate M1) — den-hoag's flake-parts-side assembly: the single splice mechanism
# that mounts the shim's evaluated fleet at flake-parts option targets (D8). It is what a consumer's
# `imports = [ inputs.den.flakeModule ]` merges into its STRICT flake-parts eval, replacing the bare
# option-declaring export: it DECLARES `options.den`, reads back `config.den`, runs the compat assembly,
# and SETS `config.flake.nixosConfigurations` / `darwinConfigurations` — the drop-in `den` output face.
#
# TWO-EVAL BRIDGE (the C1 boundary at the flake-parts seam; resolves the gen-schema↔nixpkgs type crossing):
# the consumer eval is nixpkgs flake-parts (strict), which CANNOT process gen-schema option types
# (`substSubModules` is a nixpkgs-only method). So the flake-parts-side `options.den` is declared with the
# consumer's NIXPKGS `lib` (the injected module arg — this bridge is the SECOND sanctioned nixpkgs touch,
# after the terminal; it IMPORTS no nixpkgs, lib/** import-purity intact) as a freeform SUBMODULE
# (`freeformType = anything`): den's rich v1 grammar rides through as inert data, DEEP-MERGED across the
# corpus's many `den.*` modules exactly as v1's typed option did (respecting `mkDefault`/`mkForce`), while
# the submodule form remains a legal parent for the `options.den.<x>` sub-options a consumer declares. The
# shim then runs its OWN gen-schema `evalModuleTree` INTERNALLY (`mkDenWith` → `evalV1`) on the single,
# pre-merged `config.den` def — so gen-schema types never enter the consumer's evalModules.
#
# INSTANTIATION (D7): a fleet's per-host nixpkgs crossing is a DECLARED instantiation — the corpus sets
# `host.instantiate = <channel>.nixosSystem` (nix-config schema/host.nix:325, a SCHEMA-DECLARED default,
# not an authored per-host field). Ship-gate M2 honors it in TWO halves: the compat nixos wrapper
# (flake-module.nix mkNixosInstantiate) crosses a host through its own evaluator when `instantiateFor`
# yields one, and the shim-declared HOSTS REGISTRY (`options.hosts` below — the bridge-registry
# passthrough, registry.nix; v1's own `options.den.hosts = types.hostsOption` auto-declaration, pin
# 11866c16 modules/options.nix:71) MATERIALIZES the schema default so `instantiateFor` sees it at all —
# v1 materialized it by evaluating each host through the kind's instance submodule (pin 11866c16
# nix/lib/entities/host.nix:53-57), and the declared option runs EXACTLY that eval; raw authored decls
# alone never carry it. The M1 global-fallback grain remains underneath: when `den.nixpkgs` is
# supplied, instantiate-less nixos members cross through one `crossNixos` (real NixOS systems), else
# the nixpkgs-free `collect` terminal (the member keys are present — a non-empty `nixosConfigurations`
# — with inspectable module artifacts, not built systems). `den.darwin` is the symmetric fallback; the
# per-host darwin crossing is the class-B arm (the wrapper is nixos-stamped only). `mkDen`/`mkDenWith`/
# `evalV1` are UNTOUCHED (Law preservation): the bridge is flake-parts-side assembly only, so the
# parity harness (which drives `mkDen` directly) and den-hoag's own mkDen-direct paths stay
# byte-identical (no bridge ⇒ no registry eval ⇒ `instantiateFor` reads authored fields alone).
#
# `mkCrossNixos nixpkgs` — the `crossNixos` builder closure (flake.nix threads `lib.internal.{bind,flake}`
# + the terminal source); called with the consumer-supplied `den.nixpkgs` at fold time.
{
  compat,
  mkCrossNixos,
  schema,
  denLib,
  # `passThrough` (default true) — the belt/suspenders toggle for the opaque option pass-through SEAM
  # (see `passThroughSeam` in the schema apply). true = the BELT is active (raw option decls ride through
  # to the corpus's own gen-schema); false = SEVERED (the processed kind-values flow, same-contract once
  # the consumer's gen-schema is protocol-complete). The severability witness drives both.
  passThrough ? true,
}:
{
  lib,
  config,
  options,
  ...
}:
let
  # v1's OWN deep-merge shape (pin 11866c16 nix/lib/aspects/types.nix:478-490), the ONE fold shared by
  # the `options.default` and `options.aspects` declared-option instances: colliding ATTRSETS recurse,
  # colliding LISTS concatenate, everything else (scalars AND fns — never merged, never wrapped) keeps
  # last-def-wins.
  v1DeepMerge =
    a: b:
    a
    // builtins.mapAttrs (
      bk: bv:
      if !(a ? ${bk}) then
        bv
      else if builtins.isAttrs a.${bk} && builtins.isAttrs bv then
        v1DeepMerge a.${bk} bv
      else if builtins.isList a.${bk} && builtins.isList bv then
        a.${bk} ++ bv
      else
        bv
    ) b;

  # board #58 (Fork A): the `__provider`-annotated fleet surface — ONE post-fold walk over the merged
  # `den.aspects` tree (compat.annotateAspects, annotate.nix; v1 annotateDeep, pin types.nix:561-574),
  # feeding BOTH consumers below: the corpus policy closures' `den` module arg (the navigation surface
  # a dispatch-emitted `den.aspects.<path>` include reads) and the fleet def handed to the shim (the
  # navigation surface an aspect's `with den.aspects` includes read via compile). POST-fold, never
  # inside `v1DeepMerge` — the fold's recurse-only-on-collision property is the load-bearing
  # formals-preservation mechanism (`options.aspects` comment) and stays byte-identical. The fleet's
  # declared classes/quirks feed the walk's exclusion guard (v1 reads its own registries the same way,
  # types.nix:540-542).
  annotatedDen = config.den // {
    aspects = compat.annotateAspects {
      classNames = builtins.attrNames (config.den.classes or { });
      quirkNames = builtins.attrNames (config.den.quirks or { });
    } (config.den.aspects or { });
  };
in
{
  # nixpkgs-native raw absorption: a freeform SUBMODULE whose `freeformType` deep-merges the whole `den.*`
  # surface (v1 grammar as inert data), and — being a submodule, not a leaf — is a legal PARENT for the
  # `options.den.<x>` sub-options a consumer declares in its own modules (nix-config declares typed
  # `den.clusters`/`den.environments`/`den.groups`/`den.users`/`den.secretsConfig`; a plain `anything` leaf
  # cannot host those). `freeformType = anything` deep-merges the UNDECLARED concerns (den.hosts/aspects/
  # policies/… spread across many modules) exactly as v1's typed options did, respecting mkDefault/mkForce.
  # No gen-schema type enters the consumer's strict eval; the shim re-validates internally (compile's
  # surface-totality gate), so this boundary submodule stays deliberately freeform.
  #
  # SCHEMA PROCESSING (ship-gate M1.75). `den.schema` is the ONE exception to raw absorption: v1's
  # `options.den.schema` is a gen-schema `mkSchemaOption` that PROCESSES raw kind declarations
  # (`den.schema.<K> = { parent; options; isEntity; … }`) into gen-schema KIND-VALUES carrying
  # `{ kind; strict; refs; options; validators; refinements }`. A corpus module reads that processed value
  # at declaration time (`options.den.clusters = mkInstanceRegistry den.schema.cluster`) — so the bridge
  # MUST reproduce the processing, else the corpus's own mkInstanceRegistry throws `attribute 'refs' missing`.
  # We do it as an `apply` (definitions→value transform): the raw declarations arrive as the sub-option's
  # DEFINITIONS; the apply runs the shim's OWN gen-schema (`schema.evalModuleTree` + `mkSchemaOption`) in a
  # NESTED eval — gen-schema types stay INSIDE that eval, never mounted into the consumer's nixpkgs
  # evalModules (the type-crossing dodge, same as the top-level freeform) — and returns the processed
  # kind-values as `config.den.schema`. apply reads the merged DEFINITIONS, never the applied value, so no
  # fixpoint. CROSS-PIN: the corpus's registries READ the kind-value with the corpus's gen-schema; we
  # PRODUCE it with ours — both must agree on the contract field set (a shape mismatch throws NAMED, never
  # silent). This mirrors v1's own read-behavior (v1 den.schema is equally a processing option).
  options.den = lib.mkOption {
    # FUNCTION-module form (not the attrset shorthand): the SIXTH declared option below —
    # `options.hosts`, the v1 built-in host registry — constructs its per-host instance submodule
    # from the PROCESSED host kind-value (`denConfig.schema.host`, the M1.75 apply's output), so the
    # submodule needs its own `config` in scope (aliased `denConfig`; the bridge's outer flake-parts
    # `config` is shadowed inside this function).
    type = lib.types.submodule (
      { config, ... }:
      let
        denConfig = config;
      in
      {
        freeformType = lib.types.anything;
        options.schema = lib.mkOption {
          # def-COLLECTOR (ship-gate list-merge fix A), NOT a merging type. A kind declaration is spread across
          # modules — nix-config sets `den.schema.cluster.{isEntity,imports}` in schema/cluster.nix, `.parent`
          # in schema/topology.nix, and `.includes` (kind-attached aspects) in SEVERAL kubernetes aspect
          # modules. A `lazyAttrsOf anything` pre-merge deep-merges the attrs but CONFLICTS every list-valued
          # field (`types.anything` never concatenates lists), so the multi-module `includes` threw. Instead
          # this type COLLECTS the raw per-module definitions unmerged (`merge = _: defs: map (d: d.value)
          # defs`) and the apply feeds each into the nested `mkSchemaOption` eval as a SEPARATE module — so
          # gen-schema's OWN merge runs on the DEFINITIONS (its list-default `includes` collection concatenates
          # them, exactly as v1's schema option did), never a hand-rolled list merge here.
          type = lib.mkOptionType {
            name = "denSchemaDefs";
            description = "raw per-module den.schema definitions (merged by the nested gen-schema eval, fix A)";
            merge = _loc: defs: map (d: d.value) defs;
          };
          default = [ ];
          apply =
            defsList:
            let
              # Feed each collected raw def as its own module → gen-schema's entry-type merges them. `includes`
              # is declared a COLLECTION (list default ⇒ gen-schema's `acc ++ val` concat) so v1's kind-attached
              # includes concatenate in definition order. The processed kind-values are what the CORPUS reads
              # (config.den.schema.<K>).
              # `filter isAttrs`: an UNDEFINED `den.schema` yields the `[ ]` default wrapped as a lone collected
              # def (`[ [ ] ]`), which would feed a list where mkSchemaOption expects a kind set — drop such
              # non-attrset defs (a fleet with no custom schema then processes an empty schema, as before).
              schemaDefs = builtins.filter builtins.isAttrs defsList;
              processed =
                (schema.evalModuleTree {
                  modules = [
                    { options.den.schema = schema.mkSchemaOption { collections.includes.default = [ ]; }; }
                  ]
                  ++ map (def: { config.den.schema = def; }) schemaDefs;
                }).config.den.schema;
              # Real kinds only (strip gen-schema's schema-level `_kindNames`/`_topology`/… book-keeping).
              perKind = lib.filterAttrs (n: _: builtins.substring 0 1 n != "_") processed;

              # ── OPAQUE PASS-THROUGH — a SEVERABLE SCAFFOLDING SEAM (owner: belt-and-suspenders) ──────────
              # The BELT, confined ENTIRELY to this `apply` (nothing about it escapes past `config.den.schema`;
              # the boundary suite pins that no corpus/gen-schema-rev specific leaks elsewhere in lib/**).
              #
              # WHY: mkSchemaOption CONSTRUCTS a kind's options into gen-schema (gen-merge) types — pure, so
              # mounting them into the CORPUS's OWN nixpkgs evalModules (`den.clusters = mkInstanceRegistry
              # den.schema.cluster`) threw `deprecationMessage missing` + cross-pin strict errors. This seam KEEPS
              # the structure gen-schema computes (kind/strict/refs/validators/refinements/methods/parent/includes)
              # but REPLACES the kind-value's option-declaring MODULE (`__functor`, which gen-schema's
              # mkInstanceType imports) with the corpus's OWN raw nixpkgs `imports`/`options`, untouched. `isEntity`
              # (dropped by mkSchemaOption) rides raw. Structure is the contract half WE own (mis-shaped → named
              # error); the type half is the corpus's, at its pin — v1-equivalent, no type object crosses.
              #
              # RETIREMENT CONDITION (documented severance): delete this seam once the consumer's gen-schema is
              # PROTOCOL-COMPLETE — pins a gen-merge at/past the `mkOptionType` nixpkgs-protocol completion — at
              # which point the PROCESSED kind-values (`passThrough = false`) flow same-contract into the corpus's
              # eval and this pass-through is pure redundancy. `passThrough` makes the severance one flag; the
              # severability witness pins the two paths produce DISTINCT kind-value shapes today, and (second half,
              # activated with the types work) their corpus-result EQUIVALENCE under protocol-complete pins.
              rawFieldOf =
                kindName: field: default:
                lib.foldl' (
                  acc: d: if (d.${kindName} or { }) ? ${field} then d.${kindName}.${field} else acc
                ) default schemaDefs;
              rawImportsOf =
                kindName: builtins.concatLists (map (d: (d.${kindName} or { }).imports or [ ]) schemaDefs);
              rawOptionsOf =
                kindName:
                lib.foldl' (acc: d: lib.recursiveUpdate acc ((d.${kindName} or { }).options or { })) { } schemaDefs;
              # BASE (both paths): re-add `isEntity`, which mkSchemaOption drops — it is part of den's schema
              # shape, NOT belt scaffolding, so it rides the SEVERED processed path too (same-contract). The
              # corpus's mkInstanceRegistry does not read it (e789c334 instance.nix), so retiring the seam keeps it.
              withStructure = builtins.mapAttrs (
                kindName: structure: structure // { isEntity = rawFieldOf kindName "isEntity" false; }
              ) perKind;
              # THE SEAM (belt only): swap the kind-value's option-declaring MODULE (`__functor`) for the
              # corpus's OWN raw nixpkgs `imports`/`options` — PLUS gen-schema's injected METHODS MODULE
              # (u8 path 1). gen-schema injects a per-kind methods module into a kind-value's `__functor`
              # (entry-type.nix:207-217, `mkMethodsModule` mounted INSIDE the merged module): a readOnly
              # option PER declared method whose `config` value = the method `fn` applied to the genAttrs of
              # its declared arg-names read off the INSTANCE config (methods.nix:19-35). The belt rebuilds
              # `__functor` from the corpus's raw nixpkgs decls and so DROPPED that module — the corpus's
              # `config.den.clusters.<c>.getAssignment` registry read (k3s.nix:86,161) then threw
              # `attribute 'getAssignment' missing`, and the same latent drop hit `den.environments.<e>.
              # getDomainFor`. Re-inject it here, KIND-GENERIC by construction: it runs over whatever
              # `structure.methods` the DISCOVERED kind declares — host/user declare NONE ⇒ `{ }` ⇒ NO extra
              # import ⇒ byte-identical `__functor`; cluster/environment declare methods ⇒ the module rides.
              # Reuses gen-schema's OWN `mkMethodsModule` (`schema._internal`): the method's `type` is ALREADY
              # the corpus's nixpkgs type (the corpus `schemaFn`s it with `lib.types.functionTo …`), so no
              # gen-schema type object crosses; and the method `fn` CLOSES OVER any registry it needs at corpus
              # DECLARATION time (cluster `secrets`/`domainFor` close over `config.den.environments`), so
              # nothing extra crosses. Zero corpus-specific knowledge here — no kind names, no method names.
              passThroughSeam = builtins.mapAttrs (
                kindName: structure:
                let
                  methods = structure.methods or { };
                in
                structure
                // {
                  __functor = _self: _args: {
                    imports =
                      rawImportsOf kindName
                      ++ lib.optional (methods != { }) (schema._internal.mkMethodsModule kindName methods);
                    options = rawOptionsOf kindName;
                  };
                }
              ) withStructure;
              # The kind-values the CORPUS reads: the BELT (opaque pass-through) by default; the SEVERED
              # processed path (`withStructure`) when `passThrough = false` (same-contract under complete pins).
              emittedKinds = if passThrough then passThroughSeam else withStructure;

              # __rawSchema for the SHIM (fix-A wrinkle (i), single source of truth): the kind NAMES (attrNames),
              # `parent` (ingest buildSchema) and concatenated `includes` (ingest kindIncludesOf), read off the
              # structure gen-schema already merged. `options`/`refs`/… are the corpus's, never the shim's (the
              # shim is field-less), so they are absent here; the shim's buildSchema strips to `{ parent }` and
              # re-processes minimally, unchanged.
              rawForShim = builtins.mapAttrs (_: kv: {
                parent = kv.parent or null;
                includes = kv.includes or [ ];
              }) perKind;
            in
            emittedKinds // { __rawSchema = rawForShim; };
        };
        # v1-parity COERCION for `den.policies` — den v1's `policyRegistryType` (den nix/lib/aspects/
        # policy-type.nix:15-24, pin 11866c16), reproduced at the bridge boundary. It does TWO jobs at once:
        #
        #  (1) FORMAL-PRESERVATION (why it lives here, not in the freeform `anything`). A v1 policy
        #      `den.policies.<name> = { host, environment, ... }: [ effects ]` is a TOP-LEVEL FUNCTION value.
        #      nixpkgs `lib.types.anything.merge` WRAPS a top-level fn value in a bare `arg:` lambda (its
        #      fn-merge branch), ERASING its `functionArgs` — so through the freeform `anything` a policy fn's
        #      declared coords (`{ cluster, environment }`) become `{ }`, compile reads `__condition = { }`, and
        #      concern-policies' value-less probe applies the fn WITHOUT a required coord (an UNCATCHABLE throw).
        #      This type bypasses `anything` and — by NESTING the fn inside a `{ __isPolicy; fn }` record — keeps
        #      its formals intact (a NESTED fn is NOT erased; the top-level-vs-nested blast-radius survey). It
        #      therefore SUBSUMES the old `denPoliciesDefs` raw-def collector: nesting preserves what the raw
        #      read did, and the coercion additionally restores the discriminator below.
        #
        #  (2) THE v1 DISCRIMINATOR (what unblocks the agenix rung). v1 tells a POLICY from a PARAMETRIC ASPECT
        #      by SHAPE: a `{ __isPolicy }` record is a policy (children.nix `isPolicy → register-aspect-policy`);
        #      a bare FUNCTION is a parametric aspect (normalize.nix `wrapBareFn`). `den.policies.<name>` VALUES
        #      are coerced to `{ __isPolicy; name; fn }` records HERE (policy-type.nix) — so a `den.policies.X`
        #      REFERENCE in a `den.schema.<kind>.includes` list arrives as a RECORD (→ compile classifies it a
        #      policy), while a LOCAL bare-fn aspect (agenix's `agenixHostAspect`, never laundered through
        #      `den.policies`) stays a bare fn (→ compile classifies it a parametric aspect). Without the
        #      coercion both arrive as bare fns and the shim cannot tell them apart (it mis-labelled the local
        #      aspect a policy → `compilePolicy`'s `concatMap` on aspect CONTENT). R14 correction.
        #
        # MERGE CEILING (out-of-corpus, Fork-A precedent): the shallow per-module `//` union is definition-order
        # (later wins per name); the corpus's policy names are distinct across modules, so it reproduces the
        # same effective set. A `{ __denCanTake }` built-in route (`user-to-host`) and any non-fn value ride
        # through UNCHANGED (compile reads the `__denCanTake` SHAPE, not fn formals) — only a bare fn is wrapped
        # and a `{ __isPolicy }` record is name-stamped, both harmless to the standalone compile (its `innerFn`
        # already unwraps `{ __isPolicy }` identically to a bare fn).
        options.policies = lib.mkOption {
          description = "den.policies coerced to `{ __isPolicy; name; fn }` records at the bridge boundary (v1 policyRegistryType parity, policy-type.nix:15-24): NESTS the fn (preserving formals the freeform `anything` would erase) AND restores v1's policy-vs-parametric-aspect discriminator (a den.policies reference is a record; a local bare-fn aspect is a bare fn).";
          default = { };
          type = lib.mkOptionType {
            name = "denPolicies";
            merge =
              _loc: defs:
              let
                merged = lib.foldl' (acc: d: acc // d.value) { } defs;
              in
              builtins.mapAttrs (
                name: raw:
                if builtins.isFunction raw then
                  {
                    __isPolicy = true;
                    inherit name;
                    fn = raw;
                  }
                else if builtins.isAttrs raw && (raw.__isPolicy or false) then
                  raw // { inherit name; }
                else
                  raw
              ) merged;
          };
        };
        # v1-parity MERGE for `den.default` — the THIRD instance of the bridge's declared-option pattern
        # (after `options.schema` def-collector and `options.policies` coercion). v1 declares
        # `options.den.default` (modules/aspects/defaults.nix:3-6, pin 11866c16) as an `aspectType` SUBMODULE
        # whose `includes` sub-option is `lib.types.listOf (providerType …)` (nix/lib/aspects/types.nix:696-699):
        # multiple module definitions of `den.default.includes` therefore CONCATENATE in module-definition
        # order (standard nixpkgs `listOf` merge). The corpus radiates the base battery set across TWO modules —
        # `modules/den/defaults.nix` (`define-user`/`hostname`/`primary-user`/`inputs'`/`self'`) and
        # `modules/den/batteries/nix-on-droid.nix` (the `drop-user-to-host-on-droid` policy) — so both must fold
        # into one aspect. The freeform `anything` above CONFLICTS the two `includes` LISTS (empirically: `anything`
        # never concatenates a nested list-valued key), the SAME R4-radiation wall the `schema`/`policies` fixes
        # solved for their keys. This is why `den.default` is the ONE exception to raw absorption here.
        #
        # We reproduce v1's cross-module fold as a hand-rolled per-field merge (mirroring the `policies` coercion's
        # mkOptionType, NOT a new engine), using v1's OWN deep-merge shape (nix/lib/aspects/types.nix:478-491):
        # colliding LISTS concatenate (⇒ `includes`/`excludes` concat in def order, v1's listOf semantics), colliding
        # ATTRSETS recurse (⇒ freeform class keys like `nixos`/`homeManager` deep-merge, as v1's aspectKeyType did),
        # and scalars keep last-def-wins. No per-element type wraps the `includes` entries, so aspect/policy RECORDS
        # and bare parametric FUNCTIONS ride through byte-identical (a `listOf anything` would erase a bare fn's
        # formals — the same top-level-fn hazard the `policies` coercion documents). The shim re-derives the aspect's
        # synthetic `provides`/`_`/`__functor` from this raw record via its own `translateAspect` (compile.nix
        # `defaultAspects` → `__default`), so the bridge need only produce the MERGED raw def, not v1's full submodule.
        #
        # CORPUS CEILING (STOP-GATE cleared): the corpus sets `den.default` ONLY via `.includes`, with NO
        # `mkDefault`/`mkForce` on the value — so no priority machinery is exercised beyond what the module system
        # resolves at the def level BEFORE this merge is called. A whole-value priority (`den.default = mkForce …`)
        # is honored by nixpkgs upstream of `merge`; per-sub-path inner priorities are unused by the corpus.
        # CEILING SHARED with `options.aspects` (fork D there): a 2-module collision under an mkOption-bearing
        # subtree (`settings`) would recurse into option-record internals — corpus-zero on both surfaces.
        options.default = lib.mkOption {
          description = "den.default aspect — cross-module folded at the bridge boundary (v1 aspectType parity, defaults.nix:3-6 / types.nix:696-699,478-491): `includes`/`excludes` lists CONCATENATE in module-definition order, freeform class-key attrsets deep-merge, scalars last-def-wins.";
          default = { };
          type = lib.mkOptionType {
            name = "denDefault";
            description = "raw per-module den.default definitions folded by v1's deep-merge (lists concat, attrs recurse, scalars last-wins)";
            merge = _loc: defs: lib.foldl' (acc: d: v1DeepMerge acc d.value) { } defs;
          };
        };
        # v1-parity RAW-PRESERVATION for `den.batteries` — the FOURTH instance of the bridge's declared-option
        # pattern (after `options.schema`/`options.policies`/`options.default`). den v1 provisions batteries as
        # ambient module VALUES (modules/aspects/batteries/, pin 11866c16); the shim reproduces the corpus set
        # at `config.den.batteries.<name>` (lib/compat/batteries.nix). A battery value has THREE shapes: an
        # aspect RECORD (`{ name; includes; }` — define-user/hostname/inputs'/self', with bare-fn ELEMENTS
        # nested inside a `.includes` LIST), a `__functor` (unfree), or — the failing shape — a TOP-LEVEL bare
        # parametric FUNCTION (primary-user = `userToHostContext { user, host, ... }: …`, batteries.nix:119-150).
        # The corpus references a battery BY VALUE (`den.default.includes = [ den.batteries.primary-user ]`,
        # corpus modules/den/defaults.nix:28-34).
        #
        # THROUGH THE FREEFORM `anything` a TOP-LEVEL bare-fn battery hits nixpkgs' `types.anything` LAMBDA-merge
        # branch (nixpkgs lib/types.nix:353-359): it wraps the fn in a bare `arg: anything.merge (map (d: d.value
        # arg) defs)` lambda, ERASING `functionArgs` (→ `{ }`) and making the fn OPAQUE. The bare-fn battery
        # therefore rides `den.default.includes` PRE-MANGLED. Downstream compile.nix `normalizeList`/`callGated`
        # (§339, v1 `can-take.nix` required-coord parity) DOES wrap it, but reads that ERASED `functionArgs`, so
        # its gate sees `required = [ ]` and fires the wrapper UNCONDITIONALLY — at a HOST scope (ctx has `host`,
        # no `user`) the wrapper re-applies `userToHostContext { }` → the UNCATCHABLE `called without required
        # argument 'user'`. (Record batteries survived: `anything`'s LIST branch does not recurse elements, so
        # define-user's nested include fns keep their formals and `callGated` gates them correctly — only the
        # TOP-LEVEL bare-fn shape was mangled.) This is the SAME top-level-fn-erasure hazard `options.policies`
        # documents; the batteries arm simply never had a declared option, and only surfaced once 8cf3f31 unblocked
        # the `den.default` cross-module fold so the primary-user element could radiate to a host scope at all.
        #
        # A battery value is coerced NOWHERE — it must ride BYTE-IDENTICAL (a bare fn stays a bare fn so
        # `callGated` reads its REAL formals; a record/functor stays itself), so this is a plain raw-preserving
        # UNION (shallow `//`, later-def-wins per battery name — the corpus has a single `den.batteries` def),
        # NOT the `policies` coercion nor the `default` deep-merge. The KEY stays inert-by-reference (no concern
        # reads `den.batteries`; a referenced battery rides the include list), so compile's surface-totality
        # already accepts it (knownSurfaceKeys `"batteries"`).
        options.batteries = lib.mkOption {
          description = "den.batteries raw-preserved at the bridge boundary (v1 ambient battery membership): a battery VALUE (bare parametric fn / aspect record / __functor) rides byte-identical, so compile's normalizeList/callGated reads a bare-fn battery's real formals — the freeform `anything` erases a top-level fn's functionArgs (the same hazard options.policies documents).";
          default = { };
          type = lib.mkOptionType {
            name = "denBatteries";
            description = "raw per-module den.batteries definitions unioned (shallow, later-def-wins per name); values pass through untouched (no anything top-level-fn erasure)";
            merge = _loc: defs: lib.foldl' (acc: d: acc // d.value) { } defs;
          };
        };
        # v1-parity RAW-PRESERVING DEEP-MERGE for `den.aspects` — the FIFTH instance of the bridge's
        # declared-option pattern (after `options.schema`/`options.policies`/`options.default`/
        # `options.batteries`), unblocking the corpus drvPath. v1 declares `options.den.aspects`
        # (nix/nixModule/aspects.nix:6, pin 11866c16) with `aspectsType` (nix/lib/aspects/types.nix:740-742),
        # whose per-class-key content wrapper holds every fn value RAW (`aspectContentType` stores defs
        # unmerged in `__contentValues`, types.nix:421 — a fn NEVER passes through a fn-merge). The freeform
        # `anything` above instead sends a fn at ANY attrset depth through its lambda-merge branch (nixpkgs
        # lib/types.nix:353-359), wrapping it in a bare `arg:` lambda — ERASING `functionArgs` — so EVERY
        # corpus aspect class fn crossed formals-erased, gen-bind's formals-driven wrapAll bound nothing, and
        # the corpus drvPath threw `function 'nixos' called without required argument 'firewall'` (corpus
        # modules/den/aspects/core/network/firewall-collector.nix:3) inside the real nixosSystem.
        #
        # THE LOAD-BEARING MECHANISM (why this fold fixes it): deepMerge recurses ONLY on collision (both
        # sides attrset at a shared key). A single-def subtree rides `bv` RAW, UNRECURSED. `anything` ALWAYS
        # recurses per-key (even single-def), which is what wraps a single-def leaf lambda into `arg:…`
        # (formals erased). So firewall-collector's single-path `nixos` fn rides `bv` RAW under deepMerge →
        # formals intact. Same v1 deep-merge shape as `options.default` (v1 types.nix:478-490, the shared
        # `v1DeepMerge`): colliding attrsets recurse (the namespace ancestors — `core`/`apps`/`services`/… —
        # union across the corpus's one-aspect-per-file modules), colliding lists concat (`includes`, v1's
        # listOf semantics), scalars last-def-wins. The shim re-derives `provides`/`_`/`__functor` + identity
        # via translateAspect (compile.nix); no shim consumer reads v1's `__contentValues`/`__provider`
        # typing off the bridge (compile.nix documents both as absent at the raw boundary).
        #
        # CEILING (fork A, corpus-zero): a fn-vs-fn collision at ONE class key is LAST-DEF-WINS here, where
        # v1 COLLECTS BOTH defs (`__contentValues`, types.nix:421) for emit-classes. The corpus has exactly
        # ONE cross-module aspect path (`core.impermanence` — impermanence.nix + darwin.nix, DISJOINT keys),
        # so no corpus def is dropped; adopt collect-both only when a real 2-module same-key class def
        # appears (`ci/tests/compat-bridge.nix` test-aspects-fnfn-collision-lastwins-ceiling pins the
        # semantics so any change announces). Fork C (corpus-zero): a TOP-LEVEL bare-fn aspect now reaches
        # translateAspect's fn-branch coercion (compile.nix) with PRESERVED formals, so compile's callGated
        # gates it correctly — a free correctness improvement over the erased-formals ride. Fork D CEILING
        # shared with `options.default` (see its comment): mkOption-bearing `settings` subtrees, corpus-zero
        # collisions. (#58 note: owning this fold makes v1's `annotateDeep` fold-time `__provider`
        # annotation — the dedup upgrade path — easier later.)
        options.aspects = lib.mkOption {
          description = "den.aspects — cross-module raw-preserving deep-merge at the bridge boundary (v1 aspectsType parity, nixModule/aspects.nix:6 / types.nix:740-742,478-490): attrsets recurse ONLY on collision, lists concat, scalars/fns last-def-wins RAW — a class fn is never wrapped, so its formals survive to gen-bind (the freeform `anything` erases a fn's functionArgs at any depth).";
          default = { };
          type = lib.mkOptionType {
            name = "denAspects";
            description = "raw per-module den.aspects definitions folded by v1's deep-merge (attrs recurse on collision only, lists concat, scalars/fns last-wins raw)";
            merge = _loc: defs: lib.foldl' (acc: d: v1DeepMerge acc d.value) { } defs;
          };
        };
        # THE BRIDGE-REGISTRY PASSTHROUGH (the SIXTH declared option; replaces the instance-eval
        # harvest). v1 AUTO-DECLARES its built-in host registry — `options.den.hosts = types.hostsOption`
        # (pin 11866c16 modules/options.nix:71; hostsOption = entities/host.nix:26-44, the def-collector +
        # preprocess + strict per-host instance-submodule apply) — which the shim never reproduced, so
        # `den.hosts` rode the freeform `anything` as RAW data and a SIDE eval (instance-eval.nix, deleted)
        # re-materialized the kind's schema defaults with a hand-rolled copy of the module system's
        # priority ladder. This declaration IS v1's (registry.nix mirrors the pin, consumer `lib` +
        # the M1.75 emitted host kind-value as the instance module — EXACTLY the construction the
        # corpus's own `mkInstanceRegistry den.schema.cluster` already exercises through this eval), so
        # `config.den.hosts` is the corpus-visible MERGED view (v1's typed option was never raw) and the
        # native priorities (authored 100 < corpus mkDefault 1000 < base default 1500) come for free.
        # `denConfig.schema.host` is the processed kind-value (the schema apply above) — read lazily
        # inside the hosts apply, so no fixpoint (schema's apply never reads hosts).
        options.hosts = compat.registry.mkHostsOption {
          inherit lib;
          kindModule = (denConfig.schema or { }).host or { };
        };
      }
    );
    default = { };
    description = "The den v1 declaration surface (absorbed raw here; desugared by the compat two-eval).";
  };

  # R1 legacy binding: den v1's flakeModule binds `_module.args.den = config.den` at flake scope so every
  # consumer module may reference the `den` arg (`{ den, ... }:` — nix-config's schema/cluster.nix reads
  # `den.schema.cluster`, _settings-type.nix reads `den.lib.aspects.fx.keyClassification`). den v1's `den`
  # arg carries BOTH the config surface (config.den) AND the lib surface at `den.lib` (v1's
  # `options.den.lib`), so the bridge splices the migration lib onto `.lib` — the same drop-in surface
  # `inputs.den.lib` exposes. The shim reproduces the config half separately inside its OWN v1 eval.
  # `aspects` rides ANNOTATED (board #58): a corpus policy navigating `den.aspects.<path>` off this arg
  # gets the `__provider`-bearing value, so its emitted include recovers v1's provider identity.
  config._module.args.den = annotatedDen // {
    lib = denLib;
  };

  config.flake =
    let
      # `den.nixpkgs`/`den.darwin` are BRIDGE controls (the global-fallback instantiation grain), not v1
      # surface keys — strip them before the shim, whose compile surface-totality gate (C1) rejects any
      # `den.*` key outside the v1 grammar. What remains is the single pre-merged fleet def handed to the
      # shim's internal gen-schema eval (no multi-module conflict — the flake-parts side already merged).
      npkgs = config.den.nixpkgs or null;
      # DECLARED-surface extraction (M1.5): the corpus declares `options.den.<x>` sub-options for its custom
      # kinds' instance registries AND its non-kind config namespaces (secretsConfig). The shim (which reads
      # config VALUES, not the option tree) can't tell a declared namespace from a typo; so the bridge — the
      # ONE place with the flake-parts option surface — reads the DECLARED sub-option names off `options.den`
      # (the freeform submodule's `getSubOptions`, minus the `_freeformOptions` marker) and passes them to
      # compile as the reserved `_declaredKeys`. compile's strict surface-totality classifies these as
      # legitimate (a typo is undeclared, so still aborts). `_`-prefixed ⇒ exempt from totality + ignored by
      # ingest; harmless on the shim's other passes.
      declaredDenKeys = builtins.filter (k: builtins.substring 0 1 k != "_") (
        builtins.attrNames ((options.den.type.getSubOptions or (_: { })) [ ])
      );
      # ── ctx-entity REGISTRY STAMPS (the bridge-registry passthrough; replaces the fork-(i) side
      # eval, instance-eval.nix — DELETED) ─────────────────────────────────────────────────────────
      # The BRIDGE EVAL already materializes every registry's full merged view: `den.hosts` via the
      # shim-declared v1 hostsOption parity option (options.hosts above — v1's own per-host instance
      # eval, native priorities), the custom kinds via the CORPUS's own `mkInstanceRegistry`
      # declarations (options + defaults + methods post-ad2195b + derive). The stamps are that view
      # MINUS the STRUCTURAL EXCLUSION RULE (registry.nix stampTreeOf/stampOf — `raw`/
      # `deferredModule`/`anything`-class option types never enter deepSeq'd resolution state; the
      # inclusion tree is read FORCE-FREE off the option declarations, excluded values never
      # touched). Two declaration sources, ONE classifier:
      #   - hosts: the probe eval's `.options` (`hostInstanceOptions` — the shim owns the
      #     declaration, so the probe runs the same base-entity + kind-value modules);
      #   - consumer-declared registries: the DECLARED option's own `type.getSubOptions` (the
      #     flake-parts option surface — force-free; a registry whose type exposes none stamps
      #     nothing, degrading to field-less entities, never a throw).
      # Namespaces are discovered STRUCTURALLY (`ingest.isInstanceRegistry` — id_hash-bearing
      # entries, the M1.5 marker test's shape half; `den.hosts` entries carry no id_hash, so the
      # generic scan never double-stamps them). The stamps ride to ingest as the reserved
      # `_entityStamps` (like `_declaredKeys`: `_`-exempt from surface-totality, skipped by
      # custom-kind discovery), where `entityFields` re-keys them by KIND. A fleet with no host kind
      # stamps base-only (every base option is raw → excluded → an EMPTY host stamp) — byte-identical
      # to the field-less pre-registry entities.
      hostKindModule = (config.den.schema or { }).host or { };
      hostStampTree = compat.registry.stampTreeOf (
        compat.registry.hostInstanceOptions {
          inherit lib;
          kindModule = hostKindModule;
        }
      );
      hostEntries = compat.registry.flattenRegistry (config.den.hosts or { });
      denSubOptions = (options.den.type.getSubOptions or (_: { })) [ ];
      consumerRegistryKeys = builtins.filter (
        k: builtins.substring 0 1 k != "_" && compat.ingest.isInstanceRegistry (config.den.${k} or null)
      ) declaredDenKeys;
      subOptionsOf =
        k:
        let
          t = (denSubOptions.${k} or { }).type or null;
        in
        if t == null || !(t ? getSubOptions) then
          { }
        else
          t.getSubOptions [
            "den"
            k
          ];
      stampRegistry = tree: entries: builtins.mapAttrs (_: e: compat.registry.stampOf tree e) entries;
      entityStamps = {
        hosts = stampRegistry hostStampTree hostEntries;
      }
      // lib.genAttrs consumerRegistryKeys (
        k: stampRegistry (compat.registry.stampTreeOf (subOptionsOf k)) config.den.${k}
      );
      fleet = [
        {
          # `annotatedDen` (board #58): the fleet's `den.aspects` carries the post-fold `__provider`
          # annotation, so compile's include grounding recovers v1's provider identity.
          den =
            builtins.removeAttrs annotatedDen [
              "nixpkgs"
              "darwin"
            ]
            // {
              # the shim gets the RAW schema (it re-processes; the processed value is the corpus's, not ours).
              schema = config.den.schema.__rawSchema or { };
              _declaredKeys = declaredDenKeys;
              _entityStamps = entityStamps;
            };
        }
      ];
      # Instantiation grains: the per-host `host.instantiate` (per-entity grain, ship-gate M2) is honored
      # inside the compat nixos wrapper (flake-module.nix) — a host that declares its own evaluator builds
      # through THAT channel regardless of the two lines below. These control the FALLBACK grain for hosts
      # with no per-host instantiate (M1): one `crossNixos` for every such nixos member when `den.nixpkgs`
      # is set, else the nixpkgs-free `collect` terminal (member keys present, no build).
      built =
        if npkgs == null then
          compat.mkDen fleet
        else
          compat.mkDenWith fleet { nixosTerminal = mkCrossNixos npkgs; };
    in
    {
      # The drop-in `den` output faces (D8 flake-parts option targets).
      nixosConfigurations = built.nixosConfigurations;
      # darwin members cross through `collect`: the compat per-host instantiate wrapper is stamped only on
      # the nixos class (M2), so a darwin host's `host.instantiate` is not yet honored — that is the darwin
      # live corpus run (ship-gate item 2 / class B, `patch`), a trivial stamp of the now class-neutral
      # wrapper onto the darwin class. The member keys are present so `darwinConfigurations` is non-empty
      # and inspectable.
      darwinConfigurations = built.darwinConfigurations;
      # ABSENT (honest, M1): `homeConfigurations` — den-hoag has no standalone-home output yet (den.homes /
      # parity OQ5, board #49); the `perSystem` faces (devShells/packages/apps/checks) — the compat layer
      # produces no per-system class content yet. Both are set only once the shim can honestly produce them.
    };
}
