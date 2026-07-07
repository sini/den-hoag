# compat-deliver-matrix (C3) — the `deliver` surface (+ the permanent `route`/`provide` sugar) desugars
# to den-hoag `delivery` DECLARATIONS (`declare.delivery`, resolution stratum), cell-by-cell over v1's
# `adaptArgs × path × verbatim × guard` matrix (v1 Task-17's authoritative cell mapping:
# `policy-effects.nix` fields, `edges/route.nix` classifyRoute + `edges/provides.nix` providesEdges
# modes). Declaration-in/declaration-out (Law C2): the declaration is inert INTENT (resolved class
# registrations + placement); the gen-edge record is rendered from it at the FIRING NODE by
# output-modules' `edgesAt`. A fully-compat end-to-end section then closes the dispatch loop: a v1
# deliver policy through the FULL mkDen path lands its edge in `den.graph.trace` AND moves an aspect's
# channel content into `config(root)` — exercising the C1 aspect-record fix + quirk registration.
#
# REVIEWER-PINNED correctness rule: a MODULE-source deliver (provide) renders as `sources.collected` of
# the TARGET class (edges/provides.nix:121-122 — the provided module rides the target scope's own bucket,
# carried by the default fold), NEVER `synthesize` (v1's __complexForward adapter arm only) and NEVER
# `value` (v1's frozen sourceKey has no value arm). A class-source deliver → `collected` of the `from`.
{ denCompat, denHoag, ... }:
let
  inherit (denCompat)
    deliver
    route
    provide
    compile
    ;

  # One fixture, all matrix cells as policies (compiled once). Classes `src`/`dst` are declared so the
  # C6 class-name → registration resolution finds them.
  fixture = {
    hosts.x86_64-linux.axon.class = "nixos";
    classes.src = { };
    classes.dst = { };
    policies = {
      # ── class source (route edge): mode is PATH-derived (merge at [], nest at a path), verbatim wins ──
      cMerge = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
        })
      ]; # at=[] → merge
      cNest = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
          at = [ "p" ];
        })
      ]; # at=[p] → nest
      cVerbatim = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
          mode = "verbatim";
        })
      ]; # → nest-verbatim
      cVerbatimP = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
          at = [ "p" ];
          mode = "verbatim";
        })
      ];
      cAdapt = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
          at = [ "p" ];
          adaptArgs = a: a;
        })
      ];
      cGuard = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
          guard = _: true;
        })
      ];
      cAdaptGuard = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
          at = [ "p" ];
          adaptArgs = a: a;
          guard = _: true;
        })
      ];
      cVerbAdapt = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
          at = [ "p" ];
          mode = "verbatim";
          adaptArgs = a: a;
        })
      ];
      # ── module source (provide edge): collected-of-target source, mode path-derived ──
      pMerge = _ctx: [
        (provide {
          class = "dst";
          module = {
            foo = 1;
          };
        })
      ]; # path=[] → merge
      pNest = _ctx: [
        (provide {
          class = "dst";
          module = {
            foo = 1;
          };
          path = [ "p" ];
        })
      ];
      # ── route sugar: reinstantiate → verbatim; intoPath → at ──
      rReinst = _ctx: [
        (route {
          fromClass = "src";
          intoClass = "dst";
          reinstantiate = true;
        })
      ];
      rIntoPath = _ctx: [
        (route {
          fromClass = "src";
          intoClass = "dst";
          intoPath = [ "q" ];
        })
      ];
    };
  };

  compiled = compile fixture;
  # `compile` returns policy thunks; a `delivery` declaration reads no ctx (its firing scope is the
  # dispatching node, resolved at edgesAt), so any ctx yields the same intent declaration.
  declOf = name: builtins.head (compiled.policies.${name} { });

  # ── systemFor carry-in (§2.5): v1's per-host `system` reaches the built system via the compat nixos
  #    instantiate wrapper. A stub terminal (identity) makes the injected module directly inspectable.
  sysCompiled = compile { hosts.x86_64-linux.axon.class = "nixos"; };
  sysAxon = sysCompiled.entities.registries.host.axon;
  stubTerminal = args: args;
  sysInstantiate = denCompat.mkNixosInstantiate {
    inherit (sysCompiled.entities) systemFor;
    terminal = stubTerminal;
  };
  sysInjected = sysInstantiate {
    name = "axon";
    hostModules = [ { existing = true; } ];
    bindings = {
      host = sysAxon;
    };
    classCfg = { };
  };
  sysHostModules = sysInjected.hostModules;

  # the mkDen path wires the compat systemFor instantiate into the real collect terminal.
  rt = denCompat.mkDen [ { config.den.hosts.x86_64-linux.axon.class = "nixos"; } ];
  rtAxon = rt.den.registries.host.axon;
  collectOut = rt.den.classConfigs.nixos.instantiate {
    name = "axon";
    hostModules = [ { userMod = true; } ];
    bindings = {
      host = rtAxon;
    };
    classCfg = rt.den.classConfigs.nixos;
  };
  collectModules = collectOut.modules;

  # ── FULLY-COMPAT dispatch loop: a v1 deliver policy through the FULL mkDen path lands its edge in the
  #    trace AND moves aspect channel content into config(root). This exercises the whole chain: the
  #    include edge carries the FULL compiled aspect record (C1 fix — resolved-aspects reads it directly),
  #    the quirk channel is registered (`src` gains the aspect's contribution), and the deliver resolves
  #    `from`/`to` against the fold's channels — so the `src` channel is routed into `dst` in config.
  e2e = denCompat.mkDen [
    {
      config.den.hosts.x86_64-linux.axon.class = "nixos";
      config.den.quirks.src = { };
      config.den.quirks.dst = { };
      config.den.aspects.seed.src = [ "hello" ];
      config.den.schema.host.includes = [ "seed" ];
      config.den.policies.route1 = _ctx: [
        (deliver {
          from = "src";
          to = "dst";
        })
      ];
      config.den.policies.p = _ctx: [
        (provide {
          class = "dst";
          module = {
            m = 1;
          };
        })
      ];
    }
  ];
  e2eTrace = e2e.den.graph.trace "host:axon";
  e2eConfig = e2e.den.output.outputFor "host:axon";
  e2eSrcContribs =
    ((e2e.den.structural.eval.get "host:axon" "received-collections").src or { }).contributions or [ ];
  # the route delivery edge: collected(src) → root(dst).
  routeEdges = builtins.filter (
    e:
    e.source.arm == "collected"
    && (e.source.class or null) == "src"
    && (e.target.class or null) == "dst"
  ) e2eTrace;
  # the provide delivery edge collects the TARGET class (dst) — reviewer-pinned collected shape.
  provideCollectsTarget = builtins.any (
    e:
    e.source.arm == "collected"
    && (e.source.class or null) == "dst"
    && (e.target.class or null) == "dst"
  ) e2eTrace;
  # reviewer pin: the shim NEVER emits synthesize/value — every trace edge is collected.
  everyEdgeCollected = builtins.all (e: e.source.arm == "collected") e2eTrace;

  # tryEval helper for the error cells (the descriptor forces its validation eagerly).
  fails = expr: !(builtins.tryEval expr).success;
in
{
  flake.tests.compat-deliver-matrix = {
    # ── declaration is a resolution-stratum `delivery` INTENT (dispatchable; no probe crash) ──
    test-is-delivery-action = {
      expr = (declOf "cMerge").__action;
      expected = "delivery";
    };
    test-delivery-classifies-resolution = {
      expr = denHoag.declare.kindToStratum.delivery;
      expected = "resolution";
    };
    # class source collects `from`; both classes are resolved REGISTRATIONS (C6, id_hash-bearing).
    test-class-source-class = {
      expr = (declOf "cMerge").sourceClass.name;
      expected = "src";
    };
    test-target-class = {
      expr = (declOf "cMerge").targetClass.name;
      expected = "dst";
    };
    test-source-class-is-entry = {
      expr = (declOf "cMerge").sourceClass ? id_hash;
      expected = true;
    };
    test-class-source-no-module = {
      expr = (declOf "cMerge").module;
      expected = null;
    };

    # ── mode cells: verbatim → nest-verbatim; else PATH-derived (merge at [], nest at a path) ──
    test-mode-merge = {
      expr = (declOf "cMerge").mode;
      expected = "merge";
    };
    test-mode-nest = {
      expr = (declOf "cNest").mode;
      expected = "nest";
    };
    test-mode-verbatim = {
      expr = (declOf "cVerbatim").mode;
      expected = "nest-verbatim";
    };
    test-mode-verbatim-with-path = {
      expr = (declOf "cVerbatimP").mode;
      expected = "nest-verbatim";
    };
    test-path-preserved = {
      expr = (declOf "cNest").path;
      expected = [ "p" ];
    };
    test-merge-path-empty = {
      expr = (declOf "cMerge").path;
      expected = [ ];
    };

    # ── adaptArgs × guard cells: closures carried on the declaration; annotations are trace booleans ──
    test-plain-no-annotations = {
      expr = (declOf "cMerge").annotations;
      expected = { };
    };
    test-adapt-annotation = {
      expr = (declOf "cAdapt").annotations;
      expected = {
        adaptArgs = true;
      };
    };
    test-adapt-closure-carried = {
      expr = (declOf "cAdapt").adaptArgs != null;
      expected = true;
    };
    test-guard-annotation = {
      expr = (declOf "cGuard").annotations;
      expected = {
        guard = true;
      };
    };
    test-guard-closure-carried = {
      expr = (declOf "cGuard").guard != null;
      expected = true;
    };
    test-adapt-guard-annotation = {
      expr = (declOf "cAdaptGuard").annotations;
      expected = {
        adaptArgs = true;
        guard = true;
      };
    };
    test-verbatim-adapt-mode = {
      expr = (declOf "cVerbAdapt").mode;
      expected = "nest-verbatim";
    };

    # ── module source (provide) → collected of the TARGET class, mergeHalf annotation (v1 provides.nix) ──
    test-provide-carries-module = {
      expr = (declOf "pMerge").module != null;
      expected = true;
    };
    test-provide-source-is-target = {
      expr = (declOf "pMerge").sourceClass.name;
      expected = "dst";
    };
    test-provide-target-class = {
      expr = (declOf "pMerge").targetClass.name;
      expected = "dst";
    };
    test-provide-merge-half-annotation = {
      expr = (declOf "pMerge").annotations.mergeHalf;
      expected = "default-fold";
    };
    test-provide-merge-mode = {
      expr = (declOf "pMerge").mode;
      expected = "merge";
    };
    test-provide-nest-mode = {
      expr = (declOf "pNest").mode;
      expected = "nest";
    };

    # ── route sugar: reinstantiate → nest-verbatim; intoPath → the target path ──
    test-route-reinstantiate = {
      expr = (declOf "rReinst").mode;
      expected = "nest-verbatim";
    };
    test-route-intopath = {
      expr = (declOf "rIntoPath").path;
      expected = [ "q" ];
    };
    test-route-intopath-mode = {
      expr = (declOf "rIntoPath").mode;
      expected = "nest";
    };

    # ── §2.3 error cases (pinned message, same condition, definition-time) ──
    test-error-invalid-mode = {
      expr = fails (deliver {
        from = "src";
        to = "dst";
        mode = "bogus";
      });
      expected = true;
    };
    test-error-verbatim-module = {
      expr = fails (deliver {
        from = {
          module = { };
        };
        to = "dst";
        mode = "verbatim";
      });
      expected = true;
    };
    test-error-route-path-conflict = {
      expr = fails (route {
        fromClass = "src";
        intoClass = "dst";
        intoPath = [ "a" ];
        path = [ "b" ];
      });
      expected = true;
    };
    # unknown target class → the C6 named abort (unknownClass), forced through the resolved target.
    test-error-unknown-class = {
      expr = fails (
        let
          bad = compile {
            classes.src = { };
            policies.bad = _ctx: [
              (deliver {
                from = "src";
                to = "nope";
              })
            ];
          };
        in
        (builtins.head (bad.policies.bad { })).targetClass.name
      );
      expected = true;
    };

    # ── the deliver SURFACE rejects the shim-internal fields (reached only through route's __extra):
    #    they are NOT in its (strict, no-ellipsis) arg set, so passing either is an arity abort ──
    test-deliver-surface-args = {
      expr = builtins.attrNames (builtins.functionArgs deliver);
      expected = [
        "adaptArgs"
        "at"
        "from"
        "guard"
        "mode"
        "to"
      ];
    };
    test-deliver-rejects-reinstantiate = {
      expr = builtins.functionArgs deliver ? reinstantiate;
      expected = false;
    };
    test-deliver-rejects-append-to-parent = {
      expr = builtins.functionArgs deliver ? appendToParent;
      expected = false;
    };

    # ── COMPAT dispatch loop: the v1 deliver policy's edge reaches den.graph.trace ──
    test-e2e-route-edge-in-trace = {
      expr = builtins.length routeEdges;
      expected = 1;
    };
    test-e2e-route-edge-collected = {
      expr = (builtins.head routeEdges).source.arm;
      expected = "collected";
    };
    test-e2e-provide-collects-target = {
      expr = provideCollectsTarget;
      expected = true;
    };
    # reviewer pin at the EDGE level: no synthesize/value arm ever appears in the shim's trace.
    test-e2e-no-synthesize-or-value = {
      expr = everyEdgeCollected;
      expected = true;
    };

    # ── FULLY-COMPAT content: the C1 aspect fix makes the include carry content, so the host's channel
    #    gains the aspect's contribution and the deliver routes it into config(root) ──
    test-compat-channel-gains-aspect = {
      expr = map (c: c.value) e2eSrcContribs;
      expected = [ [ "hello" ] ];
    };
    test-compat-content-moved = {
      expr = e2eConfig."host:axon".dst;
      expected = [ [ "hello" ] ];
    };
    test-compat-source-retained = {
      expr = e2eConfig."host:axon".src;
      expected = [ [ "hello" ] ];
    };

    # ── systemFor carry-in (§2.5) ──
    test-systemfor-map = {
      expr = sysCompiled.entities.systemFor sysAxon;
      expected = "x86_64-linux";
    };
    test-systemfor-injected-module = {
      expr = builtins.head sysHostModules;
      expected = {
        nixpkgs.hostPlatform.system = "x86_64-linux";
      };
    };
    test-systemfor-preserves-host-modules = {
      expr = builtins.elemAt sysHostModules 1;
      expected = {
        existing = true;
      };
    };
    test-systemfor-collect-output = {
      expr = builtins.any (
        m: builtins.isAttrs m && (m.nixpkgs.hostPlatform.system or null) == "x86_64-linux"
      ) collectModules;
      expected = true;
    };
  };
}
