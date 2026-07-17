# The merge-discipline registry (`den.disciplines.<name>`, spec §5) — compile + laws-ladder validation.
# A discipline NAMES the algebra a merge site obeys: an identity (`empty`) and a binary operation
# (`combine`) constrained by a `laws` class on the ladder. The ladder is a subsumption chain — an
# ordered monoid (associativity + identity) refines to a commutative monoid (+ commutativity), which
# refines to a join-semilattice (+ idempotence, the ACI convergence of Shapiro et al.'s CRDTs); `shadow`
# stands apart (Leijen's scoped-label last-wins record merge). The class GATES a capability: a fixpoint
# closure needs a join-semilattice (Arntzenius & Krishnaswami's Datafun restriction — idempotence is
# what makes the reachable-set iteration converge). The registry only DECLARES the algebra; the
# production folds live in their owning libs (Law A1) and the property harness proves the declaration
# matches. See REFERENCE.md.
#
# NO EFFECT RUNTIME: `compile` is one `mapAttrs` + a validation fold — field defaults + laws-ladder
# checks, no algorithm (Law A1; mirrors concern-classes / edges). A `combine` value is a FUNCTION: a
# registry holds functions freely — the fingerprint law (identity.nix) bans functions from EDGE DATA
# only, never from a registry entry.
{
  prelude,
}:
let
  # The laws ladder (spec §5) — the CLOSED set of algebraic classes a discipline may declare. A name
  # outside this set is a definition error (there is no fallback class).
  lawClasses = [
    "ordered-monoid"
    "commutative-monoid"
    "join-semilattice"
    "shadow"
  ];
  lawSet = prelude.genAttrs lawClasses (_: true);

  # The framework-reserved instance names — the three shipped merge orders declared in later steps
  # (settings-layers / collections-neron / reach-closure). A user re-registration aborts NAMED, the same
  # posture as a framework-reserved edge kind: the framework vocabulary is not user-overridable.
  reservedNames = [
    "settings-layers"
    "collections-neron"
    "reach-closure"
  ];
  reservedSet = prelude.genAttrs reservedNames (_: true);

  # A registry entry's canonical fields (spec §5). `laws` names the ladder class (REQUIRED); `empty` +
  # `combine` are the identity + binary operation the laws constrain (REQUIRED). `dedup` (`{ key; keep;
  # appliesTo }`) and `order` (`{ tiers; withinTier ? null; tieBreak ? null }`) are the collapse + total-
  # order declarations a merge instance may carry; absent ⇒ null. Their SUB-SHAPE is passed through
  # unvalidated here — the sub-field checks land with the framework instance declarations that populate
  # them (the instances are the only writers of dedup/order in this step).
  entryOf =
    name: raw:
    let
      laws =
        raw.laws
          or (throw "den.disciplines: discipline '${name}' declares no laws — one of ${builtins.toJSON lawClasses} is required");
    in
    if !(lawSet ? ${laws}) then
      throw "den.disciplines: discipline '${name}' declares unknown laws '${laws}' — one of ${builtins.toJSON lawClasses}"
    else if !(raw ? empty) then
      throw "den.disciplines: discipline '${name}' declares no empty — the identity element is required"
    else if !(raw ? combine) then
      throw "den.disciplines: discipline '${name}' declares no combine — the binary operation is required"
    else
      {
        inherit laws;
        inherit (raw) empty combine;
        dedup = raw.dedup or null;
        order = raw.order or null;
      };

  # `compile { disciplines }` → the validated compiled discipline table (a `mapAttrs` + validation fold,
  # mirroring concern-classes' / edges' compile shape). Re-registering a framework-reserved instance name
  # aborts NAMED before any entry is built.
  compile =
    {
      disciplines ? { },
    }:
    let
      reservedOffenders = builtins.filter (n: reservedSet ? ${n}) (builtins.attrNames disciplines);
    in
    if reservedOffenders != [ ] then
      throw "den.disciplines: instance '${builtins.head reservedOffenders}' is framework-reserved"
    else
      prelude.mapAttrs entryOf disciplines;
in
{
  inherit
    lawClasses
    reservedNames
    compile
    ;
}
