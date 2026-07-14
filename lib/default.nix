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
  entity = import ./entity.nix { inherit prelude schema merge; };
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
      ;
    projects = projectsLib;
    declarations = declare;
  };

  # The classes concern (§2.4) + the terminal crossing (§2.10, Law A15). `concernClasses.compile`
  # turns `den.classes` declarations into class config records; `terminalLib` is the ONE gen-flake
  # crossing (lib/output/terminal.nix) — den-hoag stays nixpkgs-free by defaulting classes to the
  # `collect` terminal (nixpkgs-free), with `crossNixos` available for a real build.
  concernClasses = import ./concern-classes.nix { inherit prelude bind; };
  terminalLib = import ./output/terminal.nix { inherit bind flake; } { nixpkgs = null; };
  graphEscape = import ./graph-escape.nix { inherit edge; };
  structuralAttributes = attributesLib.structural;
  runResolve = attributesLib.runResolve;
  inherit (buildRootsLib) buildRoots parseParent;

  # mkDen assembles the four concerns; Tasks 1–11 extend it. Task 1: entity registries
  # (gen-schema) + the fleet restricted product (gen-product). Task 2: scope roots +
  # structural stratum (attributes 1–6) over gen-resolve/gen-scope.
  mkDen =
    userModules:
    let
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
      # (output-modules.nix), its result appended AFTER the node's local emissions per channel (F4: bound =
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
          description = "Per-node channel-augmentation hook `{ id; result } -> { <channel> = [ contribution ]; }` run in `channelBindingsAt`; the gathered contributions are appended after the node's own emissions (F4: local ++ gathered); must stay lazy over the id spine (A17). Native default `_: { }` (identity path).";
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

      # den.sharedAspectKeys — shared-vs-own provenance (Track A rung 1, R-ROOT-FILTER prerequisite):
      # the resolved-aspect KEYS whose class content is radiated-SHARED root content rather than
      # scope-own. class-modules reads it to mark each bucket entry in its `__shared` sidecar. Compat
      # sets `[ "__default" ]` (the `den.default` reserved-aspect key); native default `[ ]` ⇒ no aspect
      # marked shared ⇒ the sidecar is all-`false` (byte-identical class buckets).
      sharedAspectKeysDecl = {
        options.den.sharedAspectKeys = merge.mkOption {
          type = merge.types.listOf merge.types.str;
          default = [ ];
          description = "Resolved-aspect keys whose class content is radiated-shared (`den.default`), for the class-modules `__shared` sidecar (R-ROOT-FILTER). Native default `[ ]`.";
        };
      };

      denMeta = entity.discoverKinds userModules;
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
          sharedAspectKeysDecl
        ]
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

      # Compile the relationships concern (den.policies) into the enrich / policy rule feeds.
      # The fixture carries no policies, so both feeds are empty and the fleet builds as before.
      # `probeSentinelFields` (native default `{ }`) configures the value-less stratum probe's sentinel;
      # `resolveFamilyNames` (native default `[ ]`, R2) stamps the resolve-family tag on the named policies.
      policiesRules =
        concernPolicies.compileWith ent.config.den.probeSentinelFields ent.config.den.resolveFamilyNames
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
      metaWithClass = builtins.mapAttrs (
        k: m: m // { contentClass = resolveClass (ent.config.den.contentClass.${k} or null); }
      ) ent.meta;
      classOfNode = entity.classOf {
        meta = metaWithClass;
        entityOfNode = node: node.decls.__entry or null;
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
      # option target the built systems mount at (D8; consumed by `systemOutputs` below + the flake-parts
      # bridge). The instantiation is NOT a core constant — a new system class (droid, or anything a user
      # invents) is a pure declaration needing zero edits here or in gen-flake.
      #
      # The nixos/darwin rows are DEFAULT declarations (D4, overridable — existing fleets unchanged): each derives its
      # evaluator from the supplied `den.nixpkgs`/`den.darwin` input (null input ⇒ null evaluator ⇒ the
      # nixpkgs-free `collect` terminal, den-hoag's pure path). A `den.classes.<name>.instantiation`
      # override wins over the default; a class setting its own `instantiate` overrides everything.
      defaultInstantiations = {
        nixos = {
          evaluator = if npkgs == null then null else npkgs.lib.nixosSystem;
          output = "nixosConfigurations";
        };
        darwin = {
          evaluator = if ndarwin == null then null else ndarwin.lib.darwinSystem;
          output = "darwinConfigurations";
        };
      };
      instantiationOf =
        name:
        (defaultInstantiations.${name} or { }) // (ent.config.den.classes.${name}.instantiation or { });
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
        # Shared-vs-own provenance (Track A rung 1): the resolved-aspect keys whose class content is
        # radiated-shared. The v1-surface shim sets `den.sharedAspectKeys = [ "__default" ]` (the
        # `den.default` reserved-aspect key); a native fleet leaves it unset ⇒ `[ ]` ⇒ nothing shared.
        sharedAspectKeys = ent.config.den.sharedAspectKeys or [ ];
      };

      structural = runResolve {
        roots = scopeRoots;
        inherit equations parseParent;
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
        interpret = ent.config.den.interpret or { };
        # The post-resolution binding-enrichment hook (native default = identity, byte-identical). A11-lazy:
        # applied inside `bindingsAt`, so forcing the systems spine never forces it, and a hook that stamps a
        # projected `hasAspect` never forces resolved-aspects until the closure is called (A17).
        enrichBindings = ent.config.den.enrichBindings or ({ bindings, ... }: bindings);
        # The per-node channel-augmentation supplier (#62a; native default = the empty gather, so
        # `channelBindingsAt` is byte-identical to its own-emissions form). An external consumer wires
        # its gather supplier (the v1 expose-ascent twin, #62b).
        channelGather = ent.config.den.channelGather or (_: { });
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

      # faceOf — the shared flake-output face builder (§2.10): a class's per-member systems re-keyed from
      # the member scope-node id ("host:igloo") to the host entity NAME ("igloo"), so a consumer addresses
      # `<output>.<host>` exactly as a flake does. With an evaluator declared these are REAL systems (the
      # `crossVia` crossing → `config.networking.hostName` evaluates); absent, the nixpkgs-free `collect`
      # artifacts (same class-major spine — one entry per host). Forcing the attrset SPINE counts hosts
      # without building any system (per-member lazy, Law A17); a real build is forced only at `.config`.
      faceOf =
        className:
        builtins.listToAttrs (
          map (
            memberId:
            let
              entry = (structural.eval.node memberId).decls.__entry or null;
            in
            {
              name = if entry != null then entry.name else memberId;
              value = output.systems.${className}.${memberId};
            }
          ) (builtins.attrNames (output.systems.${className} or { }))
        );

      # systemOutputs — the DECLARED flake-parts output faces (D8): each system class's declared `output`
      # target key → its host-name-keyed face. The face MOUNTS at that target (the flake-parts bridge / a
      # `mkDen` consumer reads `<output>`); a class with no `output` declaration contributes none.
      # `nixosConfigurations` / `darwinConfigurations` are the built-in aliases — and a new system class
      # (droid → `nixOnDroidConfigurations`) surfaces here from its declaration ALONE, with zero face code.
      systemOutputs = builtins.listToAttrs (
        builtins.filter (x: x != null) (
          map (
            name:
            let
              out = (instantiationOf name).output or null;
            in
            if out == null then
              null
            else
              {
                name = out;
                value = faceOf name;
              }
          ) effectiveClassNames
        )
      );
      nixosConfigurations = systemOutputs.nixosConfigurations or { };
      darwinConfigurations = systemOutputs.darwinConfigurations or { };
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
      # `outputs` is the GENERIC declared-target map (D8): `outputs.<target> = <host-keyed face>` for every
      # system class's declared `output` (nixosConfigurations/darwinConfigurations are its built-in aliases;
      # a user/droid class surfaces at its own declared target here). The flake-parts bridge mounts each.
      inherit graph nixosConfigurations darwinConfigurations;
      outputs = systemOutputs;
    };
in
{
  inherit errors mkDen;
  # den's selector vocabulary (identity-law entry/kind constructors + adapters); used to
  # write declarations, independent of any one mkDen instance.
  sel = select;

  # den's `projects`-facet sugar (§2.9 / A14): `hasSetting <field>` = a STATIC selector matching every
  # aspect that declares `<field>` in its settings schema — the address side of a projection rule
  # (`projects = [ { select = hasSetting "theme"; set = { theme = …; }; } ]`). Independent of any one
  # mkDen instance; the aspect-schema selector domain is den-hoag-owned (see lib/projects.nix).
  inherit (projectsLib) hasSetting;
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
    structural = structuralAttributes;
    compilePolicies = concernPolicies.compile;
    # The probe-sentinel convenience (`compilePoliciesWith sentinelFields policies`) keeps its 2-arg shape —
    # the resolve-family tag set defaults to `[ ]` here (the R2 knob is a fleet-level `den.resolveFamilyNames`
    # option, not a unit-suite concern). `compileWith` is the full 4-arg form default.nix threads.
    compilePoliciesWith = sentinelFields: concernPolicies.compileWith sentinelFields [ ] [ ];
    # classifyKey (the §2.2 three-branch dispatch) + its `facets` vocabulary — the shim's
    # key-classification consistency suite reads `facets` to pin the structural-key agreement.
    inherit (concernAspects) classifyKey facets;
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
      ;
    # The A10 class-share build path (gen-class tier-2/tier-3), for the suite's parity/laziness scenarios.
    classShare = import ./output/class-share.nix { inherit prelude class errors; };
  };
}
