# Structural stratum — HOAG attributes 1–6 as gen-resolve equations (r2 §B2). Every
# body is wiring plus exactly one lib call for any algorithm: `gen-scope.inheritAll`
# (attr 1), the `gen-scope.circular` re-dispatch fixpoint over `gen-dispatch.dispatch`
# (attr 2), the stratified `gen-dispatch.dispatch` (attr 4), the `gen-resolve.nta` spawn
# (attr 5). No structural attribute demands a resolution attribute (A4); the gen-resolve
# schedule enforces it. Every attribute VALUE is inert data — never a dispatch accumulator record.
#
# `policiesRules` = { enrich; policy; } gen-dispatch rule lists (Task 3 compiles them from
# `den.policies` via concern-policies; Task 2 threaded empty lists so the B1 fixpoint was real).
# `declarations` = the declaration vocabulary DEP (`declare`) — `stratumOf` a declaration to its
# B2 stratum, `strata` (the stratified-dispatch order), `kindOf`/`kindToStratum`, `importEdgesOf`
# (distinct from the attribute named `declarations` below, the dispatched policy declarations at a
# node). `fleetChildren self id` = the cell-expansion glue (gen-product enumeration lives in
# lib/fleet.nix, Law A1). `linkTarget entry` → { kind; nodeId; } | null resolves a `link` target
# to the scope node whose enriched-context feeds §B3 linked-context (root targets in Task 3;
# defaults to none so the structural stratum runs without link resolution).
{
  prelude,
  scope,
  resolve,
  dispatch,
  declarations,
  errors,
}:
{
  policiesRules,
  fleetChildren,
  linkTarget ? (_: null),
}:
{
  # 1. inherited-context — entity bindings flow down P edges. The gen-scope parent walk
  #    collects each ancestor's decls (nearest first); the local `//` fold merges them
  #    nearest-shadows-farthest. Walk = lib (inheritAll); merge = attrset assembly (A1).
  #    A cell node therefore carries both its host and user bindings.
  inherited-context = resolve.attr {
    name = "inherited-context";
    kind = "inherited";
    stratum = "structural";
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

  # 2. enrichments — the REAL cross-enrichment fixpoint (r2 §B1), as INERT DATA. The enrich
  #    rules are RE-DISPATCHED on the CONVERGING context each iteration (gen-scope.circular
  #    over one gen-dispatch.dispatch pass), so a policy whose guard needs a key another
  #    policy set only fires once that key has entered the context. keyset-eq is sound and no
  #    per-policy `fired` tracking is needed: single-writer (below) + keyset-monotone guards
  #    make a key's value fixed once it appears, so a refire at a grown context is idempotent.
  #    The circular value is the converged context (a plain attrset), never an accumulator
  #    record. B1 single-writer is ONE post-convergence dispatch: at the converged context
  #    every satisfiable guard fires, so two policies writing one key both surface — whether
  #    they collided in the same pass or across iterations. The attribute value is
  #    { added = <converged delta>; owners = <key -> policy>; }, owners seq-forced so the
  #    collision abort fires on demand.
  enrichments = resolve.attr {
    name = "enrichments";
    kind = "synthesized";
    stratum = "structural";
    readsAttrs = [ "inherited-context" ];
    compute =
      self: id:
      let
        base = self.get id "inherited-context";
        # one enrich dispatch at a context → its fired enrich declarations. classify is a
        # constant single-kind tag here (every rule in policiesRules.enrich is an enrich
        # declaration); the general declaration classifier would be ceremony.
        enrichAt =
          ctx:
          (dispatch.dispatch {
            rules = policiesRules.enrich;
            inherit id;
            context = ctx;
            match = dispatch.fromFunctionMatch;
            classify = _: "enrich";
            phaseOrder = [ "enrich" ];
          }).actions.enrich or [ ];
        delta = acts: prelude.foldl' (acc: e: acc // { ${e.key} = e.value; }) { } acts;
        converged =
          scope.circular
            {
              init = base;
              eq = a: b: builtins.attrNames a == builtins.attrNames b;
            }
            (
              _self: _id: ctx:
              ctx // delta (enrichAt ctx)
            )
            self
            id;
        finalActs = enrichAt converged;
        added = delta finalActs;
        # single-writer: fold key -> policy, aborting (naming both policies + the key) on a
        # second writer of any key.
        owners = prelude.foldl' (
          acc: e:
          if acc ? ${e.key} && acc.${e.key} != e.__policy then
            errors.singleWriter e.key acc.${e.key} e.__policy
          else
            acc // { ${e.key} = e.__policy; }
        ) { } finalActs;
      in
      builtins.seq owners { inherit added owners; };
  };

  # 3. enriched-context — inherited bindings extended with the converged enrichment delta.
  enriched-context = resolve.attr {
    name = "enriched-context";
    kind = "synthesized";
    stratum = "structural";
    readsAttrs = [
      "inherited-context"
      "enrichments"
    ];
    compute = self: id: (self.get id "inherited-context") // (self.get id "enrichments").added;
  };

  # 4. declarations — the single rule-evaluation point: every non-enrich policy dispatched
  #    over `enriched-context`, STRATIFIED across declare.strata (structural → resolution →
  #    collection → demand). Stratification is what makes §B3 hold WITHOUT a cycle: the
  #    structural phase (link/member/spawn/emit) fires on the plain context first, then
  #    `combine` extends the context with linked-context — each `link` target's enriched-context
  #    under the target's kind name — so ONLY the later (resolution/collection/demand) phases
  #    ever see it. Attr 2 dispatches (and attr 5 materializes) on `ctx` alone; linked-context
  #    reaches resolution and beyond only, never a structural read. `declarations` in this
  #    compute is the vocabulary DEP (stratumOf/strata), not this attribute. The value is INERT
  #    DATA: only the grouped-by-stratum `actions` are kept — the dispatch state (context / fired
  #    / orderedPhases) is projected away, never stored on the node. A later task that wants
  #    linked-context as data recomputes it via `linkedFrom` (pure and cheap), not by reading a
  #    dispatch accumulator back off this attribute.
  declarations = resolve.attr {
    name = "declarations";
    kind = "synthesized";
    readsAttrs = [ "enriched-context" ];
    compute =
      self: id:
      let
        ctx0 = self.get id "enriched-context";
        # §B3 linked-context, folded from the structural phase's own `link` declarations —
        # forward-threaded through `combine`, so it never feeds back into the links it reads. The
        # node's own bindings shadow it (`linkedContext // ctx`): a link only ADDS a target's
        # context under a not-yet-present kind name.
        linkedFrom =
          links:
          prelude.foldl' (
            acc: l:
            let
              t = linkTarget l.target;
            in
            if t == null then acc else acc // { ${t.kind} = self.get t.nodeId "enriched-context"; }
          ) { } (builtins.filter (a: declarations.kindOf a == "link") links);
      in
      {
        inherit
          (dispatch.dispatch {
            rules = policiesRules.policy;
            inherit id;
            context = ctx0;
            match = dispatch.fromFunctionMatch;
            classify = declarations.stratumOf;
            phaseOrder = declarations.strata;
            extract = acts: acts; # pass the { <stratum> = actions; } group through to combine
            combine = ctx: delta: linkedFrom (delta.structural or [ ]) // ctx;
          })
          actions
          ;
      };
  };

  # 5. children — the HOAG NTA: fleet cells materialized under this host node. Task 3 leaves the
  #    P-tree host-rooted; folding the structural phase's `spawn`/`member` declarations into new
  #    scope nodes (env-nesting) lands with the resolution stratum in Task 4 (B4a). The
  #    enumeration is a gen-product call inside fleetChildren (lib/fleet.nix); this equation is the
  #    Vogt node-spawning seam.
  children = resolve.nta {
    name = "children";
    spawn = self: id: fleetChildren self id;
  };

  # 6. imports — computed I edges from the dispatched declarations: `link` targets (+ collection
  #    routing, Task 5) via importEdgesOf. Empty until a policy emits `link`, keeping the neron
  #    chain inert for the fixture.
  imports = resolve.attr {
    name = "imports";
    kind = "synthesized";
    stratum = "structural";
    readsAttrs = [ "declarations" ];
    compute = self: id: declarations.importEdgesOf (self.get id "declarations");
  };
}
