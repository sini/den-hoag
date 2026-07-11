# FLAT (by-name) `den.hosts.<name>` ADDRESSING (ship-gate: den.hosts shape at flattenHosts). v1's
# `den.hosts` option normalizes TWO addressings before its `attrsOf systemType` merge (pin 11866c16
# nix/lib/entities/host.nix:31-43 `hostsOption.apply` → nix/lib/entities/_types.nix:152-172
# `preprocessHosts`): a SYSTEM-keyed group (`den.hosts.<sys>.<name>`, key ∈ flakeExposed) passes through
# two-level, and a NAME-keyed FLAT host (`den.hosts.<name>`, key ∉ flakeExposed) is GROUPED by its own
# `system` field (throwing if absent). The frozen corpus mixes BOTH: `hosts/slab.nix:3`
# (`den.hosts.slab`, an aarch64-linux droid) and `hosts/patch.nix:3` (`den.hosts.patch`, an
# aarch64-darwin host) sit beside the `den.hosts.x86_64-linux.*` system group. Before this rung the
# shim's `flattenHosts` folded EVERY top key as a system, so a flat host's own fields (e.g.
# `channel = "nixos-unstable"`) were demoted as if they were host entries → `expected a set but found a
# string: "nixos-unstable"`. These witnesses pin the reproduction of v1's `preprocessHosts`:
# flat hosts land keyed by NAME with `system` a field, system groups are unchanged (byte-stable), and a
# flat host that omits `system` aborts LOUD exactly where v1 throws.
{ denCompat, ... }:
let
  inherit (denCompat) ingest;
  inherit (ingest) flattenHosts hostUserBindings flakeExposedSystems;

  # The REAL corpus mixed shape (hosts/*.nix), verbatim idiom: a system group beside two flat by-name
  # hosts that declare their own `system` (slab: aarch64-linux droid; patch: aarch64-darwin).
  corpusShape = {
    x86_64-linux = {
      axon-02 = {
        channel = "nixos-unstable";
        environment = "prod";
      };
    };
    slab = {
      class = "droid";
      system = "aarch64-linux";
      channel = "nixos-unstable";
      environment = "dev";
      users.sini = { };
    };
    patch = {
      environment = "dev";
      system = "aarch64-darwin";
      channel = "nixpkgs-master";
      users.sini = { };
    };
  };
  flat = flattenHosts corpusShape;

  # A pure two-level input (no flat hosts) — must demote exactly as the pre-fix fold did (byte-stable).
  wellShaped = {
    x86_64-linux = {
      a.channel = "nixos-unstable";
      b.channel = "nixos-stable";
    };
    aarch64-linux = {
      c.channel = "x";
    };
  };

  # A malformed flat host (key ∉ flakeExposed, NO `system` field) — the shape v1 ALSO throws on.
  malformed = {
    rogue.channel = "nixos-unstable";
  };

  # End-to-end through the full ingestion boundary: the flat hosts must produce host registry entries and
  # a (user, host) membership cell for their embedded `users.sini`, alongside the system-group host.
  ingested = ingest.ingest { hosts = corpusShape; };
in
{
  flake.tests.compat-flat-host = {
    # DRIFT PIN: the shim's literal `reservedSystems` reproduction must be EXACTLY v1's
    # `lib.systems.flakeExposed` at the pin — the FULL 10-set, eval-verified against the corpus/parity
    # nixpkgs (567a49d): a dropped member misclassifies that system GROUP as a flat host (wrong abort
    # where v1 passes it through); an added member misclassifies a flat host NAMED like it as a group.
    # attrNames is lexicographically sorted, so this list is the sorted 10-set.
    test-flake-exposed-full-set = {
      expr = builtins.attrNames flakeExposedSystems;
      expected = [
        "aarch64-darwin"
        "aarch64-linux"
        "armv6l-linux"
        "armv7l-linux"
        "i686-linux"
        "powerpc64le-linux"
        "riscv64-linux"
        "x86_64-darwin"
        "x86_64-freebsd"
        "x86_64-linux"
      ];
    };
    # Both flat hosts land in the flat registry keyed by NAME, beside the system-group host — no field of a
    # flat host is mis-read as a host (the pre-fix crash). attrNames is lexicographically sorted.
    test-flat-and-group-hosts-present = {
      expr = builtins.attrNames flat;
      expected = [
        "axon-02"
        "patch"
        "slab"
      ];
    };
    # A flat host's `system` rides through as a field (v1 groups by it; the shim keeps it demoted).
    test-flat-host-system-field = {
      expr = {
        slab = flat.slab.system;
        patch = flat.patch.system;
      };
      expected = {
        slab = "aarch64-linux";
        patch = "aarch64-darwin";
      };
    };
    # A flat host's other fields ride through untouched (class = "droid" is what `classOfHost` reads).
    test-flat-host-fields-ride = {
      expr = {
        inherit (flat.slab) class channel;
      };
      expected = {
        class = "droid";
        channel = "nixos-unstable";
      };
    };
    # The system-group host has its path key demoted to a `system` field, config otherwise intact.
    test-system-group-host-demoted = {
      expr = {
        inherit (flat.axon-02) system channel environment;
      };
      expected = {
        system = "x86_64-linux";
        channel = "nixos-unstable";
        environment = "prod";
      };
    };
    # Byte-stability: a pure two-level input demotes exactly as the pre-fix fold did (flat branch empty).
    test-well-shaped-byte-stable = {
      expr = flattenHosts wellShaped;
      expected = {
        a = {
          channel = "nixos-unstable";
          system = "x86_64-linux";
        };
        b = {
          channel = "nixos-stable";
          system = "x86_64-linux";
        };
        c = {
          channel = "x";
          system = "aarch64-linux";
        };
      };
    };
    # A flat host's embedded `users.sini` becomes a (user, host) binding (hostUserBindings reads it).
    test-flat-host-user-binding = {
      expr = builtins.any (b: b.user == "sini" && b.host == "slab") (hostUserBindings flat);
      expected = true;
    };
    # LOUD abort for a flat host with no `system` — the shape v1 ALSO rejects (_types.nix:160-162).
    # Forcing the entry raises the named error rather than mis-demoting the host's own fields.
    test-flat-host-no-system-aborts = {
      expr = (builtins.tryEval (flattenHosts malformed).rogue).success;
      expected = false;
    };
    # End-to-end: the flat hosts are real host instances in the ingested registry, beside the group host.
    test-ingest-host-instances = {
      expr = builtins.attrNames ingested.instances.host;
      expected = [
        "axon-02"
        "patch"
        "slab"
      ];
    };
    # End-to-end: the flat host's embedded user is a membership cell binding sini@slab (real entries).
    test-ingest-membership-slab = {
      expr = builtins.any (
        c: c.coords.host.name == "slab" && c.coords.user.name == "sini"
      ) ingested.membership;
      expected = true;
    };
  };
}
