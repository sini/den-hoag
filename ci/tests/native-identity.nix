# NATIVE A-IDENT ON THE evalV1 SURFACE (Phase 5 Task 2 the native identity; Task 3 the PROBE + reader repoint).
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

  # ── THE PROBE (Task 3 gate): native `.key`/`id_hash` and the legacy `__provider` reconstruction COEXIST
  #    on the nav view this task (additive), so we can assert they are BYTE-EQUAL per node BEFORE trusting
  #    the reader repoint. A walk over the nav aspect tree checks, for every node carrying `__provider`:
  #      (1) `concatStringsSep "/" v.__provider  ==  v.key`  — the navigation `.key` (what refKey now reads)
  #          equals `pathKey v.__provider` (what refKey reconstructed before); STRING byte-equal.
  #      (2) `idHashOf v.key  ==  hashString sha256 ("den-aspect:" + concatStringsSep "/" v.__provider)`
  #          — the id_hash derived from the native key equals the one stampProvider derives from __provider.
  #    If ANY node diverges the repoint is unsound → the probe test fails LOUD (STOP, don't repoint blind).
  idHashOf = key: builtins.hashString "sha256" ("den-aspect:" + key);
  # Recurse the nav aspect tree; a node is a stampable aspect iff it carries `__provider` (the annotate
  # walk stamps every navigated aspect node). Collect `{ ok; key; providerKey; }` per such node.
  probeWalk =
    node:
    if !(builtins.isAttrs node) then
      [ ]
    else
      let
        here =
          if builtins.isList (node.__provider or null) && node.__provider != [ ] then
            let
              providerKey = builtins.concatStringsSep "/" node.__provider;
              providerHash = builtins.hashString "sha256" ("den-aspect:" + providerKey);
            in
            [
              {
                keyOk = (node.key or "<none>") == providerKey;
                hashOk = idHashOf (node.key or "<none>") == providerHash;
                key = node.key or "<none>";
                providerKey = providerKey;
              }
            ]
          else
            [ ];
        # recurse the non-`__`, non-structural children (nested aspects live in the freeform).
        childKeys = builtins.filter (k: builtins.substring 0 2 k != "__" && builtins.isAttrs node.${k}) (
          builtins.attrNames node
        );
      in
      here ++ builtins.concatMap (k: probeWalk node.${k}) childKeys;
  probeResults = probeWalk ev.aspects;
in
{
  flake.tests.native-identity = {
    # ── THE PROBE: every navigated node's native `.key` and `id_hash` byte-equal the `__provider`
    #    reconstruction — the both-arms-agree gate that licenses the reader repoint (Task 3). ──
    test-probe-native-eq-provider = {
      expr = {
        allKeyOk = builtins.all (r: r.keyOk) probeResults;
        allHashOk = builtins.all (r: r.hashOk) probeResults;
        # a non-vacuous witness: the tree carried at least the manager + gateway aspects.
        count = builtins.length probeResults;
        # the actual (key, providerKey) pairs — visible in a failure, proving WHICH node diverged.
        pairs = map (r: {
          inherit (r) key providerKey;
        }) probeResults;
      };
      # The walk visits every `__provider`-stamped node, INTERMEDIATES included (the annotate walk stamps
      # `core`/`core/network`/… as well as the leaves), so the census is 5 nodes — all byte-agreeing.
      expected = {
        allKeyOk = true;
        allHashOk = true;
        count = 5;
        pairs = [
          {
            key = "core";
            providerKey = "core";
          }
          {
            key = "core/network";
            providerKey = "core/network";
          }
          {
            key = "core/network/manager";
            providerKey = "core/network/manager";
          }
          {
            key = "services";
            providerKey = "services";
          }
          {
            key = "services/gateway";
            providerKey = "services/gateway";
          }
        ];
      };
    };
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
