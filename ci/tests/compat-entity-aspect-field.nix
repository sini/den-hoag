# THE ENTITY `aspect` FIELD — v1's `lookupAspect` default, declared shim-side (registry.nix
# baseEntityModule).
#
# den v1 declares `aspect` on BOTH entity instance types — `hostType` (pin 11866c16
# nix/lib/entities/host.nix:68-73) and `userType` (:163-168) — defaulting to `lookupAspect den config`
# = `den.aspects.${config.name}`, or a WARNED empty aspect when no same-named aspect exists
# (_types.nix:19-24). The shim originally omitted BOTH under the base module's "v1 runtime machinery"
# rule, which is the rule's boundary case and got it wrong: `mainModule`/`__resolveResult`/
# `__pathSetByScope` hold fx-pipeline RESULTS the shim replaces wholesale, but `aspect` holds the
# AUTHORED ASPECT TREE — ordinary declaration data that exists identically on both sides. The omission
# made the field simply ABSENT, and nix-config reads it: aspects/virtualization/microvm-guests.nix:43
# `den.lib.aspects.resolve "microvm" vm.aspect`, over the host ENTRIES carried in
# `host.microvm.guests`.
#
# ★ THE DIVERGENCE CLASS this arms, which is wider than one field: a v1-declared entity-instance
#   option whose value is DATA is part of the corpus-facing surface whether or not the shim's own
#   machinery reads it, so "not grain- or stamp-relevant" is not a licence to drop it. Witness (5)
#   pins the declared data options on a BARE host, so a future omission of the same shape fails here
#   rather than at a corpus toplevel — a regression guard, not a completeness oracle (see its note:
#   `hostName` and `description` remain undeclared, unread by the corpus so far).
#
# Witnesses: (1) the same-named aspect materializes on the entry, and the field EXISTS (the exact
# predicate whose falsity was the defect); (2) the no-same-named-aspect arm resolves to `{ }` —
# v1's warn-and-empty, PRESENT rather than missing; (3) TREE PLACEMENT — `types.raw` puts it on the
# #70 lazy raw side channel and keeps it OUT of the deepSeq-safe stamp, so an aspect tree's class fns
# and module trees never enter resolution state; (4) the USER twin (v1 :163-168); (5) the class
# predicate over the base-entity data options; (6) BRIDGE end-to-end — the field is the NAVIGATION
# view's node (native `.key`), i.e. indistinguishable from the corpus writing `den.aspects.<name>`
# itself; (7) THE CORPUS READ SHAPE — a host entry carried in ANOTHER host's `listOf raw` schema
# field still answers `.aspect` (microvm-guests.nix:38-46, `map (vm: … vm.aspect) host.microvm.guests`).
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  # A stand-in aspect tree for the UNIT arms: `lookupAspect` is an attrset select, so the unit arms
  # pin the SELECT (which name, which fallback); the navigation-view identity is witness (6)'s job.
  unitAspects = {
    h = {
      nixos.marker = "h";
    };
    u = {
      home.marker = "u";
    };
  };

  # The corpus's `microvm` group shape (nix-config aspects/virtualization/microvm.nix:39-53): a
  # `listOf raw` container holding host ENTRIES beside data-typed siblings.
  guestKindModule =
    { ... }:
    {
      options.microvm.guests = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
      };
    };

  hostsOpt = denCompat.registry.mkHostsOption {
    inherit lib;
    kindModule = guestKindModule;
    aspects = unitAspects;
  };
  applied = hostsOpt.apply {
    x86_64-linux = {
      # same-named aspect present ⇒ the select hits.
      h.users.u = { };
      # NO `den.aspects.orphan` ⇒ v1's warn-and-empty arm.
      orphan = { };
    };
  };
  registry = denCompat.registry.flattenRegistry applied;

  instanceOpts = denCompat.registry.hostInstanceOptions {
    inherit lib;
    kindModule = guestKindModule;
  };

  # ── BRIDGE arm: the M2 wiring (the compat-host-registry harness pattern) ────────────────────────
  mkCrossNixos =
    npkgs:
    (import "${denHoagSrc}/lib/output/terminal.nix" {
      inherit (denHoag.internal) bind flake;
    } { nixpkgs = npkgs; }).crossNixos;
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    inherit mkCrossNixos;
    schema = denHoag.internal.schema;
    denLib = denHoag;
  };
  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
  ev = lib.evalModules {
    modules = [
      flakeStub
      bridge
      (
        { den, ... }:
        {
          den.schema.host.isEntity = true;
          den.schema.host.imports = [ guestKindModule ];
          den.hosts.x86_64-linux.chan = { };
          # THE CORPUS SHAPE, verbatim (nix-config hosts/cortex.nix:14 `microvm.guests = [
          # den.hosts.x86_64-linux.cortex-cuda ]`): a host entry carried by VALUE inside another
          # host's raw container.
          den.hosts.x86_64-linux.carrier.microvm.guests = [ den.hosts.x86_64-linux.chan ];
          den.aspects.chan.nixos.marker = "c";
          den.aspects.carrier.nixos.marker = "k";
        }
      )
    ];
  };
  bridgeHosts = ev.config.den.hosts.x86_64-linux;
  # What a corpus module reads when it writes `den.aspects.chan` itself — the navigation view the
  # bridge binds as the `den` module arg. `host.aspect` must be THIS, not the raw fold.
  navChan = (denCompat.annotatedViewNav ev.config.den).aspects.chan;
in
{
  flake.tests.compat-entity-aspect-field = {
    # (1) the same-named aspect materializes, and the ATTRIBUTE EXISTS — the exact predicate whose
    # falsity aborted the corpus at microvm-guests.nix:43 (`attribute 'aspect' missing`).
    test-host-aspect-materializes = {
      expr = {
        present = registry.h ? aspect;
        value = registry.h.aspect;
      };
      expected = {
        present = true;
        value = unitAspects.h;
      };
    };
    # (2) v1's no-same-named-aspect arm (_types.nix:22-24): a WARNED empty aspect, PRESENT on the
    # entry. A throw here would refuse a fleet v1 evaluates, so the field is total, never missing.
    test-host-aspect-absent-is-empty-not-missing = {
      expr = {
        present = registry.orphan ? aspect;
        value = registry.orphan.aspect;
      };
      expected = {
        present = true;
        value = { };
      };
    };
    # (3) TREE PLACEMENT: `types.raw` ⇒ the #70 lazy raw side channel, NEVER the deepSeq-safe stamp
    # (an aspect tree holds class fns and module trees — precisely the structural-exclusion hazard).
    # The two trees' leaf sets are disjoint by construction, so this pins both halves.
    test-aspect-rides-the-raw-side-channel = {
      expr = {
        raw = denCompat.registry.rawStampTreeOf instanceOpts ? aspect;
        safe = denCompat.registry.stampTreeOf instanceOpts ? aspect;
      };
      expected = {
        raw = true;
        safe = false;
      };
    };
    # (4) the USER twin (v1 entities/host.nix:163-168) — the same `lookupAspect`, keyed by the USER
    # name, on the host-embedded user instance (#71's userType twin).
    test-user-aspect-materializes = {
      expr = {
        present = registry.h.users.u ? aspect;
        value = registry.h.users.u.aspect;
      };
      expected = {
        present = true;
        value = unitAspects.u;
      };
    };
    # (5) THE CLASS ARM: every v1 base-entity DATA option the shim declares answers on a BARE host —
    # one with no authored def for any of them, so each answer is a materialized DEFAULT. Dropping
    # any of them reproduces this bead's defect at a different field, and it fails HERE rather than
    # four layers down at a corpus toplevel.
    # ★ THIS IS A REGRESSION GUARD OVER WHAT IS DECLARED, NOT A COMPLETENESS ORACLE OVER v1'S SET:
    # `hostName` (v1 entities/host.nix:63) and `description` (:74) are pure-data v1 options the shim
    # still does NOT declare — the same shape as `aspect` was, unread by the corpus so far. Adding
    # them to this list is the check that they landed; it cannot tell you they are missing.
    test-base-entity-data-fields-all-answer = {
      expr = builtins.listToAttrs (
        map
          (f: {
            name = f;
            value = registry.orphan ? ${f};
          })
          [
            "name"
            "system"
            "class"
            "aspect"
            "users"
            "intoAttr"
          ]
      );
      expected = {
        name = true;
        system = true;
        class = true;
        aspect = true;
        users = true;
        intoAttr = true;
      };
    };
    # (6) BRIDGE end-to-end: `host.aspect` IS the navigation-view node — identical to what the
    # corpus reads writing `den.aspects.<name>` itself, and carrying native gen-aspects `.key`
    # (A-IDENT identity, born in the type — the raw fold has none). A raw-fold value here would mint
    # a second, key-less aspect surface reachable only through the registry.
    test-bridge-aspect-is-the-navigation-node = {
      expr = {
        isNavNode = bridgeHosts.chan.aspect == navChan;
        key = bridgeHosts.chan.aspect.key;
        # the raw fold is the CONTROL: same name, no `.key` — so the equality above is discriminating.
        rawFoldHasKey = ev.config.den.aspects.chan ? key;
      };
      expected = {
        isNavNode = true;
        key = "chan";
        rawFoldHasKey = false;
      };
    };
    # (7) THE CORPUS READ SHAPE (microvm-guests.nix:38-46): a host entry carried by VALUE inside
    # another host's `listOf raw` schema field still answers `.aspect` — the read that aborted.
    test-carried-guest-entry-answers-aspect = {
      expr = map (vm: {
        inherit (vm) name;
        aspectKey = vm.aspect.key;
      }) bridgeHosts.carrier.microvm.guests;
      expected = [
        {
          name = "chan";
          aspectKey = "chan";
        }
      ];
    };
  };
}
