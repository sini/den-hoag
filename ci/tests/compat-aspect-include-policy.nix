# #65 — the ASPECT-INCLUDE POLICY-RECORD grain (ledger u16; v1 children.nix:70-72 parity, the THIRD
# include grain). v1 `processInclude`'s FIRST arm routes ANY `{ __isPolicy }` include to
# `register-aspect-policy` (pin 11866c16 aspect/children.nix:70-72) — never the aspect walk — and fires
# it at the registering scope gated on the fn's REQUIRED formals (`resolveArgsSatisfied`,
# synthesize-policies.nix:7-16). The shim's two prior grains covered `den.schema.<kind>.includes` and
# top-level `den.default.includes`; a record NESTED in a REGULAR aspect's `.includes` (the corpus
# host-aspects battery via users/sini.nix:4) fell to `groundRec`, grounded to content, and its `fn` key
# aborted §2.2 (ledger u15 — the falsified "corpus-zero" claim). Now: the static collection walk
# (compile.nix `aspectIncludeRecords`) compiles each record to an `__aspectInclude__<name>` rule via the
# SAME `compilePolicy` as the sibling grains, and `normalizeList`'s `keepInclude` filter diverts the
# record out of the aspect walk (never content).
#
# Witnesses: (1) a record DIRECTLY in an aspect's `.includes` — no §2.2 abort, the rule registers, FIRES
# at the formals-satisfying scope, and its include-effect content lands; (2) TRANSITIVE depth (the
# battery shape — record nested inside a static include's `.includes`), plus the corpus's spawn-emitting
# record resolving clean at a (user,host) cell; (3) the sibling grains' behavior is pinned by their own
# suites (compat-default-include-policy / compat-kindinclude / compat-scope-local-firing — the unchanged
# baseline IS the witness); (4) a MALFORMED fn-bearing NON-policy attrset (no `__isPolicy`) still grounds
# and aborts LOUD at §2.2 (never a silent drop).
{ denCompat, ... }:
let
  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;
  forceEdges = f: builtins.concatMap (r: f.den.graph.edges r) (builtins.attrNames f.den.scopeRoots);

  # every `tag` string reachable in a wrapped deferredModule (the gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];
  termTags =
    fleet: id: class:
    builtins.concatMap tags (fleet.den.output.systems.${class}.${id}.modules or [ ]);

  # ── (1) DIRECT: a policy record in a regular aspect's `.includes`. The record's include-effect edges
  # the `injected` aspect at the firing scope, so its nixos content landing at the host terminal PROVES
  # the rule fired (v1: register at the walking scope + fire gated on `{ host, ... }`).
  directDecls = {
    hosts.x86_64-linux.igloo.class = "nixos";
    aspects.injected.nixos.tag = "injected-by-policy";
    aspects.carrier = {
      nixos.tag = "carrier-own";
      includes = [
        {
          __isPolicy = true;
          name = "test-project";
          fn =
            { host, ... }:
            [
              {
                __policyEffect = "include";
                value = {
                  name = "injected";
                };
              }
            ];
        }
      ];
    };
    schema.host.includes = [ "carrier" ];
  };
  direct = denCompat.mkDen [ { den = directDecls; } ];
  directCompiled = denCompat.compile directDecls;

  # ── (2) TRANSITIVE: the battery shape — the record rides a NAMED static include's own `.includes`
  # (exactly `den.aspects.sini.includes = [ den.batteries.host-aspects ]`), PLUS the corpus's actual
  # spawn-emitting body (`{ host, user, ... }: [ spawn { classes } ]`, v1 batteries/host-aspects.nix)
  # firing at a (user,host) cell — the cell resolves clean and the spawn parks childless-inert (the u4
  # posture; fleetChildren is membership-driven).
  transitiveDecls = {
    hosts.x86_64-linux.igloo = {
      class = "nixos";
      users.tux = { };
    };
    schema.user.parent = "host";
    aspects.injected.nixos.tag = "injected-by-policy";
    aspects.carrier = {
      includes = [
        {
          name = "battery";
          includes = [
            {
              __isPolicy = true;
              name = "battery-project";
              fn =
                { host, ... }:
                [
                  {
                    __policyEffect = "include";
                    value = {
                      name = "injected";
                    };
                  }
                ];
            }
            {
              __isPolicy = true;
              name = "spawn-project";
              fn =
                { host, user, ... }:
                [
                  {
                    __policyEffect = "spawn";
                    value = {
                      classes = [ "home-manager" ];
                    };
                  }
                ];
            }
          ];
        }
      ];
    };
    schema.host.includes = [ "carrier" ];
  };
  transitive = denCompat.mkDen [ { den = transitiveDecls; } ];
  transitiveCompiled = denCompat.compile transitiveDecls;

  # ── (4) MALFORMED: an fn-bearing attrset WITHOUT `__isPolicy`/`__denCanTake` is NOT a policy record —
  # it grounds as static content and its `fn` key aborts §2.2 LOUD (the preserved posture).
  malformed = denCompat.mkDen [
    {
      den = {
        hosts.x86_64-linux.igloo.class = "nixos";
        aspects.carrier = {
          nixos.tag = "x";
          includes = [
            {
              name = "not-a-policy";
              fn = _: { };
            }
          ];
        };
        schema.host.includes = [ "carrier" ];
      };
    }
  ];

  # ── (5) FN-VALUED REGISTERED QUIRK on an include record: a channel key whose value is a `{ ctx… }:
  # <content>` PRODUCER rides an include record. A fn key on an include record aborts §2.2 UNLESS it
  # names a registered class facet, is a `{ __isPolicy }` diversion — OR names a REGISTERED QUIRK CHANNEL
  # (the third exemption). A quirk channel body may be fn-valued: v1 materializes it unconditionally and
  # the channel-gather seam binds it fn-and-all. So §2.2 must ACCEPT it and the resolved fragment reaches
  # the channel binding. Two quirk keys ride ONE record: an `{ host, … }` producer resolved at the host
  # scope (its delivered fragment asserted), and a `{ config, … }` config-thunk sibling — the deferred
  # path — which must clear the SAME gate (its local binding forces clean, no cross-scope collect).
  quirkDecls = {
    hosts.x86_64-linux.igloo.class = "nixos";
    quirks.age-secrets = { };
    quirks.k8s-manifests = { };
    aspects.carrier = {
      nixos.tag = "carrier-own";
      includes = [
        {
          name = "bootstrap";
          age-secrets = { host, ... }: [ "age-for-${host.name}" ];
          k8s-manifests = { config, ... }: [ "manifests" ];
        }
      ];
    };
    schema.host.includes = [ "carrier" ];
  };
  quirkFleet = denCompat.mkDen [ { den = quirkDecls; } ];
  bindingsOf =
    fleet: cls: id:
    fleet.den.output.systems.${cls}.${id}.bindings;

  # ── (6) NESTED-NAME COLLISION: the aspect-include collection walk's cycle-break `seen` set must key on
  # the structural, path-unique `.key` — NOT the non-unique `.name`. A per-host `<host>.<user>` sub-aspect
  # legitimately shares its `.name` with the top-level `<user>` aspect (the corpus's
  # `den.aspects.blade.sini` beside `den.aspects.sini`). Here `blade.sini` (name `"sini"`, key
  # `blade/sini`) is walked BEFORE the top-level `sini` (name `"sini"`, key `sini`) — `blade` < `sini`.
  # A name-keyed seen-set poisons `"sini"` at the sub-aspect and SKIPS the top-level aspect's includes, so
  # the `{ __isPolicy }` record it carries is never collected and `normalizeList`'s `keepInclude` aborts
  # NAMED at resolution. Key-first cycle-breaking (v1 registers aspects by `identity.key`, children.nix)
  # distinguishes the two nodes: the record diverts + FIRES, no abort. Must run the TYPED path
  # (`compileFull` — the nodes carry native `.key` there; the raw `compile` path has neither name nor key
  # so `idOf = null` and never collides). `blade`/`blade.sini` carry own class bodies but are unattached
  # (only `sini` is host-included), so ONLY the fired include-effect content lands at the terminal.
  collisionDecls = {
    hosts.x86_64-linux.igloo.class = "nixos";
    aspects.injected.nixos.tag = "injected-by-policy";
    aspects.sini.includes = [
      {
        __isPolicy = true;
        name = "collision-project";
        fn =
          { host, ... }:
          [
            {
              __policyEffect = "include";
              value = {
                name = "injected";
              };
            }
          ];
      }
    ];
    aspects.blade = {
      nixos.tag = "blade-own";
      sini.nixos.tag = "blade-sini-own";
    };
    schema.host.includes = [ "sini" ];
  };
  collision = denCompat.mkDen [ { den = collisionDecls; } ];
  collisionCompiled = denCompat.compileFull collisionDecls;

  igloo = "host:igloo";
in
{
  flake.tests.compat-aspect-include-policy = {
    # (1) the record never grounds to content (no §2.2 `fn` abort), its rule REGISTERS under the reserved
    # `__aspectInclude__` name (the compiled policies set), and it FIRES at the host (the `{ host, ... }`
    # formals gate) — the injected aspect's content lands at the terminal beside the carrier's own.
    test-direct-record-diverts-and-fires = {
      expr = {
        forces = ok (forceEdges direct);
        ruleRegistered = directCompiled.policies ? __aspectInclude__test-project;
        terminal = termTags direct igloo "nixos";
      };
      expected = {
        forces = true;
        ruleRegistered = true;
        # the policy-EDGED aspect resolves before the kind-included carrier's own content (edge order);
        # both land — the landing set, not the order, is this witness's claim.
        terminal = [
          "injected-by-policy"
          "carrier-own"
        ];
      };
    };

    # (2) transitive depth (the battery shape): both nested records divert (no abort), the include-effect
    # record fires (content lands), the spawn record fires at the (user,host) cell and parks
    # childless-inert (no spawn-fabricated node — the host system still builds, sole nixos terminal).
    test-transitive-battery-shape = {
      expr = {
        forces = ok (forceEdges transitive);
        rules = {
          battery = transitiveCompiled.policies ? __aspectInclude__battery-project;
          spawn = transitiveCompiled.policies ? __aspectInclude__spawn-project;
        };
        injected = builtins.elem "injected-by-policy" (termTags transitive igloo "nixos");
        nixosConfigs = builtins.attrNames (transitive.nixosConfigurations or { });
      };
      expected = {
        forces = true;
        rules = {
          battery = true;
          spawn = true;
        };
        injected = true;
        nixosConfigs = [ "igloo" ];
      };
    };

    # (3) the sibling grains are pinned by their own suites (compat-default-include-policy /
    # compat-kindinclude / compat-scope-local-firing) — asserted here only as a cross-reference: the new
    # arm adds EXACTLY its own `__aspectInclude__` names, and the fixture's kind-include grain still
    # produces EXACTLY its `__kindInclude__host` edge policy (the `schema.host.includes = [ "carrier" ]`
    # static ref) — disjoint reserved namespaces, neither grain perturbing the other.
    test-grain-namespaces-disjoint = {
      expr = {
        aspectIncludeNames = builtins.filter (n: builtins.substring 0 17 n == "__aspectInclude__") (
          builtins.attrNames directCompiled.policies
        );
        kindArmNames = builtins.filter (n: builtins.substring 0 15 n == "__kindInclude__") (
          builtins.attrNames directCompiled.policies
        );
      };
      expected = {
        aspectIncludeNames = [ "__aspectInclude__test-project" ];
        kindArmNames = [ "__kindInclude__host" ];
      };
    };

    # (4) a malformed fn-bearing NON-policy attrset still aborts LOUD at §2.2 (grounds as content, the
    # `fn` key is unregistered) — the diversion admits ONLY `{ __isPolicy }`/`{ __denCanTake }` records.
    test-malformed-fn-attrset-still-aborts = {
      expr = !(ok (forceEdges malformed));
      expected = true;
    };

    # (5) a fn-valued key naming a REGISTERED quirk channel is ACCEPTED (no §2.2 abort) and its resolved
    # fragment reaches the channel binding. The `{ host, … }` producer resolves at the host; the
    # `{ config, … }` config-thunk sibling clears the SAME gate (local binding forces clean).
    test-fn-valued-quirk-accepted-and-delivered = {
      expr = {
        compiles = ok (forceEdges quirkFleet);
        ageSecrets = (bindingsOf quirkFleet "nixos" igloo).age-secrets;
        k8sManifests = ok (bindingsOf quirkFleet "nixos" igloo).k8s-manifests;
      };
      expected = {
        compiles = true;
        ageSecrets = [ "age-for-igloo" ];
        k8sManifests = true;
      };
    };

    # (6) a top-level aspect NAME-shadowed by an earlier-walked nested `<host>.<user>` sub-aspect still has
    # its `{ __isPolicy }` include COLLECTED (`__aspectInclude__collision-project` registers), DIVERTED (no
    # `keepInclude` abort — `forces` clean), and FIRED (the injected content lands at the host). RED before
    # the walk keys its cycle-break seen-set by `.key`: the name-keyed seen-set skips the top-level aspect
    # and the record aborts NAMED (forces = false, rule absent).
    test-nested-name-collision-diverts-and-fires = {
      expr = {
        forces = ok (forceEdges collision);
        ruleRegistered = collisionCompiled.policies ? __aspectInclude__collision-project;
        terminal = termTags collision igloo "nixos";
      };
      expected = {
        forces = true;
        ruleRegistered = true;
        terminal = [ "injected-by-policy" ];
      };
    };
  };
}
