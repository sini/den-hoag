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

### A worked fleet

`ci/tests/_fixtures/fleet.nix` (`acceptance`) is a complete, copyable fleet exercising every concern —
a two-host nixos fleet with users, a cluster `link`, the `projects` facet, two quirk channels, a
deferred (config-demanding) channel, and a `database` demand cascade. Copy its module list as a
starting point. Two things there are test plumbing to strip: the `permute` flag (it reorders unrelated
policy modules to prove channel-order stability) and the `saboteur`/throwing-content aspect the
end-to-end suite injects (a laziness probe, not part of the fixture).

### Authoring policies (binding contract)

A policy is `den.policies.<name> = ctx: [ declarations ]`. **The `ctx` function MUST use an OPEN
attrset pattern** — `{ host, ... }:`, never `{ host }:`. `gen-dispatch` calls a policy with the FULL
node context, so a closed pattern throws on the extra keys; the open pattern's `functionArgs` are also
what the guard machinery reads to decide where the policy fires (a policy fires only where every
destructured key is present in the node's context). A channel-named argument — a key that is never a
context binding — therefore never fires, which is the intended idiom for "this policy is inert".

A policy may also be a **rule record** `den.policies.<name> = { __condition; fn }`: `__condition` is the
gate declared as DATA (a `functionArgs`-shaped coord set — `{ host = false; }` requires a `host` in
scope), and `fn` is the same `ctx: [ declarations ]` body. This is the general form for a policy whose
gate cannot be shaped as literal formals (a programmatically-generated policy), with identical firing
semantics to the equivalent open pattern. A policy's **stratum** (B2) is normally read from a probe of
its body; a policy whose emission is gated on a context VALUE (so it emits nothing at the probe, or
throws doing value-work against the sentinel) has its stratum derived PER DECLARATION at dispatch —
each declaration produced in its own stratum's phase — so a value-conditional resolution or structural
policy is authored plainly, no probe-shaping required. A per-declaration policy may only emit
`structural`/`resolution` declarations; an `enrich` or `pipeOp` declaration from one aborts loud (those
are probe-time feed/compose commitments a value-conditional policy cannot make).

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

**Pin-bump discipline.** `ci/` and `parity/` pin this tree via `path:..`, and their locks carry
FLATTENED transitive copies of the root's inputs — a root pin bump does NOT propagate to them.
After changing any root `flake.lock` pin, re-resolve both in the same commit:

```sh
nix flake lock ./ci     --update-input den-hoag
nix flake lock ./parity --update-input den-v2
```

A stale subflake lock evals the OLD dependency (e.g. a missing new lib function) even though the
root lock is current.
