# The den-hoag-facing wiring (spec-vs-reality flag 1: den-hoag has `mkDen userModules`, not a
# `flakeModule`). Two pieces:
#
#   - `flakeModuleCore` — the module(s) that DECLARE the v1 option surface as `raw`, so the v1 grammar
#     rides untouched through a module eval. den-hoag's own `mkDen` declares `den.aspects`/`den.classes`/
#     `den.schema`/… with its OWN types, so the v1 surface cannot be read in the SAME eval (two typed
#     declarations at one path conflict). It is therefore read in a SEPARATE v1-shaped eval (`evalV1`),
#     whose config `compile` desugars — the "two-eval" shape the spec's "importing den-hoag's flakeModule
#     underneath" resolves to. `flakeModule = flakeModuleCore ++ [ legacy.* ]` is the severance surface.
#   - `mkFleetModule` — the PURE bridge: `compile`'s five-key output → ONE den-hoag module setting
#     `config.den.*`. No option is redeclared here (it EMITS den-hoag config), so no collision. This is
#     what `denHoag.mkDen` consumes.
#
# `mkDen` ties them: eval the v1 modules in the v1-shaped tree, compile, bridge, hand to `denHoag.mkDen`.
{
  denHoag,
  prelude,
  schema,
  compile,
  legacy,
  deliverLib,
}:
let
  # A `raw` option holds any v1 value unmerged (single-def passthrough) — the v1 grammar (parametric
  # aspects, policy records, two-level host maps) is never type-walked or freeform-mangled.
  rawOpt =
    description:
    schema.mkOption {
      type = schema.types.raw;
      default = { };
      inherit description;
    };
  rawListOpt =
    description:
    schema.mkOption {
      type = schema.types.raw;
      default = [ ];
      inherit description;
    };

  mergeOpt =
    description:
    schema.mkOption {
      type = schema.types.anything;
      default = { };
      inherit description;
    };

  lazyAttrsOpt =
    description:
    schema.mkOption {
      type = schema.types.lazyAttrsOf schema.types.anything;
      default = { };
      inherit description;
    };

  # The v1 option surface as ONE freeform `den` submodule: each v1 concern is a `mergeOpt` sub-option (the
  # grammar rides untouched), and the `freeformType` absorbs any v1 config outside them (custom-kind
  # instances, `den.default`, …) so an arbitrary den-scoped corpus module evaluates without a schema
  # edit. Declared as a single submodule (not `options.den.<x>` groups) so it never collides with a
  # `den` leaf — the leaf/group collision the two-eval separation exists to avoid.
  #
  # TRADE-OFF of the freeform: a TYPO in an unknown `den.*` key silently succeeds HERE (it is absorbed,
  # not rejected). That is deliberate — surface-totality (every v1 key is a KNOWN key, else a named
  # error) is enforced downstream at `compile`, over the read-back config, not at this permissive eval.
  # KEEP IN SYNC with compile.nix `knownSurfaceKeys` (the totality gate reads that list).
  v1OptionsModule = {
    freeformType = schema.types.lazyAttrsOf schema.types.anything;
    options.den = {
      hosts = lazyAttrsOpt "v1 `den.hosts.<system>.<name>` (two-level host definitions).";
      homes = lazyAttrsOpt "v1 `den.homes.<system>.<name>` (standalone home-manager configurations).";
      schema = schema.mkOption {
        type = schema.types.lazyAttrsOf (schema.types.lazyAttrsOf schema.types.anything);
        default = { };
        description = "v1 `den.schema.<kind>` (containment kinds + kind-attached includes).";
      };
      aspects = lazyAttrsOpt "v1 `den.aspects.<name>` (aspect definitions).";
      policies = lazyAttrsOpt "v1 `den.policies.<name>` (policy functions / for·when records).";
      classes = lazyAttrsOpt "v1 `den.classes.<name>` (output class registrations).";
      include = rawListOpt "v1 static entity-scoped aspect inclusions.";
      quirks = lazyAttrsOpt "v1 `den.quirks.<name>` (quirk channels).";
      contentClass = lazyAttrsOpt "v1 kind -> content-class overrides.";
      nixpkgs = lazyAttrsOpt "v1 `den.nixpkgs` (transparent pass-through to den-hoag).";
      batteries = lazyAttrsOpt "v1 `den.batteries` (legacy battery aspects).";
    };
  };

  legacyBatteries = [
    ./legacy/batteries/define-user.nix
    ./legacy/batteries/flake-parts/inputs.nix
    ./legacy/batteries/flake-parts/self.nix
    ./legacy/batteries/flake-scope.nix
    ./legacy/batteries/forward.nix
    ./legacy/batteries/hjem.nix
    ./legacy/batteries/home-manager.nix
    ./legacy/batteries/host-aspects.nix
    ./legacy/batteries/hostname.nix
    ./legacy/batteries/import-tree.nix
    ./legacy/batteries/insecure/insecure.nix
    ./legacy/batteries/maid.nix
    ./legacy/batteries/os-class.nix
    ./legacy/batteries/os-user.nix
    ./legacy/batteries/primary-user.nix
    ./legacy/batteries/tty-autologin.nix
    ./legacy/batteries/unfree/unfree.nix
    ./legacy/batteries/user-shell.nix
    ./legacy/batteries/vm-autologin.nix
    ./legacy/batteries/wsl.nix
  ];

  flakeModuleCore = [ v1OptionsModule ] ++ legacyBatteries;

  injectAspectPaths =
    classes: quirks: path: value:
    if builtins.isAttrs value then
      let
        structuralKeysSet = {
          settings = true;
          includes = true;
          neededBy = true;
          meta = true;
          tags = true;
          projects = true;
          name = true;
          description = true;
          id_hash = true;
        };
        v1ClassKeyMap = {
          homeManager = "home-manager";
        };
        isNestedKey = k:
          !(structuralKeysSet ? ${k})
          && !(classes ? ${v1ClassKeyMap.${k} or k} || classes ? ${k})
          && !(quirks ? ${k})
          && (builtins.isAttrs value.${k} || builtins.isFunction value.${k});

        nestedKeys = builtins.filter isNestedKey (builtins.attrNames value);

        # Recurse into nested aspects
        recursedNested = builtins.listToAttrs (map (k: {
          name = k;
          value = injectAspectPaths classes quirks (if path == "" then k else "${path}.${k}") value.${k};
        }) nestedKeys);

        # Check if the current node itself is an aspect
        hasAspectContent = builtins.any (k: !isNestedKey k) (builtins.attrNames value);
        
        thisAspect = value // recursedNested;
        injected = if hasAspectContent && path != "" then
          thisAspect // { _aspectPath = path; name = path; }
        else
          thisAspect;
      in
        injected
    else
      value;

  # Eval the v1 modules in the v1-shaped tree and read back `config.den` (the v1 declaration surface,
  # verbatim) for `compile` to desugar. Only `flakeModuleCore` (not the legacy tag modules) declares
  # options here; the legacy surfaces join in their own tasks.
  evalV1 =
    userModules:
    let
      # Extract ALL _module.args from userModules first so they are available to filterModule
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

      filterModuleAttrs =
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
                map filterModule attrs.imports
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
        m:
        if builtins.typeOf m == "path" then
          filterModule (import m)
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
            args: filterModuleAttrs (m args)
        else
          filterModuleAttrs m;

      filteredUserModules = map filterModule userModules;

      # Fixpoint evaluation: user modules require `den` as a module argument, but `den` itself
      # includes `config.den` (the result of evaluating those modules). This mirrors how nixpkgs
      # `lib.evalModules` passes `config` to modules.
      eval = schema.evalModuleTree {
        modules = flakeModuleCore ++ filteredUserModules;
        # Layer: extractedModuleArgs (inputs, lib, self, rootPath, ...)
        # are the BASE, then evalV1's own overrides (den, withSystem) win.
        specialArgs = extractedModuleArgs // {
          isCompatEval = true;
          flake-parts-lib = extractedModuleArgs.flake-parts-lib or (
            if extractedModuleArgs ? inputs && extractedModuleArgs.inputs ? flake-parts then
              extractedModuleArgs.inputs.flake-parts.lib
            else
              null
          );
          den = let
            envVal = eval.config.den.schema.environment or {};
            envTrace = builtins.mapAttrs (k: v: if builtins.isAttrs v then builtins.attrNames v else builtins.typeOf v) envVal;
          in builtins.trace "SCHEMA ENV DETAILED: ${builtins.toJSON envTrace}" (eval.config.den // {
            lib = import ./v1-lib.nix { inherit denHoag deliverLib; };
            batteries = eval.config.den.batteries or { };
            classes = denHoag.classes // (eval.config.den.classes or { });
            policies = { host-to-users = { __isPolicy = true; fn = _: [ ]; }; } // (eval.config.den.policies or { });
            aspects = injectAspectPaths (denHoag.classes // (eval.config.den.classes or { })) (eval.config.den.quirks or { }) "" (eval.config.den.aspects or { });
            schema =
              let
                res = (schema.evalModuleTree {
                  modules = [
                    {
                      options.den.schema = schema.mkSchemaOption { };
                      config.den.schema = eval.config.den.schema or { };
                    }
                  ];
                }).config.den.schema;
                envVal = res.environment or {};
                envTrace = builtins.mapAttrs (k: v: if builtins.isAttrs v then builtins.attrNames v else builtins.typeOf v) envVal;
              in builtins.trace "RETURNED SCHEMA ENV DETAILED: ${builtins.toJSON envTrace}" res;
          });
          withSystem = extractedModuleArgs.withSystem or (_sys: fn: fn { self' = { }; inputs' = { }; });
        };
      };
    in
    let
      _traceEnvironments =
        let
          prodEnv = eval.config.den.environments.prod or {};
          prodKeys = builtins.attrNames prodEnv;
          hasGetDomain = prodEnv ? getDomainFor;
        in
        builtins.trace "PROD ENV KEYS IN EVALV1: keys=${builtins.toJSON prodKeys}, hasGetDomainFor=${builtins.toJSON hasGetDomain}" null;
    in
    builtins.seq _traceEnvironments (eval.config.den // {
      policies = { host-to-users = { __isPolicy = true; fn = _: [ ]; }; } // (eval.config.den.policies or { });
      aspects = injectAspectPaths (denHoag.classes // (eval.config.den.classes or { })) (eval.config.den.quirks or { }) "" (eval.config.den.aspects or { });
    });

  # The compat nixos instantiate wrapper (§2.5 carry-in): v1's per-host `system` never reaches
  # den-hoag's pipeline (den-hoag entities are field-less), so it is injected HERE, at the terminal —
  # the one place the per-host binding (`bindings.host`) is available. The wrapper prepends a
  # `{ nixpkgs.hostPlatform.system = systemFor host; }` module to the host's class-modules, then
  # delegates to the underlying `terminal`. `terminal` is a SEAM: the pure fleet wiring defaults it to
  # den-hoag's nixpkgs-free `collect` (the platform is inspectable in its output modules); the parity
  # harness supplies `crossNixos` for a real NixOS build. A system-less host (systemFor → null) injects
  # nothing — byte-identical to the bare terminal.
  mkNixosInstantiate =
    {
      systemFor,
      channelFor,
      instantiateFor,
      channels ? { },
      denContext,
      terminal,
      injectRelationships ? (ctx: ctx),
      instances ? { },
    }:
    args@{
      name,
      hostModules,
      bindings,
      classCfg,
    }:
    let
      v1Quirks = denContext.quirks or { };
      defaultQuirkBindings = builtins.mapAttrs (_: _: [ ]) v1Quirks;
      _traceBindingsKeys = builtins.trace "BINDINGS_KEYS: host=${name}, keys=${builtins.toJSON (builtins.attrNames bindings)}, defaultQuirks=${builtins.toJSON (builtins.attrNames defaultQuirkBindings)}" null;
      hostEntry = bindings.host or null;
      _traceHostEntry = builtins.trace "HOST_ENTRY: host=${name}, keys=${builtins.toJSON (if hostEntry == null then null else builtins.attrNames hostEntry)}" null;
      _traceBindingsVal = builtins.trace "BINDINGS_VAL: host=${name}, val=${builtins.toJSON (builtins.mapAttrs (k: v: if v == null then "null" else if builtins.isAttrs v then (if v ? name then "attrs:${v.name}" else "attrs") else if builtins.isList v then "list" else if builtins.isFunction v then "fun" else "scalar") bindings)}" null;
      sys = if hostEntry == null then null else systemFor hostEntry;
      sysModule = if sys == null then [ ] else [ { nixpkgs.hostPlatform.system = sys; } ];

      # 1. Direct instantiate from v1 host declaration (if explicit)
      directInstantiate = if hostEntry == null then null else instantiateFor hostEntry;

      # 2. Schema default instantiate reconstructed from the channel (since v1 eval strips the schema)
      channelName = if hostEntry == null then null else channelFor hostEntry;
      resolvedChannel = channels.${channelName} or null;
      schemaInstantiate =
        if resolvedChannel == null then
          null
        else if classCfg.name == "darwin" then
          resolvedChannel.darwinSystem or null
        else
          resolvedChannel.nixosSystem or null;

      hostInstantiate = if directInstantiate != null then directInstantiate else schemaInstantiate;

      hmModule =
        if resolvedChannel == null then
          [ ]
        else if classCfg.name == "darwin" then
          if resolvedChannel ? home-manager-module.darwin && resolvedChannel.home-manager-module.darwin != null then
            [ resolvedChannel.home-manager-module.darwin ]
          else
            [ ]
        else
          if resolvedChannel ? home-manager-module.nixos && resolvedChannel.home-manager-module.nixos != null then
            [ resolvedChannel.home-manager-module.nixos ]
          else
            [ ];

      splitString = sep: s: builtins.filter builtins.isString (builtins.split sep s);

      nestPath = path: value:
        if path == [ ] then
          value
        else
          { ${builtins.head path} = nestPath (builtins.tail path) value; };

      recursiveMerge = lh: rh:
        if builtins.isAttrs lh && builtins.isAttrs rh then
          builtins.zipAttrsWith (name: values:
            if builtins.length values == 1 then
              builtins.head values
            else
              recursiveMerge (builtins.elemAt values 0) (builtins.elemAt values 1)
          ) [ lh rh ]
        else
          rh;

      resolvedSettings =
        let
          resolved = bindings.__resolvedSettings or { };
          presentAspectNames = builtins.attrNames resolved;
          nestedSettingsList = map (name:
            nestPath (splitString "\\." name) (resolved.${name}.value or { })
          ) presentAspectNames;
        in
        builtins.foldl' recursiveMerge { } nestedSettingsList;

      augmentBindings =
        binds:
        builtins.mapAttrs (
          k: e:
          if builtins.isAttrs e && e ? name && instances ? ${k} && instances.${k} ? ${e.name} then
            let
              v1Instance = instances.${k}.${e.name};
            in
            if k == "host" then
              let
                mergedSettings = recursiveMerge resolvedSettings (v1Instance.settings or { });
                _traceSettings = builtins.trace "SETTINGS_MERGE for ${e.name}: inlineKeys=${builtins.toJSON (builtins.attrNames (v1Instance.settings or { }))}, resolvedKeys=${builtins.toJSON (builtins.attrNames resolvedSettings)}, mergedKeys=${builtins.toJSON (builtins.attrNames mergedSettings)}" null;
              in
              builtins.seq _traceSettings (
              e // v1Instance // {
                settings = mergedSettings;
              })
            else
              e // v1Instance
          else
            e
        ) binds;

      hostCfg =
        if hostEntry == null then
          { }
        else
          let
            sys = systemFor hostEntry;
          in
          if sys != null then
            denContext.hosts.${sys}.${hostEntry.name} or { }
          else
            { };

      envName = hostCfg.environment or "prod";
      v1Env = instances.environment.${envName} or { };
      envEntry = bindings.environment or { name = envName; };
      environmentVal = builtins.trace "V1ENV FOR ${name} KEYS: ${builtins.toJSON (builtins.attrNames v1Env)}" (envEntry // v1Env);

      allBindings = (augmentBindings (injectRelationships (defaultQuirkBindings // bindings // {
        den = denContext;
      }))) // {
        environment = environmentVal;
      };

       _traceHostModules =
        let
          showModule = m:
            if builtins.isPath m then
              builtins.toString m
            else if builtins.isFunction m then
              "lambda"
            else if builtins.isAttrs m then
              (if m ? _file then m._file
               else if m ? key then m.key
               else if m ? config && builtins.isAttrs m.config then
                 "attrs-config:keys=${builtins.concatStringsSep "," (builtins.attrNames m.config)}"
               else
                 "attrs:keys=${builtins.concatStringsSep "," (builtins.attrNames m)}")
            else
              builtins.typeOf m;
          names = map showModule hostModules;
        in
        builtins.trace "HOST_MODULES for ${name}: [${builtins.concatStringsSep "; " names}]" null;
      compatAliasModule = { lib, ... }: {
        key = "compatAliasModule";
        _file = "compatAliasModule";
        options.den = lib.mkOption {
          type = lib.types.anything;
          default = { };
        };
        config = lib.mkMerge [
          {
            den = allBindings.den or { };
          }
          {
            den.host = instances.host or { };
            den.hosts = instances.host or { };
            den.user = instances.user or { };
            den.users = instances.user or { };
            den.environment = instances.environment or { };
            den.environments = instances.environment or { };
            den.cluster = instances.cluster or { };
            den.clusters = instances.cluster or { };
            den.group = instances.group or { };
            den.groups = instances.group or { };
          }
        ];
      };
      collected = terminal (
        args
        // {
          hostModules = [ { _module.args = allBindings; } compatAliasModule ] ++ sysModule ++ hostModules;
          bindings = allBindings;
        }
      );
      extractedModules = collected.modules or collected.hostModules or [ ];
    in
    if builtins.seq _traceBindingsKeys (builtins.seq _traceHostEntry (builtins.seq _traceBindingsVal (hostInstantiate != null))) then
      hostInstantiate {
        modules = hmModule ++ extractedModules;
        specialArgs = allBindings;
      }
    else
      collected;

  # The pure bridge: `compile`'s output → a den-hoag `config.den.*` module. Instances become
  # `config.den.<kind>.<name>` FIELD-LESS — den-hoag entities carry no content (it comes from aspects),
  # and its kinds are strict, so only the registry KEY crosses (the id_hash is name-derived, coherent
  # with the boundary entries). The v1 entity fields (class/system/…) stay compile-side metadata
  # (contentClass, systemFor, membership); everything else maps to its den-hoag concern option. The
  # nixos class carries the compat systemFor-injecting instantiate (§2.5 carry-in), so `den.hosts`'
  # per-host platform reaches the built system.
  mkFleetModule =
    v1Decls: compiled: inputs: lib:
    let
      instanceConfig = compiled.entities.instances;
      denContext = v1Decls // {
        lib = import ./v1-lib.nix { inherit denHoag deliverLib; };
        evalModules = lib.evalModules;
        rawSchema = v1Decls.schema or { };
        batteries = v1Decls.batteries or { };
        schema =
          (schema.evalModuleTree {
            modules = [
              {
                options.den.schema = schema.mkSchemaOption { };
                config.den.schema = v1Decls.schema or { };
              }
            ];
          }).config.den.schema;
      };

      nixosInstantiate = mkNixosInstantiate {
        inherit (compiled.entities) systemFor channelFor instantiateFor;
        terminal = denHoag.internal.terminal.collect;
        channels =
          let
            ins = inputs;
          in
          {
            nixos-unstable = {
              nixosSystem = ins.nixpkgs-unstable.lib.nixosSystem or null;
              darwinSystem = ins.nix-darwin-unstable.lib.darwinSystem or null;
              home-manager-module.nixos = ins.home-manager-unstable.nixosModules.home-manager or null;
              home-manager-module.darwin = ins.home-manager-unstable.darwinModules.home-manager or null;
            };
            nixpkgs-master = {
              nixosSystem = ins.nixpkgs-master.lib.nixosSystem or null;
              darwinSystem = ins.nix-darwin-unstable.lib.darwinSystem or null;
              home-manager-module.nixos = ins.home-manager-master.nixosModules.home-manager or null;
              home-manager-module.darwin = ins.home-manager-master.darwinModules.home-manager or null;
            };
            nixos-stable = {
              nixosSystem = ins.nixpkgs.lib.nixosSystem or null;
              darwinSystem = ins.nix-darwin.lib.darwinSystem or null;
              home-manager-module.nixos = ins.home-manager.nixosModules.home-manager or null;
              home-manager-module.darwin = ins.home-manager.darwinModules.home-manager or null;
            };
            nixpkgs-stable-darwin = {
              nixosSystem = ins.nixpkgs-stable-darwin.lib.nixosSystem or null;
              darwinSystem = ins.nix-darwin.lib.darwinSystem or null;
              home-manager-module.nixos = ins.home-manager-stable-darwin.nixosModules.home-manager or null;
              home-manager-module.darwin = ins.home-manager-stable-darwin.darwinModules.home-manager or null;
            };
          };
        inherit denContext;
        injectRelationships = compiled.injectRelationships or (ctx: ctx);
        instances =
          let
            rawInstances = compiled.entities.instances or { };
            regs = compiled.entities.registries or { };
            res = regs // rawInstances;
            _traceInstances = builtins.trace "INSTANCES KEYS: ${builtins.toJSON (builtins.attrNames res)}
ENV KEYS: ${builtins.toJSON (builtins.attrNames (res.environment or {}))}
CLUSTER KEYS: ${builtins.toJSON (builtins.attrNames (res.cluster or {}))}
PROD ENV KEYS: ${builtins.toJSON (builtins.attrNames (res.environment.prod or {}))}" null;
          in
          builtins.seq _traceInstances res;
      };
    in
    {
      config.den = {
        inherit (compiled.entities) schema membership contentClass;
        aspects = compiled.aspects;
        policies = compiled.policies;
        quirks = compiled.channels;
        classes = compiled.classes // {
          nixos = (compiled.classes.nixos or { }) // {
            instantiate = nixosInstantiate;
          };
        };
        nixpkgs = compiled.nixpkgs or null;
      }
      // instanceConfig;
    };

  flakeOutputModule =
    {
      config,
      ...
    }@args:
    let
      lib = args.lib or null;
      rootPath = args.rootPath or null;
      isCompatEval = args.isCompatEval or false;
      v1Base = evalV1 [
        {
          _module.args =
            prelude.optionalAttrs (lib != null) { inherit lib; }
            // prelude.optionalAttrs (args ? inputs) { inherit (args) inputs; }
            // prelude.optionalAttrs (args ? self) { inherit (args) self; }
            // prelude.optionalAttrs (rootPath != null) { inherit rootPath; };
        }
      ];
    in
    if isCompatEval then
      { }
    else
      {
      # When evaluated by flake-parts (which passes `lib`), provide a permissive definition collector.
      # This leverages gen-schema's strength: flake-parts only loosely merges the `den` attrset,
      # while the strict `schema.evalModuleTree` in `mkDen` does the actual heavy lifting.
       options.den =
        let
          v1Anything = import ./v1-type.nix {
            inherit lib;
            aspectNames = builtins.attrNames (v1Base.aspects or { });
          };
        in
        if lib != null then
          lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.lazyAttrsOf v1Anything;
              options = {
                schema = lib.mkOption {
                  type = lib.types.lazyAttrsOf (
                    lib.types.submodule {
                      freeformType = lib.types.lazyAttrsOf v1Anything;
                      options.includes = lib.mkOption {
                        type = lib.types.listOf v1Anything;
                        default = [ ];
                      };
                      options.imports = lib.mkOption {
                        type = lib.types.listOf v1Anything;
                        default = [ ];
                      };
                    }
                  );
                  default = { };
                };
              };
            };
            default = { };
            description = "The den v1 declaration surface (flake-parts permissive collector).";
          }
        else
          { };

      config._module.args.den = 
        config.den // {
        lib = import ./v1-lib.nix { inherit denHoag deliverLib; };
        batteries = v1Base.batteries or { };
        policies = (v1Base.policies or { }) // (config.den.policies or { });
        classes = denHoag.classes // (v1Base.classes or { }) // (config.den.classes or { });
        aspects = injectAspectPaths (denHoag.classes // (v1Base.classes or { }) // (config.den.classes or { })) (config.den.quirks or { }) "" ((v1Base.aspects or { }) // (config.den.aspects or { }));
        schema =
          (schema.evalModuleTree {
            modules = [
              {
                options.den.schema = schema.mkSchemaOption { };
                config.den.schema = config.den.schema or { };
              }
            ];
          }).config.den.schema;
      };

       config.flake =
        let
          built = mkDen [
            {
              den = config.den // {
                policies = (v1Base.policies or { }) // (config.den.policies or { });
                classes = denHoag.classes // (v1Base.classes or { }) // (config.den.classes or { });
                aspects = injectAspectPaths (denHoag.classes // (v1Base.classes or { }) // (config.den.classes or { })) (config.den.quirks or { }) "" ((v1Base.aspects or { }) // (config.den.aspects or { }));
              };
            }
            {
              _module.args =
                prelude.optionalAttrs (lib != null) { inherit lib; }
                // prelude.optionalAttrs (args ? inputs) { inherit (args) inputs; }
                // prelude.optionalAttrs (args ? self) { inherit (args) self; }
                // prelude.optionalAttrs (rootPath != null) { inherit rootPath; };
            }
          ];

          findHost = name:
            let
              allSystems = builtins.attrValues (config.den.hosts or { });
              found = builtins.filter (systemHosts: systemHosts ? ${name}) allSystems;
            in
            if found == [ ] then null else (builtins.head found).${name};

          hasAttr = targetAttr: hostName:
            let
              host = findHost hostName;
            in
            if host == null then
              true
            else
              let
                class = host.class or (if builtins.match ".*darwin" (host.system or "") != null then "darwin" else "nixos");
                defaultInto = if class == "darwin" then [ "darwinConfigurations" ] else [ "nixosConfigurations" ];
                into = host.intoAttr or defaultInto;
              in
              builtins.elem targetAttr into;

          filterHosts = targetAttr: hosts:
            builtins.listToAttrs (
              builtins.concatMap (
                name:
                if hasAttr targetAttr name then
                  [ { inherit name; value = hosts.${name}; } ]
                else
                  [ ]
              ) (builtins.attrNames hosts)
            );
        in
        {
          nixosConfigurations = filterHosts "nixosConfigurations" (built.nixosConfigurations or { });
          darwinConfigurations = filterHosts "darwinConfigurations" (built.darwinConfigurations or { });
        };
    };

  # The full driver: v1 modules → the den-hoag assembly. `flakeModule` supplies the v1
  # option declarations for `evalV1`; `compile` desugars; `mkFleetModule` bridges; `denHoag.mkDen` builds.
  # We expose `flakeOutputModule` for flake-parts users, but keep `flakeModuleCore` pure for `evalV1`.
  flakeModule = [ flakeOutputModule ];

  # The LEGACY desugars: the ONLY references to `legacy.*` outside `legacy/` (the flakeModule assembly,
  # §2.1 severance) — applied to the v1 surface BEFORE compile so den-hoag sees only grounded vocabulary.
  # Each is an or-identity: severed (no `desugar` ⇒ the identity), a residual legacy key survives to
  # compile and trips that surface's sentinel (Law C5). Both pure (Law C2): v1 → v1 transforms.
  #   • provides → v1-aspects → v1-aspects (§B4a `neededBy`/`includes`/content).
  #   • forwards → v1 → v1: strips `den.classes.<c>.forwardTo` (the compile-visible forward surface).
  legacyProvidesDesugar = legacy.provides.desugar or (v1: v1.aspects or { });
  legacyForwardsDesugar = legacy.forwards.desugar or (v1: v1);
  legacyDefaultsDesugar = legacy.defaults.desugar or (v1: v1);

  flattenAspects =
    classes: quirks: path: value:
    if builtins.isFunction value then
      { ${path} = value; }
    else if builtins.isAttrs value then
      let
        structuralKeysSet = {
          settings = true;
          includes = true;
          neededBy = true;
          meta = true;
          tags = true;
          projects = true;
          name = true;
          description = true;
          id_hash = true;
        };
        v1ClassKeyMap = {
          homeManager = "home-manager";
        };
        isNestedKey = k:
          !(structuralKeysSet ? ${k})
          && !(classes ? ${v1ClassKeyMap.${k} or k} || classes ? ${k})
          && !(quirks ? ${k})
          && (builtins.isAttrs value.${k} || builtins.isFunction value.${k});
        
        nestedKeys = builtins.filter isNestedKey (builtins.attrNames value);
        aspectKeys = builtins.filter (k: !isNestedKey k) (builtins.attrNames value);
        
        thisAspect =
          if path != "" && (aspectKeys != [ ] || nestedKeys == [ ]) then
            { ${path} = builtins.removeAttrs value nestedKeys; }
          else
            { };
            
        nestedAspects = prelude.foldl' (acc: k:
          acc // flattenAspects classes quirks (if path == "" then k else "${path}.${k}") value.${k}
        ) { } nestedKeys;
      in
      thisAspect // nestedAspects
    else
      { };

  # Thread the desugars: forwards reshapes `classes`, then provides reshapes `aspects`.
  desugarLegacy =
    v1:
    let
      # Flatten aspects before desugaring, so provides.desugar and compile see a flat set
      classes = denHoag.classes // (v1.classes or { });
      quirks = v1.quirks or { };
      flatAspects = flattenAspects classes quirks "" (v1.aspects or { });
      v1WithFlat = v1 // { aspects = flatAspects; };

      v1d = legacyDefaultsDesugar v1WithFlat;
      v1f = legacyForwardsDesugar v1d;
      desugaredAspects = builtins.mapAttrs (name: aspect:
        if builtins.isAttrs aspect then
          aspect // { _aspectPath = name; name = name; }
        else
          aspect
      ) (legacyProvidesDesugar v1f);
    in
    v1f
    // {
      aspects = desugaredAspects;
      _originalFlatAspects = desugaredAspects;
    };

  # `compileFull` — the "through flakeModule" compile: apply this wiring's legacy desugars, then compile.
  # This is what a v1 surface sees when driven by the assembled `flakeModule` (both legacy present) or by
  # a SEVERED wiring (`mkWiring` with a subset). For a non-legacy v1 set the desugars are or-identity, so
  # `compileFull ≡ compile`; that identity is exactly the severability the C5 suite pins (a non-legacy
  # fixture compiles byte-identically with any legacy subset). A legacy fixture through a wiring WITHOUT
  # its module keeps the residual key, which trips compile's sentinel (Law C5).
  compileFull = v1: compile (desugarLegacy v1);
  # `den.interpret` — the gen-edge source-interpreter seam (item 7): the legacy forwards module's
  # `synthesize`/`rewalk` composers, threaded into den-hoag's single `materialize` via the shipped raw
  # option (lib/default.nix `interpretDecl`, output-modules.nix `interpret ? { }`) WITHOUT editing
  # output-modules.nix. Severed (no forwards module ⇒ `or { }`) ⇒ the native default: no synthesize
  # source is ever folded, so `{ }` is complete. den-hoag constructs no synthesize record and defines
  # no interpreter — both are the legacy module's, supplied here as data + a closure.
  interpretModule = {
    config.den.interpret = legacy.forwards.interpret or { };
  };
  mkDen =
    userModules:
    let
      v1Decls = evalV1 userModules;
      extractedModuleArgs = prelude.foldl' (
        acc: m:
        if builtins.isAttrs m && m ? _module then
          acc // (m._module.args or { })
        else
          acc
      ) { } userModules;
      inputs = extractedModuleArgs.inputs or { };
      lib = extractedModuleArgs.lib or (inputs.nixpkgs.lib or null);
      
      v1DeclsWithRegistry = v1Decls // {
        _lazyDatabase = built.den;
        _evalModules = lib.evalModules;
        _rawSchema = v1Decls.schema or { };
      };


      compiled = compile (desugarLegacy v1DeclsWithRegistry);
      denModule = mkFleetModule v1Decls compiled inputs lib;
      
      built = denHoag.mkDen [
        denModule
        interpretModule
      ];
    in
    built;
in
{
  inherit
    mkNixosInstantiate
    flakeModuleCore
    flakeModule
    v1OptionsModule
    evalV1
    mkFleetModule
    mkDen
    desugarLegacy
    compileFull
    ;
}
