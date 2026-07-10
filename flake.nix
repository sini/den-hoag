{
  description = "den-hoag — the four-concern assembly (den v2 public API) over the gen substrate";

  inputs = {
    gen-prelude.url = "github:sini/gen-prelude";
    gen-algebra.url = "github:sini/gen-algebra";
    gen-types.url = "github:sini/gen-types";
    gen-merge.url = "github:sini/gen-merge";
    gen-schema.url = "github:sini/gen-schema";
    gen-aspects.url = "github:sini/gen-aspects";
    gen-graph.url = "github:sini/gen-graph";
    gen-scope.url = "github:sini/gen-scope";
    gen-resolve.url = "github:sini/gen-resolve";
    gen-select.url = "github:sini/gen-select";
    gen-bind.url = "github:sini/gen-bind";
    gen-dispatch.url = "github:sini/gen-dispatch";
    gen-class.url = "github:sini/gen-class";
    gen-edge.url = "github:sini/gen-edge";
    gen-product.url = "github:sini/gen-product";
    gen-settings.url = "github:sini/gen-settings";
    gen-demand.url = "github:sini/gen-demand";
    gen-pipe.url = "github:sini/gen-pipe";
    gen-flake.url = "github:sini/gen-flake";

    # FORMATTER-ONLY input. The lib/ substrate is nixpkgs-lib-free (ci/tests/zero-machinery +
    # boundary enforce it) and never imports this; nixpkgs enters the root ONLY to supply the
    # committed `formatter` output below, so `nix fmt` works at the repo root. The nixos-unstable
    # tarball matches ci/'s nixpkgs (one nixfmt-rfc-style version across root + CI).
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  };

  outputs =
    inputs@{ ... }:
    let
      lib = import ./lib {
        prelude = inputs.gen-prelude.lib;
        algebra = inputs.gen-algebra.lib;
        types = inputs.gen-types.lib;
        merge = inputs.gen-merge.lib;
        schema = inputs.gen-schema.lib;
        aspects = inputs.gen-aspects.lib;
        graph = inputs.gen-graph.lib;
        scope = inputs.gen-scope.lib;
        resolve = inputs.gen-resolve.lib;
        select = inputs.gen-select.lib;
        bind = inputs.gen-bind.lib;
        dispatch = inputs.gen-dispatch.lib;
        # gen-class WITH the tier-2 fixed-input kernel injected (gen-merge): `applyCoreFixed` (the A10
        # class-share build path) requires it; every tier-1 verb works without it. The flake's own
        # `gen-class.lib` is merge-less (its README §tier-2), so den-hoag re-imports the source with
        # `merge` — the same wiring the gen hub's `mkGenLibs.class` does.
        class = import "${inputs.gen-class}/lib" {
          prelude = inputs.gen-prelude.lib;
          merge = inputs.gen-merge.lib;
        };
        edge = inputs.gen-edge.lib;
        product = inputs.gen-product.lib;
        settings = inputs.gen-settings.lib;
        demand = inputs.gen-demand.lib;
        pipe = inputs.gen-pipe.lib;
        flake = inputs.gen-flake.lib;
      };
      # den-compat (L4) — the den v1 compatibility shim + the two-sided parity harness, on top of the
      # assembled `lib`. `denHoag` = the four-concern API (this flake's `lib`); the shim reaches every
      # gen substrate lib through den-hoag vocabulary and needs only `schema` (id_hash at ingestion)
      # and `edge` (inert legacy records + the frozen trace schema) directly.
      compat = import ./lib/compat {
        denHoag = lib;
        prelude = inputs.gen-prelude.lib;
        schema = inputs.gen-schema.lib;
        edge = inputs.gen-edge.lib;
        # gen-edge's core primitives (`edgeSortKey`/`renderName`/`traceEntryOf`) — the frozen trace
        # renderer the parity harness renders BOTH arms into. gen-edge's public lib deliberately keeps
        # these internal (it exposes `trace`, which uses them), so the harness imports the frozen core
        # by source path — the SAME dev-time pattern the parity flake uses for den v1's `edge.nix`.
        edgeCore = import "${inputs.gen-edge}/lib/core.nix" { prelude = inputs.gen-prelude.lib; };
      };

      # ── Migration-product re-export layer (ship-gate G1 / T1) ─────────────────────────────────────
      # den's consumers (nix-config) import `inputs.den.flakeModule` and author policies with
      # `inputs.den.lib.policy.*` etc. — den v1's TOP-LEVEL attrpaths. den-hoag exposes the same
      # capabilities under `.compat`/`.lib`; this layer re-exports them at den's expected paths so the
      # shim is a drop-in `den` input. THIN by design: a capability that exists in compat is ALIASED; a
      # semantic verb den-hoag does not yet implement is a NAMED THROWING STUB (never a fake — precedent
      # gen-select's `entityKind`) routing to its board task, so a re-probe reads named blockers, not
      # `attribute 'x' missing`. The trivial policy constructors (include/exclude/mkPolicy/pipe) are the
      # v1 `__policyEffect`/`__pipeStage` record constructors, reproduced in compat (`policy-verbs.nix`,
      # ship-gate T3b) and aliased here; the fleet-resolution / instantiation verbs remain stubs (#49/#50).
      stub = ref: task: throw "den-hoag compat: `${ref}` — ${task}";
      migrationLib = lib // {
        # den.lib.policy.* — the policy-authoring vocabulary nix-config writes policies with.
        policy = {
          route = compat.route; # alias — the deliver-surface route descriptor
          provide = compat.provide; # alias — the deliver-surface provide descriptor
          include = compat.include; # alias — v1 `{ __policyEffect = "include"; value = aspect; }`
          exclude = compat.exclude; # alias — v1 `{ __policyEffect = "exclude"; value = aspect; }`
          mkPolicy = compat.mkPolicy; # alias — v1 `{ __isPolicy = true; name; fn; }`
          pipe = compat.pipe; # alias — v1 pipe.{from,filter,…} constructor bag
          resolve = stub "lib.policy.resolve" "the fleet-resolution / fan-out surface (R8; board #49/#50) — not yet available";
          instantiate = stub "lib.policy.instantiate" "the declarable-instantiation surface (board #50) — not yet available";
        };
        # den.lib.aspects.* / resolveEntity / home / capture — v1 lib surfaces (semantic; escalated).
        aspects = {
          resolve = stub "lib.aspects.resolve" "the aspect-resolution surface (board #49) — not yet available";
          fx.keyClassification = stub "lib.aspects.fx.keyClassification" "the fx key-classification surface (board #49) — not yet available";
        };
        resolveEntity = stub "lib.resolveEntity" "the entity-resolution surface (R8; board #49/#50) — not yet available";
        home = stub "lib.home" "the home-entity surface (board #49) — not yet available";
        capture.captureFleet = stub "lib.capture.captureFleet" "the fleet-capture surface (board #49) — not yet available";
      };
    in
    {
      lib = migrationLib;
      inherit compat;

      # den-v1-compatible TOP-LEVEL flake outputs (the drop-in migration surface — G1/T1). `flakeModule`
      # is what nix-config's `modules/den/flake-parts.nix` imports; `flakeModules.default` is the
      # flake-parts convention alias. `flakeModules.dendritic` (a den-diagram optional v1 carried) is
      # intentionally absent — nix-config guards it `or {}` (ship-gate G1e, low priority).
      # `compat.flakeModule` is a LIST of flake-parts modules; den's consumers import it as a SINGLE
      # module (`imports = [ inputs.den.flakeModule ]`), so wrap the list into one module — matching den
      # v1's single-module flakeModule shape and avoiding "Module imports can't be nested lists".
      flakeModule = {
        imports = compat.flakeModule;
      };
      flakeModules.default = {
        imports = compat.flakeModule;
      };

      # The committed formatter config — `nix fmt` at the repo root runs `nixfmt-tree` (treefmt
      # preconfigured with nixfmt-rfc-style, the ecosystem's Nix formatting convention agents
      # formatted by before this pinned it). It traverses the tree and formats `.nix` with the SAME
      # nixfmt the ci/ treefmt + the pre-commit hook run, so root `nix fmt` is idempotent with them.
      # (ci/'s treefmt additionally runs actionlint + mdformat for the CI format gate; this root
      # output is the self-contained `nix fmt` a visitor runs.)
      formatter = inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed (
        system: inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree
      );
    };
}
