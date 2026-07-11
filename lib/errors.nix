# Named definition-time errors — pure message builders. Tasks 1–11 extend this set.
# nixpkgs-lib-free: plain `throw`, no prelude needed (add it back only if a future
# builder genuinely uses a prelude helper).
let
  fail = ctx: msg: throw "den-hoag: ${ctx}: ${msg}";
  # Display name of an entry / class / aspect (id_hash-bearing or name-bearing); strings are only
  # authoritative in a rendered message. Mirrors gen-pipe's renderEntry without a lib edge.
  render =
    e:
    if e == null then
      "<none>"
    else if builtins.isAttrs e then
      (e.name or e.id_hash or (builtins.toJSON e))
    else
      toString e;
  renderScope =
    coords:
    if coords == null || coords == { } then
      "<no-scope>"
    else
      builtins.concatStringsSep ", " (map (k: "${k}=${render coords.${k}}") (builtins.attrNames coords));
in
{
  identityLaw =
    api: got:
    fail "identity law (A2)" "${api} takes a registry entry (carrying id_hash), got ${builtins.typeOf got}${
      if builtins.isString got then " \"${got}\" — pass the entry, not a \"kind:name\" string" else ""
    }";

  # A5 emission discipline: `member` is accepted only at membership-independent scope
  # nodes. A `member` declaration dispatched at a membership-derived node (a fleet cell, or
  # any node beneath one) aborts, naming the policy and the scope. The membership-
  # derived classification is the caller's (Task 3 declaration-stratum classifier); this
  # builder is the abort it raises.
  memberAtCell =
    policyName: scopeId:
    fail "member discipline (A5)" "policy `${policyName}` emitted `member` at membership-derived scope `${scopeId}`; member is accepted only at membership-independent nodes";

  # B1 single-writer enrichment (A3): two enrich policies writing one context key abort at
  # definition time, naming both policies + the key. Fires on a same-pass collision AND a
  # cross-iteration one (the check runs over the converged enrich accumulation).
  singleWriter =
    key: ownerA: ownerB:
    fail "single-writer enrichment (B1)" "enrich key `${key}` is written by two policies (`${ownerA}` and `${ownerB}`); a key may be enriched by exactly one policy";

  # B2 stratum coherence: a policy whose declarations do not all classify to one STRATUM
  # aborts. Each declaration's stratum is derived from its KIND via the vocabulary's
  # kind->stratum map (Task 2: enrich -> structural is the whole map; Task 3 extends it), so
  # the abort names both offending kinds AND their strata. Wired at the declaration classifier
  # (Task 3); Task 2 provides the builder.
  mixedStratum =
    policyName: kindA: stratumA: kindB: stratumB:
    fail "declaration stratum (B2)" "policy `${policyName}` produced declarations of kind `${kindA}` (stratum `${stratumA}`) and kind `${kindB}` (stratum `${stratumB}`); a policy's declarations must all classify to a single stratum";

  # B2 per-declaration-stratum conservation. A policy whose value-less probe emitted nothing (its
  # emission is gated on a context VALUE, not just coordinate presence) has its stratum derived
  # PER DECLARATION at dispatch — expanded into one sub-rule per COVERED stratum {structural,
  # resolution, collection}. Enrich-feed selection (B1 keyset-ascent, attr 2) and fleet pipeOp
  # compose-seeding (the ONE gen-pipe DAG's DERIVED-op chains + delivery routes, seeded before eval)
  # are PROBE-TIME commitments a value-less policy cannot make: a dispatch-time enrich- or DERIVED/route
  # pipeOp-kind declaration from it would silently never reach its feed. So both abort LOUD — never a
  # silent partition. A pure SITE-MARK pipeOp (bare channel ref, no deriving/routes) is per-node
  # emission DATA, NOT a compose op, so it is ALLOWED through the collection sub-rule (see isSiteMarkData).
  expansionEnrich =
    policyName:
    fail "per-declaration stratum (B1/B2)" "policy `${policyName}` (value-less probe → per-declaration stratum) produced an `enrich` declaration at dispatch; enrich-feed selection is a probe-time commitment (attr 2 keyset-ascent), so a value-conditional policy cannot contribute enrichment — author it as an explicit enrich policy whose probe emits its enrich keys";
  expansionPipeOp =
    policyName:
    fail "per-declaration stratum (collection)" "policy `${policyName}` (value-less probe → per-declaration stratum) produced a `pipeOp` declaration carrying a DERIVED operator (a channel-shaping DAG) or a delivery route at dispatch; those seed the ONE fleet gen-pipe compose DAG BEFORE the eval from ctx-INDEPENDENT bodies, so a value-conditional policy — which emits nothing at the seeding probe — cannot contribute one. (A pure SITE-MARK pipeOp on a bare channel ref is per-node emission data, fired where the policy fires, and IS allowed through expansion.)";
  expansionUncovered =
    policyName: kind: stratum:
    fail "per-declaration stratum (B2)" "policy `${policyName}` (value-less probe → per-declaration stratum) produced kind `${kind}` (stratum `${stratum}`), outside the covered {structural, resolution, collection (site-mark pipeOps)}; a `${stratum}`-stratum declaration from a value-conditional policy is a silent partition";

  # §2.2 aspect-key dispatch: an aspect key that is neither a declared facet, a registered
  # class, nor a registered quirk channel is a definition-time error, naming the aspect + key.
  unknownAspectKey =
    aspectName: key:
    fail "aspect key (§2.2)" "aspect `${aspectName}` declares key `${key}`, which is neither a facet, a registered class, nor a quirk channel";

  # A13 class-tag ambiguity: a null-class scope emitting class-shaped (config-demanding) content —
  # the producing scope binds no class to resolve the contribution's `config` against, so the class
  # tag is undecidable. den detects this at the emission it owns (a null producing class + a deferred
  # value) and frames gen-pipe's E1 with den names — the producing aspect, the quirk channel, and the
  # scope. `config`-independent (class-neutral) emissions at the same scope are legal (T3), so the
  # abort is precise to the class-shaped case.
  classAmbiguity =
    {
      aspect,
      channel,
      scope,
    }:
    fail "class tag (A13)" "aspect `${render aspect}` emits class-shaped (config-demanding) content to quirk channel `${channel}` at null-class scope `${renderScope scope}`; a class-shaped contribution needs a producing class — tag it explicitly or make the emission config-independent";

  # A7 linearization declaration surface: a `den.linearization.dims` list that is not a total,
  # entry-only cover of the product dimensions. `tag` names the failure; `detail` is the offending
  # dim name (missing/duplicate) or the rendered non-entry (identity law A2). Definition-time.
  linearizationDim =
    tag: detail:
    fail "linearization (A7)" (
      if tag == "non-entry" then
        "den.linearization.dims takes KIND entries (each carrying a `kind` field), got a non-entry `${detail}` — pass `den.schema.<kind>`, not a dim-name string"
      else if tag == "missing" then
        "den.linearization.dims omits product dimension `${detail}`; every registered dimension must appear exactly once"
      else if tag == "duplicate" then
        "den.linearization.dims names dimension `${detail}` more than once; each dimension appears exactly once"
      else
        "malformed dims (${tag}): ${detail}"
    );

  # A10 narrow accessor: reading `.settings` of an aspect whose `present = false` at this scope.
  # Names the aspect and the scope node; the caller must check `.present` first (§2.8).
  absentAspectSetting =
    aspectName: scopeId:
    fail "narrow accessor (A10)" "aspect `${aspectName}` is not present at scope `${scopeId}` — its `.settings` is unavailable; check `.present` before reading `.settings`";

  # A14 constraint 3 (projects facet): two DISTINCT projecting aspects inject a settings layer for the
  # SAME target aspect at the SAME attachment scope — the order between projectors is undecided, so den
  # aborts at definition time, naming both projectors, the target address, and the scope.
  projectionCollision =
    {
      projectors,
      address,
      scope,
    }:
    fail "projection collision (A14)" "aspects ${
      builtins.concatStringsSep " and " (map (p: "`${p}`") projectors)
    } both project settings onto aspect `${address}` at scope `${renderScope scope}`; a target address may be projected by at most one aspect per scope";

  # A14 constraint 2 (projects facet): a projection selector must be STATIC — it may match an aspect's
  # own declared name/tags/setting fields, never resolved graph position or values. A scope-navigating
  # or identity/coordinate selector (within/has/parentMatches/entity/kind/coord) is dynamic and aborts,
  # naming the projecting aspect + the offending selector tag.
  projectionDynamicSelector =
    projectorName: tag:
    fail "projection selector (A14)" "aspect `${projectorName}` projects with a dynamic selector (`${tag}`); projection selectors are static — they match declared name/tags/setting fields only, never resolved graph position or values";

  # A18 class-share gate: an injected class-invariant core is NOT byte-identical to a member's real
  # projection at the shared keys — the share is UNSOUND and aborts LOUD (never silently reused). Names
  # the member and the two digests. The byte gate is the ONLY authority a share is sound (gen-class
  # gate.nix: "keys narrow, the gate decides"); this is den-hoag's hard-fail on `gate == false`.
  classShareGate =
    {
      member,
      candidateDigest,
      realDigest,
    }:
    fail "class-share gate (A18)" "the class-invariant core for member `${member}` is not byte-identical to its real projection (candidate ${candidateDigest} != real ${realDigest}); a class-share is authorised ONLY by the byte gate — a divergent core is never silently reused";

  # A13 cross-class consumption: a consumer at class C reads a contribution tagged class C′ ≠ C with
  # no declared C′→C adapter on the quirk. den owns the discipline (a declared adapter is the ONLY
  # authorised coercion — §2.5, never implicit); this frames the abort naming the channel, the
  # producer, and both classes before gen-pipe would otherwise coerce or reject.
  crossClassNoAdapter =
    {
      channel,
      producer,
      tag,
      consuming,
    }:
    fail "cross-class read (A13)" "quirk channel `${channel}` consumed at class `${render consuming}` but a contribution from aspect `${
      render (producer.aspect or null)
    }` (entity `${
      render (producer.entity or null)
    }`) is tagged class `${render tag}`; declare a `${render tag}` -> `${render consuming}` adapter on the quirk or consume at the producing class";
}
