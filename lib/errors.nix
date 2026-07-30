# Named definition-time errors — pure message builders. Tasks 1–11 extend this set.
# nixpkgs-lib-free: plain `throw`, no prelude needed (add it back only if a future
# builder genuinely uses a prelude helper).
let
  fail = ctx: msg: throw "den-hoag: ${ctx}: ${msg}";
  # Display name of an entry / class / aspect (id_hash-bearing or name-bearing); strings are only
  # authoritative in a rendered message. Mirrors gen-pipe's renderEntry without a lib edge.
  render =
    e:
    if e == null then
      "<none>"
    else if builtins.isAttrs e then
      (e.name or e.id_hash or (builtins.toJSON e))
    else
      toString e;
  # A key list rendered as `key` (written by `policy`), behind its own clause label and followed by
  # the remedy that THAT clause implies. An EMPTY list renders as NOTHING AT ALL — neither label nor
  # remedy — so a message carrying one key class neither trails an empty clause for another nor
  # asserts a diagnosis that class does not witness.
  renderKeys =
    label: remedy: keys: whoWrote:
    if keys == [ ] then
      ""
    else
      label
      + builtins.concatStringsSep ", " (map (k: "`${k}` (written by `${whoWrote k}`)") keys)
      + remedy;
  # A policy's rendered identity. A rule minted by a LOWERING is registered under a synthesized attr
  # key — positional for some families, so the v1 name is not recoverable from it at all — and a
  # diagnosis naming only that key names nothing its author wrote. Such a record states the name it was
  # authored under (`originName`) and BOTH are printed: the author's name to act on, the synthesized key
  # because that is what the compiled surface is indexed by. A natively-authored policy has no origin —
  # its key IS that name — and renders by the key alone, exactly as before.
  policyIdent =
    originName: policyName:
    if originName == null || originName == policyName then
      "`${policyName}`"
    else
      "`${originName}` (compiled as `${policyName}`)";
  renderScope =
    coords:
    if coords == null || coords == { } then
      "<no-scope>"
    else
      builtins.concatStringsSep ", " (map (k: "${k}=${render coords.${k}}") (builtins.attrNames coords));
in
{
  identityLaw =
    api: got:
    fail "identity law (A2)" "${api} takes a registry entry (carrying id_hash), got ${builtins.typeOf got}${
      if builtins.isString got then " \"${got}\" — pass the entry, not a \"kind:name\" string" else ""
    }";

  # A5 emission discipline: `member` is accepted only at membership-independent scope
  # nodes. A `member` declaration dispatched at a membership-derived node (a fleet cell, or
  # any node beneath one) aborts, naming the policy and the scope. The membership-
  # derived classification is the caller's (Task 3 declaration-stratum classifier); this
  # builder is the abort it raises.
  memberAtCell =
    policyName: scopeId:
    fail "member discipline (A5)" "policy `${policyName}` emitted `member` at membership-derived scope `${scopeId}`; member is accepted only at membership-independent nodes";

  # The resolve-family and exclude-family UNTAGGED guards are RETIRED. They existed because feed
  # membership was DETECTED by firing (a value-conditional emitter probes empty, so it could not be
  # detected) and an undetected emitter's declaration silently vanished. Feed membership is now a
  # set-membership test on the policy's DECLARED codomain (`emits`), and the codomain is CHECKED at every
  # firing (`emitsUndeclared`), so a `member`/`suppress` emitter is in its feed by derivation and
  # "emitted but untagged" is unrepresentable rather than detected.

  # Containment-tuple target (design note 2026-07-11 §3c-UNIFIED): a `containTo`-marked `member` whose
  # target coordinate resolves to NO existing root scope node. A containment tuple carries ctx bindings +
  # a containment ancestor INTO an existing membership-independent root (it never creates one), so an
  # unknown target is a definition error — the leaf-dim cell case leaves `containTo` null. Names the policy
  # + the target. Raised in the staged root-resolution pre-pass (lib/staged-resolution.nix).
  containTargetMissing =
    policyName: target:
    fail "containment target (§3c)" "policy `${policyName}` emitted a `containTo`-marked `member` to target `${render target}`, which resolves to no existing root scope node; a containment tuple carries ctx into an existing membership-independent root (a leaf-dim cell target leaves `containTo` null)";

  # Containment-relation CYCLE (§3c-UNIFIED chain extension): the settings-chain ancestor walk
  # (resolved-settings.nix `ancestorsOf`) revisited a node already on its path — a cyclic `containTo`
  # topology (root A contains B contains A). Corpus-unreachable (a v1-surface adapter's source coordinate
  # strictly ascends the acyclic schema topology), but a native fixture CAN author it — so abort LOUD
  # naming the repeated node, never hang (the loud-error discipline). Forced when a contained node's
  # settings resolve.
  containmentCycle =
    nodeId:
    fail "containment cycle (§3c)" "the containment-relation ancestor chain revisits node `${nodeId}` — a cyclic `containTo` topology (A contains B contains A); containment relations must follow the acyclic kind topology";

  # ── the coordinate projections' three named aborts (§6.1) ─────────────────────────────────────────
  # A node whose own TYPE is not a settings dimension. A coordinate is matched against a layer by
  # `coordsEq`, and a layer validates its `at` dims against `settingsDims`, so a node of a kind outside
  # that set would carry a coordinate NO LAYER COULD EVER NAME — silently, forever, with its settings
  # resolving to the schema defaults and nothing to distinguish that from "no layer applies".
  #
  # UNREACHABLE TODAY BY AN IDENTITY, and that is exactly why it is written. `settingsDims` is
  # `dimKinds ∪ (allKinds \ cellKinds)`, and both sides are ⊆ `allKinds` while every kind lands in one of
  # them, so `settingsDims = allKinds` as a SET for every fleet — readable off `entity.nix`'s single
  # `mapAttrs` and default.nix's two filters, with no fixture involved. This guard is what fires if that
  # relationship ever stops holding. An unreachable guard costs nothing now and is the only thing that
  # turns a silent wrong answer into an abort later.
  unknownAxis =
    nodeId: kindName: dims:
    fail "coordinate axis (§6.1)" "node `${nodeId}` has type `${kindName}`, which is not a settings dimension (${
      builtins.concatStringsSep ", " (map (d: "`${d}`") dims)
    }); its coordinate could name no layer, so the settings chain would silently resolve to schema defaults";

  # TWO ancestors of one node on ONE product axis. The per-axis projection selects the unique type-`d`
  # member of `{ n } ∪ closure n`; a second member means two candidate coordinates on one axis, and an
  # attrset literal would have silently last-won. Names the node, the axis and every member it saw.
  #
  # This is also the guard the cell-arm reduction rests on: the cascade filter's type test is sound
  # exactly when a dim-typed ancestor IS the axis selection, and the only other case is this collision.
  coordCollision =
    nodeId: axis: members:
    fail "coordinate collision (§6.1)" "node `${nodeId}` has ${toString (builtins.length members)} ancestors on axis `${axis}` (${
      builtins.concatStringsSep ", " (map (m: "`${m}`") members)
    }); a product axis fixes ONE coordinate, so two same-type ancestors name two incompatible cells";

  # A node carrying no `__entry`. Every node minter writes one (`buildRoots` and `cellChildrenFor` both
  # do), so this names a node that reached the projections without going through either. A BARE SELECT
  # here would be an uncatchable crash naming only the attribute; a silent sentinel would be an
  # absence⇒something decision of exactly the class these projections exist to remove. Neither: abort
  # NAMED, beside `unknownAxis`, since the projection is total only if its value source is.
  missingEntry =
    nodeId:
    fail "coordinate value (§6.1)" "node `${nodeId}` carries no `decls.__entry`, so it has no coordinate value; every node minter writes one, so this node reached the coordinate projections without being minted by `buildRoots` or `cellChildrenFor`";

  # A containment SOURCE slice naming more than one coordinate. The slice is the emitting scope's coords
  # minus the target (`containmentOf`), and it denotes ONE source node — the id rule reads a single
  # `kind:name` off it. Two coordinates means two candidate sources and the rule would silently take the
  # alphabetically-first, so it aborts naming every coordinate it saw. An EMPTY slice is a different,
  # legitimate case (bindings with no attachment) and is accepted, not routed here.
  containmentSliceAmbiguous =
    policyName: targetId: coordNames:
    fail "containment source slice (§2.5a)" "policy `${policyName}` emitted a `containTo`-marked `member` to target `${targetId}` whose source slice names ${toString (builtins.length coordNames)} coordinates (${
      builtins.concatStringsSep ", " (map (c: "`${c}`") coordNames)
    }); a source slice denotes ONE containment source, so it must name exactly one coordinate (or none, for a bindings-only emission)";

  # A containment source whose KIND is not the target kind's schema parent. `parent` is scalar per kind,
  # so a target of kind K has exactly one admissible source kind, `parent(K)`; a source of any other kind
  # asserts a second parent KIND, which no node shape can express. `«none»` renders the case where the
  # target kind is top-level (no parent kind at all) yet an attachment was asserted anyway.
  containmentKindMismatch =
    policyName: targetId: expectedKind: actualKind:
    fail "containment source kind (§2.5b)" "policy `${policyName}` emitted a `containTo`-marked `member` to target `${targetId}` from a source of kind `${actualKind}`, but that target's schema parent kind is ${
      if expectedKind == null then "«none»" else "`${expectedKind}`"
    }; a containment source must be an instance of the target kind's parent kind";

  # The source-slice id rule asked for the node id of a slice that names NO coordinate. Empty slices are
  # legitimate as EMISSIONS (bindings only, no attachment) but they denote no node, so every consumer must
  # filter them before asking for an id. Reaching here is a caller-contract violation, named rather than
  # left to `builtins.head`'s bare out-of-bounds.
  containmentSliceEmpty = fail "containment source slice (§2.5c)" "the source-slice id rule was asked for the node id of an EMPTY slice, which names no source; an empty slice is a bindings-only emission and carries no attachment, so it must be filtered out before its id is taken";

  # Two registry entries share one `id_hash`, so the containment-target index cannot name the node
  # either of them denotes. gen-schema's content address puts the KIND first, so entries of different
  # kinds cannot collide; entries of ONE kind collide only when an instance pins `_identity.keys` to a
  # key set that excludes the injected `name`, making two distinct instances content-identical. Whichever
  # entry the index kept, the other's `containTo` target would resolve to a node that is not its own —
  # a silent re-key. Names both entries and the identity remedy.
  rootIndexCollision =
    hash: nodeIds:
    fail "containment-target index" "registry entries ${
      builtins.concatStringsSep " and " (map (n: "`${n}`") nodeIds)
    } share the identity hash `${hash}`, so the containment-target index cannot say which node it names; entries of one kind share a content address only when `_identity.keys` pins an identity that excludes the entry's `name`, so widen those keys (or drop the pin and let identity reflect `name`) rather than letting one entry silently take the other's node id";

  # A `link` whose target entity resolves to SEVERAL scope nodes. Linked-context binds one context
  # per target KIND, so a multi-attached target leaves no defensible choice: the node ids differ only
  # by which attachment minted them, and silently taking one is last-wins under another name. Abort
  # instead, naming every candidate — the question "which attachment does the link mean?" has to be
  # answered where the link is written, not guessed here.
  # Native attachment (den.attach): the entity names a parent instance that no registry holds. A typo,
  # not an intent — so it ABORTS NAMED rather than silently failing to attach. Silent non-attachment is
  # the failure class this arc keeps finding (a registry that never reaches the fleet, with no error).
  attachRefUnresolved =
    kindName: name: refField: parentKind: refValue:
    fail "native attachment" "`${kindName}:${name}` names its ${parentKind} parent as `${refField} = \"${toString refValue}\"`, but no `${parentKind}` instance by that name is registered; a parent reference that resolves to nothing is a typo rather than an opt-out — to declare no attachment, use the kind's `unless` field";

  linkTargetAmbiguous =
    policyName: kindName: nodeIds:
    fail "link target (M7)" "policy `${policyName}` links to a `${kindName}` that resolves to ${toString (builtins.length nodeIds)} scope nodes (${
      builtins.concatStringsSep ", " (map (n: "`${n}`") nodeIds)
    }); linked context binds ONE context per kind, so link to a specific attachment instead of the multi-attached entity";

  # B1 single-writer enrichment (A3): two enrich policies writing one context key abort at
  # definition time, naming both policies + the key. Fires on a same-pass collision AND a
  # cross-iteration one (the check runs over the converged enrich accumulation).
  singleWriter =
    key: ownerA: ownerB:
    fail "single-writer enrichment (B1)" "enrich key `${key}` is written by two policies (`${ownerA}` and `${ownerB}`); a key may be enriched by exactly one policy";

  # THE JUSTIFICATION RIDES THE FACT. An enrichment fact's justification is the policy that derived it
  # (ABW's supportedness, p. 95: a fact in the model is there BECAUSE some rule's body holds). So when
  # forcing that fact raises, the diagnostic must name the rule — otherwise the author's own `throw`
  # surfaces at whichever consumer read the key, with no path back to the policy that wrote it.
  #
  # NOT a `tryEval` guard, and the difference is the whole point. `tryEval` would have to CATCH the
  # error to name it, and Nix cannot recover a caught throw's TEXT — so naming the policy would cost
  # the author's own message, trading one missing half of the diagnosis for the other. It also cannot
  # catch the non-recoverable class (a missing attribute) at all, which is exactly the class a policy
  # body reading an absent ctx field raises. `addErrorContext` DECORATES instead: the original error
  # propagates verbatim with this frame added to its trace, and it is total over the error classes
  # because it never inspects the error.
  #
  # LAZY, and therefore free: the wrapper is an unforced application, so a fact nothing reads costs
  # nothing and A17's laziness contract is untouched. It also cannot reorder anything, because it
  # neither forces earlier nor catches.
  #
  # ★ ITS EXTENT IS ONE FORCE, said rather than implied. `addErrorContext` decorates what raises while
  # the fact is brought to WHNF; a throw sitting DEEPER inside an already-WHNF value (`value = { a =
  # throw …; }`) raises after this frame has returned and is not decorated. Closing that would mean
  # `deepSeq`-ing every enrichment fact at its binding — a strictness change on a lazy contract, which
  # is a worse defect than the one it would diagnose. The wrapper covers the fact ITSELF, which is what
  # a policy's enrichment VALUE is.
  enrichValueContext =
    policyName: key: value:
    builtins.addErrorContext "while forcing the enrichment fact `${key}`, derived by policy `${policyName}` (B1 enrichment; the error below is the policy's own)" value;

  # Context supportedness — Apt, Blair & Walker (1988), "Towards a Theory of Declarative
  # Knowledge": supportedness (printed p. 95), Theorem 7 (printed p. 111). The enrichment
  # fixpoint's published delta must be the state the loop reached (a fixed point of the
  # immediate-consequence operator, printed p. 100). When it is not, some key is in the model
  # with nothing justifying it — the configuration ABW's "Stratified Programs" (Definition 3,
  # p. 96) exists to exclude — so the fleet is rejected, naming the keys and their policies.
  # THREE ARMS, EACH CARRYING ITS OWN REMEDY. A negative read is what `dropped` and only `dropped`
  # witnesses, so that diagnosis rides that clause: a fleet whose values merely drifted, or whose
  # rule fired late, is told what its own shape implies and is never sent hunting for a negative
  # edge it did not write.
  unsupportedEnrichment =
    scopeId: dropped: unclosed: drifted: whoWrote:
    fail "context supportedness (ABW p.95)" "at scope `${scopeId}` the enrichment fixpoint and the published context disagree${
      renderKeys " — produced during iteration but not re-produced at the converged context: "
        " (a policy whose guard reads the ABSENCE of a context key another policy writes forms a cycle through a negative edge, which has no supported model — remove the negative read or split the policies onto separate keys)"
        dropped
        whoWrote
    }${
      renderKeys " — derived at the converged context but absent from the state the fixpoint reached: "
        " (a policy whose guard branches on a VALUE that settles last fires only at the converged context, contributing a fact the fixpoint never carried — gate it on a key's PRESENCE instead)"
        unclosed
        whoWrote
    }${
      renderKeys " — re-produced at the converged context with a different value: "
        " (the keyset stabilised before the values did — a policy is deriving its value from a key whose own value is still moving; break the value dependency or seed the key with its final value)"
        drifted
        whoWrote
    }";

  # B2 stratum coherence: a policy whose declarations do not all classify to one STRATUM
  # aborts. Each declaration's stratum is derived from its KIND via the vocabulary's
  # kind->stratum map (Task 2: enrich -> structural is the whole map; Task 3 extends it), so
  # the abort names both offending kinds AND their strata. Wired at the declaration classifier
  # (Task 3); Task 2 provides the builder.
  mixedStratum =
    policyName: kindA: stratumA: kindB: stratumB:
    fail "declaration stratum (B2)" "policy `${policyName}` produced declarations of kind `${kindA}` (stratum `${stratumA}`) and kind `${kindB}` (stratum `${stratumB}`); a policy's declarations must all classify to a single stratum";

  # THE CODOMAIN CONTRACT. A policy DECLARES the declaration kinds its body may produce (`emits`), and
  # every firing checks each emitted declaration against it. The declaration therefore cannot drift from
  # the body: a mis-declared codomain aborts LOUD at the emitting site instead of mis-routing the rule
  # silently. Names the policy, the offending kind and the declared codomain.
  emitsUndeclared =
    originName: policyName: kind: emits:
    fail "declaration codomain" "policy ${policyIdent originName policyName} produced a `${kind}` declaration, which is not in its declared `emits` = [ ${builtins.concatStringsSep " " emits} ]. The codomain is a CONTRACT checked at every firing, not an annotation: either add `${kind}` to `emits` or stop producing it";

  # THE TWO REFINED CODOMAINS, and why `emits` alone does not discharge them. `emits` names the
  # declaration KINDS a body may produce; these name the DEPENDENCY EDGES those declarations create.
  # The policy dependency graph is decided ONCE, at registration, BEFORE any rule fires (Apt, Blair &
  # Walker 1988, "Stratified Programs", Lemma 1, p. 97: a program is stratified iff its dependency graph
  # has no cycle containing a negative edge). An edge a body introduces at firing time is an edge that
  # decision never saw, so the declared graph would not be the graph the program has and the decision
  # would range over a domain nothing guarantees. These two aborts are what make the declaration true.
  suppressesUndeclared =
    originName: policyName: target: suppresses:
    fail "suppression codomain" "policy ${policyIdent originName policyName} produced a `suppress` naming `${target}`, which is not in its declared `suppresses` = [ ${builtins.concatStringsSep " " suppresses} ]. The codomain is a CONTRACT checked at every firing: the stratification is decided from the DECLARED graph before any rule fires, so an edge introduced by a body is an edge the check never saw (Apt, Blair & Walker 1988, Lemma 1, p. 97)";

  bindsUndeclared =
    originName: policyName: key: binds:
    fail "binding codomain" "policy ${policyIdent originName policyName} emitted a `member` binding `${key}`, which is not in its declared `binds` = [ ${builtins.concatStringsSep " " binds} ]. A binding is a POSITIVE dependency edge of every policy that destructures it, and the stratification check reads those edges from the declaration, so a key bound only at runtime is an edge the check never saw";

  # THE STRATIFICATION ABORT. Not named for suppression: the cycle may run through POSITIVE binding
  # edges, and Definition 3's condition 1 (p. 96) ADMITS a purely positive cycle — same-stratum positive
  # reads are legal, so rejecting one would be over-strict rather than safe. What is forbidden is a cycle
  # containing a NEGATIVE edge (Lemma 1, p. 97), which is exactly a negative edge whose two endpoints
  # share a cluster of the condensation (Definition 12, p. 112; Lemma 11(2), p. 113, makes the cluster
  # condensation the finest stratification, so the decision is a graph computation rather than a search).
  # The whole cluster is printed because the cluster, not the edge, is the actionable unit: the positive
  # edge family is a GLOBAL name test, so a cluster may be larger than the author expects, and the repair
  # is to rename a binding key or split a codomain — never to relax the check.
  negativeCycle =
    suppressor: cluster:
    fail "stratification (ABW Lemma 1)" "the policy dependency graph has a cycle through the NEGATIVE edge contributed by `${suppressor}` — the mutually-dependent cluster is [ ${builtins.concatStringsSep " " cluster} ]. A suppression edge is a negated read and a binding edge is a positive one; Apt, Blair & Walker (1988), `Stratified Programs`, Lemma 1, p. 97, admits cycles of positive edges and forbids any cycle containing a negative one, so the program has no stratification. Break the cluster by removing one `suppresses` entry or one `binds`/formal pairing";

  # The compose-commitment boundary (declarations.nix `isSiteMarkData`). A DERIVED-channel DAG or a
  # delivery route seeds the ONE fleet gen-pipe compose BEFORE the eval, so it is declared as data in
  # `ops`; only per-node SITE MARKS are emitted from a body.
  #
  # ★ THE OTHER END OF THIS BOUNDARY IS NOT BUILT, AND CANNOT BE BUILT AS SPECIFIED. `ops` is specified as
  # a STATIC field, which requires the commitment to be ctx-INDEPENDENT — and it is not. Measured on
  # nix-config `modules/den/policies/pipes.nix:136-149` (`broadcast-syncthing-hub-shares`, wired at
  # `den.schema.user.includes`): its `pipe.transform` has `role = "derive"`, so it is ops-eligible, and its
  # function closes over `user.name` — the ops observed at two different users DIFFER. A record field
  # cannot hold a per-node value, so no design that makes `ops` a static field can work, and the fleet
  # compose seed's construction is wrong UPSTREAM of this shim rather than merely unwired here.
  # Until that is redesigned, a body carrying a derived/route pipeOp aborts HERE rather than being
  # silently dropped from a seed that never received it. Do not work around this in the shim.
  opsInBody =
    originName: policyName:
    fail "compose commitment" "policy ${policyIdent originName policyName} produced a `pipeOp` declaration carrying a derived-channel DAG or a delivery route from its BODY. Those seed the ONE fleet gen-pipe compose before the eval and are ctx-independent by contract, so they are declared as data in `ops`; only per-node SITE MARKS are emitted from the body";

  # Registration rejection, at an explicit boundary rather than as a throw deep inside a dispatch. The
  # message is produced as a VALUE by `policyMessage` (Nix's `tryEval` cannot capture a throw's text, so a
  # validator that returns its message is the only CI-testable form) and raised here.
  policyRegistration = msg: fail "policy registration" msg;

  # §4.1 the prebuilt-arm exclusivity: an aspect declaring `artifact` (the value-mode prebuilt face) may
  # carry no non-empty class content — the prebuilt IS the materialized face, so class buckets alongside it
  # are contradictory. Names the aspect and the offending class key.
  artifactBucketsNonEmpty =
    aspectName: classKey:
    fail "prebuilt arm (§4.1)" "aspect `${aspectName}` declares `artifact` (the value-mode prebuilt face) AND non-empty class content `${classKey}` — a prebuilt arm's class buckets must be empty; declare one or the other";

  # A13 class-tag ambiguity: a null-class scope emitting class-shaped (config-demanding) content —
  # the producing scope binds no class to resolve the contribution's `config` against, so the class
  # tag is undecidable. den detects this at the emission it owns (a null producing class + a deferred
  # value) and frames gen-pipe's E1 with den names — the producing aspect, the quirk channel, and the
  # scope. `config`-independent (class-neutral) emissions at the same scope are legal (T3), so the
  # abort is precise to the class-shaped case.
  classAmbiguity =
    {
      aspect,
      channel,
      scope,
    }:
    fail "class tag (A13)" "aspect `${render aspect}` emits class-shaped (config-demanding) content to quirk channel `${channel}` at null-class scope `${renderScope scope}`; a class-shaped contribution needs a producing class — tag it explicitly or make the emission config-independent";

  # A7 linearization declaration surface: a `den.linearization.dims` list that is not a total,
  # entry-only cover of the product dimensions. `tag` names the failure; `detail` is the offending
  # dim name (missing/duplicate) or the rendered non-entry (identity law A2). Definition-time.
  linearizationDim =
    tag: detail:
    fail "linearization (A7)" (
      if tag == "non-entry" then
        "den.linearization.dims takes KIND entries (each carrying a `kind` field), got a non-entry `${detail}` — pass `den.schema.<kind>`, not a dim-name string"
      else if tag == "missing" then
        "den.linearization.dims omits product dimension `${detail}`; every registered dimension must appear exactly once"
      else if tag == "duplicate" then
        "den.linearization.dims names dimension `${detail}` more than once; each dimension appears exactly once"
      else
        "malformed dims (${tag}): ${detail}"
    );

  # A10 narrow accessor: reading `.settings` of an aspect whose `present = false` at this scope.
  # Names the aspect and the scope node; the caller must check `.present` first (§2.8).
  absentAspectSetting =
    aspectName: scopeId:
    fail "narrow accessor (A10)" "aspect `${aspectName}` is not present at scope `${scopeId}` — its `.settings` is unavailable; check `.present` before reading `.settings`";

  # A14 constraint 3 (projects facet): two DISTINCT projecting aspects inject a settings layer for the
  # SAME target aspect at the SAME attachment scope — the order between projectors is undecided, so den
  # aborts at definition time, naming both projectors, the target address, and the scope.
  projectionCollision =
    {
      projectors,
      address,
      scope,
    }:
    fail "projection collision (A14)" "aspects ${
      builtins.concatStringsSep " and " (map (p: "`${p}`") projectors)
    } both project settings onto aspect `${address}` at scope `${renderScope scope}`; a target address may be projected by at most one aspect per scope";

  # A14 constraint 2 (projects facet): a projection selector must be STATIC — it may match an aspect's
  # own declared name/tags/setting fields, never resolved graph position or values. A scope-navigating
  # or identity/coordinate selector (within/has/parentMatches/entity/kind/coord) is dynamic and aborts,
  # naming the projecting aspect + the offending selector tag.
  projectionDynamicSelector =
    projectorName: tag:
    fail "projection selector (A14)" "aspect `${projectorName}` projects with a dynamic selector (`${tag}`); projection selectors are static — they match declared name/tags/setting fields only, never resolved graph position or values";

  # A18 class-share gate: an injected class-invariant core is NOT byte-identical to a member's real
  # projection at the shared keys — the share is UNSOUND and aborts LOUD (never silently reused). Names
  # the member and the two digests. The byte gate is the ONLY authority a share is sound (gen-class
  # gate.nix: "keys narrow, the gate decides"); this is den-hoag's hard-fail on `gate == false`.
  classShareGate =
    {
      member,
      candidateDigest,
      realDigest,
    }:
    fail "class-share gate (A18)" "the class-invariant core for member `${member}` is not byte-identical to its real projection (candidate ${candidateDigest} != real ${realDigest}); a class-share is authorised ONLY by the byte gate — a divergent core is never silently reused";

  # A13 cross-class consumption: a consumer at class C reads a contribution tagged class C′ ≠ C with
  # no declared C′→C adapter on the quirk. den owns the discipline (a declared adapter is the ONLY
  # authorised coercion — §2.5, never implicit); this frames the abort naming the channel, the
  # producer, and both classes before gen-pipe would otherwise coerce or reject.
  crossClassNoAdapter =
    {
      channel,
      producer,
      tag,
      consuming,
    }:
    fail "cross-class read (A13)" "quirk channel `${channel}` consumed at class `${render consuming}` but a contribution from aspect `${
      render (producer.aspect or null)
    }` (entity `${
      render (producer.entity or null)
    }`) is tagged class `${render tag}`; declare a `${render tag}` -> `${render consuming}` adapter on the quirk or consume at the producing class";

}
