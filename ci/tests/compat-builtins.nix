# Built-in provisioning + the exclude-of-policy split (ship-gate). The compat built-in-provisioning module
# (lib/compat/builtins.nix, wired into the flakeModule) presents v1's built-in policies at their v1
# attrpaths; these witnesses pin the shim MECHANISMS that provisioning relies on — the inert never-emitting
# policy (host-to-users), the v1-`{ system, ... }`-GATED throwing stub (flake-output built-ins), and the two
# halves of `policy.exclude` on a POLICY-valued ref (schema-level no-op vs effect-level named class-B abort).
# The end-to-end provisioning (the corpus's `den.policies.system-to-flake-parts` reference resolving) is
# validated by the ship-gate corpus re-probe; these are the unit-level mechanism pins.
{ denHoag, denCompat, ... }:
let
  I = denHoag.internal;
  inherit (I)
    structural
    runResolve
    parseParent
    ;

  # A gated flake-output stub, SHAPE-IDENTICAL to lib/compat/builtins.nix `outputStub`: v1's OWN formals
  # `{ system, ... }:` (verbatim from the pin — system-to-flake-parts flake-parts.nix:9-10, system-to-os/hm-
  # outputs flake.nix:53-54/67-68) over the named class-F/G throw. den-hoag reads the fn's `functionArgs` as
  # the fleet-wide dispatch gate (compile.nix `compiledPolicies` → `policies`), so this gate is what bounds
  # the firing — `{ system = false; }` fires ONLY where a `system` flake-system coord is bound.
  stubMsg =
    "den-compat builtin: `den.policies.system-to-flake-parts` is a v1 flake-OUTPUT policy "
    + "(modules/policies/flake-parts.nix:9 @ pin 11866c16); its firing populates flake outputs — class F/G.";
  gatedStub =
    { system, ... }:
    throw stubMsg;
  compiledStub =
    (denCompat.compile { policies.systemToFlakeParts = gatedStub; }).policies.systemToFlakeParts;

  # The stub through concern-policies → gen-dispatch rules (the value-less probe tryEval-catches the throw →
  # expansion, so it compiles to a policy sub-rule gated on `{ system = false; }`), driven through the REAL
  # structural `declarations` dispatch (attr 4) over a hand-built root — exactly the corpus firing path.
  stubRules = I.compilePolicies { systemToFlakeParts = compiledStub; };
  ent = k: {
    id_hash = k;
    name = k;
  };
  buildAt =
    roots:
    runResolve {
      inherit roots parseParent;
      equations = structural {
        policiesRules = {
          inherit (stubRules) enrich policy;
        };
        fleetChildren = _self: _id: { };
      };
    };
  # (a) a HOST root — ctx coords are the fleet product dims (host/…), NO top-level `system` key.
  hostRoots = {
    "host:h" = {
      id = "host:h";
      type = "host";
      parent = null;
      decls = {
        host = ent "h";
        __entry = ent "h";
      };
    };
  };
  hostDecls = (buildAt hostRoots).eval.get "host:h" "declarations";
  # (b) a SYNTHETIC flake-system node whose ctx CARRIES the `system` gate coord (v1's flake-system binding,
  #     flake.nix:50 `resolve.to "flake-system" { inherit system; }`) — the one place v1's gate would fire.
  systemRoots = {
    "flake-system:s" = {
      id = "flake-system:s";
      type = "flake-system";
      parent = null;
      decls = {
        system = ent "x86_64-linux";
        __entry = ent "s";
      };
    };
  };
  systemDecls = (buildAt systemRoots).eval.get "flake-system:s" "declarations";
in
{
  flake.tests.compat-builtins = {
    # host-to-users PROVIDE inert: a `_ctx: [ ]` policy (v1 core.nix:17 host→user resolution the corpus opts
    # OUT of) produces ZERO declarations — den-hoag resolves host→user structurally, so the built-in never
    # emits; it exists only to satisfy the `den.schema.host.excludes` reference.
    test-inert-policy-zero-declarations = {
      expr = builtins.length (
        (denCompat.compile { policies.hostToUsers = _ctx: [ ]; }).policies.hostToUsers.fn { }
      );
      expected = 0;
    };

    # A corpus policy alongside the inert built-in still compiles (env-users unaffected): the inert built-in
    # does not perturb the other policies.
    test-inert-alongside-other-policy = {
      expr =
        let
          c = denCompat.compile {
            aspects.a = { };
            policies.hostToUsers = _ctx: [ ];
            policies.envUsers = _ctx: [
              {
                __policyEffect = "include";
                value = {
                  name = "a";
                };
              }
            ];
          };
        in
        {
          hostToUsers = c.policies.hostToUsers ? fn;
          envUsers = builtins.length (c.policies.envUsers.fn { });
        };
      expected = {
        hostToUsers = true;
        envUsers = 1;
      };
    };

    # Named throwing stub (flake-output built-in): exists (compiles, no probe-time hard fail — the throw is
    # tryEval-caught into expansion), and its compiled gate IS v1's OWN destructuring `{ system, ... }` →
    # `functionArgs` → `__condition = { system = false; }` (flake-parts.nix:9-10 / flake.nix:53-54,67-68 @
    # pin 11866c16). This is the FIX: the fleet-wide compiled rule (compile.nix `compiledPolicies`) now
    # carries v1's gate, not the empty `_ctx:` condition that fired at every node.
    test-output-stub-condition-is-v1-system-gate = {
      expr = {
        exists = compiledStub ? fn;
        condition = compiledStub.__condition;
      };
      expected = {
        exists = true;
        condition = {
          system = false;
        };
      };
    };

    # FIRING (gate coord present) surfaces the named message: calling the compiled `fn` with the `system`
    # coord bound satisfies the formal, then the body throws its class-F/G message (self-announcing).
    test-output-stub-fires-named-throw = {
      expr =
        (builtins.tryEval (builtins.deepSeq (compiledStub.fn { system = ent "x86_64-linux"; }) null))
        .success;
      expected = false;
    };

    # GATED-INERT AT HOST (the fires-everywhere regression pin, ledger u3 / board #57): a host node's ctx
    # carries NO top-level `system` coord (its coords are the fleet product dims), so the `{ system = false; }`
    # -gated stub NEVER fires through the REAL `declarations` dispatch → the host resolves CLEAN (no throw).
    # Pre-fix the empty `_ctx:` gate made the fleet-wide rule fire at EVERY node incl. host class-modules.
    test-output-stub-gated-inert-at-host = {
      expr = (builtins.tryEval (builtins.deepSeq hostDecls null)).success;
      expected = true;
    };

    # SELF-ANNOUNCEMENT PRESERVED: a node whose ctx carries the `system` coord (v1's flake-system node) MATCHES
    # the gate → the stub FIRES its named throw through the same `declarations` dispatch. So the stub is inert
    # by DEMAND (corpus spawns no flake-system node), loud where v1's gate would genuinely fire.
    test-output-stub-fires-at-system-node = {
      expr = (builtins.tryEval (builtins.deepSeq systemDecls null)).success;
      expected = false;
    };

    # ADDITION 1b — EFFECT-level `policy.exclude` of a POLICY record (`__denCanTake`/`__isPolicy`/function)
    # aborts NAMED (class-B / #50), never the misleading identity-law abort at resolveAspectRef.
    test-effect-exclude-of-policy-named-abort = {
      expr =
        let
          c = denCompat.compile {
            policies.dropRoute = _ctx: [
              {
                __policyEffect = "exclude";
                value = {
                  __denCanTake = "user-host";
                  fn = _c: [ ];
                };
              }
            ];
          };
        in
        (builtins.tryEval (builtins.deepSeq (c.policies.dropRoute.fn { }) null)).success;
      expected = false;
    };

    # ADDITION 1b (other half): an ASPECT exclude still prunes (drop) — the policy-target re-route does not
    # break aspect excludes.
    test-effect-exclude-of-aspect-drops = {
      expr =
        let
          c = denCompat.compile {
            aspects.a = { };
            policies.dropAspect = _ctx: [
              {
                __policyEffect = "exclude";
                value = {
                  name = "a";
                };
              }
            ];
          };
        in
        (builtins.head (c.policies.dropAspect.fn { })).__action;
      expected = "drop";
    };

    # ADDITION 1a — SCHEMA-level `den.schema.<kind>.excludes` with a POLICY-valued ref does NOT abort at
    # ingest (class-A ingests the host schema): the shim does not force a kind-exclude ref through
    # resolveAspectRef, so a policy-valued exclude is a no-op; the fleet compiles.
    test-schema-policy-valued-exclude-noop = {
      expr =
        (builtins.tryEval (
          builtins.deepSeq
            (denCompat.compile {
              policies.hostToUsers = _ctx: [ ];
              schema.gadget = {
                parent = "host";
                excludes = [ (_ctx: [ ]) ];
              };
              gadget.g1 = { };
            }).policies
            null
        )).success;
      expected = true;
    };
  };
}
