# The JSON-safe enumeration VIEW of the forNixd projections (§ enumerate) — the WIRE view of ONE projection
# (forNixd is the IN-PROCESS view a nixd worker walks; this is what the MCP server serves over the wire).
# The forNixd projections are
# built for nixd's IN-PROCESS walk — an option leaf's `.type` is a gen-schema/nixpkgs type RECORD carrying
# functions (`check`/`merge`/`getSubOptions`) and an aspect node's `.type.getSubOptions` is itself a
# function — so `builtins.toJSON` (what the MCP enumeration server's `nix eval --json` subprocess runs)
# cannot serialize them: a raw projection tree hits "cannot convert a function to JSON". This view
# re-projects each tree into a JSON-safe ENUMERATION shape an agent reads over the wire: an option leaf
# keeps its `_type`/description/type-NAME/(JSON-safe default), every function dropped; an aspect node
# descends ONE level through `getSubOptions {}` to list its settings; the gen surface (already flat member
# names + string `functionArgs` formals) passes through. Pure builtins (no prelude/gen dep) so `lib/**`
# stays nixpkgs-lib-free — it mirrors options-projection's own pure walk, one abstraction layer above it.
{ }:
let
  # A gen-merge option leaf: an attrset tagged `_type == "option"` (same predicate options-projection walks).
  isOpt = v: builtins.isAttrs v && v ? _type && v._type == "option";

  # A type record's display NAME — the JSON-safe scalar an agent completes on (`str`/`submodule`/`attrsOf`/…).
  # Reading `.name` forces only that string field, never the type's `check`/`merge`/`getSubOptions` functions.
  # A typeless leaf (a gen-lib member, or a leaf whose refined type was stripped to null) projects `null`.
  typeName = t: if t == null then null else (t.name or "unknown");

  # A STRUCTURAL JSON-serializability probe that never calls `toJSON` — `toJSON` on a function is an
  # UNCATCHABLE eval error (tryEval does NOT trap it, unlike a `throw`), so the probe must rule functions
  # out structurally FIRST. `tryEval` guards a throwing node at each level (a poisoned default is dropped,
  # not propagated); a function anywhere in the value fails the probe; scalars/plain attrs/lists pass.
  deepJsonSafe =
    v:
    let
      t = builtins.tryEval v;
    in
    if !t.success then
      false
    else if builtins.isFunction t.value then
      false
    else if builtins.isAttrs t.value then
      builtins.all deepJsonSafe (builtins.attrValues t.value)
    else if builtins.isList t.value then
      builtins.all deepJsonSafe t.value
    else
      true;

  # `default` is included ONLY when it is JSON-safe (the structural probe above) — a scalar or plain
  # attrset/list default rides through; a function-valued, poisoned, or derivation-laden default is dropped
  # (an enumeration serves names + shapes + concrete simple defaults, never a materialized complex value).
  defaultAttr =
    opt: if opt ? default && deepJsonSafe opt.default then { default = opt.default; } else { };

  # One option leaf → its JSON-safe enumeration record: `_type`/description/type-NAME, plus `default` when
  # JSON-safe and `formals` when present (a gen-lib member carries `functionArgs` formals, not a `.type`).
  cleanLeaf =
    opt:
    {
      _type = "option";
      description = opt.description or "";
      type = typeName (opt.type or null);
    }
    // defaultAttr opt
    // (if opt ? formals then { formals = opt.formals; } else { });

  # The tree walk (mirrors options-projection's own walk): sanitize at each option leaf, recurse through
  # every other attrset, pass non-attrs through. A leaf's `.type` is reduced to its NAME here — no descent
  # into a submodule leaf's `getSubOptions` (BOUNDED: den option trees nest recursively, so the agent
  # completes PATHS from the attrset nesting + each option's type-name/description, never a fully-expanded
  # — possibly non-terminating — type tree).
  cleanTree =
    node:
    if isOpt node then
      cleanLeaf node
    else if builtins.isAttrs node then
      builtins.mapAttrs (_: cleanTree) node
    else
      node;

  # One aspect node → its JSON-safe record: description + its settings. This is the ONE place a submodule is
  # descended, because the `den.aspects.list` tool's contract IS "aspect names + per-aspect settings": force
  # the synthesized settings leaves via `getSubOptions {}` ONE level (bounded — settings are a flat §2.6
  # field record) and clean each. Declaration-only (options-projection synthesizes the leaves from static
  # `{ default; merge ? }` records), so this stays fx-pipeline-free like the projection it reads.
  cleanAspect = node: {
    _type = "option";
    description = node.description or "";
    type = "submodule";
    settings = builtins.mapAttrs (_: cleanLeaf) (node.type.getSubOptions { });
  };
in
{
  # Sanitize a forNixd option-leaf tree (`den` or `gen` — both are option-leaf trees) to JSON-safe shape.
  optionsView = cleanTree;
  # Sanitize a forNixd `den-aspects` registry: aspect name → node, each descended one level for its settings.
  aspectsView = builtins.mapAttrs (_: cleanAspect);
  # The convenience over a WHOLE forNixd surface: the three JSON-safe trees keyed exactly as forNixd keys
  # them (`den` / `den-aspects` / `gen`). This is the value a fleet exposes for the MCP enumeration server —
  # every leaf serializes cleanly under `nix eval --json`, functions dropped, aspect settings listed.
  fromForNixd = surface: {
    den = cleanTree surface.den;
    "den-aspects" = builtins.mapAttrs (_: cleanAspect) surface."den-aspects";
    gen = cleanTree surface.gen;
  };
}
