# MATERIALIZED-DEFAULT CLASS-BUCKET GROUNDING (the gen-aspects universal-`id_hash` regression guard).
#
# gen-aspects mounts an UNCONDITIONAL `id_hash` option on EVERY typed aspect submodule (the universal
# `aspectId` content-address) — the `id_hash` submodule option in gen-aspects/lib/types.nix — so a
# PRE-grounding typed nav node carries `id_hash` alongside its native `.key` AND its v1-spelled materialized
# default class buckets (an empty `homeManager` deferredModule mounted on every node, from types.nix `classOptions`).
# The shim had OVERLOADED `id_hash`-presence as a proxy for "this ref is already a den-hoag-RESOLVED record,
# don't re-ground it" at three arms (compile.nix `normalize` include arm / `resolveAspectRef` / the
# `isEmittedContentSet` emit discriminator). Once gen-native stamps `id_hash` universally, that proxy admits
# a pre-grounding typed nav node as "resolved", so its un-grounded `homeManager` default reaches the kernel
# §2.2 classifier (concern-aspects.nix `classifyKey`, which registers only the kebab `home-manager`,
# key-semantics.nix) and ABORTS `declares key homeManager` — or (the emit arm) misroutes to a registry lookup
# that MISSES a strip-only nested sub-aspect and delivers an empty stub (the C1 zero-content gap).
#
# The fix decouples by STRUCTURE, never by an identity marker: a REGISTERED nav reference (its native `.key`
# is a registry key) RESOLVES to the one canonical grounded record; inline content grounds in place; the emit
# discriminator keys on `.key`/`.name` structure. These witnesses drive the two arms a materialized default
# reaches through — a static include (registered-reference resolution) and a navigated `policy.include` emit —
# and force `content-key-totality` (which runs `classifyKey`). A future gen-aspects id_hash/materialization
# change that re-coupled control flow to id_hash would re-throw §2.2 / drop content here. Sibling
# `compat-named-aspect-ref` guards the third arm (`resolveAspectRef`, a nested nav ref in
# `schema.<kind>.includes`).
{ denCompat, ... }:
let
  bucketAt =
    den: id: cls:
    map (e: e.module) ((den.structural.eval.get id "class-seeds").${cls} or [ ]);
  # Forcing `content-key-totality` is what runs `classifyKey` over the node's materialized defaults — the
  # abort site. That attribute IS the §2.2 classification driver (`class-seeds` demands it), so this forces
  # the gate directly rather than through a content read. `tryEval` so a §2.2 throw surfaces as `false`
  # rather than an eval crash.
  bucketOkAt =
    den: id:
    (builtins.tryEval (builtins.deepSeq (den.structural.eval.get id "content-key-totality") true))
    .success;
  mk = fx: denCompat.mkDen [ fx ];

  # ── (1) STATIC INCLUDE (compile.nix `normalize` include arm). A static-attrset aspect (`collector`, a class
  #    body under `nixos`) INCLUDED by a host aspect: the node is a REGISTERED nav reference (its native `.key`
  #    is a registry key), so `normalize` resolves it to the canonical grounded record — whose `homeManager`
  #    default is already `home-manager` — instead of re-grounding it in place. Pre-fix the arm gated on
  #    `!(ref ? id_hash)`, passed the (now id_hash-bearing) node through UN-grounded, and `homeManager` aborted
  #    §2.2 at the host. The discriminator is registry membership, NOT id_hash. ──────────────────────────────
  staticFleet =
    { den, ... }:
    {
      den.hosts.x86_64-linux.h1.class = "nixos";
      den.aspects.collector.nixos = {
        networking.hostName = "h1";
      };
      den.aspects.h1.includes = with den.aspects; [ collector ];
    };
  staticDen = (mk staticFleet).den;

  # ── (2) EMITTED NAVIGATED CONTENT SET (compile.nix `isEmittedContentSet` → `mkEmittedAspect`). A policy
  #    emitting `policy.include den.aspects.<path>` navigates a node carrying its OWN native `.key` AND (post
  #    universal-aspectId) `id_hash`. The emit discriminator must still route it to `mkEmittedAspect` (which
  #    grounds it by key), NOT exclude it as an "already-resolved record" → a registry lookup that misses the
  #    strip-only nested sub-aspect and returns `{ id_hash; name }` (empty). The value is built WITH `id_hash`
  #    — the shape gen-native now materializes — which the sibling `compat-nested-aspects` hand-built value
  #    (no `id_hash`) does not exercise. ──────────────────────────────────────────────────────────────────
  emitCompiled = denCompat.compile {
    policies.p =
      { host, user, ... }:
      [
        {
          __policyEffect = "include";
          value = {
            includes = [ ];
            homeManager.marker = true;
            name = "shuo";
            key = "blade/shuo";
            id_hash = "nav-blade-shuo";
            meta.aspect-chain = [ "blade" ];
          };
        }
      ];
    hosts.x86_64-linux.h1.class = "nixos";
  };
  emitted =
    (builtins.head (
      emitCompiled.policies.p.fn {
        host = {
          id_hash = "H-blade";
          name = "blade";
        };
        user = {
          id_hash = "U-shuo";
          name = "shuo";
        };
      }
    )).aspect;
in
{
  flake.tests.compat-materialized-class-ground = {
    # (1) the host resolves without a §2.2 abort, the collector's own class content lands, and the
    #     materialized `homeManager` default did NOT leak through un-grounded (no `home-manager` content, the
    #     empty default is inert — grounded then dropped as an empty bucket).
    test-static-include-materialized-default-grounds = {
      expr = {
        resolves = bucketOkAt staticDen "host:h1";
        nixosDelivered = bucketAt staticDen "host:h1" "nixos" != [ ];
        hmDefaultInert = bucketAt staticDen "host:h1" "home-manager" == [ ];
      };
      expected = {
        resolves = true;
        nixosDelivered = true;
        hmDefaultInert = true;
      };
    };
    # (2) the id_hash-bearing navigated emit grounds through `mkEmittedAspect`: its `homeManager` content is
    #     re-keyed to `home-manager` (not lost to an empty registry stub, not left v1-spelled).
    test-emitted-navigated-content-grounds = {
      expr = {
        grounded = emitted ? home-manager && !(emitted ? homeManager);
        contentKept = (emitted.home-manager or { }) != { };
      };
      expected = {
        grounded = true;
        contentKept = true;
      };
    };
  };
}
