# The ingestion boundary (Law C6 / A2). This is the ONE place v1's name-keyed surface converts to
# den-hoag's entry-valued (id_hash-bearing) surface — exactly once, deterministically, so that every
# hand-off PAST this file carries entries, never `"kind:name"` strings (the boundary lint enforces the
# rest of the shim stays string-free). The conversions:
#
#   - `den.hosts.<sys>.<name>` (two-level) AND `den.hosts.<name>` (flat, grouped by its own `system`
#     field — v1 `preprocessHosts`) → a FLAT host registry, `system` demoted to a field (once).
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
  # den-hoag's identity conventions: the shim routes a reference through den-hoag's OWN preimage helpers
  # (denHoag.aspectIdHash/classIdHash, lib/identity-preimage.nix) so a shim entry's id_hash is the SAME
  # value mkDen builds — not a reproduced formula but the kernel authority itself (Law C6 by construction):
  #   aspect  id_hash = denHoag.aspectIdHash <key>, key = the aspect name for a top-level aspect
  #           (gen-aspects `identity.key`); class id_hash = denHoag.classIdHash <name>.
  aspectEntry = name: {
    id_hash = denHoag.aspectIdHash name;
    inherit name;
  };
  # Built-in class entries come straight from den-hoag (single source of truth, no drift); a v1-declared
  # class name gets an entry stamped by the SAME authority fn so both live in one registry.
  builtinClasses = denHoag.classes;
  classEntry =
    name:
    builtinClasses.${name} or {
      id_hash = denHoag.classIdHash name;
      inherit name;
    };

  # ── the ctx-entity REGISTRY STAMPS (the bridge-registry passthrough; the board-#59 hand census is
  # DELETED) ───────────────────────────────────────────────────────────────────────────────────────
  # v1 binds the RESOLVED entity config as the ctx entity (pin 11866c16 nix/lib/aspects/fx/
  # assemble-pipes.nix:154), so corpus aspect bodies read entity fields off `host`/`cluster`/… BOTH
  # at dispatch (policy predicates — pipes.nix:147,157,166 `host.settings…isHub or false`, ledger u6)
  # and at the MODULE FIXPOINT (delivery depth — xfs-disk-longhorn.nix:19 `host.settings.disk…`).
  # den-hoag entities are field-less; the shim stamps EVERY kind's entities from the BRIDGE-EVAL'D
  # REGISTRY entries (`den._entityStamps`, bridge.nix): the fleet's registries — `den.hosts` via the
  # shim-declared v1 hostsOption parity option (registry.nix; pin modules/options.nix:71), the custom
  # kinds via the corpus's OWN `mkInstanceRegistry` declarations — already materialize the full
  # merged view (options + defaults + methods + derive) at the module system's NATIVE priorities
  # (authored 100 < mkDefault 1000 < base default 1500), so the stamp is a PASSTHROUGH minus the
  # STRUCTURAL EXCLUSION RULE (registry.nix `stampTreeOf`: `raw`/`deferredModule`/`anything`-class
  # option types — `instantiate`/`home-manager.module`, microvm.guests — never enter deepSeq'd
  # resolution state; method lambdas and data ride, normal forms). KIND-GENERIC: zero kind names,
  # zero field names — no census list (`host.facts` rides because its declared type is data, not
  # because it is listed). No bridge ⇒ no stamps: an mkDen-direct fleet's entities carry
  # class/system/hostName alone (the raw-authored census fallback died with the census; a direct
  # fixture that needs field-bearing entities supplies `_entityStamps` as the bridge would).
  #
  # DUAL-SERVE (unchanged law): both read surfaces are the SAME entity entry, so one stamp closes
  # both — the dispatch ctx (enriched-context) and the delivery binding (bindingsAt → the
  # class-module `host` arg).

  # v1's `den.hosts` accepts TWO addressings, normalized by `preprocessHosts` (pin 11866c16
  # nix/lib/entities/host.nix:31-43 `hostsOption.apply` → nix/lib/entities/_types.nix:152-172) BEFORE
  # the `attrsOf systemType` merge — the shim reproduces that same normalization here, fused with the
  # `system`-demotion, so every host lands FLAT with `system` a field (once):
  #   - `den.hosts.<sys>.<name>` — top key ∈ flakeExposed is a SYSTEM GROUP (two-level). Its host attrs
  #     carry no `system` field, so `// { system = <sys>; }` demotes the path key to a field.
  #   - `den.hosts.<name>` — top key ∉ flakeExposed is a FLAT host (one-level, v1 `directHosts`). v1
  #     GROUPS it by its own `system` field (_types.nix:157-170), throwing if absent; the corpus
  #     `slab`/`patch` (hosts/slab.nix:3, hosts/patch.nix:3) declare it (aarch64-linux/aarch64-darwin).
  #     The flat attrs ALREADY carry `system`, so the entry rides through as-is (v1's `removeAttrs cfg
  #     ["system"]` then re-derives the identical value from the group key — net-equal to keeping it).
  # The `system ∈ flakeExposed` test IS v1's (`reservedSystems = genAttrs lib.systems.flakeExposed`,
  # _types.nix:147); reproduced literally here since the shim is nixpkgs-lib-free (frozen at the pin).
  # A name colliding across the two addressings is a v1 authoring error — v1's `recursiveUpdate
  # systemGroups grouped` (_types.nix:172) lets the flat/grouped side win, matched here by `//` order.
  flakeExposedSystems = prelude.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "armv6l-linux"
    "armv7l-linux"
    "i686-linux"
    "x86_64-darwin"
    "aarch64-darwin"
    "powerpc64le-linux"
    "riscv64-linux"
    "x86_64-freebsd"
  ] (_: true);
  flattenHosts =
    hosts:
    let
      keys = builtins.attrNames hosts;
      systemKeys = builtins.filter (k: flakeExposedSystems ? ${k}) keys;
      flatKeys = builtins.filter (k: !(flakeExposedSystems ? ${k})) keys;
      fromGroups = prelude.foldl' (
        acc: sys: acc // builtins.mapAttrs (_: h: h // { system = sys; }) hosts.${sys}
      ) { } systemKeys;
      fromFlat = prelude.foldl' (
        acc: name:
        acc
        // {
          ${name} = if hosts.${name} ? system then hosts.${name} else errors.flatHostNoSystem name;
        }
      ) { } flatKeys;
    in
    fromGroups // fromFlat;

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
            options = {
              class = schema.mkOption {
                type = schema.types.raw;
                default = null;
                description = "v1 host OS class (nixos/darwin) — the R3/R6 route gate reads it (compat).";
              };
              system = schema.mkOption {
                type = schema.types.raw;
                default = null;
                description = "v1 host platform system (the demoted `den.hosts.<system>` key) — the home-platform route gate reads it (compat).";
              };
              hostName = schema.mkOption {
                type = schema.types.raw;
                default = null;
                description = "v1 host network hostName (base default `config.name`, pin 11866c16 entities/host.nix:63) — the hostname battery reads it (compat).";
              };
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
      # §8 ISOLATION CEILING GUARD (LOUD, #63 review note): v1 declares an `isolated` collection flag on
      # every schema kind (pin 11866c16 modules/options.nix:85-88, default false — NOTHING sets it at the
      # pin or in the corpus; the one v1 reader is the scope walk's boundary stamp, handlers/
      # push-scope.nix:64). den-hoag's #63 within-class subtree fold (`classSubtreeAt`) and the #62c
      # delivery-edge subtree members are BLIND `scope.descendants` walks — an isolated kind would need
      # them to STOP at the boundary v1's isolation-aware fold honors, else a descendant's class content
      # silently over-gathers into the ancestor's assembly (a WRONG drv, not a crash — the worst failure
      # mode). Until an isolation-aware walk lands, refuse LOUD at ingestion. Read off the RAW v1 schema
      # (`v1Schema`, not `withHostFields` — buildSchema keeps only `parent`, so the flag is only visible
      # here).
      checkIsolated =
        kind: if v1Schema.${kind}.isolated or false then errors.isolatedKindUnsupported kind else true;
      _isolatedChecked = builtins.all checkIsolated (builtins.attrNames v1Schema);
    in
    builtins.seq _checked (builtins.seq _isolatedChecked withHostFields);

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
      # #73 — the per-binding user FIELD source (`hostName: userName: fields`): a host-backed cell's
      # `user` coord carries the #71 instance-evaled user value (classes/userName/… — read off the host
      # entity's #70 raw stamp), so a cell-fired body's `user.classes` read (home-env userDetectFn,
      # home-env.nix:203 — the corpus droidHm-user-detect at patch/slab's cells) resolves exactly as
      # v1's resolved user ctx does. Identity stays the registry's (the entry overlays LAST). Default =
      # field-less (the mkDen-direct ceiling, ledger u18 — unchanged).
      userFieldsFor ? (_host: _user: { }),
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
              # fields first, registry identity last (id_hash/name authoritative — A2).
              user = userFieldsFor b.host b.user // userEntry;
            };
          }
        ]
    ) deduped;

  # A namespace is an instance registry iff it is a non-empty attrset of id_hash-bearing entries —
  # the M1.5 discovery test, SHARED with the bridge's `_entityStamps` namespace scan (one definition:
  # the two sides must classify identically, or a stamped namespace could miss its kind).
  isInstanceRegistry =
    v:
    builtins.isAttrs v
    && v != { }
    && builtins.all (e: builtins.isAttrs e && e ? id_hash) (builtins.attrValues v);

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
      # ── the bridge-eval'd ctx-entity REGISTRY STAMPS (`den._entityStamps`, bridge.nix) ────────────
      # Keyed by REGISTRY NAMESPACE (`hosts` for the shim-declared built-in host registry; a custom
      # kind's marker-discovered instance key — `cluster` → `clusters`). Absent on mkDen-direct paths
      # (no bridge ⇒ no stamps). Re-keyed by KIND here, the boundary that owns the namespace→kind map.
      entityStamps = v1Decls._entityStamps or { };
      stampsByKind = {
        host = entityStamps.hosts or { };
      }
      // prelude.genAttrs customKinds (k: entityStamps.${instanceKeyMap.${k}} or { });
      # ── #70: the RAW-FIELD side channel (`den._entityRawStamps`, bridge.nix) — the stamp-EXCLUDED
      # fields (raw/deferredModule/anything-class — instantiate, home-manager.module, microvm.guests),
      # carried LAZILY onto the ctx entity. The structural exclusion's reason STANDS (those values must
      # never enter deepSeq'd resolution state — registry.nix), and the safe stamp is UNCHANGED; but v1
      # binds the FULL merged host config as the ctx entity (pin assemble-pipes.nix:154), so corpus
      # policy/channel bodies READ these fields (`host.microvm.guests`, microvm-guests.nix:38-59 — the
      # u19 frontier: the U9.2 cross-host gather forces sibling emissions, v1-faithfully). The overlay
      # is one un-forced thunk per field (stampOf's per-field lazy read, bridge-side), forced ONLY when
      # a body reads the field — the resolution spine never walks it. ──────────────────────────────────
      rawEntityStamps = v1Decls._entityRawStamps or { };
      rawStampsByKind = {
        host = rawEntityStamps.hosts or { };
      }
      // prelude.genAttrs customKinds (k: rawEntityStamps.${instanceKeyMap.${k}} or { });
      # Lazy deep-union of a safe stamp with its raw twin. The two trees' LEAF sets are disjoint by
      # construction (a field is an option in exactly one tree — registry.nix mkStampTree), so only
      # GROUPS collide (the corpus `microvm`: safe passthrough/sharedNixStore + raw guests) — the
      # `a ? k` branch therefore only ever recurses group-into-group (cheap WHNF attrsets built over
      # the static trees), never forcing a leaf thunk (a raw leaf under a fresh key is taken AS-IS,
      # short-circuited before any isAttrs force).
      deepUnionStamps =
        a: b:
        a
        // builtins.mapAttrs (
          k: v: if a ? ${k} && builtins.isAttrs v then deepUnionStamps a.${k} v else v
        ) b;
      withRawStamp =
        kind: name: base:
        deepUnionStamps base ((rawStampsByKind.${kind} or { }).${name} or { });
      # The per-kind stamped FIELD-NAME set (uniform across a kind's entities — the bridge stamps every
      # entity from ONE inclusion tree; union for safety): declared as raw+null kind options below so
      # the instanceConfig stamp (flake-module.nix) is legal on the strict den-hoag kind. Same raw+null
      # shape as the structural class/system/hostName options, so entity identity stays name-derived
      # (unperturbed — the established precedent).
      stampFieldNamesByKind = builtins.mapAttrs (
        kind: stamps:
        prelude.unique (
          prelude.concatMap builtins.attrNames (
            builtins.attrValues stamps ++ builtins.attrValues (rawStampsByKind.${kind} or { })
          )
        )
      ) stampsByKind;
      schemaDecls = builtins.mapAttrs (
        kind: decl:
        let
          fields = stampFieldNamesByKind.${kind} or [ ];
        in
        if fields == [ ] then
          decl
        else
          decl
          // {
            options =
              prelude.genAttrs fields (
                f:
                schema.mkOption {
                  type = schema.types.raw;
                  default = null;
                  description = "v1 ${kind} config field `${f}` — registry-stamped onto the ctx entity (the bridge-registry passthrough; registry.nix stampTreeOf).";
                }
              )
              // (decl.options or { });
          }
      ) (buildSchema v1Schema);

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

      # Derived from the v1-DECLARED kind names (identical set: `schemaDecls` only adds the host/user
      # built-ins), NOT from `schemaDecls` — schemaDecls now declares the stamp-field options, which
      # depend on `instanceKeyMap` ← `customKinds`; deriving from v1Schema keeps that chain acyclic.
      customKinds = builtins.filter (k: k != "host" && k != "user") (builtins.attrNames v1Schema);
      # The bridge's ROBUST namespace→kind marker (`_registryKinds`, bridge.nix registryKindOf), keyed
      # by namespace. Reflected off the DECLARED option surface (respecting internal/identity), so it
      # resolves a namespace the value-reflecting `identityHashFor` below MISSES (a derived/internal
      # primitive over-includes — cluster.sopsAgeRecipient). Absent on mkDen-direct fixtures (no bridge),
      # where the value-reflecting discovery rules — byte-identical to before.
      registryKinds = v1Decls._registryKinds or { };
      # kind → the registry namespace whose instances match it. The bridge's option-reflecting marker
      # WINS (robust against derived/internal primitives); else the value-reflecting id_hash marker; a
      # kind with neither falls back to its own name (`den.<kind>`, the pre-M1.5 singular convention) so
      # an inline fixture keyed by the kind name still resolves.
      bridgeKeyFor =
        kind:
        let
          hits = builtins.filter (n: registryKinds.${n} == kind) (builtins.attrNames registryKinds);
        in
        if hits == [ ] then null else builtins.head hits;
      discoverKeyFor =
        kind:
        let
          bridged = bridgeKeyFor kind;
          hits = builtins.filter (
            n: instanceMatchesKind kind (builtins.head (builtins.attrValues v1Decls.${n}))
          ) candidateRegistryKeys;
        in
        if bridged != null then
          bridged
        else if hits == [ ] then
          kind
        else
          builtins.head hits;
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
        # #73: the applied (instance-evaled, #71) host.users value off the host entity's raw stamp
        # (#70) — LAZY per field; `{ }` when un-stamped (mkDen-direct) or absent.
        userFieldsFor =
          hostName: userName:
          builtins.removeAttrs (((entityFields.host.${hostName} or { }).users or { }).${userName} or { }) [
            "_module"
            "id_hash"
          ];
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
      # host id_hash. ONE source — the host entry itself: on the bridge path `v1Decls.hosts` IS the
      # declared registry's APPLIED view (registry.nix mkHostsOption — v1's own instance eval, pin
      # 11866c16 entities/host.nix:26-57), so `flatHosts.<h>.instantiate` is the MERGED value with the
      # corpus's `instantiate = mkDefault resolvedChannel.nixosSystem` (host.nix:325) materialized at
      # the module system's native priorities (authored 100 < mkDefault 1000 < base default 1500); on
      # an mkDen-direct path it is the raw authored field alone, byte-identical to the pre-registry
      # read (no bridge ⇒ no kind eval ⇒ no schema default — the D7 "fall to the lower grains" slot).
      # The evaluator is a nixpkgs-BOUND function, so it stays a compile-time `id_hash -> evaluator`
      # map — NEVER a field on the strict, field-less den-hoag entity (the C1 type-crossing dodge; the
      # registry stamp EXCLUDES it structurally, `types.raw`) — and is forced only at the terminal
      # (the compat nixos wrapper crosses via it per host). Absent -> null, and the wrapper falls to
      # the class-level terminal (the global `den.nixpkgs` grain, or the pure nixpkgs-free `collect`).
      instantiateByHostId = builtins.listToAttrs (
        map (name: {
          name = registries.host.${name}.id_hash;
          value = flatHosts.${name}.instantiate or null;
        }) (builtins.attrNames flatHosts)
      );
      instantiateFor = host: instantiateByHostId.${host.id_hash} or null;

      # hmModuleFor (ship-gate R6, the home-manager host-module grain — the terminal-side twin of
      # instantiateFor): v1's per-host `home-manager.module` (the home-manager NixOS module the hm
      # battery imports into the host's class-module so a HOST-scope aspect emitting `home-manager.*`
      # content typechecks — corpus agenixHostAspect `home-manager.sharedModules`, batteries/agenix.nix:87;
      # v1 hm battery hostModule, pin home-env.nix:74-86). Keyed by host id_hash, ONE source — the host
      # entry (the instantiateFor posture): on the bridge path the registry entry's `home-manager.module`
      # is the channel-resolved MERGED value (corpus host.nix:329-334 `mkDefault` under the registry's
      # native priorities; the base entity declares both halves, registry.nix); on an mkDen-direct path
      # it is the raw authored field alone. Like instantiateFor the module is a nixpkgs closure, so it
      # rides a compile-side `id_hash -> module` map, NEVER a field on the strict den-hoag entity (the
      # registry stamp EXCLUDES it structurally, `types.raw`), forced only at the terminal (the compat
      # nixos wrapper, flake-module.nix).
      #
      # THE GATE (v1's enable, home-env.nix:44-48 `enable && osSupported && hostHasClass`), reproduced to
      # the compat-OBSERVABLE surface — BEHAVIOR-IDENTICAL to the harvest-era gate:
      #   - osSupported (nixos/darwin): carried by the wrapper being stamped on the nixos class ALONE
      #     (flake-module.nix; the darwin arm is class-B lookahead).
      #   - the MODULE must exist: a host with no `home-manager.module` (a channel-less/hm-less host) →
      #     null → NO import (the "hm-less host" gated-null: no option declared, drv unshifted).
      #   - an EXPLICIT `home-manager.enable = false` opts out → null (v1's explicit disable; the base
      #     entity declares `enable` raw+null — registry.nix — so the def is registry-legal and only an
      #     explicit def lands). CENSUS (corpus b0b20769): ZERO corpus hosts set `home-manager.enable`,
      #     so this arm is corpus-inert — every corpus nixos host defaults enabled.
      # CEILING (documented, ledger R6): v1's `hostHasClass` (host-has-user-with-class — the host has ≥1
      # homeManager user) is UNREPRODUCIBLE here — the corpus binds users to hosts via the environment resolve
      # fan-out (fleet.nix env-to-hosts → resolve.to "user"), which the shim STUBS (board #49/#50), so the
      # compat membership (ingest `bindings` = den.homes ∪ host.users) is EMPTY for every corpus host; gating
      # on it would suppress the import on EVERY corpus host and defeat the rung. So the compat gate is
      # MODULE-PRESENCE + the explicit opt-out: the corpus channel sets `home-manager.module` IFF the host is a
      # real nixos/darwin channel host, and every such host has ≥1 hm user in v1 (enable true), so
      # module-presence ⟺ v1's enable ACROSS THE CORPUS. The lone divergence — a module-carrying host with zero
      # hm users — is corpus-absent and self-announces (the imported hm module is inert without users, adding
      # only an empty `home-manager` option, never a wrong artifact). When board #49 lands (real user fan-out ⇒
      # non-empty compat membership), tighten this to the membership-aware gate.
      hmModuleByHostId = builtins.listToAttrs (
        map (
          name:
          let
            hm = flatHosts.${name}."home-manager" or { };
          in
          {
            name = registries.host.${name}.id_hash;
            value = if (hm.enable or null) == false then null else hm.module or null;
          }
        ) (builtins.attrNames flatHosts)
      );
      hmModuleFor = host: hmModuleByHostId.${host.id_hash} or null;

      # ── entityFields — the per-KIND per-entity ctx-entity field record (the instanceConfig stamp
      # source, flake-module.nix; replaces hostClassName/hostSystemName/hostHostName + the census
      # hostEntityFields) ────────────────────────────────────────────────────────────────────────────
      # host = the three STRUCTURAL fields (the R3/R6 route gates + battery reads; v1 binds the full
      # host config as the ctx entity, pin 11866c16 assemble-pipes.nix:154):
      #   class    — `host.class` else derived from system (`classOfHost`, v1 host.nix:65-67 — a
      #              classless host is NOT inert, v1 derives);
      #   system   — the `den.hosts.<system>.<name>` group key (demoted by flattenHosts / the registry's
      #              base option, v1 host.nix:64); the home-platform routes gate on it;
      #   hostName — v1's base-entity `strOpt "Network hostname" config.name` (pin entities/host.nix:63;
      #              NOT a corpus-schema field) — the hostname battery reads it;
      # PLUS the registry-passthrough stamp (`stampsByKind`, structural exclusion applied bridge-side).
      # Every OTHER kind's entities carry their registry stamp alone (kind-generic; user has none —
      # v1 declares no user registry, pin modules/options.nix:71-72). The stamp wins a name collision
      # with the structural trio only where the registry actually stamped one — the trio's fields are
      # raw-typed in the registry base (structurally excluded), so collisions are fixture-theoretical.
      entityFields = {
        host = builtins.mapAttrs (
          name: h:
          withRawStamp "host" name (
            {
              class = classOfHost h;
              system = h.system or null;
              hostName = h.hostName or name;
            }
            // (stampsByKind.host.${name} or { })
          )
        ) flatHosts;
      }
      // prelude.genAttrs customKinds (
        k: builtins.mapAttrs (name: st: withRawStamp k name st) stampsByKind.${k}
      );

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
        # hmModuleFor (R6): the per-host home-manager NixOS module (terminal-side twin of instantiateFor),
        # read off the host entry (registry-merged on the bridge path), gated on module-presence +
        # explicit `enable=false` opt-out.
        hmModuleFor
        # The per-KIND per-entity ctx-entity field record (structural trio + the registry-passthrough
        # stamp) — the instanceConfig entity stamp reads it; the delivery-depth `host.settings.*`
        # binding source and the u8-path-2 cluster/environment ctx-entity source, one mechanism.
        entityFields
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
    flakeExposedSystems
    flattenHosts
    homeBindings
    hostUserBindings
    buildSchema
    buildRegistries
    buildMembership
    isInstanceRegistry
    resolveClass
    aspectEntry
    classEntry
    ingest
    ;
}
