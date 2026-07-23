# The v1 `den.lib.canTake` arity predicate (den v1 nix/lib/can-take.nix): does a fn ACCEPT a given
# param set? `atLeast` (the __functor default) = every required arg is supplied; `exactly` = the
# supplied set equals the fn's arg set; `upTo` = satisfied AND at least one supplied arg is consumed.
# den-hoag's substrate is nixpkgs-lib-free, so this closes over gen-prelude's `isFunction`/`functionArgs`
# (= `builtins.isFunction`/`builtins.functionArgs`) + `builtins.intersectAttrs` — the same primitives v1's
# nixpkgs `lib` wrapped. NOTE: `builtins.functionArgs` is NOT functor-aware (v1 `lib.functionArgs` was);
# no reachable consumer exercises the functor case, so the divergence is a dead gap.
{ prelude, ... }:
let
  canTake =
    params: func:
    let
      valid = prelude.isFunction func && builtins.isAttrs params;
      args = prelude.functionArgs func;
      required = builtins.filter (n: !args.${n}) (builtins.attrNames args);
      intersect = builtins.intersectAttrs args params;
      satisfied = valid && builtins.all (n: params ? ${n}) required;
    in
    {
      satisfied = satisfied;
      exactly = valid && required == builtins.attrNames params;
      upTo = satisfied && intersect != { };
    };
in
{
  __functor = self: self.atLeast;
  atLeast = params: func: (canTake params func).satisfied;
  exactly = params: func: (canTake params func).exactly;
  upTo = params: func: (canTake params func).upTo;
}
