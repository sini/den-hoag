{
  inputs = {
    gen.url = "github:sini/gen";
    den-hoag.url = "path:..";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    # home-manager + nix-darwin: the behavioral-migration scaffold imports
    # `home-manager.nixosModules.home-manager` into every crossed host so a homeManager-classed user's
    # config realizes (`igloo.home-manager.users.<u>` → the `tuxHm`/`pinguHm` helpers), and stages
    # `nix-darwin` for the darwin (`apple`) crossing. Both follow the CI nixpkgs so one nixpkgs spans the
    # crossing.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # flake-parts — the HOST MATERIAL the root-entry suite's gen-flake arm hands the standalone root
    # (`internal.mkFlakeTerminal` is gated on it, and a host material is a root's to supply). Declared as
    # a FOLLOWS of the tree den-hoag's own lock already names, so this is a declaration of content the CI
    # eval already carries: no lock node is added and the resolved revision is the one den-hoag threads.
    flake-parts.follows = "den-hoag/gen-flake/flake-parts";
  };

  outputs =
    inputs@{
      gen,
      den-hoag,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      denHoag = den-hoag.lib;
      # The home-manager NixOS module — imported into every crossed host by the migration scaffold's
      # `den.default.nixos.imports`, so `igloo.home-manager.users.<u>` realizes (tuxHm/pinguHm). The
      # nix-darwin flake (carrying `.lib.darwinSystem`) is staged for the darwin (`apple`) crossing.
      homeManagerModule = home-manager.nixosModules.home-manager;
      darwinFlake = nix-darwin;
      # den-compat (L4) shim — the v1-surface-accepting compiler + parity helpers, for the shim-law
      # suites (compat-scaffold, C1–C6). Rides den-hoag's own nix-unit CI (den-hoag = `path:..`).
      denCompat = den-hoag.compat;
      # The den-hoag FLAKE-PARTS BRIDGE (den-hoag's `flakeModule` output = bridge.nix + builtins +
      # batteries) — the REAL consumer path (`imports = [ inputs.den.flakeModule ]`). The behavioral
      # migration scaffold (`ci/tests/_lib/den-compat-test.nix`) drives a fleet through THIS module so it
      # gets the bridge's v1DeepMerge for `den.aspects`/`den.default` (multi-module merge) + the crossed
      # `config.flake.{nixosConfigurations,darwinConfigurations}` output faces — which the mkDen-direct
      # path structurally lacks.
      denHoagFlakeModule = den-hoag.flakeModule;
      nixpkgsLib = import "${inputs.nixpkgs}/lib";
      # Source tree of the den-hoag flake, for the A1 zero-machinery source scan (reads
      # lib/**.nix text). The lib itself is pure/path-free, so the scan needs the store path.
      denHoagSrc = "${inputs.den-hoag}";
    in
    gen.lib.mkCi {
      inherit inputs;
      name = "den-hoag";
      testModules = ./tests;
      # `nixpkgs` (the FLAKE — carrying `.lib.nixosSystem`) is threaded through for the end-to-end
      # terminal-crossing test (den-hoag's ONE nixpkgs boundary); every other suite ignores it (`...`).
      specialArgs = {
        inherit
          denHoag
          denCompat
          denHoagFlakeModule
          homeManagerModule
          darwinFlake
          nixpkgsLib
          denHoagSrc
          ;
        nixpkgs = inputs.nixpkgs;
        # the flake-parts FLAKE — the root-entry suite's gen-flake arm supplies it to the standalone
        # root, which carries none of its own; every other suite ignores it (`...`).
        flakeParts = inputs.flake-parts;
      };
      extraModules = [
        (
          { lib, genInputs, ... }:
          {
            perSystem =
              { system, ... }:
              {
                # THE TEST INSTRUMENT, PINNED. CI used to invoke `nix run nixpkgs#nix-unit`, which resolves
                # `nixpkgs` from the DEFAULT FLAKE REGISTRY at run time — a moving branch, not this repo's
                # lock. That is a correctness problem, not hygiene: den-hoag's gate rests on nix-unit's
                # ERROR CHANNEL, and that channel FAILS OPEN on omission — an `expectedError` with no `type`
                # means "any kind", with no `msg` means "any message". A silent semantics change in a future
                # nix-unit relaxes every expectedError assertion at once, and the suite goes GREENER, not
                # redder — the direction nobody investigates. Exposing the LOCKED nix-unit as a package makes
                # the version this repository's decision (it moves only on a `flake.lock` bump) and makes CI
                # run the SAME store path as the devshell and the pre-commit `ci` hook, which both already
                # took it from the lock. `genInputs.nix-unit` is exactly what gen's `ci/flakeModule.nix`
                # resolves, because this flake declares no `nix-unit` input of its own.
                # `error-channel.nix` pins the channel's SEMANTICS; this pins the instrument.
                packages = lib.optionalAttrs (genInputs.nix-unit.packages ? ${system}) {
                  nix-unit = genInputs.nix-unit.packages.${system}.default;
                };

                # THE MARKDOWN ARM'S CORRECTION. gen's `ci/flakeModule.nix` asks for five mdformat plugins
                # by writing them into `programs.mdformat.package`, but treefmt-nix computes
                # `finalPackage = cfg.package.withPlugins cfg.plugins` and `cfg.plugins` DEFAULTS TO `_: [ ]`
                # — so the pre-wrapped package is re-wrapped with an EMPTY plugin list and all five are
                # silently dropped. Measured: the mdformat treefmt actually invoked is byte-identical to
                # plain `pkgs.mdformat` (zero plugin paths in its closure). `plugins` is the option
                # treefmt-nix honours, so it is set here.
                #
                # ONLY `mdformat-frontmatter` is enabled, and the omission is deliberate. Without it mdformat
                # reads a leading `---` as a thematic break and the YAML frontmatter under it as a setext
                # heading — which is how `.agents/skills/beads/SKILL.md` lost its `name`/`description` block
                # (the fields skill discovery reads) to a formatting commit. Enabling gen's other four was
                # measured against this tree and REJECTED: `mdformat-gfm` reflows the tables in
                # `lib/compat/parity/ledger.md` and deletes 4,551 non-whitespace characters from it.
                #
                # `number` keeps an ordered list's authored ordinals instead of renumbering every item to
                # `1.`. This repo's markdown is read as RAW TEXT by agents, where a five-step procedure shown
                # as five `1.`s is materially worse than `1.`–`5.`; it is also what makes the formatted form
                # of CLAUDE.md's standing directives equal to their authored form, so the gate stops asking
                # for a rewrite of the file every agent reads first.
                treefmt.programs.mdformat = {
                  plugins = p: [ p.mdformat-frontmatter ];
                  settings.number = true;
                };
              };
          }
        )
      ];
    };
}
