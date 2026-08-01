# Structural stratum — HOAG attributes 1–6 as gen-resolve equations (r2 §B2). Every
# body is wiring plus exactly one lib call for any algorithm: `gen-scope.inheritAll`
# (attr 1), the `gen-scope.circular` re-dispatch fixpoint over `gen-dispatch.dispatch`
# (attr 2), the stratified `gen-dispatch.dispatch` (attr 4), the `gen-resolve.nta` spawn
# (attr 5). No structural attribute demands a resolution attribute (A4); the gen-resolve
# schedule enforces it. Every attribute VALUE is inert data — never a dispatch accumulator record.
#
# `policiesIndex` = { enrich; policy; } SELECTION-INDEXED gen-dispatch feeds (concern-policies compiles
# them from `den.policies` and `indexBySelection` selects each on the rule's declared `selects`).
# `declarations` = the declaration vocabulary DEP (`declare`) — `stratumOf` a declaration to its
# B2 stratum, `strata` (the stratified-dispatch order), `kindOf`/`kindToStratum`, `importEdgesOf`
# (distinct from the attribute named `declarations` below, the dispatched policy declarations at a
# node). `isCellNode node` = the cell/root discriminator DEP (lib/build-roots.nix) — the constructor
# TAG test, consumed by the resolve-family guard below. It binds with the libs, NOT per fleet: it is a
# fixed pure predicate `node -> bool` carrying no per-fleet content, so it is the same shape as
# `declarations`, not as the per-fleet data below. Undefaulted, hence required — a defaulted
# `_: false` would call every cell a root and drop the `memberAtCell` law entirely.
# `matchAt self r id` = the PER-NODE SELECTION MATCHER — does rule `r`'s `selects` admit node `id`,
# answered by gen-select over the scope context of the in-flight eval `self`. It binds with the libs
# for the same reason `isCellNode` does; the eval arrives as its first argument, which is what lets a
# `compute` body supply its own `self` rather than the file capturing one. It is what the selection
# index applies at a position its kind memo cannot answer — a selector reading a node's POSITION
# (`within`, `parentMatches`) rather than only its kind. Undefaulted, hence required: a default
# answering `false` would silently drop every position-dependent rule at every node, and one throwing
# would make a legal selector a crash.
# `fleetChildren self id` = the cell-expansion glue (gen-product enumeration lives in
# lib/fleet.nix, Law A1). `linkTarget entry` → { kind; nodeIds; } | null resolves a `link` target
# to the scope NODES whose enriched-context feeds §B3 linked-context — a LIST, because an entity
# multi-attached to N sources is N nodes (root targets only; defaults to none so the structural
# stratum runs without link resolution).
{
  prelude,
  scope,
  resolve,
  dispatch,
  declarations,
  errors,
  isCellNode,
  matchAt,
}:
{
  # The two structural feeds already SELECTED on each rule's declared `selects`
  # (`concernPolicies.indexBySelection`): each is a function `matchAt -> id -> kind -> [rule]` built ONCE
  # PER FLEET, so the per-node compute is a lookup instead of a scan of the whole rule list. Selection is
  # a property of the feed, not of the node, so building it inside `compute` would rebuild it at every
  # node.
  policiesIndex,
  fleetChildren,
  linkTarget ? (_: null),
}:
let
  # THE SUPPORTEDNESS COMPARISON (attribute 2 below). The law asks whether the state the enrichment
  # fixpoint reached and the context it publishes AGREE. Nix's `==` cannot answer that for a closure:
  # two functions built by the same expression at two different dispatches are distinct values and
  # compare unequal, so `==` reports a disagreement it never observed — and `d.enrich`'s value carries
  # no type constraint, so a deferred module, or any value containing one, is expressible. `==` is
  # SOUND for agreement (a `true` is conclusive) and INCOMPLETE for disagreement, so it decides first
  # and a comparison-total projection decides only what it cannot.
  #
  # `project` maps ANY Nix value into a tagged union on which `==` is total:
  #   function       -> its FORMALS alone (`builtins.functionArgs` — total over lambdas, primops and
  #                     partial applications, `{ }` where there are no formals). Below its formals a
  #                     Nix closure exposes nothing.
  #   derivation     -> its `outPath`, the same rule `==` itself applies to a derivation attrset.
  #   list / attrset -> projected elementwise, so the comparable FIELDS of a value that merely
  #                     CONTAINS a function are still compared.
  #   anything else  -> itself; `==` is already total on int, float, string, path, bool and null.
  # The tag is a single-key wrapper, so no value can forge another's projection: a user attrset
  # `{ fn = …; }` projects to `{ attrs = { fn = …; }; }`, never to `{ fn = …; }`.
  #
  # ★ THE LIMIT OF THE LAW. `project` identifies all functions sharing a formals set, so two lambdas
  # in the same position AGREE unless their formals differ. A policy that re-derives a DIFFERENT
  # lambda of the same shape at the converged context is NOT judged, and an unsupported fact can ride
  # into the published context inside a closure. That is the whole of the weakening — every value Nix
  # can compare is still compared exactly, and none is excused for its neighbours. The alternative,
  # reading `==`'s `false` as a disagreement, is a FALSE report rather than a conservative one: a
  # function re-derived identically is not an unsupported fact, and the equality, not the value, was
  # the wrong instrument.
  #
  # COST: `agree` tries `==` first, so a comparable value costs exactly what a `==`-only law cost it,
  # and `project` runs only where `==` already answered `false` — one traversal per side, O(size of the
  # forced value), on values that a `==`-only law was about to abort over. Nix's identity shortcut is
  # NOT available to `agree`: it applies to an attrset's MEMBERS, not to the operands of `==` itself.
  # The law keeps it by never handing `agree` a key both contexts inherit unchanged — see `touchedKeys`
  # below, without which every comparison would re-force the node record each context carries.
  project =
    v:
    if builtins.isFunction v then
      { fn = builtins.functionArgs v; }
    else if builtins.isList v then
      { list = map project v; }
    else if builtins.isAttrs v then
      if v.type or null == "derivation" && v ? outPath then
        { drv = v.outPath; }
      else
        { attrs = prelude.mapAttrs (_: project) v; }
    else
      { atom = v; };
  agree = a: b: a == b || project a == project b;
in
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
          # Strip reserved decls from the generic context. `__edges` is gen-scope's OWN reserved key,
          # never den-hoag's to remove. `suppressedPolicies` is the typed suppression control-fact: it
          # rides its OWN inherited carrier (`suppressed-policies`, gen-scope inheritSet) and must NOT
          # re-leak into the generic binding context. Both survive because both are real keys with a
          # reason to be excluded.
          #
          # The coordinate keys are NOT in this list any more, and their absence is structural rather
          # than remembered: containment is an edge pool and a node's position is a query over it, so
          # `decls` no longer carries a graph fact for a reader to skip. A strip list is a NEGATIVE
          # enumeration — sound only while its key set is closed — and this one shrank to the keys whose
          # exclusion is a property of the key itself.
          extract =
            node:
            removeAttrs (node.decls or { }) [
              "__edges"
              "suppressedPolicies"
            ];
        } self id;
      in
      prelude.foldl' (acc: layer: layer // acc) { } layers;
  };

  # 1s. suppressed-policies — the typed suppression control-fact carrier. The pre-pass' exclude family
  #     emits a per-root suppression set (the v1 `policy.exclude <name>` constraint, dispatch-policies.nix:
  #     15-33); it rides the emitting root's decls as the typed `suppressedPolicies` slot (default.nix
  #     scopeRoots). This attribute delivers it self ∪ every ancestor (gen-scope inheritSet, an idempotent
  #     union walking UP the P-edge parent chain), so a suppression fact reaches every scope-subtree
  #     descendant of its emitting root — exactly v1's scope+ancestors consult. inheritSet's true UNION
  #     composes multiple suppressing ancestors at different depths, where the generic `layer // acc`
  #     context merge would shadow the farther under a single-key `//`; membership (`elem`) is the
  #     semantics, so order/multiplicity carry no meaning. The gate (`gateSuppression`) reads this set
  #     ctx-injected at the `declarations` dispatch (attr 4). Empty set at every node ⇒ inert.
  suppressed-policies = resolve.attr {
    name = "suppressed-policies";
    kind = "inherited";
    stratum = "structural";
    readsAttrs = [ ];
    compute =
      self: id:
      scope.inheritSet {
        extract = node: node.decls.suppressedPolicies or [ ];
      } self id;
  };

  # 2. enrichments — the REAL cross-enrichment fixpoint (r2 §B1), as INERT DATA. The enrich
  #    rules are RE-DISPATCHED on the CONVERGING context each iteration (gen-scope.circular
  #    over one gen-dispatch.dispatch pass), so a policy whose guard needs a key another
  #    policy set only fires once that key has entered the context. keyset-eq is sound for the
  #    LOOP, and no per-policy `fired` tracking is needed, because the loop's result is not
  #    assumed idempotent — it is CHECKED: a guard reading an ABSENCE is not keyset-monotone and
  #    can leave the published delta disagreeing with the state the loop reached, and the
  #    supportedness law below rejects exactly that fleet, naming the key and the policy, instead
  #    of restating the monotonicity premise unenforced.
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
        # SCOPE-LOCAL FIRING: a rule DECLARES the node-kinds it fires at (`selects`), and the feed is
        # indexed on it, so an include-scoped rule reaches only its owner-kind nodes — a coord shared with
        # a descendant kind (inherited down a P edge) no longer over-fires. `.type` is total (every node
        # carries a kind), and the index is total over kinds.
        nodeKind = (self.node id).type;
        # A kind-determined selection is answered from the memo and never applies the matcher; a
        # POSITION-dependent one is answered per node, against this dispatch's own in-flight eval — so
        # a rule selecting `within (attrs { type = "host"; })` reaches every scope under a host, which
        # is a relation over the scope graph and not a set of kind names.
        applicableEnrich = policiesIndex.enrich (matchAt self) id nodeKind;
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
        # THE FACT CARRIES ITS JUSTIFICATION. A binding is where the derived value and the rule that
        # derived it are both in scope, so the provenance is attached HERE rather than at any one
        # reader: every force of `ctx.<key>` — the supportedness comparison below, a downstream policy
        # body, a materialized NixOS option — raises inside a frame naming the producing policy. A raise
        # is the policy author's own diagnostic (`errors.enrichValueContext`); un-attributed it surfaces
        # at whichever consumer happened to read the key, with no path back to the rule that wrote it.
        delta =
          acts:
          prelude.foldl' (
            acc: e: acc // { ${e.key} = errors.enrichValueContext e.__policy e.key e.value; }
          ) { } acts;
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
        # SUPPORTEDNESS — Apt, Blair & Walker (1988), "Towards a Theory of Declarative
        # Knowledge": supportedness (printed p. 95) and Theorem 7 (printed p. 111). A minimal
        # supported model is a FIXED POINT of the immediate-consequence operator (printed
        # p. 100), so this attribute must PUBLISH THE STATE IT REACHED rather than a
        # re-derivation of it. `published` is what attribute 3 hands downstream
        # (`inherited-context // enrichments.added`, below); `converged` is the state the loop
        # reached. The law is I = T_P(I) — model-hood and supportedness at once.
        published = base // added;
        # The law is decided PER KEY, and each way the two can disagree is its own named arm — so the
        # guard and the message it raises are one computation and cannot judge more than they name.
        #   `dropped`  — in the state, absent from the published context: produced during iteration
        #                and not re-produced at convergence, so the published context would drop a
        #                fact the state carries (a guard read an ABSENCE).
        #   `unclosed` — derived at the converged context, absent from the state: a rule firing only
        #                at the returned iterate, so the state is not closed under T_P.
        #   `drifted`  — carried by both, disagreeing under `agree`: the keyset stabilised before the
        #                values did.
        # ONLY THE TOUCHED KEYS ARE COMPARED BY VALUE — what the converged dispatch wrote, plus what
        # the iteration introduced. Every other key holds `base`'s own value on BOTH sides: the SAME
        # value, not merely an equal one, since `//` carries a binding through by identity. One
        # attrset `==` settles all of them at once (`untouchedAgree`), because Nix's identity shortcut
        # applies to an attrset's MEMBERS — comparing them one at a time would instead descend into
        # the node record every context carries, forcing bindings no policy ever read. The one shape
        # this leaves for `untouchedAgree` to catch is an inherited key overwritten during iteration
        # and not re-written at convergence; it widens the scan to name that key rather than deciding
        # anything itself, so `agree` remains the sole judge.
        touchedKeys = builtins.attrNames (
          added // builtins.removeAttrs converged (builtins.attrNames base)
        );
        untouchedAgree =
          builtins.removeAttrs published touchedKeys == builtins.removeAttrs converged touchedKeys;
        dropped = builtins.filter (k: !(published ? ${k})) (builtins.attrNames converged);
        unclosed = builtins.filter (k: !(converged ? ${k})) (builtins.attrNames published);
        drifted = builtins.filter (
          k: published ? ${k} && converged ? ${k} && !(agree published.${k} converged.${k})
        ) (if untouchedAgree then touchedKeys else builtins.attrNames published);
        supported = dropped == [ ] && unclosed == [ ] && drifted == [ ];
        # key -> FIRST producing policy, by re-running the iteration with an owner accumulator.
        # ERROR PATH ONLY — never forced while `supported` holds. Same complexity as the fixpoint
        # itself, paid only when aborting.
        provenance =
          let
            step =
              acc:
              let
                acts = enrichAt acc.ctx;
              in
              {
                ctx = acc.ctx // delta acts;
                own = prelude.foldl' (
                  o: e: if o ? ${e.key} then o else o // { ${e.key} = e.__policy; }
                ) acc.own acts;
              };
            go =
              n: acc:
              let
                nxt = step acc;
              in
              if n >= 100 then
                acc
              else if builtins.attrNames nxt.ctx == builtins.attrNames acc.ctx then
                nxt
              else
                go (n + 1) nxt;
          in
          (go 0 {
            ctx = base;
            own = { };
          }).own;
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
      # `owners` is forced FIRST, so the existing B1 single-writer collision keeps precedence.
      builtins.seq owners (
        if supported then
          { inherit added owners; }
        else
          # Attribution falls back from `provenance` to `owners`: `provenance` re-runs the ITERATION,
          # so it cannot see a key that was only ever derived at the converged context — precisely the
          # `unclosed` arm's keys, and any key the final dispatch writes over an inherited binding.
          # `owners` is that dispatch's key -> policy map and is already forced above, so every key
          # either arm can name has a writer.
          errors.unsupportedEnrichment id dropped unclosed drifted (
            k: provenance.${k} or (owners.${k} or "<unknown>")
          )
      );
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
    readsAttrs = [
      "enriched-context"
      "suppressed-policies"
    ];
    compute =
      self: id:
      let
        # The dispatch context: the enriched bindings PLUS the typed suppression control-fact
        # (`suppressedPolicies`, self ∪ ancestors — the `suppressed-policies` inherited attribute). The
        # compiled-rule gate (`gateSuppression`) reads `ctx.suppressedPolicies` to fire a suppressed policy
        # as `[ ]` at this scope subtree — v1's name-keyed dispatch filter. It rides its own carrier (not
        # generic inherited-context, which strips it) so the control-fact never pollutes an entity binding.
        ctx0 = (self.get id "enriched-context") // {
          suppressedPolicies = self.get id "suppressed-policies";
        };
        # SCOPE-LOCAL FIRING (see attr 2): the feed is indexed on the rule's declared `selects`, so an
        # include-scoped rule reaches only its owner-kind nodes — an ancestor coord inherited by a
        # descendant kind no longer over-fires.
        nodeKind = (self.node id).type;
        # The same per-node matcher as attr 2 (see there).
        applicablePolicy = policiesIndex.policy (matchAt self) id nodeKind;
        # §B3 linked-context, folded from the structural phase's own `link` declarations —
        # forward-threaded through `combine`, so it never feeds back into the links it reads. The
        # node's own bindings shadow it (`linkedContext // ctx`): a link only ADDS a target's
        # context under a not-yet-present kind name.
        # A target resolves to a LIST of nodes (an entity multi-attached to N sources is N nodes).
        # Linked-context binds ONE context per kind, so N>1 has no defensible answer here and aborts
        # rather than picking — see `errors.linkTargetAmbiguous`. N==1 is the whole of today's surface.
        linkedFrom =
          links:
          prelude.foldl' (
            acc: l:
            let
              t = linkTarget l.target;
              nodeIds = if t == null then [ ] else t.nodeIds or [ ];
            in
            if nodeIds == [ ] then
              acc
            else if builtins.length nodeIds > 1 then
              errors.linkTargetAmbiguous (l.__policy or "«anonymous»") t.kind nodeIds
            else
              acc // { ${t.kind} = self.get (builtins.head nodeIds) "enriched-context"; }
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
        # DOUBLE-FIRE DISCIPLINE (design note 2026-07-11 §3(ii)) + A5. Resolve-family declarations {member}
        # are consumed by the STAGED ROOT-RESOLUTION pre-pass at membership-INDEPENDENT roots ONLY. A
        # resolve policy fires in BOTH passes (a policy is `ctx: [decls]`); the main run's structural
        # consumers (attr 5/6) never read member. So a resolve-family emission in the main run has two cases:
        #   • at a membership-DERIVED node (a fleet cell — `isCellNode`) → NO legitimate consumer (the
        #     pre-pass only fires at roots): abort LOUD `memberAtCell` (never a silent second partition; A5).
        #   • at a membership-INDEPENDENT root → the pre-pass already routed the emission; this is the
        #     BENIGN double-fire — pass through (R1's verified posture).
        # A resolve policy that should not over-fire at a descendant cell restricts scope via `selects`.
        #
        # THE UNTAGGED GUARDS ARE RETIRED, not relaxed. They asked whether an emitting policy was in its
        # pre-pass feed, because feed membership used to be DETECTED by firing and a value-conditional
        # emitter probed empty — so an undetected emitter's declaration silently vanished. Feed membership
        # is now a set-membership test on the policy's DECLARED codomain, and the codomain is CHECKED at
        # every firing, so a `member`/`suppress` emitter has declared that kind (or aborted at the emitting
        # site) and a policy that declared it IS in the feed by derivation. The question the guards asked
        # can no longer have a `false` answer: "emitted but untagged" is unrepresentable rather than
        # detected. What remains below is A5, a DIFFERENT law about WHERE a member may be emitted.
        #
        # THE GUARD IS PER-ELEMENT AND LAZY: the check rides each structural declaration and fires ONLY
        # when that element is actually forced by a consumer (attr 6 `importEdgesOf`) — a node that never
        # consumes its structural stratum pays nothing. Eagerly scanning the group here would force every
        # structural element at every node, breaking the per-cell laziness the resolution stratum relies on
        # (b2 demand-laziness) — so the guard maps the group instead of filtering it. A non-resolve-family
        # declaration (spawn/link/…) is returned untouched, so the map is result-identity for a native fleet.
        # "Is this node a CELL?" — asked through the constructor tag (`isCellNode`), never through a
        # parentage probe nor through the id's shape. Both of those answer a DIFFERENT question and
        # both now get it wrong: a scope ROOT may carry a containment parent, and a multi-attached
        # root's id carries an '@'. Either spelling would classify such a root as a cell and abort its
        # own membership emission at `memberAtCell` below.
        isMembershipDerived = isCellNode (self.node id);
        guardResolveFamily =
          a:
          # A `suppress` in the main run is the benign double-fire ANYWHERE: the pre-pass consumed the root
          # emission, and a cell firing of the same excluder is redundant because the root's suppression
          # already covers descendants via inherited-context (v1's scope+ancestors consult). CEILING
          # (corpus-zero): an excluder whose gate opens at a CELL but NOT at that cell's root would
          # under-suppress — the corpus's one excluder gates on `host.class`, identical at both.
          if declarations.isSuppress a then
            a
          else if !(declarations.isResolveFamily a) then
            a
          else if isMembershipDerived then
            errors.memberAtCell (a.__policy or "«anonymous»") id
          else
            a; # a root emission the pre-pass already routed
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

  # 5. children — the HOAG NTA: fleet cells materialized under this host node. The structural
  #    stratum leaves the P-tree host-rooted; folding the structural phase's `spawn`/`member`
  #    declarations into new scope nodes (env-nesting) is the resolution stratum's (B4a). The
  #    enumeration is a gen-product call inside fleetChildren (lib/fleet.nix); this equation is the
  #    Vogt node-spawning seam.
  children = resolve.nta {
    name = "children";
    spawn = self: id: fleetChildren self id;
  };

  # 6. imports — computed I edges from the dispatched declarations: `link` targets (+ collection
  #    routing) via importEdgesOf. `importEdgesOf` yields target ENTRIES; the neron traversal
  #    (gen-scope) walks NODE IDS, so each target is resolved to its scope-node id via `linkTarget`
  #    (a root-kind target maps to its minted root ids; an unresolvable target — e.g. a cell, pending
  #    the edge stratum — drops out). Import edges are a LIST already, so a target resolving to
  #    several nodes concatenates rather than forcing a choice — unlike linked-context, which binds one
  #    ctx per kind and must abort. Empty until a policy emits a resolving `link`, keeping the neron
  #    chain inert for a link-free fixture.
  imports = resolve.attr {
    name = "imports";
    kind = "synthesized";
    stratum = "structural";
    readsAttrs = [ "declarations" ];
    compute =
      self: id:
      prelude.concatMap (
        t:
        let
          r = linkTarget t;
        in
        if r == null then [ ] else r.nodeIds or [ ]
      ) (declarations.importEdgesOf (self.get id "declarations"));
  };
}
