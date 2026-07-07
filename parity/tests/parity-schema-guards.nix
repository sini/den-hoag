# Schema + normalization guards — the two soundness properties the ship gate (C9/P6) rests on but that
# the P1/P4/P5/P7 corpus doesn't exercise:
#
#   (1) the FROZEN-SCHEMA cross-version refusal — `assertEdgeParity` must THROW (named) on a trace tagged
#       with a different schema version, so a silent cross-version diff can never slip through. The guard
#       exists in schema.nix; this proves it FIRES (a `builtins.tryEval` refusal, not an untested branch).
#   (2) the entity-detection guard in `hoagNormName` (F1 normalization) — the "last colon segment is an
#       id_hash" heuristic is tightened to require BOTH a 64-hex shape AND registry membership, so a
#       non-entity opaque string that merely contains a colon + hex tail can never be mis-mapped as an
#       entity. Proven by passing such a string through UNMAPPED.
#
# Pure (no den eval): schema logic + the exposed `hoagNormName`/`isIdHash` helpers over synthetic maps.
{ harness, ... }:
let
  inherit (harness)
    schema
    hoagNormName
    isIdHash
    nonEntityNameMap
    ;

  # A real registry entry (64-hex id_hash present in the map) and a different 64-hex id NOT in the map.
  entityHash = builtins.hashString "sha256" "host-igloo-entity";
  strangerHash = builtins.hashString "sha256" "not-a-registered-entity";
  reg = {
    ${entityHash} = "host:igloo";
  };
  norm = hoagNormName reg;

  # tryEval a forced `.parity` (the throw is at the top of assertEdgeParity, so forcing any field triggers
  # it). success = false ⇒ the guard threw; true ⇒ the diff evaluated.
  parityEvals = args: (builtins.tryEval ((schema.assertEdgeParity args).parity)).success;
in
{
  flake.tests.parity-schema-guards = {
    # ── (1) frozen-schema cross-version refusal ──
    test-cross-version-refused = {
      expr = parityEvals {
        expected = [ ];
        actual = [ ];
        schemaVersion = 2;
      };
      expected = false;
    };
    test-default-version-accepted = {
      expr = parityEvals {
        expected = [ ];
        actual = [ ];
      };
      expected = true;
    };
    test-explicit-version-1-accepted = {
      expr = parityEvals {
        expected = [ ];
        actual = [ ];
        schemaVersion = 1;
      };
      expected = true;
    };

    # ── (2) hoagNormName entity-detection guard ──
    # the 64-hex id_hash shape predicate on its own.
    test-isIdHash-accepts-sha256 = {
      expr = isIdHash entityHash;
      expected = true;
    };
    test-isIdHash-rejects-short = {
      expr = isIdHash "bar";
      expected = false;
    };
    test-isIdHash-rejects-colon-name = {
      expr = isIdHash "system=x86_64-linux";
      expected = false;
    };

    # an entity scope (64-hex id_hash IN the registry) normalizes to its <kind>:<name>.
    test-entity-scope-maps = {
      expr = norm "host:${entityHash}";
      expected = "host:igloo";
    };
    # THE MIS-MAP GUARD: a colon-bearing non-entity name whose tail IS 64-hex but is NOT a registry entry
    # passes through UNMAPPED (membership check fails — the tail is not a real id_hash).
    test-nonentity-colon-hex-unmapped = {
      expr = norm "output:${strangerHash}";
      expected = "output:${strangerHash}";
    };
    # a colon-bearing non-entity name with a NON-hex tail passes through unmapped (shape check fails).
    test-nonentity-nonhex-unmapped = {
      expr = norm "system=x86_64-linux";
      expected = "system=x86_64-linux";
    };
    # the F2 non-entity name map still applies where it has an entry (the empty flake root).
    test-nonentity-map-applied = {
      expr = norm "";
      expected = nonEntityNameMap."";
    };
  };
}
