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
#
# DECLARE, not rewire: the three shipped merge orders are DECLARED here as framework instances, each
# `combine` being a REFERENCE to the SAME algebra its production fold applies (the fold stays in its
# owning gen lib — Law A1). An order-oracle test proves each declaration matches the live fold, so a
# drifted reference is caught; the `engine` field names the production fold nominally.
{
  prelude,
  algebra,
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

  # The framework-reserved instance names — the three shipped merge orders (settings-layers /
  # collections-neron / reach-closure). A user re-registration aborts NAMED, the same posture as a
  # framework-reserved edge kind: the framework vocabulary is not user-overridable. The framework itself
  # populates them through `frameworkInstances` (below), as each merge order is declared.
  reservedNames = [
    "settings-layers"
    "collections-neron"
    "reach-closure"
  ];
  reservedSet = prelude.genAttrs reservedNames (_: true);

  # ── THE FRAMEWORK MERGE-ORDER INSTANCES (spec §6) — DECLARE, not rewire ──────────────────────────
  # Each shipped fold is DECLARED as a discipline instance whose `combine` REFERENCES the same algebra
  # the production fold applies; an order-oracle proves the declaration matches the live fold, so a
  # drift is caught. `order` renders the merge order (tiers + within-tier rank + tie-break); `engine`
  # names the production fold NOMINALLY (the fold ENGINE leg, realized as a reference, never a re-wire).
  frameworkInstances = {
    # settings-layers (§2.7): the per-(node, aspect) layer fold — schema defaults, then the containment
    # chain (least-specific first), then the scoped-override slices, then the terminal policy layer. The
    # fold is ORDER-BEARING last-wins-per-field, so laws = ordered-monoid (NOT commutative — a later
    # layer overrides an earlier one at a shared field).
    settings-layers = {
      laws = "ordered-monoid";
      # per-field record fold — identity is the empty record (NOT the empty list): `foldLayers` over no
      # layers is `{ }`, and folding it in changes nothing.
      empty = { };
      # BY REFERENCE the production fold: `algebra.record.foldLayers` is the SAME gen-algebra unit
      # gen-settings' `resolveAll` applies (gen-settings/lib/resolve.nix: "the single fold implementation,
      # never reimplemented here"). Three facts make this binary combine exact: (i) production's per-aspect
      # strategies instantiate a strategy-INDEXED FAMILY of monoids — the declared combine samples a
      # REPRESENTATIVE member (the all-`replace` default, `strategies = { }`); (ii) the binary
      # decomposition is exact because replace/append/recursive are each associative per field, so folding
      # `[ a b ]` pairwise equals folding the whole layer list; (iii) the reference target is that same
      # gen-algebra unit, so a drift is caught by the settings-layers order oracle.
      combine =
        a: b:
        algebra.record.foldLayers {
          strategies = { };
          layers = [
            a
            b
          ];
        };
      engine = "gen-algebra record.foldLayersTraced";
      dedup = null; # no same-aspect-twice collision at the layer fold
      order = {
        tiers = [
          "schema-default"
          "contains"
          "slice"
          "policy"
        ];
        # product count-major within `slice`; containment depth descending within `contains` (least-
        # specific first) — the §2.7 linearization order the live fold lays the layers down in.
        withinTier = "linearization";
        tieBreak = null; # single layer per (aspect, scope, rendered) — no producer ties
      };
    };
  };

  # A registry entry's canonical fields (spec §5). `laws` names the ladder class (REQUIRED); `empty` +
  # `combine` are the identity + binary operation the laws constrain (REQUIRED). `dedup` (`{ key; keep;
  # appliesTo }`) and `order` (`{ tiers; withinTier ? null; tieBreak ? null }`) are the collapse + total-
  # order declarations a merge instance may carry; absent ⇒ null. `engine` NAMES the production fold
  # (the fold-engine reference, framework instances only); absent ⇒ null. Their SUB-SHAPE is passed
  # through unvalidated here — the sub-field checks land with the framework instance declarations that
  # populate them (the instances are the only writers of dedup/order/engine in this step).
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
        engine = raw.engine or null;
      };

  # `compile { disciplines }` → the validated compiled discipline table (a `mapAttrs` + validation fold,
  # mirroring concern-classes' / edges' compile shape). The framework merge-order instances SEED the
  # table (their reserved names are theirs to write); a USER registration merges beside them. Re-
  # registering a framework-reserved instance name aborts NAMED before any entry is built.
  compile =
    {
      disciplines ? { },
    }:
    let
      reservedOffenders = builtins.filter (n: reservedSet ? ${n}) (builtins.attrNames disciplines);
      allRaw = frameworkInstances // disciplines;
    in
    if reservedOffenders != [ ] then
      throw "den.disciplines: instance '${builtins.head reservedOffenders}' is framework-reserved"
    else
      prelude.mapAttrs entryOf allRaw;
in
{
  inherit
    lawClasses
    reservedNames
    compile
    ;
}
