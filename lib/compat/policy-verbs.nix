# The v1 STRUCTURAL policy-verb surface (`den.lib.policy.{include,exclude,mkPolicy,pipe}`) as inert
# record constructors — the compat twin of the same-named verbs in den v1 `nix/lib/policy-effects.nix`.
# These are PERMANENT user-API constructors a corpus policy body calls (siblings of the
# `deliver`/`route`/`provide` delivery surface in `deliver.nix`), NOT severable legacy desugars: each
# produces the exact tagged record `compile.nix`/`pipe.nix` ALREADY consume, so this file is constructor
# SHAPE only — every semantic (edge/drop translation, pipe-stage folding) lives downstream.
#
#   • include/exclude → `{ __policyEffect = "include"|"exclude"; value = aspect; }` — translated by
#     `compile.nix` `translateEffect` to `declare.edge`/`declare.drop` (v1 policy-effects.nix:175/182).
#   • mkPolicy name fn → `{ __isPolicy = true; name; fn; }` — the named-policy record `compile.nix`
#     `innerFn` unwraps (v1 policy-effects.nix:450).
#   • pipe.{from,filter,…} → the `{ __policyEffect = "pipe"; … }` head + `{ __pipeStage = "<k>"; … }`
#     stages `compile.nix` `translateEffect`(kind="pipe") + `pipe.nix` `compilePipe` fold (v1
#     policy-effects.nix:296–350). The corpus (@b0b2076) uses none of the pipe verbs — it is reproduced
#     for v1-surface totality, byte-identical to v1 so a future pipe-using body compiles unchanged.
#
# nixpkgs-lib-free: builtins only (record construction is inert data; no `prelude`/`errors` needed).
_: {
  # Inject an aspect into the current resolution context.
  include = aspect: {
    __policyEffect = "include";
    value = aspect;
  };

  # Remove/gate an aspect from the current resolution tree (context-matched).
  exclude = aspect: {
    __policyEffect = "exclude";
    value = aspect;
  };

  # Create a named policy record for use in includes.
  mkPolicy = name: fn: {
    __isPolicy = true;
    inherit name fn;
  };

  # `resolve` — v1's fleet-resolution / fan-out functor bag, REPRODUCED EXACTLY from the frozen pin
  # (den nix/lib/policy-effects.nix:128-171 @ sg0zid5qgicrs1fcxn11bxgsafv8kl2d-source). Each arm builds the
  # tagged `{ __policyEffect = "resolve"; … }` record `compile.nix` `translateEffect` (kind == "resolve")
  # consumes: the `__targetKind`-dispatching arm turns a cell-kind target into a bare `member` tuple and a
  # root-kind target into a CONTAINMENT `member` (`containTo` set — §3c-UNIFIED, `relate` dissolved). Constructor SHAPE
  # only — no semantic here (the pin's own comments: `resolve` creates a fan-out branch; `.shared` a non-
  # isolated one; `.to` names the target kind; `.withIncludes` rides classes with the resolved node).
  #   resolve.to "user" { user = e; } ⇒
  #     { __policyEffect = "resolve"; __shared = false; __targetKind = "user"; value = { user = e; }; includes = [ ]; }
  # CORPUS CENSUS (nix-config @ b0b20769, modules/den/policies/): ONLY `resolve.to "<kind>" { … }` is
  # exercised (users/fleet/clusters) — bare `resolve`, `resolve.withIncludes`, `resolve.shared.*` and
  # `resolve.to.withIncludes` are v1-surface totality (reproduced faithfully so a future body compiles
  # unchanged); the compile arm gives the corpus-unexercised arms a NAMED abort (never silent).
  resolve =
    let
      # mkResolve — a plain fan-out (no explicit target); mkResolveWith rides `includes`; mkResolveTo names
      # the target KIND (`__targetKind`); mkResolveToWith does both. Every arm is the pin's verbatim record.
      mkResolve = shared: bindings: {
        __policyEffect = "resolve";
        __shared = shared;
        value = bindings;
        includes = [ ];
      };
      mkResolveWith = shared: includes: bindings: {
        __policyEffect = "resolve";
        __shared = shared;
        value = bindings;
        inherit includes;
      };
      mkResolveTo = shared: kind: bindings: {
        __policyEffect = "resolve";
        __shared = shared;
        __targetKind = kind;
        value = bindings;
        includes = [ ];
      };
      mkResolveToWith = shared: kind: includes: bindings: {
        __policyEffect = "resolve";
        __shared = shared;
        __targetKind = kind;
        value = bindings;
        inherit includes;
      };
    in
    {
      __functor = _: mkResolve false; # resolve { bindings } — plain isolated fan-out
      withIncludes = mkResolveWith false; # resolve.withIncludes includes bindings
      shared = {
        __functor = _: mkResolve true; # resolve.shared { bindings } — non-isolated fan-out
        to = mkResolveTo true; # resolve.shared.to "kind" { bindings }
        withIncludes = mkResolveWith true; # resolve.shared.withIncludes includes bindings
      };
      to = {
        __functor = _: mkResolveTo false; # resolve.to "kind" { bindings } — explicit target kind
        withIncludes = mkResolveToWith false; # resolve.to.withIncludes "kind" includes bindings
      };
    };

  # The pipe policy vocabulary: `pipe.from name [ stages ]` heads a channel derivation; the remaining
  # constructors are the inert stage records `compilePipe` folds left-to-right (`pipe.nix`).
  pipe = {
    from = pipeNameOrRef: stages: {
      __policyEffect = "pipe";
      value = {
        pipeName = if builtins.isAttrs pipeNameOrRef then pipeNameOrRef.name else pipeNameOrRef;
        inherit stages;
      };
    };
    filter = pred: {
      __pipeStage = "filter";
      fn = pred;
    };
    transform = fn: {
      __pipeStage = "transform";
      inherit fn;
    };
    fold = fn: init: {
      __pipeStage = "fold";
      inherit fn init;
    };
    append = value: {
      __pipeStage = "append";
      inherit value;
    };
    for = fn: {
      __pipeStage = "for";
      inherit fn;
    };
    withProvenance = {
      __pipeStage = "withProvenance";
    };
    to = aspects: {
      __pipeStage = "to";
      inherit aspects;
    };
    as = targetPipeName: {
      __pipeStage = "as";
      inherit targetPipeName;
    };
    expose = {
      __pipeStage = "expose";
    };
    broadcast = pred: {
      __pipeStage = "broadcast";
      fn = pred;
    };
    collect = pred: {
      __pipeStage = "collect";
      fn = pred;
    };
    collectAll = pred: {
      __pipeStage = "collectAll";
      fn = pred;
    };
  };
}
