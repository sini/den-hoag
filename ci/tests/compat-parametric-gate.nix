# The parametric-result gate (design §9.5). A parametric aspect's RESULT is materialized at RESOLUTION
# (resolved-aspects.nix `aspect ctx`), NOT run through the compile-time closed-gated typed tree — so a typo in
# a parametric body reaches content un-gated unless the resolver re-gates it. `grndDispatch`'s content
# terminals normalize the fired result to the static pre-gate shape via `translateAspect` (droppedAspectKeys
# drop + excludes→meta.drop fold + provides sentinel), THEN type it through the SAME closed gate the compile
# view uses (lib/compat/gated-aspects-type.nix), so gated-parametric-shape == gated-static-shape. The gate is a
# VALIDATION seq: a typo throws NAMED at the gate at resolution; a valid result rides through unchanged.
# Theory: scope-as-type (Néron/Tolmach/Visser/Wachsmuth 2015) — a name resolving to no declaration in the
# aspect scope is a type error at that scope; the parametric result is a fresh scope closed the same way.
{ denCompat, ... }:
let
  # A parametric aspect compiles to a `__isWrappedFn` functor; firing it with a coordinate ctx routes its
  # result through `grndDispatch` → `translateAspect` → the gate. The ctx carries the entity coords a
  # `{ host, ... }:` body binds (empty stand-ins suffice — the witnesses key on class/typo keys, not values).
  fire =
    body:
    let
      para =
        (denCompat.compile {
          aspects.p = body;
          hosts.x86_64-linux.h.class = "nixos";
        }).aspects.p;
    in
    para {
      host = { };
      user = { };
      settings = { };
      aspects = { };
    };
  forced = body: builtins.tryEval (builtins.deepSeq (fire body) true);

  # The STATIC twin of the excludes witness — the same `excludes` on a non-parametric aspect, lowered by the
  # SAME `translateAspect`. The parametric drop must equal this by construction (one desugar path).
  staticDrop =
    ((denCompat.compile {
      aspects.s = {
        nixos.x = true;
        excludes = [ "sib" ];
      };
      hosts.x86_64-linux.h.class = "nixos";
    }).aspects.s
    ).meta.drop or "NONE";
  parametricDrop =
    (fire (
      { host, ... }:
      {
        nixos.x = true;
        excludes = [ "sib" ];
      }
    )).meta.drop or "NONE";
in
{
  flake.tests.compat-parametric-gate = {
    # A typo in a parametric body (an undeclared non-attrset leaf) throws NAMED at the gate at resolution —
    # the sole typo boundary for parametric content (the compile-time typed tree never sees the fired result).
    test-parametric-typo-throws-at-gate = {
      expr = (forced ({ host, ... }: { homeManagr = "x"; })).success;
      expected = false;
    };
    # A valid parametric result (declared class content) rides through the gate unchanged — byte-neutral.
    test-parametric-valid-admits = {
      expr = (forced ({ host, ... }: { nixos.networking.hostName = "h"; })).success;
      expected = true;
    };
    # A legit nested aspect inside a parametric result is admitted (recursive-closed: an undeclared attrset
    # child is a namespace that recurses, not a flat reject), not gate-rejected.
    test-legit-nested-in-parametric-admits = {
      expr =
        (forced (
          { host, ... }:
          {
            nixos.networking.hostName = "h";
            kid.nixos.x = 1;
          }
        )).success;
      expected = true;
    };
    # A parametric result carrying `excludes` lowers to `meta.drop` IDENTICALLY to the static path (both route
    # through the one `translateAspect` fold) — recognition ⟂ lowering, the §9.3 must-fix.
    test-parametric-excludes-lowers-to-meta-drop-identical-to-static = {
      expr = {
        inherit parametricDrop staticDrop;
        identical = parametricDrop == staticDrop;
      };
      expected = {
        parametricDrop = [ "sib" ];
        staticDrop = [ "sib" ];
        identical = true;
      };
    };
  };
}
