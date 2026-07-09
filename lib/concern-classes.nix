# Compile the classes concern (`den.classes.<name>`) into class config records (spec §2.4). A class
# registration declares how its members are wrapped and crossed to a system: the `wrap.mergeStrategy`
# → gen-bind `defaultMergeStrategy` adapter, the split-return `validators` toggle (r2 consumer
# obligation 6), the terminal `instantiate` (the gen-flake crossing, output/terminal.nix), and the
# `share.core` host-class boundary opt-in (consumed by the A10 class-share output assembly).
#
# NO EFFECT RUNTIME: `compile` is one `mapAttrs` — field renames + defaults, no algorithm (Law A1).
# The `coreStrategy` field is the A10 seam (default identity here; gen-class `applyCoreFixed` drops in
# without restructuring the output path).
{
  prelude,
  bind,
}:
{
  # classes           : { <name> = { wrap ? {}; instantiate ? <default>; share ? {}; coreStrategy ? id; }; }
  # defaultInstantiate : the terminal used when a class declares none (den-hoag's nixpkgs-free `collect`,
  #                      or a nixpkgs-bound `crossNixos` supplied by a user).
  compile =
    {
      classes,
      defaultInstantiate,
    }:
    prelude.mapAttrs (name: c: {
      inherit name;
      wrap = c.wrap or { };
      defaultMergeStrategy = (c.wrap or { }).mergeStrategy or bind.mergeStrategy.bindWins;
      validators = (c.wrap or { }).validators or true;
      instantiate = c.instantiate or defaultInstantiate;
      share = {
        core = (c.share or { }).core or false;
      };
      # A10 seam (spec §2.10 class-share output assembly): the per-class module-preparation strategy
      # applied before the terminal wraps a member. Identity by default; A10 supplies an adapter
      # lambda over gen-class (`modules: (class.applyCoreFixed { inherit core modules; }).config`),
      # never bare `applyCoreFixed` (its signature is `{ core; modules; }`, not modules→modules).
      coreStrategy = c.coreStrategy or (m: m);
    }) classes;
}
