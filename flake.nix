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
    in
    {
      inherit lib;
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
