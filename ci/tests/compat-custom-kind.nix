# Custom-kind instance-key DISCOVERY (ship-gate M1.5). A v1 config CHOOSES a custom kind's instance-registry
# KEY (`options.den.<KEY> = gen-schema.mkInstanceRegistry den.schema.<kind>`) — nix-config writes `clusters`
# for kind `cluster`; the key is arbitrary, NEVER a pluralization. The shim discovers the namespace holding a
# kind's instances by the id_hash MARKER (gen-schema's documented identity contract `hash("<kind>|<sorted
# primitive field=value>")`), never by name. This suite pins: discovery of a NON-pluralized key; that the
# discovered instances (not the singular fallback) are ingested; and that strict surface-totality still
# aborts a genuine typo (R9). The instance `id_hash` is hand-stamped with the documented formula (a gen-schema
# instance is minted by the corpus's own gen-schema; the REAL-formula match is verified dev-time by the corpus
# ship-gate re-probe).
{ lib, denCompat, ... }:
let
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  # A `rack` kind whose instances live at the CHOSEN key `rackFarm` (not `racks`, not `rack`). The instance
  # carries the id_hash gen-schema's mkInstanceRegistry would stamp: hash("rack|name=r1|slots=12").
  rackHash = builtins.hashString "sha256" "rack|name=r1|slots=12";
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
  };
}
