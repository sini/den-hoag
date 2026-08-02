# THE V1 DECLARATION SURFACE, AS ONE LIST — the SINGLE source read by both sites that used to hold a
# copy of it: `flake-module.nix` `v1OptionsModule.options` (where a v1 key is DECLARED as an option) and
# `compile.nix` `knownSurfaceKeys` (where an undeclared `den.*` key ABORTS as a typo).
#
# WHY A FILE AND NOT TWO LISTS PLUS A COMMENT. The two sites were held in step by one comment at each end
# and nothing else — "KEEP IN SYNC with …" — and the tree names both desync directions itself: a key added
# to the options without a row in the gate ABORTS EVERY FLEET, and a key in the gate without an option is
# dead. A comment cannot enforce either. Measured, the four surface-totality tests all exercise the GATE
# and none compares the two lists, so the coupling had no witness at all. Making it ONE list removes the
# invariant rather than checking it: there is no longer a pair that can disagree.
#
# ★ `option = null` IS A REAL ENTRY, NOT AN OMISSION. Three v1 keys are KNOWN surfaces with no declared
# option — they ride `v1OptionsModule`'s `freeformType` and are accepted-and-ignored by the compile. That
# is exactly the "a key here without an option there" direction, and it is DELIBERATE for these three
# rather than dead, so the asymmetry is recorded per key instead of being lost in a list difference.
#
# ★ THE `default` FIELD IS PART OF THE DECLARATION, not a detail: `include` is v1's one LIST-valued
# surface and its option defaults to `[ ]` where every other defaults to `{ }`. Holding the default here
# keeps that fact beside the key it belongs to.
{
  hosts.option = {
    description = "v1 `den.hosts.<system>.<name>` (two-level host definitions).";
    default = { };
  };
  homes.option = {
    description = "v1 `den.homes.<system>.<name>` (standalone home-manager configurations).";
    default = { };
  };
  schema.option = {
    description = "v1 `den.schema.<kind>` (containment kinds + kind-attached includes).";
    default = { };
  };
  aspects.option = {
    description = "v1 `den.aspects.<name>` (aspect definitions).";
    default = { };
  };
  policies.option = {
    description = "v1 `den.policies.<name>` (policy functions / for·when records).";
    default = { };
  };
  classes.option = {
    description = "v1 `den.classes.<name>` (output class registrations).";
    default = { };
  };
  include.option = {
    description = "v1 static entity-scoped aspect inclusions.";
    default = [ ];
  };
  quirks.option = {
    description = "v1 `den.quirks.<name>` (quirk channels).";
    default = { };
  };
  contentClass.option = {
    description = "v1 kind -> content-class overrides.";
    default = { };
  };

  # ── THE CODOMAIN DECLARATION SURFACE ─────────────────────────────────────────────────────────────
  # `den.policyCodomains.<v1 policy name> = { emits; binds; suppresses; }` — the one place a fleet states
  # what a v1 policy's body may produce, beside the lambda and by the lambda's own author.
  # ★★ IT IS THE ONE MEMBER OF THIS SURFACE THAT IS NOT `raw`, AND THAT IS A DESIGN STATEMENT. Every
  # other v1 key is `types.raw` because the v1 grammar is not ours to type — the shim reproduces it and
  # must not mangle it. This key is not reproduced from v1: it is the surface this design OWNS, and its
  # whole enforcement is that a partial record cannot be authored. Typed `raw` here, the totality claim
  # would degrade to an authoring convention nobody can check, with no signal.
  policyCodomains.option = {
    description = "`den.policyCodomains.<v1 policy name> = { emits; binds; suppresses; }` — the fleet-side declaration codomain of a v1 policy, keyed by its v1 source-ref name. TOTAL: all three fields are required, and `[ ]` is a legal value stating that the body produces none of that kind. A declared field is never recovered by firing the body.";
    default = { };
    codomainRecord = true;
  };

  # ── KNOWN SURFACES WITH NO DECLARED OPTION ───────────────────────────────────────────────────────
  # `den.default` — the fleet-wide default includes/settings block, freeform-absorbed.
  default.option = null;
  # `den.reservedKeys` (den v1 `den.reservedKeys`, key-classification.nix:34) — a CONFIG-only v1 key the
  # shim ACCEPTS and IGNORES: it extends v1's structuralKeysSet, which the compat keyClassification export
  # (#49-slice) reproduces STATICALLY (baked `[ "settings" ]`, the corpus's value). No concern reads it,
  # so it is a known surface (never a typo) but has no ingest/compile handler.
  reservedKeys.option = null;
  # `den.batteries` (den v1 `den.batteries.<name>`, modules/aspects/batteries/) — the shim provisions the
  # corpus-consumed batteries at `config.den.batteries.<name>` (lib/compat/batteries.nix). Their VALUES
  # are inert data consumed BY REFERENCE via `den.default.includes` / a user aspect's includes (the v1
  # posture — an UNREFERENCED battery is inert in v1 too), so the KEY is accepted and ignored: no concern
  # reads `den.batteries` itself (a referenced battery rides the include list, not this key), exactly like
  # `reservedKeys`.
  batteries.option = null;
}
