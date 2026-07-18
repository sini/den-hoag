# Entity registries — compile the `{ parent; contentClass; fields; }` declaration
# surface onto gen-schema. den-hoag builds ONE module tree (gen-merge) whose
# `options.den.schema` is a `mkSchemaOption`, and derives a `mkInstanceRegistry` per
# registered kind. `contentClass`/`parent` ride as den-side metadata on the kind record
# (not gen-schema fields), captured in a sidecar map keyed by kind name (`denMeta`).
{
  prelude,
  schema,
  merge,
}:
let
  # Discover the registered kinds from the schema declarations WITHOUT evaluating any
  # instance registry: a schema-only probe tree, freeform-absorbing every non-`schema`
  # `den.*` config the user modules set (instances, membership), exposes `_kindNames` +
  # `_topology`. The absorbed freeform values are IGNORED — the probe reads only
  # `schema._kindNames`/`_topology`, never the instance/membership config it swallows.
  # `build` needs the static kind list up front to generate one `mkInstanceRegistry`
  # option per kind (the tree that holds those options can't also be the tree that
  # discovers them without a laziness cycle). Two schema evals; the probe forces only
  # schema declarations. `contentClass` stays den-side and null here — the class wiring
  # that populates it lands with the classes concern (quirk channels / output assembly).
  discoverKinds =
    userModules:
    let
      probe = merge.evalModuleTree {
        modules = [
          {
            options.den = merge.mkOption {
              default = { };
              type = merge.types.submodule {
                freeformType = merge.types.lazyAttrsOf merge.types.anything;
                options.schema = schema.mkSchemaOption { };
              };
            };
          }
        ]
        ++ userModules;
      };
      sch = probe.config.den.schema;
    in
    # A kind's option mount lands at `options.den.<kindName>` (build below), so a kind literally named
    # `kinds` would collide with the framework `den.kinds` receives-registry concern option — abort NAMED
    # at discovery. `root` is likewise reserved: it is the framework output-side receiver locus (den.outputs
    # families project onto `den.kinds.root`, §4.6), not a discovered entity kind. `collector` is the
    # framework collector kind (§4.7): den-hoag augments `denMeta` with it when `den.collectors` is non-empty,
    # so a user-declared `collector` kind would collide with the framework's own. (These are the reserved
    # concern-option names guarded here; other latent concern-name collisions are out of scope.)
    if builtins.elem "kinds" sch._kindNames then
      throw "den.kinds is a framework concern option — a kind may not be named 'kinds'"
    else if builtins.elem "root" sch._kindNames then
      throw "den.kinds root is the framework output locus — a kind may not be named 'root'"
    else if builtins.elem "collector" sch._kindNames then
      throw "den.collectors owns the framework `collector` kind — a kind may not be named 'collector'"
    else
      prelude.genAttrs sch._kindNames (kindName: {
        parent = sch._topology.${kindName}.parent;
        contentClass = null;
        dim = kindName;
      });

  # Discover the declared quirk channel NAMES the same freeform-probe way `discoverKinds` reads
  # the schema: a schema-less tree freeform-absorbs every `den.*` config the user modules set and
  # exposes `den.quirks`' attr names WITHOUT forcing any quirk value (attrNames = spine only). mkDen
  # needs the channel names up front to (a) declare each as a `raw` option on the aspect schema so a
  # channel emission rides untouched (never freeform-absorbed into a nested aspect) and (b) seed the
  # §2.2 three-branch key dispatch (`classifyKey`'s channel branch). Quirk names are static decls, so
  # this probe is as sound as the kind probe.
  discoverChannels =
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
    builtins.attrNames (probe.config.den.quirks or { });

  # Discover the DECLARED output-class NAMES the same freeform-probe way `discoverChannels` reads the
  # quirks: a schema-less tree freeform-absorbs every `den.*` config the user modules set and exposes
  # `den.classes`' attr names WITHOUT forcing any class record (attrNames = spine only). mkDen needs the
  # declared class names up front to seed the REGISTERED-CLASS set — assembly spec §2.2 says an aspect key
  # is a facet, a REGISTERED class name, or a channel; the registered set is core's built-ins UNION the
  # fleet's declared classes. Declaring a class here (a) declares its `class` content bucket on the aspect
  # schema (gen-aspects `cnf.classes`), (b) admits its name to `classifyKey`'s class branch, and (c) gives
  # it a class entry + a terminal. `den.classes` names are static decls, so this probe is as sound as the
  # kind/channel probes. (The class RECORD — wrap/instantiate/share — is read later, from the built tree.)
  discoverClasses =
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
    builtins.attrNames (probe.config.den.classes or { });

  # Build the schema module tree once; user modules declare config.den.schema.<kind>
  # and the instances config.den.<kind>.<name>. Returns { kinds; registries; meta;
  # topology; roots; config; } where:
  #   kinds.<name>      = the gen-schema KIND VALUE (carries { kind; options; … }) — the sel.kind consumable
  #   registries.<name> = the evaluated instance registry (attrset of entries carrying id_hash)
  #   meta.<name>       = { parent; contentClass; dim; } den-side metadata
  #   config            = the raw evaluated module config (fleet membership + future concerns read from here)
  build =
    { userModules, denMeta }:
    let
      # THE UNIVERSAL `outputs` FIELD (§4.4/§7 output-family opt-in): every entity may opt into an output
      # family via `den.<kind>.<name>.outputs.<family> = { <field> = <value>; }`. gen-schema instance
      # registries are STRICT (an undeclared instance field aborts NAMED), so the field is DECLARED as a
      # per-kind schema option (the same posture the shim uses for `class`/`system`/`hostName`) — a `raw`
      # attrset, default `{ }`, so a fleet that opts nobody in is byte-identical (the entry carries an empty
      # `outputs`). den-side; id_hash is name-derived, so declaring the field does NOT perturb entity identity.
      outputsFieldModules = prelude.mapAttrsToList (kindName: _: {
        config.den.schema.${kindName}.options.outputs = schema.mkOption {
          type = schema.types.raw;
          default = { };
          description = "Output-family opt-ins: `<family> = { <field> = <value>; }` (§4.4/§7).";
        };
      }) denMeta;
      # THE `.edges` FIELD (§5:419 relation edges): every entity may declare relation edges via
      # `den.<kind>.<name>.edges.<rel> = <targets>`. Declared as a per-kind schema option (the same
      # outputsFieldModules posture) — a `raw` attrset, default `{ }`, so a fleet declaring no edges is
      # byte-identical (the entry carries an empty `edges`). It STORES the raw target refs; the fleet-level
      # undeclared-relation guard validates `<rel> ∈ den.relations`, and the producer lowers the refs to
      # `"${kind}:${name}"` node-ids (records carry `name` but not `kind`, so the lowering is fleet-level).
      # den-side; id_hash is name-derived, so declaring the field does NOT perturb entity identity.
      edgesFieldModules = prelude.mapAttrsToList (kindName: _: {
        config.den.schema.${kindName}.options.edges = schema.mkOption {
          type = schema.types.raw;
          default = { };
          description = "Relation edges: `<rel> = <targets>` (§5); each `<rel>` must name a declared den.relations relation.";
        };
      }) denMeta;
      tree = merge.evalModuleTree {
        modules = [
          { options.den.schema = schema.mkSchemaOption { }; }
        ]
        ++ outputsFieldModules
        ++ edgesFieldModules
        # one instance registry per declared kind, referencing the evaluated kind value:
        ++ prelude.mapAttrsToList (kindName: _: {
          options.den.${kindName} = schema.mkInstanceRegistry tree.config.den.schema.${kindName} { };
        }) denMeta
        ++ userModules;
      };
    in
    {
      kinds = removeAttrs tree.config.den.schema [
        "_kindNames"
        "_topology"
        "_refEdges"
        "_edges"
        "_roots"
        "_leaves"
      ];
      registries = prelude.mapAttrs (kindName: _: tree.config.den.${kindName}) denMeta;
      meta = denMeta;
      topology = tree.config.den.schema._topology;
      roots = tree.config.den.schema._roots;
      config = tree.config;
    };

  # classOf a scope node (§2.5): the producing scope's class entry (or null).
  classOf =
    { meta, entityOfNode }:
    node:
    let
      kindName = node.type;
      cc = meta.${kindName}.contentClass;
    in
    if cc == null then
      null
    else if builtins.isFunction cc then
      cc (entityOfNode node)
    else
      cc;
in
{
  inherit
    build
    classOf
    discoverKinds
    discoverChannels
    discoverClasses
    ;
}
