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
