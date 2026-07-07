# den-compat LEGACY surface: `provides` (self-contained, tagged — the severance surface, §2.1).
# The full v1 `provides.<name>` surface desugared to `neededBy` under §B4a; the `nameMatches`
# legacy-module-local predicate over registry entries (lifted through `sel.when`); resolution-time
# dispatch; the surface sentinel. With this module absent, any use of `provides` is a definition-time
# error (Law C5) — hence "removable without touching anything else".
#
# Task 0 scaffold: the `_denCompat.legacy` tag makes severability testable now (compat-legacy-severed,
# C5). The options + config (the desugar) land in Task 4.
{ denHoag, prelude, errors, ... }:
{
  _denCompat.legacy = "provides";
  # options + config land in Task 4; the tag makes severability testable now.
}
