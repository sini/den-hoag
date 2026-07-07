# den-compat compile core (Law C2 — pure compilation). `compile : v1Decls → den-hoag concern
# DECLARATIONS`: no evaluation machinery, no scope-graph reads, no resolved-state reads, and no edges
# constructed on this path (a `deliver` desugars to a delivery DECLARATION — the firing scope is
# unknowable at compile time). Every algorithm (fold, toposort, traversal, channel run, selector
# match) lives in den-hoag or an L1/L2 lib; this file only rewrites vocabulary.
#
# Task 0 stub: the five-key declaration shape the four-concern API consumes. The desugar for each key
# lands across Tasks 1–5 (entities/aspects/classes = ingestion + surface table; policies = deliver +
# route/provide sugar; channels = the pipe stage vocabulary).
# `prelude` reserved — the compile/error surface grows across Tasks 1–9.
{ prelude }:
{ ... }@v1Decls:
{
  entities = { }; # host/user/env registry declarations (structural only — Task 1)
  aspects = { }; # den-hoag aspect registry entries (Task 1)
  policies = { }; # den-hoag rule declarations (Tasks 1–2)
  channels = { }; # gen-pipe channel declarations (Task 3)
  classes = { }; # den-hoag class registrations (Task 1)
}
