# Per-declaration-stratum policy expansion (B2) + the record policy vocabulary. A value-conditional
# policy — one whose emission is gated on a context VALUE, so it emits nothing at concern-policies'
# value-less probe (or throws doing non-entry work on the sentinel) — is expanded into one sub-rule per
# COVERED stratum {structural, resolution}, each keeping only its-stratum declarations. So every
# declaration is produced in ITS stratum's phase (the one-rule/one-stratum law holds per sub-rule) while
# the policy's declarations self-route by kind. Enrich- or pipeOp-kind declarations from an expansion
# policy abort LOUD (probe-time commitments a value-less policy cannot make). Exercised directly through
# `denHoag.internal.compilePolicies` (concern-policies' rule compiler) + the compat compile output.
{ denHoag, denCompat, ... }:
let
  declare = denHoag.declare;
  compile = denHoag.internal.compilePolicies;
  # The CONFIGURABLE probe sentinel (B2): `compilePoliciesWith sentinelFields` merges the fields onto the
  # value-less probe entry. The compat supplies {class, system} (flake-module.nix probeSentinelModule); this
  # exercises the core mechanism directly with the same non-matching string sentinels.
  compileEnriched = denHoag.internal.compilePoliciesWith {
    class = "«probe»";
    system = "«probe»";
  };

  ent = k: {
    id_hash = k;
    name = k;
  };
  # A record policy: `{ __condition; fn }` — its gate DECLARED as data (the general vocabulary a
  # generated policy uses when it cannot shape its formals).
  gated = cond: fn: {
    __condition = cond;
    inherit fn;
  };
  hostCond = {
    host = false;
  };
  # A value-conditional body: emits its declaration only where host.name == "match" (nothing at the
  # value-less sentinel, whose name is "«probe»").
  vc = decl: ctx: if ctx.host.name == "match" then [ decl ] else [ ];
  matchCtx = {
    host = {
      id_hash = "h";
      name = "match";
    };
  };

  ruleBy = feed: id: builtins.head (builtins.filter (r: r.identity == id) feed);
  ids = feed: builtins.sort (a: b: a < b) (map (r: r.identity) feed);
  producedKinds = rule: ctx: map (a: a.__action) (rule.produce "n" ctx);

  # ── cluster-to-nixidy latent-v1-divergence (ledger row u2) — the DOWNSTREAM shim consequence of the
  #    bridge's `den.policies` v1-parity COERCION (lib/compat/bridge.nix, policy-type.nix). The corpus's
  #    `den.policies.cluster-to-nixidy = { cluster, environment, ... }: map (…instantiate…) …` (nix-config
  #    clusters.nix:96) is coerced to `{ __isPolicy; name; fn }` — its formals ride INTACT on the NESTED `fn`
  #    — and its `den.schema.cluster.includes` REFERENCE arrives as that RECORD (the coerced corpus shape).
  #    Here `ctnFn` is the raw body and `ctnRec` mirrors the bridge coercion (direct `compile` gets no bridge,
  #    so the record is applied by hand). Body calls the board-#50 `instantiate` STUB (a throw). ────────────
  instantiateStub = _spec: throw "den-hoag compat: `den.lib.policy.instantiate` — board #50 stub";
  ctnFn =
    { cluster, environment, ... }:
    [ (instantiateStub { inherit (cluster) name; }) ];
  ctnRec = {
    __isPolicy = true;
    name = "cluster-to-nixidy";
    fn = ctnFn;
  };
  ctnCompiled = denCompat.compile {
    policies.cluster-to-nixidy = ctnRec;
    schema.environment = {
      parent = "host";
    };
    schema.cluster = {
      parent = "environment";
      includes = [ ctnRec ];
    };
  };
  ctnKindRec = ctnCompiled.policies."__kindInclude__cluster__policy__0";
  ctnExpanded = compile { cluster-to-nixidy = ctnKindRec; };
  # Behavioural inert: a plain host is cluster-less + env-less, so the {cluster,environment}-gated policy
  # never fires there — the host resolves CLEAN (no throw, no instantiate).
  ctnFleet =
    (denCompat.mkDen [
      {
        config.den = {
          policies.cluster-to-nixidy = ctnRec;
          schema.environment = {
            parent = "host";
          };
          schema.cluster = {
            parent = "environment";
            includes = [ ctnRec ];
          };
          hosts.x86_64-linux.h1.class = "nixos";
        };
      }
    ]).den;
  ctnHostRa = ctnFleet.structural.eval.get "host:h1" "resolved-aspects";
in
{
  flake.tests.compat-policy-expansion = {
    # A value-conditional policy expands into per-stratum sub-rules on the POLICY feed (never the enrich
    # feed — the empty probe no longer misclassifies it as enrichment).
    test-value-conditional-expands = {
      expr =
        let
          c = compile { foo = gated hostCond (vc (declare.edge (ent "asp"))); };
        in
        {
          policy = ids c.policy;
          enrich = ids c.enrich;
        };
      expected = {
        policy = [
          "foo#resolution"
          "foo#structural"
        ];
        enrich = [ ];
      };
    };

    # The RESOLUTION sub-rule routes the value-conditional edge (a resolution kind) at a real matching
    # ctx; the STRUCTURAL sub-rule keeps nothing (the edge is not structural).
    test-resolution-subrule-routes-edge = {
      expr =
        let
          c = compile { foo = gated hostCond (vc (declare.edge (ent "asp"))); };
        in
        {
          resolution = producedKinds (ruleBy c.policy "foo#resolution") matchCtx;
          structural = producedKinds (ruleBy c.policy "foo#structural") matchCtx;
        };
      expected = {
        resolution = [ "edge" ];
        structural = [ ];
      };
    };

    # The env-to-clusters shape: a value-conditional STRUCTURAL policy (resolve → spawn) routes its spawn
    # to the structural sub-rule.
    test-value-conditional-spawn-routes-structural = {
      expr =
        let
          c = compile {
            foo = gated hostCond (
              vc (
                declare.spawn {
                  classes = [ ];
                  bindings = { };
                }
              )
            );
          };
        in
        {
          structural = producedKinds (ruleBy c.policy "foo#structural") matchCtx;
          resolution = producedKinds (ruleBy c.policy "foo#resolution") matchCtx;
        };
      expected = {
        structural = [ "spawn" ];
        resolution = [ ];
      };
    };

    # R5 — a MIXED-strata value-conditional body (link is structural, edge is resolution) self-routes:
    # the link to the structural sub-rule, the edge to the resolution sub-rule, each in its phase.
    test-mixed-strata-self-route = {
      expr =
        let
          c = compile {
            foo = gated hostCond (
              ctx:
              if ctx.host.name == "match" then
                [
                  (declare.link { target = ent "t"; })
                  (declare.edge (ent "asp"))
                ]
              else
                [ ]
            );
          };
        in
        {
          structural = producedKinds (ruleBy c.policy "foo#structural") matchCtx;
          resolution = producedKinds (ruleBy c.policy "foo#resolution") matchCtx;
        };
      expected = {
        structural = [ "link" ];
        resolution = [ "edge" ];
      };
    };

    # R1 — a body whose work on a coord VALUE THROWS against the sentinel (here: it edges to a
    # host-derived aspect that is absent at the value-less sentinel, so the edge constructor's identity
    # law throws on the "bad" fallback). The tryEval-guarded probe treats a throw IDENTICALLY to an empty
    # result, so the policy still compiles (expansion — the conservative branch) and fires correctly where
    # the aspect is real. (tryEval catches throw/abort; a body that instead hits a raw attribute-missing
    # is not catchable — but the corpus's value-conditional policies use `or` defaults / present coords and
    # emit `[]` cleanly, so they take the empty path, never this one.)
    test-probe-throw-expands = {
      expr =
        let
          throwBody = ctx: [ (declare.edge (ctx.host.aspect or "bad")) ];
          c = compile { foo = gated hostCond throwBody; };
          realCtx = {
            host = {
              aspect = ent "a";
            };
          };
        in
        {
          compiled = ids c.policy;
          firesAtReal = producedKinds (ruleBy c.policy "foo#resolution") realCtx;
        };
      expected = {
        compiled = [
          "foo#resolution"
          "foo#structural"
        ];
        firesAtReal = [ "edge" ];
      };
    };

    # R2 — conservation: a value-conditional policy that produces an ENRICH declaration at dispatch aborts
    # loud (enrich-feed selection is a probe-time commitment it cannot make).
    test-value-conditional-enrich-aborts = {
      expr =
        let
          c = compile {
            foo = gated hostCond (
              vc (
                declare.enrich {
                  key = "k";
                  value = 1;
                }
              )
            );
          };
        in
        (builtins.tryEval (
          builtins.deepSeq (producedKinds (ruleBy c.policy "foo#structural") matchCtx) null
        )).success;
      expected = false;
    };

    # R2 — conservation: a value-conditional policy that produces a pipeOp (collection) declaration at
    # dispatch aborts loud (the fleet compose DAG is seeded at the probe, which it never reaches).
    test-value-conditional-pipeop-aborts = {
      expr =
        let
          c = compile {
            foo = gated hostCond (vc {
              __action = "pipeOp";
            });
          };
        in
        (builtins.tryEval (
          builtins.deepSeq (producedKinds (ruleBy c.policy "foo#resolution") matchCtx) null
        )).success;
      expected = false;
    };

    # Byte-parity sanity: an UNCONDITIONAL policy (emits at the probe) stays a SINGLE-group rule — its
    # stratum is observed directly, no expansion, identity unchanged.
    test-unconditional-single-group = {
      expr =
        let
          c = compile { foo = gated hostCond (_ctx: [ (declare.edge (ent "asp")) ]); };
        in
        {
          ids = ids c.policy;
          group = (builtins.head c.policy).group;
        };
      expected = {
        ids = [ "foo" ];
        group = "resolution";
      };
    };

    # ── FIX-B part 1 (probe fills REQUIRED coords only) — a DEFAULTED gate coord is NOT sentinel-filled, so
    #    the body's default applies (env-users' `accessGroups ? []` shape, corpus users.nix:107). Pre-fix the
    #    probe filled it with a `{ id_hash; name }` SET → `elem g accessGroups` threw "expected a list but
    #    found a set" (uncatchable by tryEval → the whole fleet eval crashed at the value-less probe). ──────
    test-defaulted-coord-not-sentinel-filled = {
      expr =
        let
          # `req` REQUIRED (false → sentinel-filled), `opt` DEFAULTED (true → omitted, so `or []` applies).
          # The body LIST-OPS on `opt`: CLEAN when omitted; a "found a set" crash if it were the sentinel.
          c = compile {
            foo = gated {
              req = false;
              opt = true;
            } (ctx: if builtins.elem "admin" (ctx.opt or [ ]) then [ (declare.edge (ent "a")) ] else [ ]);
          };
        in
        {
          probesClean = ids c.policy;
          firesAtReal = producedKinds (ruleBy c.policy "foo#resolution") {
            req = ent "R";
            opt = [ "admin" ];
          };
        };
      expected = {
        probesClean = [
          "foo#resolution"
          "foo#structural"
        ];
        firesAtReal = [ "edge" ];
      };
    };

    # A REQUIRED coord is STILL sentinel-filled (unchanged behavior): the body reads `ctx.req.id_hash` (the
    # sentinel marker) at the probe and EMITS, so the rule stays SINGLE-group — proving the required coord
    # got a sentinel entry (were it omitted, `ctx.req.id_hash` would be an uncatchable missing-attribute).
    test-required-coord-still-sentinel-filled = {
      expr =
        let
          c = compile { foo = gated { req = false; } (ctx: [ (declare.edge (ent ctx.req.id_hash)) ]); };
        in
        {
          ids = ids c.policy;
          group = (builtins.head c.policy).group;
        };
      expected = {
        ids = [ "foo" ];
        group = "resolution";
      };
    };

    # ── FIX-B part 2 (configurable probe sentinel — the FROZEN-corpus residual). The compat enriches the
    #    probe entry with NON-MATCHING {class, system} sentinels so a corpus policy reading a bare coord FIELD
    #    takes its value-conditional FALSE branch (→ expansion) rather than hard-failing. The five corpus
    #    shapes, through the enriched core compile: ──────────────────────────────────────────────────────────
    # (a) the three home-platform ROUTE shapes (host.system, value-conditional): sentinel system="«probe»" →
    #     the OS-suffix test is false → `[]` → EXPANSION; each fires at its matching REAL host.
    test-enriched-home-route-shapes = {
      expr =
        let
          mk =
            pat:
            gated { host = false; } (
              ctx: if builtins.match pat ctx.host.system != null then [ (declare.edge (ent "hm")) ] else [ ]
            );
          firesAt =
            c: sys:
            producedKinds (ruleBy c.policy "r#resolution") {
              host = {
                id_hash = "h";
                name = "h";
                system = sys;
              };
            };
          cLinux = compileEnriched { r = mk ".*-linux"; };
          cDarwin = compileEnriched { r = mk ".*-darwin"; };
          cAarch = compileEnriched { r = mk "aarch64-.*"; };
        in
        {
          linuxExpands = ids cLinux.policy;
          linuxFires = firesAt cLinux "x86_64-linux";
          darwinFires = firesAt cDarwin "aarch64-darwin";
          aarchFires = firesAt cAarch "aarch64-linux";
        };
      expected = {
        linuxExpands = [
          "r#resolution"
          "r#structural"
        ];
        linuxFires = [ "edge" ];
        darwinFires = [ "edge" ];
        aarchFires = [ "edge" ];
      };
    };
    # (b) host-modules-capture (host.class as spec DATA, UNCONDITIONAL emit): SINGLE-group resolution; the fake
    #     sentinel class is DISCARDED — dispatch re-runs produce with the REAL class at a real node.
    test-enriched-instantiate-unconditional = {
      expr =
        let
          c = compileEnriched {
            hmc = gated { host = false; } (ctx: [
              (declare.spawn {
                instantiate = {
                  class = ctx.host.class;
                };
              })
            ]);
          };
          realDecl = builtins.head (
            (builtins.head c.policy).produce "n" {
              host = {
                id_hash = "h";
                name = "h";
                class = "nixos";
              };
            }
          );
        in
        {
          singleGroup = ids c.policy;
          realClass = realDecl.instantiate.class;
        };
      expected = {
        singleGroup = [ "hmc" ];
        realClass = "nixos";
      };
    };
    # (c) drop-user-to-host-on-droid (host.class == "droid", value-conditional): sentinel class="«probe»" ≠
    #     "droid" → `[]` → EXPANSION (no exclude at the probe; the droid-node fire stays the #50 abort).
    test-enriched-exclude-value-conditional = {
      expr =
        ids
          (compileEnriched {
            drop = gated { host = false; } (
              ctx: if ctx.host.class == "droid" then [ (declare.edge (ent "excl")) ] else [ ]
            );
          }).policy;
      expected = [
        "drop#resolution"
        "drop#structural"
      ];
    };

    # R3 — a policy declared in BOTH `den.policies` AND a `den.schema.<kind>.includes` reference keeps BOTH
    # firings: its fleet-wide compiled entry AND its kind-scoped `__kindInclude` entry. Both use the COERCED
    # `{ __isPolicy }` record shape (the bridge coercion; direct `compile` applies it by hand) — that is what
    # makes the include reference classify as a POLICY (a bare fn would be a parametric aspect, R14).
    test-both-case-keeps-both-firings = {
      expr =
        let
          pRec = {
            __isPolicy = true;
            name = "p";
            fn = _ctx: [
              {
                __policyEffect = "include";
                value = {
                  name = "a";
                };
              }
            ];
          };
          c = denCompat.compile {
            aspects.a = { };
            policies.p = pRec;
            schema.k = {
              parent = "host";
              includes = [ pRec ];
            };
            k.k1 = { };
          };
        in
        {
          fleetWide = c.policies ? p;
          kindScoped = c.policies ? "__kindInclude__k__policy__0";
        };
      expected = {
        fleetWide = true;
        kindScoped = true;
      };
    };

    # The corpus STRADDLE in ONE fixture: a value-conditional edge policy (cluster-aspect shape:
    # include → edge → resolution) AND a value-conditional spawn policy (env-to-clusters shape:
    # resolve → spawn → structural). From the same compile, the edge lands in the resolution sub-rule and
    # the spawn in the structural sub-rule — the two straddle the stratum split, each declaration produced
    # in its stratum's phase (B2), never mis-placed. This subsumes the mixed-strata self-route.
    test-corpus-straddle = {
      expr =
        let
          c = compile {
            clusterAspect = gated hostCond (vc (declare.edge (ent "asp")));
            envToClusters = gated hostCond (
              vc (
                declare.spawn {
                  classes = [ ];
                  bindings = { };
                }
              )
            );
          };
        in
        {
          edgeInResolution = producedKinds (ruleBy c.policy "clusterAspect#resolution") matchCtx;
          edgeNotStructural = producedKinds (ruleBy c.policy "clusterAspect#structural") matchCtx;
          spawnInStructural = producedKinds (ruleBy c.policy "envToClusters#structural") matchCtx;
          spawnNotResolution = producedKinds (ruleBy c.policy "envToClusters#resolution") matchCtx;
        };
      expected = {
        edgeInResolution = [ "edge" ];
        edgeNotStructural = [ ];
        spawnInStructural = [ "spawn" ];
        spawnNotResolution = [ ];
      };
    };

    # ── cluster-to-nixidy latent-v1-divergence PIN (ledger row u2 / boards #49/#50, u1 precedent) ────────
    # (a) COMPILE-SIDE: the kind-include rule's `__condition` carries BOTH coords. Pre-fix, the fn crossed
    #     the bridge's freeform `anything` and was formal-erased (`functionArgs = {}`), so `kindCoord //
    #     {}` kept only `{ cluster }` and DROPPED `environment` — then concern-policies' probe applied the
    #     fn without it (the uncatchable `called without required argument 'environment'`). The bridge's
    #     `den.policies` coercion nests the fn (`{ __isPolicy; fn }`), preserving formals; this pins the gate.
    test-cluster-to-nixidy-condition-carries-environment = {
      expr = ctnKindRec.__condition;
      expected = {
        cluster = false;
        environment = false;
      };
    };
    # (b) COMPILES (no uncatchable throw): the `instantiate` STUB throw is tryEval-caught at the value-less
    #     probe → per-declaration EXPANSION into two sub-rules, each gated on {cluster, environment}.
    test-cluster-to-nixidy-expands-gated = {
      expr = {
        ids = ids ctnExpanded.policy;
        conds = map (r: r.condition) ctnExpanded.policy;
      };
      expected = {
        ids = [
          "cluster-to-nixidy#resolution"
          "cluster-to-nixidy#structural"
        ];
        conds = [
          {
            cluster = false;
            environment = false;
          }
          {
            cluster = false;
            environment = false;
          }
        ];
      };
    };
    # (c) INERT at a cluster-less/env-less node: a plain host resolves CLEAN — the {cluster,environment}-
    #     gated policy never fires (den-hoag binds no `environment` onto cluster nodes; no env→cluster
    #     containment, board #49), so no instantiate + no throw → `nixidyEnvs` silently EMPTY. LOUD PIN: if
    #     den-hoag gains env→cluster containment (#49) or the instantiate surface lands (#50), this flips —
    #     update together with ledger row u2.
    test-cluster-to-nixidy-inert-at-plain-host = {
      expr = (builtins.tryEval (builtins.deepSeq ctnHostRa true)).success;
      expected = true;
    };
  };
}
