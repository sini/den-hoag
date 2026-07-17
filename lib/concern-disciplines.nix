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
  pipe,
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
      # BY REFERENCE the production ALGEBRA: `algebra.record.foldLayers` is the same gen-algebra fold
      # gen-settings' `resolveAll` applies — production calls the TRACED variant `foldLayersTraced`
      # (gen-settings/lib/resolve.nix), this references the untraced `foldLayers`; they are SIBLING
      # implementations (gen-algebra rec.nix), value-pinned byte-identical by gen-algebra's own suite
      # (`traced.value == untraced`), so referencing either fixes the same algebra. Three facts make this
      # binary combine exact: (i) production's per-aspect strategies instantiate a strategy-INDEXED FAMILY
      # of monoids — the declared combine samples a REPRESENTATIVE member (the all-`replace` default,
      # `strategies = { }`); (ii) the binary decomposition is exact because replace/append/recursive are
      # each associative per field, so folding `[ a b ]` pairwise equals folding the whole layer list;
      # (iii) our value-agreement pin folds THIS combine over the live layer values and reproduces the live
      # resolved value, closing the loop — a drift is caught there and by the order oracle.
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
        # the §2.7 linearization order the live fold lays the layers down in: within `contains` the
        # ancestor slices ascend by containment count (least-specific first); the `slice` tier is the
        # cell's own full-coordinate slice (projection `via` before direct override at that slice).
        withinTier = "linearization";
        tieBreak = null; # single layer per (aspect, scope, rendered) — no producer ties
      };
    };

    # collections-neron (§6 / B5): the channel-contribution fold — the pinned neron traversal (self →
    # imports → parent, gen-scope) folded by gen-pipe's `run` under the channel's associative-only
    # combine. The fold is ORDER-BEARING (the neron sequence is a fixed order), so laws = ordered-monoid;
    # a per-channel `merge` string may declare STRONGER laws for its OWN channel individually (the
    # semilattice-set channel class, say) — this instance declares the ORDER discipline the traversal obeys.
    collections-neron =
      let
        # the COMPILED channel record — its `combine`/`init` are the SAME fields gen-pipe's fold
        # (evaluate.nix `channelValue`) applies. Reference them BY VALUE (never a hand-restated append):
        # a probe channel is compiled here purely to read its default fold algebra.
        probeChannel = pipe.channel { name = "collections-neron"; };
      in
      {
        laws = "ordered-monoid";
        empty = probeChannel.init; # the fold seed (gen-pipe default `[ ]`), by reference
        combine = probeChannel.combine; # the associative-only left-fold combine (default `a: b: a ++ b`)
        engine = "gen-pipe run (B5 pinned-sequence ordered fold)";
        # PRODUCTION TRUTH: quirk channels default `dedup = null` — there is NO unified default dedup; a
        # channel COLLAPSES duplicates only when it DECLARES one (spec §6 per-channel declared dedup;
        # register item #2). So the instance declares dedup = null; keep/identity are gen-pipe's
        # per-declaration defaults when a channel opts in (the keep-first golden exercises an opted-in one).
        dedup = null;
        order = {
          tiers = [ "neron" ]; # one tier: the pinned self → imports → parent traversal IS the order
          withinTier = "traversal:neron"; # the traversal-valued rank (the §6 vocabulary)
          # same-position multi-producer ties break on the A12 triple (rank, id_hash, emissionIndex) —
          # the identity term is the aspect id_hash, PINNED (scope-adapter.nix `producerLt`).
          tieBreak = "a12";
        };
      };

    # reach-closure (§1/§2): the per-scope single-visit resolved-aspect closure — the OWN/structural
    # subtree component FIRST (verbatim), then each positive reach-edge's target aspects, first-occurrence
    # deduped by aspect-ident key, transitively. It is a set-semantics closure (idempotent under re-reach),
    # so laws = join-semilattice — the fixpoint law: idempotence is what makes the reachable-set converge
    # (Datafun). NO fold-code change (declaration-only); the reach fold stays let-bound in resolved-aspects.
    reach-closure = {
      laws = "join-semilattice";
      empty = [ ];
      # DOCUMENTED RESTATEMENT (review-sanctioned for this one instance): the production fold is let-bound
      # inside the reach attribute (resolved-aspects.nix `addNode`/`addTarget`) — no separable unit, and
      # exporting one is not warranted for a declaration-only instance. This restates the EDGE-closure
      # algebra: append `b`, keeping only its not-yet-seen keys (first-occurrence dedup by `.key`). The
      # PROOF CHAIN certifying it matches production is threefold: (i) the property harness law-checks the
      # restatement (associativity + identity + commutativity + idempotence) — note commutativity holds
      # only UP TO THE KEY-SET QUOTIENT: on the raw list carrier `combine [a] [b] = [a b] ≠ [b a]`, but the
      # closure's semantic value is the key-SET it induces, on which union commutes (the join-semilattice
      # is over key-sets, the list is a canonical-order representative); (ii) the ORDER ORACLE asserts the
      # live reach attribute's order matches the declared tiers; (iii) the VALUE-AGREEMENT pin folds this
      # combine over the live structural + edge components and reproduces the live reach list. Together
      # they certify the restatement IS the production algebra.
      combine =
        a: b:
        let
          seen = builtins.foldl' (acc: n: acc // { ${n.key} = true; }) { } a;
        in
        a ++ builtins.filter (n: !(seen ? ${n.key})) b;
      engine = "reach in-attribute ordered fold (resolved-aspects)";
      # THE RULING RECORD (review-refuted, carried — the dedup key STAYS aspect-ident):
      # (1) the previously-planned key→id_hash migration is VACUOUS — `id_hash = hashString
      #     "den-aspect:${key}"` (concern-aspects.nix: "Same key ⇒ same id_hash") is a BIJECTION of the
      #     key, so the seen-set is extensionally identical under either; Shape B's path-bearing keys
      #     already de-collided the nested same-leaf-name shape. The key therefore stays `aspect-ident`.
      # (2) reach's EDGE identity (the bare `target` string, resolved-aspects.nix "no separate edge-id
      #     field yet") ports onto the unified edgeId scheme at the substrate-CONSUMPTION step (reach edges
      #     live in the aspect graph, whose endpoints are not entity instances) — RE-STAGED, not dropped.
      dedup = {
        key = "aspect-ident";
        keep = "first";
        # NEVER structural — the structural-subtree component emits per-provider multiplicity VERBATIM
        # (distinct descendant scopes are distinct ctx-eval results, the u24 content-loss exemption) and
        # seeds the seen-set; dedup gates the reach-edge closure ONLY.
        appliesTo = [ "reach-edge" ];
      };
      order = {
        tiers = [
          "structural"
          "reach-edge"
        ];
        withinTier = "traversal:subtree-dfs"; # own node then descendants in lexicographic-DFS order
        tieBreak = null;
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
