# Standalone (non-flake) entry. Flake consumers use the `.lib` output. Mirrors gen-class's
# default.nix: every dep arg defaults to the dep's OWN root entry, which self-wires its transitive
# deps from its own flake.lock. No hand-threading; gen-rebuild never fetched here (only gen-resolve
# consumes it, from gen-resolve's own lock — spec §5).
#
# A dep's root default.nix is either a bare-value lib (gen-prelude / gen-algebra / gen-select) or a
# self-resolving FUNCTION of fully-defaulted args (every other dep). `dep` normalizes both to the lib
# value: apply `{ }` to the function form, pass the value form through — so each default resolves to a
# forced lib, not a lambda.
{
  lock ? builtins.fromJSON (builtins.readFile ./flake.lock),
  fetch ? name: builtins.fetchTree lock.nodes.${lock.nodes.root.inputs.${name}}.locked,
  dep ? name: (v: if builtins.isFunction v then v { } else v) (import (fetch name)),
  prelude ? dep "gen-prelude",
  algebra ? dep "gen-algebra",
  types ? dep "gen-types",
  merge ? dep "gen-merge",
  schema ? dep "gen-schema",
  aspects ? dep "gen-aspects",
  graph ? dep "gen-graph",
  scope ? dep "gen-scope",
  resolve ? dep "gen-resolve",
  select ? dep "gen-select",
  bind ? dep "gen-bind",
  dispatch ? dep "gen-dispatch",
  class ? dep "gen-class",
  edge ? dep "gen-edge",
  product ? dep "gen-product",
  settings ? dep "gen-settings",
  demand ? dep "gen-demand",
  pipe ? dep "gen-pipe",
  flake ? dep "gen-flake",
}:
import ./lib {
  inherit
    prelude
    algebra
    types
    merge
    schema
    aspects
    graph
    scope
    resolve
    select
    bind
    dispatch
    class
    edge
    product
    settings
    demand
    pipe
    flake
    ;
}
