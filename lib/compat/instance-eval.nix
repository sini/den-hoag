# Per-host SCHEMA-TYPED INSTANCE EVAL (ship-gate M2, fork (i)) — the v1 per-host grain, materialized.
#
# den v1 evaluates every `den.hosts.<sys>.<name>` through the host KIND's instance submodule
# (pin 11866c16 nix/lib/entities/host.nix:53-57 — `hostType = mkInstanceType den.schema.host
# { strict = false; extraModules = [ … ]; }`), so the kind-attached option modules
# (`den.schema.host.imports` — the corpus's channel machinery, nix-config modules/den/schema/
# host.nix:160) apply to EACH instance and their schema-declared per-host defaults MATERIALIZE
# (host.nix:325 `instantiate = lib.mkDefault resolvedChannel.nixosSystem`, the channel table
# :117-142 closing over the corpus's own locked inputs). The shim's bridge crosses RAW authored
# host decls (no instance eval), so those defaults never materialized: ingest's
# `flatHosts.<h>.instantiate or null` read null and the M2 per-entity instantiation grain was
# silently absent — every corpus member fell to the `collect` terminal.
#
# This file reproduces v1's instance eval at the bridge: ONE nixpkgs-lib `evalModules` per host —
# the CONSUMER's `lib` (R10-style; nixpkgs enters as an INERT ARGUMENT, this file imports no
# nixpkgs, the bridge posture) — over
#
#   base entity module  +  the corpus's raw host-kind module  +  the authored host attrs
#
# and returns each eval's LAZY `.config` — the HARVESTED instance, every schema-declared default
# materialized at v1's priorities (authored def 100 < corpus `mkDefault` 1000 < base option
# default 1500). Nothing is forced here: each downstream grain forces only its own option
# (`instantiate` forces channel/class/system, never settings/networking). The bridge stores the
# full harvest (`den._hostHarvest`) so ingest's per-host maps — `instantiateFor` NOW,
# hmModuleFor/secretPathFor when those grains land — all read the SAME eval, never a re-eval.
{ }:
{
  # The CONSUMER's nixpkgs lib (the bridge's injected module arg — R10). Inert data here.
  lib,
  # The corpus's raw host-kind module: the M1.75 emitted kind-value (bridge.nix schema apply) —
  # its `__functor` is module-system-callable on BOTH seam paths (passThroughSeam returns the
  # corpus's raw `{ imports; options }`; the severed processed path is gen-schema's own
  # option-declaring module). `{ }` for a fleet with no host kind declaration (harvest = base-only,
  # every default null, the grain absent — byte-identical to the pre-harvest bridge).
  kindModule,
  # name -> authored host attrs (`den.hosts.<sys>.<name>` flattened, `system` demoted to a field —
  # ingest.nix flattenHosts).
  flatHosts,
}:
let
  inherit (lib) mkOption types;

  # The BASE ENTITY MODULE — v1's hostType instance option surface (pin 11866c16
  # nix/lib/entities/host.nix:53-105), reproduced for exactly the options the corpus kind module
  # reads/writes plus the grain-relevant ones. Everything else v1 declares there (aspect,
  # description, users, intoAttr, mainModule, __resolveResult, __pathSetByScope) reads den v1
  # RUNTIME machinery the shim replaces wholesale — none is a harvested grain, so none is
  # declared; an authored def for one rides the freeform, inert.
  baseEntityModule =
    name:
    { config, ... }:
    {
      # v1 hostType is strict = false (pin :56): unknown authored keys (aspect content, users, …)
      # absorb as inert raw values — never type-walked, never forced.
      freeformType = types.lazyAttrsOf types.raw;
      options = {
        # `name` — gen-schema's mkInstanceType injects the instance key as `name` (pin
        # entities/host.nix:21-23); the corpus reads it (`secretPath`/`facts` defaults,
        # corpus host.nix:319-320).
        name = mkOption {
          type = types.str;
          default = name;
          description = "instance name (gen-schema-injected under v1)";
        };
        # v1 :64 `system = strOpt "platform system" system` (the `den.hosts.<sys>` group key —
        # flattenHosts stamps it as an authored field, so the def is present on every bridge host;
        # raw + null keeps a system-less direct call legal).
        system = mkOption {
          type = types.raw;
          default = null;
          description = "platform system (v1 entities/host.nix:64)";
        };
        # v1 :65-67 — class derived from the platform suffix. null-guarded (a null system derives
        # nixos, matching ingest's classOfHost fallback); an authored `class` (corpus `slab` =
        # "droid") overrides, as under v1.
        class = mkOption {
          type = types.raw;
          default =
            if config.system != null && lib.hasSuffix "darwin" config.system then "darwin" else "nixos";
          description = "os-configuration nix class for host (v1 entities/host.nix:65-67)";
        };
        # v1 :81-105 — `instantiate`, type raw (:96), base default = den v1's OWN flake inputs by
        # class (:98-104, `inputs.nixpkgs.lib.nixosSystem` / `inputs.darwin.lib.darwinSystem`) at
        # option-default priority (1500). THE ONE VALUE DEVIATION (priority-faithful): den-hoag
        # carries no nixpkgs, and its analog of "den's own fallback evaluator" IS the lower
        # instantiation grains (the class N1 declaration / `den.nixpkgs` crossNixos / `collect` —
        # flake-module.nix mkNixosInstantiate). So the base default here is null = "fall to the
        # lower grains", keeping the D7 grain ladder intact. The PRIORITY INTERPLAY is v1's
        # exactly: authored (100) beats the corpus's mkDefault (1000, corpus host.nix:325) beats
        # this base default (1500).
        instantiate = mkOption {
          type = types.raw;
          default = null;
          description = "per-host OS-configuration evaluator (v1 entities/host.nix:81-105; base default = the lower grains here)";
        };
        # v1's `host.home-manager.{enable,module}` — declared NOT by the base entity but by the
        # home-manager BATTERY's hostConf (pin nix/lib/home-env.nix:35-55 `hostOptions`, wired at
        # modules/aspects/batteries/home-manager.nix:28 `den.schema.host.imports = [ result.hostConf ]`);
        # the corpus overrides `.module` channel-driven (corpus host.nix:329-334). Only `module` is
        # declared (the harvested grain): `enable`'s v1 default reads host.users' classes
        # (home-env.nix:44-48), a fleet-membership read no shim grain consumes yet — it lands with
        # the hm grain. Type raw, not v1's deferredModule (:50): raw holds the VALUE byte-identical
        # (the C1 inert-data posture, like instantiate) for the future hmModuleFor grain; the
        # deferredModule imports-wrap belongs to the CONSUMING module eval, not the harvest.
        home-manager.module = mkOption {
          type = types.raw;
          default = null;
          description = "per-host home-manager module (v1 home-env.nix:49-53 via the hm battery hostConf; corpus host.nix:329-334)";
        };
      };
    };

  # ONE instance eval per host. The authored attrs enter as an ordinary config module (definition
  # priority 100 — author wins over every schema default, v1's interplay). DARWIN CEILING
  # (unchanged this rung): a darwin host's harvest materializes `resolvedChannel.darwinSystem`
  # too, but the compat instantiate wrapper is stamped only on the nixos class (flake-module.nix),
  # so it rides inert until the class-B darwin arm stamps the (already class-neutral) wrapper there.
  evalHost =
    name: authored:
    (lib.evalModules {
      modules = [
        (baseEntityModule name)
        kindModule
        {
          _file = "<den-compat-host:${name}>";
          config = authored;
        }
      ];
    }).config;
in
builtins.mapAttrs evalHost flatHosts
