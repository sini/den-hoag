let
  f = builtins.getFlake "path:///home/sini/Documents/repos/sini/nix-config";
  flake-module = import /home/sini/Documents/repos/den-hoag/lib/compat/flake-module.nix {
    denHoag = {};
    prelude = f.inputs.nixpkgs.lib;
    schema = import /home/sini/Documents/repos/den-hoag/lib/schema.nix { prelude = f.inputs.nixpkgs.lib; types = f.inputs.nixpkgs.lib.types; };
    compile = import /home/sini/Documents/repos/den-hoag/lib/compat/compile.nix {
      prelude = f.inputs.nixpkgs.lib;
      ingest = import /home/sini/Documents/repos/den-hoag/lib/compat/ingest.nix { prelude = f.inputs.nixpkgs.lib; };
      declare = import /home/sini/Documents/repos/den-hoag/lib/declare.nix {
        prelude = f.inputs.nixpkgs.lib;
        scope = import /home/sini/Documents/repos/den-hoag/lib/scope.nix { prelude = f.inputs.nixpkgs.lib; };
      };
      errors = import /home/sini/Documents/repos/den-hoag/lib/compat/errors.nix { lib = f.inputs.nixpkgs.lib; };
      sentinels = import /home/sini/Documents/repos/den-hoag/lib/compat/sentinels.nix { lib = f.inputs.nixpkgs.lib; };
    };
    legacy = import /home/sini/Documents/repos/den-hoag/lib/compat/legacy/default.nix { lib = f.inputs.nixpkgs.lib; };
    errors = import /home/sini/Documents/repos/den-hoag/lib/compat/errors.nix { lib = f.inputs.nixpkgs.lib; };
  };
  # evaluate user modules just like flake-module does
  userModules = [ { den = f.nixosConfigurations.cortex.config.den; } ];
  v1Config = flake-module.evalV1 userModules;
  desugared = flake-module.desugarLegacy v1Config;
  # Let's import compile directly to inspect its outputs
  compile = import /home/sini/Documents/repos/den-hoag/lib/compat/compile.nix {
      prelude = f.inputs.nixpkgs.lib;
      ingest = import /home/sini/Documents/repos/den-hoag/lib/compat/ingest.nix { prelude = f.inputs.nixpkgs.lib; };
      declare = import /home/sini/Documents/repos/den-hoag/lib/declare.nix {
        prelude = f.inputs.nixpkgs.lib;
        scope = import /home/sini/Documents/repos/den-hoag/lib/scope.nix { prelude = f.inputs.nixpkgs.lib; };
      };
      errors = import /home/sini/Documents/repos/den-hoag/lib/compat/errors.nix { lib = f.inputs.nixpkgs.lib; };
      sentinels = import /home/sini/Documents/repos/den-hoag/lib/compat/sentinels.nix { lib = f.inputs.nixpkgs.lib; };
  };
  compiled = compile desugared;
in
  builtins.typeOf (builtins.head compiled.aspects.__default.includes).includes
