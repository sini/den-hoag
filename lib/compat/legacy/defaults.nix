# den-compat LEGACY surface: `defaults` (R4 + the built-in battery membership, spec §10).
#
# R4 — `den.default` RADIATION + BUILT-IN MEMBERSHIP. den v1 `modules/aspects/defaults.nix` radiates the
# `den.default` aspect as a schema include to EXACTLY kinds `{ host, user, home }` (`lib.genAttrs [ "host"
# "user" "home" ]` — this replaced the `*-to-default` policies). The RADIATION itself is already compiled
# by the shim core (compile.nix `defaultAspects`/`defaultPolicy`: `den.default` → the reserved `__default`
# aspect + a `__denDefault` policy destructuring `{ host, ... }`, whose canTake guard fires at host + user
# cells and never at a custom-kind scope — the three-kind narrowing, compat-surface.nix).
#
# This module carries the OTHER half R4 names: the BUILT-IN MEMBERSHIP — the batteries that v1 self-appends
# to `den.default.includes` (`os-to-host`, `user-to-host`, and the always-included predicate builders).
# It composes the corpus-exercised battery ports (`legacy/batteries/*`) into ONE pure v1 → v1 desugar,
# each adding its class bucket (R2) + built-in policy (R3/R6). PINNED, not widened: only the batteries the
# corpus exercises are ported (os-class R3, os-user R6); the rest (hjem, maid, tty-autologin, wsl, …) get
# explicit ledger rows — no hallucinated content (the C6 `canTake` finding stands; spec §10 R6).
#
# SEVERABLE (Law C5): applied by flake-module.nix `desugarLegacy` when in the wiring's legacy set. Severed
# ⇒ the identity; an aspect using a battery class (`os`/`user`) then aborts as an unknown key (R9).
{
  prelude,
  errors,
  ...
}@deps:
let
  batteries = {
    os-class = import ./batteries/os-class.nix deps;
    os-user = import ./batteries/os-user.nix deps;
  };
  batteryList = builtins.attrValues batteries;
  # Compose the battery desugars left-to-right: each is a pure v1 → v1 transform ADDING its bucket +
  # policy (the additions are disjoint keys — os/user buckets, os-to-host/user-to-host policies — so the
  # fold order is irrelevant, but pinned left-to-right for determinism).
  composeDesugars = prelude.foldl' (
    acc: b: v1:
    b.desugar (acc v1)
  ) (v1: v1) batteryList;
in
{
  _denCompat.legacy = "defaults";

  # The batteries' registered classes (R2), for the rule-witness test's assertion.
  registeredClasses = prelude.concatMap (b: b.registersClasses) batteryList;

  # The set of built-in battery policy names R4 pins as den.default's membership (R3/R6). A test asserts
  # these appear after the desugar — the pinned-membership half of R4.
  builtinPolicyNames = [
    "os-to-host"
    "user-to-host"
  ];

  # NON-PORTED batteries (corpus-unexercised at the frozen pin) — the honest ledger, not silent omission.
  # A future corpus bump exercising one re-opens its port here (spec §10 R6).
  nonPortedBatteries = [
    "define-user"
    "flake-parts"
    "flake-scope"
    "hjem"
    "host-aspects"
    "hostname"
    "import-tree"
    "insecure"
    "maid"
    "primary-user"
    "tty-autologin"
    "unfree"
    "user-shell"
    "vm-autologin"
    "wsl"
  ];

  desugar = composeDesugars;

  inherit batteries;
}
