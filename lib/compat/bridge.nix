# The OUTPUT BRIDGE (ship-gate M1) — den-hoag's flake-parts-side assembly: the single splice mechanism
# that mounts the shim's evaluated fleet at flake-parts option targets (D8). It is what a consumer's
# `imports = [ inputs.den.flakeModule ]` merges into its STRICT flake-parts eval, replacing the bare
# option-declaring export: it DECLARES `options.den`, reads back `config.den`, runs the compat assembly,
# and SETS `config.flake.nixosConfigurations` / `darwinConfigurations` — the drop-in `den` output face.
#
# TWO-EVAL BRIDGE (the C1 boundary at the flake-parts seam; resolves the gen-schema↔nixpkgs type crossing):
# the consumer eval is nixpkgs flake-parts (strict), which CANNOT process gen-schema option types
# (`substSubModules` is a nixpkgs-only method). So the flake-parts-side `options.den` is declared with the
# consumer's NIXPKGS `lib` (the injected module arg — this bridge is the SECOND sanctioned nixpkgs touch,
# after the terminal; it IMPORTS no nixpkgs, lib/** import-purity intact) as a freeform SUBMODULE
# (`freeformType = anything`): den's rich v1 grammar rides through as inert data, DEEP-MERGED across the
# corpus's many `den.*` modules exactly as v1's typed option did (respecting `mkDefault`/`mkForce`), while
# the submodule form remains a legal parent for the `options.den.<x>` sub-options a consumer declares. The
# shim then runs its OWN gen-schema `evalModuleTree` INTERNALLY (`mkDenWith` → `evalV1`) on the single,
# pre-merged `config.den` def — so gen-schema types never enter the consumer's evalModules.
#
# INSTANTIATION (D7): a fleet's per-host nixpkgs crossing is a DECLARED instantiation — the corpus sets
# `host.instantiate = <channel>.nixosSystem` (nix-config schema/host.nix). Honoring that declared per-host
# evaluator is ship-gate M2; THIS milestone (M1) wires the mechanics on the global-fallback grain: when
# `den.nixpkgs` is supplied it crosses ALL nixos members through one `crossNixos` (real NixOS systems),
# else the nixpkgs-free `collect` terminal (the member keys are present — a non-empty `nixosConfigurations`
# — with inspectable module artifacts, not built systems). `den.darwin` is the symmetric fallback; the
# per-host darwin crossing is also M2. `mkDen`/`mkDenWith`/`evalV1` are UNTOUCHED (Law preservation): the
# bridge is flake-parts-side assembly only, so the parity harness (which drives `mkDen` directly) and
# den-hoag's own mkDen-direct paths stay byte-identical.
#
# `mkCrossNixos nixpkgs` — the `crossNixos` builder closure (flake.nix threads `lib.internal.{bind,flake}`
# + the terminal source); called with the consumer-supplied `den.nixpkgs` at fold time.
{
  compat,
  mkCrossNixos,
  schema,
  denLib,
}:
{
  lib,
  config,
  options,
  ...
}:
{
  # nixpkgs-native raw absorption: a freeform SUBMODULE whose `freeformType` deep-merges the whole `den.*`
  # surface (v1 grammar as inert data), and — being a submodule, not a leaf — is a legal PARENT for the
  # `options.den.<x>` sub-options a consumer declares in its own modules (nix-config declares typed
  # `den.clusters`/`den.environments`/`den.groups`/`den.users`/`den.secretsConfig`; a plain `anything` leaf
  # cannot host those). `freeformType = anything` deep-merges the UNDECLARED concerns (den.hosts/aspects/
  # policies/… spread across many modules) exactly as v1's typed options did, respecting mkDefault/mkForce.
  # No gen-schema type enters the consumer's strict eval; the shim re-validates internally (compile's
  # surface-totality gate), so this boundary submodule stays deliberately freeform.
  #
  # SCHEMA PROCESSING (ship-gate M1.75). `den.schema` is the ONE exception to raw absorption: v1's
  # `options.den.schema` is a gen-schema `mkSchemaOption` that PROCESSES raw kind declarations
  # (`den.schema.<K> = { parent; options; isEntity; … }`) into gen-schema KIND-VALUES carrying
  # `{ kind; strict; refs; options; validators; refinements }`. A corpus module reads that processed value
  # at declaration time (`options.den.clusters = mkInstanceRegistry den.schema.cluster`) — so the bridge
  # MUST reproduce the processing, else the corpus's own mkInstanceRegistry throws `attribute 'refs' missing`.
  # We do it as an `apply` (definitions→value transform): the raw declarations arrive as the sub-option's
  # DEFINITIONS; the apply runs the shim's OWN gen-schema (`schema.evalModuleTree` + `mkSchemaOption`) in a
  # NESTED eval — gen-schema types stay INSIDE that eval, never mounted into the consumer's nixpkgs
  # evalModules (the type-crossing dodge, same as the top-level freeform) — and returns the processed
  # kind-values as `config.den.schema`. apply reads the merged DEFINITIONS, never the applied value, so no
  # fixpoint. CROSS-PIN: the corpus's registries READ the kind-value with the corpus's gen-schema; we
  # PRODUCE it with ours — both must agree on the contract field set (a shape mismatch throws NAMED, never
  # silent). This mirrors v1's own read-behavior (v1 den.schema is equally a processing option).
  options.den = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.anything;
      options.schema = lib.mkOption {
        # `anything` (not `raw`): a kind declaration is spread across modules — nix-config sets
        # `den.schema.cluster.{isEntity,imports}` in schema/cluster.nix and `den.schema.cluster.parent` in
        # schema/topology.nix — so the sub-option must DEEP-MERGE them (raw is single-def, would conflict),
        # exactly as v1's typed schema option merged, before the apply processes the merged raw declaration.
        type = lib.types.lazyAttrsOf lib.types.anything;
        default = { };
        # apply = the definitions→value transform. The processed kind-values are what the CORPUS reads
        # (config.den.schema.<K>); the RAW definitions are stashed under `__rawSchema` for the SHIM, which
        # re-processes schema itself (ingest buildRegistries) — feeding it the processed value would
        # double-declare the read-only `_kindNames` (definitions-vs-value split: corpus ← processed, shim ←
        # raw, one apply carries both).
        apply =
          rawSchema:
          (schema.evalModuleTree {
            modules = [
              { options.den.schema = schema.mkSchemaOption { }; }
              { config.den.schema = rawSchema; }
            ];
          }).config.den.schema
          // {
            __rawSchema = rawSchema;
          };
      };
    };
    default = { };
    description = "The den v1 declaration surface (absorbed raw here; desugared by the compat two-eval).";
  };

  # R1 legacy binding: den v1's flakeModule binds `_module.args.den = config.den` at flake scope so every
  # consumer module may reference the `den` arg (`{ den, ... }:` — nix-config's schema/cluster.nix reads
  # `den.schema.cluster`, _settings-type.nix reads `den.lib.aspects.fx.keyClassification`). den v1's `den`
  # arg carries BOTH the config surface (config.den) AND the lib surface at `den.lib` (v1's
  # `options.den.lib`), so the bridge splices the migration lib onto `.lib` — the same drop-in surface
  # `inputs.den.lib` exposes. The shim reproduces the config half separately inside its OWN v1 eval.
  config._module.args.den = config.den // {
    lib = denLib;
  };

  config.flake =
    let
      # `den.nixpkgs`/`den.darwin` are BRIDGE controls (the global-fallback instantiation grain), not v1
      # surface keys — strip them before the shim, whose compile surface-totality gate (C1) rejects any
      # `den.*` key outside the v1 grammar. What remains is the single pre-merged fleet def handed to the
      # shim's internal gen-schema eval (no multi-module conflict — the flake-parts side already merged).
      npkgs = config.den.nixpkgs or null;
      # DECLARED-surface extraction (M1.5): the corpus declares `options.den.<x>` sub-options for its custom
      # kinds' instance registries AND its non-kind config namespaces (secretsConfig). The shim (which reads
      # config VALUES, not the option tree) can't tell a declared namespace from a typo; so the bridge — the
      # ONE place with the flake-parts option surface — reads the DECLARED sub-option names off `options.den`
      # (the freeform submodule's `getSubOptions`, minus the `_freeformOptions` marker) and passes them to
      # compile as the reserved `_declaredKeys`. compile's strict surface-totality classifies these as
      # legitimate (a typo is undeclared, so still aborts). `_`-prefixed ⇒ exempt from totality + ignored by
      # ingest; harmless on the shim's other passes.
      declaredDenKeys = builtins.filter (k: builtins.substring 0 1 k != "_") (
        builtins.attrNames ((options.den.type.getSubOptions or (_: { })) [ ])
      );
      fleet = [
        {
          den =
            builtins.removeAttrs config.den [
              "nixpkgs"
              "darwin"
            ]
            // {
              # the shim gets the RAW schema (it re-processes; the processed value is the corpus's, not ours).
              schema = config.den.schema.__rawSchema or { };
              _declaredKeys = declaredDenKeys;
            };
        }
      ];
      # Instantiation grains: the per-host `host.instantiate` (per-entity grain, ship-gate M2) is honored
      # inside the compat nixos wrapper (flake-module.nix) — a host that declares its own evaluator builds
      # through THAT channel regardless of the two lines below. These control the FALLBACK grain for hosts
      # with no per-host instantiate (M1): one `crossNixos` for every such nixos member when `den.nixpkgs`
      # is set, else the nixpkgs-free `collect` terminal (member keys present, no build).
      built =
        if npkgs == null then
          compat.mkDen fleet
        else
          compat.mkDenWith fleet { nixosTerminal = mkCrossNixos npkgs; };
    in
    {
      # The drop-in `den` output faces (D8 flake-parts option targets).
      nixosConfigurations = built.nixosConfigurations;
      # darwin members cross through `collect`: the compat per-host instantiate wrapper is stamped only on
      # the nixos class (M2), so a darwin host's `host.instantiate` is not yet honored — that is the darwin
      # live corpus run (ship-gate item 2 / class B, `patch`), a trivial stamp of the now class-neutral
      # wrapper onto the darwin class. The member keys are present so `darwinConfigurations` is non-empty
      # and inspectable.
      darwinConfigurations = built.darwinConfigurations;
      # ABSENT (honest, M1): `homeConfigurations` — den-hoag has no standalone-home output yet (den.homes /
      # parity OQ5, board #49); the `perSystem` faces (devShells/packages/apps/checks) — the compat layer
      # produces no per-system class content yet. Both are set only once the shim can honestly produce them.
    };
}
