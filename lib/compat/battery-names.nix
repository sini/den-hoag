# The SINGLE source of the gateable den-compat battery names (7 corpus + 5 coverage ports), shared between
# `batteries.nix`'s provisioned `config.den.batteries` set and the `den.features.battery.<name>` default
# record (`default.nix`). A new battery adds its name HERE once — it then gains its removability flag and
# enters the `unknownBattery` totality boundary automatically (a `battery.<typo>` override trips the named
# abort, never a silent no-op). Values are unused sentinels (`mapAttrs (_: _: true)` builds the flag record;
# `filterAttrs` reads the keys) — the set is the name carrier only.
{
  define-user = null;
  hostname = null;
  primary-user = null;
  host-aspects = null;
  "inputs'" = null;
  "self'" = null;
  unfree = null;
  insecure = null;
  tty-autologin = null;
  vm-autologin = null;
  user-shell = null;
  import-tree = null;
}
