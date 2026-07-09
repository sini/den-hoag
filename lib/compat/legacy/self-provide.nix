# den-compat LEGACY surface: `self-provide` (self-contained, tagged — the severance surface, §2.1).
#
# R5 (spec §10) — SELF-NAMED-ASPECT AUTO-INCLUDE. v1 `nix/lib/resolve-entity.nix:48-63`: when an
# entity scope is named `n`, v1's `resolveEntity` injects a synthetic self-provide include —
#
#   • `n == "default"` and `den ? default`  →  include `den.default` (the __default aspect here);
#   • else an aspect named `n` exists         →  inject `<self:${n}>` with body `ctx.${n}.aspect or { }`
#     (the arg `n` marked non-required), i.e. include the aspect NAMED `n` at that entity's own scope.
#
# This is the mechanism by which `den.aspects.<host> = { nixos.… }` lands on the host NAMED `<host>`
# (the dominant v1 idiom — a per-host aspect keyed by the host's own name). Without it, den-hoag's
# host:igloo carries an EMPTY nixos bucket (the aspect `igloo` resolves nowhere), so its producing-class
# default fold emits nothing — the L3/L5 divergence (parity/ledger.md). With it, the aspect resolves at
# its self-named entity, the bucket is non-empty, and the `collected:host:igloo/nixos | merge` fold edge
# byte-matches v1's (the L6/classFold mechanism, now reached without an explicit kind-include).
#
# PURE + SEVERABLE (Law C2 / C5): the desugar is a structural NAME OVERLAP — entity instance names ∩
# aspect names — computed off the COMPILED output (registries + aspect records), reading no scope graph
# and no resolved state. It emits den-hoag `den.include` records (`{ at = <entity entry>; aspects = [
# <aspect record> ]; }`, the §370 `directAspects` seed), node-local at exactly the self-named entity —
# NOT a kind-wide radiation. flakeModuleCore alone (this module severed from the wiring's legacy set)
# emits no self-includes: a byte-identical no-op, never an error (unlike provides/forwards, a self-named
# aspect leaves no residual KEY to sentinel — its absence just means the aspect resolves nowhere, exactly
# as a v1 config without the resolve-entity injection would).
{
  prelude,
  ...
}:
let
  # The reserved compiled name of `den.default` (compile.nix `defaultAspects`): a `default`-named entity
  # includes it, mirroring v1 resolve-entity.nix:49 (`n == "default" && den ? default`).
  defaultAspectName = "__default";
in
{
  _denCompat.legacy = "self-provide";

  # selfIncludesOf { compiled, aspectEntry } → [ den.include record ]. `compiled` is the compile core's
  # output (entities.registries / entities.instances / aspects); `aspectEntry name` is ingest.nix's
  # id_hash convention (`{ id_hash = sha256("den-aspect:<name>"); name; }`) so the emitted aspect record
  # is BYTE-IDENTICAL to the one a `neededBy`/`policy.include` inclusion carries (compile.nix
  # `resolveAspectRef` / `aspectRec`: content `// aspectEntry name`) — dedup-coherent, A2-valid.
  selfIncludesOf =
    {
      compiled,
      aspectEntry,
    }:
    let
      aspects = compiled.aspects or { };
      registries = compiled.entities.registries or { };
      hasDefault = aspects ? ${defaultAspectName};
      # The full aspect record den-hoag's resolution consumes: compiled content + its identity.
      mkFull = name: (aspects.${name} or { }) // aspectEntry name;
      # One kind's self-named includes: for every registered instance whose name also names an aspect
      # (or the `default` special case), a node-local include at that instance's own entry.
      perKind =
        kind:
        let
          reg = registries.${kind} or { };
        in
        prelude.concatMap (
          name:
          if aspects ? ${name} then
            [
              {
                at = reg.${name};
                aspects = [ (mkFull name) ];
              }
            ]
          else if name == "default" && hasDefault then
            [
              {
                at = reg.${name};
                aspects = [ (mkFull defaultAspectName) ];
              }
            ]
          else
            [ ]
        ) (builtins.attrNames reg);
    in
    prelude.concatMap perKind (builtins.attrNames registries);
}
