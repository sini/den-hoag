# NESTED `den.aspects.<path>` NAMED REFERENCE grounding (the `core.secrets.collector` rung). A v1
# `schema.<kind>.includes` list may hold a NAVIGATED aspect node (`den.aspects.grp.sub.coll`, the corpus
# defaults.nix:8-9 `den.schema.host.includes = [ den.aspects.core.secrets ]` shape). That node carries its
# NATIVE gen-aspects `.key` — the FULL container-relative slash-path (`grp/sub/coll`) — while its `.name`
# is only the LAST SEGMENT (`coll`). `resolveAspectRef` used to look the ref up by `.name`, but the aspect
# registry only ever registered TOP-LEVEL names (`translateAspect` STRIPS nested sub-aspects from their
# parent), so `aspectRec "coll"` MISSED → an empty stub → the edge carried ZERO class content (the corpus
# `age.secrets = {}` drop). The fix keys the registry by the traversal PATH and `resolveAspectRef` prefers
# `.key`, so a nested ref grounds UNIFORMLY with a shallow one. This suite pins:
#   • the NESTED nav ref delivers REAL content at the host + `grp/sub/coll` is in the resolved-aspects keys;
#   • a SHALLOW twin (a top-level named ref) stays green — the top-level registry key is unchanged;
#   • an explicit `{ name = "grp/sub/coll"; }` / `{ key = …; }` ref resolves by the SAME path key;
#   • a DIRECT-`compile`-path nested aspect (raw decls, NO `.key`) registers under the traversal path — so
#     the registry key derives from the walk, never from a (missing) `node.key`.
{ denCompat, ... }:
let
  bucketAt =
    den: id: cls:
    (den.structural.eval.get id "class-modules").${cls} or [ ];
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");

  # ── (1) NESTED nav ref on schema.host.includes — the corpus `den.aspects.core.secrets` shape. The nested
  #    node's `.key` is `grp/sub/coll`; its `.name` is `coll`. ────────────────────────────────────────────
  collBody.nixos =
    { ... }:
    {
      environment.etc."den-marker".text = "nested-delivered";
    };
  nestedNav = denCompat.evalV1 [
    { config.den.aspects.grp.sub.coll = collBody; }
  ];
  nestedFleet =
    (denCompat.mkDen [
      {
        config.den = {
          aspects.grp.sub.coll = collBody;
          schema.host.includes = [ nestedNav.aspects.grp.sub.coll ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # ── (2) SHALLOW twin — a TOP-LEVEL named ref (`.key` == `.name` == `mycoll`). Pins that the top-level
  #    registry key is unchanged by the fix (byte-stable resolve). ───────────────────────────────────────
  shallowBody.nixos =
    { ... }:
    {
      environment.etc."den-shallow".text = "shallow-delivered";
    };
  shallowNav = denCompat.evalV1 [
    { config.den.aspects.mycoll = shallowBody; }
  ];
  shallowFleet =
    (denCompat.mkDen [
      {
        config.den = {
          aspects.mycoll = shallowBody;
          schema.host.includes = [ shallowNav.aspects.mycoll ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # ── (3) EXPLICIT keyed ref — a reference carrying `name` = LAST SEGMENT (`coll`) AND `key` = the full
  #    slash-path (`grp/sub/coll`), the exact nav-node divergence made explicit. It routes to `staticRefs`
  #    (a `.name` is present, so it is NOT an `isContentRef`) and `resolveAspectRef` must PREFER `.key`:
  #    with `.name` alone it would miss (`aspectRec "coll"` — the empty stub). Locks fix (A) directly. ───
  explicitKeyFleet =
    (denCompat.mkDen [
      {
        config.den = {
          aspects.grp.sub.coll = collBody;
          schema.host.includes = [
            {
              name = "coll";
              key = "grp/sub/coll";
            }
          ];
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;

  # ── (4) DIRECT `compile` path — raw decls (no `typeAspects`), so the nested node carries NO `.key`. The
  #    nested collector must key by the TRAVERSAL PATH, else `node.key` throws `attribute 'key' missing`.
  #    A depth-2 nested aspect whose child carries a recognized structural sub-key (`includes`) is what the
  #    raw discriminator strips + registers (the compat-nested-aspects `blade.sini` shape). ──────────────
  directCompiled = denCompat.compile {
    aspects.blade = {
      nixos.ok = true;
      sub = {
        includes = [ { home-manager.x = true; } ];
      };
    };
    hosts.x86_64-linux.blade.class = "nixos";
  };
in
{
  flake.tests.compat-named-aspect-ref = {
    # (1) the nested nav ref delivers real content at the host + its native path is a resolved-aspect key.
    test-nested-nav-ref-delivers = {
      expr = {
        hasNixos = bucketAt nestedFleet "host:h1" "nixos" != [ ];
        grounded = builtins.elem "grp/sub/coll" (keysAt nestedFleet "host:h1");
      };
      expected = {
        hasNixos = true;
        grounded = true;
      };
    };
    # (2) the shallow (top-level) named ref stays green — the top-level registry key is unchanged.
    test-shallow-nav-ref-unchanged = {
      expr = {
        hasNixos = bucketAt shallowFleet "host:h1" "nixos" != [ ];
        grounded = builtins.elem "mycoll" (keysAt shallowFleet "host:h1");
      };
      expected = {
        hasNixos = true;
        grounded = true;
      };
    };
    # (3) an explicit `{ key = "grp/sub/coll"; }` ref resolves through the SAME path-keyed entry.
    test-explicit-key-ref-delivers = {
      expr = {
        hasNixos = bucketAt explicitKeyFleet "host:h1" "nixos" != [ ];
        grounded = builtins.elem "grp/sub/coll" (keysAt explicitKeyFleet "host:h1");
      };
      expected = {
        hasNixos = true;
        grounded = true;
      };
    };
    # (4) the DIRECT-`compile` path registers the nested aspect under the traversal path — the key derives
    #     from the walk (raw decls have no `.key`), and the parent stays stripped.
    test-direct-compile-path-key = {
      expr = {
        registered = directCompiled.aspects ? "blade/sub";
        parentStripped = !(directCompiled.aspects.blade ? sub);
      };
      expected = {
        registered = true;
        parentStripped = true;
      };
    };
  };
}
