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
  filterModuleAttrs =
    availableArgs:
    attrs:
    if builtins.isAttrs attrs then
      let
        newOptions =
          if attrs ? options && builtins.isAttrs attrs.options && attrs.options ? den then
            { inherit (attrs.options) den; }
          else
            { };
        newConfig =
          if attrs ? config && builtins.isAttrs attrs.config && attrs.config ? den then
            { inherit (attrs.config) den; }
          else
            { };
        newImports =
          if attrs ? imports && builtins.isList attrs.imports then
            map (filterModule availableArgs) attrs.imports
          else
            [ ];
        newModule =
          if attrs ? _module then
            { inherit (attrs) _module; }
          else
            { };
      in
      newModule
      // (prelude.optionalAttrs (newOptions ? den) { options = newOptions; })
      // (prelude.optionalAttrs (newConfig ? den) { config = newConfig; })
      // (prelude.optionalAttrs (attrs ? den) { den = attrs.den; })
      // (prelude.optionalAttrs (attrs ? imports) { imports = newImports; })
    else
      attrs;

  filterModule =
    availableArgs:
    m:
    if builtins.typeOf m == "path" then
      filterModule availableArgs (import m)
    else if builtins.isFunction m then
      let
        fArgs = builtins.functionArgs m;
        hasUnsatisfiableArg = prelude.any (
          name:
          !fArgs.${name}
          && !(builtins.elem name [ "config" "options" "lib" "pkgs" "modulesPath" "_module" ])
          && !(availableArgs ? ${name})
        ) (builtins.attrNames fArgs);
      in
      if hasUnsatisfiableArg then
        _: { }
      else
        args: filterModuleAttrs availableArgs (m args)
    else
      filterModuleAttrs availableArgs m;

  filterModules = availableArgs: map (filterModule availableArgs);

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
      extractedModuleArgs = prelude.foldl' (
        acc: m:
        if builtins.isAttrs m && m ? _module then
          acc // (m._module.args or { })
        else
          acc
      ) { } userModules;
      availableArgs = extractedModuleArgs // {
        isCompatEval = true;
        flake-parts-lib = null;
        den = null;
        withSystem = null;
      };
      filteredUserModules = filterModules availableArgs userModules;
      probe = merge.evalModuleTree {
        specialArgs = extractedModuleArgs // {
          isCompatEval = true;
          flake-parts-lib = extractedModuleArgs.flake-parts-lib or (
            if extractedModuleArgs ? inputs && extractedModuleArgs.inputs ? flake-parts then
              extractedModuleArgs.inputs.flake-parts.lib
            else
              null
          );
        };
        modules = [
          {
            freeformType = merge.types.lazyAttrsOf merge.types.anything;
            options.den = {
              schema = schema.mkSchemaOption { };
            };
          }
        ]
        ++ filteredUserModules;
      };
      sch = probe.config.den.schema;
      freeformProbe = merge.evalModuleTree {
        specialArgs = probe.specialArgs;
        modules = [
          {
            options.den = merge.mkOption {
              type = merge.types.anything;
              default = { };
            };
          }
        ]
        ++ filteredUserModules;
      };
    in
    prelude.genAttrs sch._kindNames (kindName: {
      parent = sch._topology.${kindName}.parent;
      contentClass = null;
      dim = kindName;
      strict = freeformProbe.config.den.schema.${kindName}.strict or true;
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
      extractedModuleArgs = prelude.foldl' (
        acc: m:
        if builtins.isAttrs m && m ? _module then
          acc // (m._module.args or { })
        else
          acc
      ) { } userModules;
      availableArgs = extractedModuleArgs // {
        isCompatEval = true;
        flake-parts-lib = null;
        den = null;
        withSystem = null;
      };
      filteredUserModules = filterModules availableArgs userModules;
      probe = merge.evalModuleTree {
        specialArgs = extractedModuleArgs // {
          isCompatEval = true;
          flake-parts-lib = extractedModuleArgs.flake-parts-lib or (
            if extractedModuleArgs ? inputs && extractedModuleArgs.inputs ? flake-parts then
              extractedModuleArgs.inputs.flake-parts.lib
            else
              null
          );
        };
        modules = [
          {
            freeformType = merge.types.lazyAttrsOf merge.types.anything;
            options.den = { };
          }
        ]
        ++ filteredUserModules;
      };
    in
    builtins.attrNames (probe.config.den.quirks or { });

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
      extractedModuleArgs = prelude.foldl' (
        acc: m:
        if builtins.isAttrs m && m ? _module then
          acc // (m._module.args or { })
        else
          acc
      ) { } userModules;
      availableArgs = extractedModuleArgs // {
        isCompatEval = true;
        flake-parts-lib = null;
        den = null;
        withSystem = null;
      };
      filteredUserModules = filterModules availableArgs userModules;
      tree = merge.evalModuleTree {
        specialArgs = extractedModuleArgs // {
          isCompatEval = true;
          flake-parts-lib = extractedModuleArgs.flake-parts-lib or (
            if extractedModuleArgs ? inputs && extractedModuleArgs.inputs ? flake-parts then
              extractedModuleArgs.inputs.flake-parts.lib
            else
              null
          );
        };
        modules = [
          { options.den.schema = schema.mkSchemaOption { }; }
        ]
        # one instance registry per declared kind, referencing the evaluated kind value:
        ++ prelude.mapAttrsToList (kindName: meta: {
          options.den.${kindName} = schema.mkInstanceRegistry tree.config.den.schema.${kindName} {
            strict = meta.strict;
          };
        }) denMeta
        ++ filteredUserModules;
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
    ;
}
