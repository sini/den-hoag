# THE CORPUS EXCLUDE-FAMILY TAG SET (#72, candidate A — the resolve-family-names.nix twin): the SINGLE
# source of the `den.excludeFamilyNames` knob, threaded by default.nix into compile.nix, where
# `declaredEmitsOf` folds membership into the compiled policy's DECLARED codomain — a name listed here
# contributes `"suppress"` to that policy's `emits`. Matched on the SOURCE REF's v1 `name`, so an excluder
# wired through an include (whose compiled key is synthetic) is reached by the same lookup. The kernel's
# exclude-family feed is then a set-membership test on the compiled rule's `produces`.
#
# A v1 corpus authors `policy.exclude` policies with NO den-hoag codomain declaration, and the corpus's
# excluder is VALUE-CONDITIONAL (`lib.optional (host.class == "droid") …` — it emits nothing at the
# recovery sentinel, whose fields are deliberately NON-MATCHING), so the codomain cannot be RECOVERED by
# firing; the shim DECLARES it here. THE OMISSION CATCH is the CODOMAIN CONTRACT, checked at every firing:
# an excluder omitted here recovers `emits = [ ]`, so the `suppress` it goes on to emit is outside its
# declared codomain and `conformingProduce` aborts NAMED at the emitting site
# (`errors.emitsUndeclared`); a `suppress` naming a policy outside a declared `suppresses` takes the same
# abort one level finer (`errors.suppressesUndeclared`).
#
# Census (nix-config @ b0b20769, the ONE policy-exclude emitter):
#   • drop-user-to-host-on-droid (modules/den/batteries/nix-on-droid.nix:98-104) —
#     `policy.exclude den.policies.user-to-host` at droid-class hosts (v1's suppression of the os-user
#     route where droid lacks the `users` option; registered at `den.default.includes`, :117).
[
  "drop-user-to-host-on-droid"
]
