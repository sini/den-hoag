# Declaration constructors — the four concern vocabularies as tagged, INERT graph facts
# (r2 §B2/§B3). NAMING (verb/noun split): this module binds as `declare` — a VERB, so a
# policy body reads `declare.member { … }` — while the node ATTRIBUTE that holds the facts a
# rule produced is `declarations` — a NOUN, the facts present at a node. File name and both
# names spell "declaration"; only the grammatical role differs.
#
# A declaration is `{ __action = <kind>; … }` built on gen-dispatch.mkActions. Its KIND is the
# tag (`spawn`/`link`/`member`/`edge`/…); its STRATUM (B2: structural | resolution | collection
# | demand) is the mkActions GROUP the kind sits in — `stratumOf` returns it and `kindToStratum`
# is the static kind→stratum map. NO EFFECT RUNTIME: a declaration is data, never a callable;
# the only callables ever inside one are the guards gen-dispatch reads. Identity law (A2):
# entry-typed positions (member coords, configure.of, edge, demand.subject) reject a "kind:name"
# scope-string or a provenance `rendered` display value, taking only registry entries (carrying
# `id_hash`). The check is EAGER — a bad input aborts at construction (WHNF), not lazily when the
# field is later read — so `builtins.tryEval` over the bare constructor call already catches it.
{
  prelude,
  dispatch,
  pipe,
  errors,
}:
let
  # Kind → stratum grouping (mkActions groups ARE the B2 strata). `collection`'s single kind is
  # `pipeOp` — the pipe.* op payload rides it; concern-quirks (Task 5) wraps the operators below
  # into `pipeOp` declarations.
  # Some kinds ride the mkActions dispatch with the raw `actions.<kind>` constructor (no custom
  # wrapper below), so their contract is stated here at the group site:
  #   • `spawn`/`spawnShared`/`emit` — LATENT structural constructors: child-node creation
  #     (`spawn`/`spawnShared`) and wire-entity-into-output (`emit`) are SUBSUMED by `member` fan-out
  #     (§3c-UNIFIED), so nothing in the assembly consumes these kinds; they remain in the vocabulary
  #     for surface totality.
  #   • `enrich { key = val }` — a structural enrichment fact; its consumer is the enrichment
  #     fixpoint in concern-policies.nix (A3 single-writer).
  #   • `reroute { from; to }` — a resolution fact moving a class's collected content to another class;
  #     consumed by attributes/class-modules.nix (`reroutes`).
  #   • `inject { class; module }` — a resolution fact appending a module to a class bucket;
  #     consumed by attributes/class-modules.nix (`injects`).
  groups = {
    structural = [
      "spawn"
      "spawnShared"
      "link"
      "enrich"
      "emit"
      "member"
      "suppress"
    ];
    resolution = [
      "edge"
      "drop"
      "reroute"
      "inject"
      "configure"
      "delivery"
      "reach-edge"
      "reach-suppress"
    ];
    collection = [ "pipeOp" ];
    demand = [ "demand" ];
  };
  # The SEED stratum order (§B2). The order is DATA: `compileStrata` folds name-keyed dense insertions
  # onto this seed, so a new stratum enters by declaration, never by editing this list (REFERENCE.md).
  seedStrata = [
    "structural"
    "resolution"
    "collection"
    "demand"
  ];

  # `compileStrata { inserts }` → the total stratum order. Each `inserts.<name> = { after; }` places
  # `<name>` densely — immediately after its `after` anchor. Determinism (REFERENCE.md): inserts are
  # placed lexicographically by name, and an insert whose anchor is itself an insert resolves once that
  # anchor is placed (a ready-set fixpoint over the lex-ordered names); multiple inserts after the same
  # anchor keep lexicographic order. A name colliding with an existing stratum, or an `after` that never
  # resolves (unknown / cyclic), aborts NAMED at definition time.
  compileStrata =
    {
      inserts ? { },
    }:
    let
      names = builtins.sort (a: b: a < b) (builtins.attrNames inserts);
      anchorOf = n: inserts.${n}.after;
      # duplicate-name guard: an insert may not shadow a seeded stratum.
      dupes = builtins.filter (n: builtins.elem n seedStrata) names;
      # A ready insert = one whose anchor is already in the order and which is not yet placed. Placing
      # the lexicographically-first ready insert immediately after its anchor's contiguous same-anchor
      # run gives forward-lex order for same-anchor siblings.
      indexOf =
        order: x:
        builtins.head (
          builtins.filter (i: builtins.elemAt order i == x) (builtins.genList (i: i) (builtins.length order))
        );
      insertAfterRun =
        order: name: anchor:
        let
          len = builtins.length order;
          # scan past the anchor and any already-placed inserts that share this anchor (they sort before
          # `name`, being placed lex-ascending) — `name` lands after that contiguous run.
          start = indexOf order anchor;
          runEnd = prelude.foldl' (
            j: k:
            if k > j && k < len && (inserts.${builtins.elemAt order k}.after or null) == anchor then k else j
          ) start (builtins.genList (i: i) len);
          before = builtins.genList (i: builtins.elemAt order i) (runEnd + 1);
          after = builtins.genList (i: builtins.elemAt order (runEnd + 1 + i)) (len - (runEnd + 1));
        in
        before ++ [ name ] ++ after;
      step =
        state:
        let
          ready = builtins.filter (n: builtins.elem (anchorOf n) state.order) state.pending;
        in
        if ready == [ ] then
          state
        else
          let
            name = builtins.head ready;
          in
          step {
            order = insertAfterRun state.order name (anchorOf name);
            pending = builtins.filter (n: n != name) state.pending;
          };
      final = step {
        order = seedStrata;
        pending = names;
      };
    in
    if dupes != [ ] then
      throw "den.strata: insert '${builtins.head dupes}' shadows an existing stratum — insert names must be fresh"
    else if final.pending != [ ] then
      throw "den.strata: insert '${builtins.head final.pending}' names an unknown `after` anchor '${anchorOf (builtins.head final.pending)}' (unknown or cyclic)"
    else
      final.order;

  # The compiled order with ZERO inserts is byte-identical to the seed — every existing stratum consumer
  # (`kindToStratum`, the gen-resolve schedule feed) reads THIS list (the full suite is the proof).
  strata = compileStrata { inserts = { }; };

  actions = dispatch.mkActions groups;

  # decl → its B2 stratum (the mkActions group); decl → its KIND tag.
  stratumOf = actions.classify;
  kindOf = a: a.__action;

  # LAW: the collection stratum's compose commitments are the DERIVED-op DAG (channel-shaping) and the
  # delivery ROUTES — those seed the ONE fleet gen-pipe compose BEFORE eval, from ctx-INDEPENDENT bodies.
  # A pipeOp carrying ONLY site marks on a BARE channel ref (`derived.__derived = false`, no deriving
  # stages, no routes) makes NO probe-time compose commitment: site marks are per-node EMISSION wiring
  # (default.nix:509 "Site `marks` … are per-scope EMISSION wiring, not compose ops"), fired WHERE the
  # policy fires — the v1 parity is register-pipe-effect.nix:15's per-scope `scopedPipeEffects`
  # scopedAppend at dispatch. So such a pipeOp is per-node DATA, not a compose op; `isSiteMarkData`
  # is the predicate concern-policies' value-conditional expansion guard uses to ALLOW it through (a
  # DERIVED/route pipeOp from a value-less policy still aborts — it IS a probe-time commitment).
  isSiteMarkData =
    a:
    kindOf a == "pipeOp"
    && (a.marks or [ ]) != [ ]
    && !(a.derived.__derived or false)
    && (a.routes or [ ]) == [ ];

  # Static kind → stratum map — the errors.mixedStratum naming and structural.nix's vocabulary
  # interface consume it (the inverse of `groups`).
  kindToStratum = prelude.foldl' (
    acc: stratum:
    prelude.foldl' (acc': kind: acc' // { ${kind} = stratum; }) acc (groups.${stratum} or [ ])
  ) { } strata;

  # A2 identity law: an entry-typed position takes a registry entry (id_hash), never a string.
  requireEntry = api: v: if builtins.isAttrs v && v ? id_hash then v else errors.identityLaw api v;

  # `member` — the structural membership tuple, the SOLE resolve-family verb (design note 2026-07-11
  # §3c-UNIFIED — TUPLE-CARRIED BINDINGS: `relate` DISSOLVED into `member`). Two call shapes:
  #   • BARE coords — `member { <dim> = <entry>; … }` — a CELL tuple (`bindings = { }`, `containTo = null`),
  #     the native/fixture form (a cell materialises under the product).
  #   • WRAPPED — `member { coords = { … }; bindings ? { }; containTo ? null }` — the tuple that carries
  #     ctx `bindings` and (when `containTo != null`) marks a CONTAINMENT tuple: the STAGED ROOT-RESOLUTION
  #     pre-pass folds `bindings` into the target root's ctx AND records the source coordinate as that
  #     root's containment ancestor (the env→host / env→cluster edge — the settings-chain env slice), NEVER
  #     a product cell. `containTo` names the coord kind that is the EXISTING ROOT target (`coords.<containTo>`
  #     is its identity entry; `coords` minus it is the source slice). The COMPAT `resolve.to` arm sets
  #     `containTo` for a registry-backed (root) target and leaves it null for a registry-less (cell) target
  #     — the node-class law (compile.nix); a native fixture sets it explicitly.
  # The WRAPPED shape is detected structurally (an attrset holding `coords` whose OWN keys are all reserved
  # {coords,bindings,containTo}); every other attrset is bare coords. A fleet kind named `coords`/`bindings`/
  # `containTo` is the only ambiguity — none exist (kinds are host/user/env/…). Each coordinate is
  # entry-checked EAGERLY (A2) so a string dim aborts at construction. Both shapes accepted at membership-
  # independent roots ONLY (A5).
  isMemberWrapper =
    a:
    builtins.isAttrs a
    && a ? coords
    && builtins.all (k: k == "coords" || k == "bindings" || k == "containTo") (builtins.attrNames a);
  member =
    arg:
    let
      wrapped = isMemberWrapper arg;
      rawCoords = if wrapped then arg.coords else arg;
      bindings = if wrapped then arg.bindings or { } else { };
      containTo = if wrapped then arg.containTo or null else null;
      validated = builtins.mapAttrs (dim: e: requireEntry "member.coords.${dim}" e) rawCoords;
      forced = prelude.foldl' (acc: k: builtins.seq validated.${k} acc) null (
        builtins.attrNames validated
      );
    in
    builtins.seq forced (
      actions.member {
        coords = validated;
        inherit bindings containTo;
      }
    );

  # Resolve-family kinds (design note 2026-07-11 §3c-UNIFIED): the declarations the STAGED ROOT-RESOLUTION
  # pre-pass consumes — the UNIFIED `member` tuple (a CELL tuple, or a `containTo`-marked CONTAINMENT tuple
  # carrying bindings). Accepted at membership-independent roots ONLY (A5); every OTHER kind is consumed by
  # the main run. `isResolveFamily` is the double-fire discipline's kind predicate — its exactly-one-consumer
  # split (the main run aborts LOUD on a resolve-family decl reaching a membership-derived node, never a
  # silent drop; see attributes/structural.nix attr 4). `relate` retired — one verb, one classifier.
  resolveFamilyKinds = [
    "member"
  ];
  isResolveFamily = a: builtins.elem (kindOf a) resolveFamilyKinds;

  # `suppress { name }` — structural: a SCOPE-LOCAL POLICY-SUPPRESSION fact (#72, the exclude family —
  # candidate A, ledger u21). Names a policy (the v1 registry name) whose rules must NOT fire at the
  # declaring scope or its descendants — v1's `policy.exclude <policy>` constraint (pin 11866c16
  # fx/handlers/dispatch-policies.nix:15-33: a name-keyed `type="exclude"` entry at the emitting scope,
  # consulted scope+ancestors — sibling-isolated, #613). INERT DATA like every declaration: the STAGED
  # pre-pass (staged-resolution.nix) is its exactly-one consumer (the resolve-family discipline's twin);
  # the main run's guard (attributes/structural.nix) passes a feed policy's benign double-fire and
  # aborts an untagged one LOUD. `name` is a plain string (a policy name, not an entity — no A2 entry
  # check; a non-string aborts at construction).
  suppress =
    { name }:
    if !(builtins.isString name) then
      throw "den-hoag: declare.suppress: `name` must be a policy-name string, got ${builtins.typeOf name}"
    else
      actions.suppress { inherit name; };
  isSuppress = a: kindOf a == "suppress";

  # `configure { of, set }` — resolution: set values on a target entry.
  configure =
    { of, set }:
    let
      o = requireEntry "configure.of" of;
    in
    builtins.seq o (
      actions.configure {
        of = o;
        inherit set;
      }
    );

  # `edge aspect` — resolution: an aspect-delivery edge onto this node.
  edge =
    aspect:
    let
      a = requireEntry "edge" aspect;
    in
    builtins.seq a (actions.edge { aspect = a; });

  # `drop aspect` — resolution: a scope-level constraint pruning an aspect (and its include
  # subtree) from this node's resolved set (§B4 constraints; consumed by resolved-aspects'
  # `constraintSeen` pre-seed). Aspect-entry-typed EAGERLY, like `edge`.
  drop =
    aspect:
    let
      a = requireEntry "drop" aspect;
    in
    builtins.seq a (actions.drop { aspect = a; });

  # `delivery { sourceClass; targetClass; module ? null; path ? []; mode; adaptArgs ? null;
  # guard ? null; annotations ? {}; }` — resolution: a v1 delivery-edge INTENT (an external consumer's
  # `deliver`/`route`/`provide`). The gen-edge record is rendered from this at the FIRING NODE by
  # output-modules' `edgesAt` (which owns the firing scope + collected membership) — the declaration
  # itself is inert intent. `sourceClass`/`targetClass` are class REGISTRATIONS (identity-law A2,
  # entry-checked EAGERLY like `edge`); the remaining fields are placement + closures den-hoag applies
  # at materialization. A native den-hoag fleet emits none of these — only an external consumer does.
  delivery =
    args:
    let
      s = requireEntry "delivery.sourceClass" args.sourceClass;
      t = requireEntry "delivery.targetClass" args.targetClass;
    in
    builtins.seq s (
      builtins.seq t (
        actions.delivery (
          args
          // {
            sourceClass = s;
            targetClass = t;
          }
        )
      )
    );

  # `reach-edge { target; classFilter ? null }` — resolution: POSITIVE cross-scope reach-edge (spec §7.1
  # class-scoped opt-in). `target` = bare node-id STRING; `classFilter` = predicate on the target's
  # resolved-aspect nodes (null = all). Record shape matches reachEdgesOf (attributes/resolved-aspects.nix:111-116).
  reach-edge =
    {
      target,
      classFilter ? null,
    }:
    actions."reach-edge" { inherit target classFilter; };

  # `reach-suppress { edge; when ? (_: true) }` — resolution: NEGATIVE edge removing the positive edge whose
  # target == `edge` (node-id STRING), gated by `when scope`. Record shape matches reachSuppressOf (:120-124).
  reach-suppress =
    {
      edge,
      when ? (_: true),
    }:
    actions."reach-suppress" { inherit edge when; };

  # `link { target }` — structural: an I-edge to an EXISTING entity node (annotates, never
  # creates/re-resolves). `target` denotes an entity node — an identity-law position (A2) — so it
  # is entry-checked EAGERLY, like `member`/`edge`. Selector fan-out is a POLICY-level idiom (a
  # policy resolves a selector and emits one `link` per matched entry), not constructor polymorphism.
  link =
    { target }:
    let
      t = requireEntry "link.target" target;
    in
    builtins.seq t (actions.link { target = t; });

  # `demand args` — demand: a subject entity plus the demand payload.
  demand' =
    args:
    let
      s = requireEntry "demand.subject" args.subject;
    in
    builtins.seq s (actions.demand (args // { subject = s; }));

  # I-edges a node contributes: `link` targets become import edges; a collection `route` joins
  # via channel wiring, not an import edge. Reads the multi-group dispatch result (structural +
  # resolution groups — the strata that carry edge-forming kinds).
  importEdgesOf =
    r:
    let
      acts = (r.actions.structural or [ ]) ++ (r.actions.resolution or [ ]);
    in
    prelude.concatMap (
      a:
      if kindOf a == "link" then
        [ a.target ]
      else if kindOf a == "pipeOp" && (a.op or null) == "route" then
        [ ] # routing joins imports via channel wiring
      else
        [ ]
    ) acts;

  # A4 stratum separation: a policy's declarations must all classify to ONE stratum. Derives each
  # declaration's stratum through the kindToStratum map (kind → stratum), so the two-kind abort
  # names both offending kinds AND their strata (errors.mixedStratum). Applied per policy in
  # concern-policies.
  stratumOfDecl = a: kindToStratum.${kindOf a};
  checkStratum =
    policyName: acts:
    let
      seen = prelude.unique (map stratumOfDecl acts);
    in
    if builtins.length seen <= 1 then
      acts
    else
      let
        a = builtins.head acts;
        b = builtins.head (builtins.filter (x: stratumOfDecl x != stratumOfDecl a) acts);
      in
      errors.mixedStratum policyName (kindOf a) (stratumOfDecl a) (kindOf b) (stratumOfDecl b);
in
actions
// {
  inherit
    strata
    seedStrata
    compileStrata
    stratumOf
    kindOf
    kindToStratum
    isSiteMarkData
    isResolveFamily
    suppress
    isSuppress
    resolveFamilyKinds
    isMemberWrapper
    importEdgesOf
    checkStratum
    member
    configure
    edge
    drop
    delivery
    link
    ;
  demand = demand';
  # hyphenated verbs cannot ride the `inherit` above — assign explicitly so the custom ctors (carrying
  # their defaults) SHADOW the raw dispatch.mkActions entries.
  "reach-edge" = reach-edge;
  "reach-suppress" = reach-suppress;
  # pipe.* operators re-exported from gen-pipe (map/filter/fold/scan/route/join/tee). They are
  # content-agnostic dataflow ops and carry no `__action` yet — Task 5's concern-quirks wraps
  # them as `pipeOp` collection declarations.
  pipe = {
    inherit (pipe)
      map
      filter
      fold
      scan
      route
      join
      tee
      ;
  };
}
