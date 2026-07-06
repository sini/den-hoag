# den-hoag

**den-hoag** is the L3 four-concern assembly layer that surfaces the den v2 public
API as pure vocabulary and wiring over the shipped L1/L2 `gen` substrate. It names
entities, compiles concern declarations onto library contracts, and wires the HOAG
evaluation DAG — every algorithm lives in a `gen` library; den-hoag contributes only
naming, forwarding, and attrset assembly.

## The four concerns

| Concern | Meaning | Substrate |
| ------------- | -------------- | --------------------------------------------- |
| **policies** | relationships | effect constructors + `gen-dispatch` dispatch |
| **quirks** | data | one fleet-level `gen-pipe.compose` |
| **classes** | systems | `gen-class` partition / contract / apply / gate |
| **aspects** | behavior | `gen-resolve` over `gen-scope`, settings via `gen-settings` |

## Architecture

den-hoag authors its declaration surface on the pure-gen module system
(`gen-merge.evalModuleTree` + `gen-types` checkers, nixpkgs-lib-free), registers entity
kinds as `gen-schema` registries, expands the fleet as a `gen-product` restricted
product, evaluates the HOAG DAG through `gen-resolve.resolve` over `gen-scope`, resolves
settings via `gen-settings`, flows quirks through one `gen-pipe.compose`, resolves demands
with `gen-demand`, and materializes output through `gen-edge` → `gen-bind` → the single
`gen-flake` nixpkgs crossing, with `gen-class` tier-2 fixed-input core injection as the
default fleet-build path.

Two binding laws govern the assembly:

- **Law A1 (zero machinery).** No convergence, toposort, or product traversal is
  hand-rolled — each is a direct call into a named library. The only recursion den-hoag
  writes is wiring glue.
- **Law A2 (identity law).** Every public API position denoting an entity/aspect/class/kind
  takes a **registry entry** (carrying `id_hash`), never a `"kind:name"` string.

## Usage

Flake consumers use the `.lib` output:

```nix
inputs.den-hoag.url = "github:sini/den-hoag";
# ...
den-hoag.lib.mkDen [ ./your-modules ];
```

Non-flake consumers import the repo root, which self-resolves every dependency from the
pinned `flake.lock`:

```nix
(import ./den-hoag).mkDen [ ./your-modules ];
```

## Development

```sh
ulimit -s unlimited                    # deep module-system evals exceed the 8 MB default stack
nix-unit --flake ./ci#tests            # whole suite
nix-unit --flake ./ci#tests.<suite>    # one suite
```

The suite's HOAG evaluations are deep enough to overflow the default 8 MB C stack; raise it with
`ulimit -s unlimited` (the `ci` pre-commit hook already does this). CI is unaffected.

The library core (`lib/**`) is nixpkgs-lib-free — it uses `gen-prelude` for list/attr/string
helpers. Only `ci/tests/**` may use nixpkgs `lib`.
