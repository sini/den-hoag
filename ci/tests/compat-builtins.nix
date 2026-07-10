# Built-in provisioning + the exclude-of-policy split (ship-gate). The compat built-in-provisioning module
# (lib/compat/builtins.nix, wired into the flakeModule) presents v1's built-in policies at their v1
# attrpaths; these witnesses pin the shim MECHANISMS that provisioning relies on — the inert never-emitting
# policy (host-to-users), the named throwing stub (flake-output built-ins), and the two halves of
# `policy.exclude` on a POLICY-valued ref (schema-level no-op vs effect-level named class-B abort). The
# end-to-end provisioning (the corpus's `den.policies.system-to-flake-parts` reference resolving) is
# validated by the ship-gate corpus re-probe; these are the unit-level mechanism pins.
{ denCompat, ... }:
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
    # tryEval-caught into expansion), but FIRING at a real node surfaces the named message.
    test-output-stub-fires-named-throw = {
      expr =
        let
          c = denCompat.compile { policies.systemToFlakeParts = _ctx: throw "class-F/G stub"; };
        in
        {
          exists = c.policies.systemToFlakeParts ? fn;
          firesThrows =
            (builtins.tryEval (builtins.deepSeq (c.policies.systemToFlakeParts.fn { }) null)).success;
        };
      expected = {
        exists = true;
        firesThrows = false;
      };
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
