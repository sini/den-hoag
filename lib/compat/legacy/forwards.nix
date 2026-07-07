# den-compat LEGACY surface: `forwards` (self-contained, tagged — the severance surface, §2.1).
# Tier-1 static forwards → plain `deliver`; adapter-bearing complex forwards → inert gen-edge
# `synthesize` source records + this module's `interpret.synthesize` (threaded into den-hoag's single
# `materialize` call via the shipped `den.interpret` raw seam). This is the ONE Law-C2 relaxation: a
# `synthesize` record is inert DATA whose interpreter runs later inside `materialize` — the shim never
# evaluates it, reads the scope graph, or reads resolved state. With this module absent, any use of
# `forwards` / class `forwardTo` / `batteries.forward` is a definition-time error (Law C5).
# (Tier-2 derived-children NTA: NOT implemented — the corpus census found no such consumer; PIN.md.)
#
# Task 0 scaffold: the `_denCompat.legacy` tag makes severability testable now. The desugar +
# `interpret.synthesize` land in Task 5.
{ denHoag, prelude, errors, ... }:
{
  _denCompat.legacy = "forwards";
  # options + config + interpret.synthesize land in Task 5; the tag makes severability testable now.
}
