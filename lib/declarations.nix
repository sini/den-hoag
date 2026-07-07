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
  groups = {
    structural = [
      "spawn"
      "spawnShared"
      "link"
      "enrich"
      "emit"
      "member"
    ];
    resolution = [
      "edge"
      "drop"
      "reroute"
      "inject"
      "configure"
    ];
    collection = [ "pipeOp" ];
    demand = [ "demand" ];
  };
  strata = [
    "structural"
    "resolution"
    "collection"
    "demand"
  ];

  actions = dispatch.mkActions groups;

  # decl → its B2 stratum (the mkActions group); decl → its KIND tag.
  stratumOf = actions.classify;
  kindOf = a: a.__action;

  # Static kind → stratum map — the errors.mixedStratum naming and structural.nix's vocabulary
  # interface consume it (the inverse of `groups`).
  kindToStratum = prelude.foldl' (
    acc: stratum: prelude.foldl' (acc': kind: acc' // { ${kind} = stratum; }) acc groups.${stratum}
  ) { } strata;

  # A2 identity law: an entry-typed position takes a registry entry (id_hash), never a string.
  requireEntry = api: v: if builtins.isAttrs v && v ? id_hash then v else errors.identityLaw api v;

  # `member coords` — structural membership tuple. Each coordinate is entry-checked EAGERLY
  # (seq the validated values before returning) so a string dim aborts at construction.
  member =
    coords:
    let
      validated = builtins.mapAttrs (dim: e: requireEntry "member.coords.${dim}" e) coords;
      forced = prelude.foldl' (acc: k: builtins.seq validated.${k} acc) null (
        builtins.attrNames validated
      );
    in
    builtins.seq forced (actions.member { coords = validated; });

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
    stratumOf
    kindOf
    kindToStratum
    importEdgesOf
    checkStratum
    member
    configure
    edge
    drop
    link
    ;
  demand = demand';
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
