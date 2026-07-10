# den-compat batteries (ship-gate lib-surface rung) — the corpus-consumed v1 `den.batteries.<name>`
# ports, reproduced FAITHFULLY (value-identically) from the frozen v1 pin
# (github:denful/den/11866c16, modules/aspects/batteries/), presented at `config.den.batteries.<name>`
# via a flake-parts MODULE imported into the flakeModule (mirroring v1's flakeModule importing each
# battery module). The `lib`/`withSystem`/`inputs`/`self`/`den` a battery body closes over come from the
# MODULE ARGS (the flake-parts module system supplies them) — the compat layer captures no nixpkgs `lib`
# (R10 consumer-lib principle, the same posture as home-env's hostConf). Every battery body stays LAZY:
# a battery is inert data consumed BY REFERENCE (`den.default.includes = [ den.batteries.<x> ]` / a user
# aspect's includes); an unreferenced battery never forces its `lib`/`withSystem`/`den` reads (v1 posture).
#
# The seven the corpus exercises: define-user, hostname, primary-user, host-aspects, inputs', self',
# unfree. Each cites its v1 source file. The bare-fn / `{ __fn }` includes here become den-hoag
# `__isWrappedFn` functors at the compile boundary (compile.nix `normalizeInclude`, §339 wrap-ground).
{
  config,
  lib,
  withSystem,
  inputs,
  self,
  den,
  ...
}:
let
  # ── define-user (v1 modules/aspects/batteries/define-user.nix) ─────────────────────────────────────
  defineUser =
    let
      description = ''
        Defines a user at OS and Home levels.

        Works in NixOS/Darwin and standalone Home-Manager

        ## Usage

           # for NixOS/Darwin
           den.aspects.my-user.includes = [ den.batteries.define-user ]

           # for standalone home-manager
           den.aspects.my-home.includes = [ den.batteries.define-user ]

        or globally (automatically applied depending on context):

           den.default.includes = [ den.batteries.define-user ]
      '';

      homeDir =
        host: user:
        if lib.hasSuffix "darwin" host.system then "/Users/${user.userName}" else "/home/${user.userName}";

      userContext =
        { host, user }:
        {
          name = "define-user/${user.userName}@${host.name}";
          nixos.users.users.${user.userName} = {
            name = user.userName;
            home = homeDir host user;
            isNormalUser = true;
          };
          darwin.users.users.${user.userName} = {
            name = user.userName;
            home = homeDir host user;
          };
          homeManager = {
            home.username = user.userName;
            home.homeDirectory = homeDir host user;
          };
        };

      hmContext =
        { home }:
        userContext {
          host.system = home.system;
          user.userName = home.userName;
        }
        // {
          name = "define-user/home";
        };
    in
    {
      name = "define-user";
      inherit description;
      includes = [
        userContext
        hmContext
      ];
    };

  # ── hostname (v1 modules/aspects/batteries/hostname.nix) ───────────────────────────────────────────
  hostname =
    let
      description = ''
        Sets the system hostname as defined in `den.hosts.<name>.hostName`:

        Works on NixOS/Darwin/WSL.

        ## Usage

           den.defaults.includes = [ den.batteries.hostname ];
      '';

      setHostname =
        { host, ... }:
        {
          name = "hostname/os";
        }
        # A synthetic host identity (a `user@host` home with no declared host) has
        # no OS class to set a hostname on; gate to real, class-bearing hosts.
        // lib.optionalAttrs (host ? class) {
          ${host.class}.networking.hostName = host.hostName;
        };
    in
    {
      name = "hostname";
      inherit description;
      includes = [ setHostname ];
    };

  # ── primary-user (v1 modules/aspects/batteries/primary-user.nix) ───────────────────────────────────
  # NB: the battery VALUE is the bare fn `userToHostContext` (not a `{ name; includes }` record).
  primaryUser =
    let
      description = ''
        Sets user as *primary*.

        On NixOS adds wheel and networkmanager groups.
        On Darwin sets user as system.primaryUser
        On WSL sets defaultUser if host has `wsl` support.

        ## Usage

           den.aspects.my-user.includes = [ den.batteries.primary-user ];

      '';

      userToHostContext =
        { user, host, ... }:
        {
          name = "primary-user(${user.userName}@${host.name})";
          inherit description;
          darwin.system.primaryUser = user.userName;
          wsl.defaultUser = user.userName;
          nixos.users.users.${user.userName} = {
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "networkmanager"
            ];
          };
        };
    in
    userToHostContext;

  # ── host-aspects (v1 modules/aspects/batteries/host-aspects.nix) ───────────────────────────────────
  hostAspects =
    let
      description = ''
        Projects all `user.classes` like `homeManager` from the host's aspect tree
        onto users who opt in. Requires the fx pipeline.

        ## Usage

          den.aspects.tux.includes = [ den.batteries.host-aspects ];

        Any host aspect that defines a `homeManager` key will have that
        config forwarded to the user's homeManager evaluation. Other host-class
        keys (nixos, darwin) are ignored — host.aspect is resolved
        specifically for `user.classes`.
      '';

      # Emit a deferred node spawn request. Resolution happens post-walk (in
      # resolve.nix's drain augmentation) where the parent scope-tree state (host +
      # siblings) exists, so the projection sees the fleet — a host-aspects-projected
      # homeManager consumer of a fleet-collected pipe lists every peer. Ancestor
      # bindings like `environment` arrive via the threaded scope context, not
      # manual chainCtx threading.
      from-host = { host, user, ... }: [
        (den.lib.policy.spawn { classes = user.classes or [ "homeManager" ]; })
      ];
    in
    {
      name = "host-aspects";
      inherit description;
      includes = [
        {
          __isPolicy = true;
          name = "host-aspects-project";
          fn = from-host;
        }
      ];
    };

  # ── inputs' (v1 modules/aspects/batteries/flake-parts/inputs.nix) ──────────────────────────────────
  inputsPrime =
    let
      description = ''
        Provides the `flake-parts` `inputs'` (the flake's `inputs` with system pre-selected)
        as a top-level module argument.

        This allows modules to access per-system flake outputs without needing
        `pkgs.stdenv.hostPlatform.system`.

        ## Usage

        **Global (Recommended):**
        Apply to all hosts, users, and homes.

            den.default.includes = [ den.batteries.inputs' ];

        **Specific:**
        Apply only to a specific host, user, or home aspect.

            den.aspects.my-laptop.includes = [ den.batteries.inputs' ];
            den.aspects.alice.includes = [ den.batteries.inputs' ];

        **Note:** This aspect is contextual. When included in a `host` aspect, it
        configures `inputs'` for the host's OS. When included in a `user` or `home`
        aspect, it configures `inputs'` for the corresponding Home Manager configuration.
      '';

      mkAspect =
        class: system:
        withSystem system (
          { inputs', ... }:
          {
            ${class}._module.args.inputs' = inputs';
          }
        );

      osAspect =
        { host }:
        {
          name = "inputs'/os";
        }
        # Guard a synthetic host identity (classless `user@host` home) the same way
        # hmAspect already guards `home ? class`.
        // lib.optionalAttrs (host ? class) (mkAspect host.class host.system);

      userAspect =
        {
          user,
          host,
        }:
        {
          name = "inputs'/user";
          includes = map (c: mkAspect c host.system) user.classes;
        };

      hmAspect =
        { home }:
        {
          name = "inputs'/home";
        }
        // lib.optionalAttrs (home ? class) (mkAspect home.class home.system);
    in
    {
      name = "inputs'";
      inherit description;
      includes = [
        osAspect
        userAspect
        hmAspect
      ];
    };

  # ── self' (v1 modules/aspects/batteries/flake-parts/self.nix) ──────────────────────────────────────
  selfPrime =
    let
      description = ''
        Provides the `flake-parts` `self'` (the flake's `self` with system pre-selected)
        as a top-level module argument.

        This allows modules to access per-system flake outputs without needing
        `pkgs.stdenv.hostPlatform.system`.

        ## Usage

        **Global (Recommended):**
        Apply to all hosts, users, and homes.

            den.default.includes = [ den.batteries.self' ];

        **Specific:**
        Apply only to a specific host, user, or home aspect.

            den.aspects.my-laptop.includes = [ den.batteries.self' ];
            den.aspects.alice.includes = [ den.batteries.self' ];

        **Note:** This aspect is contextual. When included in a `host` aspect, it
        configures `self'` for the host's OS. When included in a `user` or `home`
        aspect, it configures `self'` for the corresponding Home Manager configuration.
      '';

      mkAspect =
        class: system:
        withSystem system (
          { self', ... }:
          {
            ${class}._module.args.self' = self';
          }
        );

      osAspect =
        { host }:
        {
          name = "self'/os";
        }
        # Guard a synthetic host identity (classless `user@host` home) the same way
        # homeAspect already guards `home ? class`.
        // lib.optionalAttrs (host ? class) (mkAspect host.class host.system);

      userAspect =
        {
          user,
          host,
        }:
        {
          name = "self'/user";
          includes = map (c: mkAspect c host.system) user.classes;
        };

      homeAspect =
        { home }:
        {
          name = "self'/home";
        }
        // lib.optionalAttrs (home ? class) (mkAspect home.class home.system);
    in
    {
      name = "self'";
      inherit description;
      includes = [
        osAspect
        userAspect
        homeAspect
      ];
    };

  # ── unfree (v1 modules/aspects/batteries/unfree/unfree.nix) ────────────────────────────────────────
  # A `__functor` battery: `den.batteries.unfree [ names ]` → a parametric aspect (the `__fn` include).
  unfree =
    let
      description = ''
        A class generic aspect that enables unfree packages by name.

        Works for any class (nixos/darwin/homeManager,etc) on any host/user/home context.

        ## Usage

          den.aspects.my-laptop.includes = [ (den.batteries.unfree [ "example-unfree-package" ]) ];

        It will dynamically provide a module for each class when accessed.
      '';

      __functor = _self: allowed-names: {
        name = "unfree(${builtins.concatStringsSep "," allowed-names})";
        meta.provider = [
          "den"
          "provides"
        ];
        __fn =
          {
            class,
            host ? null,
            ...
          }:
          let
            validClasses = [
              "nixos"
              "darwin"
              "homeManager"
            ];
            classModule = lib.optionalAttrs (builtins.elem class validClasses) {
              ${class}.unfree.packages = allowed-names;
            };
            # When resolving for homeManager or a non-module-system class (e.g.
            # "user"), also emit to the host's OS class.  This ensures
            # nixpkgs.config.allowUnfreePredicate covers these packages:
            #   - homeManager + useGlobalPkgs = true → OS-level predicate needed
            #   - "user" class (no HM) → only the host's OS config exists
            hostModule = lib.optionalAttrs (
              (class == "homeManager" || !builtins.elem class validClasses)
              && host ? class
              && builtins.elem host.class validClasses
            ) { ${host.class}.unfree.packages = allowed-names; };
          in
          classModule // hostModule;
        __args = {
          class = true;
          host = true;
        };
      };
    in
    {
      inherit description __functor;
    };
in
{
  config.den.batteries = {
    define-user = defineUser;
    inherit hostname;
    primary-user = primaryUser;
    host-aspects = hostAspects;
    "inputs'" = inputsPrime;
    "self'" = selfPrime;
    inherit unfree;
  };
}
