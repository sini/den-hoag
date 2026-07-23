# den.lib.nh — v1's `nh` app-family builder (den nix/lib/nh.nix, pin a2f4b60), ported ~verbatim. Config-
# wired: reads `den.hosts`/`den.homes` off the fleet config, so it is bound at the bridge seam (where
# `config.den` + nixpkgs `lib` are both in scope), NOT the config-less migrationLib. The `os`/`hm` builders
# emit `nh os|home` runner apps (`writeShellApplication`) per host/home member; `denPackages`/`denShell`/
# `denApps` are `args: pkgs: …` APPLIED (2-arg) builders forced only at call time — the corpus never applies
# them, so this surface is parity-neutral (lazy lib attrs).
{ lib, den, ... }:
let

  mkApp =
    getCommand:
    {
      outPrefix ? [ ],
      fromFlake ? true,
      fromPath ? ".",
      defaultAction ? "build",
      defaultArgs ? [ ],
    }:
    pkgs: item:
    pkgs.writeShellApplication {
      name = item.name;
      runtimeInputs = [ pkgs.nh ];
      text =
        let
          command = getCommand item;
          attr = if command == "home" then "" else lib.concatStringsSep "." (outPrefix ++ item.intoAttr);
          from =
            (
              if fromFlake then
                [ "${fromPath}#${attr}" ]
              else
                [
                  "--file"
                  fromPath
                  attr
                ]
            )
            ++ (lib.optionals (command == "home") [
              "-c"
              item.name
            ]);

          args = lib.concatStringsSep " " (from ++ defaultArgs);
        in
        ''
          action="''${1:-${defaultAction}}"
          shift || true
          exec nh ${command} "$action" ${args} "$@"
        '';
    };

  os = mkApp (
    host:
    {
      darwin = "darwin";
      nixos = "os";
    }
    .${host.class}
  );
  hm = mkApp (_: "home");

  hosts = lib.concatMap lib.attrValues (lib.attrValues den.hosts);
  # CEILING — den-hoag declares no `homes` registry (the bridge declares `options.hosts` only; ingest reads
  # `v1Decls.homes or {}`), so a bare `den.homes` read THROWS. `den.homes or { }` is the ceiling mechanism:
  # absent registry → `homes = []` → `homeApps = []`, which is CORRECT for a nixos-only fleet (no home
  # members). v1's `den.homes` would equally yield `{}` for a homeless fleet; the home-app family is latent
  # until the homes registry lands (its own board rung). This is the sole deviation from byte-verbatim.
  homes = lib.concatMap lib.attrValues (lib.attrValues (den.homes or { }));

  hostApps = args: pkgs: map (os args pkgs) hosts;
  homeApps = args: pkgs: map (hm args pkgs) homes;
  denApps = args: pkgs: (hostApps args pkgs) ++ (homeApps args pkgs);

  denShell =
    args: pkgs:
    pkgs.mkShell {
      buildInputs = [ pkgs.nh ] ++ (denApps args pkgs);
    };

  denPackages =
    args: pkgs:
    lib.listToAttrs (
      map (a: {
        name = a.name;
        value = a;
      }) (denApps args pkgs)
    );

in
{
  inherit
    denPackages
    denShell
    homeApps
    hostApps
    denApps
    ;
}
