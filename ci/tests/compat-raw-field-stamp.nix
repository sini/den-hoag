# #70 (the ledger u19 next-link) — RAW ctx-entity fields ride a LAZY side channel. The structural
# exclusion (registry.nix stampTreeOf) keeps raw/deferredModule/anything-class option values OUT of the
# deepSeq-safe stamp — that law is UNCHANGED (its reason stands: those values must never enter deepSeq'd
# resolution state). But v1 binds the FULL merged host config as the ctx entity (pin 11866c16
# assemble-pipes.nix:154), so corpus policy/channel bodies READ those fields — the u19 frontier:
# cortex's `microvm-guests` channel emit maps over `host.microvm.guests` (a `listOf raw` option,
# corpus microvm.nix:39), and the U9.2 cross-host gather (v1-faithfully) forces sibling emissions from
# axon-01's eval. #70 carries the excluded fields via `_entityRawStamps` (bridge.nix — the
# instantiateFor/hmModuleFor compile-side side-map grain, generalized: registry.nix `rawStampTreeOf`,
# the exclusion's EXACT dual) overlaid LAZILY onto the ctx entity at ingest (`withRawStamp` /
# `deepUnionStamps`): one un-forced thunk per field, forced ONLY when a body reads it.
#
# Witnesses:
#   (1) THE CORTEX SHAPE — a raw-declared kind field (`mv.guests`, `listOf raw`) is readable in a
#       channel emit forced by a SIBLING's collect gather; the raw group child merges beside the safe
#       group children (the `mv` group collides across the two trees — the deepUnionStamps case);
#   (2) the NON-VACUOUS negative — the SAME fleet withOUT the raw side channel aborts exactly as the
#       u19 corpus probe did (`attribute 'guests' missing` — here the whole `mv` group is absent);
#   (3) LAZINESS — a THROWING raw field rides the entity un-forced: the fleet resolves (systems spine,
#       channel bindings, data-field reads all force fine); ONLY reading the poisoned field throws;
#   (4) the SAFE STAMP + IDENTITY unchanged — the safe stamped fields and the entity id_hash/name are
#       byte-equal with and without the raw side channel;
#   (5) the TREE DUAL (unit) — rawStampTreeOf keeps exactly the leaves stampTreeOf drops
#       (complementary trees; a mixed group appears in both, split by child).
{ denCompat, nixpkgsLib, ... }:
let
  P = denCompat.pipe;
  registryLib = denCompat.registry;

  # ── the corpus-shaped kind module: a MIXED group `mv` (safe children shared/flag + the RAW child
  #    guests — the corpus microvm shape), a top-level raw field `inert` (the laziness probe), and a
  #    plain data field. ──
  kindModule =
    { ... }:
    let
      inherit (nixpkgsLib) mkOption types;
    in
    {
      options = {
        role = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        mv.shared = mkOption {
          type = types.bool;
          default = true;
        };
        mv.guests = mkOption {
          type = types.listOf types.raw; # the corpus microvm.guests shape (STRUCTURALLY EXCLUDED)
          default = [ ];
        };
        inert = mkOption {
          type = types.raw; # the laziness probe — its authored value THROWS when forced
          default = null;
        };
      };
    };

  hostDecls = {
    x86_64-linux = {
      h1 = {
        class = "nixos";
        role = "consumer";
        mv.guests = [ { name = "g-h1"; } ];
      };
      h2 = {
        class = "nixos";
        role = "producer";
        mv.guests = [
          { name = "g-h2a"; }
          { name = "g-h2b"; }
        ];
      };
    };
  };

  # the REAL registry machinery, exactly as the bridge computes both channels.
  instanceOpts = registryLib.hostInstanceOptions {
    lib = nixpkgsLib;
    inherit kindModule;
  };
  safeTree = registryLib.stampTreeOf instanceOpts;
  rawTree = registryLib.rawStampTreeOf instanceOpts;
  applied =
    (registryLib.mkHostsOption {
      lib = nixpkgsLib;
      inherit kindModule;
    }).apply
      hostDecls;
  entries = registryLib.flattenRegistry applied;
  safeStamps = builtins.mapAttrs (_: e: registryLib.stampOf safeTree e) entries;
  # The raw stamps — POISONED at `inert` (the laziness probe, witness 3): the value throws when
  # forced, so the field crossing the side channel un-forced IS the lazy-carry proof. (Poisoned in the
  # stamp MAP, exactly where the bridge's per-field lazy `stampOf` read sits — an authored throwing
  # value would equally ride the registry's lazy raw option, but poisoning here keeps the registry
  # eval itself trivially clean.)
  rawStamps = builtins.mapAttrs (
    _: e: registryLib.stampOf rawTree e // { inert = throw "boom: the raw field was forced"; }
  ) entries;

  # ── the fleet: both hosts emit `guests` (a parametric emit reading the RAW field — the cortex
  #    microvm-guests shape) + `plain` (a data-field read); each host COLLECTS `guests` from its
  #    siblings (the #69 gather — what forces the sibling's emission, the u19 forcing path). ──
  mkFleet =
    withRaw:
    denCompat.mkDen [
      {
        # NB: merged INSIDE `den` — a top-level `{ den.x = …; } // { den.y = …; }` would clobber the
        # whole `den` attrset (attrpath sugar builds ONE `den` key per literal).
        den = {
          hosts = hostDecls;
          quirks.guests = { };
          quirks.plain = { };
          aspects.hemit =
            { host, ... }:
            {
              nixos.tag = "nixos-${host.name}";
              guests = map (g: g.name) host.mv.guests; # reads the RAW field (u19: attribute missing pre-#70)
              plain = [ "role-${host.role}" ]; # reads a SAFE stamped field
            };
          schema.host.includes = [ "hemit" ];
          policies.collect-guests =
            { host, ... }:
            [
              (P.from "guests" [ (P.collect ({ host, ... }: true)) ])
            ];
          _entityStamps.hosts = safeStamps;
        }
        // (if withRaw then { _entityRawStamps.hosts = rawStamps; } else { });
      }
    ];
  fleet = mkFleet true;
  noRaw = mkFleet false;

  bindingsOf = f: id: f.den.output.systems.nixos.${id}.bindings;
  entityOf = f: (f.den.structural.eval.get "host:h1" "enriched-context").host;
  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;
in
{
  flake.tests.compat-raw-field-stamp = {
    # (1) the cortex shape: h1's collected `guests` binding carries its OWN raw-field read AND h2's —
    #     the sibling's emission (forced by the gather) resolved against the raw-stamped entity. One
    #     contribution per emitting node (each an emitted LIST value), own-first then the sibling's.
    test-raw-field-readable-at-sibling-gather = {
      # #74b: flat values (v1 flattenAndExtract).
      expr = (bindingsOf fleet "host:h1").guests;
      expected = [
        "g-h1"
        "g-h2a"
        "g-h2b"
      ];
    };
    # …and the mixed `mv` group merged both trees' children (safe `shared` beside raw `guests`).
    test-mixed-group-carries-both-children = {
      expr = {
        shared = (entityOf fleet).mv.shared;
        guests = map (g: g.name) (entityOf fleet).mv.guests;
      };
      expected = {
        shared = true;
        guests = [ "g-h1" ];
      };
    };

    # (2) the non-vacuous negative: withOUT the raw side channel the SAME fleet's entity LACKS the
    #     field entirely — reading `host.mv.guests` is then the UNCATCHABLE `attribute missing` abort
    #     the u19 corpus probe recorded verbatim (uncatchable by tryEval, so the pin asserts the
    #     absence rather than forcing the abort; the abort's loudness IS the u19 record).
    test-without-raw-channel-field-absent = {
      expr = {
        # the safe half of the mixed group still rides (mv.shared — the stamp unchanged)…
        hasSharedStill = (entityOf noRaw).mv.shared;
        # …but the RAW child is absent without the side channel (u19's `attribute 'guests' missing`).
        hasGuests = (entityOf noRaw).mv ? guests;
        withRawHasGuests = (entityOf fleet).mv ? guests;
      };
      expected = {
        hasSharedStill = true;
        hasGuests = false;
        withRawHasGuests = true;
      };
    };

    # (3) LAZINESS: the THROWING `inert` raw field rides the entity un-forced — the systems spine, the
    #     channel bindings (incl. the raw-reading gather), and a safe-field read all resolve; ONLY
    #     reading the poisoned field throws.
    test-throwing-raw-field-unforced = {
      expr = {
        spine = ok (builtins.attrNames fleet.den.output.systems.nixos);
        gathered = ok (bindingsOf fleet "host:h1").guests;
        plain = (bindingsOf fleet "host:h1").plain;
        safeRead = (entityOf fleet).role;
        poisonedRead = ok (entityOf fleet).inert;
      };
      expected = {
        spine = true;
        gathered = true;
        plain = [ "role-consumer" ]; # flat (#74b)
        safeRead = "consumer";
        poisonedRead = false;
      };
    };

    # (4) the safe stamp + entity identity are UNCHANGED by the raw channel: same id_hash/name, same
    #     safe field values, with and without it.
    test-safe-stamp-and-identity-unchanged = {
      expr = {
        sameIdHash = (entityOf fleet).id_hash == (entityOf noRaw).id_hash;
        sameName = (entityOf fleet).name == (entityOf noRaw).name;
        sameRole = (entityOf fleet).role == (entityOf noRaw).role;
        noRawHasNoGuests = (entityOf noRaw).mv or { } ? guests;
      };
      expected = {
        sameIdHash = true;
        sameName = true;
        sameRole = true;
        noRawHasNoGuests = false;
      };
    };

    # (5) the tree dual (unit): rawStampTreeOf keeps EXACTLY the excluded leaves; the mixed group
    #     appears in both trees, split by child; the safe tree is unchanged by construction.
    test-tree-dual-complementary = {
      expr = {
        safeMv = safeTree.mv;
        rawMv = rawTree.mv;
        rawTop = rawTree ? inert;
        safeTop = safeTree ? inert;
      };
      expected = {
        safeMv = {
          shared = true;
        };
        rawMv = {
          guests = true;
        };
        rawTop = true;
        safeTop = false;
      };
    };
  };
}
