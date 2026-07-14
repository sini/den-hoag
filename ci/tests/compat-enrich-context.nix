# THE RESOLUTION-DEPTH hasAspect SEAM (`den.enrichContext` — the aspect-fn twin of `den.enrichBindings`).
#
# THE RUNG. compat-has-aspect closed the DELIVERY-depth reads: a CONTENT-module formal (`nixos = { host, … }:
# {… host.hasAspect …}`, networking.nix:341) is the TERMINAL binding (`bindingsAt`), enriched by
# `den.enrichBindings`. But the corpus battery kind-includes read `host.hasAspect` from the ASPECT-FN formal
# (`agenixHostAspect = { host, … }: let hasImpermanence = host.hasAspect …; in …`, agenix.nix:31), bound at
# RESOLUTION — the enriched-context handed to a parametric aspect by `forwardExpand`. The terminal seam does
# not reach it. `den.enrichContext` (lib/default.nix) threads the SAME `mkEnrich` hook onto the resolution
# ctx (resolved-aspects.nix `ctx`), so `host.hasAspect` resolves at BOTH depths (F2: one refKey identity).
#
# THE FORCE BOUNDARY (A17, load-bearing). `enrichContext` stamps a closure reading the node's OWN
# resolved-aspects (attribute 7 — the converged fix knot, kind=circular). `forwardExpand` forces STRUCTURE
# only: the aspect-fn's top-level keys (the `${host.class}` dynamic key — a plain field) and its `includes`.
# A `host.hasAspect` in a VALUE position (agenix's `let hasImpermanence` → the `${host.class}` content value)
# rides UNFORCED through resolution; the terminal forces it AFTER convergence, reading the memoized set — no
# cycle (W-frontier / W-lazy-seam). A read in a KEY/STRUCTURE position (`includes`-gating or a top-level
# dynamic attr name) is forced DURING `forwardExpand` → the circular attribute black-holes LOUD (W-cycle).
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  inherit (denCompat) mkEnrich;

  # ── W-frontier e2e: the bridge forcing terminal (the compat-has-aspect e2e pattern). A per-host
  #    `instantiate` = `forceEval` runs the wrapped class-modules through a real `evalModules` fixpoint, so
  #    the aspect-fn's `host.hasAspect` (executed at RESOLUTION) reaches the terminal as forced content. ──
  forceEval =
    args:
    (lib.evalModules {
      modules = args.modules ++ [ { freeformType = lib.types.lazyAttrsOf lib.types.raw; } ];
      specialArgs = args.specialArgs or { };
    }).config;
  channels.probe-chan.nixosSystem = forceEval;
  corpusKindModule =
    { config, ... }:
    {
      options.channel = lib.mkOption {
        type = lib.types.enum (builtins.attrNames channels);
        default = "probe-chan";
      };
      config.instantiate = lib.mkDefault channels.${config.channel}.nixosSystem;
    };
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    mkCrossNixos = _: throw "compat-enrich-context: mkCrossNixos unused (no den.nixpkgs)";
    schema = denHoag.internal.schema;
    denLib = denHoag;
  };
  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };

  # The agenix.nix:31 shape: a bare-fn kind-include (`den.schema.host.includes`) whose ASPECT-FN formal
  # reads `host.hasAspect` in a VALUE position (the `${host.class}` content value, unforced at resolution).
  agShaped =
    { host, ... }:
    {
      name = "ag/${host.name}";
      # Task 3: the `host.hasAspect` ref carries native `.key` (== pathKey __provider); the `{__provider}`-
      # only shape was the retired refKey reconstruction input.
      ${host.class}.persistMarker =
        if
          (host.hasAspect {
            __provider = [ "imp" ];
            key = "imp";
          })
        then
          "P"
        else
          "X";
    };

  ev = lib.evalModules {
    modules = [
      flakeStub
      bridge
      {
        den.schema.host.isEntity = true;
        den.schema.host.imports = [ corpusKindModule ];
        den.schema.host.includes = [ agShaped ];
        den.aspects.imp = { };
        # host:imp auto-includes the self-named aspect `imp` (R5) → `imp` ∈ its resolved-aspects;
        # host:plain does NOT — the true/false split of the projected read at RESOLUTION depth.
        den.hosts.x86_64-linux.imp = { };
        den.hosts.x86_64-linux.plain = { };
      }
    ];
  };
  configs = ev.config.flake.nixosConfigurations;

  # ── W-lazy-seam: resolve the SAME fleet through the pure `collect` path (denCompat.mkDen). The
  #    resolved-aspects KEY spine converges WITHOUT forcing the content's `host.hasAspect` (the value
  #    position rides deferred) — deepSeq of the keyset never re-enters the circular attribute. ──
  agShapedFleet =
    (denCompat.mkDen [
      {
        config.den = {
          schema.host.includes = [ agShaped ];
          aspects.imp = { };
          hosts.x86_64-linux.imp = { };
          hosts.x86_64-linux.plain = { };
        };
      }
    ]).den;
  keysAt = id: map (n: n.key) (agShapedFleet.structural.eval.get id "resolved-aspects");
  spineOk = id: (builtins.tryEval (builtins.deepSeq (keysAt id) true)).success;

  # ── W-lazy unit: the `enrichContext` hook (= `mkEnrich`) at the new seam with a THROWING
  #    resolved-aspects thunk. Forcing the enriched ctx SPINE (deepSeq) must NOT trip it; only CALLING a
  #    hasAspect closure may. The f729c87 `lazyProbe` twin, at the resolution seam. ──
  entHost = {
    host = true;
  };
  lazyProbe = mkEnrich entHost {
    id = "host:h";
    resolvedAspects = throw "compat-enrich-context: resolvedAspects FORCED at stamp time (A17 violation)";
    bindings = {
      host = {
        id_hash = "h";
        name = "h";
      };
    };
  };

  # ── W-native: the identity default (`{ bindings, ... }: bindings`, lib/default.nix `enrichContextDecl`)
  #    is a pure passthrough that IGNORES `resolvedAspects` — so a native fleet with no `enrichContext` set
  #    has `ctx === enriched-context`, byte-identical (the 743 native fixtures are the byte-identity proof). ──
  idHook = { bindings, ... }: bindings;
  nativeIdentity = idHook {
    id = "x";
    resolvedAspects = throw "compat-enrich-context: identity default must not force resolvedAspects";
    bindings = {
      host = {
        name = "h";
      };
    };
  };
  # A native denHoag.mkDen fleet (no enrichContext ⇒ identity default) resolves a static include unchanged.
  nativeFleet =
    (denHoag.mkDen [
      { config.den.schema.host.parent = null; }
      { config.den.host.h1 = { }; }
      (
        { config, ... }:
        {
          config.den.aspects.base = { };
          config.den.include = [
            {
              at = config.den.host.h1;
              aspects = [ config.den.aspects.base ];
            }
          ];
        }
      )
    ]).den;
  nativeKeys = map (n: n.key) (nativeFleet.structural.eval.get "host:h1" "resolved-aspects");

  # ══════════════════════════════════════════════════════════════════════════════════════════════════
  # W-cycle (the black-hole witness) — a DOCUMENTED COUNTER-EXAMPLE, deliberately NOT a test.
  #
  #   agCycle = { host, ... }: {
  #     name = "cyc/${host.name}";
  #     includes = if (host.hasAspect { __provider = [ "imp" ]; }) then [ ] else [ ];  # KEY/STRUCTURE position
  #   };
  #
  # `forwardExpand` reads `concrete.includes` to recurse, forcing the `if` CONDITION → forcing the projected
  # `host.hasAspect` → forcing the node's OWN resolved-aspects (`self.get id "resolved-aspects"`) WHILE it is
  # being computed → the circular attribute black-holes. Empirically (verified against this build) it aborts
  # with `error: stack overflow; max-call-depth exceeded` at has-aspect.nix:87 — and `builtins.tryEval` does
  # NOT catch it: the abort propagates PAST tryEval to the evaluator top. So it CANNOT be pinned as a passing
  # nix-unit assertion (a `(tryEval …).success == false` witness would itself abort). The LOUD failure IS the
  # contract (the includes-position ban the v1 schema.nix:59-77 laziness note names — "the lookup is pure and
  # forced lazily … don't decide includes from it"): a KEY/STRUCTURE-position projected read self-announces
  # by aborting, never a silent wrong resolution. A top-level dynamic attr name
  # (`${if host.hasAspect … then "nixos" else "darwin"} = …`) is the sibling shape (forced when `concrete`
  # goes to WHNF) with the same black-hole. NOT-A-TEST.
  # ══════════════════════════════════════════════════════════════════════════════════════════════════
in
{
  flake.tests.compat-enrich-context = {
    # ── W-frontier: the agenix.nix:31 shape end-to-end. host:imp (aspect present) carries the TRUE branch
    #    at the terminal; host:plain (absent) the FALSE branch — the resolution-depth read resolves. ──
    test-w-frontier-resolution-depth = {
      expr = {
        impTrueBranch = configs.imp.persistMarker;
        plainFalseBranch = configs.plain.persistMarker;
      };
      expected = {
        impTrueBranch = "P";
        plainFalseBranch = "X";
      };
    };

    # ── W-lazy-seam: the resolved-aspects KEY spine converges without forcing the deferred hasAspect read. ──
    test-w-lazy-seam-spine = {
      expr = {
        imp = spineOk "host:imp";
        plain = spineOk "host:plain";
      };
      expected = {
        imp = true;
        plain = true;
      };
    };

    # ── W-lazy: the enrichContext hook keeps resolvedAspects UNFORCED at stamp (deepSeq the ctx spine ⇒
    #    the throwing thunk survives); CALLING hasAspect DOES force it (the throw fires). ──
    test-w-lazy-throwing-thunk = {
      expr = {
        spineSafe = (builtins.tryEval (builtins.deepSeq lazyProbe true)).success;
        callForces =
          (builtins.tryEval (
            lazyProbe.host.hasAspect {
              __provider = [ "x" ];
              key = "x"; # native `.key` (Task 3); == pathKey __provider.
            }
          )).success;
      };
      expected = {
        spineSafe = true; # forcing the enriched-ctx spine never forces resolved-aspects
        callForces = false; # calling the hasAspect closure DOES (the throw surfaces)
      };
    };

    # ── W-native: the identity default is a pure passthrough that ignores resolvedAspects (ctx ===
    #    enriched-context on the native path), and a native fleet resolves its static include unchanged. ──
    test-w-native-identity-default = {
      expr = {
        identity = nativeIdentity;
        nativeResolves = builtins.elem "base" nativeKeys;
      };
      expected = {
        identity = {
          host = {
            name = "h";
          };
        };
        nativeResolves = true;
      };
    };
  };
}
