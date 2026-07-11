# The ingestion boundary (Law C6 / A2). This is the ONE place v1's name-keyed surface converts to
# den-hoag's entry-valued (id_hash-bearing) surface — exactly once, deterministically, so that every
# hand-off PAST this file carries entries, never `"kind:name"` strings (the boundary lint enforces the
# rest of the shim stays string-free). The conversions:
#
#   - `den.hosts.<sys>.<name>` (two-level) → a FLAT host registry, `system` demoted to a field (once).
#   - `den.homes.<sys>.<name>` and `host.users.<u>` → user registry entries + `member` tuples (users
#     first-class, §8). A standalone home `user@host` binds to the declared host or a SYNTHETIC host
#     identity parsed from its name (§2.5 nameMatches) — never instantiating a real host entity.
#   - `den.schema.<kind>` → the den-hoag containment DAG (`parent`) atop the built-in `host`/`user`.
#   - a class-name STRING → its class registration entry (`resolveClass`); an unknown name aborts named.
#
# Entries are stamped by gen-schema (`schema.evalModuleTree` + `mkInstanceRegistry`, the SAME code path
# `denHoag`'s own `entity.build` uses), so a shim entry and a den-hoag entry for the same (kind, name)
# share an id_hash by construction — that determinism is what lets the compiled declarations resolve
# against the fleet mkDen later builds. nixpkgs-lib-free: `schema.*` re-exports the merge surface.
{
  denHoag,
  prelude,
  schema,
  errors,
}:
let
  # den-hoag's identity conventions, reproduced so a shim reference matches the entry mkDen builds:
  #   aspect  id_hash = sha256("den-aspect:<key>"), key = the aspect name for a top-level aspect
  #           (gen-aspects `identity.key`); class id_hash = sha256("den-class:<name>").
  aspectEntry = name: {
    id_hash = builtins.hashString "sha256" "den-aspect:${name}";
    inherit name;
  };
  # Built-in class entries come straight from den-hoag (single source of truth, no drift); a v1-declared
  # class name gets an entry stamped by the SAME convention so both live in one registry.
  builtinClasses = denHoag.classes;
  classEntry =
    name:
    builtinClasses.${name} or {
      id_hash = builtins.hashString "sha256" "den-class:${name}";
      inherit name;
    };

  # `den.hosts.<sys>.<name>` → `{ <name> = <hostAttrs> // { system = <sys>; }; }`. Flat, once. A name
  # colliding across systems is a v1 authoring error surfaced by the later merge, not masked here.
  flattenHosts =
    hosts:
    prelude.foldl' (
      acc: sys: acc // builtins.mapAttrs (_: h: h // { system = sys; }) hosts.${sys}
    ) { } (builtins.attrNames hosts);

  # Split a home registry key `"user@host"` (or bare `"user"`) into its bound user + host names. The
  # host is null for an unbound standalone home. `builtins.split "@"` yields `[ user [] host ]`; keeping
  # the string parts drops the empty separator match.
  parseHomeName =
    name:
    let
      parts = builtins.filter builtins.isString (builtins.split "@" name);
    in
    {
      user = builtins.head parts;
      host = if builtins.length parts > 1 then builtins.elemAt parts 1 else null;
    };

  # All (user, host) BINDINGS from `den.homes.<name>` — one per original entry, so the SAME user on N
  # hosts (`bob@host1`, `bob@host2`) yields N bindings, hence N distinct membership cells (the NORMAL v1
  # case, not an edge). `host` is null for an unbound standalone home (bare `"user"`). The user REGISTRY
  # dedups these to one field-less entry per name; the MEMBERSHIP keeps every binding (`buildMembership`).
  homeBindings =
    homes:
    prelude.concatMap (
      sys:
      map (
        key:
        let
          parsed = parseHomeName key;
        in
        {
          user = parsed.user;
          host = homes.${sys}.${key}.hostName or parsed.host;
        }
      ) (builtins.attrNames homes.${sys})
    ) (builtins.attrNames homes);

  # All (user, host) bindings from `host.users.<u>` across every flat host — one binding per user-under-
  # host, so a user present on several hosts yields one cell per host (same NORMAL multi-host case).
  hostUserBindings =
    flatHosts:
    prelude.concatMap (
      hostName:
      map (u: {
        user = u;
        host = hostName;
      }) (builtins.attrNames (flatHosts.${hostName}.users or { }))
    ) (builtins.attrNames flatHosts);

  # Build the den-hoag containment schema from v1's declared kinds atop the built-ins. den v1 makes
  # `host` a root and `user` a cell under it implicitly; `den.schema.<kind> = { parent; }` declares
  # additional kinds (and MAY re-parent host, e.g. under an `env`). Each named parent must be a declared
  # kind. Kind-attached `includes` are lifted out here (they become fire-at-kind policies in `compile`).
  buildSchema =
    v1Schema:
    let
      declared = builtins.mapAttrs (_: k: { parent = k.parent or null; }) v1Schema;
      # Built-ins fill only what the v1 schema does not already pin.
      withBuiltins =
        (if declared ? host then { } else { host.parent = null; })
        // (if declared ? user then { } else { user.parent = "host"; })
        // declared;
      # v1's `host.class` (nixos/darwin) and `host.system` (the `den.hosts.<system>.<name>` path key that
      # `flattenHosts` demoted to a field) are STRUCTURAL entity FIELDS (den v1 host entities carry them),
      # NOT aspect content — so the host kind DECLARES them as instance fields (gen-schema kind `options`),
      # `raw` + default null (a synthetic `user@host` home, or a class-/system-less custom host, carries
      # none). The fields ride the entity into the policy ctx, so the built-in `os-to-host`/`user-to-host`
      # routes (R3/R6) gate on `ctx.host.class ∈ {nixos,darwin}`, and the home-platform routes gate on
      # `ctx.host.system` (`hasPrefix "aarch64-"` / `hasSuffix "-linux"`/`"-darwin"`), exactly as v1 does.
      # id_hash is name-derived (sha256 "host|name=<name>"), so adding fields does NOT perturb entity identity.
      withHostFields =
        withBuiltins
        // prelude.optionalAttrs (withBuiltins ? host) {
          host = withBuiltins.host // {
            options.class = schema.mkOption {
              type = schema.types.raw;
              default = null;
              description = "v1 host OS class (nixos/darwin) — the R3/R6 route gate reads it (compat).";
            };
            options.system = schema.mkOption {
              type = schema.types.raw;
              default = null;
              description = "v1 host platform system (the demoted `den.hosts.<system>` key) — the home-platform route gate reads it (compat).";
            };
          };
        };
      kinds = builtins.attrNames withHostFields;
      checkParent =
        kind:
        let
          p = withHostFields.${kind}.parent;
        in
        if p == null || builtins.elem p kinds then true else errors.unknownParentKind kind p;
      _checked = builtins.all checkParent kinds;
    in
    builtins.seq _checked withHostFields;

  # Kind-attached includes (`den.schema.<kind>.includes = [ <aspect> ]`) → `{ <kind> = [ <aspectName> ]; }`,
  # the raw material `compile` turns into fire-at-kind policies (an aspect radiated to every instance of
  # a kind). Empty for a schema without kind-includes.
  kindIncludesOf =
    v1Schema:
    prelude.filterAttrs (_: v: v != [ ]) (builtins.mapAttrs (_: k: k.includes or [ ]) v1Schema);

  # Build id_hash-bearing registries via gen-schema — the SAME evalModuleTree shape `entity.build`
  # uses, so identity is byte-identical to what mkDen stamps. Instances are stamped MINIMAL (`{ }`, so
  # id_hash reflects only `name`); the caller keeps the full v1 attrs separately (`instances`) for mkDen
  # to rebuild class-carrying entries. Self-referential `tree` (options read `tree.config.den.schema`)
  # is the documented gen-schema pattern (laziness ties the knot).
  buildRegistries =
    { schemaDecls, instanceNames }:
    let
      kinds = builtins.attrNames schemaDecls;
      tree = schema.evalModuleTree {
        modules = [
          { options.den.schema = schema.mkSchemaOption { }; }
          { config.den.schema = schemaDecls; }
        ]
        ++ map (kindName: {
          options.den.${kindName} = schema.mkInstanceRegistry tree.config.den.schema.${kindName} { };
        }) kinds
        ++ [
          {
            config.den = prelude.genAttrs kinds (
              kindName: prelude.genAttrs (instanceNames.${kindName} or [ ]) (_: { })
            );
          }
        ];
      };
    in
    prelude.genAttrs kinds (kindName: tree.config.den.${kindName});

  # Membership tuples: one cell `{ host = <hostEntry>; user = <userEntry>; }` per (user, host) BINDING.
  # host binds to its declared registry entry, else a synthetic `{ name; }` (a NAME-MATCH target §2.5,
  # not a scope node — carries no id_hash). A null-host binding (unbound standalone home) yields a user
  # entry but no cell. Deduped by the (user, host) name pair — membership is a RELATION, so a user
  # reachable via BOTH a standalone home and a `host.users` entry on the SAME host collapses to one cell
  # (distinct hosts stay distinct cells). The null-host sentinel `""` cannot collide with a real host
  # name (hostnames are non-empty); the key uses `@` (never `:`), so it is not a scope-string.
  buildMembership =
    {
      bindings,
      hostRegistry,
      userRegistry,
    }:
    let
      deduped = builtins.attrValues (
        prelude.foldl' (
          acc: b: acc // { "${b.user}@${if b.host == null then "" else b.host}" = b; }
        ) { } bindings
      );
    in
    prelude.concatMap (
      b:
      let
        userEntry = userRegistry.${b.user};
        hostEntry =
          if b.host == null then
            null
          else if hostRegistry ? ${b.host} then
            hostRegistry.${b.host}
          else
            { name = b.host; };
      in
      if hostEntry == null then
        [ ]
      else
        [
          {
            coords = {
              host = hostEntry;
              user = userEntry;
            };
          }
        ]
    ) deduped;

  # `resolveClass classRegistry policy name` — a class-name STRING → its registration entry; the string
  # does NOT survive (C6). An unknown name aborts named (the deliver-adjacent §2.3 error, reused for the
  # class row here). Curried so `compile` hands `deliver` (Task 2) a registry-closed resolver.
  resolveClass =
    classRegistry: policy: name:
    classRegistry.${name} or (errors.unknownClass policy name);

  # The top-level boundary: v1Decls → the entry-valued ingestion record every later pass reads. Nothing
  # here evaluates a parametric body, reads a scope graph, or reads resolved state (Law C2).
  ingest =
    v1Decls:
    let
      v1Schema = v1Decls.schema or { };
      schemaDecls = buildSchema v1Schema;

      flatHosts = flattenHosts (v1Decls.hosts or { });
      # Every (user, host) binding from standalone homes AND host-embedded users — the cell granularity.
      bindings = homeBindings (v1Decls.homes or { }) ++ hostUserBindings flatHosts;
      # ONE field-less user entry per DISTINCT user name. den-hoag entities carry no content (it comes
      # from aspects), so merging a user's N per-host homes is trivial: ingestion reads only the user
      # NAME (here) and the host BINDING (kept per-cell in `membership`), never a per-host user field —
      # so there is nothing to conflict on and no per-host config is silently dropped. (If ingestion ever
      # grew to read a per-host user field, differing values would need a named abort added right here.)
      userNames = prelude.unique (map (b: b.user) bindings);

      # ── custom-kind instance-key DISCOVERY (M1.5) ─────────────────────────────────────────────────
      # A v1 config CHOOSES a custom kind's instance-registry KEY: `options.den.<KEY> =
      # gen-schema.mkInstanceRegistry den.schema.<kind>` (nix-config schema/cluster.nix). The key is
      # arbitrary — nix-config writes `clusters` for kind `cluster` — NEVER a pluralization heuristic.
      # A gen-schema instance exposes no `.kind`, but its `id_hash` IS a content-addressed kind marker. We
      # recompute it per candidate kind via GEN-SCHEMA'S OWN exported derivation (`schema.identityHashFor`,
      # NOT an inline formula copy — so the recompute can never drift from `mkIdentityModule`) and match the
      # instance's observed `id_hash` — discovery by MARKER, never by name (a kind `rack` at `den.rackFarm`
      # resolves). VERSION-SKEW PROPERTY: the corpus's values were hashed by the CORPUS's gen-schema; the
      # shim recomputes with ITS gen-schema. If the two derivations ever diverged, EVERY instance would
      # mismatch → the namespace matches NO kind → surface-totality aborts NAMED (a loud MISS, R9 — never a
      # misclassification; a wrong-kind false match needs a sha256 collision across different preimages). OUR
      # gen-schema's derivation is pinned by the `compat-custom-kind` formula canary; every corpus probe
      # re-proves the two pins agree. COST: O(kinds × candidate namespaces × 1 probe instance) — trivial at
      # corpus scale (~7 × ~10).
      #
      # INSTANCE-BASED (`identityHashFor`, reflecting the INSTANCE's present fields) is PERMANENT here, not an
      # interim — the option-level twin `identityHashForKind` (reflecting a kind-value's OPTIONS) CANNOT be
      # used: the shim's kind-values are deliberately OPTION-LESS (`buildSchema` keeps only `parent`; den-hoag
      # entities are field-less), so option-level would hash `name` alone and never match an instance whose
      # id_hash carries its other identity fields. The `identity = false` edge (an instance carrying a field
      # the kind excludes from identity) is a NON-match, and a non-match is covered by the loud-miss property
      # above — a named R9 abort, never a silent misclassification. So the instance-approximate hash is exact
      # ENOUGH here by construction; `identityHashForKind` stays a general gen-schema export for consumers that
      # DO hold option-bearing kind-values.
      instanceMatchesKind =
        kind: inst: (inst.id_hash or null) != null && schema.identityHashFor kind inst == inst.id_hash;
      # A namespace is an instance registry iff it is a non-empty attrset of id_hash-bearing entries.
      isInstanceRegistry =
        v:
        builtins.isAttrs v
        && v != { }
        && builtins.all (e: builtins.isAttrs e && e ? id_hash) (builtins.attrValues v);
      # Candidate registry namespaces: `den.*` keys outside the fixed concern surface holding an instance
      # registry (`_`-prefixed keys are den-internal, never a user surface).
      concernKeys = [
        "hosts"
        "homes"
        "schema"
        "aspects"
        "policies"
        "classes"
        "include"
        "quirks"
        "contentClass"
        "default"
      ];
      candidateRegistryKeys = builtins.filter (
        k:
        (builtins.substring 0 1 k != "_")
        && !(builtins.elem k concernKeys)
        && isInstanceRegistry (v1Decls.${k} or null)
      ) (builtins.attrNames v1Decls);

      customKinds = builtins.filter (k: k != "host" && k != "user") (builtins.attrNames schemaDecls);
      # kind → the registry namespace whose instances match it by the id_hash marker. A kind with no
      # matching namespace falls back to its own name (`den.<kind>`, the pre-M1.5 singular convention) so an
      # inline fixture keyed by the kind name still resolves.
      discoverKeyFor =
        kind:
        let
          hits = builtins.filter (
            n: instanceMatchesKind kind (builtins.head (builtins.attrValues v1Decls.${n}))
          ) candidateRegistryKeys;
        in
        if hits == [ ] then kind else builtins.head hits;
      instanceKeyMap = prelude.genAttrs customKinds discoverKeyFor;
      customInstances = prelude.genAttrs customKinds (k: v1Decls.${instanceKeyMap.${k}} or { });
      # The discovered registry keys — LEGITIMATE custom-kind instance namespaces (not typos), read by
      # compile's surface-totality so a marker-discovered key classifies without widening the strict gate.
      discoveredRegistryKeys = prelude.unique (builtins.attrValues instanceKeyMap);

      instances = {
        host = flatHosts;
        user = prelude.genAttrs userNames (_: { });
      }
      // customInstances;

      instanceNames = builtins.mapAttrs (_: insts: builtins.attrNames insts) instances;
      registries = buildRegistries { inherit schemaDecls instanceNames; };

      membership = buildMembership {
        inherit bindings;
        hostRegistry = registries.host or { };
        userRegistry = registries.user or { };
      };

      # contentClass (§2.5): a host produces its own class (v1 `host.class`, `nixos`/`darwin`), a user
      # produces `home-manager`. den-hoag entities are field-less (content comes from aspects), so the
      # per-host class rides a compile-time `id_hash → class` map rather than a field on the strict
      # entry — den-hoag's `entity.classOf` calls the function with the host entry, and it reads only
      # `host.id_hash` (always present). Custom kinds are class-neutral unless declared.
      # v1 DERIVES a classless host's class FROM its system (nix/lib/entities/host.nix:65-66):
      #   `class = host.class or (if lib.hasSuffix "darwin" system then "darwin" else "nixos")`.
      # The shim reproduces it EXACTLY so a system-declared classless host classifies as v1 does — the
      # corpus `patch` (aarch64-darwin, no `class` field) → "darwin", every linux host → "nixos", and an
      # explicit `host.class` (corpus `slab` = "droid") overrides. [Ledger p: this SUPERSEDES the review's
      # null-default adjudication — v1 is NOT inert on classless hosts, it DERIVES; verified on the v1 arm
      # (`igloo` → nixos, `patch` → darwin). A null default would misroute darwin hosts.]
      hasDarwinSuffix =
        s:
        let
          n = builtins.stringLength s;
        in
        n >= 6 && builtins.substring (n - 6) 6 s == "darwin";
      classOfHost = h: h.class or (if hasDarwinSuffix (h.system or "") then "darwin" else "nixos");
      classByHostId = builtins.listToAttrs (
        map (name: {
          name = registries.host.${name}.id_hash;
          value = classOfHost flatHosts.${name};
        }) (builtins.attrNames flatHosts)
      );
      # The host mapping is the per-host FUNCTION form: den-hoag's `entity.classOf` calls it with the
      # host entry and uses the result DIRECTLY (it re-resolves only a bare STRING contentClass, not a
      # function's return), so this returns a class ENTRY, not a name. The user mapping is a plain string
      # (den-hoag resolves it to the built-in `home-manager` entry). An unknown host class name (a v1
      # `host.class` with no registration) synthesises an entry rather than aborting the output fold.
      contentClass = {
        host =
          host:
          let
            cls = classByHostId.${host.id_hash} or "nixos";
          in
          classRegistry.${cls} or (classEntry cls);
        user = "home-manager";
      };

      # systemFor (§2.5 carry-in): v1's per-host `system` (the `den.hosts.<system>.<name>` path key,
      # demoted to a field by `flattenHosts`) keyed by host id_hash. den-hoag entities are field-less,
      # so — like contentClass — the platform rides a compile-time `id_hash → system` map, read by the
      # compat nixos instantiate wrapper (flake-module.nix) to inject `nixpkgs.hostPlatform.system` per
      # host. Absent (a system-less custom kind) → null, and the wrapper injects nothing.
      systemByHostId = builtins.listToAttrs (
        map (name: {
          name = registries.host.${name}.id_hash;
          value = flatHosts.${name}.system or null;
        }) (builtins.attrNames flatHosts)
      );
      systemFor = host: systemByHostId.${host.id_hash} or null;

      # instantiateFor (ship-gate M2, the per-entity instantiation grain, D7): v1's per-host
      # `host.instantiate` (nix-config schema/host.nix — `resolvedChannel.nixosSystem`, a
      # `{ modules; specialArgs; } -> system` EVALUATOR embedding that host's channel nixpkgs) keyed by
      # host id_hash. The `hosts` sub-option is `raw` (flake-module.nix), so this function rides through
      # `flatHosts` untouched. Like systemFor, it is a nixpkgs-BOUND function, so it stays a compile-time
      # `id_hash -> evaluator` map — NEVER a field on the strict, field-less den-hoag entity (the C1
      # type-crossing dodge) — and is forced only at the terminal (the compat nixos wrapper crosses via it
      # per host). Absent (the fleet declares no per-host instantiate) -> null, and the wrapper falls to the
      # class-level terminal (the global `den.nixpkgs` grain, or the pure nixpkgs-free `collect`).
      instantiateByHostId = builtins.listToAttrs (
        map (name: {
          name = registries.host.${name}.id_hash;
          value = flatHosts.${name}.instantiate or null;
        }) (builtins.attrNames flatHosts)
      );
      instantiateFor = host: instantiateByHostId.${host.id_hash} or null;

      # Per-host OS class NAME keyed by host name — the value mkFleetModule stamps onto the den-hoag host
      # entity's declared `class` field (§ os-class R3 gate). Derived from `host.class` else the system
      # (`classOfHost`, matching v1's `host.nix` default) so the os-to-host route gates exactly as v1's
      # `host ? class` does — a classless host is NOT inert (v1 derives), so the shim derives too.
      hostClassName = builtins.mapAttrs (_: classOfHost) flatHosts;

      # Per-host platform SYSTEM keyed by host name — the value mkFleetModule stamps onto the den-hoag host
      # entity's declared `system` field, so the home-platform route gates read `ctx.host.system` exactly as
      # v1 does (v1 binds the full host config as the ctx entity — pin 11866c16
      # nix/lib/aspects/fx/assemble-pipes.nix:154 — so `host.system` is present there). The value is v1's
      # `den.hosts.<system>.<name>` path key demoted to a field by `flattenHosts`; absent (a synthetic or
      # system-less host) → null, so the route's `hasPrefix`/`hasSuffix` test is false, matching v1's default.
      hostSystemName = builtins.mapAttrs (_: h: h.system or null) flatHosts;

      # The class registry `resolveClass` closes over: den-hoag's built-ins ∪ every v1-declared class.
      declaredClassNames = builtins.attrNames (v1Decls.classes or { });
      classRegistry = builtinClasses // prelude.genAttrs declaredClassNames classEntry;

      # A delivery names a FOLD BUCKET — in den-hoag that is a quirk channel (the fold operates on
      # `received-collections`), so `resolveBucket` (used by `deliver`/`route`/`provide`) resolves
      # against classes ∪ quirk channels: a channel name → a `{ id_hash; name }` channel entry (the name
      # is the gen-edge collected `class`), a class name → its registration (a class-content delivery,
      # whose fold bucket is empty until class content joins the fold, §9). A class shadows a channel of
      # the same name (`// classRegistry` last). Unknown → the C6 named abort. `resolveClass` stays
      # class-only for `contentClass`/kind selection.
      channelNames = builtins.attrNames (v1Decls.quirks or { });
      channelEntry = name: {
        id_hash = builtins.hashString "sha256" "den-channel:${name}";
        inherit name;
      };
      bucketRegistry = prelude.genAttrs channelNames channelEntry // classRegistry;
    in
    {
      schema = schemaDecls;
      inherit
        registries
        instances
        membership
        contentClass
        systemFor
        instantiateFor
        hostClassName
        hostSystemName
        classRegistry
        ;
      kindIncludes = kindIncludesOf v1Schema;
      resolveClass = resolveClass classRegistry;
      resolveBucket = resolveClass bucketRegistry;
      inherit aspectEntry classEntry;
      # M1.5 custom-kind discovery: kind → its marker-discovered registry key, and the discovered key set
      # (compile's surface-totality classifies these as legitimate custom-kind namespaces).
      inherit instanceKeyMap discoveredRegistryKeys;
    };
in
{
  inherit
    flattenHosts
    homeBindings
    hostUserBindings
    buildSchema
    buildRegistries
    buildMembership
    resolveClass
    aspectEntry
    classEntry
    ingest
    ;
}
