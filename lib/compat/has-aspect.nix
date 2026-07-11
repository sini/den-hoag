# THE PROJECTED hasAspect ENTITY SURFACE (v1 PR #602 semantics; the den-hoag dissolution).
#
# v1 stamps a SHARED projected `hasAspect` onto every entity-kind ctx binding at the CONSUMING scope
# (pin sg0zid…-source nix/lib/aspects/fx/policy/schema.nix:88-96 — one `mkProjectedHasAspect` answers for
# the active scope's re-keyed bucket, so `host`/`user`/… all read "is X delivered into THIS scope"). The
# membership test is `refKey ref ∈ pathSet` with the THREE-branch `refKey` law (has-aspect.nix:7-16):
# name+meta → `pathKey(aspectPath ref)`; `__provider` → `pathKey ref.__provider`; else a NAMED throw
# (never a silent false). The surface is class-invariant (`{ __functor; forClass; forAnyClass; }`,
# :56-65).
#
# THE DISSOLUTION (v2). den-hoag has NO re-key machinery and no per-scope path-set bucket: a node's
# resolved-aspects (attribute 7) IS the projected set for that node — the deduped `[ { key; content; } ]`
# list whose keys are exactly `gen-aspects.key` of every aspect delivered into the node. So the projected
# hasAspect is a pure lookup over the node's OWN resolved-aspects entry keys, keyed by `refKey` — the same
# `gen-aspects.key` identity, so the ref and the resolved node agree BY CONSTRUCTION (both grounded through
# the SAME `stampProvider`, see stamp-provider.nix; W2 pins it).
#
# THE MATCHING LAW. `refKey ref` recovers the identity the corpus reads a `den.aspects.<path>` value with:
# a NAVIGATED value off the annotated `den` arg carries `__provider` (annotate.nix), so it takes the
# `__provider` branch = `key (stampProvider ref)` = `pathKey ref.__provider`; a value read straight off the
# compiled REGISTRY carries name+meta, the name+meta branch = `key ref`. Both equal the resolved node's key
# (which `resolved-aspects.nix` computed as `keyOf concrete` over the SAME `stampProvider` grounding).
#
# THE CENSUS (nix-config b0b20769): 13 reads, all `host.hasAspect den.aspects.<path>`, all in
# delivery-depth nixos aspect bodies (networking.nix:341 `core.network.manager`, gpg.nix:80/bitwarden.nix:39
# `roles.*`, steam.nix:13 / hardware/*, disk/impermanence guards), all HARD (an `attribute 'hasAspect'
# missing` at the binding if absent). The corpus reads only `host.hasAspect`; the surface stamps EVERY
# entity-kind binding (v1-faithful) so `user`/`cluster` reads resolve too.
#
# LAZINESS (A17 — load-bearing). `refKey`, `seen`, and the projected closures are built INSIDE `mkHas`'s
# body: forcing the enriched bindings (the terminal binding spine, even under deepSeq) only forces the
# stamped attrsets to lambdas — it NEVER forces `resolvedAspects`. Only CALLING a `hasAspect` closure forces
# `seen` (hence resolved-aspects). So the entity-stamp never re-enters the resolve that produced it (W4).
{
  aspects,
  stampProvider,
}:
let
  inherit (aspects) key; # gen-aspects identity: pathKey(aspectPath) for a name+meta / stampProvider'd value.

  # v1's FULL three-branch refKey law (has-aspect.nix:7-16 @ pin). NEVER a silent false: an unresolvable
  # ref shape aborts NAMED (the message names the requirement), so a mistyped `hasAspect <x>` self-announces.
  refKey =
    ref:
    if builtins.isAttrs ref && (ref ? name) && (ref ? meta) then
      key ref
    else if builtins.isAttrs ref && (ref ? __provider) then
      # A nested/navigated aspect value from the annotated `den` arg (annotate.nix sets `__provider`, not
      # name/meta). `stampProvider` derives name = last / aspect-chain = init, so `key` = `pathKey __provider`
      # — the SAME identity the include-grounding path stamps (stamp-provider.nix; the by-construction match).
      key (stampProvider ref)
    else
      throw "hasAspect: ref must have `name`+`meta` or `__provider` (got ${builtins.typeOf ref}).";
in
{
  inherit refKey;

  # The POST-RESOLUTION binding-enrichment hook (the compat `den.enrichBindings` value). `entityKinds` is
  # the schema entity-kind set (the fleet's `den.schema` kind names) baked at bridge-assembly time; the
  # returned hook is threaded onto `bindingsAt` (output-modules.nix). Per node it stamps a SHARED projected
  # `hasAspect` onto every entity-kind binding whose value is an attrset — v1's `overrideKinds` filter
  # (schema.nix:77-79: `schemaEntityKindsSet ? k && isAttrs ctx.k`). `secretsConfig`/`fleet`/channel bindings
  # are NOT schema kinds ⇒ never stamped.
  mkEnrich =
    entityKinds:
    # The core hook contract is `{ id, resolvedAspects, bindings }`; `id` rides in the `...` — the node's
    # OWN resolved-aspects IS the active/consuming scope (the v2 dissolution of v1's shared-scope re-key),
    # so the lookup never needs it.
    {
      resolvedAspects,
      bindings,
      ...
    }:
    let
      # LAZY keyset from the node's resolved-aspects entry keys (attribute 7 = the projected set). Captured
      # in `mkHas`'s closure; `resolvedAspects` is a THUNK, forced ONLY when a hasAspect closure is called
      # (A17).
      seen = builtins.foldl' (acc: n: acc // { ${n.key} = true; }) { } resolvedAspects;
      mkHas = ref: seen ? ${refKey ref};
      # v1's class-invariant surface shape (schema.nix:56-65 / mkProjectedHasAspect): the structural set is
      # class-invariant, so every arm is the same `mkHas`.
      projected = {
        __functor = _: mkHas;
        forClass = _class: mkHas;
        forAnyClass = mkHas;
      };
      stampKinds = builtins.filter (k: (entityKinds ? ${k}) && builtins.isAttrs (bindings.${k} or null)) (
        builtins.attrNames bindings
      );
    in
    bindings
    // builtins.listToAttrs (
      map (k: {
        name = k;
        value = bindings.${k} // {
          hasAspect = projected;
        };
      }) stampKinds
    );
}
