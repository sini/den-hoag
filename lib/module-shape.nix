# deferredModule SHAPE helpers — the one place that peels a gen-merge deferredModule wrap and decides
# emptiness. Under the single typed tree a class-keyed value is a deferredModule `{ imports = [ … ]; }`
# (gen-merge wraps `{ _file; imports }`), and gen-aspects materializes EVERY registered class key on every
# aspect — an UNSET class defaults to the EMPTY wrap `{ imports = [ { } ]; }`. Several sites need to peel the
# wrap and test whether the real content is empty (class-modules `classSliceOf`'s no-op drop; compile's
# `looksLikeClassContent` empty-deferred guard; the annotate-battery test's content read) — hoisted here so
# the peel/empty rule can never drift. nixpkgs-lib-free (only `prelude` + builtins).
{ prelude }:
rec {
  # Recursively peel a deferredModule wrap (`{ imports = [ … ]; }`) down to its real leaf modules. A leaf is
  # any non-`imports` value (an attrset content module, a function/path module — a guard-fn body).
  unwrapDeferredModule =
    m:
    if builtins.isAttrs m && m ? imports then
      builtins.concatMap unwrapDeferredModule m.imports
    else
      [ m ];

  # Is a deferredModule EMPTY (a declared no-op)? Every unwrapped leaf is an EMPTY attrset (only `_`-prefixed
  # scaffolding keys — `_file`/`_module`). A NON-attrset leaf (a function/path module) is REAL content,
  # NEVER empty. (An `m` that is not a deferredModule wrap at all — e.g. a raw `{ }` body — unwraps to `[ m ]`
  # and is judged by the same leaf rule, so a raw empty body is empty too.)
  isEmptyDeferredModule =
    m:
    builtins.all (
      leaf: builtins.isAttrs leaf && builtins.all (k: prelude.hasPrefix "_" k) (builtins.attrNames leaf)
    ) (unwrapDeferredModule m);
}
