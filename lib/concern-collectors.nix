# Compile the collectors concern (`den.collectors.<name>`, spec §4.7) onto the framework `collector` entity
# kind. A collector is a FIRST-CLASS ENTITY — it carries its own class content, an id_hash, and a root scope
# node — so it is a real gen-schema kind (`collector`), not a bare data record. The kind is FRAMEWORK-OWNED:
# it enters `denMeta` by a `//`-augment GATED on `den.collectors != {}` (a fleet with no collectors has no
# collector kind/registry — corpus-inert), and `entity.discoverKinds` reserves the name against a user kind.
#
# The collector's producing class is a PER-INSTANCE FUNCTION of its own `class` field (§2.5's function-form
# `contentClass`, the shim's per-host precedent): `contentClassFn e = effectiveClassEntries.${e.class}`, so
# distinct collectors carry distinct classes. Both failure modes abort catchable-NAMED — an ABSENT/null class
# (null-guarded BEFORE any string selector, because a null attr selector `x.${null}` is a tryEval-uncatchable
# coercion the `or` never intercepts) and a non-null UNREGISTERED class — at the compiled surface (eager) AND
# the classOf path.
#
# NO EFFECT RUNTIME (Law A1): every export is pure wiring — a freeform names probe (the discoverClasses
# idiom), a schema-decl + bridge module, a `//`-augment, a `mapAttrs` validation, a lookup-with-guard.
{
  prelude,
  schema,
  merge,
  select,
}:
let
  # The framework kind name. Reserved by `entity.discoverKinds` (a user kind may not be `collector`); keyed
  # here so default.nix's `metaWithClass` special-case and the `//`-augment share one literal.
  kindName = "collector";

  # DISCOVER the declared collector NAMES the freeform-probe way `entity.discoverClasses` reads `den.classes`:
  # a schema-less tree freeform-absorbs every `den.*` the user modules set and exposes `den.collectors`' attr
  # names WITHOUT forcing any collector record (attrNames = spine only). default.nix needs the names up front
  # to GATE the kind augment (empty ⇒ no collector kind). Static-decl, so as sound as the kind/class probes.
  discoverCollectors =
    userModules:
    let
      probe = merge.evalModuleTree {
        modules = [
          {
            options.den = merge.mkOption {
              default = { };
              type = merge.types.submodule {
                freeformType = merge.types.lazyAttrsOf merge.types.anything;
              };
            };
          }
        ]
        ++ userModules;
      };
    in
    builtins.attrNames (probe.config.den.collectors or { });

  # The `den.collectors.<name>` DECLARATION option (always present, the `classesDecl` posture): each value is
  # a raw record `{ class; members ? null; consumes ? null; render ? null; }`. `raw` holds it unmerged (its
  # `members`/`render` may carry functions). Absent ⇒ `{ }` (the corpus default), so the augment never fires.
  optionModule = {
    options.den.collectors = merge.mkOption {
      type = merge.types.lazyAttrsOf merge.types.raw;
      default = { };
      description = "Collector registrations (§4.7): `<name> = { class; members ? null; consumes ? null; render ? null; }` — each becomes a `collector` entity.";
    };
  };

  # The `//`-augment for `denMeta`: the framework `collector` kind record in the `discoverKinds` shape
  # (parentless, class-neutral-IN-THE-AUGMENT, dim = the kind name), ONLY when collectors are declared. The
  # per-instance `contentClass` is injected downstream (metaWithClass), matching discoverKinds' null-in-augment
  # convention (the class wiring is not a discovery-time fact). Empty ⇒ `{ }` (no collector kind), the gate.
  metaAugment =
    { hasCollectors }:
    if hasCollectors then
      {
        ${kindName} = {
          parent = null;
          contentClass = null;
          dim = kindName;
        };
      }
    else
      { };

  rawField =
    description:
    schema.mkOption {
      type = schema.types.raw;
      default = null;
      inherit description;
    };

  # The framework INSTANCE modules (added to `entity.build`'s userModules, GATED on collectors present):
  # declare the `collector` schema kind — a parentless kind whose strict fields are the collector record — and
  # BRIDGE the user surface `den.collectors` into the entity registry `den.collector` (so each collector
  # becomes an id_hash-bearing root entity). The universal `outputs` field rides via build's
  # `outputsFieldModules` (denMeta carries collector), so it is not re-declared here. Empty ⇒ `[ ]` (no schema
  # kind), the corpus-inert gate.
  collectorModules =
    { hasCollectors }:
    prelude.optional hasCollectors (
      { config, ... }:
      {
        config.den.schema.${kindName} = {
          parent = null;
          options = {
            class = rawField "The collector's output class (a registered class name) — resolved to its `contentClass` entry (§4.7).";
            members = rawField "The collector's member selector/set (§4.7); consumed by the membership producer.";
            consumes = rawField "The product a collector member supplies at the aggregate crossing (§4.7).";
            render = rawField "The aggregate render the collector's members cross through (§4.7).";
          };
        };
        # BRIDGE: the user surface `den.collectors` populates the `collector` instance registry. The user sets
        # only `den.collectors`; `den.collector` is framework-written here (one definition, no user clash).
        config.den.${kindName} = config.den.collectors;
      }
    );

  # The two class-validity messages, shared by the compiled surface (eager) and the contentClass function
  # (classOf path). `effectiveClassNames` is the built-ins ∪ the fleet's declared classes. The ABSENT/null
  # branch must fire BEFORE any string selector: `class` is an optional field (default null), and a null attr
  # selector `x.${null}` throws a tryEval-uncatchable coercion the `or` never intercepts — so both guards read
  # `class or null` and null-guard explicitly, keeping BOTH failure modes catchable-NAMED.
  declaresNoClassMsg = name: "den.collectors: collector '${name}' declares no `class` (§4.7)";
  unknownClassMsg =
    effectiveClassNames: name: class:
    "den.collectors: collector '${name}' names class '${class}', which is not a registered class (known: ${builtins.concatStringsSep ", " effectiveClassNames})";

  # The COMPILED collector surface (`den.collectors`, the concern's validated table — the products/renders
  # compile-and-expose posture): each collector's `class` is validated against the registered classes, a NAMED
  # throw on an absent/null class OR a non-null unregistered one. Reading the surface fires the check.
  compile =
    { collectors, effectiveClassNames }:
    prelude.mapAttrs (
      name: c:
      let
        class = c.class or null;
      in
      if class == null then
        throw (declaresNoClassMsg name)
      else if !(builtins.elem class effectiveClassNames) then
        throw (unknownClassMsg effectiveClassNames name class)
      else
        c
    ) collectors;

  # The PER-INSTANCE contentClass FUNCTION (§2.5 function-form, entity.classOf's function arm): the collector's
  # producing class is its own `class` field resolved to a class ENTRY. Null-guarded FIRST (a null selector is
  # uncatchable), then `effectiveClassEntries.${class} or throw` converts the unregistered-class attr-miss into
  # a catchable NAMED throw — the same class-validity guard the compiled surface enforces eagerly, here on the
  # classOf path (a collector whose class the compile did not force).
  contentClassFn =
    { effectiveClassEntries, effectiveClassNames }:
    e:
    let
      class = e.class or null;
    in
    if class == null then
      throw (declaresNoClassMsg e.name)
    else
      effectiveClassEntries.${class} or (throw (unknownClassMsg effectiveClassNames e.name class));

  # ── §4.7: `hasClass` selector sugar + the member-edge producer ──────────────────────────────────────
  # `hasClass cls` — a TOP-LEVEL selector sugar (the `hasSetting` posture, projects.nix): matches a scope node
  # whose PRODUCING class NAME is `cls`. It reads `ctx.classOf` — a class-NAME accessor the GATHER injects into
  # the run ctx (the base gen-select scope ctx carries no producing class; den's classOfNode is not a scope
  # primitive). NULL-GUARDED: the gather runs over ALL scope nodes, so a class-neutral node yields `ctx.classOf
  # id == null` — the short-circuit keeps a null from a name comparison (a first-class composable selector VALUE,
  # not a marker record). NO gen-select change (select.matches threads the ctx straight to the `when` fn); NO
  # closure capture (the per-mkDen classOf lives in the injected ctx, mirroring how hasSetting reads ctx.data).
  hasClass =
    cls:
    select.when (
      id: ctx:
      let
        c = ctx.classOf id;
      in
      c != null && c == cls
    );

  # The member-edge PRODUCER (§4.7, the nestProducer posture): each collector declaring `members` (a selector)
  # contributes one `member` edge per matching scope node — `collector→member` (from = the collector entity, to
  # = the matched member). EXPOSED + gathered per-mkDen; the aggregate FOLDS over these edges (never re-
  # selects — the audit's graph-fidelity pin). Corpus-inert BY CONSTRUCTION: no collector (or a collector with
  # `members == null`) ⇒ EMPTY set, and the edges never join the live fleet trace (a separate read-only
  # surface), so byte-identity holds with no guaranteed-empty contribution to guard.
  #   collectors   — the collector entity registry `{ <name> = { class; members; … }; }`.
  #   memberIdsFor — `selector -> [ matching node id ]`: the GATHER, supplied per-mkDen (runs the selector over
  #                  all scope nodes with the class-injected ctx), so this stays free of classOfNode/structural.
  #   classNameOf  — `node id -> producing class NAME | null`: stamped on each member edge's `to`.
  memberProducer =
    {
      collectors,
      memberIdsFor,
      classNameOf,
    }:
    prelude.concatMap (
      cName:
      let
        c = collectors.${cName};
      in
      if (c.members or null) == null then
        [ ]
      else
        map (memberId: {
          id = "member:${cName}/${memberId}";
          kind = "member";
          from = {
            entityId = "collector:${cName}";
            class = c.class;
          };
          to = {
            entityId = memberId;
            class = classNameOf memberId;
          };
        }) (memberIdsFor c.members)
    ) (builtins.attrNames collectors);

  # ── §4.7: the `members` family-level SUGAR → an anonymous collector (the config→config desugar) ────────
  # `den.outputs.<f>.members = { of = <selector>; consumes = <memberProduct>; }` (the family-level spelling)
  # elaborates to a REAL anonymous collector ENTITY: the desugar is a config-rewrite run BEFORE the pipeline,
  # synthesizing `den.collectors."members:<f>" = { class; members; consumes; render }` so the anon collector
  # flows through the EXACT SAME kernel as a named one (discoverCollectors → bridge → registry → member edges →
  # render → mount). NO second N→1 arm. `render`/`contentClass` come from the family's OWN fields (the
  # family's render.output = <f>, so the anon mounts into <f> itself — the family stays the RECEIVER, the anon is
  # the PRODUCER); the member selector + product come from the `members` record (co-located, so the
  # family's own `consumes` stays unambiguously the mounted-OUT HiveInfo).
  #
  # CORPUS-INERT BY CONSTRUCTION: a fleet with no `members`-bearing family synthesizes `{ }`, so the caller
  # appends NOTHING to userModules (the module list stays byte-untouched). The `raw`/structural probe (the
  # discoverCollectors idiom, no full module eval) reads the family fields; a missing required field aborts
  # NAMED (never a bare attr-miss), and a synthetic name colliding with a user collector aborts NAMED.
  membersPrefix = "members:";
  synthesizeMembersSugar =
    userModules:
    let
      probe = merge.evalModuleTree {
        modules = [
          {
            options.den = merge.mkOption {
              default = { };
              type = merge.types.submodule {
                freeformType = merge.types.lazyAttrsOf merge.types.anything;
              };
            };
          }
        ]
        ++ userModules;
      };
      outputs = probe.config.den.outputs or { };
      userCollectors = probe.config.den.collectors or { };
      membersFamilies = builtins.filter (f: outputs.${f} ? members) (builtins.attrNames outputs);
      synthOne =
        f:
        let
          fam = outputs.${f};
          anonName = membersPrefix + f;
          cc = fam.contentClass or null;
          m = fam.members or { };
          of = m.of or null;
          mc = m.consumes or null;
          r = fam.render or null;
        in
        if userCollectors ? ${anonName} then
          throw "den.outputs: family '${f}' members-sugar synthesizes collector '${anonName}', which collides with a user `den.collectors` entry — rename the collector or the family (§4.7)"
        else if cc == null then
          throw "den.outputs: members-sugar family '${f}' declares no contentClass — the synthesized collector needs a class (§4.7)"
        else if of == null then
          throw "den.outputs: members-sugar family '${f}' declares no `members.of` — the member selector (`members = { of = <selector>; consumes = <product>; }`) is required (§4.7)"
        else if mc == null then
          throw "den.outputs: members-sugar family '${f}' declares no `members.consumes` — the member product (`members = { of = <selector>; consumes = <product>; }`) is required (§4.7)"
        else if r == null then
          throw "den.outputs: members-sugar family '${f}' declares no render — the aggregate render (its `output` names this family) is required (§4.7)"
        else
          {
            name = anonName;
            value = {
              class = cc;
              members = of;
              consumes = mc;
              render = r;
            };
          };
    in
    builtins.listToAttrs (map synthOne membersFamilies);
in
{
  inherit
    kindName
    discoverCollectors
    optionModule
    metaAugment
    collectorModules
    compile
    contentClassFn
    hasClass
    memberProducer
    synthesizeMembersSugar
    ;
}
