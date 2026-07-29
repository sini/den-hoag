# The edge-kind registry (`den.edges.<kind>`, spec §2.2) + the pre-identity-freeze override tier (§2.4)
# + the edge-assembly pipeline (§2.1). The registry DESCRIBES every typed-edge kind — its structural
# stratum, product typing, algebraic discipline; den-hoag pre-registers the framework vocabulary and a
# user registers beside it. `assembleEdges` runs SYNTHETIC edge intents through overrides → two-level
# identity → fill-graph acyclicity → gen-edge records stamped with `kind`. Every algorithm delegates to a
# named lib (Law A1: mapAttrs + validation for the registry; the identity module for the hashes; the
# override fold for the tier; gen-edge's `edge` for the record). See REFERENCE.md.
{
  prelude,
  identity,
  edge,
  reservedRegistry,
  # the graft-site dispatch (receivers.nix) + the mode-execution engine (nest.nix), threaded in for the
  # cell/containment nest-edge producer: `resolveReceiver` is the receiver-gate predicate, `executeNest` the
  # content-arm graft, `checkSingular` the wiring-time singular mount check. Used ONLY by `nestProducer`; the
  # registry/override/assembly surfaces never touch them (so forcing those never forces the receivers/nest
  # libs).
  resolveReceiver,
  executeNest,
  checkSingular,
}:
let
  # The framework-pre-registered kinds, their strata and their projection targets (spec §2.2/§7):
  # contains/include/kindOf are structural; member/reach/reach-suppress resolution (selector-driven
  # membership targets a later stratum per §2.3, and literal declared membership rides the same kind
  # harmlessly); nest/defer are OUTPUT — a stratum the framework itself registers through the den.strata
  # dense-insertion mechanism after `demand` (the seed stays the shipped four; the framework dogfoods the
  # extension). `demand` is the demand-stratum edge kind demand's `toEdges` stamps — the first live
  # labeled kind (its records cite this registry row).
  #
  # BOTH FIELDS ARE REQUIRED HERE — there is no `or` on either, and that totality is the point. A `to`
  # read through a default says *a kind that did not declare its projection target delivers content*: a
  # decision made silently, at a site four files from this seed, in the wrong direction. This is the one
  # place where the framework's own vocabulary is enumerated in full, so a framework kind that has not
  # said where it projects is an INCOMPLETE DECLARATION, not a materializing one — after this, adding a
  # reserved kind without a `to` is an eval error HERE rather than a silent trace entry later.
  #
  # THE RULE, not the enumeration: a kind is `materialize` IFF IT DELIVERS CONTENT. Structural and
  # resolution kinds are assertions ABOUT the graph — they answer topology questions and belong in the
  # query pool; output and demand kinds CARRY CONFIGURATION. `demand` must stay `materialize`:
  # `edgesForRoot = materializeFilter (edge.edgesFor {…} ++ demandEdges)` puts demand edges on the
  # materialization trace by design.
  preRegisteredKinds = {
    contains = {
      stratum = "structural";
      to = "query";
    };
    include = {
      stratum = "structural";
      to = "query";
    };
    kindOf = {
      stratum = "structural";
      to = "query";
    };
    member = {
      stratum = "resolution";
      to = "query";
    };
    reach = {
      stratum = "resolution";
      to = "query";
    };
    reach-suppress = {
      stratum = "resolution";
      to = "query";
    };
    nest = {
      stratum = "output";
      to = "materialize";
    };
    defer = {
      stratum = "output";
      to = "materialize";
    };
    demand = {
      stratum = "demand";
      to = "materialize";
    };
  };
  reservedNames = builtins.attrNames preRegisteredKinds;

  # The strata the registry itself requires: `output` (nest/defer) enters the compiled order through the
  # SAME `den.strata.insert` machinery the user surface uses — dense-inserted after `demand`.
  frameworkStrataInserts = {
    output = {
      after = "demand";
    };
  };

  # closureMessage — the closure-capability law (spec §2.2) as a VALUE: null when the `{ closure; discipline }`
  # pair is lawful (closure = false is a no-op), else the NAMED message. Factored out of `entryOf` so BOTH the
  # edge registry AND the den.derived closure field-gate validate the SAME law (one source of truth —
  # re-implementing would fork it), AND so the NAMED contract is CI-testable (Nix's `tryEval` cannot capture a
  # throw's text). A closure declaration is legal ONLY under a registered join-semilattice discipline whose
  # carrier is ACC (idempotence is what makes the reachable-set fixpoint converge — Datafun — and the
  # ascending-chain condition is what bounds its iteration to a finite fixpoint). `disciplines` is the compiled
  # disciplines registry; `subject` + `name` name the locus — `subject` defaults to the edge-registry prefix,
  # and a caller (e.g. a den.derived field-gate) passes its own so the message names ITS surface.
  closureMessage =
    disciplines:
    {
      name,
      closure,
      discipline,
      subject ? "den.edges: kind",
    }:
    if closure && discipline == null then
      "${subject} '${name}' declares closure = true with no discipline — closure requires a declared discipline; discipline laws are validated by the disciplines registry"
    else if closure && !(disciplines ? ${discipline}) then
      "${subject} '${name}' declares closure = true with discipline '${discipline}', which is not in the disciplines registry — closure requires a registered join-semilattice discipline"
    else if closure && disciplines.${discipline}.laws != "join-semilattice" then
      "${subject} '${name}' declares closure = true with discipline '${discipline}' (laws '${disciplines.${discipline}.laws}') — closure is legal ONLY under a join-semilattice discipline"
    # the ACC obligation: a JSL discipline whose carrier is not ACC (finite-height) cannot bound the fixpoint
    # iteration. This branch NEVER fires on the corpus — the only shipped JSL discipline (reach-closure) is
    # acc = true (a join-semilattice compiles acc = true FREE, concern-disciplines.nix `entryOf`) — so it is a
    # NEW message that leaves every existing closure edge / derived closure green.
    else if closure && !(disciplines.${discipline}.acc or false) then
      "${subject} '${name}' declares closure = true with discipline '${discipline}' (join-semilattice but not ACC) — closure requires an ACC / finite-height carrier: the ascending-chain condition is what bounds the reachable-set fixpoint iteration"
    else
      null;

  # closureGate — the thin throwing wrapper over closureMessage: aborts NAMED when the pair is unlawful, else
  # null. `entryOf` uses this with the default subject, so the compiled edge-kind table's throw text (and thus the
  # frozen-71 corpus + edges.nix's own suite) is byte-identical to the pre-extraction inline gate.
  closureGate =
    disciplines: args:
    let
      m = closureMessage disciplines args;
    in
    if m != null then throw m else null;

  # A registry entry's canonical fields (spec §2.2). `data` is the per-kind edge-data schema; `requires`/
  # `produces` are the product typing (relation/derived kinds; unused by nest, whose typing derives from
  # its endpoint registries); `discipline` names the algebraic laws; `inverse` enables reverse queries;
  # `closure` is legal ONLY under a join-semilattice discipline (validated against the disciplines registry).
  # `to ∈ { query, materialize, both }` (spec §7) is the PROJECTION TARGET — the parity-load-bearing tag: an
  # edge-production declares WHERE its edges land. `query` is OFF the materialization trace (a relation/query
  # edge — parity-safe); `materialize` is ON the trace (real config, like demandEdges); `both` lands on both.
  # The `raw.to or "materialize"` default below is scoped to the USER surface (`den.edges` kinds), where it
  # is the documented and tested contract; the `den.relations` desugar (`relationsToEdgeKinds`) overrides it
  # to `query`, keeping relation edges provably off the frozen trace. The FRAMEWORK rows never reach this
  # default — `preRegisteredKinds` states every reserved kind's `to`, and the seed passes it through, so the
  # `raw.to` read finds it. Making the seed total while keeping the user default is the whole point: the
  # framework's vocabulary is declared, the user's is defaulted.
  entryOf =
    disciplines: name: raw:
    let
      e = {
        data = raw.data or null;
        requires = raw.requires or null;
        produces = raw.produces or null;
        discipline = raw.discipline or null;
        inverse = raw.inverse or null;
        closure = raw.closure or false;
        # a USER kind reusing a reserved name inherits that name's stratum off the seed row. The whole
        # select path binds before the final `or`, so a non-reserved name falls to "resolution" as before.
        stratum = raw.stratum or preRegisteredKinds.${name}.stratum or "resolution";
        to = raw.to or "materialize";
      };
    in
    # the shared closureGate validates the closure capability (present discipline + join-semilattice laws),
    # aborting NAMED on each degenerate case; `seq` forces the gate before the entry is handed back.
    builtins.seq (closureGate disciplines {
      inherit name;
      inherit (e) closure discipline;
    }) e;

  # `compile { kinds; strataOrder; disciplines }` → the validated compiled kind table (a `mapAttrs` +
  # validation fold, mirroring concern-classes' compile shape). Pre-registered kinds seed the table; a
  # user kind merges beside them. Re-registering a framework kind name aborts NAMED; a `stratum` outside
  # the compiled order aborts NAMED. `disciplines` is the COMPILED disciplines registry (spec §5): the
  # closure gate validates a closure kind's discipline against it (present + join-semilattice laws).
  compile =
    {
      kinds ? { },
      strataOrder,
      disciplines ? { },
    }:
    let
      strataSet = prelude.genAttrs strataOrder (_: true);
      # the reserved seed is the pre-registered framework rows — its keyset is the reserved set (a user
      # kind re-registering one aborts NAMED inside the combinator) and its values pre-populate the table
      # (allRaw = seed // kinds). BOTH declared fields ride through: `entryOf` reads `raw.to` and finds
      # the seed's, so no framework row is ever classified by the user-surface default.
      compiled = reservedRegistry.mkReservedRegistry {
        subject = "den.edges";
        noun = "kind";
        reserved = prelude.genAttrs reservedNames (n: {
          inherit (preRegisteredKinds.${n}) stratum to;
        });
        entryOf = entryOf disciplines;
        table = kinds;
      };
      # every entry's stratum must name a stratum in the compiled order. A POST-compile guard (it reads
      # `compiled.<n>.stratum`), so it stays at the call site wrapping the combinator result — forcing
      # `compiled` fires the combinator's reserved throw first, preserving the reserved-then-stratum order.
      stratumOffenders = builtins.filter (n: !(strataSet ? ${compiled.${n}.stratum})) (
        builtins.attrNames compiled
      );
    in
    if stratumOffenders != [ ] then
      throw "den.edges: kind '${builtins.head stratumOffenders}' names unknown stratum '${
        compiled.${builtins.head stratumOffenders}.stratum
      }' (not in the compiled order)"
    else
      compiled;

  # ── the projection filter (spec §7, the parity-load-bearing seam) ──────────────────────────────────────
  # `projectsMaterialize compiledKinds edge` — does this edge land ON the materialization trace? It reads the
  # edge's `kind` label, looks up the kind's `to` projection target in the compiled table, and keeps `to ∈
  # { materialize, both }`. Excluded: every registered `to = query` kind — the `den.relations` desugar, AND
  # the framework's own structural/resolution vocabulary (contains/include/kindOf/member/reach/
  # reach-suppress), which the seed above declares `query` because they assert things ABOUT the graph rather
  # than delivering content. This is what keeps a `contains` edge off the materialization trace by
  # DECLARATION rather than by the accident that the query pool is never concatenated into `edgesForRoot`.
  #
  # TWO `absence ⇒ materialize` decisions remain here, and they are DIFFERENT facts, both KEPT deliberately:
  #   • `k == null` — an UNLABELED edge, the corpus content-edge majority. An edge with no kind label IS
  #     content; this default is parity-preserving and stays.
  #   • `compiledKinds.${k}.to or "materialize"` — a LABELED edge naming a kind in the table nowhere. NOT
  #     "an edge I cannot classify" but an UNREGISTERED LABEL. Kept on a REACHABILITY argument, not on a
  #     frozen-path one: exactly three constructors put edges into this filter's input (gen-edge's
  #     `defaultEdges`, `deliveryEdgesAt`'s `renderDelivery`, and `demandLib.toEdges`), and only the third
  #     passes a `kind` at all — the literal "demand", whose row exists by the seed's totality. So the
  #     residual arm's reachable set is empty today. It EXPIRES the moment a new producer stamps a `kind`
  #     on an edge reaching `edgesForRoot`; at that point the same absence-is-a-decision argument the seed
  #     makes applies here, and `assembleEdges` in this very file is the in-file precedent for the remedy
  #     (it aborts NAMED on an intent naming an unregistered kind). The two sites disagree today; that is
  #     recorded rather than resolved, because resolving it changes the delivery-edge path.
  # `materializeEdges` is the list filter output-modules.nix applies to `edgesForRoot`.
  projectsMaterialize =
    compiledKinds: e:
    let
      k = e.kind or null;
      to = if k == null then "materialize" else (compiledKinds.${k}.to or "materialize");
    in
    to == "materialize" || to == "both";
  materializeEdges = compiledKinds: edges: builtins.filter (projectsMaterialize compiledKinds) edges;

  # ── den.overrides: the pre-identity-freeze match/rewrite tier (spec §2.4) ──
  # Framework-emitted NEW-substrate edge INTENTS (`{ kind; from; to; data ? {}; }`) pass through the
  # override list BEFORE their edgeId is computed. An override is `{ match; rewrite; }`:
  #   • `match` — an attrset of PRE-HASH coordinates `{ kind ?; from ?; to ?; data ? { <field> = v; } }`.
  #     Every STATED coordinate must EQUAL the edge's (kind/from/to by whole value; `data` per-field);
  #     an absent coordinate is a wildcard. Matchers are STRUCTURAL DATA ONLY — no function-valued
  #     matchers (consistent with the fingerprint law; a selector-language upgrade is a later step).
  #     A `null` field VALUE in `match.data` matches both an explicitly-null and an absent edge field —
  #     there is no "explicitly null only" matcher in v1 (the null≡absent conflation is deliberate).
  #   • `rewrite` — an attrset data-patch shallow-merged into `data` (`//`), or `null` = SUPPRESS the
  #     edge entirely (it contributes nothing downstream).
  # SINGLE-STEP: one pass over the list per edge, FIRST match wins, the rewritten edge is NEVER
  # re-matched (a rewrite that would satisfy a later entry's match does not re-fire).
  matchCoords = [
    "kind"
    "from"
    "to"
    "data"
  ];
  matchesEdge =
    match: edge:
    builtins.all (
      coord:
      if coord == "data" then
        builtins.all (f: (edge.data.${f} or null) == match.data.${f}) (builtins.attrNames match.data)
      else
        match.${coord} == (edge.${coord} or null)
    ) (builtins.attrNames match);
  applyOverrides =
    {
      overrides ? [ ],
      edges,
    }:
    let
      # definition-time totality: a match coordinate outside the closed set aborts NAMED.
      badCoordsOf = o: builtins.filter (c: !(builtins.elem c matchCoords)) (builtins.attrNames o.match);
      malformed = builtins.concatMap badCoordsOf overrides;
      # first-match scan (no prelude findFirst — an inline recursive scan): returns the rewritten edge,
      # or `null` to SUPPRESS, or the unchanged edge if nothing matches. Never re-matches a rewrite.
      overrideEdge =
        edge: os:
        if os == [ ] then
          edge
        else
          let
            o = builtins.head os;
          in
          if matchesEdge o.match edge then
            (if o.rewrite == null then null else edge // { data = (edge.data or { }) // o.rewrite; })
          else
            overrideEdge edge (builtins.tail os);
    in
    if malformed != [ ] then
      throw "den.overrides: match coordinate '${builtins.head malformed}' is not one of ${builtins.toJSON matchCoords}"
    else
      builtins.filter (e: e != null) (map (e: overrideEdge e overrides) edges);

  # ── assembleEdges: override → two-level identity → fill-graph acyclicity → stamped record (§2.1) ──
  # SYNTHETIC-ONLY in this step: no live producer routes through here yet (a live producer arrives with
  # later spec steps). An intent is
  #   `{ id; kind; from = { entityId; class; s ? {}; }; to = <same>; data ? {}; when; }`.
  # `id` is a readable, stable, producer-supplied string (e.g. "family:<family>:<entity>",
  # "nest:<outer>/<inner>:<slot>") — REQUIRED, read as the source key (never a hash). `when` is an
  # optional demand-condition carried by producers, read at the demand step (this step neither reads
  # nor defaults it).
  # Order (the reviewer-ratified §2.4 rider): overrides match the RAW intent (pre-normalization — "pre-hash
  # coordinates" are the as-declared coordinates), THEN identities are computed on the surviving intents.
  #
  # data schema enforcement arrives with live producers — see REFERENCE.md

  # every string leaf of a structural fill (the producer-id references recorded IN S, §2.1).
  stringLeaves =
    v:
    if builtins.isString v then
      [ v ]
    else if builtins.isAttrs v then
      prelude.concatMap stringLeaves (builtins.attrValues v)
    else if builtins.isList v then
      prelude.concatMap stringLeaves v
    else
      [ ];

  assembleEdges =
    {
      kinds,
      overrides ? [ ],
      intents,
    }:
    let
      # unknown-kind guard (definition-time, named): every intent's kind must be a registered edge kind.
      unknownKinds = builtins.filter (i: !(kinds ? ${i.kind})) intents;
      # id guard (definition-time, named): every intent must carry a readable `id` — it is the source
      # identity key. A missing `id` is otherwise a bare attribute error the moment the source key is
      # forced (uncatchable by tryEval); this makes the requirement observable and names the locus.
      idlessIntents = builtins.filter (i: !(i ? id)) intents;
      # the override tier runs on the RAW intents; identities are computed on the survivors.
      survivors = applyOverrides {
        inherit overrides;
        edges = intents;
      };
      # per side: the content coordinate (assemblyId) and the placement (instanceId over canonical S).
      sideIdentity =
        side:
        let
          aid = identity.assemblyId {
            inherit (side) entityId class;
          };
        in
        {
          entityId = side.entityId;
          instanceId = identity.instanceId {
            assemblyId = aid;
            s = side.s or { };
          };
          s = side.s or { };
        };
      resolved = map (
        i:
        let
          from = sideIdentity i.from;
          to = sideIdentity i.to;
        in
        {
          inherit from to;
          record = edge.edge {
            # The intent's data is the value source, KEYED by the intent's readable `id` — the source
            # identity that rides into the trace (a stable producer-supplied string, never a hash). The
            # target root is keyed by the `to` instanceId (the placement). The record carries the STAMPED
            # kind + the frozen (T,P,S,M,K) key. The edge's derived identity is the source key, not an
            # `annotations` stamp: gen-edge annotations are provenance/diagnostics, never read by
            # materialize, and its `traceEntryOf` folds the SOURCE identity (this key) into the trace.
            source = edge.sources.keyedValue {
              key = i.id;
              value = i.data or { };
            };
            target = edge.targets.root {
              root = to.instanceId;
              class = i.to.class;
            };
            kind = i.kind;
            # PLACEMENT: `merge` at the root (`path = [ ]`) is the DEFAULT — an un-decorated intent rides
            # exactly as before. A nest intent opts into `mode = "nest"` + its placement `path` (the
            # producer resolves the path from the receives row's `at`, so assembleEdges stays receives-
            # agnostic), making the nest edge a substrate citizen: its placement enters the (T,P,S,M,K)
            # trace.
            #
            # ENDURING INVARIANT (the two-facet kernel — the Backpack content-vs-artifact facet split,
            # §4.2): this record's `path` is TRACE / IDENTITY only. The content GRAFT is OWNED by the
            # mode-execution engine (nest.nix `executeNest`), which places a content slice PER MODULE
            # (`placeSlice at payload` — one wrap per module). gen-edge's own nest-materialize wraps the
            # WHOLE value once (`setAttrByPath path <list>`); the two are NOT equal for a module-list
            # payload, so the whole-list materialize is NEVER the content path. A future live fold must
            # consume nest content through `executeNest`, never by feeding this record's `path` to gen-edge
            # `materialize` — the trace facet and the content facet are distinct and never conflated.
            mode = i.mode or "merge";
            path = i.path or [ ];
          };
        }
      ) survivors;
      # The fill-reference graph (§2.1: "which producer-ids appear in whose S"), declared ACYCLIC. Nodes
      # are PER INSTANCE, keyed by instanceId — the instanceId is computable pre-check (S is literal data
      # in this vocabulary; it never contains the node's own instanceId, so there is no hash regress). The
      # check runs over the declared nominal reference structure per instance — the well-foundedness of
      # identity computation. Entity-sugar refs (an entityId string leaf in S) resolve ONLY when the entity
      # has exactly one instance in the assembly; a literal instanceId string leaf resolves directly (the
      # spec's own reference vocabulary). Checked ONCE per assembly.
      sides = prelude.concatMap (r: [
        r.from
        r.to
      ]) resolved;
      instanceIdSet = prelude.genAttrs (map (s: s.instanceId) sides) (_: true);
      # entityId -> the instanceIds it has in this assembly (an entity may fan out to several instances).
      # gen-prelude.groupBy buckets the sides by entity (order-preserving), then each bucket's instanceIds
      # are first-occurrence deduped — folding unique over the ordered bucket equals the original per-append
      # unique.
      entityInstances = builtins.mapAttrs (_: ss: prelude.unique (map (s: s.instanceId) ss)) (
        prelude.groupBy (s: s.entityId) sides
      );
      # resolve one S string leaf to a referenced instanceId, or `null` if it names nothing in the
      # assembly. A literal instanceId is a direct ref; an entityId is INSTANCE-DISCRIMINATING sugar —
      # it resolves iff the entity has exactly ONE instance here, else it is ambiguous and aborts NAMED
      # (resolving it to ALL the entity's instances would re-derive the entity quotient — the very
      # false-positive this keying removes).
      resolveRef =
        leaf:
        if instanceIdSet ? ${leaf} then
          leaf
        else if entityInstances ? ${leaf} then
          (
            let
              is = entityInstances.${leaf};
            in
            if builtins.length is == 1 then
              builtins.head is
            else
              throw "den.edges: assembleEdges structural-fill reference to entity '${leaf}' is ambiguous — it has ${toString (builtins.length is)} instances in this assembly; reference an instanceId"
          )
        else
          null;
      refsOf = side: builtins.filter (r: r != null) (map resolveRef (stringLeaves side.s));
      # instanceId -> its resolved structural-fill refs. gen-prelude.groupBy buckets by instanceId
      # (order-preserving), then each bucket's refs are concatenated in side order and first-occurrence
      # deduped — folding unique over the ordered concat equals the original per-side unique.
      fillGraph = builtins.mapAttrs (_: ss: prelude.unique (prelude.concatMap refsOf ss)) (
        prelude.groupBy (s: s.instanceId) sides
      );
    in
    if unknownKinds != [ ] then
      throw "den.edges: assembleEdges intent names unknown kind '${(builtins.head unknownKinds).kind}' (not in the registry)"
    else if idlessIntents != [ ] then
      throw "den.edges: assembleEdges intent (kind '${(builtins.head idlessIntents).kind}') lacks a required `id` — the id is the source identity key (spec §2.1)"
    else
      # checkFillAcyclic runs once per assembly; a cycle aborts NAMED (identity module). `seq` forces the
      # check before the records are handed back, so a cyclic assembly aborts rather than emitting.
      builtins.seq (identity.checkFillAcyclic fillGraph) (map (r: r.record) resolved);

  # ── nestProducer: the cell/containment nest-edge producer (§4.2/§4.6) ─────────────────────────────────
  # Reads the fleet's containment pairs (fleet.nix `containmentPairs`) and, for each parent→child pair whose
  # parent kind carries a receives row the pair DISPATCHES (slot ≻ class), emits a NEST production. Each
  # production is three coherent views of ONE mount: an `intent` (the `{ id; kind; from; to; data; mode;
  # path; when? }` shape — ridden by `assembleEdges` for identity/override/acyclicity + the trace), a
  # `contribution` (the `executeNest` content-arm graft — the payload placed at the row's `at`), and the
  # resolved `row`/`inner`/`ctx` handles. THE RECEIVER-GATE PREDICATE (corpus-inertness): a pair is emitted
  # IFF its parent kind is a registered receiver AND `resolveReceiver` returns non-null. A corpus host/user
  # kind registers NO receives rows, so `compiledKinds ? parentKind` is false and the pair is skipped — the
  # corpus producer set is EMPTY by construction (the payload/class are forced only PAST the guard). THE
  # MOUNT CHECK: at a
  # singular graft site (`row.arity == "singular"`) the producer runs `checkSingular` over the site's post-
  # `when` live intents — two live edges into one singular mount abort NAMED (naming the mount + every tied
  # id). `classOf kind` = the content-class string (den-side `contentClass` stays null on `meta`); `payloadFor
  # childId` = the inner's content slice; `whenFor childId` = the mount condition (default: always live).
  nestProducer =
    {
      compiledKinds,
      pairs,
      classOf,
      payloadFor,
      whenFor ? (_: true),
    }:
    let
      mkProduction =
        p: row: childClass: parentClass:
        let
          payload = payloadFor p.childId;
          inner = {
            product = "ModulesInfo";
            inherit payload;
            name = p.childName;
            kind = p.childKind;
          };
          # structural handles ONLY (§2.1 corollary — `at` never sees the payload).
          ctx = {
            paramPoint = {
              name = p.childName;
              kind = p.childKind;
              slot = p.childKind;
            };
          };
          innerFace = removeAttrs inner [ "payload" ];
          path = row.at ctx.paramPoint innerFace;
          id = "nest:${p.parentId}/${p.childId}:${p.childKind}";
        in
        {
          inherit
            id
            row
            inner
            ctx
            ;
          # the graft site — a singular row admits ≤ 1 live intent at ONE (parent, slot).
          mount = "${p.parentId}:${p.childKind}";
          intent = {
            inherit id path;
            kind = "nest";
            mode = "nest";
            from = {
              entityId = p.childId;
              class = childClass;
            };
            to = {
              entityId = p.parentId;
              class = parentClass;
            };
            data = payload;
            when = whenFor p.childId;
          };
          # the CONTENT-arm graft (executeNest) — the payload placed at the row's `at`, PER MODULE: the
          # content-facet half of the two-facet invariant documented on the assembleEdges record above
          # (§4.2). placeSlice is lazy, so building the production never forces the payload.
          contribution = executeNest { inherit row inner ctx; };
        };
      # gate + build one production per dispatching pair. The `compiledKinds ? parentKind` pre-guard keeps
      # resolveReceiver total (it throws on an unknown outer kind): a skipped pair takes the `else null`
      # branch without reaching resolveReceiver, and `childClass`/`payloadFor` are lazy lets forced only when
      # a row is built — so a corpus pair (parent kind ∉ receivers) costs nothing.
      gated = builtins.concatMap (
        p:
        let
          childClass = classOf p.childKind;
          parentClass = classOf p.parentKind;
          row =
            if compiledKinds ? ${p.parentKind} then
              resolveReceiver {
                inherit compiledKinds;
                outerKind = p.parentKind;
                slot = p.childKind;
                class = childClass;
              }
            else
              null;
        in
        if row == null then [ ] else [ (mkProduction p row childClass parentClass) ]
      ) pairs;
      # THE MOUNT CHECK: per graft site, `checkSingular` filters the post-`when` live set (singular → ≤ 1 or
      # a NAMED throw; many → every edge rides through). Map the checked intents back to their productions.
      byMount = prelude.groupBy (g: g.mount) gated;
      checkedGroups = prelude.mapAttrsToList (
        mount: group:
        let
          row = (builtins.head group).row;
          liveIds = map (i: i.id) (checkSingular {
            inherit row mount;
            edges = map (g: g.intent) group;
          });
        in
        builtins.filter (g: builtins.elem g.id liveIds) group
      ) byMount;
    in
    builtins.concatLists checkedGroups;
in
{
  inherit
    preRegisteredKinds
    reservedNames
    frameworkStrataInserts
    closureMessage
    closureGate
    compile
    projectsMaterialize
    materializeEdges
    applyOverrides
    assembleEdges
    nestProducer
    ;
}
