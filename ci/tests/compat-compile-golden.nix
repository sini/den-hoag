# compat-compile-golden (C2, partial) — the pure-desugar snapshot. `denCompat.compile` is a pure
# function from v1 declarations to den-hoag concern DECLARATIONS (Law C2): declaration-in,
# declaration-out, forcing no parametric body and reading no scope graph. This suite pins the
# entity / aspect / policy / class rows for one small v1 snippet — one host, one aspect with a
# parametric class key + a quirk key, one `policy.include`, one class — against a snapshot derived
# from first principles (id_hashes recomputed here, not copied from a run), and proves purity by
# poisoning a parametric body with `throw` and showing the structural projection still computes.
{ denCompat, denHoagSrc, ... }:
let
  # The parametric class body is a THROW: if `compile` (or any structural read below) forced it, the
  # suite would abort. It never does — the aspect row is near-identity passthrough, values stay thunks.
  poison = { host, ... }: throw "compile must not force a parametric aspect body";

  fixture = {
    hosts.x86_64-linux.axon = {
      class = "nixos";
    };
    aspects.system = {
      nixos = poison; # class key, parametric (den-hoag class `nixos`)
      ssh-peers = [ "axon-ip" ]; # quirk key
    };
    # a policy whose body includes the `system` aspect (v1 `policy.include`).
    policies.attachSystem = _ctx: [
      {
        __policyEffect = "include";
        value = {
          name = "system";
        };
      }
    ];
    classes.myclass = { };
  };

  compiled = denCompat.compile fixture;

  # Expected identities, recomputed from the frozen conventions (gen-schema entry / den-hoag aspect).
  hostAxonHash = builtins.hashString "sha256" "host|name=axon";
  aspectSystemHash = builtins.hashString "sha256" "den-aspect:system";

  # Run the compiled policy body to observe the translated declaration (the include → edge row). The
  # body is unconditional, so any ctx yields the same edge.
  attachDecls = compiled.policies.attachSystem.fn { };
  edgeDecl = builtins.head attachDecls;

  # The rest of the C1 policy vocabulary (include is above): exclude → drop, resolve → spawn, a
  # `for`-wrapped policy (v1 emits an `__isPolicy` record whose `fn` gates on ctx) → its inner edge,
  # and a `when`-over-inline-aspect (v1 emits a conditional-aspect record) → a den-hoag conditional
  # ASPECT, not a policy (its guard reads the path set, A9.1 — v1 lifts it to avoid the resolved cycle).
  vocab = denCompat.compile {
    aspects.a = { };
    aspects.b = { };
    policies.detachA = _ctx: [
      {
        __policyEffect = "exclude";
        value = {
          name = "a";
        };
      }
    ];
    policies.fanout = _ctx: [
      {
        __policyEffect = "resolve";
        __shared = false;
        value = { };
        includes = [ ];
      }
    ];
    policies.forB = {
      __isPolicy = true;
      name = "forB";
      fn = _ctx: [
        {
          __policyEffect = "include";
          value = {
            name = "b";
          };
        }
      ];
    };
    policies.whenGuard = {
      name = "<when>";
      meta.guard = { hasAspect, ... }: true;
      meta.aspects = [ { name = "a"; } ];
      includes = [ ];
    };
  };
  vExclude = builtins.head (vocab.policies.detachA.fn { });
  vResolve = builtins.head (vocab.policies.fanout.fn { });
  vFor = builtins.head (vocab.policies.forB.fn { });

  # The NORMAL v1 multi-host case: the same user (`bob`) on TWO hosts. The user REGISTRY must dedup to
  # ONE `bob` entry (den-hoag entities are field-less, so the merge is trivial and drops nothing), while
  # MEMBERSHIP must carry TWO cells — one per host — each binding the right host entry. A last-wins
  # re-key would silently drop a cell here.
  multiHost = denCompat.compile {
    hosts.x86_64-linux.host1 = {
      class = "nixos";
      users.bob = { };
    };
    hosts.x86_64-linux.host2 = {
      class = "nixos";
      users.bob = { };
    };
  };
  multiHostCells = multiHost.entities.membership;
  multiHostHostNames = builtins.sort (a: b: a < b) (map (m: m.coords.host.name) multiHostCells);
  bobHash = builtins.hashString "sha256" "user|name=bob";

  # The full C1 pipeline: v1 module → evalV1 → compile → mkFleetModule → denHoag.mkDen. Proves the
  # compiled declarations actually feed the assembly (ingestion round-trips the v1 fixture), not just
  # that `compile` returns a well-shaped attrset. A host with a `host.users` member exercises the
  # membership half.
  roundTrip = denCompat.mkDen [
    {
      config.den.hosts.x86_64-linux.axon = {
        class = "nixos";
        users.alice = { };
      };
      config.den.aspects.system.ssh-peers = [ "axon-ip" ];
      config.den.classes.myclass = { };
    }
  ];

  # ── §2.4 pipe stage vocabulary (Task 3) ──────────────────────────────────────────────────────────
  # The C1 witness fixtures live in the parity harness (shared with the future P-suites); read through
  # the den-hoag flake source (`path:..`), the same store-path route the zero-machinery source scan uses.
  pipeFx = import "${denHoagSrc}/parity/fixtures/pipe-stages.nix" { };

  # Walk a gen-pipe derived-channel DAG outermost→base, collecting each op left-to-right (the base channel
  # ref has no `__derive`, so the walk stops there). Reads only `.op` / `.__derive.inputs` — the structural
  # projection, forcing no stage closure (so a deferred value on the channel is never touched here).
  opChain =
    d: if (d.__derived or false) then opChain (builtins.head d.__derive.inputs) ++ [ d.op ] else [ ];
  baseOf = d: if (d.__derived or false) then baseOf (builtins.head d.__derive.inputs) else d;

  # Each pipe fixture's `pipe.from` policy body is unconditional, so any ctx yields the pipeOp declaration.
  derivePipeOp = builtins.head ((denCompat.compile pipeFx.derivePipe).policies.shapeMetric.fn { });
  deliverToOp = builtins.head ((denCompat.compile pipeFx.deliverToPipe).policies.routePorts.fn { });
  deliverAsOp = builtins.head ((denCompat.compile pipeFx.deliverAsPipe).policies.renameRaw.fn { });
  sitePipeOp = builtins.head ((denCompat.compile pipeFx.sitePipe).policies.gatherPeers.fn { });
  siteMark = k: builtins.head (builtins.filter (m: m.__pipeMark == k) sitePipeOp.marks);

  # for (whole-list) vs transform (per-element): both are the `map` node; only `for`'s inert
  # `__derive.wholeList` marker keeps the distinction the run wiring (task #44) needs. Ordered
  # transform-then-for, so `.derived` is the `for` node and its single input is the `transform` node.
  fvtOp = builtins.head ((denCompat.compile pipeFx.forVsTransform).policies.shapeStream.fn { });
  forDerived = fvtOp.derived;
  transformDerived = builtins.head fvtOp.derived.__derive.inputs;

  # `den.quirks.<name>` → channel registration + the class/quirk key-overlap check.
  channelsCompiled = (denCompat.compile pipeFx.channelsFixture).channels;

  # Deferred (config-thunk) discipline: the raw quirk value + the pipe compiled over it.
  deferredCompiled = denCompat.compile pipeFx.deferredFixture;
  deferredMarks = deferredCompiled.aspects.svc.marks;
  deferredPipeOp = builtins.head (deferredCompiled.policies.shapeMarks.fn { });
in
{
  flake.tests.compat-compile-golden = {
    # ── entities row ────────────────────────────────────────────────────────────────────────────
    # den.hosts.<sys>.<name> flattened to a host registry; built-in host/user kinds present.
    test-schema-kinds = {
      expr = builtins.attrNames compiled.entities.schema;
      expected = [
        "host"
        "user"
      ];
    };
    test-host-parent-root = {
      expr = compiled.entities.schema.host.parent;
      expected = null;
    };
    test-user-parent-host = {
      expr = compiled.entities.schema.user.parent;
      expected = "host";
    };
    # The flat host entry carries id_hash (system demoted to a field, name preserved).
    test-host-entry-id = {
      expr = compiled.entities.registries.host.axon.id_hash;
      expected = hostAxonHash;
    };
    test-host-entry-name = {
      expr = compiled.entities.registries.host.axon.name;
      expected = "axon";
    };
    # The instance mkDen rebuilds from keeps the demoted `system` field.
    test-host-instance-system = {
      expr = compiled.entities.instances.host.axon.system;
      expected = "x86_64-linux";
    };

    # ── multi-host user: one distinct user entry, one membership cell per host ───────────────────
    test-multihost-one-user = {
      expr = builtins.attrNames multiHost.entities.registries.user;
      expected = [ "bob" ];
    };
    test-multihost-two-cells = {
      expr = builtins.length multiHostCells;
      expected = 2;
    };
    test-multihost-both-hosts = {
      expr = multiHostHostNames;
      expected = [
        "host1"
        "host2"
      ];
    };
    # both cells bind the SAME (single) bob entry — the distinct hosts are the only thing that varies.
    test-multihost-user-coherent = {
      expr = builtins.all (m: m.coords.user.id_hash == bobHash) multiHostCells;
      expected = true;
    };

    # ── aspect row (near-identity, class key + quirk key pass through) ───────────────────────────
    test-aspect-keys = {
      expr = builtins.attrNames compiled.aspects.system;
      expected = [
        "nixos"
        "ssh-peers"
      ];
    };
    # the quirk key rides raw (a plain list), not mangled into a nested aspect.
    test-aspect-quirk-value = {
      expr = compiled.aspects.system.ssh-peers;
      expected = [ "axon-ip" ];
    };

    # ── policy row (policy.include → declare.edge, entry-valued) ─────────────────────────────────
    test-policy-name = {
      expr = builtins.attrNames compiled.policies;
      expected = [ "attachSystem" ];
    };
    test-include-becomes-edge = {
      expr = edgeDecl.__action;
      expected = "edge";
    };
    # the edge's aspect is an ENTRY (id_hash), never a name string (C6).
    test-edge-aspect-entry = {
      expr = edgeDecl.aspect.id_hash;
      expected = aspectSystemHash;
    };
    test-edge-aspect-not-string = {
      expr = builtins.isString edgeDecl.aspect;
      expected = false;
    };

    # ── class row ───────────────────────────────────────────────────────────────────────────────
    test-class-name = {
      expr = builtins.attrNames compiled.classes;
      expected = [ "myclass" ];
    };
    # channels register `den.quirks.<name>` (Task 3); this fixture declares no quirk, so it is empty.
    test-channels-empty = {
      expr = compiled.channels;
      expected = { };
    };

    # ── policy vocabulary (exclude/resolve/for/when) ─────────────────────────────────────────────
    test-exclude-becomes-drop = {
      expr = vExclude.__action;
      expected = "drop";
    };
    test-resolve-becomes-spawn = {
      expr = vResolve.__action;
      expected = "spawn";
    };
    test-for-wrapped-inner-edge = {
      expr = vFor.__action;
      expected = "edge";
    };
    # a `when`-over-inline-aspect lifts to a conditional ASPECT (guard + gated includes), not a policy.
    test-when-lifts-to-aspect = {
      expr = (vocab.aspects ? whenGuard) && (vocab.aspects.whenGuard.meta ? guard);
      expected = true;
    };
    test-when-not-a-policy = {
      expr = vocab.policies ? whenGuard;
      expected = false;
    };

    # ── round-trip: the compiled declarations feed denHoag.mkDen ─────────────────────────────────
    test-roundtrip-host-registry = {
      expr = builtins.attrNames roundTrip.den.registries.host;
      expected = [ "axon" ];
    };
    test-roundtrip-user-registry = {
      expr = builtins.attrNames roundTrip.den.registries.user;
      expected = [ "alice" ];
    };
    test-roundtrip-aspect-registry = {
      expr = builtins.attrNames roundTrip.den.aspects;
      expected = [ "system" ];
    };
    # the boundary entry's id_hash equals the entry mkDen independently stamps (identity coherence).
    test-roundtrip-id-coherent = {
      expr = roundTrip.den.registries.host.axon.id_hash == hostAxonHash;
      expected = true;
    };

    # ── §2.4 pipe stages: deriving vocab → left-to-right op DAG on the named channel ─────────────
    test-pipe-op-kind = {
      expr = derivePipeOp.__action;
      expected = "pipeOp";
    };
    test-pipe-channel = {
      expr = derivePipeOp.channel;
      expected = "metric";
    };
    # filter→filter, transform→map, fold→fold (assoc-only B5), for→map — folded left-to-right, order pinned.
    test-pipe-derive-chain = {
      expr = opChain derivePipeOp.derived;
      expected = [
        "filter"
        "map"
        "fold"
        "map"
      ];
    };
    # the DAG roots at the named channel (the base ref's id is the quirk key).
    test-pipe-derive-base = {
      expr = (baseOf derivePipeOp.derived).id;
      expected = "metric";
    };

    # for vs transform: SAME `map` node, distinguished only by `for`'s inert `__derive.wholeList` marker
    # (v1 `for` = whole-list assemble-pipes.nix:289-290; gen-pipe `map` = per-element evaluate.nix:247).
    # Without the marker the two records are byte-identical and the whole-list run semantics are lost.
    test-for-transform-both-map = {
      expr = [
        forDerived.op
        transformDerived.op
      ];
      expected = [
        "map"
        "map"
      ];
    };
    test-for-wholelist-marked = {
      expr = forDerived.__derive.wholeList;
      expected = true;
    };
    test-transform-not-wholelist = {
      expr = transformDerived.__derive ? wholeList;
      expected = false;
    };

    # ── §2.4 delivery stages: to → route selecting aspects; as → route to a target pipe ──────────
    test-pipe-to-route = {
      expr = map (r: r.op) deliverToOp.routes;
      expected = [ "route" ];
    };
    test-pipe-to-route-from = {
      expr = (builtins.head deliverToOp.routes).from;
      expected = "ports";
    };
    test-pipe-as-route = {
      expr = map (r: r.op) deliverAsOp.routes;
      expected = [ "route" ];
    };
    test-pipe-as-route-to = {
      expr = (builtins.head deliverAsOp.routes).to;
      expected = "shaped";
    };

    # ── §2.4 site stages: append/expose/broadcast/collect/collectAll/withProvenance → inert markers ─
    test-pipe-site-marks = {
      expr = map (m: m.__pipeMark) sitePipeOp.marks;
      expected = [
        "append"
        "expose"
        "broadcast"
        "collect"
        "collectAll"
        "withProvenance"
      ];
    };
    # collectAll reads raw + exposed (PR #623), collect only the local gather.
    test-pipe-collectall-exposed = {
      expr = (siteMark "collectAll").exposed;
      expected = true;
    };
    test-pipe-collect-not-exposed = {
      expr = (siteMark "collect").exposed;
      expected = false;
    };

    # ── §2.4 `den.quirks.<name>` → channel registration + key-overlap check ──────────────────────
    test-quirk-channel-keys = {
      expr = builtins.attrNames channelsCompiled.backends;
      expected = [
        "adapters"
        "channel"
        "ops"
      ];
    };
    # a bare marker quirk → an empty (default ordered-list) channel; the v1 `description` is dropped.
    test-quirk-channel-default = {
      expr = channelsCompiled.backends.channel;
      expected = { };
    };
    # a quirk carrying gen-pipe channel options passes them through (non-channel keys still dropped).
    test-quirk-channel-options = {
      expr = channelsCompiled.tuned.channel;
      expected = {
        merge = "ordered-list";
        dedup = "by-key";
      };
    };
    test-quirk-channel-empty-ops = {
      expr = channelsCompiled.backends.ops == [ ] && channelsCompiled.backends.adapters == [ ];
      expected = true;
    };
    # a name declared as both a class and a quirk channel aborts (classes ∪ channels must stay disjoint).
    test-quirk-class-overlap-aborts = {
      expr =
        (builtins.tryEval (builtins.deepSeq (denCompat.compile pipeFx.overlapFixture).channels true))
        .success;
      expected = false;
    };

    # ── deferred-value discipline (parity-watch items 5, 6) ──────────────────────────────────────
    # item 5: the config-demanding channel value rides RAW — a bare function whose args carry the
    # producing-class config handle, so gen-bind keeps the consuming module's config arg unbound at the
    # terminal (a fully-bound consumer would skip thunk resolution, wrap.nix `allMatched`).
    test-deferred-value-raw = {
      expr = builtins.isFunction deferredMarks;
      expected = true;
    };
    test-deferred-config-handle = {
      expr = (builtins.functionArgs deferredMarks) ? config;
      expected = true;
    };
    # item 6: the pipe over the deferred value emits only filter/map (no value-demanding fold/scan), and
    # NOTHING forces the poison body — deepSeq of the structural projection (op chain + channel + arg keys)
    # completes. Had `compile` (or the compiled pipe) forced the throwing thunk, this would abort; that it
    # does not proves the deferred marker crosses the compiled v1 pipe intact to the terminal.
    test-deferred-derive-chain = {
      expr = opChain deferredPipeOp.derived;
      expected = [
        "filter"
        "map"
      ];
    };
    test-deferred-no-force = {
      expr = builtins.deepSeq {
        ops = opChain deferredPipeOp.derived;
        chan = deferredPipeOp.channel;
        argKeys = builtins.attrNames (builtins.functionArgs deferredMarks);
      } true;
      expected = true;
    };

    # ── purity: the structural projection forces no function, reads no scope ─────────────────────
    # deepSeq a function-free projection of the output; if `compile` had forced the poisoned body or
    # touched a scope graph, this would throw. attrNames + scalars only — no aspect body in reach.
    test-purity-no-force = {
      expr = builtins.deepSeq {
        kinds = builtins.attrNames compiled.entities.schema;
        hostId = compiled.entities.registries.host.axon.id_hash;
        aspectKeys = builtins.attrNames compiled.aspects.system;
        policyNames = builtins.attrNames compiled.policies;
        classNames = builtins.attrNames compiled.classes;
        edge = edgeDecl.__action;
      } true;
      expected = true;
    };
  };
}
