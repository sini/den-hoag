let
  prelude = import ./lib/prelude/default.nix;
  dispatch = import ./lib/dispatch.nix { inherit prelude; };
  setFunctionArgs = f: args: {
    __functor = self: f;
    __functionArgs = args;
  };
  policyFn = setFunctionArgs (ctx: ctx) { host = false; };
  rule = dispatch.fromFunction policyFn;
in
rule.produce "id1" { host = { name = "foo"; }; }
