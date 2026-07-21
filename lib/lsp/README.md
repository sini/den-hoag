# `den.lib.lsp` — the nixd projection surface

This lib re-keys a built den fleet's static declarations into the shape a Nix LSP
([nixd](https://github.com/nix-community/nixd)) walks for completion, hover, and goto. It is
**pure builtins** (no gen/prelude dependency, so `lib/**` stays nixpkgs-lib-free) and, by design,
**declaration-only**: every projection reads schema/aspect/library declarations and never forces a
fleet's resolved output or enters den's fx pipeline / materialization.

## The nixd contract (E0, cache-once)

nixd's option-provider config is `nixd.settings.options.<name>.expr`, a **string** holding a Nix
expression. A nixd worker evaluates that expression **once**, interprets the result as an option
declaration tree (an attrset whose leaves carry `_type == "option"` with `type` / `description` /
`default`), caches it, and walks it lazily for completion/hover/goto. The evaluated value is **never
re-invalidated** while the worker lives — so the expression must be cheap and side-effect-free with
respect to den: it must serve only *declarations*, never run the fx pipeline or force resolved
output. That is exactly what these projections guarantee (see the laziness guarantee below).

## The three projections

`den.lib.lsp.forNixd` is the convenience entry. Given a **built** den and the gen-lib `internal`
bundle it returns the three ready-to-serve projections, keyed as their nixd option-provider names:

| nixd `options.<name>` | value | what it completes |
| --------------------- | ----- | ----------------- |
| `den`                 | `optionsProjection { options = den._options; }` | the fleet's option-declaration tree (`den.*` options), each leaf carrying real `declarationPositions` (goto) |
| `den-aspects`         | `aspectsProjection { aspects = den.aspects; }`  | each declared aspect as a submodule, its settings (§2.6) as sub-options |
| `gen`                 | `genLibProjection { internal = den.lib.internal; }` | the gen substrate libraries' member names + `functionArgs` formals |

**Reaching `internal`.** The gen-lib `internal` bundle rides the **library** (`den.lib.internal`),
not the built den value — a built den (`mkDen … .den`) exposes `_options` and `aspects` but not the
raw libs. So `forNixd` takes both:

```nix
den.lib.lsp.forNixd {
  den = (den.lib.mkDen fleetModules).den;   # carries _options + aspects
  inherit (den.lib) internal;               # carries the 19 gen libs
}
```

The three projections are also exposed individually (`den.lib.lsp.optionsProjection`,
`aspectsProjection`, `genLibProjection`, and the reusable `positions` layer) if a consumer wants to
serve a subset.

## Consumer wiring

Expose the projections at any flake output, then point each nixd `options.<name>.expr` at it. A flake
output is chosen (over inlining the whole `mkDen` in the `expr` string) so nixd re-reads it cheaply
and the expression stays short:

```nix
# flake.nix — expose the projection surface for nixd
{
  outputs = { self, den, ... }: {
    # … your fleet's modules live somewhere, e.g. `self.fleetModules` …
    lspOptions = den.lib.lsp.forNixd {
      den = (den.lib.mkDen self.fleetModules).den;
      inherit (den.lib) internal;
    };
  };
}
```

Then the nixd config — as JSON (`.nixd.json` / editor `settings`):

```json
{
  "options": {
    "den": {
      "expr": "(builtins.getFlake (builtins.toString ./.)).lspOptions.den"
    },
    "den-aspects": {
      "expr": "(builtins.getFlake (builtins.toString ./.)).lspOptions.\"den-aspects\""
    },
    "gen": {
      "expr": "(builtins.getFlake (builtins.toString ./.)).lspOptions.gen"
    }
  }
}
```

…or the same in Nix (e.g. a home-manager `nixd.settings` block):

```nix
nixd.settings.options = {
  den.expr = ''(builtins.getFlake (builtins.toString ./.)).lspOptions.den'';
  "den-aspects".expr = ''(builtins.getFlake (builtins.toString ./.)).lspOptions."den-aspects"'';
  gen.expr = ''(builtins.getFlake (builtins.toString ./.)).lspOptions.gen'';
};
```

Note the inner quoting: the `den-aspects` key needs escaped quotes in the JSON `expr` string
(`.\"den-aspects\"`) and literal quotes in the Nix attr-path (`.\"den-aspects\"` → `."den-aspects"`),
because the attribute name is not a bare identifier.

Verify any `expr` in `nix repl` before wiring it into your editor — a nixd worker surfaces an eval
error only as absent completions.

## The laziness guarantee

Because a nixd worker evaluates each `expr` once and never re-invalidates it, the served value must be
declaration-only. `ci/tests/lsp-laziness.nix` pins this: it builds a fleet whose **resolved output
carries a live `throw`**, then `deepSeq`s the entire `forNixd` surface — the option tree (including
every leaf's `declarationPositions`), the aspect registry (including each node's
`type.getSubOptions {}`, which forces its settings records), and the gen-lib surface — and asserts it
resolves clean, *while* forcing the poisoned resolved output genuinely throws. That single guard keeps
the whole LSP surface fx-pipeline-free.
