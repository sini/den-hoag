# den v1 `flakeModules.dendritic` (denful/den nix/dendritic.nix): the den flakeModule, dendritic-flavored.
# den's source is a 4-line flake-parts module doing two things:
#   flake-file.inputs.den.url = lib.mkDefault "github:denful/den";   # (i) inert flake-file generator write
#   imports = [ (inputs.den.flakeModule or { }) ];                    # (ii) the LOAD-BEARING payload
# Line (ii) pulls in den's default flakeModule — the full `den.*` option surface (the fleet, the bridge).
# `dendritic ⊃ default`: importing it is exactly importing `flakeModule`. The 6-of-7 dendritic corpus
# importers guard it `(inputs.den.flakeModules.dendritic or { })`, so when the key is absent the `or {}`
# silently DROPS the whole den flakeModule → downstream `option 'den' does not exist`. Providing this key
# lands the den surface (den-hoag's `inputs.den` = den-hoag itself under the corpus's `--override-input`).
#
# FORM B (decoupled): den's line (i) is DROPPED. It is a `mkDefault` write to the external `flake-file`
# (mightyiam/vic) tool's option namespace, consumed ONLY by that generator's `write-flake` output — INERT
# for `nixosConfigurations`/`homeConfigurations` eval. Every dendritic corpus config self-sets `flake-file.
# inputs.den.url` (a plain `den.url = …` overriding den's `mkDefault`), so den's line is provably inert
# across the corpus. Keeping only line (ii) is the minimal faithful reproduction of what the corpus needs,
# carries no external-tool option surface / URL literal, and is strictly more robust (line (i)'s Form A
# would error `option 'flake-file' does not exist` on a config importing dendritic WITHOUT flake-file; this
# never can).
{ inputs, ... }:
{
  imports = [ (inputs.den.flakeModule or { }) ];
}
