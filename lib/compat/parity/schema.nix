# The FROZEN parity schema (version 1) — the shared structural identity + the diff engine.
#
# The whole structural oracle is the frozen `T | P | S | M` sort-key STRING (gen-edge `edgeSortKey` ==
# den v1 `edgeSortKey`, byte-for-byte — the "v1 byte contract", edge-schema.md). The harness keys the
# diff by that string and NOTHING else: it never translates one arm's record shape into the other's, it
# renders both arms into the same string and diffs on strings (Notes-for-engineer: "the sort-key string
# is the whole structural oracle"). Each arm attaches its rendered key as `__sortKey` and carries its
# structured trace entry (`entry`) + its `arm` tag ONLY for the `firstDivergent` display — never for
# identity.
#
# A trace element (both arms) is `{ __sortKey; entry; arm; }`:
#   __sortKey — the rendered, name-normalized `T | P | S | M` string (the identity; see oracle.nix for
#               why entity scopes are name-normalized rather than id_hash-compared).
#   entry     — the structured, identity-level trace entry (gen-edge `traceEntryOf` shape), for display.
#   arm       — "v1" | "hoag", for divergence attribution.
#
# nixpkgs-lib-free: only `prelude`.
{ prelude }:
let
  # The schema version. `assertEdgeParity` refuses to diff traces tagged with a different version — a
  # schema change (the §4.1 record / sort key / scope naming) requires a version bump + a ledger entry
  # (edge-schema.md's version-bump discipline).
  version = 1;

  # keyOf: the frozen `T | P | S | M` sort-key STRING. Arm-agnostic — both arms already render it into the
  # SAME string (the byte contract), so this is the sole cross-arm identity.
  keyOf = e: e.__sortKey;

  # firstDivergent (§4.3 triage): the least element of the symmetric difference under the total sort-key
  # order, with arm attribution ("v1" = in the expected/oracle arm only; "hoag" = in the actual arm only)
  # and the bracketing matched neighbours (the matched keys immediately before/after it) so a reader sees
  # exactly where in the ordered trace the two arms first part ways. `null` when the traces agree.
  firstDivergentOf =
    {
      missingFromActual,
      extraInActual,
      matched,
    }:
    let
      # Every symmetric-difference element, tagged by the arm it is unique to. missingFromActual is
      # present in `expected` (the v1 oracle) but absent from `actual` (hoag); extraInActual the reverse.
      diffs =
        (map (e: {
          key = keyOf e;
          onlyIn = e.arm or "v1";
          element = e;
        }) missingFromActual)
        ++ (map (e: {
          key = keyOf e;
          onlyIn = e.arm or "hoag";
          element = e;
        }) extraInActual);
      sortedDiffs = prelude.sort (a: b: a.key < b.key) diffs;
      matchedKeys = prelude.sort (a: b: a < b) (map keyOf matched);
    in
    if sortedDiffs == [ ] then
      null
    else
      let
        fd = builtins.head sortedDiffs;
        before = builtins.filter (k: k < fd.key) matchedKeys;
        after = builtins.filter (k: k > fd.key) matchedKeys;
      in
      {
        key = fd.key;
        # Which arm the first-divergent edge is unique to — the SIDE of the divergence.
        onlyIn = fd.onlyIn;
        entry = fd.element.entry or null;
        precededBy = if before == [ ] then null else prelude.last before;
        followedBy = if after == [ ] then null else builtins.head after;
      };

  # assertEdgeParity — the v1 helper shape (`{ matched; missingFromActual; extraInActual; parity; }`,
  # den v1 `edges/parity.nix`) + the §4.3 `firstDivergent` triage record. Keyed ENTIRELY by `keyOf` (the
  # frozen string): `matched` = expected edges whose key is also in actual; `missingFromActual` = expected
  # keys absent from actual; `extraInActual` = actual keys absent from expected. `parity` iff both diffs
  # are empty. Refuses a cross-version diff (the frozen-schema guard).
  assertEdgeParity =
    {
      expected,
      actual,
      schemaVersion ? version,
    }:
    if schemaVersion != version then
      throw "den-compat parity: schema version mismatch (harness is v${toString version}, trace tagged v${toString schemaVersion}) — a schema change needs a version bump + a ledger entry (edge-schema.md)"
    else
      let
        expKeys = prelude.listToAttrs (map (e: prelude.nameValuePair (keyOf e) e) expected);
        actKeys = prelude.listToAttrs (map (e: prelude.nameValuePair (keyOf e) e) actual);
        missingFromActual = builtins.filter (e: !(actKeys ? ${keyOf e})) expected;
        extraInActual = builtins.filter (e: !(expKeys ? ${keyOf e})) actual;
        matched = builtins.filter (e: actKeys ? ${keyOf e}) expected;
        parity = missingFromActual == [ ] && extraInActual == [ ];
      in
      {
        inherit
          matched
          missingFromActual
          extraInActual
          parity
          ;
        firstDivergent = firstDivergentOf { inherit missingFromActual extraInActual matched; };
      };

  # keysOf — a small reporting helper: the sorted list of frozen keys of a trace (or a diff arm). The
  # golden-diff gates (P1) assert over these stable strings, not the structured records.
  keysOf = trace: prelude.sort (a: b: a < b) (map keyOf trace);
in
{
  inherit
    version
    keyOf
    keysOf
    assertEdgeParity
    firstDivergentOf
    ;
}
