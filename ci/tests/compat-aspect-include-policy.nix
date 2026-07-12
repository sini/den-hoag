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
  };
}
