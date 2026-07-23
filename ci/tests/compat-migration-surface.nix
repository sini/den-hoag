# ship-gate T1/T3b — the G1 migration re-export layer (flake.nix). den-hoag exposes den v1's TOP-LEVEL
# attrpaths so it is a drop-in `den` input for nix-config. This roster pins: every consumed `lib.*`
# attrpath EXISTS (no `attribute 'x' missing` — the interface-block fix); the delivery aliases
# (route/provide) and the structural verbs (include/exclude/mkPolicy/pipe, T3b) are real constructors
# producing v1's inert tagged records; the still-unimplemented SEMANTIC verbs are NAMED THROWING STUBS
# routing to their board task, never fakes. `flakeModule`/`flakeModules` are TOP-LEVEL flake outputs
# (not lib), so they are gate-verified by `nix eval den-hoag#flakeModule`, not this unit surface.
{ denHoag, ... }:
let
  L = denHoag; # = den-hoag.lib, the migration lib (four-concern API + the den-v1 re-export surface)
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
in
{
  flake.tests.compat-migration-surface = {
    # ── existence: every consumed lib.* attrpath is present (`?` never forces the value) ──
    test-attrpaths-exist = {
      expr = {
        policy = L ? policy;
        route = L.policy ? route;
        provide = L.policy ? provide;
        include = L.policy ? include;
        exclude = L.policy ? exclude;
        mkPolicy = L.policy ? mkPolicy;
        pipe = L.policy ? pipe;
        resolve = L.policy ? resolve;
        instantiate = L.policy ? instantiate;
        aspectsResolve = L.aspects ? resolve;
        keyClassification = L.aspects.fx ? keyClassification;
        resolveEntity = L ? resolveEntity;
        home = L ? home;
        captureFleet = L.capture ? captureFleet;
      };
      expected = builtins.listToAttrs (
        map
          (n: {
            name = n;
            value = true;
          })
          [
            "policy"
            "route"
            "provide"
            "include"
            "exclude"
            "mkPolicy"
            "pipe"
            "resolve"
            "instantiate"
            "aspectsResolve"
            "keyClassification"
            "resolveEntity"
            "home"
            "captureFleet"
          ]
      );
    };

    # ── aliases: route/provide are the compat capability (a FUNCTION that does not throw), not a stub ──
    test-route-provide-are-aliases = {
      expr = {
        route = builtins.isFunction L.policy.route;
        provide = builtins.isFunction L.policy.provide;
      };
      expected = {
        route = true;
        provide = true;
      };
    };

    # ── constructors: include/exclude/mkPolicy/pipe reproduce v1's inert tagged records (T3b) ──
    # Byte-shape assertions, not mere `isFunction`: each produces the exact record `compile`/`pipe`
    # consume (v1 policy-effects.nix:175/182/450/296). `pipe` is a constructor bag (attrset), so its
    # head + a representative stage are checked.
    test-structural-verbs-are-constructors = {
      expr = {
        include = (L.policy.include "aspect-ref").__policyEffect;
        exclude = (L.policy.exclude "aspect-ref").__policyEffect;
        mkPolicy = (L.policy.mkPolicy "p" (_: [ ])).__isPolicy;
        pipeHead = (L.policy.pipe.from "chan" [ ]).__policyEffect;
        pipeStage = (L.policy.pipe.filter (_: true)).__pipeStage;
        # instantiate — #50 un-stubbed (v1 policy-effects.nix:243): a plain effect constructor now.
        instantiate = (L.policy.instantiate { name = "n"; }).__policyEffect;
        # resolve — R2 un-stubbed (v1 policy-effects.nix:128-171): the functor bag; `resolve.to <kind>`
        # produces the tagged resolve record the compat `__targetKind` arm consumes.
        resolve =
          (L.policy.resolve.to "user" {
            user = {
              id_hash = "u";
              name = "n";
            };
          }).__policyEffect;
      };
      expected = {
        include = "include";
        exclude = "exclude";
        mkPolicy = true;
        pipeHead = "pipe";
        pipeStage = "filter";
        instantiate = "instantiate";
        resolve = "resolve";
      };
    };

    # ── keyClassification MOVED stub→real (ship-gate #49-SLICE): `structuralKeysSet` is a real membership
    #    set the corpus's _settings-type.nix reads to type the settings submodule, not a throwing stub. ──
    test-keyclassification-is-real = {
      expr = {
        isSet = builtins.isAttrs L.aspects.fx.keyClassification.structuralKeysSet;
        metaStructural = L.aspects.fx.keyClassification.structuralKeysSet ? "meta";
        settingsStructural = L.aspects.fx.keyClassification.structuralKeysSet ? "settings";
      };
      expected = {
        isSet = true;
        metaStructural = true;
        settingsStructural = true;
      };
    };

    # ── stubs throw a NAMED blocker (not silent, not a fake) — the STILL-escalated set (#49); the
    #    keyClassification slice + `policy.instantiate` (#50) + `policy.resolve` (R2, now the functor bag
    #    above) moved to real, so the escalated set is now 4. ──
    test-semantic-verbs-are-named-stubs = {
      expr = map throws [
        L.aspects.resolve
        L.resolveEntity
        L.home
        L.capture.captureFleet
      ];
      expected = builtins.genList (_: true) 4;
    };

    # ── LHF lib-forward quick-wins (den v1 nix/lib/*): the four additive passthrough surfaces exist and
    #    behave. `deliver` = the delivery-descriptor surface (policy-effects.nix:68); `canTake` = the arity
    #    predicate (can-take.nix); `schema` = the raw gen-schema.lib; `strict` = the UNAPPLIED strict module
    #    fn (strict.nix — the substrate cannot apply it; the consumer's evalModules injects nixpkgs lib). ──
    test-lhf-surfaces = {
      expr =
        let
          # route case: a class-source deliver descriptor (from a class name, default merge at root).
          d = L.policy.deliver {
            from = "nixos";
            to = "home-manager";
          };
        in
        {
          deliverDelivery = d.__delivery;
          deliverSourceClass = d.sourceClass;
          deliverTarget = d.target;
          deliverMode = d.mode;
          # atLeast (the __functor default): a required arg supplied → true (no functor-arg case, since
          # builtins.functionArgs is not functor-aware — the dead gap noted in the register).
          canTakeAtLeast = L.canTake.atLeast { a = null; } (
            {
              a,
              b ? 0,
            }:
            0
          );
          canTakeUpTo = L.canTake.upTo { a = null; } (
            {
              a,
              b ? 0,
            }:
            0
          );
          # schema = raw gen-schema.lib (host.nix/home.nix consume it as `schemaLib`).
          schemaTypes = L.schema ? types;
          schemaMkStrictModule = L.schema ? mkStrictModule;
          # strict is exported UNAPPLIED (the `{ lib, ... }:` fn) — NEVER `strict ? _module`.
          strictIsFn = builtins.isFunction L.strict;
        };
      expected = {
        deliverDelivery = true;
        deliverSourceClass = "nixos";
        deliverTarget = "home-manager";
        deliverMode = "merge";
        canTakeAtLeast = true;
        canTakeUpTo = true;
        schemaTypes = true;
        schemaMkStrictModule = true;
        strictIsFn = true;
      };
    };

    # ── lib-forward remainder: the deprecated context guards (den v1 modules/context/perHost-perUser.nix +
    #    nix/lib/take.nix). perHost/perUser/perHome are pure plain-lambda aliases; take is the fn→fn guard bag
    #    (NOT the nixpkgs list-take — migrationLib overrides it). Byte-transparent (lib.warn returns the value).
    #    perHost binds `host` through the same isFunction include arm as an inline lambda — witnessed
    #    behaviorally in den-behavioral/top-level-parametric.nix (test-perhost-alias-equals-inline). ──
    test-lib-forward-remainder = {
      expr =
        let
          fromHost = { host, ... }: { nixos.x = host; };
          # take.exactly on an all-optional-arg fn returns it UNCHANGED (v1-faithful — no required key, so
          # the parked parametric-wrapper is never reached). Nix cannot compare functions with `==`, so
          # passthrough is proven behaviorally: the returned fn applied yields the original fn's result.
          allOptional =
            {
              a ? 0,
              b ? 1,
            }:
            a;
        in
        {
          perHostExists = L ? perHost;
          perUserExists = L ? perUser;
          perHomeExists = L ? perHome;
          # a function aspect wraps into a formal lambda declaring the bound key; a non-function rides through.
          perHostWrapsFn = builtins.isFunction (L.perHost fromHost);
          perHostPassesAttr = (L.perHost { plain = true; }).plain;
          takeIsBag = builtins.isAttrs L.take;
          takeMembers = builtins.all (m: L.take ? ${m}) [
            "unused"
            "atLeast"
            "upTo"
            "exactly"
          ];
          takeUnused = L.take.unused "ignored" "kept";
          # atLeast is warn+identity → the returned fn behaves as `fromHost`.
          takeAtLeastPassthrough = (L.take.atLeast fromHost { host = "h"; }).nixos.x;
          # exactly on an all-optional fn returns it unchanged → applies as the original.
          takeExactlyAllOptionalUnchanged = L.take.exactly allOptional { a = 7; };
        };
      expected = {
        perHostExists = true;
        perUserExists = true;
        perHomeExists = true;
        perHostWrapsFn = true;
        perHostPassesAttr = true;
        takeIsBag = true;
        takeMembers = true;
        takeUnused = "kept";
        takeAtLeastPassthrough = "h";
        takeExactlyAllOptionalUnchanged = 7;
      };
    };

    # ── synthesizePolicies.resolveArgsSatisfied (v1 nix/lib/synthesize-policies.nix:7-16): the policy-dispatch
    #    predicate — does ctx supply every REQUIRED formal of fn? Arg-flipped canTake.atLeast. `{a,b?0}` requires
    #    `a`: ctx `{a=1;}` → true; ctx `{b=1;}` (missing required `a`) → false. ──
    test-resolve-args-satisfied = {
      expr = {
        satisfied = L.synthesizePolicies.resolveArgsSatisfied (
          {
            a,
            b ? 0,
          }:
          0
        ) { a = 1; };
        unsatisfied = L.synthesizePolicies.resolveArgsSatisfied (
          {
            a,
            b ? 0,
          }:
          0
        ) { b = 1; };
      };
      expected = {
        satisfied = true;
        unsatisfied = false;
      };
    };

    # ── the four-concern API stays intact under the migration merge (no key clobbered) ──
    test-four-concern-intact = {
      expr = {
        mkDen = L ? mkDen;
        internal = L ? internal;
        classes = L ? classes;
      };
      expected = {
        mkDen = true;
        internal = true;
        classes = true;
      };
    };
  };
}
