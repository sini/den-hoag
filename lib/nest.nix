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

  # `mkContribution mode extra` — every arm's contribution is `{ mode; } // <arm fields>`, so the mode tag
  # is written ONCE and the arms differ only in their payload fields. The arm fields carry the LAZY faces
  # (the placed modules / the injected value / the render thunk), so a contribution's shape (mode + attr
  # names) is forcible without forcing the payload.
  mkContribution = mode: extra: { inherit mode; } // extra;

  # `executeNest { row; inner; ctx; conversions ? { } }` — the mode dispatch. `row` = a compiled receives row
  # (or one element of a `resolveReceiver` multi-winners list); `inner` = `{ product; payload; }` (or the
  # prebuilt `artifactRef` arm) plus the inner's structural FACE fields (name/kind/…); `ctx` = structural
  # handles ONLY (§2.1 corollary — name/kind/slot/ids/paramPoint, NO content); `conversions` = the compiled
  # single-step conversion table (den.conversions, §4.1), threaded at CALL time (the receivers pattern — the
  # engine holds no tables). The engine reads the row's DERIVED `mode` (F1) and hands the payload lazily into
  # the arm's contribution — it may not force `inner.payload` during wiring.
  executeNest =
    {
      row,
      inner,
      ctx,
      conversions ? { },
    }:
    let
      # the inner's STRUCTURAL face handed to `at` — the payload STRIPPED (§2.1: `at` sees structure, never
      # the produced content). `ctx.paramPoint` is the placement's first argument (the paramPoint handle).
      innerFace = removeAttrs inner [ "payload" ];
      atPath = row.at ctx.paramPoint innerFace;

      # CONTENT dispatch on a payload already known to be the row's mode (post-conversion or exact-match): the
      # graft is over the derived `mode`. `content` places the module list at `at`; a non-content mode under
      # this seam is unhandled (artifact/extend arrive next tasks — leave the seam marked). `payload` is the
      # (possibly converted) module list.
      graftMode =
        payload:
        if row.mode == "content" then
          # CONTENT mode: the module list grafted at `at` — flat for `at = [ ]`, wrapped under the path
          # otherwise. The caller places the contribution; the engine performs only the pure at-path wrap.
          mkContribution "content" {
            at = atPath;
            modules = placeSlice atPath payload;
          }
        else
          throw "den.nest: unhandled receive mode '${row.mode}' — the mode-execution engine handles no such arm";

      # THE CONVERSIONS CONSULT (§4.1): on a (produces, consumes) mismatch, EXACTLY ONE single-step lookup in
      # the compiled table (`"<from>-><to>"`). Found ⇒ `via` applied LAZILY to the payload, the contribution
      # proceeds under the row's mode; not found ⇒ the named mismatch throw. NO chain search — the MLIR-style
      # multi-hop materialization is rejected for determinism (a needed composite is its own registered pair).
      pairKey = "${inner.product}->${row.consumes}";
    in
    # VALUE mode (the prebuilt ArtifactRef arm, §4.1): an `inner` carrying the `artifactRef` wrapper is the
    # short-circuited prebuilt value — injected VERBATIM, never evaluated, never converted (conversions never
    # apply to the prebuilt arm; ArtifactRef acceptance at consumes = P is DEFINITIONAL). Checked FIRST, before
    # the exact-match/conversion arms: the wrapper's `inner.product` is the `ArtifactRef <face>` name, which
    # never equals the row's bare `consumes`, so those arms would misroute it. A wrapped-face MISMATCH
    # (`artifactRef.product` ≠ the row's consumes) sets the `unrealizedCast` marker — a trace-visible node,
    # NEVER an eval failure (§4.1 verbatim) — the value still rides verbatim.
    if inner ? artifactRef then
      mkContribution "value" (
        {
          at = atPath;
          inherit (inner.artifactRef) value;
        }
        // (
          if inner.artifactRef.product != row.consumes then
            {
              # the prebuilt face does not match the row's consumes — an unrealized cast (a trace node), not a
              # throw: the value is injected as-is and the mismatch is recorded for the trace to surface.
              unrealizedCast = {
                from = inner.artifactRef.product;
                to = row.consumes;
              };
            }
          else
            { }
        )
      )
    # EXACT MATCH: the inner's product face equals the row's `consumes` — graft directly under the row's mode.
    else if inner.product == row.consumes then
      graftMode inner.payload
    # MISMATCH: consult the single-step conversion table for the (produces, consumes) pair. Found ⇒ materialize
    # LAZILY through `via` and proceed under the row's mode; not found ⇒ the named throw naming both products.
    else if conversions ? ${pairKey} then
      graftMode (conversions.${pairKey}.via inner.payload)
    else
      throw "den.nest: inner produces '${inner.product}' but the receiver consumes '${row.consumes}' — no conversion (§4.1) registered for the pair '${pairKey}'";
in
{
  inherit executeNest;
}
