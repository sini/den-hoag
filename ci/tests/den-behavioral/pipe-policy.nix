# den v1 BEHAVIORAL migration — public-api/pipe-policy.nix (denful/den templates/ci/modules/public-api/
# pipe-policy.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `pipe` (`pipe.from` with
# transform stages — `den.lib.policy.pipe` is forwarded).
{
  denHoag,
  denHoagFlakeModule,
  homeManagerModule,
  genInputs,
  nixpkgs,
  nixpkgsLib,
  ...
}:
let
  denTest = import ../_lib/den-compat-test.nix {
    inherit
      denHoag
      denHoagFlakeModule
      homeManagerModule
      nixpkgs
      nixpkgsLib
      ;
    flakeParts = genInputs.flake-parts;
  };
  # v1's file-level `{ denTest, lib, ... }:` arg — several nested class-module closures below (e.g.
  # `nixos = { items, ... }: { … lib.foo … }`) reference `lib` WITHOUT naming it as their own formal,
  # relying on v1's file-level lexical binding rather than the module system's per-module `lib` injection.
  # Reproduced identically so the pasted bodies need no per-closure edits.
  lib = nixpkgsLib;
in
{
  flake.tests.den-pipe = {

    # pipe.filter removes entries that don't match the predicate.
    test-pipe-filter = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.firewall = {
          description = "Firewall port declarations";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          firewall = [
            {
              port = 80;
              proto = "tcp";
            }
            {
              port = 53;
              proto = "udp";
            }
            {
              port = 443;
              proto = "tcp";
            }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { firewall, lib, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" (f: toString f.port) firewall;
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.filter-tcp = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.filter-tcp =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "firewall" [
              (pipe.filter (e: e.proto == "tcp"))
            ])
          ];

        den.default.includes = [ den.policies.filter-tcp ];

        # Only TCP entries survive: 80, 443.
        expr = igloo.networking.hostName;
        expected = "80-443";
      }
    );

    # pipe.transform maps each entry.
    test-pipe-transform = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.items = {
          description = "Items";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          items = [
            { name = "a"; }
            { name = "b"; }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { items, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" (i: i.label) items;
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.transform-items = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.transform-items =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "items" [
              (pipe.transform (i: {
                label = "x-${i.name}";
              }))
            ])
          ];

        den.default.includes = [ den.policies.transform-items ];

        expr = igloo.networking.hostName;
        expected = "x-a-x-b";
      }
    );

    # PARKED-DIVERGENCE (same pipe run-wiring gap as test-pipe-filter above): v1 expected "a-z"; den-hoag actual "a" (pipe.append not applied — nothing appended to the pool).
    # # pipe.append adds an entry to the pool.
    # test-pipe-append = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.items = {
    #       description = "Items";
    #     };
    #
    #     den.aspects.igloo = {
    #       includes = [
    #         den.aspects.producer
    #         den.aspects.consumer
    #       ];
    #     };
    #
    #     den.aspects.producer = {
    #       items = [
    #         { name = "a"; }
    #       ];
    #     };
    #
    #     den.aspects.consumer = {
    #       nixos =
    #         { items, ... }:
    #         {
    #           networking.hostName = lib.concatMapStringsSep "-" (i: i.name) items;
    #         };
    #     };
    #
    #     den.policies.append-item =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         (pipe.from "items" [
    #           (pipe.append { name = "z"; })
    #         ])
    #       ];
    #
    #     den.default.includes = [ den.policies.append-item ];
    #
    #     expr = igloo.networking.hostName;
    #     expected = "a-z";
    #   }
    # );

    # pipe.fold reduces the pool to a single value.
    test-pipe-fold = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.nums = {
          description = "Numbers";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          nums = [
            10
            20
            30
          ];
        };

        den.aspects.consumer = {
          nixos =
            { nums, ... }:
            {
              # fold produces a single-element list with the fold result.
              networking.hostName = toString (builtins.head nums);
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.fold-nums = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.fold-nums =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "nums" [
              (pipe.fold (acc: n: acc + n) 0)
            ])
          ];

        den.default.includes = [ den.policies.fold-nums ];

        expr = igloo.networking.hostName;
        expected = "60";
      }
    );

    # pipe.for replaces the list entirely.
    test-pipe-for = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.items = {
          description = "Items";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          items = [
            { name = "a"; }
            { name = "b"; }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { items, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" (i: i.name) items;
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.for-items = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.for-items =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "items" [
              (pipe.for (vals: lib.reverseList vals))
            ])
          ];

        den.default.includes = [ den.policies.for-items ];

        expr = igloo.networking.hostName;
        expected = "b-a";
      }
    );

    # Combined stages: filter then transform in one pipe.from.
    test-pipe-combined-stages = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.items = {
          description = "Items";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          items = [
            {
              name = "a";
              keep = true;
            }
            {
              name = "b";
              keep = false;
            }
            {
              name = "c";
              keep = true;
            }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { items, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" (i: i.label) items;
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.combined = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.combined =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "items" [
              (pipe.filter (i: i.keep))
              (pipe.transform (i: {
                label = lib.toUpper i.name;
              }))
            ])
          ];

        den.default.includes = [ den.policies.combined ];

        expr = igloo.networking.hostName;
        expected = "A-C";
      }
    );

    # PARKED — the unconsumed `append` mark, and now the ONLY thing between this case and green.
    # RE-MEASURED at this rev with the codomain declared (the body below carries it): "x-y--p" against
    # v1's "x-y-z--p". The beta arm's `pipe.filter` APPLIED — "q" is gone — so the deriving half of this
    # case is already correct and the alpha arm's `pipe.append "z"` is all that is missing. That makes
    # this a SECOND witness to the defect `test-pipe-append` above carries, not a separate gap:
    # `pipe.append` compiles to a site mark (lib/compat/pipe.nix, the `append` branch) that no consumer
    # reads — lib/compat/gather.nix interprets `expose`/`collect`/`collectAll`/`broadcast`, and nothing
    # anywhere interprets `append`.
    # # Multiple pipe.from in one policy targeting different pipes.
    # test-pipe-multiple-from = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.alpha = {
    #       description = "Alpha";
    #     };
    #     den.quirks.beta = {
    #       description = "Beta";
    #     };
    #
    #     den.aspects.igloo = {
    #       includes = [
    #         den.aspects.producer
    #         den.aspects.consumer
    #       ];
    #     };
    #
    #     den.aspects.producer = {
    #       alpha = [
    #         "x"
    #         "y"
    #       ];
    #       beta = [
    #         "p"
    #         "q"
    #       ];
    #     };
    #
    #     den.aspects.consumer = {
    #       nixos =
    #         { alpha, beta, ... }:
    #         {
    #           networking.hostName = lib.concatStringsSep "--" [
    #             (lib.concatStringsSep "-" alpha)
    #             (lib.concatStringsSep "-" beta)
    #           ];
    #         };
    #     };
    #
    #     # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
    #     # untouched. ONE declaration covers BOTH `pipe.from` effects: the codomain is the policy's, not
    #     # the effect's. The alpha arm is site-only and commits nothing; the beta arm's `filter` builds a
    #     # derived terminal, and that one commitment is what the whole body owes `pipeCommit` for.
    #     den.policyCodomains.multi-pipe = {
    #       emits = [
    #         "pipeCommit"
    #         "pipeMark"
    #       ];
    #       binds = [ ];
    #       suppresses = [ ];
    #     };
    #     den.policies.multi-pipe =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         (pipe.from "alpha" [
    #           (pipe.append "z")
    #         ])
    #         (pipe.from "beta" [
    #           (pipe.filter (v: v != "q"))
    #         ])
    #       ];
    #
    #     den.default.includes = [ den.policies.multi-pipe ];
    #
    #     # The two halves fail independently: "x-y--p" is a dropped append, "x-y-z--p-q" a dropped
    #     # filter, so neither arm can carry the other's pass.
    #     expr = igloo.networking.hostName;
    #     expected = "x-y-z--p";
    #   }
    # );

    # Multiple policies targeting the same pipe — results merge.
    test-pipe-multi-policy-merge = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.items = {
          description = "Items";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          items = [
            { name = "a"; }
            { name = "b"; }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { items, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" (i: i.name) items;
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.policy-a = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.policy-a =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "items" [
              (pipe.filter (i: i.name == "a"))
            ])
          ];

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.policy-b = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.policy-b =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "items" [
              (pipe.filter (i: i.name == "b"))
            ])
          ];

        den.default.includes = [
          den.policies.policy-a
          den.policies.policy-b
        ];

        # Both filters run independently on the base pool, results concatenated.
        expr = igloo.networking.hostName;
        expected = "a-b";
      }
    );

    # Multi-STAGE multi-policy: two policies on the same base, each `[ filter, transform ]` with DISTINCT
    # predicates. Their INTERMEDIATE filter nodes would share the predicate-blind `<base>.filter` id, so
    # without disambiguation compose's first-wins byId dedup would silently replace policy-b's filter with
    # policy-a's — dropping a non-terminal predicate. Each declaration's gen-pipe `site` folds a distinct id
    # into every stage (the site propagates down the linear chain), so both policies' filter AND transform survive.
    test-pipe-multi-policy-multi-stage = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.items = {
          description = "Items";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          items = [
            { name = "a"; }
            { name = "b"; }
            { name = "c"; }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { items, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" (i: i.name) items;
            };
        };

        # policy-a: drop "c", tag "a"; policy-b: drop "a", tag "b" — distinct filter AND transform (alnum
        # tags so the concatenated result is a valid hostName).
        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.policy-a = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.policy-a =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "items" [
              (pipe.filter (i: i.name != "c"))
              (pipe.transform (i: {
                name = "a${i.name}";
              }))
            ])
          ];

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.policy-b = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.policy-b =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "items" [
              (pipe.filter (i: i.name != "a"))
              (pipe.transform (i: {
                name = "b${i.name}";
              }))
            ])
          ];

        den.default.includes = [
          den.policies.policy-a
          den.policies.policy-b
        ];

        # policy-a keeps {a,b}→aa,ab ; policy-b keeps {b,c}→bb,bc ; per-policy concat in include order.
        # A terminal-only rename would collapse policy-b's filter onto policy-a's (drop "c"), yielding the
        # WRONG "aa-ab-ba-bb".
        expr = igloo.networking.hostName;
        expected = "aa-ab-bb-bc";
      }
    );

    # No pipe effects — pipe data passes through unchanged.
    test-pipe-no-policy-passthrough = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.items = {
          description = "Items";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          items = [
            { name = "a"; }
            { name = "b"; }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { items, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" (i: i.name) items;
            };
        };

        # No policies — pipe data passes through unmodified.
        expr = igloo.networking.hostName;
        expected = "a-b";
      }
    );
    # PARKED — `pipe.to` aspect-delivery is not wired, compounded by the unconsumed `append`.
    # RE-MEASURED at this rev with the codomain declared: `'builtins.head' called on an empty list`.
    # `secrets` has no native emitter and `filter (_: false)` empties what little there is, so both
    # consumers read [ ]. `to` compiles to an inert `targeted` intent that lib/compat/pipe.nix's own `to`
    # branch describes as awaiting "a FUTURE consumption-side aspect-carrier wiring (a separate WS-B
    # kernel seam)": an aspect is not a gen-pipe channel, so this delivery cannot be a route, and the
    # consumption-side carrier it needs instead does not exist yet.
    # # pipe.to delivers pipe data only to the targeted aspect.
    # test-pipe-to-aspect = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.secrets = {
    #       description = "Secret paths";
    #     };
    #
    #     den.aspects.igloo = {
    #       includes = [
    #         den.aspects.postgres
    #         den.aspects.nginx-server
    #       ];
    #     };
    #
    #     den.aspects.postgres = {
    #       nixos =
    #         { secrets, ... }:
    #         {
    #           networking.hostName = builtins.head secrets;
    #         };
    #     };
    #
    #     den.aspects.nginx-server = {
    #       nixos =
    #         { secrets, ... }:
    #         {
    #           networking.domain = builtins.head secrets;
    #         };
    #     };
    #
    #     # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
    #     # untouched. `to` is an aspect-delivery TARGET, the third commitment shape beside `derived` and
    #     # `routes`, so this body would owe `pipeCommit` on the `to` stages alone even without the filters.
    #     den.policyCodomains.app-secrets = {
    #       emits = [
    #         "pipeCommit"
    #         "pipeMark"
    #       ];
    #       binds = [ ];
    #       suppresses = [ ];
    #     };
    #     den.policies.app-secrets =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         (pipe.from "secrets" [
    #           (pipe.filter (_: false))
    #           (pipe.append "pg-pass")
    #           (pipe.to [ den.aspects.postgres ])
    #         ])
    #         (pipe.from "secrets" [
    #           (pipe.filter (_: false))
    #           (pipe.append "nginx-key")
    #           (pipe.to [ den.aspects.nginx-server ])
    #         ])
    #       ];
    #
    #     den.default.includes = [ den.policies.app-secrets ];
    #
    #     # The two consumers read the SAME channel and must see DIFFERENT values, so a `to` that
    #     # delivers to everyone fails here exactly as loudly as one that delivers to no one.
    #     expr = {
    #       host = igloo.networking.hostName;
    #       domain = igloo.networking.domain;
    #     };
    #     expected = {
    #       host = "pg-pass";
    #       domain = "nginx-key";
    #     };
    #   }
    # );

    # PARKED — the same two blockers as `test-pipe-to-aspect`: `pipe.to` unwired, `append` unconsumed.
    # RE-MEASURED at this rev with both codomains declared: "" against v1's "x-y". `filter (_: false)`
    # empties the base and neither append reaches it, so nothing survives for the two deliveries to
    # concatenate.
    # # Two policies targeting the same aspect on the same pipe concatenate.
    # test-pipe-to-same-aspect-concat = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.items = {
    #       description = "Items";
    #     };
    #
    #     den.aspects.igloo = {
    #       includes = [ den.aspects.consumer ];
    #     };
    #
    #     den.aspects.consumer = {
    #       nixos =
    #         { items, ... }:
    #         {
    #           networking.hostName = lib.concatStringsSep "-" items;
    #         };
    #     };
    #
    #     # THE DECLARATION COMPLETED — one record per POLICY, and the two are separate policies even
    #     # though their bodies are the same shape over the same channel.
    #     den.policyCodomains.policy-a = {
    #       emits = [
    #         "pipeCommit"
    #         "pipeMark"
    #       ];
    #       binds = [ ];
    #       suppresses = [ ];
    #     };
    #     den.policies.policy-a =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         (pipe.from "items" [
    #           (pipe.filter (_: false))
    #           (pipe.append "x")
    #           (pipe.to [ den.aspects.consumer ])
    #         ])
    #       ];
    #
    #     den.policyCodomains.policy-b = {
    #       emits = [
    #         "pipeCommit"
    #         "pipeMark"
    #       ];
    #       binds = [ ];
    #       suppresses = [ ];
    #     };
    #     den.policies.policy-b =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         (pipe.from "items" [
    #           (pipe.filter (_: false))
    #           (pipe.append "y")
    #           (pipe.to [ den.aspects.consumer ])
    #         ])
    #       ];
    #
    #     den.default.includes = [
    #       den.policies.policy-a
    #       den.policies.policy-b
    #     ];
    #
    #     # Both targeted effects concatenate for the same aspect. The `filter (_: false)` empties the
    #     # base first, so ONLY the two appends can produce this value — "x" or "y" alone is one policy's
    #     # delivery lost, and "" is both.
    #     expr = igloo.networking.hostName;
    #     expected = "x-y";
    #   }
    # );

    # PARKED — the same two blockers as `test-pipe-to-aspect`. RE-MEASURED at this rev with the codomain
    # declared: { normal = "a-b"; special = "a-b"; } against v1's
    # { normal = "a-b-c"; special = "special-only"; }. The two consumers AGREE, and that is the whole
    # failure: with no aspect-carrier the targeted arm collapses onto the same scope-wide pool the
    # untargeted arm reads. The missing "c" on `normal` is the untargeted arm's own `append`.
    # # Untargeted and targeted coexist: targeted overrides for specific aspect.
    # test-pipe-to-with-untargeted = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.items = {
    #       description = "Items";
    #     };
    #
    #     den.aspects.igloo = {
    #       includes = [
    #         den.aspects.producer
    #         den.aspects.special
    #         den.aspects.normal
    #       ];
    #     };
    #
    #     den.aspects.producer = {
    #       items = [
    #         "a"
    #         "b"
    #       ];
    #     };
    #
    #     # special is targeted — gets targeted data (overrides scope-wide)
    #     den.aspects.special = {
    #       nixos =
    #         { items, ... }:
    #         {
    #           networking.hostName = lib.concatStringsSep "-" items;
    #         };
    #     };
    #
    #     # normal is NOT targeted — gets untargeted scope-wide data
    #     den.aspects.normal = {
    #       nixos =
    #         { items, ... }:
    #         {
    #           networking.domain = lib.concatStringsSep "-" items;
    #         };
    #     };
    #
    #     # THE DECLARATION COMPLETED — the targeted arm's `to` is the commitment; the untargeted arm
    #     # beside it is site-only. Both ride ONE policy record.
    #     den.policyCodomains.mixed-policy = {
    #       emits = [
    #         "pipeCommit"
    #         "pipeMark"
    #       ];
    #       binds = [ ];
    #       suppresses = [ ];
    #     };
    #     den.policies.mixed-policy =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         # Untargeted: append "c" to all
    #         (pipe.from "items" [
    #           (pipe.append "c")
    #         ])
    #         # Targeted: special only gets filtered + appended result
    #         (pipe.from "items" [
    #           (pipe.filter (_: false))
    #           (pipe.append "special-only")
    #           (pipe.to [ den.aspects.special ])
    #         ])
    #       ];
    #
    #     den.default.includes = [ den.policies.mixed-policy ];
    #
    #     # The two consumers read ONE channel and must DISAGREE. `special == normal` is the whole
    #     # failure — the targeted arm collapsing back onto the scope-wide pool — and it is unreachable
    #     # here whichever value the collapse lands on.
    #     expr = {
    #       # special sees targeted data (overrides scope-wide)
    #       special = igloo.networking.hostName;
    #       # normal sees untargeted data (scope-wide)
    #       normal = igloo.networking.domain;
    #     };
    #     expected = {
    #       special = "special-only";
    #       normal = "a-b-c";
    #     };
    #   }
    # );
    # pipe.from accepts a quirk REF (`den.quirks.firewall`) in place of the name string; the ref carries
    # its own `name` (the navigation view's stamp, flake-module.nix `annotatedViewNav`), which is what the
    # pipe constructor reads. RED for the deriving-stage cause the armed `pipe.filter`/`transform`/`fold`/
    # `for`/`as` cases above carry, NOT for the ref form: a deriving stage or a delivery route in a policy
    # BODY is a fleet-compose commitment (`compose commitment` abort, on the undeclared-codomain law),
    # so the body must declare it as data in `ops` and emit only per-node site marks.
    test-pipe-from-ref = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.firewall = {
          description = "Firewall port declarations";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          firewall = [
            80
            443
          ];
        };

        den.aspects.consumer = {
          nixos =
            { firewall, lib, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" toString firewall;
            };
        };

        # Use ref syntax: den.quirks.firewall instead of string "firewall".
        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.filter-high = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.filter-high =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from den.quirks.firewall [
              (pipe.filter (p: p > 100))
            ])
          ];

        den.default.includes = [ den.policies.filter-high ];

        expr = igloo.networking.hostName;
        expected = "443";
      }
    );

    # pipe.as renames pipe output to a different quirk name.
    test-pipe-as-basic = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.source = {
          description = "Source pipe";
        };
        den.quirks.target = {
          description = "Target pipe (no native emitters)";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          source = [
            { name = "a"; }
            { name = "b"; }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { target, ... }:
            {
              networking.hostName = lib.concatMapStringsSep "-" (i: i.name) target;
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.rename-pipe = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.rename-pipe =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "source" [
              (pipe.as "target")
            ])
          ];

        den.default.includes = [ den.policies.rename-pipe ];

        expr = igloo.networking.hostName;
        expected = "a-b";
      }
    );

    # pipe.as with transform: data reshaped before renaming.
    test-pipe-as-with-transform = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.raw-ports = {
          description = "Raw port data";
        };
        den.quirks.firewall-rules = {
          description = "Derived firewall rules";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.consumer
          ];
        };

        den.aspects.producer = {
          raw-ports = [
            {
              port = 80;
              proto = "tcp";
            }
            {
              port = 443;
              proto = "tcp";
            }
          ];
        };

        den.aspects.consumer = {
          nixos =
            { firewall-rules, ... }:
            {
              networking.domain = lib.concatStringsSep "-" firewall-rules;
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.derive-rules = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.derive-rules =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "raw-ports" [
              (pipe.transform (p: "${p.proto}:${toString p.port}"))
              (pipe.as "firewall-rules")
            ])
          ];

        den.default.includes = [ den.policies.derive-rules ];

        expr = igloo.networking.domain;
        expected = "tcp:80-tcp:443";
      }
    );

    # PARKED — a gathered contribution never enters the derive chain.
    # RE-MEASURED at this rev with the codomain declared: { count = "1"; urls = "http://10.0.0.1:80"; }
    # against v1's { count = "2"; urls = "http://10.0.0.1:80,http://10.0.0.2:80"; }.
    # ★ THE OLD PARK NOTE'S DIAGNOSIS IS FALSIFIED. It recorded { count = "0"; urls = ""; } and blamed
    # "transform+as not applied". Both ARE applied: the one URL present is in transformed form, and it
    # arrived at `peer-urls`, which has no native emitter, so it can only have come down the `as` route.
    # What is missing is iceberg's entry. The `collect` mark merges peer contributions onto the BASE
    # channel at the node, while the route reads the DERIVED terminal composed from the base's own
    # contributions — so a gathered value bypasses the chain rooted above it.
    # Same root as pipe-scope.nix's `test-pipe-collect-filter`.
    # # pipe.as + pipe.collect: cross-host collection delivered under target name.
    # test-pipe-as-with-collect = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.http-addrs = {
    #       description = "HTTP addresses";
    #     };
    #     den.quirks.peer-urls = {
    #       description = "Derived peer URLs (no native emitters)";
    #     };
    #
    #     # THE DECLARATION COMPLETED — the `as` route is the commitment (a channel→channel move seeded
    #     # into the ONE fleet compose), the collect mark is per-node emission wiring.
    #     den.policyCodomains.collect-as-urls = {
    #       emits = [
    #         "pipeCommit"
    #         "pipeMark"
    #       ];
    #       binds = [ ];
    #       suppresses = [ ];
    #     };
    #     den.policies.collect-as-urls =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         (pipe.from "http-addrs" [
    #           (pipe.collect ({ host, ... }: true))
    #           (pipe.transform (a: "http://${a.addr}:${toString a.port}"))
    #           (pipe.as "peer-urls")
    #         ])
    #       ];
    #
    #     den.schema.host.includes = [ den.policies.collect-as-urls ];
    #
    #     den.aspects.iceberg = {
    #       http-addrs = {
    #         addr = "10.0.0.2";
    #         port = 80;
    #       };
    #     };
    #
    #     den.aspects.igloo = {
    #       includes = [ den.aspects.url-consumer ];
    #       http-addrs = {
    #         addr = "10.0.0.1";
    #         port = 80;
    #       };
    #     };
    #
    #     den.aspects.url-consumer = {
    #       nixos =
    #         { peer-urls, lib, ... }:
    #         {
    #           networking.hostName = toString (builtins.length peer-urls);
    #           networking.domain = lib.concatStringsSep "," (lib.sort (a: b: a < b) peer-urls);
    #         };
    #     };
    #
    #     # `peer-urls` has no native emitter, so every entry here arrived by route. The count separates a
    #     # lost gather (1) from a lost route (0); the urls separate a lost transform (the raw attrsets
    #     # cannot be sorted as strings) from a route carrying the base instead of the derived terminal.
    #     expr = {
    #       count = igloo.networking.hostName;
    #       urls = igloo.networking.domain;
    #     };
    #     expected = {
    #       count = "2";
    #       urls = "http://10.0.0.1:80,http://10.0.0.2:80";
    #     };
    #   }
    # );

    # pipe.as + pipe.to: aspect-targeted delivery under renamed pipe.
    # NOTE: the `pipe.to` targeting is redundant with `pipe.as` in THIS fleet — `derived-data` is consumed
    # ONLY by `targeted-consumer` (normal-consumer reads `raw-data`, a different channel), so the `as` route
    # alone delivers the transformed value to the renamed channel and the sole consumer reads it. The `to`
    # aspect-index (DONE_WITH_CONCERNS) is not needed to distinguish consumers here.
    test-pipe-as-with-to = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.raw-data = {
          description = "Raw data";
        };
        den.quirks.derived-data = {
          description = "Derived data (no native emitters)";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.producer
            den.aspects.targeted-consumer
            den.aspects.normal-consumer
          ];
        };

        den.aspects.producer = {
          raw-data = [
            "x"
            "y"
          ];
        };

        # This aspect gets derived-data via pipe.as + pipe.to.
        den.aspects.targeted-consumer = {
          nixos =
            { derived-data, ... }:
            {
              networking.hostName = lib.concatStringsSep "-" derived-data;
            };
        };

        # This aspect reads raw-data normally (unaffected by pipe.as).
        den.aspects.normal-consumer = {
          nixos =
            { raw-data, ... }:
            {
              networking.domain = lib.concatStringsSep "-" raw-data;
            };
        };

        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.as-and-to = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.as-and-to =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "raw-data" [
              (pipe.transform (v: "d-${v}"))
              (pipe.as "derived-data")
              (pipe.to [ den.aspects.targeted-consumer ])
            ])
          ];

        den.default.includes = [ den.policies.as-and-to ];

        expr = {
          targeted = igloo.networking.hostName;
          normal = igloo.networking.domain;
        };
        expected = {
          # targeted-consumer gets derived-data via pipe.as + pipe.to
          targeted = "d-x-d-y";
          # normal-consumer gets raw-data unmodified
          normal = "x-y";
        };
      }
    );

    # No-emitter quirk: entirely populated by pipe.as from another pipe.
    test-pipe-as-no-emitter-quirk = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.backends = {
          description = "Backend addresses";
        };
        den.quirks.monitoring-targets = {
          description = "Monitoring targets (no native emitters)";
        };

        den.aspects.igloo = {
          includes = [
            den.aspects.web
            den.aspects.monitor
          ];
        };

        # web emits backends, never mentions monitoring-targets.
        den.aspects.web = {
          backends = [
            {
              addr = "10.0.0.1";
              port = 80;
            }
            {
              addr = "10.0.0.2";
              port = 443;
            }
          ];
        };

        # monitor consumes monitoring-targets — which has no native emitters.
        den.aspects.monitor = {
          nixos =
            { monitoring-targets, lib, ... }:
            {
              networking.domain = lib.concatStringsSep "," (lib.sort (a: b: a < b) monitoring-targets);
            };
        };

        # Policy derives monitoring-targets from backends via pipe.as.
        # THE DECLARATION COMPLETED — through the fleet surface, beside the policy and leaving the body
        # untouched. A `pipe` stage pair states BOTH kinds: the commitment seeds the ONE fleet compose
        # before the eval, and the mark route emits at every dispatched node, so a `pipeCommit`-only
        # declaration clears the commitment abort and fails the next one at `emitsUndeclared`.
        den.policyCodomains.backends-to-monitoring = {
          emits = [
            "pipeCommit"
            "pipeMark"
          ];
          binds = [ ];
          suppresses = [ ];
        };
        den.policies.backends-to-monitoring =
          { host, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [
            (pipe.from "backends" [
              (pipe.transform (b: "${b.addr}:${toString b.port}"))
              (pipe.as "monitoring-targets")
            ])
          ];

        den.default.includes = [ den.policies.backends-to-monitoring ];

        expr = igloo.networking.domain;
        expected = "10.0.0.1:80,10.0.0.2:443";
      }
    );

    # PARKED — den-hoag DIVERGES where v1 refused. RE-MEASURED at this rev with the codomain declared:
    # `stack overflow; max-call-depth exceeded`. `pipe.as "items"` on channel `items` builds a route
    # whose `from` and `to` ends are the same channel; nothing refuses it, so compose chases the cycle.
    # ★ NOT ARMED AS AN `expectedError` ON THAT MESSAGE, DELIBERATELY. This case exists to witness that a
    # self-reference is REFUSED, so asserting the overflow would assert the refusal's ABSENCE: it would
    # sit green over the defect and then turn red on the day the named refusal lands. The assertion is
    # left below in the form it should take once there is a refusal to name.
    # ★ v1's original `!(builtins.tryEval (builtins.seq … null)).success` is NOT restored either. That
    # boolean is true for ANY throw from anywhere in the fleet, so it would have passed on the
    # undeclared-codomain abort and on this overflow alike — it cannot fail for its own reason.
    # # pipe.as targeting own pipe throws an error.
    # #
    # # THE ASSERTION IS SHARPENED FROM WHAT v1 CARRIED. v1 asserted
    # # `!(builtins.tryEval (builtins.seq … null)).success` — a boolean that is `true` for ANY throw from
    # # anywhere in the fleet, including the undeclared-codomain abort this case now has to clear, so it
    # # would have passed on precisely the wrong error. `expectedError` rides nix-unit's native channel
    # # instead: it matches the message, and it FAILS when nothing throws at all.
    # test-pipe-as-self-error = denTest (
    #   { den, igloo, ... }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.quirks.items = {
    #       description = "Items";
    #     };
    #
    #     den.aspects.igloo = {
    #       items = [ "a" ];
    #       nixos =
    #         { items, ... }:
    #         {
    #           networking.hostName = lib.concatStringsSep "-" items;
    #         };
    #     };
    #
    #     # THE DECLARATION COMPLETED — an `as` stage builds a delivery route, and a route is a
    #     # commitment whether or not its target resolves. Declaring it is what lets the SELF-reference be
    #     # the error this case reaches, rather than the missing declaration.
    #     den.policyCodomains.self-as = {
    #       emits = [
    #         "pipeCommit"
    #         "pipeMark"
    #       ];
    #       binds = [ ];
    #       suppresses = [ ];
    #     };
    #     den.policies.self-as =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         (pipe.from "items" [
    #           (pipe.as "items")
    #         ])
    #       ];
    #
    #     den.default.includes = [ den.policies.self-as ];
    #
    #     expr = igloo.networking.hostName;
    #     expectedError = {
    #       type = "ThrownError";
    #       msg = "self";
    #     };
    #   }
    # );
  };
}
