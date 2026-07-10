# Custom-kind instance-key DISCOVERY (ship-gate M1.5). A v1 config CHOOSES a custom kind's instance-registry
# KEY (`options.den.<KEY> = gen-schema.mkInstanceRegistry den.schema.<kind>`) — nix-config writes `clusters`
# for kind `cluster`; the key is arbitrary, NEVER a pluralization. The shim discovers the namespace holding a
# kind's instances by the id_hash MARKER, recomputed through gen-schema's OWN exported derivation
# (`schema.identityHashFor`), never by name. This suite pins: discovery of a NON-pluralized key; that the
# discovered instances (not the singular fallback) are ingested; and that strict surface-totality still
# aborts a genuine typo (R9).
#
# FORMULA CANARY: the fixture stamps `id_hash` with the DOCUMENTED formula (`rackHash`, computed inline);
# the ingest's discovery recomputes it through OUR gen-schema's `identityHashFor`. If our gen-schema's
# derivation ever drifted from the documented `<kind>|<sorted primitive field=value>`, the two would
# mismatch → `rackFarm` matches no kind → `test-discovery-nonpluralized` FAILS in-repo (loud, before any
# corpus run). The corpus side is re-proven by every ship-gate probe (discovery working on real
# corpus-gen-schema instances proves that pin agrees with ours today).
{ lib, denCompat, ... }:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  # A `rack` kind whose instances live at the CHOSEN key `rackFarm` (not `racks`, not `rack`). `rackHash` is
  # the FORMULA CANARY: the PINNED id_hash literal gen-schema's `identityHashFor "rack" { name="r1"; slots=12; }`
  # must reproduce (the documented `<kind>|<sorted primitive field=value>` content-address). The discovery
  # (ingest → `schema.identityHashFor`) matches against it, so if OUR gen-schema's derivation ever drifts from
  # this literal, `test-discovery-nonpluralized` FAILS in-repo — before any corpus run. Regenerate with
  # `nix eval --expr 'builtins.hashString "sha256" "rack|name=r1|slots=12"'` if the fixture's fields change.
  rackHash = "f25f73d7b74fa093bfe797d8fa7393952699b3fd60d76af714940a7612a62906";
  fixture = {
    schema.rack.parent = null;
    rackFarm.r1 = {
      name = "r1";
      slots = 12;
      id_hash = rackHash;
    };
  };
  ing = denCompat.ingest.ingest fixture;
in
{
  flake.tests.compat-custom-kind = {
    # MARKER discovery: kind `rack` resolves to the arbitrary key `rackFarm` (name-agnostic — proving the
    # discovery is by id_hash, not by a `rack` → `racks`/`rackFarm` name heuristic).
    test-discovery-nonpluralized = {
      expr = {
        key = ing.instanceKeyMap.rack or null;
        discovered = ing.discoveredRegistryKeys;
      };
      expected = {
        key = "rackFarm";
        discovered = [ "rackFarm" ];
      };
    };
    # the discovered INSTANCES are ingested from the chosen key (the `den.rack` singular fallback is empty).
    test-instances-from-discovered-key = {
      expr = builtins.attrNames (ing.instances.rack or { });
      expected = [ "r1" ];
    };
    # strict totality ACCEPTS the marker-discovered namespace (no abort on the legitimate `rackFarm` key).
    test-totality-accepts-discovered = {
      expr = throws (denCompat.compile fixture);
      expected = false;
    };
    # strict totality still ABORTS a genuine typo — `hots` is undeclared, holds no instance registry (no
    # id_hash), matches no kind, so it is neither discovered nor declared: named abort (R9, no widening).
    test-totality-aborts-typo = {
      expr = throws (
        denCompat.compile {
          schema.rack.parent = null;
          hots.box1 = { };
        }
      );
      expected = true;
    };
    # `reservedKeys` (den v1 `den.reservedKeys`) is a CONFIG-only key surface-totality ACCEPTS (not a typo):
    # it extends v1's structuralKeysSet, reproduced statically by the compat keyClassification export, so no
    # concern reads it but it must not abort a fleet that sets it (nix-config `den.reservedKeys = [ "settings" ]`).
    test-totality-accepts-reserved-keys = {
      expr = throws (
        denCompat.compile {
          schema.rack.parent = null;
          reservedKeys = [ "settings" ];
        }
      );
      expected = false;
    };
  };
}
