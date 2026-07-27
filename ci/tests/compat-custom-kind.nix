# Custom-kind instance-key DISCOVERY (ship-gate M1.5). A v1 config CHOOSES a custom kind's instance-registry
# KEY (`options.den.<KEY> = gen-schema.mkInstanceRegistry den.schema.<kind>`) — nix-config writes `clusters`
# for kind `cluster`; the key is arbitrary, NEVER a pluralization. The shim discovers the namespace holding a
# kind's instances by the id_hash MARKER, recomputed through gen-schema's OWN exported derivation
# (`schema.identityHashFor`), never by name. This suite pins: discovery of a NON-pluralized key; that the
# discovered instances (not the singular fallback) are ingested; and that strict surface-totality still
# aborts a genuine typo (R9).
#
# FORMULA CANARY: the registry's `id_hash` is stamped by gen-schema's own `mkIdentityModule`; the ingest's
# discovery recomputes it through `identityHashFor`, and the suite pins BOTH against the DOCUMENTED formula
# literal (`rackHash`). If either derivation ever drifted from `<kind>|<sorted primitive field=value>`, the
# stamp and the literal diverge → `rackFarm` matches no kind → `test-discovery-nonpluralized` FAILS in-repo
# (loud, before any corpus run). The corpus side is re-proven by every ship-gate probe (discovery working on
# real corpus-gen-schema instances proves that pin agrees with ours today).
{
  lib,
  denCompat,
  denHoag,
  ...
}:
let
  registry = import ./_lib/instance-registry.nix { inherit denHoag lib; };
  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  # A `rack` kind whose instances live at the CHOSEN key `rackFarm` (not `racks`, not `rack`). The kind's
  # own options are nixpkgs-typed because that is how a consumer authors them (`den.schema.<kind>.imports`
  # carrying its own `lib.mkOption`); the REGISTRY around them is gen-schema's.
  rackKind = {
    isEntity = true;
    parent = null;
    imports = [
      (_: {
        options.slots = lib.mkOption {
          type = lib.types.int;
          default = 0;
        };
      })
    ];
  };
  # `rackHash` is the FORMULA CANARY: the PINNED id_hash literal the documented
  # `<kind>|<sorted primitive field=value>` content-address produces for this instance. gen-schema's
  # `mkIdentityModule` stamps the registry entry and `identityHashFor` recomputes it at discovery — both
  # are pinned against this literal below. Regenerate with
  # `nix eval --expr 'builtins.hashString "sha256" "rack|name=r1|slots=12"'` if the fixture's fields change.
  rackHash = "f25f73d7b74fa093bfe797d8fa7393952699b3fd60d76af714940a7612a62906";
  # The registry the consumer declares — gen-schema's `mkInstanceRegistry`, so the instances carry the
  # identity module's own stamp rather than a hand-written `id_hash`, and the discovery marker reads a
  # surface gen-schema produced.
  rackReg = registry.mkRegistry {
    kindName = "rack";
    kind = rackKind;
    namespace = "rackFarm";
    instances.r1.slots = 12;
  };
  fixture = {
    schema.rack = rackKind;
    rackFarm = rackReg.instances;
  };
  ing = denCompat.ingest.ingest fixture;
in
{
  flake.tests.compat-custom-kind = {
    # THE CANARY, both halves: gen-schema's `mkIdentityModule` STAMPED the registry entry with the
    # documented content-address, and the instance's declared surface is the one `mkInstanceType` builds
    # (the injected `name`/`id_hash`/`_identity` beside the kind's own `slots`) — contents pinned, not
    # membership, so a surface that lost a field cannot pass.
    test-identity-stamped-by-gen-schema = {
      expr = {
        stamped = rackReg.instances.r1.id_hash;
        documented = builtins.hashString "sha256" "rack|name=r1|slots=12";
        surface = builtins.attrNames rackReg.subOptions;
      };
      expected = {
        stamped = rackHash;
        documented = rackHash;
        surface = [
          "_identity"
          "id_hash"
          "name"
          "slots"
        ];
      };
    };
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
          schema.rack = rackKind;
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
          schema.rack = rackKind;
          reservedKeys = [ "settings" ];
        }
      );
      expected = false;
    };
  };
}
