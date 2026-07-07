# den-hoag

**den-hoag** is the L3 four-concern assembly layer that surfaces the den v2 public
API as pure vocabulary and wiring over the shipped L1/L2 `gen` substrate. It names
entities, compiles concern declarations onto library contracts, and wires the HOAG
evaluation DAG — every algorithm lives in a `gen` library; den-hoag contributes only
naming, forwarding, and attrset assembly.

## The four concerns

| Concern | Meaning | Substrate |
| ------------- | -------------- | --------------------------------------------------------------- |
| **policies** | relationships | declaration constructors + `gen-dispatch` rule evaluation |
| **quirks** | data | one fleet-level `gen-pipe.compose` |
| **classes** | systems | `gen-class` partition / contract / apply / gate |
| **aspects** | behavior | `gen-resolve` over `gen-scope`, settings via `gen-settings` |

A **policy** is a rule (`den.policies.<name> = ctx: [ declarations ]`) evaluated at graph nodes; a
**declaration** is an inert, tagged graph fact (`spawn`/`link`/`member`/`edge`/`configure`/`demand`/…)
the rule produces. There is no effect runtime — no queue, no resume, no router. A producer *attribute*
computes declaration lists, consumer *attributes* filter them by kind, and attribute demand + edge
toposort are the only evaluation order. See [REFERENCE.md](./REFERENCE.md) for the law index and the
grounded-terminology mapping.

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

`mkDen` takes a list of declaration modules (the fleet) and returns the assembled fleet:

```nix
inputs.den-hoag.url = "github:sini/den-hoag";
# ...
den-hoag.lib.mkDen fleetModules
# => { den; graph; nixosConfigurations; }
```

- **`den`** — the full assembly surface: `schema`/`registries`/`meta` (entities), `fleet`/`cells`
  (the restricted product), `structural` (the resolve eval), `aspectsAt` (the narrow settings accessor),
  `quirkDag`/`receivedOutputs` (the quirk channels), `demandKinds`/`demandResolution`/`demandEdges`
  (the demand stratum), `output` (the edge-fold + per-class terminal), and `graph` (the escape hatch).
- **`graph`** — the read-only graph escape hatch (`scope`/`fleet`/`edges`/`trace`/`demands`); `trace` is
  the frozen, hashable parity oracle E(topology).
- **`nixosConfigurations`** — the `nixos` class's per-host systems, keyed by host name. Set
  `den.nixpkgs` (the nixpkgs flake) in a fleet module to make these REAL NixOS systems (the ONE
  gen-flake crossing); absent, they are the nixpkgs-free `collect` artifacts.

Non-flake consumers import the repo root, which self-resolves every dependency from the
pinned `flake.lock`:

```nix
(import ./den-hoag).mkDen fleetModules
```

### Authoring policies (binding contract)

A policy is `den.policies.<name> = ctx: [ declarations ]`. **The `ctx` function MUST use an OPEN
attrset pattern** — `{ host, ... }:`, never `{ host }:`. `gen-dispatch` calls a policy with the FULL
node context, so a closed pattern throws on the extra keys; the open pattern's `functionArgs` are also
what the guard machinery reads to decide where the policy fires (a policy fires only where every
destructured key is present in the node's context). A channel-named argument — a key that is never a
context binding — therefore never fires, which is the intended idiom for "this policy is inert".

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
