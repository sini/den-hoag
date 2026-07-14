# NATIVE A-IDENT ON THE evalV1 SURFACE (Phase 5 Task 2 — the value-injection debt closure, first half).
#
# THE RUNG. The compat two-eval reads the v1 declaration surface (`den.aspects.<path>`) back through a
# SEPARATE v1-shaped eval (`evalV1`). Historically that surface was a `raw` option: a navigated node
# carried NO native gen aspect identity, so the shim reconstructed it via a post-fold `__provider` walk
# (annotate.nix) that `stampProvider` re-read to recover v1's include key. gen-aspects @14652a0 (A-IDENT)
# makes a TYPED `den.aspects` node carry its OWN container-relative identity natively: `.key` = the full
# path, `meta.aspect-chain` = its ancestors. This suite witnesses that native identity on the evalV1
# read-back — the mechanism Task 3 repoints the readers onto and Task 4 retires `__provider` for.
#
# ADDITIVE (Task 2): `__provider` still rides in PARALLEL (the annotate walk is untouched this task), so a
# navigated node carries BOTH `.key` (native) and `__provider` (legacy). This suite asserts the native
# half is now present; the __provider half stays green in the existing compat-include-identity suite.
{ denCompat, ... }:
let
  # The evalV1 read-back of a nested-path aspect (the F1 baseline shape) — a sibling aspect includes it
  # via `with aspects; …` (the legacy binding rewire must keep resolving), and a freeform `den.<custom>`
  # key rides alongside (the raw-absorption the two-eval surface-totality gate depends on downstream).
  ev = denCompat.evalV1 [
    (
      { ... }:
      {
        den.aspects.core.network.manager.nixos =
          { ... }:
          {
            marker.manager = true;
          };
        # sibling include through the `aspects` module arg (the `with den.aspects; …` corpus idiom) —
        # exercises the `_module.args.aspects` rewire the typed surface must keep binding.
        den.aspects.services.gateway.includes = with ev.aspects; [ core.network.manager ];
        # a freeform den key with no typed sub-option — must still absorb (custom-kind / den.default).
        den.customFreeform = "rides-freeform";
      }
    )
  ];
  nav = ev.aspects.core.network.manager;
in
{
  flake.tests.native-identity = {
    # ── the decisive native-identity witness: the navigated evalV1 node carries A-IDENT's `.key`
    #    (full container-relative path) + `meta.aspect-chain` (its ancestors). ──
    test-native-key-and-chain = {
      expr = {
        key = nav.key or "<none>";
        chain = nav.meta.aspect-chain or "<absent>";
      };
      expected = {
        key = "core/network/manager";
        chain = [
          "core"
          "network"
        ];
      };
    };
    # ── the sibling `with aspects; …` include still resolves (no `module argument 'aspects' is not
    #    defined`): the include holds one entry, and it is the manager node (its native key). ──
    test-sibling-include-resolves = {
      expr = {
        count = builtins.length ev.aspects.services.gateway.includes;
        includedKey = (builtins.head ev.aspects.services.gateway.includes).key or "<none>";
      };
      expected = {
        count = 1;
        includedKey = "core/network/manager";
      };
    };
    # ── freeform den.<custom> still absorbs (the raw-passthrough the surface-totality gate reads). ──
    test-freeform-absorbs = {
      expr = ev.customFreeform or "<absent>";
      expected = "rides-freeform";
    };
  };
}
