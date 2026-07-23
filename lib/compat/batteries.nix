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
# The seven the CORPUS exercises: define-user, hostname, primary-user, host-aspects, inputs', self',
# unfree. Five additional COVERAGE ports (corpus-unexercised, faithful to the frozen v1 pin — the
# ship-gate battery-surface completion): insecure, tty-autologin, vm-autologin, user-shell, import-tree.
# Each cites its v1 source file. The bare-fn / `{ __fn }` includes here become den-hoag
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

  # ── insecure (v1 modules/aspects/batteries/insecure/insecure.nix) ──────────────────────────────────
  # A `__functor` battery: `den.batteries.insecure [ names ]` → a parametric aspect (the `__fn` include).
  # Byte-identical to `unfree` above modulo the emitted option key (permittedInsecurePackages.packages).
  insecure =
    let
      description = ''
        A class generic aspect that enables insecure packages by name and version.

        Works for any class (nixos/darwin/homeManager,etc) on any host/user/home context.

        ## Usage

          den.aspects.my-laptop.includes = [ (den.batteries.insecure [ "example-insecure-package-1.0.0" ]) ];

        It will dynamically provide a module for each class when accessed.
      '';

      __functor = _self: allowed-names: {
        name = "insecure(${builtins.concatStringsSep "," allowed-names})";
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
              ${class}.permittedInsecurePackages.packages = allowed-names;
            };
            # When resolving for homeManager or a non-module-system class (e.g.
            # "user"), also emit to the host's OS class so
            # nixpkgs.config.permittedInsecurePackages covers these packages.
            hostModule = lib.optionalAttrs (
              (class == "homeManager" || !builtins.elem class validClasses)
              && host ? class
              && builtins.elem host.class validClasses
            ) { ${host.class}.permittedInsecurePackages.packages = allowed-names; };
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

  # ── tty-autologin (v1 modules/aspects/batteries/tty-autologin.nix) ─────────────────────────────────
  # A `__functor` battery: `den.batteries.tty-autologin "root"` → a `{ name; meta.provider; nixos }` aspect
  # whose `nixos` is a NixOS module (routes as class content). No `__fn` — the module reads pkgs/config at
  # NixOS eval depth. From https://discourse.nixos.org/t/autologin-for-single-tty/49427/2
  ttyAutologin =
    let
      description = ''
        Enables automatic tty login given a username.

        This battery must be included in a Host aspect.

           den.aspects.my-laptop.includes = [ (den.batteries.tty-autologin "root") ];
      '';

      tty-autologin-module =
        username:
        { pkgs, config, ... }:
        {
          systemd.services."getty@tty1" = {
            overrideStrategy = "asDropin";
            serviceConfig.ExecStart = [
              ""
              "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin ${username} --noclear --keep-baud %I 115200,38400,9600 $TERM"
            ];
          };
        };

      __functor = _self: username: {
        name = "tty-autologin(${username})";
        meta.provider = [
          "den"
          "provides"
        ];
        nixos = tty-autologin-module username;
      };
    in
    {
      inherit description __functor;
    };

  # ── vm-autologin (v1 modules/aspects/batteries/vm-autologin.nix) ───────────────────────────────────
  # As tty-autologin, but the module nests under `nixos.virtualisation.vmVariant` (build-vm only).
  vmAutologin =
    let
      description = ''
        Enables automatic tty login given a username when running `nixos-rebuild build-vm`.

        This battery must be included in a Host aspect.

           den.aspects.my-laptop.includes = [ (den.batteries.vm-autologin "root") ];
      '';

      vm-autologin-module =
        username:
        { pkgs, config, ... }:
        {
          systemd.services."getty@tty1" = {
            overrideStrategy = "asDropin";
            serviceConfig.ExecStart = [
              ""
              "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin ${username} --noclear --keep-baud %I 115200,38400,9600 $TERM"
            ];
          };
        };

      __functor = _self: username: {
        name = "vm-autologin(${username})";
        meta.provider = [
          "den"
          "provides"
        ];
        nixos.virtualisation.vmVariant = vm-autologin-module username;
      };
    in
    {
      inherit description __functor;
    };

  # ── user-shell (v1 modules/aspects/batteries/user-shell.nix) ───────────────────────────────────────
  # NB: the battery VALUE is a CURRIED BARE FN `shell: { description; includes }` (not a `{ description;
  # __functor }` record) — v1's exact shape; `.description` is readable only after applying `shell`. The
  # inner helper is renamed `shellFor` because the outer `let`-binding already claims `userShell`.
  userShell =
    let
      description = ''
        Sets a user default shell, enables the shell at OS and Home level.

        Usage:

          den.aspects.vic.includes = [
            # will always love red snappers.
            (den.batteries.user-shell "fish")
          ];
      '';

      shellFor =
        shell: user:
        let
          nixos =
            { pkgs, ... }:
            {
              programs.${shell}.enable = true;
              users.users.${user.userName}.shell = pkgs.${shell};
            };
          darwin = nixos;
          homeManager.programs.${shell}.enable = true;
        in
        {
          inherit nixos darwin homeManager;
        };
    in
    shell: {
      inherit description;
      includes = [
        ({ host, user }: { name = "user-shell/${user.userName}@${host.name}"; } // shellFor shell user)
        ({ home }: { name = "user-shell/${home.name}"; } // shellFor shell home)
      ];
    };

  # ── import-tree (v1 modules/aspects/batteries/import-tree.nix) ─────────────────────────────────────
  # A `{ description; __functor; provides }` battery: the functor readDir-scans `root` for `_<class>` dirs
  # and emits per-class `imports = [ (inputs.import-tree "<root>/_<class>") ]`. `inputs.import-tree` + `lib`
  # are read LAZILY (only when the functor is applied to a `_<class>`-bearing tree) — inert-by-reference, so
  # den-hoag needs NO `import-tree` flake input (## Requirements: inputs.import-tree is a CONSUMER contract,
  # v1-faithful). `provides.{host,user,home}` re-apply the LOCAL `importTree` at `<root>/<entity-name>`
  # (v1 used the config self-reference `den.batteries.import-tree`; the local binding is byte-equivalent).
  importTree = {
    description = ''
      Recursively imports non-dendritic .nix files depending on their Nix configuration `class`.

      This can be used to help migrating from huge existing setups.


      ```
        # this is at <repo>/modules/non-dendritic.nix
        den.aspects.my-laptop.includes = [
          (den.batteries.import-tree.provides.host ../non-dendritic)
        ]
      ```

      With following structure, it will automatically load modules depending on their class.

      ```
         <repo>/
           modules/
             non-dendritic.nix # configures this aspect
           non-dendritic/ # name is just an example here
             hosts/
               my-laptop/
                 _nixos/          # a directory for `nixos` class
                   auto-generated-hardware.nix # any nixos module
                 _darwin/
                   foo.nix
                 _homeManager/
                   me.nix
      ```

      ## Requirements

        - inputs.import-tree

      ## Usage

        this aspect can be included explicitly on any aspect:

            # example: will import ./disko/_nixos files automatically.
            den.aspects.my-disko.includes = [ (den.batteries.import-tree ./disko/) ];

        or it can be default imported per host/user/home:

            # load from ./hosts/<host>/_nixos
            den.schema.host.includes = [ (den.batteries.import-tree.provides.host ./hosts) ];

            # load from ./users/<user>/{_homeManager, _nixos}
            den.schema.user.includes = [ (den.batteries.import-tree.provides.user ./users) ];

            # load from ./homes/<home>/_homeManager
            den.schema.home.includes = [ (den.batteries.import-tree.provides.home ./homes) ];

        you are also free to create your own auto-imports layout following the implementation of these.
    '';

    __functor =
      _: root:
      let
        # Scan for _<class> directories under root and emit per-class imports.
        # This avoids depending on the scope's `class` argument, which the
        # fx-pipeline only provides once per scope (not once per class).
        rootStr = toString root;
        entries = lib.optionalAttrs (builtins.pathExists rootStr) (builtins.readDir rootStr);
        classEntries = lib.filterAttrs (name: type: type == "directory" && lib.hasPrefix "_" name) entries;
        aspect = lib.mapAttrs' (dirName: _: {
          name = lib.removePrefix "_" dirName;
          value.imports = [ (inputs.import-tree "${rootStr}/${dirName}") ];
        }) classEntries;
      in
      {
        name = "import-tree(${baseNameOf rootStr})";
        meta.provider = [
          "den"
          "batteries"
        ];
      }
      // aspect;

    provides = {
      host = root: { host, ... }: importTree "${toString root}/${host.name}";
      home = root: { home, ... }: importTree "${toString root}/${home.name}";
      user = root: { user, ... }: importTree "${toString root}/${user.name}";
    };
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
    inherit unfree insecure;
    tty-autologin = ttyAutologin;
    vm-autologin = vmAutologin;
    user-shell = userShell;
    import-tree = importTree;
  };
}
