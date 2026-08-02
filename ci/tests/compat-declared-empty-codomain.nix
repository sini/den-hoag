# AN EXPLICIT `emits = [ ]` ON THE COMPAT PATH IS THE AUTHOR'S DECLARATION, and the shim honours it rather
# than replacing it with a sentinel probe's answer.
#
# The kernel ruled what an empty codomain MEANS: `emits = [ ]` is an EMPTY HEAD — a rule that compiles, is
# registered at the bottom stratum, fires wherever its gate admits and produces nothing; producing anything
# violates its own codomain and aborts NAMED (concern-policies.nix header; silent-deletion.nix pins it on
# the kernel surface). The compat shim reaches the same field by a different route: `codomainRecordFor` takes the
# source record's own `emits` if there is one, then the corpus fact tables keyed by the v1 name, and only
# then FIRES the body at a value-less sentinel to recover a codomain (`policy-recover.nix`).
#
# ★ WHY THE TWO ROUTES HAD TO BE SEPARATED. While an empty codomain compiled to no rule at all, "declared
# empty" and "probed empty" reached the same place, so a chain arm that skipped a declaration BECAUSE
# it was empty was invisible. Under the empty-head ruling they are different programs: the declaration
# states a rule with an empty consequence set, and the probe result is a GUESS about a body — one that
# a value-conditional body answers wrongly by construction (it takes its false branch at a value-less ctx).
# Reading `[ ]` as "nothing was declared" therefore silently substitutes an inference for a declaration,
# which is the defect shape rather than an instance of it. Every arm now tests PRESENCE.
#
# WHAT THESE FIXTURES DISCRIMINATE, and why the control is not optional. A fixture asserting `emits == [ ]`
# proves nothing on its own: the probe returns `[ ]` for plenty of bodies, so "honoured" and "probed, and
# the probe happened to agree" are the same observation. Every witness here therefore pairs an EMITTING
# body with its own declaration-free twin — the SAME body, the SAME fleet, in the SAME run — so the probe
# is shown LIVE and returning something else at the moment the declaration is shown to win.
#
# THE SECOND CODOMAIN LAYER (`suppresses`/`binds`, compile.nix `codomainRecordFor`) was already presence-keyed
# (`ref.<field> or <recovery>`), so an explicit empty refined codomain always survived; it is pinned here
# because the two layers state one property and a reader has no way to tell which of them a regression
# moved. One row (`suppress`) carries it — both rows are the same expression over `declare.codomainRows`.
{ denCompat, denHoag, ... }:
let
  compile = denHoag.internal.compilePolicies;
  msg = denHoag.internal.policyMessage;
  d = denHoag.declare;
  aborts = x: !(builtins.tryEval (builtins.deepSeq x x)).success;

  # A body that emits UNCONDITIONALLY — at a value-less sentinel too. That is what makes the pair
  # discriminating: undeclared, its codomain recovers `[ "edge" ]`, so an observed `[ ]` can only be the
  # declaration. (`{ name = "a"; }` is a REFERENCE stub, not a content set — `isEmittedContentSet` — so it
  # resolves against `aspects.a` below.)
  edgeBody = _ctx: [
    {
      __policyEffect = "include";
      value = {
        name = "a";
      };
    }
  ];
  # The v1 registry shape a corpus policy arrives in (`mkPolicy` / the bridge's policy coercion): a record,
  # which is the only v1 policy shape with a field to declare a codomain on at all — a bare `ctx:` closure
  # has none, and that asymmetry is the whole reason the recovery exists.
  policyRec =
    extra:
    {
      __isPolicy = true;
      name = "p";
      fn = edgeBody;
    }
    // extra;
  compiledOf =
    extra:
    (denCompat.compile {
      aspects.a = { };
      policies.p = policyRec extra;
    }).policies.p;

  declaredEmpty = compiledOf { emits = [ ]; };
  undeclared = compiledOf { };

  # ── the refined codomain (`suppresses`), same pairing ────────────────────────────────────────────────
  # `policy.exclude <named policy record>` compiles to `declare.suppress { name }` — a NEGATIVE dependency
  # edge, which is why its codomain must be known before the stratification is decided rather than after.
  victim = {
    __isPolicy = true;
    name = "victim";
    fn = _: [ ];
  };
  supRec =
    extra:
    {
      __isPolicy = true;
      name = "s";
      emits = [ "suppress" ];
      fn = _ctx: [ (denCompat.exclude victim) ];
    }
    // extra;
  supCompiledOf =
    extra:
    (denCompat.compile {
      policies.s = supRec extra;
    }).policies.s;

  supDeclaredEmpty = supCompiledOf { suppresses = [ ]; };
  supUndeclared = supCompiledOf { };

  # The compiled compat record IS a den-hoag policy record, so the kernel's own compiler is what says
  # whether the empty head survived the crossing — read through `compilePolicies` rather than asserted of
  # the compat field alone.
  ruleOf = rec': builtins.head (compile { p = rec'; }).policy;
in
{
  flake.tests.compat-declared-empty-codomain = {
    # ── the witness ─────────────────────────────────────────────────────────────────────────────────────
    # THE DECLARATION SURVIVES THE COMPILE. Under the emptiness-keyed guard this was `[ "edge" ]` — the
    # probe's answer, standing in for a declaration the author wrote and nothing reporting the swap.
    test-explicit-empty-emits-is-honoured = {
      expr = declaredEmpty.emits;
      expected = [ ];
    };
    # THE POSITIVE CONTROL, same body and same fleet, declaration removed: the sentinel probe is LIVE in
    # this run and returns something ELSE. Without it the assertion above is satisfied by a probe that
    # merely agreed, and the suite could not tell the two apart.
    test-undeclared-twin-still-probes = {
      expr = undeclared.emits;
      expected = [ "edge" ];
    };

    # ── it is the EMPTY HEAD, not an absent rule (the kernel semantics, reached through compat) ──────────
    # REGISTERED: the crossed record passes definition-time validation. An empty `emits` with the always-
    # stamped `suppresses`/`binds` at `[ ]` is clean — an empty refined codomain asserts no edge, so the
    # spurious-codomain guard does not apply to it (concern-policies.nix `codomainMessage`).
    test-empty-head-registers-clean = {
      expr = msg { p = declaredEmpty; };
      expected = null;
    };
    # COMPILED TO ONE RULE, keeping its identity: the deletion reading yielded no rule at all, which is the
    # state that leaves nothing to look at.
    test-empty-head-compiles-to-one-identified-rule = {
      expr = map (r: r.identity) (compile { p = declaredEmpty; }).policy;
      expected = [ "p" ];
    };
    # AT THE BOTTOM STRATUM, and carrying the empty codomain onward as its own `produces`. Read off
    # `declare.strata` rather than spelled, so inserting a stratum cannot leave this asserting a stale name.
    test-empty-head-is-bottom-stratum-with-empty-produces = {
      expr = {
        bottom = (ruleOf declaredEmpty).group == builtins.head d.strata;
        produces = (ruleOf declaredEmpty).produces;
      };
      expected = {
        bottom = true;
        produces = [ ];
      };
    };
    # AND IT IS ENFORCED. The body emits an edge at every context; against the empty head it declared, the
    # FIRST real emission aborts through the contract every other policy already runs
    # (`conformingProduce` → `errors.emitsUndeclared`) — the honest reading made unavoidable rather than
    # documented. A probe-derived `[ "edge" ]` would have routed this emission silently instead.
    test-empty-head-first-emission-aborts = {
      expr = aborts ((ruleOf declaredEmpty).produce "n" { });
      expected = true;
    };
    # CONTROL for that abort's SCOPE: the undeclared twin, same body, same fleet, resolves and emits. So
    # the abort above is caused by the codomain the author declared and not by the fixture's shape.
    test-undeclared-twin-emits-cleanly = {
      expr = map (a: a.__action) ((ruleOf undeclared).produce "n" { });
      expected = [ "edge" ];
    };

    # ── the refined codomain, the same property one layer down ───────────────────────────────────────────
    # An explicit `suppresses = [ ]` beside a `suppress` head survives: a rule that MAY fire and name
    # nobody is a legal declaration, distinct from one whose suppression set was read off a fire.
    test-explicit-empty-suppresses-is-honoured = {
      expr = supDeclaredEmpty.suppresses;
      expected = [ ];
    };
    # ITS CONTROL: undeclared, the same body's sentinel fire recovers the name it excludes.
    test-undeclared-suppresses-twin-still-recovers = {
      expr = supUndeclared.suppresses;
      expected = [ "victim" ];
    };
    # ENFORCED the same way: the body names `victim` at every context, which the empty suppression codomain
    # does not admit, so the emission aborts NAMED (`errors.suppressesUndeclared`) rather than adding a
    # negative dependency edge the stratification never saw.
    test-empty-suppresses-violation-aborts = {
      expr = aborts ((ruleOf supDeclaredEmpty).produce "n" { });
      expected = true;
    };
  };
}
