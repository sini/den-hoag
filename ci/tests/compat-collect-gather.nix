# #69 (slice U9.2, catalog v33) — the v1 `pipe.collect` / `pipe.collectAll` gather twins
# (lib/compat/collect-gather.nix), composed with the expose ascent into `den.channelGather`. v1
# provenance: findMatchingSiblings/findMatchingAll (pin 11866c16 assemble-pipes.nix:318-382, F2 EXACT —
# incl. the predEntityArgs/extraEntityKinds own-kind gating), collectTagged (:437-450, raw ++ exposed),
# the run arms (:455-478), F4 augment (bound = local ++ gathered), source-node-id lexicographic order,
# no dedup.
#
# Witnesses (the v33 set):
#   (1) SIBLING gather with the entity-kind gate — hosts are mutual siblings (parentless roots): a
#       `{ host, … }: true` collect at h1 binds own + h2's contributions (own-first, then lex);
#       the NON-VACUOUS negative — a (user,host) CELL also emits on the channel and its ctx CARRIES
#       `host` (hasRequired passes), but its OWN kind is `user` ⇒ extraEntityKinds rejects it
#       (v1 :341-347) — the cell's value reaches NO host binding via collectAll either.
#   (2) collect vs collectAll — cells of DIFFERENT hosts are not siblings: a `{ user, … }: true`
#       collect at a cell gathers its same-host sibling cell only; collectAll additionally gathers the
#       other host's cell (fleet-wide).
#   (3) no-mark channels unaffected — a channel with no collect mark binds own emissions alone.
#   (4) THE F6 LOUD CEILING — a config-dependent (deferred) emission on a collected channel aborts
#       NAMED at the consumer (errors.collectedConfigThunk), never a silent wrong value.
{ denCompat, ... }:
let
  P = denCompat.pipe;

  # ── fixture A/B: two hosts (mutual siblings), h1 with cells tuxA+tuxB, h2 with cell tuxC.
  #    Channels: `mesh` (host-emitted, host-collected), `umesh` (cell-emitted, cell-collected),
  #    `plain` (host-emitted, NO marks). All emissions pipeline-parametric ⇒ resolved at the emitter. ──
  fleet = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.h1 = {
        class = "nixos";
        users.tuxA = { };
        users.tuxB = { };
      };
      den.hosts.x86_64-linux.h2 = {
        class = "nixos";
        users.tuxC = { };
      };
      den.schema.user.parent = "host";
      den.quirks.mesh = { };
      den.quirks.umesh = { };
      den.quirks.plain = { };
      # host-kind emissions (parametric — resolved at each host; U9.1).
      den.aspects.hemit =
        { host, ... }:
        {
          nixos.tag = "nixos-${host.name}";
          mesh = [ "mesh-${host.name}" ];
          plain = [ "plain-${host.name}" ];
        };
      den.schema.host.includes = [ "hemit" ];
      # cell emissions: `mesh` (the entity-gate negative — a cell's ctx carries `host`) + `umesh`.
      den.aspects.cemit =
        { user, ... }:
        {
          home-manager.tag = "hm-${user.name}";
          mesh = [ "mesh-cell-${user.name}" ];
          umesh = [ "umesh-${user.name}" ];
        };
      den.schema.user.includes = [ "cemit" ];
      # the corpus collect shapes (policies/pipes.nix): host-collect (siblings) + host-collectAll on
      # `mesh`… split across the two hosts so both arms are exercised on ONE fleet:
      #   h-collect fires at every host-bearing node ({ host, … }) — the mark lands at hosts AND cells
      #   (cells gather nothing on `mesh`: their siblings are cells, kind-gated out).
      den.policies.collect-mesh =
        { host, ... }:
        [
          (P.from "mesh" [ (P.collect ({ host, ... }: true)) ])
        ];
      # cell-collect (same-host siblings) + cell-collectAll (fleet) on `umesh`.
      den.policies.collect-umesh =
        { user, ... }:
        [
          (P.from "umesh" [ (P.collect ({ user, ... }: true)) ])
        ];
    }
  ];

  # a second fleet where the cell pipe is collectALL — the fleet-wide arm of witness (2).
  fleetAll = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.h1 = {
        class = "nixos";
        users.tuxA = { };
        users.tuxB = { };
      };
      den.hosts.x86_64-linux.h2 = {
        class = "nixos";
        users.tuxC = { };
      };
      den.schema.user.parent = "host";
      den.quirks.mesh = { };
      den.quirks.umesh = { };
      den.aspects.hemit =
        { host, ... }:
        {
          nixos.tag = "nixos-${host.name}";
        };
      den.schema.host.includes = [ "hemit" ];
      den.aspects.cemit =
        { user, ... }:
        {
          home-manager.tag = "hm-${user.name}";
          mesh = [ "mesh-cell-${user.name}" ];
          umesh = [ "umesh-${user.name}" ];
        };
      den.schema.user.includes = [ "cemit" ];
      den.policies.collect-umesh-all =
        { user, ... }:
        [
          (P.from "umesh" [ (P.collectAll ({ user, ... }: true)) ])
        ];
      # host-side collectAll on `mesh` — the entity-gate NEGATIVE: only CELLS emit mesh here, and the
      # `{ host, … }: true` predicate must reject every one of them (own kind `user`), so the host's
      # mesh binding stays EMPTY even fleet-wide.
      den.policies.collect-mesh-all =
        { host, ... }:
        [
          (P.from "mesh" [ (P.collectAll ({ host, ... }: true)) ])
        ];
    }
  ];

  # ── fixture E: the F6 ceiling — every host's `mesh` emission demands `config` (a deferred
  #    config-thunk; attached kind-wide, so each host's LOCAL binding carries its own thunk — the
  #    local deferral path, untouched); each host also COLLECTS the channel, and gathering the
  #    SIBLING's thunk aborts NAMED. ──
  f6 = denCompat.mkDen [
    {
      den.hosts.x86_64-linux.h1.class = "nixos";
      den.hosts.x86_64-linux.h2.class = "nixos";
      den.quirks.mesh = { };
      den.aspects.hemit.nixos.tag = "nixos-h";
      den.aspects.femit = {
        mesh = { config, ... }: [ "config-dependent" ];
      };
      den.schema.host.includes = [
        "hemit"
        "femit"
      ];
      den.policies.collect-mesh =
        { host, ... }:
        [
          (P.from "mesh" [ (P.collect ({ host, ... }: true)) ])
        ];
    }
  ];

  bindingsOf =
    fleet: cls: id:
    fleet.den.output.systems.${cls}.${id}.bindings;
  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;
in
{
  flake.tests.compat-collect-gather = {
    # (1) sibling gather, own-first ++ source-lex — h1 binds its own mesh emission then h2's; and the
    #     symmetric read at h2 (own first, h1's gathered after — F4, not a global order).
    test-collect-sibling-gather-own-first = {
      expr = {
        h1 = (bindingsOf fleet "nixos" "host:h1").mesh;
        h2 = (bindingsOf fleet "nixos" "host:h2").mesh;
      };
      expected = {
        h1 = [
          [ "mesh-h1" ]
          [ "mesh-h2" ]
        ];
        h2 = [
          [ "mesh-h2" ]
          [ "mesh-h1" ]
        ];
      };
    };
    # …the entity-kind gate (non-vacuous): the cells DO emit mesh (their own bindings prove the data
    #    exists) yet NO cell value reaches a host's mesh binding (own kind `user` ⇒ extraEntityKinds).
    test-collect-entity-gate-cells-emit-but-rejected = {
      expr = {
        cellEmits = (bindingsOf fleet "home-manager" "user:tuxA@host:h1").mesh;
        h1HasNoCellValue = builtins.any (
          v: builtins.elem "mesh-cell-tuxA" (if builtins.isList v then v else [ ])
        ) ((bindingsOf fleet "nixos" "host:h1").mesh);
      };
      expected = {
        cellEmits = [ [ "mesh-cell-tuxA" ] ];
        h1HasNoCellValue = false;
      };
    };
    # …and fleet-wide (collectAll) the gate STILL rejects them: only cells emit mesh in fleetAll, so
    #    the host's mesh binding is empty — the gate, not sibling-scoping, is what excludes them.
    test-collectall-entity-gate-rejects-cells = {
      expr = (bindingsOf fleetAll "nixos" "host:h1").mesh;
      expected = [ ];
    };

    # (2) collect (same-parent siblings) vs collectAll (fleet): tuxA's sibling gather sees tuxB only;
    #     the collectAll fleet sees tuxB AND the other host's tuxC (source-lex within the gather).
    test-collect-cell-siblings-only = {
      expr = (bindingsOf fleet "home-manager" "user:tuxA@host:h1").umesh;
      expected = [
        [ "umesh-tuxA" ]
        [ "umesh-tuxB" ]
      ];
    };
    test-collectall-cell-fleet-wide = {
      expr = (bindingsOf fleetAll "home-manager" "user:tuxA@host:h1").umesh;
      expected = [
        [ "umesh-tuxA" ]
        [ "umesh-tuxB" ]
        [ "umesh-tuxC" ]
      ];
    };

    # (3) a channel with NO collect mark binds own emissions alone — the gather adds no key/values.
    test-no-mark-channel-unaffected = {
      expr = (bindingsOf fleet "nixos" "host:h1").plain;
      expected = [ [ "plain-h1" ] ];
    };

    # (4) the F6 LOUD ceiling: a config-dependent (deferred) emission on a collected channel aborts at
    #     the consumer's gather — never a silent wrong value. Companion: the EMITTER's own binding
    #     still carries its thunk (local deferral untouched; only the CROSS-scope gather refuses).
    test-f6-collected-config-thunk-aborts = {
      expr = ok (bindingsOf f6 "nixos" "host:h1").mesh;
      expected = false;
    };
  };
}
