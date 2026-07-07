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

  # `den.homes.<sys>.<name>` → user instances (keyed by the bare user name) + `member` tuples binding
  # each to its host (a declared host entry when present, else a synthetic `{ host = <name>; }` identity
  # so host-keyed policies still resolve). Symmetric to `flattenHosts`; the membership half is deferred
  # to `buildMembership` (it needs the built entries, which need the flattened instances first).
  homesToUsers =
    homes:
    prelude.foldl' (
      acc: sys:
      acc
      // builtins.mapAttrs (
        n: h:
        let
          parsed = parseHomeName n;
        in
        h
        // {
          system = sys;
          userName = parsed.user;
          hostName = h.hostName or parsed.host;
        }
      ) (renameByUser homes.${sys})
    ) { } (builtins.attrNames homes);

  # Re-key a system's homes from the registry key ("user@host") to the bare user name, preserving the
  # original key under `__homeKey` for host parsing / membership.
  renameByUser =
    systemHomes:
    prelude.foldl' (
      acc: key:
      let
        parsed = parseHomeName key;
      in
      acc
      // {
        ${parsed.user} = systemHomes.${key} // {
          __homeKey = key;
        };
      }
    ) { } (builtins.attrNames systemHomes);

  # `host.users.<u>` across every flat host → user instances (keyed by user name) tagged with the host
  # they sit under (`__hostName`), so `buildMembership` can bind the cell.
  hostUsers =
    flatHosts:
    prelude.foldl' (
      acc: hostName:
      let
        us = flatHosts.${hostName}.users or { };
      in
      acc // builtins.mapAttrs (u: uAttrs: uAttrs // { __hostName = hostName; }) us
    ) { } (builtins.attrNames flatHosts);

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
      kinds = builtins.attrNames withBuiltins;
      checkParent =
        kind:
        let
          p = withBuiltins.${kind}.parent;
        in
        if p == null || builtins.elem p kinds then true else errors.unknownParentKind kind p;
      _checked = builtins.all checkParent kinds;
    in
    builtins.seq _checked withBuiltins;

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

  # Membership tuples from the user instances: a cell `{ host = <hostEntry>; user = <userEntry>; }` per
  # user, host bound to its declared registry entry when present, else a synthetic `{ name; }` identity
  # (which carries no id_hash — a synthetic host is a NAME MATCH target, §2.5, not a scope node). Users
  # with no resolvable host (unbound standalone home) contribute a user entry but no cell.
  buildMembership =
    {
      userInstances,
      hostRegistry,
      userRegistry,
    }:
    prelude.concatMap (
      userName:
      let
        u = userInstances.${userName};
        hostName = u.__hostName or u.hostName or null;
        userEntry = userRegistry.${userName};
        hostEntry =
          if hostName == null then
            null
          else if hostRegistry ? ${hostName} then
            hostRegistry.${hostName}
          else
            { name = hostName; };
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
    ) (builtins.attrNames userInstances);

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
      standaloneUsers = homesToUsers (v1Decls.homes or { });
      cellUsers = hostUsers flatHosts;
      # host.users and standalone homes both land in the user registry; a declared host user wins a
      # same-name standalone home (it carries the real cell binding).
      userInstances = standaloneUsers // cellUsers;

      # Custom (non-host/user) kinds carry their own v1 instances verbatim.
      customKinds = builtins.filter (k: k != "host" && k != "user") (builtins.attrNames schemaDecls);
      customInstances = prelude.genAttrs customKinds (k: v1Decls.${k} or { });

      instances = {
        host = flatHosts;
        user = userInstances;
      }
      // customInstances;

      instanceNames = builtins.mapAttrs (_: insts: builtins.attrNames insts) instances;
      registries = buildRegistries { inherit schemaDecls instanceNames; };

      membership = buildMembership {
        inherit userInstances;
        hostRegistry = registries.host or { };
        userRegistry = registries.user or { };
      };

      # contentClass (§2.5): a host produces its own class (v1 `host.class`, `nixos`/`darwin`), a user
      # produces `home-manager`. den-hoag entities are field-less (content comes from aspects), so the
      # per-host class rides a compile-time `id_hash → class` map rather than a field on the strict
      # entry — den-hoag's `entity.classOf` calls the function with the host entry, and it reads only
      # `host.id_hash` (always present). Custom kinds are class-neutral unless declared.
      classByHostId = builtins.listToAttrs (
        map (name: {
          name = registries.host.${name}.id_hash;
          value = flatHosts.${name}.class or "nixos";
        }) (builtins.attrNames flatHosts)
      );
      contentClass = {
        host = host: classByHostId.${host.id_hash} or "nixos";
        user = "home-manager";
      };

      # The class registry `resolveClass` closes over: den-hoag's built-ins ∪ every v1-declared class.
      declaredClassNames = builtins.attrNames (v1Decls.classes or { });
      classRegistry = builtinClasses // prelude.genAttrs declaredClassNames classEntry;
    in
    {
      schema = schemaDecls;
      inherit
        registries
        instances
        membership
        contentClass
        classRegistry
        ;
      kindIncludes = kindIncludesOf v1Schema;
      resolveClass = resolveClass classRegistry;
      inherit aspectEntry classEntry;
    };
in
{
  inherit
    flattenHosts
    homesToUsers
    buildSchema
    buildRegistries
    resolveClass
    aspectEntry
    classEntry
    ingest
    ;
}
