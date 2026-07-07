# den-compat legacy surface SENTINELS — Law C5's error half. Each legacy surface (`provides`,
# `forwards`, …) is desugared by a self-contained tagged module (legacy/*.nix) that the flakeModule
# assembly applies BEFORE compile, CONSUMING the surface (stripping its key). With that module present
# the key is gone by the time compile runs, so the sentinel passes; with it ABSENT (severed), the
# residual key survives into compile and the sentinel fails LOUDLY at definition — naming the surface
# and the module to import — rather than the shim silently dropping a v1 declaration.
#
# This is a SHIM-CORE file (compile.nix imports it): it references ONLY `errors`, never a legacy
# module, so severability holds. A sentinel is the shim core's knowledge that a surface EXISTS (so it
# can refuse it when unhandled), NOT how to desugar it (that stays behind the severable boundary).
# The `forwards` sentinel lands with Task 5; this file grows one builder per legacy surface.
{ errors }:
{
  # A `provides` key on an aspect that reached compile un-desugared ⇒ legacy/provides.nix is absent.
  # `true` when clean, so it composes under `builtins.all` / `builtins.seq` at the compile boundary.
  provides =
    aspectName: aspect:
    if builtins.isAttrs aspect && aspect ? provides then
      errors.legacyProvidesAbsent aspectName
    else
      true;
}
