# Class-share output assembly — HOAG tier-3, the DEFAULT fleet-build path (spec §2.10, Laws A17/A18).
# Partition a class's members by class entry id_hash, compose the class-invariant core ONCE, byte-gate
# it, and build each member's output via gen-class `applyCoreFixed` (the tier-2 fixed-input kernel):
# per-class core, per-cell lazy deltas.
#
#   A17 (no fleet flag) — the strategy is PER-CLASS (`share.core`) and PER-CELL lazy. `mkClasses` is the
#     ONLY partition (declared, keyed by class entry id_hash, O(classes)); a member's delta is built
#     only when its output-map entry is forced. There is no fleet-wide switch anywhere in this surface.
#   A18 (implementation, not semantics) — the class-invariant candidate set is the config-independent
#     (gen-pipe `classInvariant`) projection; `mkCore` is the byte-identical intersection (member-varying
#     values drop out); `gateCore` is the ONLY authority a share is sound — a divergent core fails LOUD,
#     never silently reused ("keys narrow, the gate decides", gen-class partition.nix). `applyCoreFixed`'s
#     spine-skip is byte-identical to the ordinary fold by the gen-class tier-2 contract; a member that
#     also defines the core loc falls through, still byte-identical. This file shapes only
#     `systems.<class>.<member>` — `config(root)` and trace E are untouched by `share.core`.
#
# NO EFFECT RUNTIME / Law A1: the body is a partition + attrset assembly + exactly the gen-class calls
# (`mkClasses` / `mkCore` / `gateCore` / `applyCoreFixed`) — no hand-rolled convergence or ordering.
#
# Deps: prelude (map/filter/head/listToAttrs), class (gen-class, imported WITH the gen-merge kernel so
# `applyCoreFixed` fires — flake.nix), errors (the A18 loud-fail).
{
  prelude,
  class,
  errors,
}:
{
  # build { members; classOf; projectionOf; projectionPath; shareCore } -> null | shared-builder.
  #   members        : { <memberId> = node; }  — the members to share (one scope node per member).
  #   classOf        : node -> class entry (carrying id_hash) — the partition key source (A17: declared).
  #   projectionOf   : memberId -> attrs — the member's config-independent (classInvariant) projection
  #                    subtree; its KEYS are what `mkCore` intersects (member-varying keys drop out).
  #   projectionPath : dotted string — the loc the shared core occupies (applyCoreFixed's sole-def leaf).
  #   shareCore      : the class's `share.core` flag. false ⇒ null (the caller uses the ordinary fold).
  build =
    {
      members,
      classOf,
      projectionOf,
      projectionPath,
      shareCore,
    }:
    if !shareCore then
      null
    else
      let
        # A17: the ONE declared partition — members grouped by class entry id_hash (O(classes)). A key
        # only NARROWS the share candidates; the byte gate below is the sole authority (partition.nix).
        classes = class.mkClasses {
          nodes = members;
          keyOf = _name: node: (classOf node).id_hash;
        };

        # Per partition: the config-independent projection per member, and the class-invariant core =
        # the byte-identical intersection (`mkCore`). The projections force here (cheap classInvariant
        # data) — NOT the members' deltas (built lazily in `outputFor`), so per-cell laziness holds.
        perClass = prelude.map (
          cls:
          let
            projections = prelude.listToAttrs (
              prelude.map (m: prelude.nameValuePair m (projectionOf m)) cls.members
            );
            core = class.mkCore {
              class = cls;
              projection = projectionPath;
              inherit projections;
            };
          in
          {
            inherit cls core projections;
          }
        ) classes;

        # The partition entry owning a member (mkClasses is a total partition ⇒ exactly one). A miss is
        # an assembly invariant break (the member set fed to `build` and to `outputFor`/`gate` disagree),
        # never user error — a plain throw, not a named den error.
        entryOf =
          memberId:
          let
            hits = prelude.filter (pc: builtins.elem memberId pc.cls.members) perClass;
          in
          if hits == [ ] then
            throw "den-hoag: class-share: member `${memberId}` is in no class partition (internal invariant)"
          else
            prelude.head hits;

        # gateCore authority (A18): the core's CLAIMED shared values vs the member's REAL projection at
        # those keys (`real` restricted to `sharedKeys` — the core claims only those). `.gate` is true iff
        # byte-identical. Cheap: it re-reads the already-forced projection, never the full merge.
        gateOf =
          memberId: realProjection:
          let
            core = (entryOf memberId).core;
          in
          class.gateCore {
            inherit core;
            candidate = core.values;
            real = builtins.intersectAttrs core.values realProjection;
          };
      in
      {
        inherit perClass;

        # A member's built output = `applyCoreFixed { core; modules = <delta> }.config` (tier-2): the
        # core's projection loc is supplied as a pre-merged `mkCoreValue` — SOLE def ⇒ the merge spine is
        # SKIPPED there (byte-identical to the full fold); a delta that also DEFINES the loc falls through
        # to the full merge (still byte-identical, no skip). `deltaModules` is a gen-merge module LIST.
        outputFor =
          memberId: deltaModules:
          (class.applyCoreFixed {
            core = (entryOf memberId).core;
            modules = deltaModules;
          }).config;

        # The gateCore record (`authorize` is the loud-fail wrapper). Exposed for inspection/tests.
        gate = gateOf;

        # A18 loud-fail: assert the gate before a share is trusted. A divergent core (candidate != real)
        # aborts NAMED (`errors.classShareGate`) — never a silent reuse. Returns `true` on a sound share,
        # so a caller can `builtins.seq (authorize …) (outputFor …)`.
        authorize =
          memberId: realProjection:
          let
            g = gateOf memberId realProjection;
          in
          if g.gate then
            true
          else
            errors.classShareGate {
              member = memberId;
              inherit (g) candidateDigest realDigest;
            };
      };
}
