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

    # R3 — a policy declared in BOTH `den.policies` AND a `den.schema.<kind>.includes` reference keeps BOTH
    # firings: its fleet-wide compiled entry AND its kind-scoped `__kindInclude` entry.
    test-both-case-keeps-both-firings = {
      expr =
        let
          p = _ctx: [
            {
              __policyEffect = "include";
              value = {
                name = "a";
              };
            }
          ];
          c = denCompat.compile {
            aspects.a = { };
            policies.p = p;
            schema.k = {
              parent = "host";
              includes = [ p ];
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
  };
}
