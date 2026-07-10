# ship-gate T1 — the G1 migration re-export layer (flake.nix). den-hoag exposes den v1's TOP-LEVEL
# attrpaths so it is a drop-in `den` input for nix-config. This roster pins: every consumed `lib.*`
# attrpath EXISTS (no `attribute 'x' missing` — the interface-block fix); aliases are the compat
# capability (a function, not a stub); unimplemented SEMANTIC verbs are NAMED THROWING STUBS routing
# to their board task, never fakes. `flakeModule`/`flakeModules` are TOP-LEVEL flake outputs (not lib),
# so they are gate-verified by `nix eval den-hoag#flakeModule`, not this unit surface.
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

    # ── stubs throw a NAMED blocker (not silent, not a fake) — the whole escalated set ──
    test-semantic-verbs-are-named-stubs = {
      expr = map throws [
        L.policy.include
        L.policy.exclude
        L.policy.mkPolicy
        L.policy.pipe
        L.policy.resolve
        L.policy.instantiate
        L.aspects.resolve
        L.aspects.fx.keyClassification
        L.resolveEntity
        L.home
        L.capture.captureFleet
      ];
      expected = builtins.genList (_: true) 11;
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
