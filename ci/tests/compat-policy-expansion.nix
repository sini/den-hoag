# Per-declaration-stratum policy expansion (B2) + the record policy vocabulary. A value-conditional
# policy — one whose emission is gated on a context VALUE, so it emits nothing at concern-policies'
# value-less probe (or throws doing non-entry work on the sentinel) — is expanded into one sub-rule per
# COVERED stratum {structural, resolution, collection}, each keeping only its-stratum declarations. So
# every declaration is produced in ITS stratum's phase (the one-rule/one-stratum law holds per sub-rule)
# while the policy's declarations self-route by kind. An enrich-kind declaration or a DERIVED/route
# pipeCommit from an expansion policy aborts LOUD (probe-time compose/feed commitments a value-less policy
# cannot make); a `pipeMark` on a bare channel ref is per-node emission DATA and rides the
# `#collection` sub-rule, seeding no compose op. A policy that DECLARES its
# produced-kind family (`emits` / `producesByName`) skips the fan entirely: `dispatch.deriveGroup`
# stamps its group at DEFINITION time (gen-dispatch declared-stratum), so ONE declared rule keyed by the
# bare name is built (the corpus path); the blind fan is the additive fallback for undeclared policies.
# Exercised directly through
# `denHoag.internal.compilePolicies` (concern-policies' rule compiler) + the compat compile output.
# ══ RETIREMENT RECORD — eleven tests removed with the probe they pinned ══════════════════════════════
# A test whose SUBJECT is deleted is not "a failing test": it is the durable statement of a property the
# old design guaranteed. Retiring one without recording that property loses the only written trace of
# something deliberately given up, and an abandoned property with no trace gets re-proposed later as a
# defect. So each is named here with what it pinned and why that property no longer exists.
#
# GROUP A — the 3-way EXPANSION FAN and its per-stratum sub-rule routing. Property: a policy whose stratum
# could not be observed (its value-less probe emitted nothing) was compiled into one sub-rule per covered
# stratum, each keeping only its own stratum's declarations, so every declaration reached its phase.
# Gone because the stratum is now DECLARED (`emits`) and derived through `declare.stratumOfKind`: there is
# nothing to fan over, one policy compiles to ONE rule, and the `#<stratum>` identity suffix these tests
# addressed sub-rules by no longer exists. The conservation the fan bought is now a definition-time law.
#   · test-value-conditional-expands              — a value-conditional body expands to 3 sub-rules
#   · test-probe-throw-expands                    — a body THROWING at the sentinel expands identically
#                                                   (the swallowed-throw path; now a codomain declaration)
#   · test-resolution-subrule-routes-edge         — an `edge` reaches the resolution sub-rule only
#   · test-value-conditional-spawn-routes-structural — a `spawn` reaches the structural sub-rule only
#   · test-value-conditional-sitemark-pipeop-expands — a `pipeMark` rides the `#collection` sub-rule
#   · test-corpus-straddle                        — two corpus-shaped policies straddling strata, each
#                                                   self-routing through its own fan
#
# GROUP B — the KERNEL PROBE SENTINEL. Property: the value-less probe filled only the REQUIRED gate coords,
# leaving a DEFAULTED coord to the author's own default (a default IS the author's probe-safe value, so
# clobbering it was a probe defect, not a policy signal), and a caller could enrich the sentinel with
# type-correct non-matching fields. Gone FROM THE KERNEL — `internal.compilePoliciesWith` is retired with
# it — because the kernel recovers nothing by firing.
#   · test-defaulted-coord-not-sentinel-filled    · test-enriched-exclude-value-conditional
#   · test-required-coord-still-sentinel-filled   · test-enriched-home-route-shapes
#                                                 · test-enriched-instantiate-unconditional
#
# ★ GROUP B's PROPERTY IS STILL LIVE, and re-expressing it is OWED WORK, not a discharged retirement. The
# mechanism moved to the shim: `lib/compat/policy-recover.nix` `requiredCoordsOf` still fills only required
# coords, and `lib/compat/probe-sentinel.nix` is the enrichment set. Nothing currently pins either. Group A
# is a true retirement; Group B is a relocation whose tests did not follow it yet.
# ═════════════════════════════════════════════════════════════════════════════════════════════════════
{ denHoag, denCompat, ... }:
let
  inherit (denHoag) sel;
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
  # A record policy: `{ gate; fn }` — its gate DECLARED as data (the general vocabulary a
  # generated policy uses when it cannot shape its formals).
  gated = cond: fn: {
    gate = cond;
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
  noMatchCtx = {
    host = {
      id_hash = "h";
      name = "other";
    };
  };

  # A bare channel REFERENCE (compilePipe's base seed: no deriving stages → `__derived = false`).
  bareRef = ch: {
    __genPipeChannel = true;
    __derived = false;
    id = ch;
    name = ch;
  };
  # The corpus broadcast-hub-peer shape (nix-config pipes.nix:164-170): a value-conditional pipe
  # carrying ONLY a broadcast SITE MARK on a bare channel ref — no deriving DAG, no delivery route — so
  # per-node emission DATA, not a compose commitment. Built via the SAME `declare.pipeMark` constructor
  # `compilePipe` uses (lib/compat/pipe.nix:276-281), so it is faithful to the real compile output.
  hubPeerPipeOp = declare.pipeMark {
    channel = "syncthing-peers";
    marks = [
      {
        __pipeMark = "broadcast";
        receiver = { user, ... }: true;
      }
    ];
  };
  # NON-site-mark collection decls that STILL abort under expansion (genuine probe-time compose
  # commitments): a DERIVED-op `pipeCommit` (channel-shaping DAG, `derived.__derived = true`) and a
  # delivery-ROUTE `pipeCommit` (`routes != []`).
  derivedPipeOp = declare.pipeCommit {
    channel = "c";
    derived = (bareRef "c") // {
      __derived = true;
    };
    routes = [ ];
    targeted = [ ];
  };
  routePipeOp = declare.pipeCommit {
    channel = "c";
    derived = bareRef "c";
    routes = [ { to = "other"; } ];
    targeted = [ ];
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
  #    so the record is applied by hand). Body now emits the UN-STUBBED (#50) `instantiate` EFFECT (`inst` =
  #    the constructor's `{ __policyEffect = "instantiate"; value = spec }`) — so it PROBES SINGLE-GROUP (an
  #    unconditional emission), where the old #50 STUB-throw made it look value-conditional (expansion). The
  #    DISPOSITION is unchanged: cluster-to-nixidy still never fires at a real node (no `environment` coord is
  #    bound onto cluster nodes, board #49) → `nixidyEnvs` still silently EMPTY. ─────────────────────────────
  inst = spec: {
    __policyEffect = "instantiate";
    value = spec;
  };
  ctnFn =
    { cluster, environment, ... }:
    [
      (inst {
        inherit (cluster) name;
        class = "k8s-manifests";
        instantiate = { modules, ... }: modules;
        intoAttr = [ "nixidyEnvs" ];
      })
    ];
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
  ctnRecompiled = compile { cluster-to-nixidy = ctnKindRec; };
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

    # R5 — a MIXED-strata codomain (link is structural, edge is resolution) is REFUSED AT REGISTRATION.
    # It used to self-route into one sub-rule per stratum behind a `#<stratum>` identity suffix; that fan
    # existed because the stratum was discovered by firing and a value-conditional body revealed nothing,
    # so the compiler synthesized a rule per stratum rather than guess. With the codomain declared there is
    # nothing to guess, and one rule / one stratum is gen-dispatch's core invariant. The remedy is one
    # AUTHORED policy per stratum, which is what the fan built anyway, only named.
    test-mixed-strata-refused = {
      expr =
        let
          mixed = {
            foo = {
              emits = [
                "link"
                "edge"
              ];
              selects = sel.star;
              fn =
                ctx:
                if ctx.host.name == "match" then
                  [
                    (declare.link { target = ent "t"; })
                    (declare.edge (ent "asp"))
                  ]
                else
                  [ ];
            };
          };
        in
        {
          named =
            builtins.match ".*emits kinds spanning strata.*" (denHoag.internal.policyMessage mixed) != null;
          compileAborts = (builtins.tryEval (builtins.length (compile mixed).policy)).success;
        };
      expected = {
        named = true;
        compileAborts = false;
      };
    };
    # THE AUTHORED SPLIT — the remedy the refusal names, shown working: two policies, one per stratum,
    # each a single rule with its own bare identity and no `#<stratum>` suffix anywhere.
    test-authored-per-stratum-split = {
      expr =
        let
          c = compile {
            foo-link = {
              emits = [ "link" ];
              selects = sel.star;
              fn = ctx: if ctx.host.name == "match" then [ (declare.link { target = ent "t"; }) ] else [ ];
            };
            foo-edge = {
              emits = [ "edge" ];
              selects = sel.star;
              fn = ctx: if ctx.host.name == "match" then [ (declare.edge (ent "asp")) ] else [ ];
            };
          };
        in
        {
          ids = ids c.policy;
          structural = producedKinds (ruleBy c.policy "foo-link") matchCtx;
          resolution = producedKinds (ruleBy c.policy "foo-edge") matchCtx;
        };
      expected = {
        ids = [
          "foo-edge"
          "foo-link"
        ];
        structural = [ "link" ];
        resolution = [ "edge" ];
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

    # R2 — conservation: a value-conditional policy that produces a BARE `pipeMark` (no marks, no derived, no
    # routes) at dispatch aborts loud — it is not site-mark DATA, so the fleet-compose-commitment posture
    # is retained (the DAG is seeded at the probe, which it never reaches). RETAINED verbatim across the
    # site-mark rung: a bare collection declaration still aborts.
    test-value-conditional-pipeop-aborts = {
      expr =
        let
          c = compile {
            foo = gated hostCond (vc {
              __action = "pipeMark";
            });
          };
        in
        (builtins.tryEval (
          builtins.deepSeq (producedKinds (ruleBy c.policy "foo#resolution") matchCtx) null
        )).success;
      expected = false;
    };

    # NEW (site-mark rung) — a value-conditional DERIVED-op `pipeCommit` (channel-shaping DAG,
    # `derived.__derived = true`) STILL aborts: it is a genuine probe-time compose commitment a
    # value-less policy cannot make.
    test-value-conditional-derived-pipeop-aborts = {
      expr =
        let
          c = compile { foo = gated hostCond (vc derivedPipeOp); };
        in
        (builtins.tryEval (
          builtins.deepSeq (producedKinds (ruleBy c.policy "foo#collection") matchCtx) null
        )).success;
      expected = false;
    };

    # NEW (site-mark rung) — a value-conditional delivery-ROUTE `pipeCommit` (`routes != []`) STILL aborts (the
    # same compose-commitment law: a delivery route seeds the fleet compose before eval).
    test-value-conditional-route-pipeop-aborts = {
      expr =
        let
          c = compile { foo = gated hostCond (vc routePipeOp); };
        in
        (builtins.tryEval (
          builtins.deepSeq (producedKinds (ruleBy c.policy "foo#collection") matchCtx) null
        )).success;
      expected = false;
    };

    # Byte-parity sanity: an UNCONDITIONAL policy (emits at the probe) stays a SINGLE-group rule — its
    # stratum is observed directly, no expansion, identity unchanged.
    test-unconditional-single-group = {
      expr =
        let
          c = compile {
            foo = gated hostCond (_ctx: [ (declare.edge (ent "asp")) ]) // {
              emits = [ "edge" ];
              selects = sel.star;
            };
          };
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

    # ── DECLARED-STRATUM (gen-dispatch deriveGroup). A value-conditional policy carrying a DECLARED
    #    produced-kind family (`emits`) has its group stamped at DEFINITION time by
    #    `dispatch.deriveGroup declare.stratumOfKind` — so ONE declared rule keyed by the BARE name is
    #    built, NOT the blind per-stratum fan. This is the corpus path (the five value-conditional corpus
    #    policies declare via `producesByName`); here `emits` on the record exercises the SAME
    #    mechanism directly. The undeclared fixtures above stay on the `mkExpanded` fan (produces == null),
    #    the additive fallback. ────────────────────────────────────────────────────────────────────────
    # A single-stratum declared value-conditional policy (cluster-aspect shape: edge → resolution) →
    # ONE rule, bare name, no `#stratum` fan; it fires the edge at a matching ctx.
    test-declared-single-stratum-no-fan = {
      expr =
        let
          c = compile {
            foo = (gated hostCond (vc (declare.edge (ent "asp")))) // {
              emits = [ "edge" ];
              selects = sel.star;
            };
          };
          r = builtins.head c.policy;
        in
        {
          ids = ids c.policy;
          group = r.group;
          produces = r.produces;
          firesAtMatch = producedKinds r matchCtx;
          firesAtNonMatch = producedKinds r noMatchCtx;
        };
      expected = {
        ids = [ "foo" ];
        group = "resolution";
        produces = [ "edge" ];
        firesAtMatch = [ "edge" ];
        firesAtNonMatch = [ ];
      };
    };

    # The broadcast-hub-peer shape declared: a value-conditional site-mark pipe declares `[ pipeMark ]` →
    # ONE collection rule (bare name). It STILL seeds no compose op (`pipeOps == []` — value-conditional
    # makes no compose commitment), and `assertCovered`'s site-mark allowance rides the declared rule
    # exactly as it rode the `#collection` fan sub-rule.
    test-declared-sitemark-collection = {
      expr =
        let
          c = compile {
            foo = (gated hostCond (vc hubPeerPipeOp)) // {
              emits = [ "pipeMark" ];
              selects = sel.star;
            };
          };
          r = builtins.head c.policy;
        in
        {
          ids = ids c.policy;
          group = r.group;
          composeSeeds = c.pipeOps;
          collectionAtMatch = producedKinds r matchCtx;
        };
      expected = {
        ids = [ "foo" ];
        group = "collection";
        composeSeeds = [ ];
        collectionAtMatch = [ "pipeMark" ];
      };
    };

    # A single-group (probe-emitting) rule now carries `produces` (probe-DERIVED — a free by-product of the
    # compose-seed fire), so `dispatch` HONORS the declaration and skips its per-dispatch fire-and-classify.
    test-single-group-carries-produces = {
      expr =
        (builtins.head
          (compile {
            foo = gated hostCond (_ctx: [ (declare.edge (ent "asp")) ]) // {
              emits = [ "edge" ];
              selects = sel.star;
            };
          }).policy
        ).produces;
      expected = [ "edge" ];
    };

    # DECLARING the multi-group codomain does not buy an exemption: the refusal is on the DECLARATION, so
    # it is reached whether the kinds were declared outright or recovered. This is the pair of the test
    # above and it exists because a reader could reasonably expect the declared path to be the one that
    # partitions — it is not, and the refusal names the same law from the same guard chain.
    test-declared-multi-group-refused = {
      expr =
        let
          mixed = {
            foo = {
              emits = [
                "link"
                "edge"
              ];
              selects = sel.star;
              fn = _ctx: [ ];
            };
          };
        in
        {
          named =
            builtins.match ".*emits kinds spanning strata.*" (denHoag.internal.policyMessage mixed) != null;
          citesInvariant = builtins.match ".*deriveGroup.*" (denHoag.internal.policyMessage mixed) != null;
        };
      expected = {
        named = true;
        citesInvariant = true;
      };
    };
    # (b) host-modules-capture (host.class as spec DATA, UNCONDITIONAL emit): SINGLE-group resolution; the fake
    #     sentinel class is DISCARDED — dispatch re-runs produce with the REAL class at a real node.
    # (c) drop-user-to-host-on-droid (host.class == "droid", value-conditional): sentinel class="«probe»" ≠
    #     "droid" → `[]` → EXPANSION (no exclude at the probe; the droid-node fire stays the #50 abort).

    # R3 — SCOPE-LOCAL FIRING (board #57, ledger u3): a policy declared in BOTH `den.policies` AND a
    # `den.schema.<kind>.includes` reference fires SOLELY via its kind-scoped `__kindInclude` arm — its
    # fleet-wide compiled entry is REMOVED (`includeReferencedNames`: v1 fires a policy only where INCLUDED,
    # not by mere `den.policies` presence). The include reference is the COERCED `{ __isPolicy }` record
    # (the bridge coercion; direct `compile` applies it by hand) — that is what makes it classify as a
    # POLICY (a bare fn would be a parametric aspect, R14) and carry the `.name` the removal set keys on.
    test-included-policy-fires-only-via-arm = {
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
          arm = c.policies."__kindInclude__k__policy__0";
        in
        {
          fleetWide = c.policies ? p;
          kindScoped = c.policies ? "__kindInclude__k__policy__0";
          # the surviving arm is confined to owner-kind nodes (Part 2 — `selects`).
          armFiresAtKind = arm.selects;
        };
      expected = {
        fleetWide = false;
        kindScoped = true;
        armFiresAtKind = sel.attrs { type = "k"; };
      };
    };

    # ── cluster-to-nixidy latent-v1-divergence PIN (ledger row u2 / boards #49/#50, u1 precedent) ────────
    # (a) COMPILE-SIDE: the kind-include rule's `gate` carries BOTH coords. Pre-fix, the fn crossed
    #     the bridge's freeform `anything` and was formal-erased (`functionArgs = {}`), so `kindCoord //
    #     {}` kept only `{ cluster }` and DROPPED `environment` — then concern-policies' probe applied the
    #     fn without it (the uncatchable `called without required argument 'environment'`). The bridge's
    #     `den.policies` coercion nests the fn (`{ __isPolicy; fn }`), preserving formals; this pins the gate.
    test-cluster-to-nixidy-condition-carries-environment = {
      expr = ctnKindRec.gate;
      expected = {
        cluster = false;
        environment = false;
      };
    };
    # (b) SINGLE-GROUP (the #50 un-stub): the `instantiate` constructor now EMITS (no throw), so the body
    #     produces UNCONDITIONALLY at the value-less probe → a single-group resolution rule gated on
    #     {cluster, environment} (the old STUB-throw made it LOOK value-conditional → expansion; the emission
    #     reveals it is unconditional). Its produce is a `spawn { instantiate }` (childless-inert; the intoAttr
    #     nixidyEnvs family is den-hoag-absent → latent, ledger u2).
    test-cluster-to-nixidy-single-group = {
      expr = {
        ids = ids ctnRecompiled.policy;
        conds = map (r: r.condition) ctnRecompiled.policy;
      };
      expected = {
        ids = [ "cluster-to-nixidy" ];
        conds = [
          {
            cluster = false;
            environment = false;
          }
        ];
      };
    };
    # (c) INERT at a cluster-less/env-less node: a plain host resolves CLEAN — the {cluster,environment}-
    #     gated policy never fires (den-hoag binds no `environment` onto cluster nodes; no env→cluster
    #     containment, board #49), so no instantiate emission → `nixidyEnvs` silently EMPTY. The #50 un-stub
    #     did NOT flip this (disposition unchanged: the emission is gated by the same missing `environment`
    #     coord); env→cluster containment (#49) is what would materialize nixidyEnvs — update with ledger u2.
    test-cluster-to-nixidy-inert-at-plain-host = {
      expr = (builtins.tryEval (builtins.deepSeq ctnHostRa true)).success;
      expected = true;
    };
  };
}
