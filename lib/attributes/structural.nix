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
          # Strip reserved `__` decls from the context: `__edges` (gen-scope's own) and
          # `__containment` (the cell's coordinate-root ids, a resolution-only visibility aid) are
          # graph machinery, not entity bindings — a settings/policy read must never see them.
          extract =
            node:
            removeAttrs (node.decls or { }) [
              "__edges"
              "__containment"
              "__coords"
            ];
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
        # SCOPE-LOCAL FIRING pre-filter: a rule may DECLARE the node-kinds it fires at (`__firesAtKinds`,
        # a list). Drop a rule whose list excludes THIS node's kind BEFORE dispatch (absent = every node),
        # so an include-scoped rule fires only at its owner-kind nodes — a coord shared with a descendant
        # kind (inherited down a P edge) no longer over-fires. `.type` is total (every node carries a kind).
        nodeKind = (self.node id).type;
        applicableEnrich = builtins.filter (
          r: !(r ? __firesAtKinds) || builtins.elem nodeKind r.__firesAtKinds
        ) policiesRules.enrich;
        # one enrich dispatch at a context → its fired enrich declarations. classify is a
        # constant single-kind tag here (every rule in policiesRules.enrich is an enrich
        # declaration); the general declaration classifier would be ceremony.
        enrichAt =
          ctx:
          (dispatch.dispatch {
            rules = applicableEnrich;
            inherit id;
            context = ctx;
            match = dispatch.fromFunctionMatch;
            classify = _: "enrich";
            groupOrder = [ "enrich" ];
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
  #    DATA: only the grouped-by-stratum `actions` are kept — the dispatch state (context /
  #    orderedGroups) is projected away, never stored on the node. A later task that wants
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
        # SCOPE-LOCAL FIRING pre-filter (see attr 2): drop a rule whose `__firesAtKinds` excludes this
        # node's kind before dispatch (absent = every node), so an include-scoped rule fires only at its
        # owner-kind nodes — an ancestor coord inherited by a descendant kind no longer over-fires.
        nodeKind = (self.node id).type;
        applicablePolicy = builtins.filter (
          r: !(r ? __firesAtKinds) || builtins.elem nodeKind r.__firesAtKinds
        ) policiesRules.policy;
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
        result = dispatch.dispatch {
          rules = applicablePolicy;
          inherit id;
          context = ctx0;
          match = dispatch.fromFunctionMatch;
          classify = declarations.stratumOf;
          groupOrder = declarations.strata;
          extract = acts: acts; # pass the { <stratum> = actions; } group through to combine
          combine = ctx: delta: linkedFrom (delta.structural or [ ]) // ctx;
        };
        # DOUBLE-FIRE DISCIPLINE (design note 2026-07-11 §3(ii)) + A5 + R2 REQUIREMENT 1. Resolve-family
        # declarations {member, relate} are consumed by the STAGED ROOT-RESOLUTION pre-pass at membership-
        # INDEPENDENT roots ONLY. A resolve policy fires in BOTH passes (a policy is `ctx: [decls]`); the
        # main run's structural consumers (attr 5/6) never read member/relate. So a resolve-family emission
        # in the main run has three cases:
        #   • at a membership-DERIVED node (a fleet cell, `parent != null`) → NO legitimate consumer (the
        #     pre-pass only fires at roots): abort LOUD `memberAtCell` (never a silent second partition; A5).
        #   • at a membership-INDEPENDENT root by a FEED policy (in `resolveFamilyNames`) → the pre-pass
        #     already routed the emission; this is the BENIGN double-fire — pass through (R1's verified posture).
        #   • at a membership-INDEPENDENT root by a NON-feed policy (untagged AND undetected) → the pre-pass
        #     never dispatched it, so the emission would SILENTLY DROP: abort LOUD `resolveFamilyUntagged`
        #     (R2 REQUIREMENT 1 — converts the R1 reviewer's silent-drop edge to loud, with the tag remedy).
        # A resolve policy that should not over-fire at a descendant cell restricts scope via `__firesAtKinds`.
        #
        # The FEED name-set: the resolve-family feed rules' identities strip their `#<stratum>` expansion
        # suffix back to the original policy name (a value-conditional resolve policy expands to
        # `<name>#structural`; a detected one keeps `<name>`) — the declarations carry the ORIGINAL `__policy`
        # stamp, so this maps identities back to it. Derived from `policiesRules.resolveFamily` (already in
        # scope), so R2 REQUIREMENT 1 stays local to this file (no default.nix/equations plumbing).
        resolveFamilyPolicyNames = builtins.listToAttrs (
          map (
            r:
            let
              m = builtins.match "(.*)#structural" r.identity;
            in
            {
              name = if m == null then r.identity else builtins.head m;
              value = true;
            }
          ) policiesRules.resolveFamily
        );
        #
        # THE GUARD IS PER-ELEMENT AND LAZY: the check rides each structural declaration and fires ONLY
        # when that element is actually forced by a consumer (attr 6 `importEdgesOf`) — a node that never
        # consumes its structural stratum pays nothing. Eagerly scanning the group here would force every
        # structural element at every node, breaking the per-cell laziness the resolution stratum relies on
        # (b2 demand-laziness) — so the guard maps the group instead of filtering it. A non-resolve-family
        # declaration (spawn/link/…) is returned untouched, so the map is result-identity for a native fleet.
        isMembershipDerived = (self.node id).parent != null;
        guardResolveFamily =
          a:
          if !(declarations.isResolveFamily a) then
            a
          else if isMembershipDerived then
            errors.memberAtCell (a.__policy or "«anonymous»") id
          else if resolveFamilyPolicyNames ? ${a.__policy or "«anonymous»"} then
            a # a feed policy's benign double-fire at a root (the pre-pass consumed its emission)
          else
            errors.resolveFamilyUntagged (a.__policy or "«anonymous»") id;
        guardedActions =
          if result.actions ? structural then
            result.actions // { structural = map guardResolveFamily result.actions.structural; }
          else
            result.actions;
      in
      {
        actions = guardedActions;
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
  #    routing, Task 5) via importEdgesOf. `importEdgesOf` yields target ENTRIES; the neron traversal
  #    (gen-scope) walks NODE IDS, so each target is resolved to its scope-node id via `linkTarget`
  #    (a root-kind target maps to its flat root id; an unresolvable target — e.g. a cell, pending the
  #    Task 4 edge stratum — drops out). Empty until a policy emits a resolving `link`, keeping the
  #    neron chain inert for a link-free fixture.
  imports = resolve.attr {
    name = "imports";
    kind = "synthesized";
    stratum = "structural";
    readsAttrs = [ "declarations" ];
    compute =
      self: id:
      builtins.filter (i: i != null) (
        map (
          t:
          let
            r = linkTarget t;
          in
          if r == null then null else r.nodeId
        ) (declarations.importEdgesOf (self.get id "declarations"))
      );
  };
}
