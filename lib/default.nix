{
  prelude,
  algebra,
  types,
  merge,
  schema,
  aspects,
  graph,
  scope,
  resolve,
  select,
  bind,
  dispatch,
  class,
  edge,
  product,
  settings,
  demand,
  pipe,
  flake,
}:
let
  errors = import ./errors.nix;
  # Two-level edge identity (assembly/instance/edge hashes + fill-graph acyclicity) — pure over the
  # builtins, no gen dep (REFERENCE.md). Exposed through `internal` for the substrate suite; the
  # substrate consumers reach it there.
  identity = import ./identity.nix { inherit prelude; };
  # The edge-kind registry (den.edges): pre-registered vocabulary + validation (§2.2), the override tier
  # (§2.4), the synthetic edge-assembly pipeline (§2.1), and the cell/containment nest-edge producer
  # (§4.2/§4.6). Its `output` stratum is dogfooded into the fleet strata order below; the compiled table
  # rides `den.edges`. `assembleEdges` needs the identity module + the gen-edge lib (to stamp `kind` on the
  # constructed records); `nestProducer` additionally threads the graft dispatch + mode engine — the
  # forward references to `receiversLib`/`nestLib` (defined below) are cycle-free (neither depends on
  # `edgesLib`, and only `nestProducer` forces them).
  edgesLib = import ./edges.nix {
    inherit prelude identity edge;
    inherit (receiversLib) resolveReceiver;
    inherit (nestLib) executeNest checkSingular;
  };
  # stratum-scope (§2.3): the capability-scope arithmetic (edgesBelowStratum / ceilingGate / indexOf /
  # strataLt) shared by the relation accessors and the derive compute. See stratum-scope.nix.
  strataScopeLib = import ./stratum-scope.nix { inherit prelude; };
  # production-guard (§8 law 5): the bounded-NTA registration law for a node-spawning production (`emit =
  # nodes`). A STANDALONE guard — no `den.productions` user surface yet (Phase 5); Phase-5's productions compile
  # calls it at registration. Inert on every current corpus. See production-guard.nix.
  productionGuardLib = import ./production-guard.nix { strataScope = strataScopeLib; };
  # den.relations (§5): the relation registry desugared onto the den.edges edge-kind registry (§2.2
  # one-registry) — a relation → one edge-kind @resolution carrying its inverse label. See concern-relations.nix.
  relationsLib = import ./concern-relations.nix {
    inherit prelude;
    strataScope = strataScopeLib;
  };
  # den.derived (§5): laws-gated synthesized attributes over the resolution graph — the field validator. See
  # concern-derived.nix.
  derivedLib = import ./concern-derived.nix {
    inherit prelude;
    strataScope = strataScopeLib;
  };
  entity = import ./entity.nix { inherit prelude schema merge; };
  # The collectors concern (§4.7): the framework `collector` entity kind — the `den.collectors` option, the
  # denMeta `//`-augment (gated on collectors present), the schema-decl + registry bridge, the compiled-surface
  # class validation, and the per-instance function-form `contentClass`. Pure wiring over gen-schema/gen-merge.
  collectorsLib = import ./concern-collectors.nix {
    inherit
      prelude
      schema
      merge
      select
      ;
  };
  fleet = import ./fleet.nix { inherit prelude product errors; };
  buildRootsLib = import ./build-roots.nix { inherit prelude; };
  scopeAdapter = import ./scope-adapter.nix { inherit prelude select; };
  concernQuirks = import ./concern-quirks.nix { inherit prelude pipe errors; };

  # The demand concern (§B demand stratum): the demand channel, kind registration, the fleet
  # resolveAll wrapper, and the resources/wiring → gen-edge constructors. Pure wiring over gen-demand
  # (cascade), gen-pipe (the channel), and gen-edge (edge records) — Law A1.
  demandLib = import ./demand.nix {
    inherit
      prelude
      demand
      pipe
      edge
      resolve
      scopeAdapter
      ;
  };

  # The `projects` facet (§2.9 / A14): the aspect-schema selector domain (`hasSetting` + schemaContext)
  # and the projection-layer expansion. Pure vocabulary over gen-select; resolved-settings consumes
  # `projectionLayers`, `hasSetting` is exposed at the top for writing `projects` rules standalone.
  projectsLib = import ./projects.nix { inherit prelude select errors; };

  # Settings compilation surface (schema + scoped-override layers + ref re-export, §2.6/§4.3) and the
  # linearization declaration surface (§2.7). Both are pure vocabulary over gen-settings / gen-product.
  settingsLib = import ./settings.nix { inherit prelude settings errors; };
  linearizationLib = import ./linearization.nix { inherit prelude product errors; };

  # den-hoag's output classes — the class-separated content buckets on every aspect, and the
  # class-tag vocabulary for quirk contributions (§2.5). The full class registry (wrap/instantiate/
  # share) is Task 6/A10; Task 5 needs only class ENTRIES to tag with, built here from the class
  # names with a stable identity (id_hash) so gen-pipe's duck-typed entry comparison and den's
  # cross-class discipline both key off a real identity (Law A2), never a bare string.
  classNames = [
    "nixos"
    "darwin"
    "home-manager"
    "k8s-manifests"
  ];
  classEntries = prelude.genAttrs classNames (name: {
    id_hash = builtins.hashString "sha256" "den-class:${name}";
    inherit name;
  });

  # The declaration vocabulary (verb `declare`) + the policy compiler. `declare` supplies the
  # tagged constructors, stratum classifier, and identity-law checks the structural stratum reads
  # as its `declarations` DEP; concern-policies compiles `den.policies` onto gen-dispatch rules.
  declare = import ./declarations.nix {
    inherit
      prelude
      dispatch
      pipe
      errors
      ;
  };
  concernPolicies = import ./concern-policies.nix {
    inherit
      prelude
      dispatch
      declare
      errors
      ;
  };

  # The STAGED ROOT-RESOLUTION pre-pass (design note 2026-07-11 §2/§3(ii), slice R1): the kind-ordered
  # dispatch over ROOT nodes, run BEFORE the fleet product, that routes policy-emitted MEMBERSHIP into the
  # fleet (the deferred Task 4) and folds RELATION-carried bindings into target roots' ctx. Pure gen-
  # prelude + gen-dispatch wiring over the `declare` vocabulary; consumed per-mkDen below (`prePass`).
  stagedResolution = import ./staged-resolution.nix {
    inherit
      prelude
      dispatch
      declare
      errors
      ;
  };

  # The aspects concern — compiles `den.aspects` onto gen-aspects (the neededBy/guard/drop surface
  # + §2.2 key dispatch). This TOP-LEVEL instance is used ONLY for `internal.classifyKey` (which reads
  # `classNames`, never moduleArgs), so `kindNames = [ ]` here is inert — the eval-load-bearing instance is
  # the per-mkDen `denAspects` (below), which threads the DISCOVERED kinds. `aspectSchema.mkAspectOption`
  # declares `options.den.aspects` from that kind-aware instance.
  concernAspects = import ./concern-aspects.nix {
    inherit
      prelude
      aspects
      merge
      classNames
      errors
      ;
    kindNames = [ ];
  };

  # Attribute assembly (structural attrs 1–6 + resolution attrs 7/9 + collection/settings/output) + the
  # gen-resolve seam.
  attributesLib = import ./attributes/default.nix {
    inherit
      prelude
      scope
      resolve
      dispatch
      aspects
      select
      pipe
      product
      settings
      settingsLib
      scopeAdapter
      edge
      bind
      class
      merge
      errors
      graph
      ;
    projects = projectsLib;
    declarations = declare;
    strataScope = strataScopeLib;
  };

  # The classes concern (§2.4) + the terminal crossing (§2.10, Law A15). `concernClasses.compile`
  # turns `den.classes` declarations into class config records; `terminalLib` is the ONE gen-flake
  # crossing (lib/output/terminal.nix) — den-hoag stays nixpkgs-free by defaulting classes to the
  # `collect` terminal (nixpkgs-free), with `crossNixos` available for a real build.
  concernClasses = import ./concern-classes.nix { inherit prelude bind; };
  # The merge-discipline registry (den.disciplines): compile + laws-ladder validation (§5). The closure
  # gate (edges.nix) validates a closure kind's discipline against the compiled table; the framework
  # instance names are reserved here; the framework seeds the three shipped merge orders. Pure Law A1.
  concernDisciplines = import ./concern-disciplines.nix { inherit prelude algebra pipe; };
  # The typed-product registry (den.products) + the single-step conversion registry (den.conversions):
  # compile + mode-set/reserved validation (§4.1). Materialization reads modes off the compiled table;
  # receivers call `checkConsumes` at a consumes position. Pure Law A1 (mapAttrs + validation).
  productsLib = import ./products.nix { inherit prelude; };
  # The resolution-product registry (den.resolutionProducts): compile + reserved-name validation (§5). The
  # resolution-facet counterpart of den.products — a derived's `provides` validates against THIS registry,
  # a distinct namespace from the materialization faces. Pure Law A1 (mapAttrs + validation).
  resolutionProductsLib = import ./resolution-products.nix { inherit prelude; };
  # The render registry (den.renders): the D7 promotion of the shipped `{ evaluator; output }`
  # instantiation record into a full §4.3 registry row. PER-FLEET compile (the built-in nixos/darwin
  # evaluators close over the fleet's own nixpkgs/darwin inputs) — invoked inside the mkDen closure.
  rendersLib = import ./renders.nix { inherit prelude; };
  # The receives registry (den.kinds.<outerKind>.receives.<slot>): the graft-site rows, validated (§4.2), +
  # the slot ≻ class dispatch (§4.2 F4) executed as a gen-graph visible query over the kind-include graph.
  # Mode derives via the products table; the outer-kind + includes + render names are checked. PER-FLEET
  # compile (the render-name check reads the per-fleet render rows) — invoked inside the mkDen closure.
  # `graph` is the gen-graph lib (the labeled-query calculus) — threaded from the UNSHADOWED outer-scope arg
  # here, the same seam productsLib rides (the mkDen-local `graph = graphEscape {…}` shadow is deeper in).
  receiversLib = import ./receivers.nix {
    inherit prelude productsLib graph;
  };
  # The query spine (den.query, §3/§5): a pure lowering of the §3 follow-grammar query over a SUPPLIED flat
  # labeled edge list onto gen-graph's query engine — the SAME unshadowed outer `graph` the receivers dispatch
  # rides (the mkDen-local `graph = graphEscape {…}` shadow has no `.query`). Source-agnostic; see lib/query.nix.
  queryLib = import ./query.nix {
    inherit prelude graph;
  };
  # The UNSHADOWED gen-graph lib alias — the relation producer (§9) reverses each relation kind's forward edges
  # via `genGraphLib.transpose` (Mokhov 2017 §4.3) instead of a hand-rolled from/to swap. Inside the mkDen
  # closure `graph` is shadowed by the read-only `graph = graphEscape {…}` surface (no `.transpose`), so the
  # producer reaches the outer labeled-graph calculus through this alias (the seam receiversLib/queryLib ride).
  genGraphLib = graph;
  # The output-families registry (den.outputs.<family>): the root-as-entity §4.4 rows — the fleet's
  # TOP-LEVEL output faces (nixosConfigurations/darwinConfigurations/a user target) as validated DATA, one
  # row per family. Mode derives via the products table; `render`/`params`/`requires` are name-checked
  # against the per-fleet render rows / the axis registry / the products table. PER-FLEET compile (the
  # render-name check reads the per-fleet render rows), invoked inside the mkDen closure like receivesTable.
  outputsLib = import ./outputs.nix {
    inherit prelude productsLib;
  };
  # The nest-mode EXECUTION engine (§4.2 mode taxonomy): `executeNest { row; inner; ctx; conversions ? {};
  # renders ? {} }` turns a compiled receives row + the inner entity's product face into a mode-tagged
  # CONTRIBUTION the output fold places. The live-edge counterpart to receiversLib (which DECLARES + dispatches
  # the graft-site rule); this EXECUTES it. The per-fleet conversion table (§4.1) AND render table (§4.3, the
  # artifact evaluator/face + the extend `extendsVia`) are passed at CALL time (the receivers pattern) — a
  # static registry cannot hold the per-fleet evaluator, so the engine holds no tables or evaluators.
  nestLib = import ./nest.nix {
    inherit prelude;
  };
  terminalLib = import ./output/terminal.nix { inherit bind flake; } { nixpkgs = null; };
  # The greenfield v2 flake-parts mount (§4.4/§4.6): a built den fleet → a flake-parts module handing the
  # fleet's transposed family map to `config.flake`. Dep-less (a pure one-line handoff); see output/flake-adapter.nix.
  flakeAdapter = import ./output/flake-adapter.nix;
  graphEscape = import ./graph-escape.nix { inherit edge; };
  structuralAttributes = attributesLib.structural;
  runResolve = attributesLib.runResolve;
  inherit (buildRootsLib) buildRoots parseParent;

  # mkDen assembles the four concerns; Tasks 1–11 extend it. Task 1: entity registries
  # (gen-schema) + the fleet restricted product (gen-product). Task 2: scope roots +
  # structural stratum (attributes 1–6) over gen-resolve/gen-scope.
  mkDen =
    userModules0:
    let
      # ── §4.7: the `members` family-level SUGAR pre-pass (config→config desugar, run BEFORE the pipeline).
      # `den.outputs.<f>.members = { of; consumes }` synthesizes a REAL anonymous collector
      # `den.collectors."members:<f>"`, appended to the user modules HERE so it flows through the EXACT SAME
      # kernel as a named collector (discoverCollectors → bridge → registry → member edges → render → mount) —
      # no second N→1 arm. CORPUS-INERT BY CONSTRUCTION: no `members`-bearing family ⇒ `{ }` ⇒ NOTHING appended
      # (the module list is byte-untouched, so `discoverCollectors userModules` is byte-identical).
      synthCollectors = collectorsLib.synthesizeMembersSugar userModules0;
      userModules =
        userModules0
        ++ prelude.optional (synthCollectors != { }) { config.den.collectors = synthCollectors; };

      # §2.2/§27 raw channel keys — probe the declared quirk channel names (a static-decl probe, like
      # `discoverKinds`), then build a CHANNEL-AWARE aspect schema: each channel key is a `raw` option
      # (so an emission rides untouched, never freeform-absorbed into a nested aspect) and `classifyKey`
      # gains its three-branch channel branch. Rebuilt per mkDen because channels are user config.
      discoveredChannels = entity.discoverChannels userModules;
      channelSet = prelude.genAttrs discoveredChannels (_: true);

      # §2.2 REGISTERED-CLASS set — the built-in `classNames` UNION the fleet's DECLARED classes
      # (`config.den.classes.<name>`, a static-decl probe like the channel probe). The spec's three-branch
      # dispatch keys on a "registered class name", not a built-in one: a declared class joins the class
      # branch of `classifyKey`, gains a `class` content bucket (gen-aspects `cnf.classes`), a class entry,
      # and a terminal — everything a built-in class has. `classNames` (the core constant) is UNCHANGED;
      # the extension is per-fleet, computed here from user config. `effectiveClassEntries` mirrors the
      # top-level `classEntries` identity convention (sha256 "den-class:<name>") over the widened set.
      discoveredClasses = entity.discoverClasses userModules;
      effectiveClassNames =
        classNames ++ builtins.filter (n: !(builtins.elem n classNames)) discoveredClasses;
      effectiveClassEntries = prelude.genAttrs effectiveClassNames (name: {
        id_hash = builtins.hashString "sha256" "den-class:${name}";
        inherit name;
      });

      denAspects = import ./concern-aspects.nix {
        inherit
          prelude
          aspects
          merge
          errors
          ;
        classNames = effectiveClassNames;
        quirkChannels = channelSet;
        # Kind-generic aspect moduleArgs — the DECLARED schema kinds (assembly §2.2), so an aspect body may
        # destructure any custom kind (`{ datacenter, rack, ... }:`) exactly like `{ host, user, ... }:`,
        # with ZERO kind-name literals in core. `denMeta` (= `entity.discoverKinds userModules`, defined
        # below in this `let`) is the probed schema; a fleet declaring only host/user is byte-identical.
        kindNames = builtins.attrNames denMeta;
      };

      # den-managed module: the fleet membership channel. Task 1 bootstrap surface — the
      # fixture sets these tuples directly. Task 3 dispatches `member` declarations (they land in
      # the `declarations` attribute's structural group); routing them back into this membership
      # channel is part of the Task 4 P-tree/edge wiring.
      membershipDecl = {
        options.den.membership = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Fleet membership tuples { coords; via ? null; } (A5).";
        };
      };

      # den.policies.<name> = ctxFn — the relationships concern. Each value is a context
      # function (opaque, function-valued), so `raw` holds it without a merge attempt.
      policiesDecl = {
        options.den.policies = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Relationship policies: `<name> = ctx: [ declarations ]` (r2 §B).";
        };
      };

      # den.aspects.<name> — the behavior concern (aspectsType). Compiled onto gen-aspects by
      # concern-aspects (the CHANNEL-AWARE schema above); each entry carries
      # `key`/`neededBy`/`meta.guard`/`meta.drop`/`includes` + a `raw` option per registered channel.
      aspectsDecl = {
        options.den.aspects = denAspects.aspectSchema.mkAspectOption { };
      };

      # den.classes.<name> — the classes concern (§2.4). Each entry declares `wrap`/`instantiate`/`share`;
      # absent ⇒ den-hoag's defaults (bind-wins merge, validators on, the nixpkgs-free `collect`
      # terminal). `raw` holds each record (its `instantiate` is a function) unmerged.
      classesDecl = {
        options.den.classes = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Output class registrations: `<name> = { wrap ? {}; instantiate ? <default>; share ? {}; }` (§2.4).";
        };
      };

      # den.include — the static entity-scoped aspect-inclusion surface (r2 §370 `directAspects`):
      # each `{ at = <entity>; aspects = [ <aspect> ]; }` seeds its aspects at exactly the entity's
      # own scope node (node-local, so an include at an ancestor does not seed descendants).
      includeDecl = {
        options.den.include = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Static entity-scoped aspect inclusions: [ { at = <entity>; aspects = [ <aspect> ]; } ].";
        };
      };

      # den.quirks.<name> — the data concern (§2.5). Each entry declares a gen-pipe channel plus
      # optional dataflow `ops` and cross-class `adapters`; concern-quirks assembles every quirk (and
      # its ops) into ONE fleet-level compose. `raw` holds the (channel/ops/adapters) record unmerged.
      quirksDecl = {
        options.den.quirks = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Quirk channels: `<name> = { channel ? {}; ops ? []; adapters ? []; }` (§2.5).";
        };
      };

      # den.linearization.dims — the slice-order declaration surface (§2.7): a total order on the
      # product DIMENSIONS as KIND entries (identity law A2), least→most specific. Empty (the default)
      # means "canonical" — den-hoag fills it with the name-sorted kind entries, preserving the pre-
      # concern behavior. `raw` holds the entry list unmerged.
      linearizationDecl = {
        options.den.linearization.dims = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Slice-order dimensions (§2.7): [ <kind entry> ], least→most specific (identity law A2).";
        };
      };

      # den.settings.layers — the scoped-override surface (§2.6 source 2), the `at`-record form:
      # [ { at = <partial coords, entries>; of = <aspect entry>; set = { <field> = <value|ref> }; via ? null } ].
      # `raw` holds each layer record unmerged (its `at`/`of` are entries, `set` a patch).
      settingsDecl = {
        options.den.settings.layers = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Scoped settings overrides (§2.6): [ { at; of; set; via ? null } ].";
        };
      };

      # den.contentClass.<kind> — the class-tag vocabulary (§2.1/§2.5): the output class a kind's
      # scopes produce, as a class-name string (resolved to the class entry) or a class entry; a kind
      # with no mapping is class-neutral (e.g. env). den v2's canonical home is
      # `den.schema.<kind>.contentClass`; gen-schema kinds carry no such field, so den-hoag threads it
      # as a parallel den-managed map. Absent for every kind ⇒ a policy-free / quirk-free fleet stays
      # entirely class-neutral, exactly as before this concern existed.
      contentClassDecl = {
        options.den.contentClass = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Kind -> content class (class name or entry): the class a kind's scopes produce (§2.5).";
        };
      };

      # den.strata.insert.<name> = { after = "<existing>"; } — the stratum-order extension surface
      # (spec §5). Each name-keyed insert places a NEW stratum densely after its `after` anchor; the
      # compiled order (declarations.compileStrata) becomes the stratum order every consumer reads.
      # `raw` holds each `{ after }` record unmerged. Absent ⇒ the seeded order
      # (structural < resolution < collection < demand), byte-identical.
      strataDecl = {
        options.den.strata.insert = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Stratum-order inserts: `<name> = { after = \"<existing stratum>\"; }` — dense insertion after the anchor (spec §5).";
        };
      };

      # den.edges.<kind> — the edge-kind registry (§2.2). Each entry describes a typed-edge kind:
      # `{ data ? null; requires ? null; produces ? null; discipline ? null; inverse ? null;
      # closure ? false; stratum ? "resolution"; }`. `raw` holds each record unmerged (its `data` may be
      # a schema). Absent ⇒ a fleet with only the framework-pre-registered kinds. The registry DESCRIBES
      # kinds; emission rewiring onto the substrate is a later step.
      edgesDecl = {
        options.den.edges = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Edge-kind registry: `<kind> = { data ? null; requires ? null; produces ? null; discipline ? null; inverse ? null; closure ? false; stratum ? \"resolution\"; }` (§2.2).";
        };
      };

      # den.relations.<name> — the relation registry (§5). Each entry `{ inverse ? null; data ? {}; }` desugars
      # to ONE `den.edges` kind @resolution (closure = false), carrying `inverse` as the reverse-query label
      # (§2.2 one-registry). `raw` holds each record unmerged. Absent ⇒ a fleet with no relations (the producer
      # emits nothing). The registry DESCRIBES relations; the live edge SOURCE + the per-entity accessor are the
      # downstream steps.
      relationsDecl = {
        options.den.relations = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Relation registry (§5): `<name> = { inverse ? null; data ? {}; }` — desugars to a den.edges kind @resolution, closure = false (§2.2 one-registry); `inverse` is the reverse-query label.";
        };
      };

      # den.derived.<name> — laws-gated synthesized attributes (§5). Each entry `{ over; direction; stratum;
      # provides; discipline ? null; closure ? false; negates ? [ ]; derive }` synthesizes a value over the
      # resolution graph, capability-scoped by `stratum` (§2.3) and laws-gated by `closure`/`discipline`. `negates`
      # names the relation kinds read under NEGATION (throwing-gate + strictly-above disciplined, §2.3). `raw`
      # holds each record unmerged (its `derive` is a function). Absent ⇒ a fleet with no derived attributes.
      derivedDecl = {
        options.den.derived = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Derived-attribute registry (§5): `<name> = { over; direction; stratum; provides; discipline ? null; closure ? false; negates ? [ ]; derive }` — a laws-gated synthesized attribute over the resolution graph; `provides` names a den.resolutionProducts face, `negates` the relation kinds read under stratified negation.";
        };
      };

      # den.disciplines.<name> — the merge-discipline registry (§5). Each entry declares the algebra a
      # merge site obeys: `{ laws; empty; combine; dedup ? null; order ? null; }` — `laws` names the
      # ladder class (ordered-monoid / commutative-monoid / join-semilattice / shadow), `empty`/`combine`
      # are the identity + binary operation. `raw` holds each record unmerged (its `combine` is a
      # function). Absent ⇒ a fleet registering no USER disciplines (the framework instances are always
      # seeded). The registry DESCRIBES disciplines; the closure edge-gate reads the compiled table.
      disciplinesDecl = {
        options.den.disciplines = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Merge-discipline registry: `<name> = { laws; empty; combine; dedup ? null; order ? null; }` (§5).";
        };
      };

      # den.products.<name> — the typed-product registry (§4.1). Each entry declares a materialization
      # payload's mode: `{ mode; nestable ? true; }` — `mode` ∈ { content artifact extend value }, `nestable`
      # gates whether the product may appear in a receiver's `consumes`. `raw` holds each record unmerged.
      # Absent ⇒ a fleet with only the framework-pre-registered faces. The registry DESCRIBES products; the
      # payload SCHEMAS arrive with mode execution.
      productsDecl = {
        options.den.products = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Typed-product registry: `<name> = { mode; nestable ? true; }`, mode ∈ { content artifact extend value } (§4.1).";
        };
      };

      # den.resolutionProducts.<name> — the resolution-product registry (§5). Each entry names a typed
      # payload a resolution-facet synthesizer (a `den.derived`'s `provides`) emits: `{ schema ? null; }`.
      # A DISTINCT namespace from den.products (materialization): a derived's `provides` validates here, so
      # a materialization face named as a derived's `provides` fails naturally. `raw` holds each record
      # unmerged. Absent ⇒ a fleet registering no resolution products (the framework seeds none yet).
      resolutionProductsDecl = {
        options.den.resolutionProducts = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Resolution-product registry: `<name> = { schema ? null; }` — the payload faces a den.derived `provides` (§5), distinct from den.products materialization faces.";
        };
      };

      # den.conversions."<from>-><to>" — the single-step conversion registry (§4.1). Each entry declares the
      # materialization for a (produces, consumes) mismatch: `{ via = fn; }`. `raw` holds each record
      # unmerged (its `via` is a function). Uniqueness is GLOBAL per pair by keying; conversions are
      # single-step (no chain search). Absent ⇒ a fleet with no declared conversions.
      conversionsDecl = {
        options.den.conversions = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Single-step conversion registry: `\"<from>-><to>\" = { via = fn; }` (§4.1).";
        };
      };

      # den.renders.<name> — the render registry (§4.3, the D7 promotion). Each entry declares how a class
      # materializes: `{ evaluator ? null; provision ? null; adapt ? null; face ? null; produces ? null;
      # requires ? []; params ? []; extendsVia ? null; compatibleWith ? null; output ? null; }`. `raw`
      # holds each record unmerged (its `evaluator`/`provision`/`adapt` are functions). The built-in
      # nixos/darwin rows are seeded PER-FLEET from `den.nixpkgs`/`den.darwin`; a user row registers beside
      # them. Absent ⇒ a fleet with only the built-in system faces.
      rendersDecl = {
        options.den.renders = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Render registry: `<name> = { evaluator ? null; produces ? null; requires ? []; params ? []; output ? null; … }` (§4.3).";
        };
      };

      # den.kinds.<outerKind> — the receives registry (§4.2). Each entry carries `receives.<slot> = { at;
      # consumes; arity ? "many"; render ? null; provide ? null; adapt ? null; identity ? null; shape ?
      # null; multiplicity ? "error"; includes ? []; }` — the graft-site rule as data on the outer kind.
      # `raw` holds each record unmerged (its `at`/`provide`/`adapt`/`identity` are functions). Absent ⇒ a
      # fleet declaring no receives rows. `den.kinds` is a FRAMEWORK concern option — a kind may not be
      # named `kinds` (entity.nix guards the collision at kind discovery).
      kindsDecl = {
        options.den.kinds = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Receives registry: `<outerKind>.receives.<slot> = { at; consumes; arity ? \"many\"; multiplicity ? \"error\"; includes ? []; … }` (§4.2).";
        };
      };

      # den.outputs.<family> — the output-families registry (§4.4). Each entry declares a top-level output
      # face: `{ at; consumes; render ? null; params ? []; requires ? []; }` — the root-as-entity rule as data
      # (the fleet's nixosConfigurations/darwinConfigurations/a user target). `raw` holds each record unmerged
      # (its `at` is a function). Absent ⇒ a fleet declaring no output families. `at`/`consumes` are required;
      # `render` names a registered render, `params` names a known axis (today `system`, over `den.systems`),
      # `requires` names registered products. A family may ALSO carry `members = { of; consumes }` + `contentClass`
      # — the §4.7 members-sugar fields, absorbed via this freeform `raw` row (a strict submodule here would
      # silently break the sugar's structural probe).
      outputsDecl = {
        options.den.outputs = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Output-families registry: `<family> = { at; consumes; render ? null; params ? []; requires ? []; }` (§4.4).";
        };
      };

      # den.systems — the axis-value surface (§4.4): a plain list of system strings, the domain of a family's
      # `system` param. Empty (the default) ⇒ a fleet declaring no per-system axis; the params validation only
      # reads the axis NAMES, so a `system`-param family compiles regardless of this list's contents.
      systemsDecl = {
        options.den.systems = merge.mkOption {
          type = merge.types.listOf merge.types.str;
          default = [ ];
          description = "System axis values (§4.4): the domain of a family's `system` param, e.g. [ \"x86_64-linux\" ].";
        };
      };

      # den.axes — the user-declarable materialization axes (§4.4): `<name> = { values = [ <string> ]; }`, the
      # finite domains a family's `params` fans over. `system` is framework-reserved (its domain is den.systems);
      # a user `den.axes.system` aborts NAMED at the axis registry.
      axesDecl = {
        options.den.axes = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "User-declarable materialization axes (§4.4): `<name> = { values = [ <string> ]; }`; a family's `params` fans the cartesian over them. `system` is reserved (its domain is den.systems).";
        };
      };

      # den.overrides — the pre-identity-freeze match/rewrite tier (§2.4). An ordered list of
      # `{ match = { kind ?; from ?; to ?; data ? {}; }; rewrite = <data-patch> | null; }`: a framework
      # edge intent passes through BEFORE its edgeId, first match wins, `rewrite = null` suppresses.
      # `raw` holds each record unmerged (its `match`/`rewrite` are structural data, `rewrite` maybe null).
      # Absent ⇒ an override-free fleet (every framework edge intent passes through untouched).
      overridesDecl = {
        options.den.overrides = merge.mkOption {
          type = merge.types.listOf merge.types.raw;
          default = [ ];
          description = "Pre-identity-freeze edge overrides: [ { match = { kind ?; from ?; to ?; data ? {}; }; rewrite = <patch> | null; } ] (§2.4).";
        };
      };

      # den.demandKinds.<name> — the demand-kind registry (§B demand stratum). Each entry declares a
      # gen-demand kind: `{ below ? []; resolve; dedupKey ? null; fold ? null; }` (functions, so `raw`
      # holds it unmerged); `below` names the kinds this one may cascade into (downward-only DAG,
      # checked at registration). Absent ⇒ a demand-free fleet (empty kind set, no cascade).
      demandKindsDecl = {
        options.den.demandKinds = merge.mkOption {
          type = merge.types.lazyAttrsOf merge.types.raw;
          default = { };
          description = "Demand kinds: `<name> = { below ? []; resolve; dedupKey ? null; fold ? null; }` (§B).";
        };
      };

      # den.demandContext — the STATIC context passed verbatim to every demand resolver (gen-demand
      # `ctx`). It is opaque, config-independent data; the engine never adds resolved state to it, so a
      # resolver desugars a composite from its own fields + this ctx alone (emission ⊥ consumption).
      demandContextDecl = {
        options.den.demandContext = merge.mkOption {
          type = merge.types.raw;
          default = { };
          description = "Static context passed verbatim to every demand resolver (§B); never resolved state.";
        };
      };

      # den.nixpkgs — the nixpkgs FLAKE (carrying `.lib.nixosSystem`) the `nixos` class's terminal crosses
      # through (§2.10, the ONE gen-flake boundary). It rides `raw` (single-value passthrough, never merged
      # or type-walked): lib/** stays nixpkgs-lib-free — nixpkgs enters as inert CONFIG data a consumer
      # supplies, forced only when a nixos member is built at the terminal, never during the pure graph
      # walk. Absent (null, the default) ⇒ the fleet stays pure: the `nixos` class defaults to the
      # nixpkgs-free `collect` terminal and `nixosConfigurations` are collect artifacts, not NixOS systems.
      nixpkgsDecl = {
        options.den.nixpkgs = merge.mkOption {
          type = merge.types.raw;
          default = null;
          description = "The nixpkgs flake the `nixos` class terminal crosses through (§2.10); null ⇒ nixpkgs-free `collect`.";
        };
      };

      # den.darwin — the nix-darwin FLAKE (carrying `.lib.darwinSystem`) the `darwin` class's terminal
      # crosses through: the darwin SIBLING of `den.nixpkgs` (§2.10). `darwin` is a native output class
      # (a macOS system type), peer to `nixos`; the crossing routes through gen-flake's GENERIC
      # `mkSystemTerminal` with `darwin.lib.darwinSystem` as the evaluator (output/terminal.nix
      # `crossDarwin`) — gen-flake names no system, the darwin knowledge lives in this crossing. Rides
      # `raw` like nixpkgs — inert config data, forced only at a darwin member's
      # build, never during the pure graph walk. Absent (null, the default) ⇒ the `darwin` class defaults
      # to the nixpkgs-free `collect` terminal (`darwinConfigurations` are collect artifacts). den-hoag's
      # own CI runs the collect path; a REAL darwin build (the ship-gate, against a corpus with a
      # nix-darwin input) supplies it.
      darwinDecl = {
        options.den.darwin = merge.mkOption {
          type = merge.types.raw;
          default = null;
          description = "The nix-darwin flake the `darwin` class terminal crosses through (§2.10); null ⇒ nixpkgs-free `collect`.";
        };
      };

      # den.interpret — the gen-edge source-interpreter seam (§2.6, the A15 external-source path). Native
      # den-hoag constructs only `collected`/`value` edge sources, so the default `{ }` is complete;
      # an external consumer sets `den.interpret = { synthesize = …; rewalk = …; }` here to teach the output fold how
      # to interpret its external `synthesize`/`rewalk` sources — WITHOUT editing lib/attributes/output-modules.nix.
      # `raw` (opaque functions), forced only when an external source is actually folded (never for a native fleet).
      interpretDecl = {
        options.den.interpret = merge.mkOption {
          type = merge.types.raw;
          default = { };
          description = "gen-edge source interpreters `{ synthesize ? …; rewalk ? …; }` (§2.6, the external source-interpreter seam).";
        };
      };

      # den.enrichBindings — the POST-RESOLUTION binding-enrichment seam (the terminal-binding twin of
      # `den.interpret`). An external consumer may enrich a node's entity bindings AFTER resolution: the hook
      # `{ id; resolvedAspects; bindings } -> bindings'` runs inside `bindingsAt` (output-modules.nix), so a
      # binding a class module destructures (`host`/`user`/…) can carry a stamped closure (e.g. a projected
      # membership accessor). THE LAZINESS LAW (A17): `resolvedAspects` is the node's attribute-7 THUNK — the
      # hook must not force it at stamp time, only a closure it stamps (called later) may. Native den-hoag
      # supplies the identity default, so the native binding surface is byte-identical; an external consumer
      # sets this WITHOUT editing output-modules.nix. `raw` (an opaque function), forced only at a terminal.
      enrichBindingsDecl = {
        options.den.enrichBindings = merge.mkOption {
          type = merge.types.raw;
          default = { bindings, ... }: bindings;
          description = "Post-resolution binding-enrichment hook `{ id; resolvedAspects; bindings } -> bindings'` run in `bindingsAt`; must preserve laziness (A17). Native default = identity.";
        };
      };

      # den.enrichContext — the POST-INHERITANCE resolution-ctx enrichment seam (the aspect-fn twin of
      # `den.enrichBindings`). An external consumer may enrich the resolution ctx a parametric aspect-fn
      # receives: the hook `{ id; resolvedAspects; bindings } -> bindings'` runs on the enriched-context BEFORE
      # it is handed to `forwardExpand` (resolved-aspects.nix), so a bare-fn kind-include destructuring an
      # entity binding (`host`/`user`/…) can carry a stamped closure (e.g. a projected resolved-aspect
      # accessor) at RESOLUTION depth, not only at the terminal. THE LAZINESS LAW (A17): `resolvedAspects` is
      # the node's OWN attribute-7 value — the converged fix knot (resolved-aspects reads itself, kind=circular)
      # — so the hook MUST NOT force it at stamp time. A closure it stamps may read it, but ONLY at a VALUE
      # position forced AFTER convergence (the memoized knot); a KEY/structure-position read black-holes the
      # circular attribute LOUD (`infinite recursion`). Native den-hoag supplies the identity default, so the
      # resolution ctx is byte-identical; an external consumer sets this WITHOUT editing resolved-aspects.nix.
      # `raw` (an opaque function), forced only during resolution.
      enrichContextDecl = {
        options.den.enrichContext = merge.mkOption {
          type = merge.types.raw;
          default = { bindings, ... }: bindings;
          description = "Post-inheritance resolution-ctx enrichment hook `{ id; resolvedAspects; bindings } -> bindings'` applied to the aspect-fn ctx before forwardExpand; must keep resolvedAspects unforced at stamp (A17). Native default = identity.";
        };
      };

      # den.channelGather — the PER-NODE CHANNEL-AUGMENTATION seam (#62a). A consumer may augment the channel
      # values bound to a node's class-module formals with contributions GATHERED from beyond the node's own
      # emissions: the hook `{ id; result } -> { <channel> = [ contribution ]; }` runs inside `channelBindingsAt`
      # (output-modules.nix), its result appended AFTER the node's local emissions per channel (bound =
      # local ++ gathered). The gathered records share local-collection-data's contribution shape
      # (`.deferred`/`.value`/`.producer`) so they extract through the SAME deferred-thunk path (a gathered
      # deferred value resolves at ITS OWN producing scope). THE LAZINESS LAW (A17): `result` is the eval passed
      # opaquely; a supplier that walks descendants must stay lazy over the id spine (read children ids +
      # exposing nodes' collection data, never force ALL descendants' resolved-aspects). Native den-hoag supplies
      # the empty default (`_: { }`), so the augmentation is the identity path (`local ++ [ ]`) — byte-identical.
      # An external consumer sets it = its gather supplier (e.g. the v1 expose-ascent twin, #62b). `raw` (an
      # opaque function), forced only at a terminal.
      channelGatherDecl = {
        options.den.channelGather = merge.mkOption {
          type = merge.types.raw;
          default = _: { };
          description = "Per-node channel-augmentation hook `{ id; result } -> { <channel> = [ contribution ]; }` run in `channelBindingsAt`; the gathered contributions are appended after the node's own emissions (local ++ gathered); must stay lazy over the id spine (A17). Native default `_: { }` (identity path).";
        };
      };

      # den.probeSentinelFields — the CONFIGURABLE probe sentinel (B2). concern-policies reads a policy's
      # stratum by producing it against a value-less sentinel entry (`{ id_hash; name }`). A consumer whose
      # policy bodies read a coord FIELD on that entry (a corpus fact the consumer knows) supplies the
      # extra fields here as TYPE-CORRECT NON-MATCHING sentinels, so the body takes its value-conditional
      # FALSE branch (→ expansion) instead of hard-failing. Native default `{ }` = the universal sentinel,
      # byte-identical. Core stays field-agnostic; the field NAMES live consumer-side (composition-first).
      probeSentinelDecl = {
        options.den.probeSentinelFields = merge.mkOption {
          type = merge.types.raw;
          default = { };
          description = "extra fields merged onto concern-policies' value-less probe sentinel (beyond `{ id_hash; name }`) so a policy body reading a coord field gets a type-correct non-matching sentinel, not a hard-fail (B2). Native default `{ }`.";
        };
      };

      # den.resolveFamilyNames — the resolve-family TAG SET (R2 REQUIREMENT 2, the corpus-facts-as-config
      # precedent alongside `probeSentinelFields`). concern-policies stamps `__resolveFamily = true` on each
      # named compiled policy, so the STAGED ROOT-RESOLUTION pre-pass dispatches it — the DECLARED tag a
      # value-conditional resolve policy needs (its value-less probe emits no member/relate, so it cannot be
      # DETECTED). A v1 corpus authors `resolve.to` policies without the den-hoag tag on the value, so the
      # shim supplies the corpus resolve-emitting names (its `resolveFamilyModule`). A NAMED
      # policy that emits member/relate at a root but is OMITTED here is caught LOUD by the untagged guard
      # (attributes/structural.nix `resolveFamilyUntagged`). Native default `[ ]` — a native fleet's
      # resolve-family policies are DETECTED (probe emits), never tagged.
      resolveFamilyNamesDecl = {
        options.den.resolveFamilyNames = merge.mkOption {
          type = merge.types.raw;
          default = [ ];
          description = "policy names concern-policies stamps `__resolveFamily = true` on, so the staged pre-pass dispatches them (R2). The declared tag a value-conditional resolve policy needs. Native default `[ ]`.";
        };
      };
      # den.excludeFamilyNames (#72, candidate A) — the resolveFamilyNames twin for `suppress` emitters:
      # policy names whose rules join the staged pre-pass's EXCLUDE-FAMILY feed (a value-conditional
      # excluder probes empty, so the declared tag is its only path). Native default `[ ]`.
      excludeFamilyNamesDecl = {
        options.den.excludeFamilyNames = merge.mkOption {
          type = merge.types.raw;
          default = [ ];
          description = "policy names concern-policies stamps `__excludeFamily = true` on, so the staged pre-pass dispatches them for suppression collection (#72). Native default `[ ]`.";
        };
      };

      # The collector NAMES probe (§4.7) — the gate for the framework `collector` kind: a fleet declaring no
      # `den.collectors` gets no collector kind (`metaAugment { hasCollectors = false } == { }`, corpus-inert).
      discoveredCollectors = collectorsLib.discoverCollectors userModules;
      hasCollectors = discoveredCollectors != [ ];
      # denMeta = the DISCOVERED user kinds `//` the framework collector-kind augment (§4.7). The `//`-augment
      # (NOT fed through discoverKinds, whose reserved-name guard would throw on the framework kind) rides
      # `contentClass = null`; the per-instance function-form class is injected at `metaWithClass` below.
      denMeta = entity.discoverKinds userModules // collectorsLib.metaAugment { inherit hasCollectors; };
      ent = entity.build {
        userModules = [
          membershipDecl
          policiesDecl
          aspectsDecl
          classesDecl
          includeDecl
          quirksDecl
          contentClassDecl
          linearizationDecl
          settingsDecl
          strataDecl
          edgesDecl
          relationsDecl
          derivedDecl
          disciplinesDecl
          productsDecl
          resolutionProductsDecl
          conversionsDecl
          rendersDecl
          kindsDecl
          outputsDecl
          systemsDecl
          axesDecl
          overridesDecl
          demandKindsDecl
          demandContextDecl
          nixpkgsDecl
          darwinDecl
          interpretDecl
          enrichBindingsDecl
          enrichContextDecl
          channelGatherDecl
          probeSentinelDecl
          resolveFamilyNamesDecl
          excludeFamilyNamesDecl
          # The `den.collectors` DECLARATION option (§4.7, always present, the classesDecl posture — inert
          # default `{ }`). The collector schema kind + the `den.collector` registry bridge ride separately,
          # GATED on collectors present, so a corpus fleet gets neither the kind nor the registry.
          collectorsLib.optionModule
        ]
        ++ collectorsLib.collectorModules { inherit hasCollectors; }
        ++ userModules;
        inherit denMeta;
      };

      # ── CELL-KIND CLASSIFICATION (membership-derived, design note 2026-07-11 §3b, user-delivery R3-core) ──
      # THE GAP this rung closes: core formerly picked ONE `leafKind = head cellKinds`, where `cellKinds`
      # was every childless-with-a-parent kind — so a topology with TWO such kinds (the corpus's
      # cluster←environment AND user←host) selected `cluster` alphabetically, `user` never became a product
      # dimension, and user cells never materialized. The product already supports several dim families
      # (fleet.nix `byDims` groups tuples by coord signature); only the ROOT/CELL classification held the
      # single-leaf constraint. THE LAW: a kind is a CELL kind iff a membership tuple (static ∪ pre-pass-
      # derived) targets it as a COORDINATE — read from the tuple DIM SIGNATURES (coord attr NAMES) alone,
      # never the coord VALUES (so no new fixpoint). Every other kind is a ROOT.
      allKinds = builtins.attrNames ent.meta;
      parentKinds = prelude.unique (
        builtins.filter (p: p != null) (map (k: ent.meta.${k}.parent) allKinds)
      );
      # CANDIDATE cell kinds — the topology LEAVES (childless: nothing nests under them) that HAVE a parent
      # (a cell materializes UNDER its parent). STRUCTURAL — reads only `ent.meta` (the discovered
      # containment topology), NEVER membership — which is precisely what breaks the cycle below. A
      # childless PARENTLESS kind (a standalone link/root kind — the r2 acceptance fixture's `cluster`,
      # `parent = null`) is NOT a candidate: it can never be a cell.
      candidateKinds = builtins.filter (
        k: !(builtins.elem k parentKinds) && ent.meta.${k}.parent != null
      ) allKinds;
      # NON-candidate kinds are ROOTS regardless of the membership-derived verdict (the parent-chain kinds
      # + standalone roots). They carry every resolve-family policy the corpus includes (its five are all
      # flake/fleet/environment/host includes — `den.resolveFamilyNames`), and their root set is membership-
      # INDEPENDENT.
      nonCandidateKinds = builtins.filter (k: !(builtins.elem k candidateKinds)) allKinds;

      # THE STAGING THAT BREAKS THE CYCLE (design note §3b). Naive "cellKinds ← tuples ← pre-pass ← roots ←
      # cellKinds" is circular. Instead the pre-pass reads a root set fixed BEFORE classification
      # (`prePassScopeRoots`, over the STRUCTURAL non-candidates), derives the membership tuples, and the
      # classification reads those tuples' DIM SIGNATURES afterward. IDENTITY: for every fleet whose
      # candidates are ALL targeted (each native/synthetic fixture) `nonCandidateKinds == rootScopeKinds`,
      # so this pre-pass input is BYTE-IDENTICAL to the pre-R3 one (`baseScopeRoots` over `rootScopeKinds`);
      # only a multi-candidate topology with an UNtargeted candidate (the corpus's `cluster`) differs, and
      # only in the MAIN-run classification (the pre-pass never sees the difference).
      prePassRootKinds = nonCandidateKinds;
      prePassScopeRoots = buildRoots {
        inherit (ent) registries;
        roots = prePassRootKinds;
      };
      # Fleet membership = STATIC `den.membership` ∪ the staged pre-pass's DERIVED CELL tuples (Task 4, A5's
      # promised law): a policy-emitted bare `member` at a membership-independent root routes into the
      # fleet. `prePass` also carries `relationBindings` (nodeId -> ctx additions from a `containTo`-marked
      # member), injected into the target roots' decls (`scopeRoots`, below) so the main run's inherited-
      # context threads them, AND `containmentRelations` (nodeId -> [ ancestor slice ]), threaded to
      # resolved-settings for the settings-chain env slice (§3c-UNIFIED, byte-neutral when unset).
      # THE IDENTITY PATH: a fleet with ZERO resolution emissions gives `tuples = [ ]` + `relationBindings =
      # { }`, so `membershipTuples`/`scopeRoots` are byte-identical to the pre-R1 values. The pre-pass reads
      # `prePassScopeRoots` (structural, un-injected) + `policiesRules` + `ent.meta` topology — none depend
      # on `membershipTuples`/`theFleet`/the classification, so no cycle.
      prePass = stagedResolution.runPrePass {
        scopeRoots = prePassScopeRoots;
        rootKinds = prePassRootKinds;
        parentOf = k: ent.meta.${k}.parent;
        inherit (ent) registries;
        # The resolve-family feed (concern-policies) — the structural-group rules that CAN emit
        # member/relate (single-group probe DETECTED, or the `__resolveFamily` tag DECLARED). Dispatching
        # only these keeps the pre-pass from running an arbitrary co-firing policy body at a root (which
        # could hit an uncatchable missing-attribute read). Empty for a resolve-free fleet → pre-pass inert.
        resolveRules = policiesRules.resolveFamily;
        # The EXCLUDE-FAMILY feed (#72, candidate A): dispatched at the same roots/ctx for `suppress`
        # collection — v1's policy.exclude constraint registration (pin fx/handlers/dispatch-policies
        # .nix:15-33), rendered as pre-pass suppression sets. Empty for an exclude-free fleet → inert.
        excludeRules = policiesRules.excludeFamily;
      };
      membershipTuples = ent.config.den.membership ++ prePass.tuples;

      # The DIM SIGNATURES of the membership tuples — the kinds any tuple names as a coordinate. Both the
      # cell-kind verdict (which candidates are targeted) and the product dims read this ONE set (byDims,
      # fleet.nix:66, groups the SAME signatures into per-family relations). Coord NAMES only — no values.
      tupleDimKinds = prelude.unique (
        prelude.concatMap (t: builtins.attrNames t.coords) membershipTuples
      );

      # THE CLASSIFICATION: a CANDIDATE targeted by some tuple is a CELL kind; an untargeted candidate is
      # an ordinary ROOT. The corpus's `cluster` (childless under environment, but NO tuple names it — its
      # k8s content is read off the cluster ROOT entity) stays a root; `user` (named by the `{ host; user }`
      # tuples) becomes the leaf, exactly where membership says so — with zero kind-name literals.
      # EDGE (corpus-zero, documented loud): a resolve-family policy included ON a candidate kind would
      # dispatch NOWHERE — the pre-pass runs over non-candidates. The main-run guard (attributes/
      # structural.nix) still catches a resolve-family emission at a TARGETED candidate's cell
      # (`memberAtCell`) and an UNtagged/undetected one at any root (`resolveFamilyUntagged`); the ONLY
      # unguarded sliver is a FEED policy (in `den.resolveFamilyNames`) firing at an UNtargeted-candidate
      # root — it would double-fire benignly yet route nothing. Unreachable for the corpus: its five feed
      # policies are all flake/fleet/environment/host includes, never a cluster/user include.
      cellKinds = builtins.filter (k: builtins.elem k tupleDimKinds) candidateKinds;
      rootScopeKinds = builtins.filter (k: !(builtins.elem k cellKinds)) allKinds;

      # Cell FAMILIES — one `{ leafDim; parentDim }` per cell kind (per-family cells; byDims-grouped in the
      # product). No `head cellKinds` single-leaf pick: `fleetChildren` spawns EVERY family's cells under
      # its parent kind. The corpus yields ONE family (user×host); the zone/rack/blade fixture another. A
      # topology with several DISJOINT-chain cell families simultaneously is the deferred native #49 arc —
      # the single gen-product would natural-join disjoint signatures (fleet.nix `byDims` → conjunctive
      # relations), a cross-product out of R3-core scope (no corpus/fixture exercises it).
      cellFamilies = map (leaf: {
        leafDim = leaf;
        parentDim = ent.meta.${leaf}.parent;
      }) cellKinds;

      # Product dims = the CELL COORDINATE kinds — the membership tuples' DIM SIGNATURES (the byDims
      # families' axes), NOT the leaf's full containment CHAIN. A chain ancestor bound by a RELATION rather
      # than a membership tuple (the corpus's environment→host edge, carried as ctx via `resolve.to host`)
      # is a scope ROOT, never a product axis — forcing it in as a dim with an empty registry would ZERO
      # the product (the corpus's environment/cluster registries are empty in the ship-gate eval). Every
      # cell kind is targeted by definition, so each leaf IS in a signature; each family's tuples also carry
      # the parent coordinate, so `cellChildrenFor`'s parent-slice has its dim. A cell-free fleet (no
      # membership) keeps ALL registered kinds as dims (the degenerate product), unchanged. den.linearization
      # takes over the dim ORDER (§2.7); the canonical order here is name-sorted.
      dimKinds =
        let
          basis = if tupleDimKinds == [ ] then builtins.attrNames ent.registries else tupleDimKinds;
        in
        prelude.sort (a: b: a < b) (
          builtins.filter (k: builtins.elem k basis) (builtins.attrNames ent.registries)
        );

      theFleet = fleet.mkFleet {
        inherit (ent) registries;
        inherit dimKinds membershipTuples;
      };

      # The BASE root scope nodes (un-injected) — the MAIN run's roots, over the membership-derived
      # `rootScopeKinds` (non-candidates ∪ UNtargeted candidates, e.g. the corpus's cluster). Distinct from
      # `prePassScopeRoots` (non-candidates only): an untargeted candidate is a root the main run reads but
      # the pre-pass did NOT (no resolve-family policy fires there — see the classification edge note).
      baseScopeRoots = buildRoots {
        inherit (ent) registries;
        roots = rootScopeKinds;
      };
      # The main-run root scope nodes: base roots with each `relate`-carried binding folded onto its
      # TARGET root's decls (the enriched-context/decls seam — the corpus's `resolve.to host { accessGroups }`
      # binds into the host SCOPE's ctx; inherited-context threads it to the host's cells, attr 1). A fleet
      # with no relations gives `relationBindings = { }`, so `scopeRoots` is byte-identical to base.
      # …AND (#72) each pre-pass SUPPRESSION set folded onto its emitting root's decls as the reserved
      # `__denSuppressedPolicies` ctx key: inherited-context threads it to the root's DESCENDANTS (attr 1
      # strips only __edges/__containment/__coords), matching v1's scope+ancestors constraint consult
      # (dispatch-policies.nix:15-33) — sibling-isolated (#613) because only the emitting root's decls
      # carry it. The compiled-rule GATES read it (the shim-side fn wrap, `gateSuppression`);
      # it is never a module binding read (gen-bind binds destructured args only) and never traced.
      scopeRoots = builtins.mapAttrs (
        id: node:
        node
        // {
          decls =
            node.decls
            // (prePass.relationBindings.${id} or { })
            // prelude.optionalAttrs (prePass.suppressions ? ${id}) {
              __denSuppressedPolicies = prePass.suppressions.${id};
            };
        }
      ) baseScopeRoots;

      # The `children` NTA's fleet arm: a node spawns the cells of every family whose parent kind it is;
      # every other node spawns none. Folded over ALL cell families (no single-leaf assumption).
      fleetChildren =
        self: id:
        let
          node = self.node id;
        in
        prelude.foldl' (
          acc: fam:
          if node.type == fam.parentDim then
            acc
            // fleet.cellChildrenFor {
              fleet = theFleet;
              parentDim = fam.parentDim;
              hostEntry = node.decls.__entry;
              hostNodeId = id;
              leafDim = fam.leafDim;
            }
          else
            acc
        ) { } cellFamilies;

      # Resolve a `link` target entry to the scope node whose enriched-context feeds §B3
      # linked-context. Root-kind targets map to their flat root id `"${kind}:${name}"`; the
      # index is over the entity registries (not scope nodes), so this stays demand-safe. Cell
      # targets resolve through the edge stratum in Task 4 (null here).
      entryNodeIndex = prelude.foldl' (
        acc: kindName:
        prelude.foldl' (
          acc': name:
          let
            e = ent.registries.${kindName}.${name};
          in
          acc'
          // {
            ${e.id_hash} = {
              kind = kindName;
              nodeId = "${kindName}:${name}";
            };
          }
        ) acc (builtins.attrNames ent.registries.${kindName})
      ) { } rootScopeKinds;
      linkTarget = entry: entryNodeIndex.${entry.id_hash} or null;

      # The compiled stratum order (spec §5): the seeded four with the framework's OWN edge-registry
      # inserts (the `output` stratum after `demand`, for nest/defer), each declared `den.relations`
      # relation's OWN stratum (`rel:<name>` after `structural` — §5 L2 EDB, bottom-pinned), plus each
      # `den.strata.insert.<name>`, each placed densely after its anchor. Zero user/relation inserts ⇒ seeded
      # four + `output`. A user insert naming a framework-reserved stratum aborts NAMED — the same posture as a
      # seed-stratum shadow (compileStrata) or a reserved edge-kind (edges.nix): a framework stratum is not
      # overridable. TWO reservations: the exact `output` name, AND the whole per-relation `rel:<name>` namespace
      # (§5 L2 — a relation's stratum is MINTED by `den.relations`, never user-declared; reserving the prefix
      # mirrors how relation LABELS are guarded against user edges, closing the silent //-overwrite class where a
      # user `rel:<existing>` insert would last-wins over the desugared one). Threaded into policy compilation as
      # the capability-scoped ctx projection's stratum order (ctx-key map seeded empty, so a no-op natively).
      userStrataInserts = ent.config.den.strata.insert or { };
      # the per-relation strata (§5 L2), //-merged BESIDE the user + framework inserts into the ONE compile so
      # the compiled order carries every relation's `rel:<name>` (which `edgeKindTable` validates each
      # relation-kind's `stratum` against below). Empty relations ⇒ `{ }` ⇒ byte-identical to the shipped order.
      relationStrataInserts = relationsLib.relationStrataInserts {
        relations = ent.config.den.relations or { };
      };
      reservedInsertOffenders = builtins.filter (
        n: (edgesLib.frameworkStrataInserts ? ${n}) || prelude.hasPrefix "rel:" n
      ) (builtins.attrNames userStrataInserts);
      compiledStrata =
        if reservedInsertOffenders != [ ] then
          let
            off = builtins.head reservedInsertOffenders;
            reason =
              if prelude.hasPrefix "rel:" off then
                "names the framework-generated per-relation stratum namespace 'rel:*' — a relation's stratum is minted by den.relations (§5), not user-declared"
              else
                "is framework-reserved";
          in
          throw "den.strata: insert '${off}' ${reason}"
        else
          declare.compileStrata {
            inserts = userStrataInserts // relationStrataInserts // edgesLib.frameworkStrataInserts;
          };

      # The compiled merge-discipline table (§5): the fleet's `den.disciplines` registrations, validated
      # (laws ladder, reserved-name). The framework seeds the three shipped merge orders (settings-layers /
      # collections-neron / reach-closure); a user registration joins beside them. The closure edge-gate reads it.
      disciplinesTable = concernDisciplines.compile {
        disciplines = ent.config.den.disciplines or { };
      };

      # The compiled edge-kind table (§2.2): the framework-pre-registered vocabulary UNION the fleet's
      # `den.edges` registrations, validated (reserved-name, closure-gate, stratum ∈ the compiled order).
      # The closure gate validates a closure kind's discipline against `disciplinesTable` (present +
      # join-semilattice laws). Threaded to the kernel via `den.edges`, mirroring `classesByName`.
      # den.relations desugared to edge-kinds (§5/§2.2 one-registry): one kind per relation @resolution,
      # //-merged BESIDE the user den.edges kinds into the ONE compile. The collision guard (relation names +
      # inverse labels, pairwise-distinct + disjoint from user kinds + reserved) fires here when forced.
      relationEdgeKinds = relationsLib.relationsToEdgeKinds {
        relations = ent.config.den.relations or { };
        userEdgeKinds = builtins.attrNames (ent.config.den.edges or { });
        reservedNames = edgesLib.reservedNames;
      };
      edgeKindTable = edgesLib.compile {
        kinds = (ent.config.den.edges or { }) // relationEdgeKinds;
        strataOrder = compiledStrata;
        disciplines = disciplinesTable;
      };

      # THE UNDECLARED-RELATION GUARD (§5, the validate-then-transform contract): every relation named in any
      # entity's `.edges` must be a declared `den.relations` relation. A fleet-level read-only pass over the
      # registries' `.edges` attr-NAMES × `den.relations` — no ref→node-id lowering (that is the producer's).
      # Corpus-inert: no `.edges` anywhere ⇒ `edgeRels = [ ]` ⇒ the detector is null ⇒ no throw.
      declaredRelationNames = builtins.attrNames (ent.config.den.relations or { });
      entityEdgeRels = prelude.concatMap (
        kindName:
        prelude.concatMap (
          name:
          map (rel: {
            entityId = "${kindName}:${name}";
            inherit rel;
          }) (builtins.attrNames ((ent.registries.${kindName}.${name}).edges or { }))
        ) (builtins.attrNames ent.registries.${kindName})
      ) (builtins.attrNames ent.registries);
      edgesRelationGuard =
        let
          m = relationsLib.edgesRelationMessage {
            edgeRels = entityEdgeRels;
            relationNames = declaredRelationNames;
          };
        in
        if m != null then throw m else null;

      # The compiled typed-product table (§4.1): the framework-pre-registered faces UNION the fleet's
      # `den.products` registrations, validated (mode-set, reserved-name). Materialization reads modes off
      # it; a receiver's `consumes` passes through `checkConsumes` against it (the next step).
      productsTable = productsLib.compile {
        products = ent.config.den.products or { };
      };

      # The compiled resolution-product table (§5): the fleet's `den.resolutionProducts` registrations,
      # validated (reserved-name). A `den.derived`'s `provides` validates against THIS table (guard (e)),
      # a distinct namespace from productsTable — so a materialization face as a `provides` fails naturally.
      resolutionProductsTable = resolutionProductsLib.compile {
        resolutionProducts = ent.config.den.resolutionProducts or { };
      };

      # THE DERIVED FIELD GUARD (§5): definition-time validation of each `den.derived`'s fields against the
      # fleet's relations (`relationEdgeKinds`), the compiled strata order, and the RESOLUTION-product table
      # (§5, `provides` validates against den.resolutionProducts, not the materialization faces) — a value
      # detector thrown when non-null. Read-only + corpus-inert (empty `den.derived` ⇒ the detector is null ⇒
      # no throw). Forced by reading the `den.derived` return surface.
      derivedGuardMessage = derivedLib.derivedFieldMessage {
        deriveds = ent.config.den.derived or { };
        relationKinds = relationEdgeKinds;
        strataOrder = compiledStrata;
        resolutionProductNames = builtins.attrNames resolutionProductsTable;
      };
      derivedGuard = if derivedGuardMessage != null then throw derivedGuardMessage else null;
      # guard (f): the closure/discipline laws-gate — a VALUE-DETECTOR (like guards (a)-(e)) validated by the
      # SHARED edges closureMessage against the compiled disciplines registry (a closure=true derive needs a
      # registered join-semilattice discipline, §2.2), thrown at the wiring.
      derivedClosureGuardMessage = derivedLib.derivedClosureMessage {
        closureMessage = edgesLib.closureMessage;
        disciplines = disciplinesTable;
        deriveds = ent.config.den.derived or { };
      };
      derivedClosureGuard =
        if derivedClosureGuardMessage != null then throw derivedClosureGuardMessage else null;
      # the guarded derived registry (forcing it forces the field guards first — (a)-(e) then (f)) — the name→spec
      # index the compute engine reads (`spec = derivedTable.${name}`) and the `den.derived` return surface share.
      derivedTable = builtins.seq derivedGuard (
        builtins.seq derivedClosureGuard (ent.config.den.derived or { })
      );

      # The compiled single-step conversion table (§4.1): the fleet's `den.conversions` pairs, validated
      # (key well-formedness, no ArtifactRef endpoint). Global per-pair uniqueness holds by keying.
      conversionsTable = productsLib.compileConversions {
        conversions = ent.config.den.conversions or { };
      };

      # Compile the relationships concern (den.policies) into the enrich / policy rule feeds.
      # The fixture carries no policies, so both feeds are empty and the fleet builds as before.
      # `probeSentinelFields` (native default `{ }`) configures the value-less stratum probe's sentinel;
      # `resolveFamilyNames` (native default `[ ]`, R2) stamps the resolve-family tag on the named policies.
      policiesRules =
        concernPolicies.compileWithStrata
          {
            order = compiledStrata;
            ctxKeyStrata = { };
          }
          ent.config.den.probeSentinelFields
          ent.config.den.resolveFamilyNames
          ent.config.den.excludeFamilyNames
          ent.config.den.policies;

      # The quirks concern: ONE fleet-level gen-pipe.compose over every declared channel (+ its ops),
      # plus the den-managed demand channel (§B) AND the collection-stratum pipe operators threaded
      # through the `policyOps` seam so they join the SAME compose — channel-name uniqueness (E4b) and
      # reference closure (E4a) are therefore fleet-wide over quirks, demands AND pipes.
      #
      # PIPE OPS (den.policies `pipe.from name [stages]`, compiled to `pipeOp` declarations): a pipe's
      # `derived` channel DAG (filter/transform/fold/for folded left-to-right) is FLEET-WIDE — the
      # transform is ONE DAG over the named channel, not a per-scope fact — so it rides `policyOps`
      # exactly like the demand channel, seeded (from the static probe in concern-policies) BEFORE the
      # eval. The compose's cycle-safe worklist dedups the pipe's base-channel stub against the real
      # `den.quirks` registration by id (channelDecls seeded first, first wins), so `pipe.from feat …`
      # resolves onto the registered `feat` channel with no E4b clash and the derived channel
      # (`feat.<op>.<idx>`) joins the DAG — CONSUMED, where before it compiled but never reached the fold.
      #
      # NOT yet threaded (a bounded C3/C8 follow-up, not a regression — these compile, they just do not
      # join the compose): the `to`/`as` delivery `routes` carry channel refs as NAMES (v1 aspect targets
      # / pipe names), but gen-pipe's compose consumes route `from`/`to` as channel RECORDS, so routing
      # them needs the C3 route to carry `channelRef` records (and `to`'s aspect-carrier semantics
      # resolved — an aspect is not a gen-pipe channel). Site `marks` (append/expose/collect/broadcast)
      # are per-scope EMISSION wiring, not compose ops. The `for` whole-list run IS threaded now
      # (board #45): `honorWholeList` (below) reroutes each `__derive.wholeList` node to gen-pipe's
      # whole-list `over` op, so a v1 `for` applies its fn to the WHOLE channel list, not per-element.
      quirks = ent.config.den.quirks;
      channelNames = concernQuirks.channelNames quirks;
      # Every derived channel in the DAG must be a DIRECT declaration (gen-pipe E4a checks a declared
      # op's inputs against the declaration set, not the transitively-reached worklist), so the compiled
      # pipe's `derived` (the FINAL node) is walked base-ward to declare the whole chain. `compilePipe`
      # folds the deriving stages linearly, so each node has one input; the walk stops at the base ref
      # (`__derived = false`) — the registered quirk, declared via channelDecls, so it is NOT re-added.
      pipeChainOf =
        d: if (d.__derived or false) then [ d ] ++ pipeChainOf (builtins.head d.__derive.inputs) else [ ];
      # Honor the `__derive.wholeList` routing marker: a `map` node carrying `__derive.wholeList = true`
      # (a v1 `for` — whole-list, vs `transform`'s per-element `map`) reroutes to gen-pipe's whole-list
      # `over` op. deriveSeq dispatches on `__derive.op` and compose names by `.op`, so both become "over"
      # (the provisional id and the inert marker key stay: compose resolves inputs by the unchanged id and
      # reassigns final names from `.op`). No value is forced — the derived channel's merge keeps `f` a
      # thunk, so the deferred-value discipline is untouched.
      honorWholeList =
        d:
        if (d.__derived or false) && (d.__derive.wholeList or false) then
          d
          // {
            op = "over";
            __derive = d.__derive // {
              op = "over";
            };
          }
        else
          d;
      pipeChannelOps = builtins.map honorWholeList (
        prelude.concatMap (p: pipeChainOf p.derived) (policiesRules.pipeOps or [ ])
      );
      quirkDag = concernQuirks.compose {
        inherit quirks;
        policyOps = [ demandLib.demandChannel ] ++ pipeChannelOps;
      };

      # classOfNode — the producing-scope → class-entry function (§2.5). Resolve each kind's declared
      # `contentClass` (a class-name string or an entry) to a class entry; a kind with no mapping is
      # class-neutral. Reuses entity.classOf (which also handles the per-host function form) by
      # enriching ent.meta with the resolved contentClass entry.
      resolveClass =
        cc:
        if cc == null then
          null
        else if builtins.isString cc then
          effectiveClassEntries.${cc}
            or (throw "den-hoag: den.contentClass names unknown class `${cc}` (known: ${builtins.concatStringsSep ", " effectiveClassNames})")
        else
          cc;
      # The framework `collector` kind's producing class is a PER-INSTANCE function of the collector's own
      # `class` field (§4.7/§2.5 function-form): `contentClassFn e = effectiveClassEntries.${e.class}` (guarded
      # NAMED on an unregistered class). Every OTHER kind reads its string/entry from `den.contentClass`. The
      # special-case fires only when the collector kind is present, so a corpus fleet is byte-identical.
      collectorContentClass = collectorsLib.contentClassFn {
        inherit effectiveClassEntries effectiveClassNames;
      };
      metaWithClass = builtins.mapAttrs (
        k: m:
        m
        // {
          contentClass =
            if k == collectorsLib.kindName then
              collectorContentClass
            else
              resolveClass (ent.config.den.contentClass.${k} or null);
        }
      ) ent.meta;
      classOfNode = entity.classOf {
        meta = metaWithClass;
        entityOfNode = node: node.decls.__entry or null;
      };

      # The compiled collectors surface (§4.7): the fleet's `den.collectors` registrations with each `class`
      # validated against the registered classes (an unregistered/absent class aborts NAMED when read). Absent
      # ⇒ `{ }` (no collectors), byte-neutral. The collector ENTITIES themselves ride `registries.collector`;
      # this is the concern's validated declaration table (the products/renders compile-and-expose posture).
      collectorsTable = collectorsLib.compile {
        collectors = ent.config.den.collectors or { };
        inherit effectiveClassNames;
      };

      # The classes concern (§2.4): compile every registered class (the class-name buckets, extended by
      # any `den.classes.<name>` declaration) into class config records — the `wrap.mergeStrategy` →
      # gen-bind `defaultMergeStrategy` adapter, the validator toggle, the terminal `instantiate`, the
      # `share.core` opt-in, and the A10 `coreStrategy` seam. Default terminal = the nixpkgs-free
      # `collect` (den-hoag stays pure; a real build supplies `crossNixos` per class).
      #
      # The ONE real nixpkgs crossing (§2.10, Law A15): when `den.nixpkgs` is supplied, the `nixos` class
      # crosses through `crossNixos` (gen-flake `terminals.mkSystemTerminal` + `nixpkgs.lib.nixosSystem`) by default — so `nixosConfigurations`
      # are REAL NixOS systems — unless the class declares its own `instantiate`. The terminal builder is
      # re-imported here with the supplied nixpkgs; lib/** stays nixpkgs-free (nixpkgs is inert config data
      # threaded to the terminal, never imported). Every other class keeps the nixpkgs-free `collect` default.
      npkgs = ent.config.den.nixpkgs or null;
      ndarwin = ent.config.den.darwin or null;
      crossTerminalLib = import ./output/terminal.nix { inherit bind flake; } {
        nixpkgs = npkgs;
        darwin = ndarwin;
      };
      # DECLARED INSTANTIATION (D7): a system class declares HOW it crosses — `den.classes.<name>.
      # instantiation = { evaluator ? null; output ? null; }`. `evaluator` is the `{ modules, specialArgs }
      # -> system` builder (gen-flake's `mkSystemTerminal` contract, #48); `output` names the flake-parts
      # option target the built systems mount at (D8; the built-in family seeding below reads it to key each
      # family, the flake-parts bridge mounts each). The instantiation is NOT a core constant — a new system class (droid, or anything a user
      # invents) is a pure declaration needing zero edits here or in gen-flake.
      #
      # The compiled render table (§4.3, the D7 promotion) — the SINGLE source of the built-in nixos/darwin
      # instantiation rows: seeded PER-FLEET from `npkgs`/`ndarwin` (the null-input ⇒ null-evaluator ⇒
      # nixpkgs-free `collect` derivation lives in renders.nix `builtinRows`), plus the fleet's `den.renders`
      # registrations, validated (produces/requires against the products table). The evaluators close over
      # the fleet's own inputs, so the compile is invoked HERE — inside the closure, after the input reads.
      rendersRows = rendersLib.compile {
        registered = ent.config.den.renders or { };
        inherit npkgs ndarwin;
        products = productsTable;
      };
      # THE ROOT KIND (§4.6, root-as-entity): the fleet's `den.outputs.<family>` faces resolve through the SAME
      # slot ≻ class dispatch a nested receives row does — so each family projects to a receives row on a
      # framework `root` outer kind (`outputsLib.toReceives`), merged into the receivers compile's rows. A user
      # declaring `den.kinds.root` directly collides with this framework output locus — abort NAMED (the
      # sibling reserved posture; root is not a user-writable receives entry). The `rootReserved` guard aborts
      # BEFORE this merge, so a user `root` — which WOULD win the right-biased `//` — can never reach it; the
      # guard is the sole protection (operand order is not).
      userKinds = ent.config.den.kinds or { };
      rootReserved = userKinds ? root;
      # THE BUILT-IN FAMILY SEEDING (§4.4, the D7 promotion of the declared-target output face): the
      # framework's own output families (nixosConfigurations/darwinConfigurations + any user system class's
      # declared target) derived per-fleet from each class's INSTANTIATION `output` field (via
      # `instantiationOf`, so the `classes.<name>.instantiation` overlay is preserved). `families`
      # seed both the families table (`outputsTable`) and the root receives projection; `classOf` maps each
      # family to its winning class for the live mount (`familyOutputs`, below the output stratum).
      builtinFams = outputsLib.builtinFamilies {
        classNames = effectiveClassNames;
        inherit instantiationOf;
        hasRender = class: rendersRows ? ${class};
      };
      # the family rows the framework + user contribute: the built-in seeds UNION `den.outputs` (a user
      # re-declaration of a built-in family key wins — the extension posture, the `//` right-bias).
      allFamilies = builtinFams.families // (ent.config.den.outputs or { });
      rootKindEntry = outputsLib.toReceives allFamilies;
      # The compiled receives table (§4.2): the fleet's `den.kinds.<outerKind>.receives.<slot>` graft-site
      # rows UNION the projected `root` families entry, validated (mode derived via the products table; outer-
      # kind + includes checked against the registered kinds — augmented with `root`, the output-side receiver
      # locus that is NOT a discovered entity kind; `render` checked against the render rows). PER-FLEET (the
      # render-name check reads `rendersRows`, which compiles here), following the render read-through's placement.
      receivesTable =
        if rootReserved then
          throw "den.kinds: 'root' is the framework output locus (den.outputs families project onto it) — a kind may not be declared as den.kinds.root"
        else
          receiversLib.compile {
            rows = rootKindEntry // userKinds;
            knownKinds = builtins.attrNames ent.kinds ++ [ "root" ];
            products = productsTable;
            renders = rendersRows;
          };
      # The axis registry (§4.4): the built-in `system` axis (domain = `den.systems`) ∪ the user `den.axes`.
      # `system` is reserved — a user `den.axes.system` aborts NAMED here. `.names` is the family-`params`
      # validation set; `.domains` the per-axis value lists the fan draws from.
      axesReg = outputsLib.axesRegistry {
        axes = ent.config.den.axes or { };
        systems = ent.config.den.systems or [ ];
      };
      # The compiled output-families table (§4.4): the fleet's `den.outputs.<family>` rows, validated (mode
      # derived via the products table; `render` checked against the render rows; `params` against the axis
      # registry `axesReg.names`; `requires` against the products table). PER-FLEET (the render-name check reads
      # `rendersRows`), following receivesTable's placement. The `seq` forces the axis registry (its reserved-
      # `system` guard) whenever the families table is read, so a user `den.axes.system` aborts even if no family
      # names a `params` axis.
      outputsTable = builtins.seq axesReg.names (
        outputsLib.compile {
          registered = allFamilies;
          renders = rendersRows;
          products = productsTable;
          axisNames = axesReg.names;
        }
      );
      # REQUIRES CONSUMPTION (§4.4): each family's `requires` (∪ its render's `requires`) must be SATISFIABLE
      # at the graft site — the products a member can supply there. The graft-site available set is the
      # family's own `consumes` (what its members produce) UNION the family's render `produces` (the artifact
      # face the render emits), EXTENDED by the single-step conversion targets (§4.1: a product reachable from
      # an available one through ONE registered conversion). A required product outside that set aborts NAMED
      # (`checkRequires`). The built-ins carry `requires = [ ]` (vacuous), so this is byte-neutral for them.
      # deepSeq'd into the `outputsTable` surface below so the check fires when the families table is forced.
      requiresChecked = builtins.mapAttrs (
        family: row:
        let
          renderRequires =
            if row.render != null && rendersRows ? ${row.render} then
              rendersRows.${row.render}.requires or [ ]
            else
              [ ];
          renderProduces =
            if row.render != null && rendersRows ? ${row.render} then
              prelude.optional (
                rendersRows.${row.render}.produces or null != null
              ) rendersRows.${row.render}.produces
            else
              [ ];
          available = [ row.consumes ] ++ renderProduces;
        in
        outputsLib.checkRequires {
          inherit family available;
          requires = (row.requires or [ ]) ++ renderRequires;
          # CONVERSION-AWARE satisfiability (§4.1, single-step): a required product reachable from an available
          # one through ONE registered conversion is satisfiable — the compiled table carries `.from`/`.to`.
          conversions = conversionsTable;
        }
      ) outputsTable;

      # THE ENTITY-LEVEL OPT-INS (§4.4/§7): each entity's `den.<kind>.<name>.outputs.<family>` opt-in
      # elaborated to an inert record `{ family; entity; data }`, the render-declared required fields (the
      # family's `params`) definition-time-checked (`checkOptIn` — missing → named throw, never silent). NO
      # EDGE EMISSION: the family nest edge for an opted-in entity arrives with the live-producer sub-plan;
      # this surfaces the elaboration records only. An entity opting into an UNKNOWN family aborts NAMED (a
      # family must be registered in `outputsTable` for its params to be known). Absent for every entity ⇒
      # `[ ]` (byte-neutral — a fleet that opts nobody in surfaces no records).
      # the enriched elaboration records — checkOptIn's `{ family; entity; data }` PLUS `entityKind` (the opt-in
      # mount reads it to slice the member's content at the entity's root scope `"${kind}:${name}"`). The
      # PUBLIC `optIns` (below) strips `entityKind` back to the §4.4 `{ family; entity; data }` record.
      optInsEnriched = prelude.concatMap (
        kindName:
        prelude.concatMap (
          name:
          let
            entry = ent.registries.${kindName}.${name};
            entOptIns = entry.outputs or { };
          in
          map (
            family:
            if !(outputsTable ? ${family}) then
              throw "den.outputs: entity '${name}' opts into unregistered family '${family}' — register it in den.outputs"
            else
              outputsLib.checkOptIn {
                inherit family;
                params = outputsTable.${family}.params or [ ];
                entity = name;
                optIn = entOptIns.${family};
              }
              // {
                entityKind = kindName;
              }
          ) (builtins.attrNames entOptIns)
        ) (builtins.attrNames ent.registries.${kindName})
      ) (builtins.attrNames ent.registries);
      optIns = map (o: {
        inherit (o) family entity data;
      }) optInsEnriched;
      # THE READ-THROUGH (spec §4.3): the render row supplies the BASE `{ evaluator; output }`; the
      # `den.classes.<name>.instantiation` D4 overlay STAYS ON TOP. Precedence law:
      # `classes.instantiation` ≻ render row ≻ nothing. The built-in nixos/darwin rows are always present in
      # `rendersRows`, so a fleet declaring nothing reads them unchanged — the promotion is transparent (the
      # else arm is `{ }`: a class name with no render row and no classes.instantiation is un-crossed, the
      # nixpkgs-free `collect` default). See REFERENCE.md.
      instantiationOf =
        name:
        (if rendersRows ? ${name} then { inherit (rendersRows.${name}) evaluator output; } else { })
        // (ent.config.den.classes.${name}.instantiation or { });
      classDecls = prelude.genAttrs effectiveClassNames (
        name:
        let
          decl = ent.config.den.classes.${name} or { };
          evaluator = (instantiationOf name).evaluator or null;
        in
        if decl ? instantiate then
          decl
        else if evaluator != null then
          decl // { instantiate = crossTerminalLib.crossVia evaluator; }
        else
          decl
      );
      classesByName = concernClasses.compile {
        classes = classDecls;
        defaultInstantiate = terminalLib.collect;
      };

      equations = attributesLib.equations {
        inherit policiesRules fleetChildren linkTarget;
        allAspects = ent.config.den.aspects;
        directIncludes = ent.config.den.include;
        # The post-inheritance resolution-ctx enrichment hook (native default = identity, byte-identical).
        # A17-lazy: applied to the enriched-context before `forwardExpand`, so a stamped closure never forces
        # the node's resolved-aspects until it is called at a value position after convergence.
        enrichContext = ent.config.den.enrichContext or ({ bindings, ... }: bindings);
        inherit quirkDag classOfNode channelNames;
        # The consumer's nixpkgs lib for pipeline-parametric `lib`-arg injection (collections.nix): the
        # supplied `den.nixpkgs` flake's `.lib`, or null on the pure path (nixpkgs-free `collect`). Same
        # inert-config seam the terminal crossing reads (`npkgs.lib.nixosSystem`, §2.10) — lib/** stays
        # import-pure. A `lib`-demanding parametric emit rides unresolved when null (the named ceiling).
        consumerLib = if npkgs == null then null else npkgs.lib or null;
        localDemandData = demandLib.localDemandData;
        fleet = theFleet;
        # The staged pre-pass's containment relations (nodeId -> [ ancestor slice ]) — the settings-chain
        # env slice (§3c-UNIFIED). Empty for a fleet with no `containTo`-marked members → byte-identical.
        inherit (prePass) containmentRelations;
        inherit
          lin
          settingsLayers
          dimKinds
          projectors
          ;
        classNames = effectiveClassNames;
        inherit (denAspects) classifyKey;
        inherit
          relationEdges
          relationEdgeKinds
          derivedTable
          ;
        strataOrder = compiledStrata;
      };

      structural = runResolve {
        roots = scopeRoots;
        inherit
          equations
          parseParent
          declaredEdges
          ;
        strataOrder = compiledStrata;
      };

      # The output stratum (attribute 12, Law A15): the gen-edge fold's graph accessor + `outputFor`/
      # `traceFor`, and the per-class terminal crossing (`systems.<class>.<member>`). Reads the FINAL
      # eval; applied once here (like the narrow accessor). `demandEdges` (the fleet's gen-demand
      # resolution as inert gen-edge records, computed below) is folded into each root's edge set — A11
      # closes the A9 staging where the demand edges did not yet join the fleet output. Lazy: a
      # demand-free fleet's `demandEdges` is `[ ]`, so the fold is byte-identical to the pre-A11 output.
      output = attributesLib.mkOutputModules {
        result = structural.eval;
        inherit
          classesByName
          classOfNode
          demandEdges
          channelNames
          ;
        # The §7 projection filter: keep only `to ∈ { materialize, both }` edge kinds on the materialization
        # trace. Relation kinds (`den.relations` desugar) carry `to = "query"` and are filtered off — inert on
        # the corpus (relation edges never join `edgesForRoot`), formalizing the off-trace parity seam.
        materializeFilter = edgesLib.materializeEdges edgeKindTable;
        interpret = ent.config.den.interpret or { };
        # The post-resolution binding-enrichment hook (native default = identity, byte-identical). A11-lazy:
        # applied inside `bindingsAt`, so forcing the systems spine never forces it, and a hook that stamps a
        # projected `hasAspect` never forces resolved-aspects until the closure is called (A17).
        enrichBindings = ent.config.den.enrichBindings or ({ bindings, ... }: bindings);
        # The per-node channel-augmentation supplier (#62a; native default = the empty gather, so
        # `channelBindingsAt` is byte-identical to its own-emissions form). An external consumer wires
        # its gather supplier (the v1 expose-ascent twin, #62b).
        channelGather = ent.config.den.channelGather or (_: { });
        # THE ONE per-aspect class-slice extraction + §2.2 totality assertion (Task 2/3), built with the
        # discovered `classifyKey` so `projectClass` (the reach-based projection) and the `class-modules`
        # buckets share exactly one extraction — the ANCHOR `projectClass == classSubtreeAt` on a no-edge
        # node is that equivalence — and `projectClass` enforces the unregistered-key totality abort.
        inherit
          (attributesLib.mkClassSlice {
            classNames = effectiveClassNames;
            inherit (denAspects) classifyKey artifactExclusive;
          })
          classSliceOf
          assertKeysRegistered
          ;
      };

      # The narrow accessor (A10, §2.8) at any scope node: `aspects.<name> = { present; settings; }`,
      # over the FINAL eval (`structural.eval`). Consumed as the `aspects` module arg at output
      # assembly (Task 9); exposed here so the settings/cross-aspect surface is readable standalone.
      aspectsAt = attributesLib.mkNarrowAccessor ent.config.den.aspects structural.eval;

      # The fleet channel outputs — one gen-pipe.run over the neron traversal, for the class-relative
      # read (concernQuirks.consumeAt) at output assembly (Task 6). `.at pos` selects any position; it
      # is the same run attribute 11 (received-collections) computes per node inside the schedule.
      # DRIFT NOTE: this traversal adapter MUST stay identical to attribute 11's (lib/attributes/
      # collections.nix received-collections) — both are assembled from the same three
      # `scopeAdapter.traversalAdapter` components (neron order / local-collection-data / classOfNode),
      # differing only in whose eval they read (final `structural.eval` here vs the in-flight `self`
      # there). Divergence would silently make consumeAt and the attribute disagree.
      receivedOutputs = pipe.run {
        dag = quirkDag;
        traversal = scopeAdapter.traversalAdapter {
          result = structural.eval;
          localDataOf = pos: chName: (structural.eval.get pos "local-collection-data").${chName} or [ ];
          classesOfNode =
            node:
            let
              c = classOfNode node;
            in
            if c == null then [ ] else [ c ];
        };
      };

      # The demand concern (§B): register the kinds (downward-only DAG, checked here), gather the
      # fleet's demand declarations in the demand channel's pinned order, run ONE resolveAll, and
      # construct the resources/wiring → gen-edge records. All lazy — a demand-free fleet never forces
      # a resolveAll (the fixtures reading only `structural`/`quirkDag` pay nothing for this concern).
      demandKindSet = demandLib.registerKinds (ent.config.den.demandKinds or { });
      orderedDemands = demandLib.collectDemands structural.eval;
      demandResolution = demandLib.resolveDemands {
        kinds = demandKindSet;
        inherit orderedDemands;
        ctx = ent.config.den.demandContext or { };
      };
      demandEdges = demandLib.toEdges demandResolution;

      # Slice-order linearization (§2.7). `den.linearization.dims` declares the dimension order as
      # KIND entries; empty ⇒ canonical (name-sorted kind entries), preserving the pre-concern order.
      # linearizationLib validates totality/identity and renders entries → product dim names (Law A1:
      # the count-major slice key lives in gen-product).
      declaredDims = ent.config.den.linearization.dims or [ ];
      linDims = if declaredDims == [ ] then map (k: ent.kinds.${k}) dimKinds else declaredDims;
      lin = linearizationLib.linearization {
        dims = linDims;
        productDims = dimKinds;
      };

      # Scoped settings overrides (§2.6) compiled to internal den-layer records (validated: `of` an
      # aspect entry, `at` dims ∈ the settings-dim set). resolved-settings folds them per (cell, aspect)
      # by §2.7. The settings-dim set is the product dims UNION the root scope kinds (§3c-UNIFIED): a
      # containment-relation ancestor (env → the settings-chain env slice) is a ROOT, not a product dim,
      # so an env-/cluster-level layer (`at = { env = <e>; }`) must validate against the root kinds too —
      # else the owner's default→env→host→user cascade could not attach a layer to its env slice. Widening
      # (never narrowing) the allowed set: a real typo dim (not a kind at all) still aborts named.
      settingsDims = prelude.unique (dimKinds ++ rootScopeKinds);
      settingsLayers = settingsLib.compileLayers {
        layers = ent.config.den.settings.layers or [ ];
        productDims = settingsDims;
      };

      # Projecting aspects (§2.9 / A14, the `projects` facet): each aspect declaring a non-empty
      # `projects`, paired with its ATTACHMENT scopes — the containment position `{ <kind> = entity }`
      # of every entity it is directly included at (`den.include`). v1 uses the static include surface
      # as the introduction source; policy / neededBy / edge introduction is deferred: deriving it would
      # require per-node scope derivation inside the resolve loop (projectors are pre-computed as a
      # static list before it) — an implementation-complexity deferral, not a formal A9 violation. The projection
      # LAYERS are expanded in resolved-settings (`projectionLayersAt`); this only resolves attachment.
      entityKindOf =
        let
          index = prelude.foldl' (
            acc: kindName:
            prelude.foldl' (
              acc': name: acc' // { ${ent.registries.${kindName}.${name}.id_hash} = kindName; }
            ) acc (builtins.attrNames ent.registries.${kindName})
          ) { } (builtins.attrNames ent.registries);
        in
        entry: index.${entry.id_hash};
      allAspects = ent.config.den.aspects;
      projectors =
        let
          scopesOf =
            aspect:
            prelude.concatMap (
              inc:
              if builtins.any (x: (x.id_hash or null) == aspect.id_hash) inc.aspects then
                [ { ${entityKindOf inc.at} = inc.at; } ]
              else
                [ ]
            ) (ent.config.den.include or [ ]);
        in
        map (name: {
          aspect = allAspects.${name};
          scopes = scopesOf allAspects.${name};
        }) (builtins.filter (n: (allAspects.${n}.projects or [ ]) != [ ]) (builtins.attrNames allAspects));

      # The graph escape hatch (§2.11): the gen-scope result, the restricted fleet product, the per-root
      # gen-edge edge set + frozen trace (the parity oracle input, Law A15 — `output.edgesForRoot` folds
      # in the demand edges, so the trace is the exact topology the output materializes), and the
      # gen-demand resolution.
      graph = graphEscape {
        scope = structural.eval;
        fleet = theFleet;
        inherit (output) edgesForRoot;
        demands = demandResolution;
      };

      # ── §4.7: SELECTOR-DRIVEN MEMBERSHIP → the member-edge producer. Each collector's `members` selector
      # is run over ALL scope nodes with a CLASS-INJECTED ctx (`matchIdWith` adds `classOf`, the seam a
      # `hasClass` selector reads — the base scope ctx carries no producing class), yielding `member` edges
      # collector→member. EXPOSED read-only (`den.memberEdges`); the aggregate FOLDS over these edges (never
      # re-selects). NOT spliced into `output.edgesForRoot`/the live trace, so byte-identity holds by
      # construction. Corpus-inert: no collector ⇒ `[ ]` (the concatMap short-circuits before forcing the
      # gather). `classNameOf` = producingClassOf semantics (the class NAME string, or null on a class-neutral
      # node — the null-guard `hasClass` short-circuits on).
      classNameOf =
        id:
        let
          c = classOfNode (structural.eval.node id);
        in
        if c == null then null else c.name;
      # The sel → (node-id → bool) predicate over the fleet's structural scope: `matchIdStructural sel` is the raw
      # gen-select match, the `classOf` extension feeding `hasClass` the producing class the base ctx lacks.
      # Shared by the collector membership filter AND relQuery's `where` — collector members and relation endpoints
      # are BOTH scope node-ids.
      matchIdStructural = scopeAdapter.matchIdWith structural { classOf = classNameOf; };
      memberIdsFor =
        sel: builtins.filter (matchIdStructural sel) (builtins.attrNames structural.eval.allNodes);
      collectorMemberEdges = collectorsLib.memberProducer {
        collectors = ent.registries.collector or { };
        inherit memberIdsFor classNameOf;
      };
      # ── THE FLAT RELATION PRODUCER (§5, the memberProducer POSTURE): over all entities' `.edges.<rel> =
      # [targets]`, emit FLAT records `{ id; kind; from; to }` with PLAIN-STRING `from`/`to` node-ids (den.query
      # string-compares the flat list — NOT the `{entityId;class}` records the collector producer emits). `from`
      # is the DECLARING entity's node-id = the iteration key (no lowering); each TARGET ref is lowered to
      # `"${kind}:${name}"` via `entityKindOf` (the id_hash→kind index over all registries — records carry
      # id_hash + name, not kind). Read-only + OFF `edgesForRoot` (never in the live trace) — corpus-inert by
      # construction (no `.edges` ⇒ `[ ]`).
      forwardRelationEdges = prelude.concatMap (
        kindName:
        prelude.concatMap (
          name:
          let
            from = "${kindName}:${name}";
            entityEdges = (ent.registries.${kindName}.${name}).edges or { };
          in
          prelude.concatMap (
            rel:
            map (
              target:
              let
                to = "${entityKindOf target}:${target.name}";
              in
              {
                id = "rel:${rel}/${from}->${to}";
                kind = rel;
                inherit from to;
              }
            ) entityEdges.${rel}
          ) (builtins.attrNames entityEdges)
        ) (builtins.attrNames ent.registries.${kindName})
      ) (builtins.attrNames ent.registries);
      # ── THE INVERSE EDGES via gen-graph.transpose (§9): the reverse-query edges are the FORWARD edges of a
      # relation kind REVERSED — a per-kind `genGraphLib.transpose` (Mokhov 2017 §4.3), NOT a hand-rolled from/to
      # swap. For each relation kind `k` carrying an `inverse` label `k⁻¹`: k's forward edges become a per-kind
      # accessor `{ edges = from → [to]; nodes = k's endpoints }` (the synthesized `nodes` is the union of k's
      # endpoints — transpose materializes over it); `transpose` reverses the adjacency (to → [from]); each
      # reversed pair `(node, src)` is re-labelled kind `k⁻¹`. den.query is forward-only, so these
      # `<inverse>`-labelled edges are what the per-entity accessor's forward `follow = <inverse>` query reads —
      # byte-identical to the retired inline swap `{ id = "rel:${k⁻¹}/${to}->${from}"; kind = k⁻¹; … }`. A null
      # inverse ⇒ no reverse edges (the relation is forward-only); a relation with no forward edges ⇒ `[ ]`.
      inverseRelationEdges = prelude.concatMap (
        rel:
        let
          inverseLabel = relationEdgeKinds.${rel}.inverse or null;
        in
        if inverseLabel == null then
          [ ]
        else
          let
            kindForward = builtins.filter (e: e.kind == rel) forwardRelationEdges;
            adjacency = builtins.foldl' (
              acc: e: acc // { ${e.from} = (acc.${e.from} or [ ]) ++ [ e.to ]; }
            ) { } kindForward;
            nodes = prelude.unique (
              prelude.concatMap (e: [
                e.from
                e.to
              ]) kindForward
            );
            # NB: transpose set-dedups the reversed adjacency (materialize's `prelude.unique`); the forward edges
            # are NOT deduped. Divergent ONLY for a malformed duplicate-target `.edges` declaration (old: 2
            # inverse records; new: 1) — the identical `id` means any id-keyed consumer already collapses them,
            # and it is corpus/trace-inert (relation edges are morally a set). The deliberate asymmetry.
            reversed = genGraphLib.transpose {
              edges = id: adjacency.${id} or [ ];
              inherit nodes;
            };
          in
          prelude.concatMap (
            node:
            map (src: {
              id = "rel:${inverseLabel}/${node}->${src}";
              kind = inverseLabel;
              from = node;
              to = src;
            }) (reversed.edges node)
          ) nodes
      ) (builtins.attrNames relationEdgeKinds);
      relationEdgesRaw = forwardRelationEdges ++ inverseRelationEdges;
      # WEAVE THE GUARD onto the producer's critical path (the validate-then-transform contract made real):
      # forcing `relationEdges` forces the undeclared-relation guard first, so a malformed `.edges` aborts NAMED
      # for ANY consumer of the producer output — not only when the `den.relations` surface is read.
      relationEdges = builtins.seq edgesRelationGuard relationEdgesRaw;
      # GAP-2 (§11): the SOUND conservative consumer→producer declaration for warm-serve. A node's resolution
      # (`rel-accessor`/`derived-accessor`) reads the relation graph reachable from it — `targets`/`inverse`/
      # `closure` and every `node.query` follow the `relationEdges` pool — so declaring EVERY node's read-set as
      # the full relation-endpoint set is the SAFE over-declaration (a superset of the actual reads: never
      # stale; a tighter per-node reachable set is the tracked perf refinement, §13). Corpus-inert: no
      # `relationEdges` ⇒ `[ ]` for every node ⇒ byte-identical to the empty default; and `declaredEdges` feeds
      # ONLY the warm-serve/rebuild layer (DP3/DP4, unforced in the cold materialization path).
      relationEndpoints = prelude.unique (
        prelude.concatMap (e: [
          e.from
          e.to
        ]) relationEdges
      );
      declaredEdges = _id: relationEndpoints;
      # relQuery (§5) — the sel→matchId `where`-adaptation over den.query, built PER-MKDEN from the fleet's scope.
      # `whereFor` is the SAME `matchIdStructural` the collector membership filter runs (memberIdsFor) — reused,
      # not re-spelled. ★ §11 Phase 1: UNLIKE relAt/derivedAt (now scheduled `rel-accessor`/`derived-accessor`
      # resolution attrs), relQuery STAYS a fleet-global helper — it is parameterized by `from` (not a per-node
      # attribute), and its only eval-dependence (`whereFor = matchIdStructural`, a SHARED scope-selector adapter
      # reading the ONE final eval) is a legitimate consumer, not a second evaluator. Folding it into the schedule
      # would make a FUNCTION-valued attribute (violating "an attribute value is inert data") for no warm-serve
      # gain; it is therefore NOT part of the second delivery-context Phase 1 deletes.
      relQuery = relationsLib.mkRelQuery {
        denQuery = queryLib.denQuery;
        inherit relationEdges;
        whereFor = matchIdStructural;
      };
      # ── §4.7: the member-product EXTRACTION — read a member's `consumes` product ALREADY-RESOLVED (never
      # re-derived), DISPATCHED on the product's mode (the mode-generic backbone a later L2 lift extracts): a
      # content product (RawModulesInfo) = the member's raw class slice (`classSubtreeAt`); an artifact product
      # (SystemInfo) = the member's built system (`output.systems`). An unknown mode aborts NAMED (never a bare
      # crash). This is the abstraction the genericity floor rests on — a collector differs from another ONLY in
      # its `consumes` (+ render), the extraction dispatches on the consumed product's mode alone.
      extractMemberProduct =
        product: memberNodeId: memberClass:
        let
          mode = productsLib.modeOf productsTable product;
        in
        if mode == "content" then
          # the raw class slice. Uncatchable-clean by construction on a content-empty member: `classSubtreeAt`
          # is `concatMap (nid: (classModulesAt nid).${class} or [ ]) …`, so an absent class bucket yields `[ ]`
          # (an empty aggregate), never an attr-miss — no guard needed. The artifact arm below is the ASYMMETRIC
          # case (output.systems FILTERS content-empty nodes → the key is absent → a bare miss), so only it guards.
          output.classSubtreeAt memberNodeId memberClass
        else if mode == "artifact" then
          # the already-built system for this member. NAMED-guard the read (never a bare `.${id}` miss — the
          # tryEval-uncatchable class): a member selected by the collector's `members` but ABSENT from
          # `output.systems.<class>` (a class-bearing node with empty content never surfaces a system) aborts
          # NAMED, quoting the member + class.
          (output.systems.${memberClass} or { }).${memberNodeId}
            or (throw "den.collectors: member '${memberNodeId}' (class '${memberClass}') has no built system in output.systems — an artifact-consuming collector aggregates already-built systems, so a selected member must produce one (§4.7)")
        else
          throw "den.collectors: member product '${product}' has mode '${mode}' — a collector aggregates content (raw modules) or artifact (built systems) products, not ${mode}-mode";

      # ── THE LIVE FAMILY MOUNT (§4.4/§4.6): the output map assembled VIA the root family dispatch ──
      # `familyOutputs` is the root entity's PRODUCT — the plain attrset `{ <family> = { <entityName> =
      # <artifact>; }; }` — assembled by nesting each built member into the root through the SAME machinery a
      # nested receives edge uses: the family row resolved via the REAL `resolveReceiver` (over the receives
      # table carrying `root`), the built artifact injected VALUE-mode through `executeNest` (the prebuilt
      # ArtifactRef arm — the artifact is injected verbatim, never re-evaluated). NO hand-rolled dispatch: the
      # row comes from `resolveReceiver`, the placement from the contribution's `at`. THE OUTPUT FACE: the
      # top-level `outputs` and the nixosConfigurations/darwinConfigurations aliases project off this. The
      # member re-key (scope-node id → entity name) and the last-wins family collapse (listToAttrs semantics)
      # are the face laws — an empty face for a memberless family, one entry per member keyed by entity name.
      #
      # the fold's `place` primitive — a local `setAttrByPath` twin (den-hoag has no public gen-edge
      # `core.setAttrByPath` re-export; the same local-twin note the nest engine + output-modules carry).
      familyNestAtPath =
        path: value:
        if path == [ ] then
          value
        else
          { ${builtins.head path} = familyNestAtPath (builtins.tail path) value; };
      # recursively merge two plain attrset trees (the per-member contributions fold into one family subtree,
      # families into the root product). A leaf (a built artifact — never an attrset with a colliding key path)
      # rides as-is; two subtrees at the same family key merge. Member names are `attrNames output.systems.
      # <class>` — unique per class — so no two contributions target the same `[ family, member ]` leaf.
      familyMerge =
        a: b:
        a
        // builtins.mapAttrs (
          k: bv:
          if (a ? ${k}) && builtins.isAttrs a.${k} && builtins.isAttrs bv then familyMerge a.${k} bv else bv
        ) b;
      familyOutputs =
        let
          families = builtins.attrNames builtinFams.classOf;
          # EVERY family key surfaces even with NO members: the declared-target face law emits `<family> = { }`
          # for a memberless class (a class like darwin with no members yields `darwinConfigurations = { }`).
          # Seed the fold with one empty subtree per family so a memberless family keeps its key (the empty-face
          # law) — otherwise a member-only fold would drop the key entirely.
          emptyFamilies = builtins.listToAttrs (
            map (family: {
              name = family;
              value = { };
            }) families
          );
          # one value-mode contribution per (family, member): the built artifact nested into the root through
          # the resolved family row. The contribution's `at` is `[ <family> <entityName> ]` (the family row's
          # placement); `value` is the built artifact (carried verbatim — the value arm never forces it).
          contributions = prelude.concatMap (
            family:
            let
              class = builtinFams.classOf.${family};
              row = receiversLib.resolveReceiver {
                compiledKinds = receivesTable;
                outerKind = "root";
                slot = family;
                class = class;
              };
            in
            map (
              memberId:
              let
                entry = (structural.eval.node memberId).decls.__entry or null;
                entityName = if entry != null then entry.name else memberId;
              in
              nestLib.executeNest {
                inherit row;
                inner = {
                  product = "ArtifactRef SystemInfo";
                  artifactRef = {
                    product = "SystemInfo";
                    value = output.systems.${class}.${memberId};
                  };
                  name = entityName;
                  kind = class;
                };
                ctx.paramPoint = {
                  name = entityName;
                };
              }
            ) (builtins.attrNames (output.systems.${class} or { }))
          ) families;
          # ── the opt-in family mount (§4.4/§7): each opted-in entity BUILT through its family's render
          # (ARTIFACT-mode executeNest — the render evaluator is the sole forcing boundary), keyed by entity
          # NAME (the member re-key law). Unlike the built-in mount (a PREBUILT system injected value-mode),
          # an opt-in entity is not in `output.systems` — its member content is sliced from the entity's ROOT
          # scope (`classSubtreeAt "${kind}:${name}" contentClass`) and the render evaluator builds it. SINGLE-
          # INSTANCE root scope only: an entity with one root scope has exactly one content slice; a
          # multi-instance/cell entity's content resolves through the reach-route (§7), out of this mount's
          # scope. GUARDED below by `optIns != [ ]` — a fleet opting nobody in is structurally the built-in fold
          # (byte-identical).
          optInContributions = prelude.concatMap (
            o:
            let
              famRow = outputsTable.${o.family};
              row = receiversLib.resolveReceiver {
                compiledKinds = receivesTable;
                outerKind = "root";
                slot = o.family;
                class = o.family;
              };
              # the member's content slice at its root scope — the mount's content source (the render's input
              # for an artifact family, the `imports` face for a content family). A family with an opt-in but
              # NO contentClass has no channel to slice, so a build here aborts NAMED.
              payload =
                if famRow.contentClass == null then
                  throw "den.outputs: opt-in family '${o.family}' has no contentClass — an opted-in member needs a content channel to slice its modules (entity '${o.entity}')"
                else
                  output.classSubtreeAt "${o.entityKind}:${o.entity}" famRow.contentClass;
              inner = {
                product = row.consumes;
                inherit payload;
                name = o.entity;
                kind = o.entityKind;
              };
            in
            map
              (
                paramPoint:
                nestLib.executeNest {
                  inherit row inner;
                  ctx.paramPoint = {
                    name = o.entity;
                  }
                  // paramPoint;
                  renders = rendersRows;
                }
              )
              (
                outputsLib.fanParams {
                  inherit (o) family;
                  inherit (famRow) params;
                  axesDomains = axesReg.domains;
                }
              )
          ) optInsEnriched;
          # ── the collector AGGREGATE mount (§4.7): each collector with a render GATHERS its member edges
          # into a NAME-KEYED member map (a FOLD over `collectorMemberEdges` — never a mount re-select), calls
          # the aggregate render's `evaluator` ONCE (memberMap → HiveInfo — the aggregate crossing behind the
          # swappable evaluator seam), and VALUE-mode nests the PREBUILT HiveInfo into root via the render's
          # `output` family. The member payload is the collector's `consumes` product read already-resolved
          # (`extractMemberProduct`, mode-dispatched). Three product roles stay distinct: `collector.consumes`
          # (aggregated-IN) ≠ `render.produces` = `family.consumes` (mounted-OUT) — the render/family match is
          # asserted NAMED. The render is asserted an AGGREGATE render (arity misuse → NAMED). GUARDED below
          # (with optIns): a fleet with no collector contributions is the byte-identical built-in fold.
          collectorContributions = prelude.concatMap (
            cName:
            let
              c = ent.registries.collector.${cName};
            in
            if (c.render or null) == null then
              [ ]
            else
              let
                renderRow =
                  rendersRows.${c.render}
                    or (throw "den.collectors: collector '${cName}' names unregistered render '${c.render}'");
                # The render must be an AGGREGATE render (memberMap → HiveInfo), not a per-config one.
                aggChecked =
                  if renderRow.aggregate then
                    true
                  else
                    throw "den.collectors: collector '${cName}' render '${c.render}' is not an aggregate render (its evaluator is per-config { modules; specialArgs } → system) — set `aggregate = true` on the render to cross a member map → HiveInfo (§4.7)";
                # The compiled render row always carries `output` (default null), so a `.output or (throw)`
                # would be DEAD (fires only on a missing attr) and a null `output` would flow to a bare
                # `outputsTable.${null}` / `resolveReceiver slot=null` — the tryEval-uncatchable `.${null}` class.
                # Null-guard explicitly (the aggChecked/producesChecked idiom) so an omitted `output` aborts NAMED.
                family =
                  if renderRow.output == null then
                    throw "den.collectors: collector '${cName}' render '${c.render}' declares no `output` — an aggregate render must name its output family (§4.7)"
                  else
                    renderRow.output;
                famRow =
                  outputsTable.${family}
                    or (throw "den.collectors: collector '${cName}' render '${c.render}' names output family '${family}', which is not a registered den.outputs family");
                # render.produces must equal family.consumes (the mounted-OUT product) — a silent shape
                # mismatch is the tryEval-uncatchable class, so it aborts NAMED.
                producesChecked =
                  if renderRow.produces == famRow.consumes then
                    true
                  else
                    throw "den.collectors: collector '${cName}' render '${c.render}' produces '${renderRow.produces}' but its output family '${family}' consumes '${famRow.consumes}' (§4.7)";
                # THE GATHER: this collector's member edges → { <memberName> = <member product payload> }. The
                # member name is the member node's entity name (edge.to → node → __entry.name); the payload is
                # the collector's `consumes` product read already-resolved (mode-dispatched).
                cMemberEdges = builtins.filter (e: e.from.entityId == "collector:${cName}") collectorMemberEdges;
                memberMap = builtins.listToAttrs (
                  map (
                    e:
                    let
                      memberId = e.to.entityId;
                      # guarded read + raw-id fallback, mirroring the built-in mount (an entry-less node keeps
                      # its raw id rather than a bare `.__entry.name` crash — the gather runs over the broader
                      # selector-matched set, so it stays at least as defensive as the mount it mirrors).
                      entry = (structural.eval.node memberId).decls.__entry or null;
                    in
                    {
                      name = if entry != null then entry.name else memberId;
                      value = extractMemberProduct c.consumes memberId e.to.class;
                    }
                  ) cMemberEdges
                );
                # THE RENDER: ONE call over the aggregated map — the aggregate crossing behind the seam. A
                # `needsSelf` render (§4.4, the self-knot) is CURRIED `evaluator { self = familyOutputs; }
                # memberMap` — `self` is the RECURSIVE root product this fold produces, tied natively through the
                # `familyOutputs` `let` (no combinator, nothing deepSeq'd), so a hosted render reads sibling
                # output families through the knot. WELL-FOUNDEDNESS: it terminates ONLY IF the render's output
                # KEY SPINE is self-independent (a NECESSARY condition — only leaf VALUES may read `self`, and each
                # leaf must read ANOTHER family's value, never its own); a spine derived from `self`, OR a leaf
                # reading its own family's value (a self-loop), diverges with a tryEval-UNCATCHABLE infinite
                # recursion (a documented boundary — Case B in flakeparts.nix, never an executed oracle).
                # `needsSelf = false` (every shipped HiveInfo/SystemInfo render) keeps
                # the byte-untouched `evaluator memberMap` call — the lazy `if` never forces the then-branch there.
                hiveInfo = builtins.seq aggChecked (
                  builtins.seq producesChecked (
                    if renderRow.needsSelf then
                      renderRow.evaluator { self = familyOutputs; } memberMap
                    else
                      renderRow.evaluator memberMap
                  )
                );
                row = receiversLib.resolveReceiver {
                  compiledKinds = receivesTable;
                  outerKind = "root";
                  slot = family;
                  class = c.class;
                };
              in
              [
                (nestLib.executeNest {
                  inherit row;
                  # VALUE-mode: the PREBUILT HiveInfo injected verbatim (the render already ran ONCE above), the
                  # built-in system mount's ArtifactRef arm — never re-evaluated at the mount.
                  inner = {
                    product = "ArtifactRef ${renderRow.produces}";
                    artifactRef = {
                      product = renderRow.produces;
                      value = hiveInfo;
                    };
                    name = cName;
                    kind = c.class;
                  };
                  ctx.paramPoint = {
                    name = cName;
                  };
                })
              ]
          ) (builtins.attrNames (ent.registries.collector or { }));
          # the placed value per contribution mode: the value arm carries `value` (the prebuilt system), the
          # artifact arm `artifact` (the render-built face), the extend arm `extended` (the render's `extendsVia`
          # applied to the inner handle), the content arm the RAW (un-placed) module slice wrapped as a SINGLE
          # `{ imports = raw }` module — placed ONCE at `[ family, member ]` by the fold below (the placed
          # `modules` field is skipped here, so the slice is not double-nested). All lazy — the fold forces the
          # attr shape only.
          placedValue =
            c:
            if c.mode == "artifact" then
              c.artifact
            else if c.mode == "extend" then
              c.extended
            else if c.mode == "content" then
              { imports = c.raw; }
            else
              c.value;
        in
        # GUARD: with no opt-ins AND no collector contributions the built-in fold is byte-identical (both extra
        # arms are structurally absent — the corpus path). The guard gates BOTH: a collectors-but-no-opt-ins
        # fleet must take the all-arms branch, else its collector aggregates would be silently dropped.
        if optIns == [ ] && collectorContributions == [ ] then
          prelude.foldl' (acc: c: familyMerge acc (familyNestAtPath c.at c.value)) emptyFamilies contributions
        else
          prelude.foldl' (acc: c: familyMerge acc (familyNestAtPath c.at (placedValue c))) emptyFamilies (
            contributions ++ optInContributions ++ collectorContributions
          );

      # The built-in aliases (§4.4): each is the corresponding family projected off the root product
      # (`familyOutputs`). The output face is now assembled ENTIRELY by the family dispatch — the per-class
      # face-builder + the declared-target map that preceded it are retired, the family assembly owns the
      # face. A new system class (droid → `nixOnDroidConfigurations`) surfaces at its own family key with zero
      # face code; the `or { }` keeps a fleet with no members of that class projecting the empty face.
      nixosConfigurations = familyOutputs.nixosConfigurations or { };
      darwinConfigurations = familyOutputs.darwinConfigurations or { };
    in
    {
      den = {
        schema = ent.kinds;
        inherit (ent) registries meta roots;
        aspects = ent.config.den.aspects;
        fleet = theFleet;
        cells = product.cells theFleet;
        inherit dimKinds;
        linearization = lin;
        # The compiled stratum order (spec §5): the seeded four + `den.strata.insert` dense insertions
        # + the framework's `output` stratum (nest/defer).
        strata = compiledStrata;
        # The compiled edge-kind table (§2.2): framework vocabulary + `den.edges` registrations, validated.
        edges = edgeKindTable;
        # The relation registry (§5): the fleet's declared `den.relations`, guard-forced — reading this surface
        # fires the undeclared-relation guard (`.edges.<rel>` naming an undeclared relation aborts NAMED). The
        # relations desugar to edge kinds (surfaced under `edges`); this exposes the raw declared set + the gate.
        relations = builtins.seq edgesRelationGuard (ent.config.den.relations or { });
        # The derived-attribute registry (§5): the fleet's declared `den.derived`, guard-forced — reading this
        # surface fires the field guards (unknown relation / reverse-over-inverse-less / unknown or too-early
        # stratum / unregistered provides). The stratum/closure gates are later rungs.
        derived = derivedTable;
        # The compiled merge-discipline table (§5): the fleet's `den.disciplines` registrations, validated
        # (laws ladder): the framework merge-order instances seeded, plus any user registration.
        disciplines = disciplinesTable;
        # The compiled typed-product table (§4.1): framework faces + `den.products` registrations, validated
        # (mode-set). Materialization derives each receiver's mode from it (F1's canonical machine form).
        products = productsTable;
        # The compiled single-step conversion table (§4.1): the fleet's `den.conversions` pairs, validated.
        conversions = conversionsTable;
        # The compiled render table (§4.3, the D7 promotion): the built-in nixos/darwin rows (seeded
        # per-fleet from den.nixpkgs/den.darwin) + the fleet's `den.renders` registrations, validated.
        renders = rendersRows;
        # The compiled receives table (§4.2): the fleet's `den.kinds.<outerKind>.receives.<slot>` graft-site
        # rows, validated (mode derived from consumes; outer-kind/includes/render checked). The
        # dispatch-execution work walks these rows' `includes` for receiver inheritance.
        kinds = receivesTable;
        # The compiled output-families table (§4.4): the fleet's `den.outputs.<family>` root-as-entity rows
        # (framework-seeded + `den.outputs`), validated (mode derived from consumes; render/params/requires
        # checked). Forcing this surface deep-forces the REQUIRES CONSUMPTION check (`requiresChecked`), so an
        # unsatisfiable `requires` aborts NAMED when the families table is read. The face-materialization work
        # reads these rows to surface each family at the flake root.
        outputs = builtins.seq (builtins.deepSeq requiresChecked null) outputsTable;
        # THE ENTITY-LEVEL OPT-INS (§4.4/§7): the elaborated `den.<kind>.<name>.outputs.<family>` records
        # `{ family; entity; data }`, each definition-time-checked against the family's render-declared required
        # fields (its params). Inert this task — the family nest edge arrives with the live-producer sub-plan.
        inherit optIns;
        # The compiled collectors surface (§4.7): the fleet's `den.collectors` registrations with each `class`
        # validated against the registered classes (an absent/null or unregistered class aborts NAMED). A
        # collector is a `collector`-kind ENTITY — its id_hash-bearing instance rides `registries.collector`.
        # deepSeq'd EAGER (the `requiresChecked` posture): reading the surface validates EVERY collector's class,
        # not only the entries a consumer happens to force. Corpus-safe (empty table ⇒ deepSeq no-op ⇒ parity
        # byte-identical). The classOf materialization path additionally fires the same guard via `contentClassFn`.
        collectors = builtins.seq (builtins.deepSeq collectorsTable null) collectorsTable;
        # THE MEMBER EDGES (§4.7): the selector-driven `member` edges collector→member, one per matching
        # scope node (`den.collectors.<c>.members` run over all nodes). A read-only surface — the aggregate
        # render folds over these edges (never a mount re-select). NOT in `output.edgesForRoot`/the live trace,
        # so byte-identity holds; corpus-inert `[ ]` (no collectors ⇒ no member edges).
        memberEdges = collectorMemberEdges;
        # THE RELATION EDGES (§5): the FLAT plain-string relation edge set produced from every entity's
        # `.edges` (forward + swapped-inverse), the live SOURCE `den.query` consumes. A read-only surface, the
        # `memberEdges` twin — NOT in `output.edgesForRoot`/the live trace, so byte-identity holds; corpus-inert
        # `[ ]` (no `.edges` ⇒ nothing). Forcing it fires the woven undeclared-relation guard.
        relationEdges = relationEdges;
        # relQuery (§5): the fleet's `sel`→`matchId` `where`-adapted relation query over `den.relationEdges` —
        # `relQuery { from; kind; sel ? null; mode ? "all" }`. Per-mkDen (closes over the fleet's scope +
        # relation edges); corpus-inert — a new read-only surface nothing in the corpus calls.
        relQuery = relQuery;
        # relAt (§5): the per-entity relation accessor, delivered from the SCHEDULED `rel-accessor` resolution
        # attr (§11 Phase 1 — no longer a top-level closure). `relAt id = structural.eval.get id "rel-accessor"`
        # = `{ <kind> = { targets; inverse; closure; paths }; }` (this per-node record is what a node's `ctx.rel`
        # reads). Lazy per field; corpus-inert.
        relAt = id: structural.eval.get id "rel-accessor";
        # derivedAt (§5): the per-node derived-attribute accessor, delivered from the SCHEDULED `derived-accessor`
        # resolution attr (§11 Phase 1 — no longer a top-level closure). `derivedAt name id` =
        # `(structural.eval.get id "derived-accessor").${name}`; the unknown-name check runs FIRST against
        # `derivedTable`, so a typo'd name aborts NAMED before any eval read (the nodeId stays inert). `deps` is a
        # throw-on-read placeholder; the stratum-gate + `node` handle live in the attr's `mkDerived` body.
        derivedAt =
          name: id:
          if derivedTable ? ${name} then
            (structural.eval.get id "derived-accessor").${name}
          else
            throw "den.derived: no such derived '${name}' — not a name declared in den.derived (§5)";
        # THE LIVE FAMILY MOUNT (§4.4/§4.6): the root entity's PRODUCT — `{ <family> = { <entityName> =
        # <artifact>; }; }` — assembled via the root family dispatch (`resolveReceiver`) + the value-mode
        # `executeNest` arm. This IS the output face: the top-level `outputs` and the nixosConfigurations/
        # darwinConfigurations aliases project off it (the per-class face-builder that preceded it is retired).
        inherit familyOutputs;
        # The system-axis values (§4.4): the domain of a family's `system` param (`den.systems`, default `[ ]`).
        inherit (ent.config.den) systems;
        scopeRoots = scopeRoots;
        inherit structural;
        # The quirks concern surface: class entries (the class-tag vocabulary — the built-ins UNION the
        # fleet's DECLARED classes, §2.2), the ONE composed channel DAG, and the fleet channel outputs
        # (`.at pos` → per-position channel values, and the input to the class-relative read
        # `internal.consumeAt`).
        classes = effectiveClassEntries;
        inherit quirkDag receivedOutputs;
        # Settings resolution surface (§2.6/§2.7/§2.8): the compiled scoped-override layers, and the
        # narrow accessor `aspectsAt <nodeId> = { <aspectName> = { present; settings; }; }` (A10).
        inherit settingsLayers aspectsAt;
        # The demand concern surface (§B): the registered kind set (downward-only DAG), the single
        # fleet resolveAll result ({ resources; wiring; trace; }), and its resources/wiring rendered as
        # inert gen-edge records — these join the fleet edge set Task 9 materializes.
        demandKinds = demandKindSet;
        inherit demandResolution demandEdges;
        # The output stratum (attribute 12, Law A15): the gen-edge fold (`graphAccessor`/`outputFor`/
        # `traceFor`), the per-class terminal crossing (`systems`), and the compiled class configs.
        inherit output;
        classConfigs = classesByName;
        # The graph escape hatch (§2.11), read-only.
        inherit graph;
      };
      # The top-level assembly face (§2.10 acceptance): `graph` (the read-only escape hatch, also under
      # `den.graph`) and the flake-output system faces (`nixosConfigurations` / `darwinConfigurations`,
      # host-name-keyed) lifted beside `den` so a consumer reads
      # `mkDen fleetModules → { den; graph; nixosConfigurations; darwinConfigurations; outputs; }`.
      # `outputs` is the GENERIC family map (§4.4): `outputs.<family> = <entity-name-keyed face>` — the root
      # entity's product, assembled by the family dispatch (`familyOutputs`). nixosConfigurations/
      # darwinConfigurations are its built-in family aliases; a user/droid class surfaces at its own family
      # key here. The flake-parts bridge mounts each.
      inherit graph nixosConfigurations darwinConfigurations;
      outputs = familyOutputs;
    };
in
{
  inherit errors mkDen;
  # The greenfield v2 flake-parts mount (§4.4/§4.6, D8): `flakeAdapter <built den fleet>` → a flake-parts
  # module handing the fleet's transposed family map to `config.flake` — `imports = [ (den.flakeAdapter
  # (den.mkDen [ … ])) ]`. A v2 entry distinct from the drop-in v1 `flakeModule` (zero shared splice); see
  # lib/output/flake-adapter.nix.
  inherit flakeAdapter;
  # den.query (§3 query calculus, §5): a pure lowering of the §3 follow-grammar query over a SUPPLIED flat
  # labeled edge list (`[{ kind; from; to }]`) onto gen-graph — `query { edges; from; follow; where ? (_: true);
  # mode ? "all"; order ? {}; empty; combine; valueOf; }`. Source-agnostic (plain-string ids); the live
  # relation-graph source is a downstream concern. See lib/query.nix.
  query = queryLib.denQuery;
  # den's selector vocabulary (identity-law entry/kind constructors + adapters); used to
  # write declarations, independent of any one mkDen instance.
  sel = select;

  # den's `projects`-facet sugar (§2.9 / A14): `hasSetting <field>` = a STATIC selector matching every
  # aspect that declares `<field>` in its settings schema — the address side of a projection rule
  # (`projects = [ { select = hasSetting "theme"; set = { theme = …; }; } ]`). Independent of any one
  # mkDen instance; the aspect-schema selector domain is den-hoag-owned (see lib/projects.nix).
  inherit (projectsLib) hasSetting;
  # den's collector-membership sugar (§4.7): `hasClass <name>` = a scope-node selector matching every node
  # whose PRODUCING class name is `<name>` — the `hasSetting` posture (a top-level, composable selector VALUE),
  # written literally in `den.collectors.<c>.members`. It reads a `classOf` accessor the membership gather
  # injects into the run ctx (den-hoag owns the classOf seam; no gen-select addition — see concern-collectors.nix).
  inherit (collectorsLib) hasClass;
  # den's class-tag vocabulary (the fixed class entries, identity-law A2): the same entries every
  # mkDen tags contributions with, exposed for writing quirk `adapters` (cross-class coercions) that
  # reference a class by its entry rather than a bare name.
  classes = classEntries;
  # den's declaration vocabulary (verb): the tagged constructors + stratum classifier +
  # identity-law checks, independent of any one mkDen instance. Policies read `declare.member`,
  # `declare.edge`, etc.
  inherit declare;

  # den's settings vocabulary, independent of any one mkDen instance: `ref` (cross-aspect reference
  # data, §2.8) and the linearization declaration helper (§2.7). `settings` re-exports gen-settings'
  # `ref`; `linearization` is the totality-checked dim-order wrapper.
  inherit (settingsLib) ref;
  linearization = linearizationLib.linearization;

  # Internal builders + raw gen libs — for constructing minimal scenarios in the suite
  # (structural equations over hand-built roots/rules), not a public API.
  internal = {
    inherit
      buildRoots
      parseParent
      runResolve
      scopeAdapter
      stagedResolution
      ;
    # gen-flake's flake-parts crossing (`terminals.mkFlakeTerminal { inputs; self; modules; systems ? [] }` →
    # the transposed `config.flake`), for the suite's real-flake-parts witnesses to hand an aggregate render's
    # `evaluator` as the swappable seam value. Present only when the constructed `flake` lib carries it (its
    # published rev may predate mkFlakeTerminal — the witnesses that read it are override-gated accordingly).
    mkFlakeTerminal = flake.terminals.mkFlakeTerminal or null;
    structural = structuralAttributes;
    compilePolicies = concernPolicies.compile;
    # The probe-sentinel convenience (`compilePoliciesWith sentinelFields policies`) keeps its 2-arg shape —
    # the resolve-family tag set defaults to `[ ]` here (the R2 knob is a fleet-level `den.resolveFamilyNames`
    # option, not a unit-suite concern). `compileWith` is the full 4-arg form default.nix threads.
    compilePoliciesWith = sentinelFields: concernPolicies.compileWith sentinelFields [ ] [ ];
    # The strata-aware compiler (spec §5): compile with an explicit stratum order + stratum→ctx-key map,
    # so the capability-scoped ctx projection is exercisable from the suite (the seeded config = the
    # byte-identical no-op the fleet path uses). `compilePoliciesWithStrata { order; ctxKeyStrata } sentinel rf ef`.
    compilePoliciesWithStrata = concernPolicies.compileWithStrata;
    # The edge-kind registry compile (§2.2) + the framework pre-registration, for the suite's
    # registration/validation scenarios. `compileEdges { kinds; strataOrder; disciplines ? {} }` (the
    # `disciplines` arm is the compiled disciplines table the closure gate reads); `edgeKinds` = the
    # pre-registered strata + framework strata inserts.
    compileEdges = edgesLib.compile;
    edgeKinds = edgesLib;
    # The relation registry desugar (§5): `relationsToEdgeKinds`/`relationCollisionMessage`, for the suite's
    # desugar + collision-message scenarios (the NAMED contract is a value, since tryEval can't capture a throw).
    relations = relationsLib;
    # The derived-attribute field validator (§5): `derivedFieldMessage`, for the suite's field-guard scenarios
    # (the NAMED contract as a value).
    derived = derivedLib;
    # The stratum-scope arithmetic (§2.3): `edgesBelowStratum`/`ceilingGate`/`indexOf`/`strataLt`, for the
    # suite's capability-scope scenarios (the extraction's own witnesses beside the derived/acl behavior tests).
    strataScope = strataScopeLib;
    # The bounded-NTA registration law (§8 law 5): `boundedNtaMessage`/`boundedNtaGuard` over a production-shaped
    # record, for the suite's synthetic `emit = nodes` scenarios (the NAMED contract as a value — no fleet
    # declares a node-spawning production yet; Phase 5 lands the surface + its consumer).
    productionGuard = productionGuardLib;
    # The merge-discipline registry compile (§5) + the lib (its `reservedNames`/`lawClasses`), for the
    # suite's laws-ladder validation scenarios. `compileDisciplines { disciplines }`.
    compileDisciplines = concernDisciplines.compile;
    disciplines = concernDisciplines;
    # The typed-product registry (§4.1): the lib (its `modes`/`reservedNames` + the `modeOf`/`checkConsumes`
    # definition-time helpers) + the two compile fns, for the suite's product/mode/conversion scenarios.
    # `compileProducts { products }` → the framework-seeded table; `compileConversions { conversions }` →
    # the validated single-step pairs.
    products = productsLib;
    compileProducts = productsLib.compile;
    compileConversions = productsLib.compileConversions;
    # The render registry (§4.3, the D7 promotion): the lib, for the suite's per-fleet compile + validation
    # scenarios. `renders.compile { registered; npkgs; ndarwin; products }` seeds the built-in nixos/darwin
    # rows and validates produces/requires against the compiled products table.
    renders = rendersLib;
    # The receives registry (§4.2): the lib, for the suite's graft-site row compile + validation scenarios.
    # `receivers.compile { rows; knownKinds; products; renders }` validates the outer kind, derives each
    # row's mode via the products table, and checks includes/render names.
    receivers = receiversLib;
    # The output-families registry (§4.4): the lib, for the suite's family-row compile + validation scenarios.
    # `outputsLib.compile { registered; builtins ? {}; renders; products; systems }` derives each family's mode
    # via the products table and checks consumes/render/params/requires.
    inherit outputsLib;
    # The slot ≻ class dispatch (§4.2 F4), exposed flat for the suite's dispatch scenarios: `resolveReceiver
    # { compiledKinds; outerKind; slot; class }` runs the visible query over the kind-include graph.
    # `checkSingularDefinition { row; intents; mount }` is the §4.2 arity DEFINITION-TIME half (two
    # unconditional intents into a singular mount abort NAMED before the identity freeze).
    inherit (receiversLib) resolveReceiver checkSingularDefinition;
    # The nest-mode EXECUTION engine (§4.2 mode taxonomy), exposed flat for the suite's execution scenarios:
    # `executeNest { row; inner; ctx; conversions ? {}; renders ? {} }` dispatches on the resolved row's derived
    # `mode` and returns that mode's contribution — content (grafted at `at`), value (the prebuilt arm),
    # artifact (rendered via `renders.${row.render}`), extend (the render's `extendsVia`) — plus the §4.8
    # provide/adapt riders. `bindArgs argEnv fnModule` is the pure functionArgs binder (adapt); `executeDefer
    # { record }` produces the `{ mode = "defer"; needs; thenFn; fn }` record (§4.8 R6 — `fn` is the config-
    # adapter `lowerDefer` wraps into a __configThunk). `checkSingular { row; edges; mount }` is the §4.2 arity
    # WIRING-TIME half (the live edge set, post-`when`).
    inherit (nestLib)
      executeNest
      bindArgs
      executeDefer
      checkSingular
      ;
    # `lowerDefer <scope> <deferContribution>` (§4.8 R6) — lower an executeDefer contribution onto a gen-bind
    # config-thunk (`mkThunkFrom` over its config-adapter `fn`). The terminal defer→configThunk consumption
    # lives in output-modules.nix `lowerDefer` (per-fleet, beside deferredToThunk); this is its top-level twin
    # for the suite (the setAttrByPath/nestAtPath local-twin posture). `bind` (the raw gen-bind lib — its
    # `wrapAll`/`isThunk` drive the terminal-resolution harness) is exposed below with the other gen libs.
    lowerDefer = scope: c: bind.mkThunkFrom scope c.fn;
    # The pre-identity-freeze override tier (§2.4): `applyOverrides { overrides; edges }` — the
    # match/rewrite pass framework edge intents take BEFORE edgeId, for the suite's override scenarios.
    # `assembleEdges { kinds; overrides; intents }` — the §2.1 synthetic assembly pipeline (override →
    # identity → acyclicity → stamped gen-edge record), for the suite's end-to-end scenario. `nestProducer`
    # (§4.2/§4.6) — the cell/containment nest-edge producer, for the nest-producer suite (emits nest
    # intents + graft contributions from `containmentPairs`, gated corpus-inert by `resolveReceiver`).
    inherit (edgesLib) applyOverrides assembleEdges nestProducer;
    # `containmentPairs { fleet; meta }` (§4.2/§4.6) — the fleet's immediate parent→child cell edges, the
    # thin containment accessor `nestProducer` reads.
    inherit (fleet) containmentPairs;
    # `memberProducer { collectors; memberIdsFor; classNameOf }` (§4.7) — the selector-driven member-edge
    # producer (collector→member), the nestProducer twin the aggregate folds over. Pure over the gather.
    inherit (collectorsLib) memberProducer;
    # classifyKey (the §2.2 three-branch dispatch) + its `facets` vocabulary — the shim's
    # key-classification consistency suite reads `facets` to pin the structural-key agreement.
    # `artifactExclusive` (§4.1) is the pure prebuilt-arm buckets-empty check, for the suite's exclusivity
    # scenarios (also fired at the projection terminal via mkClassSlice's assertKeysRegistered).
    inherit (concernAspects) classifyKey facets artifactExclusive;
    # The quirks concern's composer + class-relative read, for the suite's channel scenarios.
    inherit (concernQuirks) compose consumeAt;
    # Settings/linearization builders + the raw gen-settings/gen-algebra surfaces, for the suite's
    # A7/A16 direct-function and byte-parity scenarios (foldLayers reference; linearization errors).
    inherit settingsLib linearizationLib;
    # The classes concern compiler + the terminal builder (crossNixos / collect), for the suite's
    # class-modules + output + terminal-crossing scenarios.
    compileClasses = concernClasses.compile;
    terminal = terminalLib;
    # The synthetic loc the shared class-invariant core occupies in share.core=true output —
    # exported so tests detect the share path via this constant instead of re-hardcoding the string.
    classShareCoreAttr = "denClassShareCore";
    inherit
      prelude
      dispatch
      resolve
      scope
      select
      product
      aspects
      pipe
      settings
      algebra
      demand
      edge
      bind
      class
      merge
      flake
      schema
      identity
      ;
    # The raw gen-graph lib (labeled-query calculus — the regular-path-query surface), role-named the
    # genEdge way so the seam register reads uniformly and the bare name doesn't collide with den's own
    # graph escape-hatch vocabulary (graphEscape / den.graph).
    genGraph = graph;
    # The A10 class-share build path (gen-class tier-2/tier-3), for the suite's parity/laziness scenarios.
    classShare = import ./output/class-share.nix { inherit prelude class errors; };
  };
}
