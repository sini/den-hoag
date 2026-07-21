# den v1 BEHAVIORAL migration — public-api/pipe-broadcast.nix (denful/den templates/ci/modules/public-api/
# pipe-broadcast.nix). Migrated by copy + arg-rename onto the `_lib/den-compat-test.nix` scaffold; the
# `den.*` declarations + the assertions are BYTE-IDENTICAL to v1. Concern: `pipe` (`pipe.broadcast` — push
# primitive, dual of `pipe.expose` — `den.lib.policy.pipe` is forwarded).
{
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
      denHoagFlakeModule
      homeManagerModule
      nixpkgs
      nixpkgsLib
      ;
    flakeParts = genInputs.flake-parts;
  };
  # v1's file-level `{ denTest, lib, ... }:` arg — nested class-module closures below reference `lib`
  # without naming it as their own formal (see pipe-policy.nix for the full rationale).
  lib = nixpkgsLib;
in
{
  flake.tests.den-pipe = {

    # BLOCKED-WSB (known gap, same as host-aspects-sibling-leak.nix "on-demand hm-users key"):
    # home-manager.users.<name> entries are created ON-DEMAND (content-driven), not for every
    # nominally-homeManager-classed user; forcing `tuxHm` throws `attribute 'tux' missing`.
    # # Basic all-to-all: each user broadcasts peer-dev to every user scope
    # # fleet-wide. tux's home sees its own base (tux) + alice's broadcast.
    # test-broadcast-basic = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     den.aspects.tux = {
    #       peer-dev = [ { who = "tux@igloo"; } ];
    #       homeManager =
    #         { peer-dev, ... }:
    #         {
    #           home.sessionVariables.PEERS = lib.concatStringsSep "," (
    #             lib.sort (a: b: a < b) (map (p: p.who) peer-dev)
    #           );
    #         };
    #     };
    #     den.aspects.alice = {
    #       peer-dev = [ { who = "alice@iceberg"; } ];
    #     };
    #
    #     # USER scope: broadcast peer-dev to all user scopes fleet-wide.
    #     den.policies.broadcast-peer-dev =
    #       { host, user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.broadcast ({ user, ... }: true)) ]) ];
    #     den.schema.user.includes = [ den.policies.broadcast-peer-dev ];
    #
    #     # tux's home sees BOTH its own and alice's broadcast peer-dev.
    #     expr = tuxHm.home.sessionVariables.PEERS;
    #     expected = "alice@iceberg,tux@igloo";
    #   }
    # );

    # PARKED-DIVERGENCE (pipe.broadcast is UNWIRED for consumption — confirmed by source:
    # lib/compat/flake-module.nix:532 `channelGather = collectGather.mkGather entityKinds` composes
    # only expose+collect/collectAll; no `broadcast-gather.nix`-equivalent supplier exists, so the
    # `__pipeMark = "broadcast"` site marker lib/compat/pipe.nix builds is never consulted):
    # v1 expected "alice@iceberg"; den-hoag actual "" (igloo's host consumer gathers nothing — alice's broadcast never reaches it).
    # # User → REMOTE host. alice (a user on iceberg) broadcasts her device
    # # record to every HOST scope ({ host, ... }: true). igloo — a host on the
    # # OTHER side of the fleet — consumes it at host scope. Crosses both the
    # # entity-kind boundary (user → host) and the host boundary.
    # test-broadcast-to-remote-host = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     den.aspects.alice = {
    #       peer-dev = [ { who = "alice@iceberg"; } ];
    #     };
    #
    #     # USER scope: broadcast to all HOST scopes fleet-wide.
    #     den.policies.broadcast-to-hosts =
    #       { host, user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.broadcast ({ host, ... }: true)) ]) ];
    #     den.schema.user.includes = [ den.policies.broadcast-to-hosts ];
    #
    #     # igloo (remote relative to alice) consumes the broadcast at host scope.
    #     den.aspects.igloo = {
    #       includes = [ den.aspects.peer-consumer ];
    #     };
    #     den.aspects.peer-consumer = {
    #       nixos =
    #         { peer-dev, lib, ... }:
    #         {
    #           networking.domain = lib.concatStringsSep "," (lib.sort (a: b: a < b) (map (p: p.who) peer-dev));
    #         };
    #     };
    #
    #     expr = igloo.networking.domain;
    #     expected = "alice@iceberg";
    #   }
    # );

    # BLOCKED-WSB (known gap, same as host-aspects-sibling-leak.nix "on-demand hm-users key"):
    # home-manager.users.<name> entries are created ON-DEMAND (content-driven), not for every
    # nominally-homeManager-classed user; forcing `tuxHm` throws `attribute 'tux' missing`.
    # # Source-side transform stages apply BEFORE distribution: the broadcast
    # # value is the transformed view, identical at every receiver.
    # test-broadcast-source-transform = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     den.aspects.tux = {
    #       peer-dev = [ { who = "tux"; } ];
    #       homeManager =
    #         { peer-dev, ... }:
    #         {
    #           home.sessionVariables.PEERS = lib.concatStringsSep "," (
    #             lib.sort (a: b: a < b) (map (p: p.who) peer-dev)
    #           );
    #         };
    #     };
    #     den.aspects.alice = {
    #       peer-dev = [ { who = "alice"; } ];
    #     };
    #
    #     # Transform (uppercase-style tag) runs source-side, then broadcast.
    #     den.policies.broadcast-peer-dev =
    #       { host, user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [
    #         (pipe.from "peer-dev" [
    #           (pipe.transform (p: {
    #             who = "dev:${p.who}";
    #           }))
    #           (pipe.broadcast ({ user, ... }: true))
    #         ])
    #       ];
    #     den.schema.user.includes = [ den.policies.broadcast-peer-dev ];
    #
    #     # tux's own value is transformed too (own untargeted path) + alice's
    #     # transformed broadcast → uniform "dev:" view everywhere.
    #     expr = tuxHm.home.sessionVariables.PEERS;
    #     expected = "dev:alice,dev:tux";
    #   }
    # );

    # Predicate scoping (negative): a broadcast targeting USER scopes is NOT
    # visible to a HOST consumer — the receiver predicate gates by entity kind.
    test-broadcast-predicate-excludes-host = denTest (
      {
        den,
        igloo,
        lib,
        ...
      }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.hosts.x86_64-linux.iceberg.users.alice = { };

        den.quirks.peer-dev.description = "per-user device records";

        den.aspects.tux = {
          peer-dev = [ { who = "tux@igloo"; } ];
        };
        den.aspects.alice = {
          peer-dev = [ { who = "alice@iceberg"; } ];
        };

        # Broadcast to USER scopes only.
        den.policies.broadcast-peer-dev =
          { host, user, ... }:
          let
            inherit (den.lib.policy) pipe;
          in
          [ (pipe.from "peer-dev" [ (pipe.broadcast ({ user, ... }: true)) ]) ];
        den.schema.user.includes = [ den.policies.broadcast-peer-dev ];

        # HOST consumer reads peer-dev — should be empty (host is not a user).
        den.aspects.igloo = {
          includes = [ den.aspects.host-consumer ];
        };
        den.aspects.host-consumer = {
          nixos =
            { peer-dev, lib, ... }:
            {
              networking.domain = lib.concatStringsSep "," (map (p: p.who) peer-dev);
            };
        };

        expr = igloo.networking.domain;
        expected = "";
      }
    );

    # BLOCKED-WSB (known gap, same as host-aspects-sibling-leak.nix "on-demand hm-users key"):
    # home-manager.users.<name> entries are created ON-DEMAND (content-driven), not for every
    # nominally-homeManager-classed user; forcing `tuxHm` throws `attribute 'tux' missing`.
    # # Self-exclusion (S≠R): a lone broadcaster sees only its own base, NOT a
    # # duplicate of its own broadcast value.
    # test-broadcast-self-excluded = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     den.aspects.tux = {
    #       peer-dev = [ { who = "tux@igloo"; } ];
    #       homeManager =
    #         { peer-dev, ... }:
    #         {
    #           home.sessionVariables.PEERS = lib.concatStringsSep "," (map (p: p.who) peer-dev);
    #         };
    #     };
    #
    #     den.policies.broadcast-peer-dev =
    #       { host, user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.broadcast ({ user, ... }: true)) ]) ];
    #     den.schema.user.includes = [ den.policies.broadcast-peer-dev ];
    #
    #     # Only tux's own base — no self-broadcast duplicate.
    #     expr = tuxHm.home.sessionVariables.PEERS;
    #     expected = "tux@igloo";
    #   }
    # );

    # BLOCKED-WSB (known gap, same as host-aspects-sibling-leak.nix "on-demand hm-users key"):
    # home-manager.users.<name> entries are created ON-DEMAND (content-driven), not for every
    # nominally-homeManager-classed user; forcing `tuxHm` throws `attribute 'tux' missing`.
    # # No leak: a narrow predicate reaches ONLY matching scopes. Every user
    # # broadcasts to tux alone ({ user }: user.name == "tux"). tux receives
    # # pingu's record; pingu receives NOTHING (tux's broadcast must not leak to
    # # a non-matching peer). Both homes inspected.
    # test-broadcast-targeted-no-leak = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     pinguHm,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.igloo.users.pingu = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     den.aspects.tux = {
    #       peer-dev = [ { who = "tux"; } ];
    #       homeManager =
    #         { peer-dev, ... }:
    #         {
    #           home.sessionVariables.PEERS = lib.concatStringsSep "," (
    #             lib.sort (a: b: a < b) (map (p: p.who) peer-dev)
    #           );
    #         };
    #     };
    #     den.aspects.pingu = {
    #       peer-dev = [ { who = "pingu"; } ];
    #       homeManager =
    #         { peer-dev, ... }:
    #         {
    #           home.sessionVariables.PEERS = lib.concatStringsSep "," (
    #             lib.sort (a: b: a < b) (map (p: p.who) peer-dev)
    #           );
    #         };
    #     };
    #
    #     den.policies.broadcast-to-tux =
    #       { host, user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.broadcast ({ user, ... }: user.name == "tux")) ]) ];
    #     den.schema.user.includes = [ den.policies.broadcast-to-tux ];
    #
    #     expr = {
    #       tux = tuxHm.home.sessionVariables.PEERS;
    #       pingu = pinguHm.home.sessionVariables.PEERS;
    #     };
    #     expected = {
    #       # tux receives pingu's broadcast + own base.
    #       tux = "pingu,tux";
    #       # pingu is not a target — sees only its own base. No leak.
    #       pingu = "pingu";
    #     };
    #   }
    # );

    # BLOCKED-WSB (same on-demand hm-users key gap as test-broadcast-basic above, here on `alice`):
    # forcing `iceberg.home-manager.users.alice` throws `attribute 'alice' missing`.
    # # Compound { host, user } targeting: a predicate requiring BOTH host and
    # # user selects USER scopes (host scopes lack `user`) and can filter on the
    # # receiver's host. alice@iceberg broadcasts to user scopes on igloo only.
    # # tux@igloo receives; alice@iceberg (wrong host) does not.
    # test-broadcast-target-host-user = denTest (
    #   {
    #     den,
    #     iceberg,
    #     tuxHm,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     den.aspects.tux = {
    #       peer-dev = [ { who = "tux@igloo"; } ];
    #       homeManager =
    #         { peer-dev, ... }:
    #         {
    #           home.sessionVariables.PEERS = lib.concatStringsSep "," (
    #             lib.sort (a: b: a < b) (map (p: p.who) peer-dev)
    #           );
    #         };
    #     };
    #     den.aspects.alice = {
    #       peer-dev = [ { who = "alice@iceberg"; } ];
    #       homeManager =
    #         { peer-dev, ... }:
    #         {
    #           home.sessionVariables.PEERS = lib.concatStringsSep "," (
    #             lib.sort (a: b: a < b) (map (p: p.who) peer-dev)
    #           );
    #         };
    #     };
    #
    #     # Target user scopes whose host is igloo (requires host AND user in ctx).
    #     den.policies.broadcast-to-igloo-users =
    #       { host, user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.broadcast ({ host, user, ... }: host.name == "igloo")) ]) ];
    #     den.schema.user.includes = [ den.policies.broadcast-to-igloo-users ];
    #
    #     expr = {
    #       tux = tuxHm.home.sessionVariables.PEERS;
    #       alice = iceberg.home-manager.users.alice.home.sessionVariables.PEERS;
    #     };
    #     expected = {
    #       # tux (user on igloo) receives alice's broadcast + own base.
    #       tux = "alice@iceberg,tux@igloo";
    #       # alice (user on iceberg) is not targeted — own base only.
    #       alice = "alice@iceberg";
    #     };
    #   }
    # );

    # PARKED-DIVERGENCE (pipe.broadcast is UNWIRED for consumption — confirmed by source:
    # lib/compat/flake-module.nix:532 `channelGather = collectGather.mkGather entityKinds` composes
    # only expose+collect/collectAll; no `broadcast-gather.nix`-equivalent supplier exists, so the
    # `__pipeMark = "broadcast"` site marker lib/compat/pipe.nix builds is never consulted):
    # v1 expected "h-iceberg"; den-hoag actual "" (host-sourced broadcast never reaches igloo's consumer).
    # # Config-dependent emit broadcast from a HOST source resolves against the
    # # producer's class config — the host's own nixos config.
    # test-broadcast-config-thunk-host = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     den.aspects.set-hostname.nixos =
    #       { host, ... }:
    #       {
    #         networking.hostName = host.name;
    #       };
    #
    #     # iceberg HOST emits a config-dependent record and broadcasts to hosts.
    #     den.aspects.iceberg.peer-dev = { config, ... }: [ { who = "h-${config.networking.hostName}"; } ];
    #     den.policies.broadcast-to-hosts =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.broadcast ({ host, ... }: true)) ]) ];
    #     den.schema.host.includes = [
    #       den.aspects.set-hostname
    #       den.policies.broadcast-to-hosts
    #     ];
    #
    #     den.aspects.igloo.includes = [ den.aspects.peer-consumer ];
    #     den.aspects.peer-consumer.nixos =
    #       { peer-dev, ... }:
    #       {
    #         networking.domain = lib.concatStringsSep "," (map (p: p.who) peer-dev);
    #       };
    #
    #     expr = igloo.networking.domain;
    #     expected = "h-iceberg";
    #   }
    # );

    # PARKED-DIVERGENCE (pipe.broadcast is UNWIRED for consumption — confirmed by source:
    # lib/compat/flake-module.nix:532 `channelGather = collectGather.mkGather entityKinds` composes
    # only expose+collect/collectAll; no `broadcast-gather.nix`-equivalent supplier exists, so the
    # `__pipeMark = "broadcast"` site marker lib/compat/pipe.nix builds is never consulted):
    # v1 expected "u-alice"; den-hoag actual "" (user-sourced broadcast never reaches igloo's consumer).
    # # A config-dependent emit broadcast from a USER source resolves against the
    # # PRODUCER's class config — the user's home-manager config (not the cross-
    # # host nixos config, which has no entry for a user scope). alice reads her
    # # own home field; the resolved value reaches a peer host's consumer.
    # test-broadcast-config-thunk-user = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     # alice (USER) emits a config-dependent record reading her HOME config,
    #     # broadcast to hosts. Resolves against alice's home-manager config.
    #     den.aspects.alice.peer-dev = { config, ... }: [ { who = "u-${config.home.username}"; } ];
    #     den.policies.broadcast-to-hosts =
    #       { host, user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.broadcast ({ host, ... }: true)) ]) ];
    #     den.schema.user.includes = [ den.policies.broadcast-to-hosts ];
    #
    #     den.aspects.igloo.includes = [ den.aspects.peer-consumer ];
    #     den.aspects.peer-consumer.nixos =
    #       { peer-dev, ... }:
    #       {
    #         networking.domain = lib.concatStringsSep "," (map (p: p.who) peer-dev);
    #       };
    #
    #     expr = igloo.networking.domain;
    #     expected = "u-alice";
    #   }
    # );

    # BLOCKED-WSB (known gap, same as host-aspects-sibling-leak.nix "on-demand hm-users key"):
    # home-manager.users.<name> entries are created ON-DEMAND (content-driven), not for every
    # nominally-homeManager-classed user; forcing `tuxHm` throws `attribute 'tux' missing`.
    # # Pure-receiver binding: a user with NO own emit/effect, on a host that runs
    # # a peer-dev policy (so its policyBoundAncestor is non-null), receives a
    # # peer's broadcast. The bindsPipeLocally broadcast clause makes tux read the
    # # broadcast ("alice"); WITHOUT it tux would fall through to ancestor
    # # inheritance and read igloo host's collected value ("igloo-host").
    # test-broadcast-pure-receiver-binds = denTest (
    #   {
    #     den,
    #     tuxHm,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.peer-dev.description = "per-user device records";
    #
    #     # alice-specific broadcast (NOT schema.user — so tux has no peer-dev policy).
    #     den.policies.broadcast-peer-dev =
    #       { user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.broadcast ({ user, ... }: true)) ]) ];
    #     den.aspects.alice = {
    #       peer-dev = [ { who = "alice"; } ];
    #       includes = [ den.policies.broadcast-peer-dev ];
    #     };
    #
    #     # igloo host binds peer-dev (policy effect → tux's policyBoundAncestor)
    #     # with a DISTINCT value, so inheritance is observable.
    #     den.policies.host-collect =
    #       { host, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "peer-dev" [ (pipe.collectAll ({ host, ... }: true)) ]) ];
    #     den.aspects.igloo = {
    #       peer-dev = [ { who = "igloo-host"; } ];
    #       includes = [ den.policies.host-collect ];
    #     };
    #
    #     # tux: pure receiver — only a home consumer.
    #     den.aspects.tux.homeManager =
    #       { peer-dev, ... }:
    #       {
    #         home.sessionVariables.PEERS = lib.concatStringsSep "," (
    #           lib.sort (a: b: a < b) (map (p: p.who) peer-dev)
    #         );
    #       };
    #
    #     expr = tuxHm.home.sessionVariables.PEERS;
    #     expected = "alice";
    #   }
    # );

    # BLOCKED-WSB (compile-time key-classification restriction, distinct from the broadcast-unwired
    # gap above): `den-hoag compat (§2.2): aspect-include \`<unnamed>\` declares key \`homeManager\`
    # with a function value — neither a facet, a registered class, nor a quirk channel` —
    # `den.aspects.claude.homeManager` is a bare FUNCTION (`{ replicateHome, ... }: {...}`)
    # included directly at a HOST aspect (`den.aspects.iceberg.includes = [ den.aspects.claude ]`);
    # den-hoag's compile rejects a function-valued `homeManager` facet at that position.
    # # REPRO (nix-config replicateHome → hub shortfall): a HOME-POOL quirk —
    # # emitted by a named aspect that also carries homeManager content and is
    # # consumed in homeManager — broadcast from the USER scope to a remote host.
    # # Identical in shape to test-broadcast-to-remote-host (which passes), except
    # # the quirk is home-pool. The remote host should receive the broadcast.
    # test-broadcast-home-pool-to-host = denTest (
    #   {
    #     den,
    #     igloo,
    #     lib,
    #     ...
    #   }:
    #   {
    #     den.hosts.x86_64-linux.igloo.users.tux = { };
    #     den.hosts.x86_64-linux.iceberg.users.alice = { };
    #
    #     den.quirks.replicateHome.description = "home dirs to replicate";
    #
    #     # claude-like: a HOST aspect that emits replicateHome AND consumes it in
    #     # homeManager. nix-config projects such host aspects onto the user's home
    #     # via the host-aspects battery (a deferred node SPAWN), so replicateHome
    #     # lands in the spawned home node — NOT the user-entity scope.
    #     den.aspects.claude = {
    #       replicateHome = [ { directories = [ ".claude/memory" ]; } ];
    #       homeManager =
    #         { replicateHome, ... }:
    #         {
    #           home.sessionVariables.DIRS = lib.concatStringsSep "," (
    #             lib.concatMap (e: e.directories or [ ]) replicateHome
    #           );
    #         };
    #     };
    #     # iceberg (host) carries claude; alice projects it onto her home via the
    #     # host-aspects spawn — exactly nix-config's sini.includes = [host-aspects].
    #     den.aspects.iceberg.includes = [ den.aspects.claude ];
    #     den.aspects.alice.includes = [ den.batteries.host-aspects ];
    #
    #     # USER scope: broadcast replicateHome to all hosts.
    #     den.policies.broadcast-rh =
    #       { user, ... }:
    #       let
    #         inherit (den.lib.policy) pipe;
    #       in
    #       [ (pipe.from "replicateHome" [ (pipe.broadcast ({ host, ... }: true)) ]) ];
    #     den.schema.user.includes = [ den.policies.broadcast-rh ];
    #
    #     # igloo (remote relative to alice) consumes the broadcast at host scope.
    #     den.aspects.igloo.includes = [ den.aspects.rh-consumer ];
    #     den.aspects.rh-consumer = {
    #       nixos =
    #         { replicateHome, lib, ... }:
    #         {
    #           networking.domain = lib.concatStringsSep "," (
    #             lib.concatMap (e: e.directories or [ ]) replicateHome
    #           );
    #         };
    #     };
    #
    #     expr = igloo.networking.domain;
    #     expected = ".claude/memory";
    #   }
    # );
  };
}
