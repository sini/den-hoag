# Assemble the structural equations and run gen-resolve. The equation map is built by
# structural.nix (Task 2) and extended by later tasks; this seam just hands (roots,
# equations, parseParent) to gen-resolve.resolve, which forces the Vogt gate + two-stratum
# assert at construction (§8-step2). den over-declares read-edges via readsAttrs, so the
# separate declaredEdges accessor stays empty until later tasks refine it per attribute.
{ resolve }:
{
  roots,
  equations,
  parseParent,
}:
resolve.resolve {
  inherit roots equations parseParent;
  declaredEdges = _: [ ];
}
