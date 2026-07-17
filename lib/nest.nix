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

  # `checkSingular { row; edges; mount ? "<mount>" }` (§4.2 arity, the WIRING-TIME half) — the singular
  # live-edge enforcement at wiring, on the LIVE edge set (post-`when`): "two predicate-differing edges into a
  # singular mount both firing throws". The `when` filter is applied BEFORE the check — an edge is LIVE iff
  # its `when` fired (`e.when or true` — an unconditional edge, no `when`, is always live; a conditional edge
  # rides its already-resolved fired flag). A `singular` mount with MORE than one live edge aborts NAMED
  # (naming the mount + every live edge id); `arity = "many"` never throws.
  # RETURN CONTRACT: the post-`when` live set on the SINGULAR path; the input `edges` UNCHANGED on the `many`
  # path (the `when` filter is a singular-arity concern only — a `many` mount admits every edge, so the
  # unfiltered input rides through). This is a deliberate asymmetry vs `receivers.checkSingularDefinition`,
  # which returns `intents` UNFILTERED on every pass path (it inspects the unconditional subset only to decide
  # the throw, never to reshape the result). The DEFINITION-TIME half (the unconditional-pair static check) is
  # `receivers.checkSingularDefinition` — each check lives where its phase-data does (§4.2 "both depths").
  checkSingular =
    {
      row,
      edges,
      mount ? "<singular mount>",
    }:
    let
      live = builtins.filter (e: e.when or true) edges;
    in
    if row.arity or "many" != "singular" then
      edges
    else if builtins.length live > 1 then
      throw "den.nest: singular mount '${mount}' has ${toString (builtins.length live)} live edges [ ${
        builtins.concatStringsSep " " (map (e: e.id) live)
      } ] — a singular arity admits at most one live edge (§4.2)"
    else
      live;

  # `bindArgs argEnv fnModule` (§4.8 adapt) — bind ONLY the functionArgs-declared args of a function-module,
  # LAZILY. `intersectAttrs (functionArgs fnModule) argEnv` keeps exactly the args the fn DECLARES (a
  # `{ osConfig, ... }:` module binds `osConfig`, an undeclared arg in `argEnv` is never selected, so it
  # never forces); a non-`{…}:` fn (`_:`, empty functionArgs) binds nothing. The module is applied with the
  # bound args — the `...` in a real class module swallows the rest the mount supplies. The BINDING at a live
  # mount happens in the families step; this is the pure binder the `adaptEnv` rider is applied through.
  # ArgsInfo (content-mode, non-nestable — `checkConsumes` blocks it as a `consumes`) is the arg-environment
  # product vocabulary; `adapt` is its legal consumer.
  bindArgs =
    argEnv: fnModule: fnModule (builtins.intersectAttrs (builtins.functionArgs fnModule) argEnv);

  # `executeDefer { record }` (§4.8 defer / R6) — the reconciled defer contract. `record` is
  # `{ needs = [ paths ]; then = vals: config; }`; the contribution is the INERT `{ mode = "defer"; needs;
  # thenFn; }` record — NO terminal consumer exists yet (the live mount arrives with the families work; there
  # is NO mkMerge splice here). den-hoag ALREADY ships a deferred mechanism: a config-demanding aspect fn
  # rides `deferredToThunk` → gen-bind's `__configThunk`, resolved at the producing scope at the terminal
  # (output-modules.nix `deferredToThunk`, collections.nix `isConfigThunk`). Spec §4.8 R6 is THAT restriction
  # made explicit: THIS record formalizes the same contract (`needs` = the resolved paths a `then` reads,
  # `then` = the config producer). The families-step consumer either LOWERS this record onto the
  # `__configThunk` path or RETIRES both into one — recorded here so no THIRD defer surface is built.
  # `then` is a Nix keyword, so the record's field is read dynamically (`record.${"then"}`) and surfaced as
  # the keyword-free `thenFn`. The EXECUTABLE check now: a `then` producing `options`/`imports` is ILLEGAL (a
  # defer produces config, never options/imports) — a named throw fired when `thenFn` is APPLIED (so the
  # record stays inert until a consumer applies it; forcing the record shape never fires it).
  executeDefer =
    { record }:
    {
      mode = "defer";
      inherit (record) needs;
      thenFn =
        vals:
        let
          produced = record.${"then"} vals;
        in
        if produced ? options || produced ? imports then
          throw "den.nest: a defer's `then` produced ${
            if produced ? options then "options" else "imports"
          } — a defer produces config only, never options/imports (§4.8 R6)"
        else
          produced;
    };

  # `executeNest { row; inner; ctx; conversions ? { }; renders ? { } }` — the mode dispatch. `row` = a compiled
  # receives row (or one element of a `resolveReceiver` multi-winners list); `inner` = `{ product; payload; }`
  # (or the prebuilt `artifactRef` arm) plus the inner's structural FACE fields (name/kind/…); `ctx` =
  # structural handles ONLY (§2.1 corollary — name/kind/slot/ids/paramPoint, NO content); `conversions` = the
  # compiled single-step conversion table (den.conversions, §4.1); `renders` = the compiled render table
  # (den.renders, §4.3, holding each render's evaluator/face/extendsVia). Both tables are threaded at CALL time
  # (the receivers pattern — the engine holds no tables or evaluators). The engine reads the row's DERIVED
  # `mode` (F1) and hands the payload lazily into the arm's contribution — it may not force `inner.payload`
  # (nor call an evaluator / extendsVia) during wiring.
  executeNest =
    {
      row,
      inner,
      ctx,
      conversions ? { },
      renders ? { },
    }:
    let
      # the inner's STRUCTURAL face handed to `at` — the payload STRIPPED (§2.1: `at` sees structure, never
      # the produced content). `ctx.paramPoint` is the placement's first argument (the paramPoint handle).
      innerFace = removeAttrs inner [ "payload" ];
      atPath = row.at ctx.paramPoint innerFace;

      # graftMode dispatches on a payload already known to be the row's mode (post-conversion or exact-match).
      # `content` places the module list at `at`; `artifact` renders the inner through the row's render (the
      # ISOLATED INNER EVAL, the forcing boundary — REFERENCE.md §4.2 forward); `extend` extends the inner's
      # handle through the render's `extendsVia` capability. `payload` is the (possibly converted) inner payload.
      graftMode =
        payload:
        if row.mode == "content" then
          # CONTENT mode: the module list grafted at `at` — flat for `at = [ ]`, wrapped under the path
          # otherwise. The caller places the contribution; the engine performs only the pure at-path wrap.
          mkContribution "content" {
            at = atPath;
            modules = placeSlice atPath payload;
          }
        else if row.mode == "artifact" then
          # ARTIFACT mode: the render row (`renders.${row.render}`) crosses the inner's modules in ISOLATION —
          # the render call is the SOLE FORCING BOUNDARY (REFERENCE.md §4.2: "artifact — isolated inner eval,
          # the forcing boundary"). The eval is `renderRow.evaluator payload`; `face` projects it to the placed
          # artifact (`face eval`), or a NULL face means the eval ITSELF is the artifact. The `artifact` field
          # is a THUNK — the evaluator is never called during wiring, only when the mount consumer forces it.
          # `renderRow.provision`/`adapt` stay SHAPE-ONLY here (the provisioning-data + arg-crossing wiring is
          # the families/provide-adapt work) — the artifact arm reads only evaluator + face. A null `row.render`
          # is a MISSING-RENDER throw (an artifact consume has no way to build its face without a render row).
          if row.render == null then
            throw "den.nest: '${row.consumes}' is artifact-mode but the receives row names no render — an artifact consume needs a render row to build its face (§4.3)"
          else
            let
              renderRow = renders.${row.render};
            in
            mkContribution "artifact" {
              at = atPath;
              artifact =
                let
                  eval = renderRow.evaluator payload;
                in
                if renderRow.face != null then renderRow.face eval else eval;
            }
        else if row.mode == "extend" then
          # EXTEND mode: legal ONLY when the consulted render declares `extendsVia` (§4.3 — the capability lives
          # on the render row). A null `row.render`, or a render without `extendsVia`, is the MISSING-CAPABILITY
          # throw. The `extended` field is a THUNK wrapping `extendsVia` applied to the inner's EvalHandleInfo
          # payload (the extendModules handle) — the capability is never called during wiring.
          let
            renderRow = if row.render == null then null else renders.${row.render};
            extendsVia = if renderRow == null then null else renderRow.extendsVia;
          in
          if extendsVia == null then
            throw "den.nest: '${row.consumes}' is extend-mode but its render ${
              if row.render == null then "reference is null" else "'${row.render}' declares no extendsVia"
            } — extend is legal only under a render declaring the extendsVia capability (§4.3)"
          else
            mkContribution "extend" {
              at = atPath;
              extended = extendsVia payload;
            }
        else
          throw "den.nest: unhandled receive mode '${row.mode}' — the mode-execution engine handles no such arm";

      # THE CONVERSIONS CONSULT (§4.1): on a (produces, consumes) mismatch, EXACTLY ONE single-step lookup in
      # the compiled table (`"<from>-><to>"`). Found ⇒ `via` applied LAZILY to the payload, the contribution
      # proceeds under the row's mode; not found ⇒ the named mismatch throw. NO chain search — the MLIR-style
      # multi-hop materialization is rejected for determinism (a needed composite is its own registered pair).
      pairKey = "${inner.product}->${row.consumes}";

      # the MODE contribution (before the cross-cutting riders): value / exact-match / conversion.
      base =
        # VALUE mode (the prebuilt ArtifactRef arm, §4.1): an `inner` carrying the `artifactRef` wrapper is the
        # short-circuited prebuilt value — injected VERBATIM, never evaluated, never converted (conversions
        # never apply to the prebuilt arm; ArtifactRef acceptance at consumes = P is DEFINITIONAL). Checked
        # FIRST, before the exact-match/conversion arms: the wrapper's `inner.product` is the `ArtifactRef
        # <face>` name, which never equals the row's bare `consumes`, so those arms would misroute it. A
        # wrapped-face MISMATCH (`artifactRef.product` ≠ the row's consumes) sets the `unrealizedCast` marker —
        # a trace-visible node, NEVER an eval failure (§4.1 verbatim) — the value still rides verbatim.
        if inner ? artifactRef then
          mkContribution "value" (
            {
              at = atPath;
              inherit (inner.artifactRef) value;
            }
            // (
              if inner.artifactRef.product != row.consumes then
                {
                  # the prebuilt face does not match the row's consumes — an unrealized cast (a trace node),
                  # not a throw: the value is injected as-is and the mismatch is recorded for the trace.
                  unrealizedCast = {
                    from = inner.artifactRef.product;
                    to = row.consumes;
                  };
                }
              else
                { }
            )
          )
        # EXACT MATCH: the inner's product face equals the row's `consumes` — graft directly under the mode.
        else if inner.product == row.consumes then
          graftMode inner.payload
        # MISMATCH: consult the single-step conversion table for the (produces, consumes) pair. Found ⇒
        # materialize LAZILY through `via` and proceed under the row's mode; not found ⇒ the named throw.
        else if conversions ? ${pairKey} then
          graftMode (conversions.${pairKey}.via inner.payload)
        else
          throw "den.nest: inner produces '${inner.product}' but the receiver consumes '${row.consumes}' — no conversion (§4.1) registered for the pair '${pairKey}'";

      # ── THE CROSS-CUTTING RIDERS (§4.8) — attach to the mode contribution on ANY mode ──
      # PROVIDE: `row.provide = outer: attrs` supplies args crossed from the OUTER to the inner. The rider
      # carries BOTH delivery arms of the SAME `provide ctx` result (LAZILY — `provide` is not forced at
      # wiring): `specialArgs` (the extraSpecialArgs-style arm, for a crossing that exposes special args) and
      # `argsModule` (the `_module.args` module arm, the fallback). Which arm a crossing uses is the caller's
      # choice (the families step). THE RESTRICTION (§4.8): `_module.args` values are UNUSABLE in `imports`
      # (the module system evaluates `imports` before `_module.args` is available) — so an arg a downstream
      # module needs in ITS `imports` must ride the `specialArgs` arm. `ctx` is the outer's structural handle.
      provideRider =
        if row.provide or null == null then
          { }
        else
          {
            provideArgs =
              let
                args = row.provide ctx;
              in
              {
                specialArgs = args;
                argsModule = {
                  _module.args = args;
                };
              };
          };
      # ADAPT: `row.adapt` is the arg ENVIRONMENT (§4.8) a function-module's declared args bind against. The
      # rider carries the `adaptEnv` verbatim; the BINDING (`bindArgs adaptEnv fnModule`) happens at the mount
      # (families), not here — so the rider is inert data, the argEnv never forced at wiring.
      adaptRider = if row.adapt or null == null then { } else { adaptEnv = row.adapt; };
    in
    base // provideRider // adaptRider;
in
{
  inherit
    executeNest
    bindArgs
    executeDefer
    checkSingular
    ;
}
