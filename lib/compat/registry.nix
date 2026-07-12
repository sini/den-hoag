# THE BRIDGE-REGISTRY PASSTHROUGH — the v1 built-in host registry, declared shim-side (replaces the
# per-host side-eval harvest, the deleted instance-eval.nix).
#
# den v1 AUTO-DECLARES its built-in entity registries: `options.den.hosts = types.hostsOption` (pin
# 11866c16 modules/options.nix:71; `options.den.homes` is the :72 twin — corpus-unused, not
# reproduced; v1 declares NO `den.users` registry — users nest under `host.users`/`den.homes`).
# `hostsOption` (pin nix/lib/entities/host.nix:26-44) is a TWO-PHASE option:
#
#   (1) a permissive def COLLECTOR — `attrsOf (submodule { freeformType = deepMergeAttrs })`
#       (deepMergeAttrs: recursiveUpdate without leaf forcing, pin _types.nix:29-34) merges the
#       per-module authored decls;
#   (2) an `apply` that NORMALIZES flat hosts into their system group (`preprocessHosts`, pin
#       _types.nix:147-172) and RE-MERGES through the STRICT `innerType` — `attrsOf systemType`,
#       `systemType = submodule { freeformType = attrsOf (hostType <system>) }` (pin host.nix:24,
#       46-51) — so EVERY host evaluates through the host kind's instance submodule (strict = false,
#       pin host.nix:56) and the kind's schema-declared per-host defaults MATERIALIZE at the module
#       system's NATIVE priorities: authored def 100 < corpus `mkDefault` 1000 (nix-config
#       schema/host.nix:319-334) < base option default 1500. The deleted harvest hand-rolled exactly
#       that ladder in a SIDE eval; the registry eval reproduces it for free.
#
# The bridge (bridge.nix) mounts `mkHostsOption` as `options.den.hosts` beside its other declared
# options — the declaration BYPASSES the freeform `anything` (no fn-formals erasure, no raw ride), and
# `config.den.hosts` becomes the corpus-visible MERGED view (what v1's typed option always was: the
# corpus's own `den.hosts` readers — colmena.nix, policies/fleet.nix, scope-engine/acl.nix — read the
# APPLIED view under v1). It is the SINGLE source the ctx-entity stamps (`stampOf`, via the bridge's
# `_entityStamps`) and the compile-side grains (`instantiateFor`/`hmModuleFor`, ingest.nix) read.
#
# nixpkgs-lib-free file: the CONSUMER's `lib` enters as an inert call argument (the R10 posture; this
# file imports no nixpkgs).
{ }:
let
  # The BASE ENTITY MODULE — v1's hostType instance option surface (pin 11866c16
  # nix/lib/entities/host.nix:53-105), reproduced for exactly the options the corpus kind module
  # reads/writes plus the grain-relevant ones. Everything else v1 declares there (aspect,
  # description, mainModule, __resolveResult, __pathSetByScope) reads den v1 RUNTIME machinery the
  # shim replaces wholesale — none is grain- or stamp-relevant, so none is declared; an authored def
  # for one rides the freeform, inert. (`intoAttr` IS declared below — the corpus gates on it,
  # fleet.nix:69.) `system` is the two-level GROUP KEY
  # (v1 :64 `strOpt "platform system" system` — the systemType submodule's `name`), null on the
  # option-classification probe.
  baseEntityModule =
    lib: system:
    { name, config, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      # v1 hostType is strict = false (pin :56): unknown authored keys (aspect content, …) absorb as
      # inert raw values — never type-walked, never forced.
      freeformType = types.lazyAttrsOf types.raw;
      # v1's gen-schema mkInstanceType injects `_module.args.<kind>` — the instance itself as the
      # kind-named module arg (pin 11866c16 entities/home.nix:20-22 comment; the explicit cross-kind
      # twin `config._module.args.host` at home.nix:105 / host.nix:154). Corpus kind-module imports
      # READ it: the home-env `hostOptions` module is `{ host, lib, ... }:` (v1 home-env.nix:35-55;
      # compat home-env.nix `hostOptions`) with option defaults over `host.users` — the nix-on-droid
      # battery's `droidHome.hostConf` (corpus nix-on-droid.nix:172) rides `den.schema.host.imports`.
      config._module.args.host = config;
      options = {
        # `name` — gen-schema's mkInstanceType injects the instance key as `name` (pin
        # entities/host.nix:21-23); the corpus reads it (`secretPath`/`facts` defaults,
        # corpus host.nix:319-320).
        name = mkOption {
          type = types.str;
          default = name;
          description = "instance name (gen-schema-injected under v1)";
        };
        # v1 :64 `system = strOpt "platform system" system` — the `den.hosts.<sys>` group key rides
        # as the option DEFAULT (a flat host's authored `system` was moved to its group key by
        # preprocessHosts, v1 _types.nix:157-170); raw + null keeps the probe/system-less case legal.
        system = mkOption {
          type = types.raw;
          default = system;
          description = "platform system (v1 entities/host.nix:64 — the two-level group key)";
        };
        # v1 :65-67 — class derived from the platform suffix. null-guarded (a null system derives
        # nixos, matching ingest's classOfHost fallback); an authored `class` (corpus `slab` =
        # "droid") overrides, as under v1.
        class = mkOption {
          type = types.raw;
          default =
            if config.system != null && lib.hasSuffix "darwin" config.system then "darwin" else "nixos";
          description = "os-configuration nix class for host (v1 entities/host.nix:65-67)";
        };
        # v1 :75-80 — `users`, the host-embedded user accounts, default `{ }`. v1 types it
        # `attrsOf (userType config)` (each user through the USER kind's instance submodule); here it
        # is RAW-HELD — the user instance machinery is v1 runtime the shim replaces (users bind via
        # the stubbed env fan-out, board #49; authored `host.users` is corpus-zero), and raw keeps the
        # field structurally EXCLUDED from the ctx-entity stamp (user attrs may carry aspects/fns).
        # The DECLARATION matters for v1 option-default parity: the home-env `enable` default reads
        # `attrValues host.users` (v1 home-env.nix:44-48), which must be `{ }` — not a missing
        # attribute — on a user-less host.
        users = mkOption {
          type = types.lazyAttrsOf types.raw;
          default = { };
          description = "host-embedded user accounts (v1 entities/host.nix:75-80; raw-held, board #49)";
        };
        # v1 :81-105 — `instantiate`, type raw (:96), base default = den v1's OWN flake inputs by
        # class (:98-104, `inputs.nixpkgs.lib.nixosSystem` / `inputs.darwin.lib.darwinSystem`) at
        # option-default priority (1500). THE ONE VALUE DEVIATION (priority-faithful): den-hoag
        # carries no nixpkgs, and its analog of "den's own fallback evaluator" IS the lower
        # instantiation grains (the class N1 declaration / `den.nixpkgs` crossNixos / `collect` —
        # flake-module.nix mkNixosInstantiate). So the base default here is null = "fall to the
        # lower grains", keeping the D7 grain ladder intact. The PRIORITY INTERPLAY is v1's
        # exactly: authored (100) beats the corpus's mkDefault (1000, corpus host.nix:325) beats
        # this base default (1500) — the module system's NATIVE ladder, nothing hand-rolled.
        instantiate = mkOption {
          type = types.raw;
          default = null;
          description = "per-host OS-configuration evaluator (v1 entities/host.nix:81-105; base default = the lower grains here)";
        };
        # v1 :106-135 — `intoAttr`, the flake attr PATH where this configuration's named result lands
        # (`flake.<intoAttr>.<name>`), CLASS-DERIVED verbatim: nixos ⇒ ["nixosConfigurations" name],
        # darwin ⇒ ["darwinConfigurations" name], systemManager ⇒ ["systemConfigs" name]; an unknown
        # class THROWS on the `.${config.class}` select — v1's posture, KEPT. Declared (unlike the
        # runtime-machinery fields the header lists) because the corpus GATES `env-to-hosts` on
        # `hostCfg.intoAttr != [ ]` (nix-config policies/fleet.nix:69) — a live read once the resolve
        # arm fires; the omission stalled the corpus re-probe here (blocker #3). `listOf str` is
        # DATA-shaped, so it RIDES the ctx-entity stamp (v1 hosts carry it, harmless data); an authored
        # def wins natively (def priority 100 > this base option default 1500).
        intoAttr = mkOption {
          type = types.listOf types.str;
          default =
            {
              nixos = [
                "nixosConfigurations"
                config.name
              ];
              darwin = [
                "darwinConfigurations"
                config.name
              ];
              systemManager = [
                "systemConfigs"
                config.name
              ];
            }
            .${config.class};
          description = "flake attr path for the named result (v1 entities/host.nix:106-135; class-derived: flake.<intoAttr>.<name>)";
        };
        # v1's `host.home-manager.{enable,module}` — declared NOT by the base entity but by the
        # home-manager BATTERY's hostConf (pin nix/lib/home-env.nix:35-55 `hostOptions`, wired at
        # modules/aspects/batteries/home-manager.nix:28 `den.schema.host.imports = [ result.hostConf ]`);
        # the corpus overrides `.module` channel-driven (corpus host.nix:329-334). Both halves are
        # declared here so an authored def of either is registry-legal; `enable`'s v1 DEFAULT
        # (`host-has-user-with-class`, home-env.nix:44-48 — a read of the host's RESOLVED users) is
        # DELIBERATELY NOT reproduced: the compat membership is empty for corpus hosts (users bind via
        # the stubbed env fan-out, board #49), so materializing it would yield `false` fleet-wide and
        # suppress the hm import. raw + null: only an explicit authored/kind def lands, and the
        # hmModuleFor gate (ingest.nix) reads `enable == false` as the opt-out — the documented
        # membership CEILING (ledger R6). Type raw, not v1's deferredModule (:50): raw holds the VALUE
        # byte-identical (the C1 inert-data posture, like instantiate); the deferredModule
        # imports-wrap belongs to the CONSUMING module eval (the compat nixos wrapper's keyed import,
        # flake-module.nix), not the registry.
        home-manager.enable = mkOption {
          type = types.raw;
          default = null;
          description = "per-host home-manager opt-out (v1 home-env.nix:44-48; the membership-derived default is the board-#49 ceiling, so only an explicit def lands)";
        };
        home-manager.module = mkOption {
          type = types.raw;
          default = null;
          description = "per-host home-manager module (v1 home-env.nix:49-53 via the hm battery hostConf; corpus host.nix:329-334)";
        };
      };
    };

  # ── the STRUCTURAL EXCLUSION RULE (kind-generic: one predicate over DECLARED option types; zero
  # kind names, zero field names) ─────────────────────────────────────────────────────────────────
  # A field rides the ctx-entity stamp iff its declared option type holds resolvable DATA or
  # normal-form lambdas. EXCLUDED type classes — `raw`, `deferredModule`(`With`), `anything` — hold
  # ARBITRARY unevaluated structure (a nixpkgs module tree, an evaluator closure, another entity's
  # registry entry): deepSeq'd resolution state must never walk those (the deepSeq-state hazard;
  # `instantiate`/`home-manager.module` are `types.raw` → structurally excluded). The exclusion
  # recurses through `nestedTypes`, so a CONTAINER of an excluded element is excluded (`listOf raw` —
  # the corpus's microvm.guests, host ENTRIES each carrying an hm module tree; `attrsOf anything` —
  # cluster.secrets), while `functionTo <data>` (gen-schema METHODS — the corpus's `functionTo str`
  # getAssignment/domainFor/getDomainFor) RIDES: a lambda is a NORMAL FORM (deepSeq stops at function
  # values), which is how method lambdas and data ride while module-shaped values never do.
  # Submodule-typed fields ride WHOLE (their merged values are data trees — the settings precedent;
  # a submodule's option internals are its own merge's concern, not a crossing hazard).
  excludedType =
    t:
    builtins.elem (t.name or "") [
      "raw"
      "deferredModule"
      "deferredModuleWith"
      "anything"
    ]
    || builtins.any excludedType (builtins.attrValues (t.nestedTypes or { }));

  # The INCLUSION TREE over a kind's declared option surface (an `options` attrset: the shim-owned
  # hosts registry probe below, or a consumer-declared registry's `type.getSubOptions` — both read
  # FORCE-FREE: only option `.type` records are inspected, never a default or a config value). Leaf
  # `true` = the field rides; a nested tree = an option GROUP rides partially (only its included
  # children — the corpus's `microvm` group keeps passthrough/sharedNixStore, drops the raw
  # `guests`); an all-excluded group is omitted. Skipped structurally: `_`-prefixed internals
  # (`_module`) at every level, and the gen-schema IDENTITY pair `name`/`id_hash` at the TOP level —
  # the den-hoag registry OWNS entity identity (its mkInstanceRegistry declares both on every
  # instance), so identity is never stamped (an identity convention, not a field census).
  # `mkStampTree keepLeaf` — the shared walk; `keepLeaf` decides which OPTION leaves ride. Two
  # instances: the deepSeq-safe stamp (`stampTreeOf`, leaves NOT excludedType — the original law,
  # unchanged) and its RAW DUAL (`rawStampTreeOf`, #70 — EXACTLY the excluded leaves). A name is
  # either an option (a leaf, in exactly ONE tree) or a group (walked by both), so the two trees'
  # LEAF sets are disjoint by construction and only GROUPS can collide (the corpus `microvm`: safe
  # children passthrough/sharedNixStore, raw child guests) — the property ingest's lazy deep-union
  # overlay relies on (ingest.nix `deepUnionStamps`).
  mkStampTree =
    keepLeaf: options:
    let
      isOption = v: builtins.isAttrs v && (v._type or null) == "option";
      walk =
        skipIdentity: opts:
        let
          names = builtins.filter (
            n: builtins.substring 0 1 n != "_" && (!skipIdentity || (n != "name" && n != "id_hash"))
          ) (builtins.attrNames opts);
          classify =
            n:
            let
              v = opts.${n};
            in
            if isOption v then
              (if keepLeaf v then { ${n} = true; } else { })
            else if builtins.isAttrs v then
              (
                let
                  sub = walk false v;
                in
                if sub == { } then { } else { ${n} = sub; }
              )
            else
              { };
        in
        builtins.foldl' (acc: n: acc // classify n) { } names;
    in
    walk true options;

  stampTreeOf = mkStampTree (v: !excludedType (v.type or { }));

  # The RAW-FIELD tree (#70, ledger u19's next-link): exactly the leaves `stampTreeOf` EXCLUDES.
  # The exclusion's reason STANDS — raw/deferredModule/anything-class values must never enter
  # deepSeq'd resolution state (the original rationale above) — but v1 binds the FULL merged host
  # config as the ctx entity (pin 11866c16 assemble-pipes.nix:154), so corpus policy/channel bodies
  # READ these fields (`host.microvm.guests`, microvm-guests.nix:38-59 — the u19 frontier: the U9.2
  # cross-host gather forces sibling emissions, v1-faithfully). They therefore ride a SEPARATE
  # side channel (`_entityRawStamps`, bridge.nix — the instantiateFor/hmModuleFor compile-side
  # side-map grain, generalized) and are overlaid LAZILY onto the ctx entity at ingest
  # (`entityFields`): one un-forced thunk per field (`stampOf`'s read is already per-field lazy),
  # forced ONLY when a body reads the field — never by the resolution spine.
  rawStampTreeOf = mkStampTree (v: excludedType (v.type or { }));

  # The stamped ctx-entity record for ONE registry entry: the entry's MERGED config values at the
  # inclusion tree's leaves, read LAZILY (one thunk per field — nothing is forced here, and the
  # excluded values are never touched). `or null` / `or { }` guard a tree/value mismatch soft (a
  # stamp read may miss, never throw — the fallback posture of the deleted census).
  stampOf =
    tree: cfg:
    builtins.mapAttrs (n: v: if v == true then cfg.${n} or null else stampOf v (cfg.${n} or { })) tree;

  # ── the OPTION-REFLECTING kind MARKER (the robust twin of ingest's value-reflecting id_hash
  # discovery) ─────────────────────────────────────────────────────────────────────────────────────
  # A consumer chooses a custom kind's registry KEY (`options.den.<key> = mkInstanceRegistry
  # den.schema.<kind>`), so the shim must map that key back to its kind. ingest's `identityHashFor`
  # marker reflects the INSTANCE VALUE's primitive fields — but a kind carrying a DERIVED/INTERNAL
  # primitive (the corpus `cluster.sopsAgeRecipient`: a `readFile` string, `internal`, `nullOr str`)
  # makes the value-reflection OVER-include it (a string value is primitive), so the recompute never
  # matches the carried id_hash and the namespace matches NO kind → its registry never reaches the
  # fleet (env/cluster root nodes absent → the staged env phase never runs). The DECLARED option
  # surface carries what the value cannot: `internal`/`identity` flags. `identityKeysOf` reflects the
  # SAME primitive-option set gen-schema's `mkIdentityModule` hashed when it stamped the carried
  # id_hash — a primitive-typed (str/int/bool), non-internal, `identity != false` option, minus the
  # `_`-internals and the `id_hash` identity field. Read FORCE-FREE (only `.type.name`/`.internal`/
  # `.identity` records). nixpkgs names primitives `str`/`int`/`bool`, gen-merge `string`/`int`/`bool`
  # — both accepted; the hash-equality gate in `registryKindOf` rejects any over/under-inclusion, so a
  # wrong set is a LOUD miss (null), never a misclassification.
  identityKeysOf =
    opts:
    builtins.filter (
      n:
      builtins.substring 0 1 n != "_"
      && n != "id_hash"
      && (opts.${n} ? type)
      && builtins.elem (opts.${n}.type.name or "") [
        "str"
        "string"
        "int"
        "bool"
      ]
      && !(opts.${n}.internal or false)
      && (opts.${n}.identity or true)
    ) (builtins.attrNames opts);

  # `registryKindOf { opts; instances; candidateKinds; hashIdentity; }` — the robust namespace→kind
  # marker. Reflect the namespace's identity keys off its DECLARED option surface (`opts`, the
  # consumer registry's own `type.getSubOptions` — the same surface `stampTreeOf` reads), recompute the
  # first instance's content-address for each candidate kind through gen-schema's OWN `hashIdentity`
  # (passed in — the SINGLE formula, no duplication), and match the carried `id_hash`. Returns the
  # matching kind NAME, or null when no candidate reproduces the hash (an empty namespace, or a marker
  # miss — the caller falls back to the value-reflecting discovery). `tryEval` guards a forcing throw
  # in a primitive value; the equality gate keeps a false match at sha256-collision odds.
  registryKindOf =
    {
      opts,
      instances,
      candidateKinds,
      hashIdentity,
    }:
    let
      entries = builtins.attrValues instances;
    in
    if entries == [ ] then
      null
    else
      let
        ikeys = identityKeysOf opts;
        first = builtins.head entries;
        carried = first.id_hash or null;
        hits = builtins.filter (
          k:
          carried != null
          && (builtins.tryEval (hashIdentity k ikeys (n: first.${n} or null) == carried)).value or false
        ) candidateKinds;
      in
      if hits == [ ] then null else builtins.head hits;

  # The host registry's declared option surface, probe-eval'd ONCE per fleet (no authored config;
  # only `.options` is walked — option defaults and config are never forced). Feeds `stampTreeOf`:
  # the shim OWNS this registry's declaration, so its option records come from the same modules that
  # stamp entries; a consumer-declared registry's twin is `type.getSubOptions`, read at the bridge.
  hostInstanceOptions =
    { lib, kindModule }:
    (lib.evalModules {
      modules = [
        (baseEntityModule lib null)
        kindModule
        { config._module.args.name = "«den-compat-probe»"; }
      ];
    }).options;

  # The applied two-level registry flattened by host NAME (each entry already carries `system` — the
  # group key materialized as its option default), the shape the per-host stamps and grains key by.
  # Names are unique across groups (the v1 assumption ingest.flattenHosts shares).
  flattenRegistry =
    applied: builtins.foldl' (acc: sys: acc // applied.${sys}) { } (builtins.attrNames applied);

  # `mkHostsOption { lib; kindModule; }` — v1's `hostsOption`, mirrored (the pin is the template;
  # see the header). `kindModule` is the M1.75 emitted kind-value (bridge.nix schema apply) — its
  # `__functor` is module-system-callable on BOTH seam paths (passThroughSeam returns the corpus's
  # raw `{ imports; options }`; the severed processed path is gen-schema's own option-declaring
  # module); `{ }` for a fleet with no host kind declaration (base-only registry — every schema
  # default null, the grains absent, byte-identical to the pre-registry bridge).
  mkHostsOption =
    { lib, kindModule }:
    let
      inherit (lib) types;
      # v1's deepMergeAttrs (pin _types.nix:29-34): recursive merge without forcing leaf values —
      # unlike `types.anything` it never inspects values deeply, so authored fn/entity references
      # ride the collector un-mangled (the top-level-fn-erasure hazard options.policies documents).
      deepMergeAttrs = lib.mkOptionType {
        name = "deepMergeAttrs";
        description = "recursively merged attribute set";
        check = builtins.isAttrs;
        merge = _loc: defs: builtins.foldl' (acc: def: lib.recursiveUpdate acc def.value) { } defs;
      };
      # v1's flat/two-level normalization (pin _types.nix:147-172): a top key ∈ flakeExposed is a
      # system GROUP; a flat host (`den.hosts.slab`) groups under its own `system` field — throwing
      # v1's message if absent — with the field removed (the group key re-derives it via the base
      # option default, v1's `removeAttrs cfg ["system"]` net-equality).
      reservedSystems = lib.genAttrs lib.systems.flakeExposed (_: true);
      preprocessHosts =
        raw:
        let
          systemGroups = lib.filterAttrs (k: _: reservedSystems ? ${k}) raw;
          directHosts = lib.filterAttrs (k: _: !(reservedSystems ? ${k})) raw;
          grouped = lib.foldlAttrs (
            acc: name: cfg:
            let
              system =
                cfg.system
                  or (throw "den: flat host '${name}' must specify 'system' (e.g. system = \"x86_64-linux\")");
            in
            acc
            // {
              ${system} = (acc.${system} or { }) // {
                ${name} = builtins.removeAttrs cfg [ "system" ];
              };
            }
          ) { } directHosts;
        in
        lib.recursiveUpdate systemGroups grouped;
      # v1 host.nix:46-57 — the strict inner registry: per-system submodule whose freeform attrs are
      # host INSTANCE submodules (base entity + the kind module; the group key rides in as `system`).
      hostType =
        system:
        types.submoduleWith {
          shorthandOnlyDefinesConfig = true;
          modules = [
            (baseEntityModule lib system)
            kindModule
          ];
        };
      systemType = types.submodule (
        { name, ... }:
        {
          freeformType = types.attrsOf (hostType name);
        }
      );
      innerType = types.attrsOf systemType;
    in
    lib.mkOption {
      description = "den hosts definition (v1 hostsOption parity, pin 11866c16 modules/options.nix:71 / entities/host.nix:26-44): per-module defs deep-merge, flat hosts normalize into their system group, and every host evaluates through the host kind's instance submodule — schema defaults materialize at the module system's native priorities.";
      default = { };
      type = types.attrsOf (types.submodule { freeformType = deepMergeAttrs; });
      apply =
        raw:
        innerType.merge
          [ "den" "hosts" ]
          [
            {
              file = "<den.hosts>";
              value = preprocessHosts raw;
            }
          ];
    };
in
{
  inherit
    baseEntityModule
    excludedType
    stampTreeOf
    rawStampTreeOf
    stampOf
    identityKeysOf
    registryKindOf
    hostInstanceOptions
    flattenRegistry
    mkHostsOption
    ;
}
