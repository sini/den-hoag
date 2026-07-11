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
      };
      expected = {
        include = "include";
        exclude = "exclude";
        mkPolicy = true;
        pipeHead = "pipe";
        pipeStage = "filter";
        instantiate = "instantiate";
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
    #    keyClassification slice + `policy.instantiate` (#50 un-stubbed, now a constructor below) moved to
    #    real, so the escalated set is now 5. ──
    test-semantic-verbs-are-named-stubs = {
      expr = map throws [
        L.policy.resolve
        L.aspects.resolve
        L.resolveEntity
        L.home
        L.capture.captureFleet
      ];
      expected = builtins.genList (_: true) 5;
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
