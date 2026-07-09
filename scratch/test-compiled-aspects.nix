let
  flake = builtins.getFlake "path:///home/sini/Documents/repos/sini/nix-config";
  denHoag = builtins.getFlake "path:///home/sini/Documents/repos/den-hoag";
  nixpkgs = flake.inputs.nixpkgs-unstable or flake.inputs.nixpkgs;
  lib = nixpkgs.lib;
  inputs = flake.inputs;
  userModules = [
    { _module.args = { inherit lib inputs; }; }
    (flake.inputs.import-tree /home/sini/Documents/repos/sini/nix-config/modules)
  ];
  v1 = denHoag.compat.evalV1 userModules;
  compiled = denHoag.compat.compileFull v1;
in
{
  axonKeys = builtins.attrNames compiled.entities.instances.host.axon-01;
  axonVal = compiled.entities.instances.host.axon-01;
}
