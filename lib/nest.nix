# The nest-mode EXECUTION engine (spec §4.2 mode taxonomy) — the live-edge counterpart to the receives
# registry. `receivers.nix` DECLARES the graft-site rule (the `at` placement, the `consumes` product, the
# derived `mode`) and resolves slot ≻ class; THIS module EXECUTES it on a resolved nest edge, turning a
# compiled row + the inner entity's product face into a mode-tagged CONTRIBUTION the caller places. The MLIR
# dialect-conversion reading: each mode is a lowering from the product's typed carrier into the outer
# assembly's dialect (content ⇒ a module list at the graft path, artifact ⇒ a rendered face, extend ⇒ an
# extendModules handle, value ⇒ a verbatim injection). The Backpack / F-ing-modules content-vs-artifact
# distinction is the spine: a CONTENT contribution carries the raw module face (unit body, still open to
# further merge at the mount), an ARTIFACT one carries a render THUNK (a sealed, already-elaborated result).
#
# NO EFFECT RUNTIME (Law A1): `executeNest` is a `mode` dispatch + a pure attrset assembly per arm — no
# fixpoint, no gen-graph walk (the dispatch that PICKED the row already ran in `resolveReceiver`). It reads
# the compiled row's DERIVED `mode` field (never re-derives from `consumes` — F1's canonical machine form is
# computed once, at registry compile). NIXPKGS-FREE: the sole nixpkgs crossing in the output stratum is
# output/terminal.nix; the engine wires module faces without evaluating them, so it never touches nixpkgs.
#
# THE §2.1 HOOK-SCOPING COROLLARY (the row contract, mirrored from receivers.nix): the engine may not force
# `inner.payload` during wiring — a contribution carries the payload lazily (the S-hashing law: a produced
# value never enters the structural fill, only the producing node's structural reference does). `at` is
# handed STRUCTURAL handles only — the paramPoint (`ctx.paramPoint`) and the inner's structural FACE with
# the payload STRIPPED (`removeAttrs inner [ "payload" ]`); the payload travels separately, forced only
# inside a contribution's lazy fields. See REFERENCE.md.
{
  prelude,
  productsLib,
}:
let
  # nest a module at an attr path — the fold's `place` (gen-edge `core.setAttrByPath`; output-modules.nix's
  # own `nestAtPath` twin). `[]` ⇒ the module verbatim (the []⇒flat convention: a merge places at the root),
  # else wrap under the path. Pure attrset assembly (A1) — the module VALUE stays a thunk under the wrap, so
  # a content contribution's placement never forces the payload. den-hoag has no public re-export of
  # gen-edge's `core.setAttrByPath`, so this is a local twin (the same local-twin note output-modules carries
  # for its own copy).
  nestAtPath =
    path: value:
    if path == [ ] then value else { ${builtins.head path} = nestAtPath (builtins.tail path) value; };

  # `placeSlice at slice` — graft each module of a content slice at the `at` path (output-modules.nix's
  # `placeSlice`). `at == [ ]` ⇒ the slice verbatim (flat, root merge); else each module is wrapped under the
  # path. The map keeps each module a thunk (nestAtPath does not force), so the placement is lazy.
  placeSlice = at: slice: if at == [ ] then slice else map (nestAtPath at) slice;

  # `executeNest { row; inner; ctx }` — the mode dispatch. `row` = a compiled receives row (or one element
  # of a `resolveReceiver` multi-winners list); `inner` = `{ product; payload; }` plus the inner's structural
  # FACE fields (name/kind/…); `ctx` = structural handles ONLY (§2.1 corollary — name/kind/slot/ids/
  # paramPoint, NO content). The engine reads the row's DERIVED `mode` (F1) and hands the payload lazily into
  # the arm's contribution — it may not force `inner.payload` during wiring.
  executeNest =
    {
      row,
      inner,
      ctx,
    }:
    let
      # the inner's STRUCTURAL face handed to `at` — the payload STRIPPED (§2.1: `at` sees structure, never
      # the produced content). `ctx.paramPoint` is the placement's first argument (the paramPoint handle).
      innerFace = removeAttrs inner [ "payload" ];
      atPath = row.at ctx.paramPoint innerFace;
    in
    # THE CONSUMES/PRODUCT MISMATCH GUARD: the inner's product face must EXACTLY match the row's `consumes`.
    # A mismatch aborts NAMED, naming both products. THE SEAM: the single-step conversion registry
    # (den.conversions, §4.1) consult REPLACES this hard throw for a registered (produces, consumes) pair —
    # a mismatch with a conversion materializes through its `via`; only an unregistered mismatch throws. That
    # consult is the next step; here every mismatch is an error.
    if inner.product != row.consumes then
      throw "den.nest: inner produces '${inner.product}' but the receiver consumes '${row.consumes}' — no conversion (§4.1) registered for the pair"
    # CONTENT mode: the inner's ModulesInfo module list grafted at the `at` path. The contribution carries the
    # PLACED modules (`placeSlice atPath inner.payload`) — flat for `at = [ ]`, wrapped under the path
    # otherwise — plus the `at` path as provenance. The caller places the contribution; the engine performs
    # only the pure at-path wrap (nestAtPath), never a module eval.
    else if row.mode == "content" then
      {
        mode = "content";
        at = atPath;
        modules = placeSlice atPath inner.payload;
      }
    else
      throw "den.nest: unhandled receive mode '${row.mode}' — the mode-execution engine handles no such arm";
in
{
  inherit executeNest;
}
