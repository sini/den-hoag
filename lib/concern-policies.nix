# Compile `den.policies.<name>` into gen-dispatch rules, partitioned into the two feeds the structural
# stratum consumes: `enrich` (attr 2's keyset-ascent fixpoint, B1) and `policy` (attr 4's one-shot
# stratified rule evaluation, B2), plus the two staged pre-pass feeds and the fleet compose seed.
#
# A policy value is a RECORD. It DECLARES the facts the kernel schedules on rather than having them
# recovered by firing its body against a fabricated context:
#
#   { emits :: [Kind]; selects :: Selector; fn :: ctx -> [Decl]; gate ? functionArgs fn; ops ? [ ];
#     suppresses :: [PolicyName]  (iff emits contains `suppress`)
#     binds      :: [BindingKey]  (iff emits contains `member`) }
#
# EMITS is the declaration CODOMAIN — the closed set of declaration-kind tags the body may produce
# (declarations.nix `groups`). It is REQUIRED, and it is CHECKED at every firing, so it is a CONTRACT
# rather than an annotation: the declaration cannot drift from the body. Five facts the kernel used to
# obtain by execution are set-membership tests on it — the dispatch group (`declare.stratumOfKind` is
# TOTAL on the kind vocabulary), the produced-kind family, resolve-family membership, exclude-family
# membership, and enrich-only-ness.
#
# `emits = [ ]` IS AN EMPTY HEAD, NOT AN ABSENT RULE, and that is a RULING on what an empty declaration
# means rather than a default nobody chose. The three readings and why two are refused:
#   · EVERYTHING — not expressible, and already refused by a law here: the stratum is DERIVED from the
#     codomain, and a codomain over the whole kind vocabulary spans strata, which `policyMessage`
#     rejects. Ruled out by the representation, not by preference.
#   · NOTHING, i.e. compile the policy away — REFUSED, and this is the ruling that matters. It reads an
#     under-specified declaration as a DELETION ORDER, and the deletion is total and silent: the body
#     fires at no node, and the record's `selects`, `gate` and fleet-wide `ops` go with it, because
#     every feed is a filter over the compiled rules. Nothing reddens, and an absent policy leaves
#     nothing to look at — the worst shape a failure can take. It also conflates two states that must
#     stay apart: "I deliberately produce nothing" and "my codomain could not be determined", which is
#     the same conflation an under-specified declaration always invites.
#   · A RULE WHOSE CONSEQUENCE SET IS EMPTY — the ruling. A clause with an empty head is an ordinary
#     clause form, not the absence of one: it is in the program P, T_P maps over it, and it contributes
#     nothing to the model. Dropping it from P yields a DIFFERENT program. So an `emits = [ ]` policy
#     compiles to a rule like any other, fires where its gate admits, and produces nothing — and the
#     codomain contract already here makes the honest reading enforceable: a body that emits ANYTHING
#     violates an empty codomain and aborts NAMED at the emitting site (`conformingProduce` →
#     `errors.emitsUndeclared`), naming the policy and the kind it produced. The check that catches the
#     drift is the one every other policy already runs; nothing new has to be maintained for this case.
# THE DELETION IS THEREFORE UNREPRESENTABLE rather than merely discouraged: `compileOne` is TOTAL onto
# exactly one rule per declared policy, with no arm that yields none, so no value of `emits` can remove
# a policy from the compiled rule set. A policy disappears only by not being written — which is the one
# spelling of "this fleet has no such rule" that a reader cannot mistake for anything else.
#
# SELECTS is the dispatch selection, and it is REQUIRED and TOTAL: one representation — a gen-select
# SELECTOR — with no default, no `null`, and no kind-name list. Absence has two DIFFERENT meanings and a
# field with a default converts one of them into the meaning of silence, at which point silence is
# indistinguishable from a decision. So both absences are promoted to CONSTRUCTED VALUES with distinct
# constructors, and they are the two unit elements of the selector lattice's own operations:
#   · `sel.star`     every node — gen-select's top selector (`matchOne` answers `true` unconditionally);
#   · `sel.any [ ]`  no node    — the empty disjunction (`builtins.any f [ ] = false`);
#   · anything else  the constrained case, e.g. `sel.attrs { type = "host"; }` positionally, or
#                    `sel.kind den.schema.host` where the schema kind VALUE is in scope.
# The empty list is not a selector at all, so the CONSTRUCTOR consuming it is the choice an author makes
# — `sel.any [ ]` selects nothing and `sel.and [ ]` selects everything, because `any` and `all` have
# opposite empty-list identities. An omitted `selects` is refused at registration, because silence must
# not be read as a permission to reach every node. That is the same argument `emits` makes one field up.
#
# THE SELECTION PREDICATE IS gen-select's, NOT den-hoag's. `indexBySelection` decides only WHEN IT IS
# SAFE NOT TO CALL IT (the kind-determined fragment, below); there is no expression in the kernel that
# decides what a selection MEANS.
#
# GATE defaults to the body's `functionArgs` — the presence gate (a rule fires only where every
# destructured ctx key is present; a channel-named arg, never a ctx key, therefore never fires). It is
# NOT derived from `emits`: what a policy produces and where its ctx admits it are different questions.
#
# OPS carries the FLEET-WIDE gen-pipe compose commitments as DATA. A derived-channel DAG or a delivery
# route seeds the ONE fleet compose BEFORE the eval and is ctx-INDEPENDENT by contract, so extracting it
# by firing a body was recovering a constant. Only per-node SITE MARKS are emitted from `fn`
# (`declare.isSiteMarkData` — site marks are per-node emission wiring, v1 register-pipe-effect.nix:15
# `scopedPipeEffects`); the two directions are checked at opposite ends.
#
# STRATUM (B2) is DERIVED, never declared. A rule fires in exactly ONE stratum, and `declare.stratumOfKind`
# is a total function from the kind tag, so declaring a stratum beside `emits` would create a second source
# for a derivable fact. A codomain spanning STRATA is rejected at registration: one rule, one stratum is
# gen-dispatch's core invariant (`dispatch.deriveGroup` aborts on a declared family spanning groups, and
# every rule here is discharged through it), so the surface refuses it at its own boundary rather than
# letting it throw deep inside a dispatch. The remedy is to author one policy per stratum — named, rather
# than synthesized behind a `#<stratum>` suffix.
#
# THE LEVEL CONDITION, stated correctly because den-hoag has negated reads (Apt, Blair & Walker 1988,
# `Towards a Theory of Declarative Knowledge`, Stratified Programs Definition 3, p. 96). A stratification
# assigns levels so that, for a clause whose head is in P_i, a relation occurring POSITIVELY in the body is
# defined within ⋃_{j ≤ i} P_j — the SAME stratum is permitted, which is what makes intra-stratum recursion
# legal — while a relation occurring NEGATIVELY must be defined within ⋃_{j < i} P_j, STRICTLY below. The
# paper's own gloss: "each stratum defines new relations in terms of itself only positively and in terms of
# the relations from the previous strata, possibly negatively." The condition is asymmetric, and reading it
# as "a body may not read at or above its own head" forbids what the paper permits.
{
  prelude,
  dispatch,
  declare,
  errors,
  strataScope,
  graph,
  # gen-select — the selector vocabulary `selects` is valued in and the matcher the index memoises.
  # The kernel reads `select.matches` and nothing else of the selection semantics.
  select,
}:
let
  # The SEEDED strata config (§B2): the compiled stratum order with the stratum→ctx-key-groups map EMPTY
  # above the structural stratum. Rule ctx today is entity BINDINGS — inherited/enriched/linked context
  # (structural.nix attributes 1–3), ALL structural — so no ctx key belongs to a stratum above structural
  # and the projection below is a NO-OP for every shipped rule. The order threads from `den.strata`
  # (declarations.compileStrata) via `compileWithStrata`; a caller that inserts a stratum and tags a ctx
  # key to it gets the capability projection by construction.
  seededStrataCfg = {
    order = declare.strata;
    ctxKeyStrata = { };
  };

  # A policy value's declared parts. `emits`, `selects` and `fn` are REQUIRED (validated by
  # `policyMessage` before any rule is built) and are read as bare selects — an accessor with an `or`
  # default is a default, whatever it is spelled as, and `selects` had one. The rest carry their
  # documented defaults, and each default is the exact semantics the corresponding omission had before
  # it was a field.
  emitsOf = v: v.emits;
  fnOf = v: v.fn;
  gateOf = v: v.gate or (builtins.functionArgs v.fn);
  opsOf = v: v.ops or [ ];
  # The group a policy's declared codomain classifies to. `declare.stratumOfKind` is TOTAL on the closed
  # kind vocabulary, so the stratum is DERIVED and never declared twice (a second source can disagree with
  # the first). Stratum-spanning is refused at registration, so this is a singleton wherever the codomain
  # is non-empty; `groupOf` below is the total function `compileOne` reads.
  groupsOf = emits: prelude.unique (map declare.stratumOfKind emits);

  # THE STRATUM OF AN EMPTY HEAD, decided rather than defaulted. ABW's level condition (Apt, Blair &
  # Walker 1988, Stratified Programs Definition 3, p. 96) constrains a clause's level THROUGH THE
  # RELATIONS IN ITS HEAD: a clause whose head is in P_i bounds where its body may read from. An empty
  # head names no relation and so imposes no lower bound, which makes the BOTTOM stratum the canonical
  # assignment — and it is the conservative one on the reading that matters here, because the A9
  # capability projection admits ctx facts only AT OR BELOW the rule's stratum (Definition 3, condition 1),
  # so a bottom-stratum rule is granted the least. It also fires earliest, so a body that violates its
  # empty codomain aborts at the first
  # dispatch rather than a later one. `declare.strata` is non-empty by construction (compileStrata seeds
  # the framework strata), so this is total.
  groupOf =
    emits:
    let
      groups = groupsOf emits;
    in
    if groups == [ ] then builtins.head declare.strata else builtins.head groups;

  # ── THE SELECTOR VOCABULARY, READ STRUCTURALLY ───────────────────────────────────────────────────
  #
  # gen-select's tag set is CLOSED by `matchOne`'s if-chain, whose final arm throws on an unknown tag,
  # and every predicate the kernel applies to a `selects` value is structural over the selector TREE
  # rather than a test on its outermost tag. A top-tag test is evaded by nesting: `sel.any [ … (sel.has
  # …) ]` carries tag `any` while its `has` child is matched normally and reads `ctx.children`. So the
  # closed-set check, the refusal and the payload check ride ONE recursion — the one that already owns
  # termination — and `knownTags` has exactly one reader.
  knownTags = [
    "star"
    "attrs"
    "entity"
    "kind"
    "and"
    "any"
    "not"
    "has"
    "within"
    "parentMatches"
    "coord"
    "when"
  ];
  # The three tags this dispatch context cannot safely interpret, refused BY NAME at registration:
  #   · `coord` — `matchOne`'s arm requires `data ? __coords`, which the scope adapter's projection does
  #     not carry, so it would abort deep inside gen-select naming a coordinate-blind context;
  #   · `has`   — reads `ctx.children`, an attribute the dispatch sites are upstream of;
  #   · `when`  — its payload is a Nix FUNCTION, so the walk has nowhere to descend and cannot see the
  #     identical `ctx.children` read the `has` refusal exists to stop. Refuse-at-the-tag is the only
  #     structural option, and the direction of approximation is the safe one: over-refusing costs a
  #     message, over-admitting costs an uncatchable abort at an arbitrary consumer.
  refusedTags = {
    coord = true;
    has = true;
    when = true;
  };
  # ONE ROW PER TAG THE WALK ADMITS — i.e. `knownTags \ refusedTags`, exactly. Each row names the tag's
  # payload FIELD and, where its consumers need one, the TYPE test they presuppose. `star` carries no
  # payload and `ok = null` means no type test — both are ROWS rather than omissions, because an absent
  # declaration is a decision here too.
  #
  # A payload field needs a type test iff its consumers include an operation THAT IS NOT ALREADY TOTAL
  # ON EVERY NIX VALUE and whose totality THE WALK'S OWN DESCENT INTO THAT FIELD does not establish.
  # Both clauses are load-bearing: `kind` and `id_hash` are exempt by the first (their only consumer is
  # `==`, total across types), and `selector` by the second (A4/A6 hand it back to this walk, whose root
  # case is total on every Nix value, so the recursion IS the check). `selectors` and `a` are exempt by
  # neither — `head`/`tail`/`all`/`any` presuppose a list before any element is reached, and
  # `builtins.attrNames` is the first operation to touch `a` at all.
  payloadOf = {
    star = null;
    attrs = {
      field = "a";
      ok = builtins.isAttrs;
    };
    kind = {
      field = "kind";
      ok = null;
    };
    entity = {
      field = "id_hash";
      ok = null;
    };
    and = {
      field = "selectors";
      ok = builtins.isList;
    };
    any = {
      field = "selectors";
      ok = builtins.isList;
    };
    not = {
      field = "selector";
      ok = null;
    };
    within = {
      field = "selector";
      ok = null;
    };
    parentMatches = {
      field = "selector";
      ok = null;
    };
  };
  # A tag that is not a string cannot be interpolated — `matchOne`'s own unknown-tag throw fails building
  # its message on one — so the renderer is TOTAL by construction: `builtins.typeOf` answers on every Nix
  # value. A scalar tier (render the value when `toJSON` can) is deliberately NOT taken: it requires
  # enumerating the types `toJSON` is total on, which is a closure claim over Nix's value space that a
  # future value type falsifies silently, and `toJSON` itself aborts on a function and overflows on a
  # self-referential set. The cost is one bit of detail; a non-string tag is illegal whatever its value.
  renderTag = t: if builtins.isString t then t else "<${builtins.typeOf t}>";
  # PRESENCE, THEN TYPE. The second test READS the field, so it cannot precede the first — that ordering
  # is internal to this helper, which is why it is one helper and not two arms that a reshuffle could
  # separate. `found` distinguishes the two faults an author fixes two different ways: `<absent>` says
  # add the field, `<string>` says the field is there and holds the wrong kind of thing.
  payloadFault =
    row: s:
    if !(s ? ${row.field}) then
      {
        inherit (row) field;
        found = "<absent>";
      }
    else if row.ok != null && !(row.ok s.${row.field}) then
      {
        inherit (row) field;
        found = "<${builtins.typeOf s.${row.field}}>";
      }
    else
      null;
  # `refusesAt path s` → `null` (admissible) or the FIRST fault with the PATH to the offending node.
  # A message naming `has` on a rule whose top tag is `any` is the same puzzle for the reader that a
  # top-tag test was for the checker, so every answer carries where it was found.
  #
  # THE ARM ORDER IS DERIVED, not stylistic, and each constraint is named by what its violation does:
  #   A0 before everything — every later arm reads `s.__sel`; on a non-attrset that is an uncatchable
  #      missing-attribute abort, and A0's predicate is total on every Nix value.
  #   A1 before A3 — A3 indexes `payloadOf.${t}`, whose domain is a tag vocabulary, so an unrecognised
  #      tag is itself a missing-attribute abort there.
  #   A2 before A3 — `payloadOf` has rows only for the admissible tags, so A3 on a refused tag aborts;
  #      and on a refused tag with an absent payload, `refused` is the message the author needs.
  #   A3 before A4-A6 — the descent arms read `s.selectors` / `s.selector`, and the type half of A3
  #      before A5's iteration, which reaches `builtins.head` on a non-list.
  # A1 and A2 themselves COMMUTE (`refusedTags ⊆ knownTags`, so their predicates are disjoint); the
  # ordering that matters is that both precede A3.
  refusesAt =
    path: s:
    if !(builtins.isAttrs s && s ? __sel) then
      {
        status = "unknown";
        tag = "<not-a-selector>";
        field = null;
        found = null;
        inherit path;
      }
    else
      let
        t = s.__sel;
      in
      if !(builtins.isString t) || !(builtins.elem t knownTags) then
        {
          status = "unknown";
          tag = renderTag t;
          field = null;
          found = null;
          inherit path;
        }
      else if refusedTags ? ${t} then
        {
          status = "refused";
          tag = t;
          field = null;
          found = null;
          inherit path;
        }
      else
        let
          row = payloadOf.${t};
          fault = if row == null then null else payloadFault row s;
        in
        if fault != null then
          {
            status = "malformed";
            tag = t;
            inherit (fault) field found;
            inherit path;
          }
        # `child`/`descendant` mint no tag of their own — they ARE `and`/`within` compositions — so they
        # need no case and the walk is total on them by construction.
        else if t == "and" || t == "any" then
          firstRefusal path 0 s.selectors
        else if t == "not" || t == "within" || t == "parentMatches" then
          refusesAt "${path}/${t}" s.selector
        else
          null;
  firstRefusal =
    path: i: xs:
    if xs == [ ] then
      null
    else
      let
        r = refusesAt "${path}/${toString i}" (builtins.head xs);
      in
      if r != null then r else firstRefusal path (i + 1) (builtins.tail xs);

  # `kindDetermined : Selector → Bool` — the fragment whose answer is provably a function of node KIND
  # alone, which is exactly what a per-kind memo presupposes. Structural over the same closed tag set,
  # and applied ONLY to registered selectors, so every payload it reads has already been established
  # present and usable by the walk above.
  #   · `star`   constant `true`;
  #   · `attrs`  iff its payload is exactly `{ type = …; }` — the scope adapter's `project` merges `type`
  #              LAST, so it is present on every node and no decl key can shadow it;
  #   · `kind`   reads `data.__identity.kind`, which the adapter copies from `node.type` — true under the
  #              entry-totality precondition, and at an entry-less node the memo is COARSER than per-node
  #              evaluation (the witness supplies `__identity` unconditionally);
  #   · `and`/`any`/`not`  pointwise boolean combinations of functions of `type` are functions of `type`;
  #   · everything else    reads a per-node or positional fact. `when` is classified position-dependent
  #     WITHOUT inspecting its function, which is the FINER direction — it costs evaluations and never
  #     mis-selects; over-classifying as kind-determined is the unsound one and no analysis of an
  #     arbitrary Nix function could justify it.
  kindDetermined =
    s:
    let
      t = s.__sel;
    in
    if t == "star" then
      true
    else if t == "attrs" then
      builtins.attrNames s.a == [ "type" ]
    else if t == "kind" then
      true
    else if t == "and" || t == "any" then
      builtins.all kindDetermined s.selectors
    else if t == "not" then
      kindDetermined s.selector
    else
      false;

  # THE MEMO'S SYNTHETIC WITNESS. The kind-determined fragment's answer factors through `type`, so it is
  # decided against a single-node stand-in and never against a real node — which is what lets the index
  # be built once per fleet, before any node exists. A selector reading more than `type` cannot reach
  # this context (it is classified position-dependent and never consulted here), so supplying no
  # `parent`, `children`, `ancestors` or decls IS the guard rather than an omission.
  witnessId = "__kindWitness";
  kindWitness = k: {
    data = _: {
      type = k;
      __identity = {
        kind = k;
        id_hash = witnessId;
      };
    };
  };

  # THE REFINED CODOMAINS (`declare.codomainRows`): the required-iff rule, over every row. `emits` names
  # the declaration KINDS a body may produce; a row's field names the DEPENDENCY EDGES one of those kinds
  # creates, which the stratification below must know BEFORE it decides anything. The table is the
  # declaration vocabulary's — one statement, read here for registration, at `conformingProduce` for
  # firing, and by the v1 lowering shim for recovery.
  #
  # Reads `emits` only after the chain below has validated it as a list of known kinds, so no row can
  # read a field an earlier guard has not established.
  codomainMessage =
    name: v: emits:
    let
      checkKind =
        k:
        let
          row = declare.codomainRows.${k};
          declared = builtins.elem k emits;
          present = v ? ${row.declaredIn};
        in
        if declared && !present then
          row.missing name
        else if present && !(builtins.isList v.${row.declaredIn}) then
          "den.policies: `${name}`.${row.declaredIn} must be a LIST of ${row.type}, got ${
            builtins.typeOf v.${row.declaredIn}
          }"
        # SPURIOUS IS ABOUT A NON-EMPTY CODOMAIN, and the check's own justification is why. The harm it
        # names is a codomain that "names a dependency the rule cannot create" — an edge asserted by a
        # policy with no head to create it. An EMPTY codomain asserts no edge at all, so the harm does
        # not apply to it, and refusing `[ ]` here would contradict the empty-head ruling `emits` already
        # carries one level up: a declaration that the rule binds nothing is TRUE of a rule that emits no
        # `member`, not a mis-declaration of it.
        else if !declared && present && v.${row.declaredIn} != [ ] then
          row.spurious name
        else
          null;
      offenders = builtins.filter (m: m != null) (
        map checkKind (builtins.attrNames declare.codomainRows)
      );
    in
    if offenders == [ ] then null else builtins.head offenders;

  # policyMessage — the DEFINITION-TIME validator as a VALUE (`null` = clean, else the FIRST named
  # message), so every named contract here is CI-testable: Nix cannot recover a throw's TEXT from a caught
  # evaluation, so a validator that returns its message is the only form a test can assert on.
  # The guard chain is ORDERED — shape first, then vocabulary, then the ops law — so a later guard never
  # reads a field an earlier one has not validated. Rejection is AT REGISTRATION, an explicit boundary,
  # not a throw deep inside a dispatch (the `den.productions` posture, concern-productions.nix:18,82-149).
  policyMessage =
    policies:
    let
      knownKind = k: declare.kindToStratum ? ${k};
      checkOne =
        name: v:
        let
          emits = v.emits or null;
          unknown = builtins.filter (k: !(knownKind k)) (if builtins.isList emits then emits else [ ]);
          ops = v.ops or [ ];
          siteMarkOps = builtins.filter declare.isSiteMarkData ops;
          # ONE walk, THREE messages. Read only after the `fn` guard, and only when the field is present
          # (arm 1 is what makes `v.selects` safe for the three arms below it).
          refusal = if builtins.isAttrs v && v ? selects then refusesAt "" v.selects else null;
          at = r: if r.path == "" then "the selector" else "the selector at `${r.path}`";
        in
        if !(builtins.isAttrs v) then
          "den.policies: `${name}` is not a record - a policy value is `{ emits; selects; fn; gate ? <formals>; ops ? [ ]; }`. A bare `ctx: [ declarations ]` closure cannot carry the emitted-kind family the kernel schedules on, and recovering it by firing the body against a fabricated context is what this surface replaces"
        else if !(v ? emits) then
          "den.policies: `${name}` declares no `emits` - the declaration codomain is REQUIRED. `emits = [ ]` (an EMPTY HEAD: the rule compiles, fires, and producing anything violates its codomain) is a legal value; an omitted `emits` is not, because silence must not be read as a permission to discover it by execution"
        else if !(builtins.isList emits) then
          "den.policies: `${name}`.emits must be a LIST of declaration-kind tags, got ${builtins.typeOf emits}"
        else if !(v ? fn) || !(builtins.isFunction v.fn) then
          "den.policies: `${name}` declares no function-valued `fn` - the body is `ctx: [ declarations ]`"
        else if !(v ? selects) then
          "den.policies: `${name}` declares no `selects` - the dispatch selection is REQUIRED. The three selections are `sel.star` (every node), `sel.any [ ]` (no node) and any other selector (the constrained case, e.g. `sel.attrs { type = \"host\"; }`); an omitted field is not a legal spelling of any of them, because silence must not be read as a permission to reach every node"
        else if refusal != null && refusal.status == "unknown" then
          "den.policies: `${name}`.selects — ${at refusal} carries the unknown tag `${refusal.tag}`, which is not one of gen-select's selector tags. `selects` is a SELECTOR, not `null` and not a list of kind names: write `sel.star` for every node, `sel.any [ ]` for no node, or `sel.attrs { type = <kind name>; }` / `sel.kind <kind value>` to constrain by kind"
        else if refusal != null && refusal.status == "refused" then
          "den.policies: `${name}`.selects — ${at refusal} carries tag `${refusal.tag}`, which the dispatch context cannot interpret. `coord` needs a `__coords` projection the scope context does not carry; `has` and `when` can read `ctx.children`, an attribute the dispatch sites are upstream of. den-hoag's own `hasClass` / `hasSetting` sugars are `when` selectors, so they are inadmissible in `selects` (they remain admissible on `members`, `of` and `sel`, which are read at a different stratum)"
        else if refusal != null && refusal.status == "malformed" then
          "den.policies: `${name}`.selects — ${at refusal} carries tag `${refusal.tag}` whose payload field `${refusal.field}` is `${refusal.found}`. A recognised tag with an unusable payload aborts inside gen-select's own descent, where the message names neither the field nor the policy that wrote it; registration is the only total position at which the field can be established usable"
        else if unknown != [ ] then
          "den.policies: `${name}` emits unknown declaration kind `${builtins.head unknown}` - the vocabulary is the registered declaration kinds (declarations.nix `groups`)"
        else if builtins.length (groupsOf emits) > 1 then
          "den.policies: `${name}` emits kinds spanning strata ${builtins.concatStringsSep ", " (groupsOf emits)} - a rule's declarations classify to ONE stratum. This is gen-dispatch's core invariant, not only den-hoag's: `dispatch.deriveGroup` (gen-dispatch `mkActions`, the declared-stratum vocabulary) aborts on a declared kind family spanning groups, and `compileOne` discharges every rule through it. Split it into one policy per stratum; the split is authored and named rather than synthesized"
        else if siteMarkOps != [ ] then
          "den.policies: `${name}`.ops carries a SITE-MARK-only pipeOp - site marks are per-node emission data fired WHERE the policy fires, so they belong in the body's emission, not in the fleet-wide compose seed. `ops` carries only ctx-independent commitments (a derived-channel DAG or a delivery route)"
        else
          codomainMessage name v emits;
      offenders = builtins.filter (m: m != null) (prelude.mapAttrsToList checkOne policies);
    in
    if offenders == [ ] then null else builtins.head offenders;

  # ── THE SIGNED POLICY DEPENDENCY GRAPH ───────────────────────────────────────────────────────────
  #
  # Over POLICY NAMES, and SIGNED, which is Lemma 1's own shape rather than a specialisation of it. Edge
  # direction is the paper's: `p -> q` means p's definition REFERS TO q.
  #
  #   NEGATIVE  q -> p   for each p, each q in suppresses(p)
  #             (q's firing consults, negatedly, the set p contributed — the gate reads `suppressedPolicies`)
  #   POSITIVE  p -> q   when formals(p) INTERSECT binds(q) is non-empty
  #             (p's body destructures a binding key q emitted)
  #
  # BOTH FAMILIES ARE REQUIRED. Checking only the negative subgraph would be sound solely if no
  # suppressor could read a binding; a suppressor CAN, and then the cycle `q --neg--> p --pos--> q` is a
  # cycle containing a negative edge one of whose two edges is positive, and so invisible to a check over
  # the negative subgraph alone.
  #
  # ★ THE DOMAIN IS `policies`, THE DECLARATION ATTRSET, not a compiled feed. `suppresses` and `binds`
  # are DECLARATION fields validated over exactly this attrset, and a stratification decided from
  # declarations must range over every declaration. Compiling first and filtering to the suppress
  # emitters would truncate the node set to the suppressors, at which point no `binds` declaration is in
  # the graph at all, every positive edge is vacuous, and a negative edge to a pure member-emitter cannot
  # even be enumerated — a correct expression over a domain narrower than its own quantifier.
  #
  # ⚠ THE DIRECTION OF APPROXIMATION, stated because it is not exact. `posOf` is a GLOBAL NAME test: any
  # policy destructuring a formal that ANY policy declares in `binds` gets a positive edge, with no
  # reachability scoping. Common keys (`host`, `name`, `token`) therefore link policies that can never
  # meet, merging clusters and pushing a legitimate BETWEEN-cluster negative edge INSIDE one. So the
  # approximation is FINER — it over-rejects, never over-admits, which is the safe direction for a
  # soundness guard. Scoping the edge needs a per-(policy, node) reachability relation that does not
  # exist at registration, and inventing one here would be a new position rather than a check. The
  # repairing discipline is the abort's: it prints the whole cluster, so a false rejection is legible and
  # is repaired by renaming a binding key or splitting a codomain, never by relaxing the check.
  signedGraph =
    { policies, formalsOf }:
    let
      names = builtins.attrNames policies;
      suppressesOf = p: policies.${p}.suppresses or [ ];
      bindsOf = q: policies.${q}.binds or [ ];
      negOf = q: builtins.filter (p: builtins.elem q (suppressesOf p)) names;
      # The positive family is empty unless SOMETHING declares a binding key, so the producers are
      # enumerated first and the reader side is consulted only if that set is non-empty. This is the same
      # set either way — a `q` with `binds = [ ]` can satisfy no membership test — but it keeps a fleet
      # with no binding producers from having to know any policy's formals at all, which matters because
      # `formalsOf` reads a gate and a gate is the one part of a compiled rule that a generated policy may
      # not be able to produce.
      posOf =
        p:
        let
          producers = builtins.filter (q: q != p && bindsOf q != [ ]) names;
        in
        if producers == [ ] then
          [ ]
        else
          let
            fs = formalsOf p;
          in
          builtins.filter (q: builtins.any (f: builtins.elem f (bindsOf q)) fs) producers;
    in
    {
      nodes = names;
      negEdges = q: negOf q;
      edges = n: (negOf n) ++ (posOf n);
    };

  # THE CHECK, at REGISTRATION, and the RANK it returns. Lemma 1 (p. 97) AS STATED: reject iff some
  # NEGATIVE edge has both endpoints in one cluster. A negative edge inside a cluster is precisely a cycle
  # through a negative edge; a negative edge BETWEEN clusters is the ordinary stratified case, and a
  # purely POSITIVE cycle is ADMITTED — Definition 3's condition 1 (p. 96) permits same-stratum positive
  # reads, so rejecting one would be over-strict rather than safe.
  #
  # `graph.condensation` IS the paper's cluster construction: `sccOf` is Definition 12's cluster map
  # (p. 112) and `bottomUp` is a reverse-topological order over the quotient, which by Lemma 11(2)
  # (p. 113 — every stratum of every stratification is a union of clusters) is the FINEST stratification,
  # the one every other factors through. So stratifiability is DECIDED in graph time rather than searched
  # for, and the cluster order IS the stratification. A longest-path rank would not do: it has no fixed
  # point on a cycle, and positive cycles are legal here.
  #
  # The returned rank is a position in that order. A policy at rank k fires against the suppression set
  # contributed by ranks strictly below k — literally M_i = T_{P_i}↑ω(M_{i-1}) (p. 108), with the
  # clusters as the strata, rather than the ONE application of T_P a single un-ordered pass computes.
  stratifyOrThrow =
    { policies, formalsOf }:
    let
      g = signedGraph { inherit policies formalsOf; };
      cond = graph.condensation { inherit (g) edges nodes; };
      bad = builtins.concatMap (
        q: builtins.filter (p: cond.sccOf p == cond.sccOf q) (g.negEdges q)
      ) g.nodes;
    in
    if bad != [ ] then
      errors.negativeCycle (builtins.head bad) (cond.members (cond.sccOf (builtins.head bad)))
    else
      builtins.listToAttrs (
        prelude.concatMap (
          i:
          map (m: {
            name = m;
            value = i;
          }) (cond.members (builtins.elemAt cond.bottomUp i))
        ) (builtins.genList (i: i) (builtins.length cond.bottomUp))
      );

  # THE SELECTION, once per feed. Dispatch order determines emission order and therefore merge order, so
  # a bucket-concatenation index (`byKind ++ anyKind`) would perturb output; ONE filter over the feed's
  # OWN list preserves it exactly. That is why the memo is a PARALLEL BOOLEAN VECTOR at the feed's own
  # positions rather than a sub-list: partitioning into kind-determined and position-dependent halves and
  # concatenating them produces a mis-ordered intermediate that a later sort would have to repair, and a
  # repair that works is how an order defect closes falsely. A rule selecting `sel.any [ ]` lands in NO
  # bucket — it is not filtered out at a node, it is ABSENT FROM EVERY NODE'S RULE LIST; a rule selecting
  # `sel.star` is in every bucket. The two absences are opposite extremes of one table, which is the
  # clearest reason they cannot share a spelling. `kinds` is opaque data supplied by the caller — the
  # kernel learns no kind NAMES.
  #
  # `.at` is a FUNCTION, not an attrset, and that is deliberate: a table lookup with an `or [ ]` fallback
  # would answer "no rules" for a kind absent from `kinds`, silently dropping every unconstrained rule at
  # that node — the failure mode this whole design exists to remove, reintroduced at the read. Both
  # tables here recompute on a miss instead, so the selection is TOTAL over node kinds by construction and
  # `kinds` is a memoisation hint rather than a correctness precondition. The record this returns is a
  # CONSTRUCTION carrying that one function plus one observable; `positionDependent` is read at the
  # BINDING site and never threaded, so nothing a call site holds is an attrset where a function belongs.
  #
  # ★ THE INDEX IS A MEMO OF THE MATCHER, NOT A SECOND SELECTION PREDICATE. The semantics is
  # `select.matches`; this decides only when it is safe not to call it.
  indexBySelection =
    kinds: feed:
    let
      # `kindDetermined` is a pure function of the RULE, so it is decided once per rule, never per node.
      tagged = prelude.imap0 (i: r: {
        inherit i r;
        kd = kindDetermined r.selects;
      }) feed;

      # THE MEMO, over the fragment for which kind IS the key: a boolean at each of the feed's OWN
      # positions. `false` at a position holding a position-dependent rule — that position is answered
      # per node below and never read from here. It needs no resolve result at all: the fragment's
      # answer factors through `type`, so it is decided against the synthetic single-node witness.
      admitsAt' = k: map (e: e.kd && select.matches e.r.selects witnessId (kindWitness k)) tagged;
      table = prelude.genAttrs kinds admitsAt';
      admitsAt = k: table.${k} or (admitsAt' k); # TOTAL: a kind outside `kinds` recomputes

      positionDependent = map (e: e.r) (builtins.filter (e: !e.kd) tagged);

      # ★ THE SHORT-CIRCUIT. When NO rule is position-dependent the whole feed's answer is a function of
      # kind alone, so the per-node filter is not merely memoisable, it is UNNECESSARY: precompute the
      # selected list per kind and hand it back whole. One table lookup per node — today's cost, restored
      # BY CONSTRUCTION rather than recovered later as an optimisation. `pick` filters the same `tagged`
      # list by the same positional vector, so the precomputed list is the feed's own order with entries
      # removed and the order property above is inherited rather than re-argued.
      pick = adm: map (e: e.r) (builtins.filter (e: builtins.elemAt adm e.i) tagged);
      selectedTable = prelude.genAttrs kinds (k: pick (admitsAt k));
      selectedAt = k: selectedTable.${k} or (pick (admitsAt k)); # TOTAL, same discipline
    in
    {
      # `matchAt` is supplied BY THE DISPATCH SITE, which is where the resolve eval is in scope. Both
      # arms have the SAME ARITY so every call site is one expression either way. It takes the RULE, not
      # the rule's selector: a selector value cannot name the policy that wrote it, and the matcher the
      # current landing supplies is a throw whose whole job is to name it.
      at =
        if positionDependent == [ ] then
          # Nothing reads `matchAt` or `id`: the selection is a table lookup on kind.
          _matchAt: _id: kind:
          selectedAt kind
        else
          # ONE order-preserving pass over the ORIGINAL feed. No partition, no concatenation.
          matchAt: id: kind:
          let
            admits = admitsAt kind;
          in
          map (e: e.r) (
            builtins.filter (e: if e.kd then builtins.elemAt admits e.i else matchAt e.r id) tagged
          );
      # Exposed: its LENGTH is the scaling observable — a fleet-independent number a gate can assert on,
      # and the exact quantity whose growth converts the per-node cost from negligible to dominant.
      inherit positionDependent;
    };

  # `compileWithStrata { order; ctxKeyStrata } policies` — the strata-aware compiler. `compileWith` is
  # this with the seeded config (an empty ctx-key map ⇒ identity projection).
  compileWith = compileWithStrata seededStrataCfg;
  compileWithStrata =
    strataCfg: policies:
    let
      # Capability-scoped ctx (A9 stratification-by-construction, spec §5): a rule declared at stratum
      # `ruleStratum` may read ctx facts AT OR BELOW its own stratum — Apt, Blair & Walker (1988),
      # "Stratified Programs", Definition 3, p. 96, condition 1. A ctx key whose declared stratum is
      # ABOVE the rule's is REPLACED with a NAMED THROW (not omitted — a replaced key aborts
      # CATCHABLY when read, diagnosing better than an attribute-missing read). The seeded map is empty
      # above structural, so this is an identity map for every shipped rule.
      #
      # Condition 1 is not a choice here, it is the only law this guard can carry. `mapAttrs` preserves
      # the ctx KEY SET exactly and replaces only VALUES, so the one negation-shaped read an attribute set
      # offers — `ctx ? key` — is INVARIANT under the projection. A guard that cannot observe a negation is
      # not guarding negation, whatever operator it spells; its only observable is a forced value, which is
      # a positive read.
      stratumIndex = prelude.foldl' (acc: i: acc // { ${builtins.elemAt strataCfg.order i} = i; }) { } (
        builtins.genList (i: i) (builtins.length strataCfg.order)
      );
      # key → its declared stratum (inverting the stratum→keys map); un-tagged keys are structural-safe.
      # A stratum name in the map that is absent from the compiled order aborts NAMED (forced at the first
      # projection, since the fold is lazy) — an untagged silent pass would defeat the projection.
      ctxKeyStratum = prelude.foldl' (
        acc: stratum:
        if !(stratumIndex ? ${stratum}) then
          throw "den.strata: ctxKeyStrata names unknown stratum '${stratum}' (not in the compiled order)"
        else
          prelude.foldl' (acc': key: acc' // { ${key} = stratum; }) acc (strataCfg.ctxKeyStrata.${stratum})
      ) { } (builtins.attrNames (strataCfg.ctxKeyStrata or { }));
      # TOTAL in the rule's own stratum: a bare `stratumIndex.${ruleStratum}` select is an attribute miss
      # on an order that omits the stratum, which `tryEval` CANNOT catch — it aborts the evaluation outright
      # rather than yielding a value. The `or (throw …)` makes it a NAMED, catchable failure.
      # `ctxKeyStratum` is already total by its own construction (the fold above throws NAMED on a stratum
      # absent from the order), so `stratumIndex.${ks}` needs no fallback.
      projectCtx =
        ruleStratum: ctx:
        let
          r =
            stratumIndex.${ruleStratum}
              or (throw "den.strata: rule stratum '${ruleStratum}' is not in the compiled strata order");
        in
        builtins.mapAttrs (
          key: v:
          let
            ks = ctxKeyStratum.${key} or null;
          in
          if ks != null && !(strataScope.admitPositive stratumIndex.${ks} r) then
            throw "den.strata: ctx fact '${key}' is stratum '${ks}', ABOVE rule stratum '${ruleStratum}' — a rule reads ctx facts at or below its own stratum (Apt-Blair-Walker 1988, Definition 3, condition 1)"
          else
            v
        ) ctx;
      # The FINAL (dispatch) produce reads its ctx through `projectCtx stratum`, so an ABOVE-stratum ctx
      # fact throws named when the body reads it.
      projectedBase =
        stratum: baseProduce: id: ctx:
        baseProduce id (projectCtx stratum ctx);

      # THE CONFORMANCE LAW: every declaration the body returns has its kind in the declared codomain, or
      # the run aborts NAMED at the emitting site. This is what makes `emits` a contract — a mis-declared
      # codomain is caught LOUD rather than mis-routing the rule silently. It SUBSUMES
      # `declare.checkStratum` (a conforming emission cannot span strata, because `emits` does not) and the
      # retired resolve-/exclude-family untagged guards (a `member`/`suppress` emitter has DECLARED it, so
      # it is in the feed by derivation and "emitted but untagged" is unrepresentable). The `pipeOp` arm is
      # the body end of the compose-commitment boundary whose other end is `policyMessage`'s ops law. One
      # attrset membership test per emitted declaration, on a list already being materialised.
      #
      # THE SAME LAW ONE LEVEL FINER, for the two kinds that create dependency EDGES. The registration
      # check decides the stratification from the DECLARED graph; without a firing-time check a body
      # could name a policy or bind a key outside its declaration, and the graph the check read would
      # stop being the graph the program has — which makes the registration messages false rather than
      # merely incomplete. Both checks ride THIS map, in the arm that already computed the kind, and both
      # read their row from `declare.codomainRows`, so the kind→field pairing has one statement rather than two.
      # VACUOUS FOR A RULE THAT NEVER FIRES, and that is sound: a rule that does not fire creates no edge
      # either, so the declared graph stays the graph the program has.
      conformingProduce =
        name: record: emits: baseProduce: id: ctx:
        let
          admitted = prelude.genAttrs emits (_: true);
          # THE NAME AN AUTHOR CAN ACT ON, when the registration key is not it. A record minted by a
          # LOWERING is registered under a synthesized key and states, in `originName`, the name it was
          # authored under; a natively-authored policy carries no such field and its key IS that name.
          # The kernel neither parses the key nor learns what synthesized it — it reads one optional
          # field and hands both names to the message builder, which decides the rendering. Read on the
          # abort path ONLY, so a conforming firing forces neither the field nor the record.
          originName = record.originName or null;
        in
        map (
          a:
          let
            k = declare.kindOf a;
            stamped = a // {
              __policy = name;
            };
          in
          if !(admitted ? ${k}) then
            errors.emitsUndeclared originName name k emits
          else if k == "pipeOp" && !(declare.isSiteMarkData a) then
            errors.opsInBody originName name
          else if declare.codomainRows ? ${k} then
            let
              row = declare.codomainRows.${k};
              declared = record.${row.declaredIn} or [ ];
              undeclared = builtins.filter (x: !(builtins.elem x declared)) (row.keysOf a);
            in
            if undeclared != [ ] then row.fail originName name (builtins.head undeclared) declared else stamped
          else
            stamped
        ) (baseProduce id ctx);

      # ONE policy compiles to ONE rule — TOTALLY, with no arm that compiles to none. `group` is stamped
      # from the DECLARED codomain at definition time and `produces` IS that codomain, so gen-dispatch
      # honours it and skips its per-dispatch fire-and-classify validation. There is no probe, no
      # sentinel, no fabricated context and no per-stratum fan. The capability projection over ctx (A9)
      # is unchanged; it now reads a declared group instead of an observed one.
      #
      # THE MAP IS TOTAL, which IS the remedy for the silent-deletion defect rather than a check against
      # it. A `[ ]` arm here would be a policy-shaped hole in the compiled rule set that nothing can
      # observe — no acts, no error, no trace — so there is no such arm: an empty codomain is an empty
      # HEAD (a rule that fires and produces nothing, its emptiness enforced by `conformingProduce`), not
      # an absent rule. `groupOf` is total over codomains, so the group exists for every policy.
      compileOne =
        name: v:
        let
          emits = emitsOf v;
          base = dispatch.fromFunction (fnOf v);
          group = groupOf emits;
        in
        [
          (dispatch.deriveGroup declare.stratumOfKind {
            inherit (base) nac priority overrides;
            inherit group;
            condition = gateOf v;
            produces = emits;
            inherit (v) selects;
            ops = opsOf v;
            identity = name;
            produce = conformingProduce name v emits (projectedBase group base.produce);
          })
        ];

      # Registration rejection is forced BEFORE any rule exists, so a malformed surface is refused at its
      # own boundary rather than at whichever consumer first forces a rule.
      registration = policyMessage policies;
      # THE STRATIFICATION, decided once per fleet from the declarations alone. Ordered AFTER
      # `registration` and forced with it: it reads the two codomain fields that check is what validates,
      # so deciding a graph from declarations nothing has established would be a checker reading a domain
      # nothing guarantees. `formalsOf` reads the reader side of a positive edge off the surface that
      # already defines it — `gateOf` is the same expression the dispatch presence-gate uses — rather
      # than re-deriving it.
      policyRank = stratifyOrThrow {
        inherit policies;
        formalsOf = n: builtins.attrNames (gateOf policies.${n});
      };
      rules =
        if registration != null then
          errors.policyRegistration registration
        else
          builtins.seq policyRank (
            prelude.concatMap (name: compileOne name policies.${name}) (builtins.attrNames policies)
          );

      # Every feed is a set-membership test on the DECLARED codomain. The name-keyed knobs that supplied
      # these by hand (`den.resolveFamilyNames`, `den.excludeFamilyNames`, `den.producesByName`) have no
      # remaining job, and neither does a strip list: there are no `__`-carriers to remove, because the
      # facts they carried are fields.
      emitsAny = r: ks: builtins.any (k: builtins.elem k ks) r.produces;
    in
    {
      enrich = builtins.filter (r: r.produces == [ "enrich" ]) rules;
      policy = builtins.filter (r: r.produces != [ "enrich" ]) rules;
      # The STAGED ROOT-RESOLUTION pre-pass feed (design note 2026-07-11 §3(ii)): the structural-group
      # rules that can emit resolve-family {member}. The pre-pass dispatches ONLY these at roots, so an
      # arbitrary co-firing policy body is never run there. Empty for a fleet with no resolve policies.
      resolveFamily = builtins.filter (
        r: r.group == "structural" && emitsAny r declare.resolveFamilyKinds
      ) rules;
      # The EXCLUDE-FAMILY feed (#72): the structural-group rules that can emit `suppress`. The staged
      # pre-pass dispatches ONLY these for suppression collection; empty for an exclude-free fleet.
      excludeFamily = builtins.filter (r: r.group == "structural" && emitsAny r [ "suppress" ]) rules;
      # THE RANK, name-keyed and spanning EVERY declared policy — not only the exclude feed. The
      # stratification is a property of the whole declaration graph; the exclude feed is the projection
      # of it that fires, joined back by the compiled rule's `identity`. Handing out the ranked set
      # rather than a pre-filtered one is what keeps the firing a projection of the check's domain
      # instead of its definition.
      inherit policyRank;
      # The fleet-wide compose commitments, DECLARED. No firing, no probe: a ctx-independent commitment
      # read from a body by firing it was recovering a constant the record can simply carry.
      pipeOps = prelude.concatMap (r: r.ops) rules;
    };
in
{
  compile = compileWith;
  inherit
    compileWith
    compileWithStrata
    indexBySelection
    policyMessage
    ;
}
