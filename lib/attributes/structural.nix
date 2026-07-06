# Structural stratum — HOAG attributes 1–6 as gen-resolve equations (r2 §B2). Every
# body is wiring plus exactly one lib call for any algorithm: `gen-scope.inheritAll`
# (attr 1), the `gen-scope.circular ∘ gen-dispatch.dispatchStep` pairing (attr 2),
# `gen-dispatch.dispatch` (attr 4), the `gen-resolve.nta` spawn (attr 5). No structural
# attribute demands a resolution attribute (A4); the gen-resolve schedule enforces it.
#
# `policiesRules` = { enrich; effects; } gen-dispatch rule lists (Task 3 compiles them
# from `den.policies`; Task 2 threads them straight through so the B1 fixpoint is real).
# `fleetChildren self id` = the cell-expansion glue (gen-product enumeration lives in
# lib/fleet.nix, Law A1).
{
  prelude,
  scope,
  resolve,
  dispatch,
  effects,
  errors,
}:
{ policiesRules, fleetChildren }:
{
  # 1. inherited-context — entity bindings flow down P edges. The gen-scope parent walk
  #    collects each ancestor's decls (nearest first); the local `//` fold merges them
  #    nearest-shadows-farthest. Walk = lib (inheritAll); merge = attrset assembly (A1).
  #    A cell node therefore carries both its host and user bindings.
  inherited-context = resolve.attr {
    name = "inherited-context";
    kind = "inherited";
    readsAttrs = [ ];
    compute =
      self: id:
      let
        layers = scope.inheritAll {
          extract = node: removeAttrs (node.decls or { }) [ "__edges" ];
        } self id;
      in
      prelude.foldl' (acc: layer: layer // acc) { } layers;
  };

  # 2. enrich-effects — the REAL self-referential enrichment fold (r2 §B1 cross-enrichment):
  #    the enrich rules are RE-DISPATCHED on the CONVERGING context each iteration, so a
  #    policy whose guard needs a key another policy set only fires once that key has entered
  #    the context. This is the Law A1 pairing `gen-scope.circular ∘ gen-dispatch.dispatchStep`
  #    — NOT a one-shot fold over a precomputed list. `dispatchStep`'s `self: id: prev -> next`
  #    matches `circular`'s `f`; `dispatchInit base` seeds `{ context; fired; accActions;
  #    orderedPhases }`. dispatch threads each pass's enrich delta into `context` via
  #    extract/combine, so the next iteration dispatches against the grown context; `fired`
  #    dedups per policy across iterations. The circular is internal to the body (not an
  #    attribute-level cycle), so kind stays synthesized; stratum is forced structural (the
  #    fold BUILDS structure — it must not be warm-served).
  enrich-effects = resolve.attr {
    name = "enrich-effects";
    kind = "synthesized";
    stratum = "structural";
    readsAttrs = [ "inherited-context" ];
    compute =
      self: id:
      let
        base = self.get id "inherited-context";
        cfg = {
          rules = policiesRules.enrich;
          inherit id;
          match = dispatch.fromFunctionMatch;
          classify = effects.classify;
          phaseOrder = [ "enrich" ];
          # extract this pass's enrich actions into a { key = value; } delta; combine grows context.
          extract = acts: prelude.foldl' (acc: e: acc // { ${e.key} = e.value; }) { } (acts.enrich or [ ]);
          combine = ctx: delta: ctx // delta;
        };
        loop = scope.circular {
          init = dispatch.dispatchInit base;
          # keyset-eq on the converging context (B1-sound: a key's value is stable once it appears).
          eq = a: b: builtins.attrNames a.context == builtins.attrNames b.context;
        } (dispatch.dispatchStep { inherit (dispatch) dispatch; } cfg) self id;
        # B1 single-writer over the CONVERGED accumulation — catches both a same-pass collision
        # and a cross-iteration one (two policies writing one key even if they fired in different
        # passes). Names both policies + the key.
        owners = prelude.foldl' (
          acc: e:
          if acc ? ${e.key} && acc.${e.key} != e.__policy then
            errors.singleWriter e.key acc.${e.key} e.__policy
          else
            acc // { ${e.key} = e.__policy; }
        ) { } (loop.accActions.enrich or [ ]);
      in
      builtins.seq owners loop;
  };

  # 3. enriched-context — the converged context that dispatch reads: a plain projection of
  #    enrich-effects.context (the keyset-eq fixpoint above), not itself circular.
  enriched-context = resolve.attr {
    name = "enriched-context";
    kind = "synthesized";
    stratum = "structural";
    readsAttrs = [ "enrich-effects" ];
    compute = self: id: (self.get id "enrich-effects").context;
  };

  # 4. policy-effects — resolution/collection/demand policies dispatched on the structural
  #    context (Task 3 widens `context` to `enriched-context // linked-context`).
  policy-effects = resolve.attr {
    name = "policy-effects";
    kind = "synthesized";
    readsAttrs = [ "enriched-context" ];
    compute =
      self: id:
      let
        ctx = self.get id "enriched-context";
      in
      dispatch.dispatch {
        rules = policiesRules.effects;
        inherit id;
        context = ctx;
        match = dispatch.fromFunctionMatch;
        classify = effects.classify;
        phaseOrder = effects.phaseOrder;
      };
  };

  # 5. children — the HOAG NTA: fleet cells materialized under this host node (+ spawn
  #    effects from policy-effects, wired in Task 3). The enumeration is a gen-product call
  #    inside fleetChildren (lib/fleet.nix); this equation is the Vogt node-spawning seam.
  children = resolve.nta {
    name = "children";
    spawn = self: id: fleetChildren self id;
  };

  # 6. imports — computed I edges: link effects + collection routing (Task 3 populates the
  #    effect vocabulary; Task 2's importEdgesOf yields none, keeping the neron chain empty).
  imports = resolve.attr {
    name = "imports";
    kind = "synthesized";
    readsAttrs = [ "policy-effects" ];
    compute = self: id: effects.importEdgesOf (self.get id "policy-effects");
  };
}
