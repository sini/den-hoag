# The v1 class-key SPELLING map (camelCase v1 attr key → grounded den-hoag class name). v1 keys
# home-manager content under `homeManager` (pin 11866c16 nix/lib/entities/home.nix:124
# `class = strOpt "…" "homeManager"`; nix/denTest.nix:108 `den.schema.user.classes = ["homeManager"]`),
# whereas den-hoag registers the grounded `home-manager` class. This is the SINGLE source for that
# rename, imported by BOTH compile.nix (the static/runtime `groundKeys`/`groundClassName` grounding)
# AND flake-module.nix (the §2.2 raw-totality discriminator's `groundK`, so a fn-valued class facet
# spelled the v1 way grounds to its registered class before the malformed-fn membership test). Identity
# for every already-grounded name; extended as the corpus surfaces more (harness-driven).
{
  homeManager = "home-manager";
}
