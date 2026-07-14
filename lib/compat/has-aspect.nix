# THE PROJECTED hasAspect ENTITY SURFACE (v1 PR #602 semantics; the den-hoag dissolution).
#
# v1 stamps a SHARED projected `hasAspect` onto every entity-kind ctx binding at the CONSUMING scope
# (pin sg0zid…-source nix/lib/aspects/fx/policy/schema.nix:88-96 — one `mkProjectedHasAspect` answers for
# the active scope's re-keyed bucket, so `host`/`user`/… all read "is X delivered into THIS scope"). The
# membership test is `refKey ref ∈ pathSet`; under A-IDENT (Task 3) `refKey` is a SINGLE native-`.key`
# lookup + a NAMED throw for a keyless ref (never a silent false). The surface is class-invariant
# (`{ __functor; forClass; forAnyClass; }`).
#
# THE DISSOLUTION (v2). den-hoag has NO re-key machinery and no per-scope path-set bucket: a node's
# resolved-aspects (attribute 7) IS the projected set for that node — the deduped `[ { key; content; } ]`
# list whose keys are exactly `gen-aspects.key` of every aspect delivered into the node. So the projected
# hasAspect is a pure lookup over the node's OWN resolved-aspects entry keys, keyed by `refKey` — the same
# `gen-aspects.key` identity, so the ref and the resolved node agree BY CONSTRUCTION (W2 pins it).
#
# THE MATCHING LAW (Task 3 — native identity). `refKey ref` = `ref.key`: under A-IDENT every
# `den.aspects.<path>` value carries its OWN container-relative `.key` (born in gen-aspects' type). A
# NAVIGATED value off the `den` arg (the shim binds the NAVIGATION view — flake-module.nix `bindLegacyEnv →
# annotatedViewNav`) AND a value read straight off the compiled REGISTRY both carry `.key`, and it equals the
# resolved node's key (`resolved-aspects.nix` `keyOf concrete`, the SAME `gen-aspects.key`). The prior
# three-branch reconstruction (name+meta / `__provider` via `stampProvider`) retired — the PROBE
# (ci/tests/native-identity.nix) pins `.key == pathKey __provider` per node while both coexist (Task 4 deletes
# `__provider`).
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
}:
let
  # A NATIVE-IDENTITY refKey (Task 3 — the value-injection debt closure). Under A-IDENT a `den.aspects.<path>`
  # value carries its OWN container-relative `.key` (born in gen-aspects' type; the compat two-eval binds the
  # NAVIGATION view — `flake-module.nix bindLegacyEnv → annotatedViewNav` — so a navigated ref AND a value read
  # off the compiled registry both carry `.key`). So `refKey` is a SINGLE lookup: the ref's native `.key`,
  # which by construction equals the resolved node's `keyOf` (both `gen-aspects.key`, W2). No `__provider`
  # reconstruction (the prior three-branch's `stampProvider` path retires; PROBE proves `.key ==
  # pathKey __provider` per node this task). NEVER a silent false: a ref with no `.key` aborts NAMED, so a
  # mistyped `hasAspect <x>` self-announces (the v1 refKey posture preserved).
  refKey =
    ref:
    if builtins.isAttrs ref && (ref ? key) then
      ref.key
    else
      throw "hasAspect: ref must be a `den.aspects.<path>` value carrying `key` (got ${builtins.typeOf ref}).";
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
