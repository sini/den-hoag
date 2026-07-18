# The COLLECTOR FRAMEWORK-KIND suite (vocabulary spec §4.7, spec §12 step 4c-iii). A collector is
# a first-class ENTITY of the framework `collector` kind: `den.collectors.<name> = { class; … }` bridges into
# the entity registry (`den.collector.<name>`, an id_hash-bearing root node), so a collector carries its OWN
# class content DISTINCT from any member's. The kind is framework-owned: `discoverKinds` reserves the name
# (a user kind may not be `collector`), and it enters `denMeta` by a `//`-augment GATED on `den.collectors !=
# {}` — so a fleet with no collectors has no collector kind/registry (corpus-inert). The collector's producing
# class is a PER-INSTANCE function of its own `class` field (`contentClass.collector = e: effectiveClassEntries
# .${e.class}`, the shim's per-host function precedent); a collector naming an unregistered class aborts NAMED
# (never a bare attr-miss). See REFERENCE.md.
{
  denHoag,
  ...
}:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  inherit (denHoag) hasClass;

  # A class slice is a list of `{ imports = [ … ]; }` modules (den content is module-wrapped), so the
  # marker `meta.tag = "core"` rides nested — deep-search for an attrset carrying `meta.tag == "core"`.
  hasMetaTagCore =
    v:
    if builtins.isAttrs v then
      (builtins.isAttrs (v.meta or null) && (v.meta.tag or null) == "core")
      || builtins.any hasMetaTagCore (builtins.attrValues v)
    else if builtins.isList v then
      builtins.any hasMetaTagCore v
    else
      false;

  # A collector `hive` (class colmena, own content `meta.tag = "core"`) beside an ordinary nixos member `m`
  # carrying plain nixos content with NO `meta.tag`. `colmena` is a user-registered output class (so its
  # aspect key classifies + `contentClass.collector` resolves it); the collector + the member are separate
  # parentless root entities — the contrast that proves the collector's own content is distinct.
  collectorFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.classes.colmena = { };
      config.den.collectors.hive = {
        class = "colmena";
      };
      config.den.host.m = { };
    }
    (
      { config, ... }:
      {
        config.den.aspects.hiveMeta.colmena.meta.tag = "core";
        config.den.aspects.memberPlain.nixos.services.enable = true;
        config.den.include = [
          {
            at = config.den.collector.hive;
            aspects = [ config.den.aspects.hiveMeta ];
          }
          {
            at = config.den.host.m;
            aspects = [ config.den.aspects.memberPlain ];
          }
        ];
      }
    )
  ];

  # A corpus-shaped fleet with NO `den.collectors`: the collector kind must be structurally absent.
  plainFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.host.m = { };
    }
  ];

  # A collector naming a class that is NOT registered (`phantom` ∉ den.classes ∪ built-ins) — the guard's
  # subject: reading the compiled `den.collectors` surface must abort NAMED, not silently attr-miss.
  badClassFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.collectors.ghost = {
        class = "phantom";
      };
    }
  ];

  # A collector with `class` OMITTED — the field is optional (default null), so BOTH guards must null-guard
  # BEFORE any string selector (a null attr selector is a tryEval-uncatchable coercion the `or` never
  # intercepts). Exercised on the compiled surface AND the classOf/materialization path (forcing `systems`
  # computes every node's producing class → the orphan collector's `contentClassFn`).
  omittedClassFleet = denHoag.mkDen [
    {
      config.den.schema.host.parent = null;
      config.den.collectors.orphan = { };
      config.den.host.m = { };
    }
  ];

  collectorSlice = collectorFleet.den.output.classSubtreeAt "collector:hive" "colmena";
  memberSlice = collectorFleet.den.output.classSubtreeAt "host:m" "nixos";

  # ── §4.7: SELECTOR-DRIVEN MEMBERSHIP + the member-edge producer ──
  # `hasClass "nixos"` (the top-level sugar, written literally in config — A1 ergonomics) selects the scope
  # nodes whose PRODUCING class is `nixos`. A fleet with a nixos host `n`, a darwin host `d`, and a class-
  # NEUTRAL env `e` (no contentClass) beside a collector `members = hasClass "nixos"`: the member producer must
  # emit `member` edges `collector→member` targeting ONLY the nixos node — including `n`, EXCLUDING `d` (the
  # selector rejects non-matching) AND `e` (the null-guard: a class-neutral node must not crash the gather).
  memberFleet = denHoag.mkDen [
    {
      config.den.schema.nixosHost.parent = null;
      config.den.schema.darwinHost.parent = null;
      config.den.schema.env.parent = null;
      config.den.contentClass.nixosHost = "nixos";
      config.den.contentClass.darwinHost = "darwin";
      config.den.classes.colmena = { };
      config.den.collectors.hive = {
        class = "colmena";
        members = hasClass "nixos";
      };
      config.den.nixosHost.n = { };
      config.den.darwinHost.d = { };
      config.den.env.e = { };
    }
  ];
  memberEdges = memberFleet.den.memberEdges;
  memberTargets = map (edge: edge.to.entityId) memberEdges;
in
{
  flake.tests.collectors = {
    # the collector is a real entity in its own registry with a name-derived id_hash DISTINCT from the member's
    # (two separate entities, never a shared identity).
    test-collector-is-entity = {
      expr = collectorFleet.den.registries.collector.hive.name;
      expected = "hive";
    };
    test-collector-distinct-id-hash = {
      expr =
        collectorFleet.den.registries.collector.hive.id_hash
        != collectorFleet.den.registries.host.m.id_hash;
      expected = true;
    };

    # the collector carries its OWN class content: its colmena subtree contains `meta.tag = "core"` …
    test-collector-own-content-has-meta-tag = {
      expr = hasMetaTagCore collectorSlice;
      expected = true;
    };
    # … while the member's nixos subtree does NOT (distinct content, no cross-contamination).
    test-member-content-lacks-meta-tag = {
      expr = hasMetaTagCore memberSlice;
      expected = false;
    };

    # the collector's PRODUCING class is its own `class` field (the per-instance `contentClass.collector`
    # function): it surfaces as a colmena-class content node in the terminal crossing (forces `classOfNode`
    # → `contentClassFn` for the collector node).
    test-collector-produces-its-own-class = {
      expr = builtins.hasAttr "collector:hive" collectorFleet.den.output.systems.colmena;
      expected = true;
    };

    # CORPUS-INERT: a fleet declaring no `den.collectors` has no collector kind (no augment, no registry).
    test-no-collectors-no-kind = {
      expr = plainFleet.den.registries ? collector;
      expected = false;
    };

    # a collector naming an unregistered class aborts NAMED when the compiled `den.collectors` surface is read.
    test-collector-unknown-class-aborts = {
      expr = throws badClassFleet.den.collectors;
      expected = true;
    };

    # a collector with `class` OMITTED aborts CATCHABLE-NAMED on the compiled surface …
    test-collector-omitted-class-aborts-surface = {
      expr = throws omittedClassFleet.den.collectors;
      expected = true;
    };
    # … AND on the classOf/materialization path (forcing `systems` runs the orphan's `contentClassFn`) — the
    # null must never reach a string selector (which would be tryEval-uncatchable, crashing the fold).
    test-collector-omitted-class-aborts-materialization = {
      expr = throws omittedClassFleet.den.output.systems;
      expected = true;
    };

    # the `members = hasClass "nixos"` selector INCLUDES the nixos node as a member edge target …
    test-member-includes-matching-class = {
      expr = builtins.elem "nixosHost:n" memberTargets;
      expected = true;
    };
    # … and EXCLUDES the darwin node (the selector rejects non-matching — exclusion, not just inclusion).
    test-member-excludes-nonmatching-class = {
      expr = builtins.elem "darwinHost:d" memberTargets;
      expected = false;
    };
    # the member edges are `collector→member`: from = the collector entity, kind = "member".
    test-member-edges-from-collector = {
      # self-standing: `memberEdges != []` guards the vacuous-truth pass (never leans on the inclusion test).
      expr =
        memberEdges != [ ]
        && builtins.all (edge: edge.from.entityId == "collector:hive" && edge.kind == "member") memberEdges;
      expected = true;
    };
    # the NULL-GUARD: the gather runs over a class-neutral (contentClass-null) env node without crashing —
    # forcing the whole member-edge set evaluates cleanly (the env node is simply not a member).
    test-member-gather-null-safe = {
      expr = throws memberEdges || builtins.elem "env:e" memberTargets;
      expected = false;
    };
    # CORPUS-INERT: a fleet with no `den.collectors` emits an EMPTY member producer set (byte-identical trace).
    test-no-collectors-no-member-edges = {
      expr = plainFleet.den.memberEdges;
      expected = [ ];
    };
  };
}
