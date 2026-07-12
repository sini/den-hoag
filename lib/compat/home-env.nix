# den-compat home-env surface (ship-gate lib-surface rung). Reproduces den v1's `den.lib.home-env`
# (frozen pin 11866c16, nix/lib/home-env.nix) — the OS-user home battery builder a consumer calls to
# wire a home-manager-class context (nix-on-droid's `droidHome`, corpus modules/den/batteries/
# nix-on-droid.nix:61). It is v1 VOCABULARY, so it lives COMPAT-side (the boundary tripwire holds); the
# three exports {makeHomeEnv, mkDetectHost, mkIntoClassUsers} are v1's surface (makeHomeEnv is the entry;
# the other two are its internals, exported by v1 for reuse — reproduced for surface totality).
#
# NIXPKGS-LIB-FREE (Law, like every compat file): v1's home-env.nix receives nixpkgs `lib` from its import
# context and uses it for both trivial list ops AND the `hostConf` option module (mkOption/types). The shim
# has no nixpkgs lib. So: the trivial ops are `prelude`/`builtins` (elem/any/filter/attrValues/optional;
# `singleton`/`optionals` inlined — prelude carries neither), and `hostConf`'s option module pulls `lib`
# from its MODULE ARGS (`{ host, lib, ... }:`) instead of a captured import-context lib. This is the ONE
# sourcing deviation from byte-faithful, and it is observationally identical: the module system supplies
# `lib` to every `den.schema.<kind>.imports` module, the emitted option declarations are the same
# mkOption/types calls, and using the CONSUMER's own lib (not a second instance) is if anything safer.
#
# PROBE-SAFETY of mkDetectHost's bare `host.class` (v1 :22). concern-policies classifies a policy's stratum
# by probing it at a VALUE-LESS sentinel entry (`{ id_hash; name }`, no `class`/`users`/option field). The
# battery's policy fires through that probe. mkDetectHost returns `isEnabled && isOsSupported &&
# hostHasClass`, and `isEnabled = (host.${optionPath} or { }).enable or false` is the FIRST `&&` operand —
# `false` at the sentinel (and at any non-droid host) — so `&&` SHORT-CIRCUITS before `isOsSupported` reads
# the bare `host.class` or `hostHasClass` reads the bare `host.users`. The reproduction is therefore
# BYTE-FAITHFUL (no `or null` needed): the operand order IS the probe-safety. (Witnessed: the exact
# concern-policies sentinel through the faithful policyFn yields `[ ]`, no hard-fail — compat-home-env.nix.)
{
  prelude,
  den,
  # v1's home-env receives the den flake `inputs` and threads them into `getModule`; the corpus getModule
  # (`{ ... }: { }`) ignores its args, so the value is inert for the ship-gate. Defaulted `{ }` — a getModule
  # that reads flake inputs is out-of-corpus (it would be threaded when a consumer needs it).
  inputs ? { },
}:
let
  inherit (prelude)
    any
    attrValues
    concatMap
    elem
    filter
    optional
    ;
  # `lib.singleton`/`lib.optionals` — prelude carries neither; inlined (v1 nix/lib/home-env.nix uses the
  # nixpkgs spellings).
  singleton = x: [ x ];
  optionals = cond: xs: if cond then xs else [ ];

  host-has-user-with-class = host: class: any (user: elem class user.classes) (attrValues host.users);

  mkDetectHost =
    {
      className,
      supportedOses ? [
        "nixos"
        "darwin"
      ],
      optionPath,
    }:
    { host, ... }:
    let
      isOsSupported = elem host.class supportedOses;
      isEnabled = (host.${optionPath} or { }).enable or false;
      hostHasClass = host-has-user-with-class host className;
    in
    isEnabled && isOsSupported && hostHasClass;

  mkIntoClassUsers =
    className:
    { host, ... }:
    map (user: { inherit host user; }) (filter (u: elem className u.classes) (attrValues host.users));

  hostOptions =
    {
      className,
      optionPath,
      getModule,
    }:
    # DEVIATION (documented above): `lib` from the MODULE ARGS, not a captured import lib — the compat
    # layer has no nixpkgs lib, and the module system supplies it here. Byte-identical option content.
    { host, lib, ... }:
    {
      options.${optionPath} = {
        enable = lib.mkOption {
          type = lib.types.bool;
          defaultText = lib.literalExpression "host-has-user-with-class host className";
          default = host-has-user-with-class host className;
        };
        module = lib.mkOption {
          type = lib.types.deferredModule;
          defaultText = lib.literalExpression "getModule { inherit host inputs; }";
          default = getModule { inherit host inputs; };
        };
      };
    };

  # Self-contained battery: host → user routing via aspect-included policy.
  # The battery is an aspect with policies — include it in den.schema.host.includes
  # and its policy fires during host resolution without separate den.policies registration.
  #
  # SHIM COMPILE PATH (the convergence, not a new mechanism): the battery `{ policies; includes }` is an
  # INLINE aspect in `den.schema.host.includes`. compile.nix `kindIncludePolicies` EXPANDS it — HOISTS its
  # `.includes` (the `{ __isPolicy; name; fn }` record) into the kind's ref list, where it reaches the
  # policy-ref branch → `compilePolicy` record `{ __condition = { host = false; }; fn }` → concern-policies'
  # value-less probe → policyFn short-circuits to `[ ]` (probe-safety above) → per-declaration EXPANSION
  # (the 8e2f8c8 parametric-policy machinery). The `.policies` entry is DROPPED as a VERIFIED-DUPLICATE of
  # that same-named includes record (v1 normalize.nix `wrapChild` passes this shape through unchanged, then
  # the aspect pipeline NAME-KEYS the policy — the identical name in `.policies` and `.includes` makes v1's
  # effective firing ONE, so the hoist+drop matches the oracle, not just the corpus).
  makeHomeEnv =
    {
      className,
      ctxName ? className,
      supportedOses ? [
        "nixos"
        "darwin"
      ],
      optionPath,
      getModule,
      forwardPathFn,
      schemaIncludes ? [ ],
    }:
    let
      # Keyed module wrapper: the NixOS module system deduplicates imports
      # with the same `key`, so this fires once even when included from
      # multiple user entity resolves.
      hostModule =
        { host }:
        {
          ${host.class}.imports = [
            {
              key = "den:${optionPath}-host-module";
              imports = [ host.${optionPath}.module ];
            }
          ];
        };

      userForward =
        { host, user }:
        den.batteries.forward {
          each = singleton true;
          fromClass = _: className;
          intoClass = _: host.class;
          intoPath = _: forwardPathFn { inherit host user; };
          # The forward source resolves via spawnNode (threaded with the
          # parent scope-tree state), so parametric host aspects re-fired at the
          # user scope bind the same ancestor args (e.g. `environment`) they
          # would at the host scope — no manual chainCtx threading needed.
          fromAspect = _: den.lib.resolveEntity "user" { inherit host user; };
          # #53c (§9 item 3, ratified) — the CELL-FIRED emitter (userDetectFn) fires this forward AT the
          # (user,host) cell, and den-hoag isolates every cell as its own edge-root: without a parent
          # target the delivered content lands in the cell's OWN root and never reaches the host
          # terminal (v1's non-isolated nesting fold carried it there; cell isolation removes that).
          # `appendToParent` (v1's route property, pin fx/edges/route.nix:364/:370-377) makes the forward
          # target the containment PARENT root — the host — where the #66 terminal law consumes it. THE
          # RATIFIED CEILING (accepted-and-ledgered): the resulting edge targets the HOST where v1's
          # synthesize edge targets the CELL — a TRACE-only divergence, drvPath-invisible. Harmless for
          # the host-fired policyFn emitter's resolves (a parentless firing root falls back to the firing
          # scope itself — v1's `or sid`, route.nix:375).
          appendToParent = true;
        };

      # Includes shared by both host-scope and user-scope detection.
      classIncludes = [
        (den.lib.policy.include hostModule)
      ]
      ++ optional (den.aspects ? os-user-class-fwd) (
        den.lib.policy.include den.aspects.os-user-class-fwd
      );

      policyFn =
        { host, ... }:
        let
          enabled = mkDetectHost {
            inherit className supportedOses optionPath;
          } { inherit host; };
        in
        if !enabled then
          [ ]
        else
          let
            pairs = mkIntoClassUsers className { inherit host; };
            resolves = map (
              pair:
              den.lib.policy.resolve.withIncludes ([ userForward ] ++ schemaIncludes) {
                user = pair.user;
              }
            ) pairs;
          in
          resolves ++ classIncludes ++ map (inc: den.lib.policy.include inc) schemaIncludes;

      # Complements the host-scope battery which only sees users
      # declared on host.users, not registry or policy-resolved users.
      userDetectFn =
        { host, user, ... }:
        let
          # BYTE-FAITHFUL to v1 (nix/lib/home-env.nix). userDetectFn's `isOsSupported` is the FIRST operand of
          # `optionals (isOsSupported && hasClass)` (no `isEnabled` short-circuit, unlike policyFn), so it IS
          # forced at concern-policies' value-less probe. Probe-safety is now the GENERAL configurable sentinel
          # (B2, lib/compat/flake-module.nix `probeSentinelModule`): the probe entry carries a non-matching
          # `class = "«probe»"`, so `elem "«probe»" supportedOses` = false → gated-inert, with NO per-site
          # deviation; `user.classes` is then short-circuited by `&&`. (The earlier `host.class or null`
          # deviation was warranted only until this general mechanism existed — reverted; enrichment subsumes it.)
          isOsSupported = elem host.class supportedOses;
          hasClass = elem className user.classes;
        in
        optionals (isOsSupported && hasClass) (
          [
            (den.lib.policy.include (userForward {
              inherit host user;
            }))
          ]
          ++ classIncludes
        );
    in
    {
      battery = {
        policies."host-to-${ctxName}-users" = policyFn;
        includes = [
          {
            __isPolicy = true;
            name = "host-to-${ctxName}-users";
            fn = policyFn;
          }
        ];
      };

      # User-scope policy for user schema includes.
      userDetect = {
        policies."${ctxName}-user-detect" = userDetectFn;
        includes = [
          {
            __isPolicy = true;
            name = "${ctxName}-user-detect";
            fn = userDetectFn;
          }
        ];
      };

      hostConf = hostOptions {
        inherit
          className
          optionPath
          getModule
          ;
      };

    };

in
{
  inherit makeHomeEnv mkDetectHost mkIntoClassUsers;
}
