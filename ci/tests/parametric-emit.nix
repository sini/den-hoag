# U9 slice 1 — pipeline-parametric channel-emit resolution at the EMITTING node (§27 eager dual;
# collections.nix attribute 10 `resolveParametric`, v1 twin assemble-pipes.nix:52-90). A channel emit
# that is a FUNCTION over the node's binding surface (`{ host, ... }: …`, NOT config/osConfig) resolves
# AT THE EMITTING NODE against its enriched-context, so its consumers see DATA, not a raw lambda (the
# corpus frontier: a collected `k3s-nodes = { environment, host, ... }: {…}` reaching a module unresolved).
#
# Over one env/host fleet where the host produces `nixos`, six channels witness the law:
#   single   — a parametric attrset emit resolves to the record (not a fn) at the emitting host.
#   many     — a parametric LIST emit SPLITS into N flat contributions (decision §5), emit order kept.
#   defd     — a defaulted arg (`extra ? 3`) resolves with the default honored.
#   far      — a required arg absent from the node's context DROPS (gen-aspects wrapGatedFn inert miss).
#   cfg      — a config-thunk emit stays DEFERRED (byte-identical path — the deferred marker survives).
#   libch    — a `lib`-demanding emit DROPS with no consumer lib, RESOLVES when `den.nixpkgs` is supplied.
{
  denHoag,
  nixpkgs,
  ...
}:
let
  base = [
    {
      config.den.schema = {
        env.parent = null;
        host.parent = "env";
        user.parent = "host";
      };
    }
    {
      config.den = {
        env.prod = { };
        host.axon = { };
      };
    }
    (
      { config, ... }:
      {
        config.den.membership = [
          {
            coords = {
              env = config.den.env.prod;
              host = config.den.host.axon;
            };
          }
        ];
      }
    )
    { config.den.contentClass.host = "nixos"; }
    {
      config.den.quirks = {
        single = { };
        many = { };
        defd = { };
        far = { };
        cfg = { };
        libch = { };
        empt = { };
      };
    }
    (
      { config, ... }:
      {
        config.den.aspects.emit = {
          # a trivial nixos class body so the host carries content ⇒ appears in `systems.nixos` (the
          # terminal-binding witness reads `output.systems.nixos.<id>.bindings`).
          nixos.marker = "axon";
          # a parametric attrset emit — resolves to the record at the host.
          single = { host, ... }: { name = host.name; };
          # a parametric LIST emit — SPLITS into two contributions, emit order preserved.
          many =
            { host, ... }:
            [
              { n = host.name; }
              { n = "static"; }
            ];
          # a defaulted arg — resolves with the default honored (`extra` never in ctx).
          defd =
            {
              host,
              extra ? 3,
              ...
            }:
            {
              e = extra;
              n = host.name;
            };
          # a required arg the node's context CANNOT satisfy — the gate misses, so it drops inert (no emission).
          far = { nonexistent, ... }: { a = 1; };
          # a config-thunk — stays deferred (config-demanding, resolve-at-producing-scope §27).
          cfg = { config, ... }: [ config.foo ];
          # a `lib`-demanding parametric emit — the corpus hub.nix:31 shape.
          libch = { host, lib, ... }: lib.optionals true [ { n = host.name; } ];
          # a SATISFIED emit resolving to an empty attrset — the emit-nothing `{ }` that FIRES (distinct
          # from a gate miss). Guards the sentinel: it must stay ONE contribution (`[ { } ]`), not drop.
          empt = { host, ... }: { };
        };
        config.den.include = [
          {
            at = config.den.host.axon;
            aspects = [ config.den.aspects.emit ];
          }
        ];
      }
    )
  ];

  # pure arm: no `den.nixpkgs` ⇒ consumerLib = null (the nixpkgs-free path).
  denPure = (denHoag.mkDen base).den;
  # lib arm: `den.nixpkgs` supplied ⇒ consumerLib = nixpkgs.lib (the injection path).
  denLib = (denHoag.mkDen (base ++ [ { config.den.nixpkgs = nixpkgs; } ])).den;

  axonId = "host:axon";
  # the resolved VALUES of a channel's local contributions at the host (attribute 10).
  valsOf =
    den: ch: map (c: c.value) ((den.structural.eval.get axonId "local-collection-data").${ch} or [ ]);
  # the deferred FLAGS (read without forcing the poison value — the deferred marker itself).
  defersOf =
    den: ch:
    map (c: c.deferred) ((den.structural.eval.get axonId "local-collection-data").${ch} or [ ]);
  # the TERMINAL binding for a channel (the collect terminal's `bindings`, what a class module is handed).
  bindOf = den: ch: (den.output.systems.nixos.${axonId}.bindings).${ch};
in
{
  flake.tests.parametric-emit = {
    # ── single: parametric attrset resolves at the emitting node ──
    test-single-resolves-to-record = {
      expr = valsOf denPure "single";
      expected = [ { name = "axon"; } ];
    };
    # the RESOLVED value is what the terminal binding carries (not a lambda) — the frontier fix.
    test-single-binding-is-data = {
      expr = bindOf denPure "single";
      expected = [ { name = "axon"; } ];
    };

    # ── many: a parametric LIST emit SPLITS into N flat contributions (§5) ──
    test-many-splits-flat = {
      expr = valsOf denPure "many";
      expected = [
        { n = "axon"; }
        { n = "static"; }
      ];
    };
    test-many-split-count = {
      expr = builtins.length (valsOf denPure "many");
      expected = 2;
    };

    # ── defd: a defaulted arg resolves with its default honored ──
    test-default-arg-honored = {
      expr = valsOf denPure "defd";
      expected = [
        {
          e = 3;
          n = "axon";
        }
      ];
    };

    # ── far: a required arg the ctx cannot satisfy DROPS (gen-aspects wrapGatedFn inert miss) ──
    # the gate is unsatisfied ⇒ the emit contributes nothing (no ride-raw ceiling — the miss is silent-inert).
    test-missing-arg-drops = {
      expr = valsOf denPure "far";
      expected = [ ];
    };

    # ── empt: a SATISFIED emit resolving to `{ }` stays ONE contribution ([{}]) — the sentinel guard ──
    # onResult wraps the satisfied `{ }` as `[ { } ]` (record preserved); ONLY a gate miss (raw `{ }`, no
    # onResult) drops — so an emit-nothing `{ }` that FIRES is never conflated with a miss.
    test-empty-attrset-emit-preserved = {
      expr = valsOf denPure "empt";
      expected = [ { } ];
    };

    # ── cfg: a config-thunk stays DEFERRED (byte-identical path — the marker survives) ──
    test-config-thunk-still-deferred = {
      expr = defersOf denPure "cfg";
      expected = [ true ];
    };

    # ── libch: the `lib`-demand gate (pure) vs injection (den.nixpkgs) ──
    # no consumer lib ⇒ `lib` is an unsatisfied required arg ⇒ the gate drops the emit (gen-native inert miss).
    test-lib-demand-drops-when-pure = {
      expr = valsOf denPure "libch";
      expected = [ ];
    };
    # `den.nixpkgs` supplied ⇒ `lib` injected ⇒ resolves (v1 parity: v1 always injects den's lib).
    test-lib-demand-resolves-with-nixpkgs = {
      expr = valsOf denLib "libch";
      expected = [ { n = "axon"; } ];
    };
  };
}
