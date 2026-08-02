# den-compat named definition-time errors — pure message builders, nixpkgs-lib-free (grows every
# task). Every compile-time failure the shim raises names its concern (C-law) and the surface at
# fault, so a v1 declaration that cannot compile fails at DEFINITION with a legible message rather
# than deep in a later evaluation. No `lib`, only `throw` + string interpolation (Law: nixpkgs-lib-free).
# `prelude` reserved — the compile/error surface is still growing.
{ prelude }:
let
  fail = ctx: msg: throw "den-compat: ${ctx}: ${msg}";

  # The populated commitment fields of a `pipeCommit`, rendered as one clause. A commitment is one of
  # three shapes and the author's next move differs by shape, so the message names WHICH — never merely
  # "a commitment". An EMPTY render is unreachable (`bearsCommitment` is what routed the record here) and
  # is NOT allowed to degrade to silence: it renders all three as candidates, the same rule the fire-site
  # attribution takes for an empty coordinate set.
  commitmentFieldsOf =
    decl:
    let
      populated = builtins.filter (s: s != null) [
        (if decl.derived.__derived or false then "a derived-channel DAG (`derived`)" else null)
        (if (decl.routes or [ ]) != [ ] then "a delivery route (`routes`)" else null)
        (if (decl.targeted or [ ]) != [ ] then "an aspect-delivery target (`targeted`)" else null)
      ];
    in
    builtins.concatStringsSep " and " (
      if populated == [ ] then
        [ "a commitment in one of `derived` / `routes` / `targeted`" ]
      else
        populated
    );
in
{
  unknownClass =
    policy: name:
    fail "deliver (C6)" "policy `${policy}` names unknown class `${name}` — classes are named channels; register it or fix the name";
  deliverMode = got: fail "deliver (C3)" "invalid mode `${got}` (merge | nest | verbatim)";
  deliverVerbatimModule = fail "deliver (C3)" "mode = \"verbatim\" applies to collected class sources only, not a module source";
  routePathConflict = fail "route (C3)" "`intoPath` and `path` are both present — supply exactly one";
  legacyProvidesAbsent =
    aspect:
    fail "legacy provides (C5)" "aspect `${aspect}` uses legacy `provides` — import denCompat.legacy.provides";

  # A `provides.<key> = <value>` whose value is neither an aspect attrset nor a parametric aspect
  # function (a scalar/string) — it cannot become deliverable content. Named at definition (legacy
  # provides desugar, C4) rather than surfacing as a deep aspect-merge failure.
  provideValueShape =
    got:
    fail "legacy provides (C4)" "a `provides.<key>` value must be an aspect (attrset or parametric function), got ${builtins.typeOf got}";
  legacyForwardsAbsent =
    what:
    fail "legacy forwards (C5)" "`${what}` uses legacy `forwards` — import denCompat.legacy.forwards";

  # C6 identity law AT THE INGESTION BOUNDARY — the one place v1 name-strings convert to registry
  # entries, exactly once. A value that should already be an entry (host/user/aspect/class position)
  # is still a bare string (or otherwise lacks `id_hash`) when it crosses `compile`'s output. Names the
  # position and what was found. This is the shim-side twin of den-hoag's A2 `identityLaw` (which
  # guards the declaration constructors); the shim fails EARLIER, at the boundary the string outran.
  identityLaw =
    position: got:
    fail "identity boundary (C6)" "value at `${position}` crossed the compile boundary without an `id_hash` (got ${builtins.typeOf got}${
      if builtins.isString got then " \"${got}\" — pass the entry, not a \"kind:name\" string" else ""
    }); v1 name-strings become registry entries at ingestion, exactly once";

  # A v1 `policy.exclude` whose target is a POLICY (a `__denCanTake`/`__isPolicy`/function record) rather
  # than an aspect. Suppressing a POLICY's firing at a scope (the corpus's droid `drop-user-to-host-on-droid`
  # excludes the os-user `user-to-host` route) is a distinct mechanism from pruning an aspect edge — it is
  # the droid arm's user-route exclude, DEFERRED to class-B / board #50 (the nixOnDroid class). The class-A
  # `nixosConfigurations` arm never reaches it (the exclude is `host.class == "droid"`-gated). Named here so
  # the droid arm greets a self-announcing rung, never a misleading identity-law abort.
  # #72 (candidate A): a NAMED policy target compiles to `declare.suppress` (the staged pre-pass's
  # exclude family — the class-B stub RETIRED); a NAMELESS one (a bare fn / an uncoerced `__denCanTake`
  # record) has nothing for v1's NAME-KEYED suppression to match (pin dispatch-policies.nix:15-33
  # filters by registry name), so it stays a definition-time abort.
  excludeOfPolicyNameless = fail "exclude-of-policy (#72)" "`policy.exclude` targets a NAMELESS policy value (a bare fn or an uncoerced `__denCanTake` record); v1's suppression is NAME-keyed (pin 11866c16 fx/handlers/dispatch-policies.nix:15-33), so the exclude cannot be routed — target the `den.policies.<name>` registry record (the coerced `{ __isPolicy; name; fn }` shape) or a `mkPolicy`-named record";

  # INLINE-ASPECT kind-include guards (ship-gate, home-env battery). An inline aspect in a
  # `den.schema.<kind>.includes` list (v1's `{ policies; includes }` battery shape, nix/lib/home-env.nix
  # makeHomeEnv) is EXPANDED by `kindIncludePolicies`: its `.includes` are HOISTED into the kind's ref list
  # (each classified normally) and its `.policies` is DROPPED as a verified duplicate. Two loud guards keep
  # the drop honest (the silent-partition ban applies to the drop, not just to per-declaration strata):
  #
  #   (A) VERIFIED-DUPLICATE — every `.policies.<name>` must be NAME-MATCHED by a `.includes` `__isPolicy`
  #       record (fn-equality is unassertable; name-match is the check). The corpus battery mirrors the same
  #       name both sides (v1's name-keyed registration is why its effective firing is ONE); an inline aspect
  #       whose `.policies` carries a NON-mirrored policy aborts here rather than losing it silently.
  inlineAspectPolicyUnmatched =
    name:
    fail "inline-aspect kind-include" "inline-aspect `.policies.${name}` has no matching `.includes` `__isPolicy` record — refusing to DROP a policy silently (the hoist keeps `.includes` and drops `.policies` ONLY as a verified duplicate; a non-mirrored `.policies` entry would be lost). Mirror it into `.includes` as `{ __isPolicy = true; name = \"${name}\"; fn; }`, or register it as a `den.policies.<name>`";
  #   (B) UNKNOWN-KEY — the shim expands ONLY the `{ policies; includes }` battery shape; any other key on an
  #       inline aspect (class content) is not hoisted. Named abort listing the keys rather than a silent drop.
  inlineAspectUnknownKeys =
    keys:
    fail "inline-aspect kind-include (C1)" "an inline aspect in a `den.schema.<kind>.includes` list carries key(s) beyond {includes, policies}: [${builtins.concatStringsSep ", " keys}] — the shim expands only the v1 `{ policies; includes }` battery shape (nix/lib/home-env.nix); class-content on an inline include is not hoisted. Register it as a named `den.aspects.<name>` and include it by reference (`{ name = \"<name>\"; }`)";

  # A FLAT `den.hosts.<name>` entry (keyed by a HOST NAME, not a flakeExposed system string — the v1
  # `preprocessHosts` `directHosts` branch, pin 11866c16 nix/lib/entities/_types.nix:156-170) that omits
  # its `system` field. v1 GROUPS a flat host by that field (`${system} = … ${name} = …`) and THROWS when
  # it is absent (_types.nix:160-162: "den: flat host '<name>' must specify 'system'"). The shim reproduces
  # that loud abort at the ingestion boundary rather than mis-demoting the host's own fields into systems —
  # a flat host with no system is a shape v1 ALSO rejects. Named here so a corpus author greets the same
  # requirement v1 states (the corpus `slab`/`patch` both declare `system`, so this fires only on genuine
  # malformation).
  flatHostNoSystem =
    name:
    fail "hosts (ingest)" "flat host `${name}` (a `den.hosts.<name>` entry keyed by NAME, not a flakeExposed system) must declare a `system` field — v1 groups it by that field (nix/lib/entities/_types.nix:156-170) and throws `den: flat host '${name}' must specify 'system'` when absent; add e.g. `system = \"x86_64-linux\";` or nest it under `den.hosts.<system>.${name}`";

  # A v1 `den.schema.<kind>` names a `parent` kind that no other kind declares — the containment DAG is
  # broken at ingestion. Named at definition time so a schema typo fails legibly, not deep in the fleet
  # product. (den-hoag's built-in `host`/`user` are always present.)
  unknownParentKind =
    kind: parent:
    fail "schema" "kind `${kind}` names parent `${parent}`, which is not a declared kind (known kinds are `den.schema.<kind>` + the built-in `host`/`user`)";

  # A v1 `den.schema.<kind>` sets `isolated = true` (the v1 collection flag, pin 11866c16
  # modules/options.nix:85-88 — default false; NOTHING sets it at the pin or in the corpus). den-hoag's
  # #63 within-class subtree fold (`classSubtreeAt`, output-modules.nix) and the #62c delivery-edge
  # subtree members are BLIND `scope.descendants` walks — the §8-risk-2 ceiling: an isolated kind would
  # need those gathers to STOP at the isolation boundary v1's isolation-aware fold honors
  # (push-scope.nix:64), and a blind walk would silently OVER-GATHER a descendant's class content across
  # it into the ancestor's assembly (a wrong drv, not a crash). Until an isolation-aware walk lands, an
  # ingested isolated kind refuses LOUD at ingestion — never a silent mis-fold.
  isolatedKindUnsupported =
    kind:
    fail "schema (§8 isolation ceiling)" "kind `${kind}` sets `isolated = true` — den-hoag's subtree gathers (#63 classSubtreeAt, #62c delivery members) are blind descendants walks that would silently over-gather class content across the isolation boundary v1 stops at (pin 11866c16 options.nix:85-88; push-scope.nix:64). Unset `isolated`, or build the isolation-aware walk (the §8 risk-2 ceiling) first";

  # A v1 `pipe.from` names a stage the shim does not compile: it handles the §2.4 stage vocabulary
  # (filter/transform/fold/for + to/as + append/expose/broadcast/collect/collectAll/withProvenance).
  # Anything else names itself here rather than compiling to a silent no-op (pipe.nix `stageOp`).
  unknownPipeStage =
    kind:
    fail "pipe stage (C3)" "unknown v1 pipe stage `${kind}` — the shim compiles §2.4 (filter/transform/fold/for, to/as, append/expose/broadcast/collect/collectAll/withProvenance)";

  # A v1 `pipe.as` whose target is not the channel NAME string — in practice a quirk REF, the form
  # `pipe.from` accepts. The ref affordance is `from`'s ALONE: v1 resolves `pipeNameOrRef.name` in the
  # `from` constructor (pin 7f11ba14 nix/lib/policy-effects.nix:300) and at no other pipe verb, while `as`
  # stores `targetPipeName` unexamined (:331-333). Its one consumer compares that value to a channel name
  # by equality (`getAsTarget e == pipeName`, fx/assemble-pipes.nix:506,989) and an attrset never equals a
  # string, so under v1 a ref target selects no pipe, delivers nothing, and says nothing. The shim refuses
  # instead — identical acceptance to v1 for every target v1 routes, LOUD where v1 drops the data.
  pipeAsTargetNotAName =
    got:
    fail "pipe stage (C3)" "`pipe.as` takes the target channel NAME as a string, got ${builtins.typeOf got}${
      if builtins.isAttrs got && builtins.isString (got.name or null) then
        " — a quirk ref for `${got.name}`; write `pipe.as \"${got.name}\"`"
      else
        ""
    }. The ref form belongs to `pipe.from`, which resolves it to `.name`; `as` matches its target against the channel name by string equality, so a non-string target routes nothing";

  # THE F6 CEILING (catalog v33, ruled): a CONFIG-DEPENDENT (config/osConfig-demanding, deferred)
  # channel emission gathered by a CROSS-SCOPE collect/collectAll. den-hoag resolves a deferred
  # contribution at ITS producing scope's terminal (decision #27) — for a COLLECTED contribution the
  # producer is a DIFFERENT root (a sibling host), so resolving it at the consuming terminal would force
  # the producer host's config from inside the consumer's eval: the cross-host config fixpoint v33
  # explicitly rules OUT ("no cross-host config-fixpoint machinery"). Corpus-zero (every corpus
  # collect-channel emit is pipeline-parametric or plain — resolved at the emitting node by U9.1), so
  # this refuses LOUD, never a silently wrong or diverging value.
  collectedConfigThunk =
    {
      channel,
      producer,
      consumer,
    }:
    fail "collect (U9.2 F6 ceiling)" "channel `${channel}`: a config-dependent (deferred) emission at `${producer}` was gathered by a cross-scope collect at `${consumer}` — resolving it would force the producer's config from the consumer's eval (the cross-host config fixpoint catalog v33 rules out). Make the emission pipeline-parametric (binding-surface args) or plain";

  # A name declared as BOTH a class (`den.classes.<name>`) and a quirk channel (`den.quirks.<name>`):
  # den-hoag's `resolveBucket` unions classes ∪ channels, so an overlapping name is ambiguous at
  # dispatch. Named at definition time — the key-overlap check §2.4 preserves from v1.
  quirkClassOverlap =
    name:
    fail "quirks (C3)" "`${name}` is declared as both a class and a quirk channel — a name is one or the other (classes ∪ channels must stay disjoint); rename one";

  # A v1 policy effect the shim does not compile: it handles the structural/resolution vocabulary —
  # include/exclude/resolve and the for/when combinators; deliver/route/provide and pipe land with their
  # own passes (named above). Anything else names itself here rather than being mis-routed.
  unsupportedEffect =
    effect:
    fail "policy effect" "unsupported v1 policy effect `${effect}` — the shim compiles include/exclude/resolve and for/when; deliver/route/provide and pipe land with their own passes";

  # THE RESOLVE ARM — corpus-UNEXERCISED variants (user-delivery R2, design note 2026-07-11 §3(i)). The
  # census (nix-config @ b0b20769, modules/den/policies/) exercises ONLY `resolve.to "<kind>" { … }`: bare
  # `resolve {}`, `resolve.shared.*` and `resolve.*.withIncludes` are v1-surface totality the constructor
  # reproduces faithfully, but the compat ARM has no corpus-verified translation for them yet. Each names
  # itself here (LOUD, never a silent drop) so the rung that first needs it greets a named blocker.
  resolveNoTargetKind = fail "resolve arm (R2)" "a bare `resolve { … }` (no `__targetKind`) has no compat translation — the shim routes `resolve.to \"<kind>\" { … }` (cell kind → member, root kind → containment member). The corpus (b0b20769) never emits a bare resolve; supply an explicit target kind, or build the untargeted fan-out arm when a corpus body first needs it";
  resolveShared =
    kind:
    fail "resolve arm (R2)" "`resolve.shared.to \"${kind}\" { … }` (non-isolated fan-out) has no compat translation — the corpus (b0b20769) uses only the isolated `resolve.to`. Build the shared-branch member semantics when a corpus body first exercises it";
  resolveWithIncludes =
    kind:
    fail "resolve arm (R2)" "`resolve.*.withIncludes` targeting `${kind}` (a resolved node riding `includes` classes) has no compat translation — the corpus (b0b20769) emits `includes = [ ]` at every `resolve.to`. Build the includes-riding arm (the resolved cell's edged classes) when a corpus body first exercises it";
  resolveUnknownKind =
    kind:
    fail "resolve arm (R2)" "`resolve.to \"${kind}\" { … }` names a kind absent from the ingested containment schema (`ing.schema`) — a resolve target must be a declared kind (a cell kind → a member tuple, or a root kind → a containment member). Declare `den.schema.${kind}` (with its `parent`), or fix the target-kind spelling";

  # ASPECT-INCLUDE POLICY-RECORD DIVERSION (#65, ledger u16) — a `{ __isPolicy }` record in an aspect
  # `.includes` diverts to its compiled `__aspectInclude__<name>` rule (v1 children.nix:70-72
  # register-aspect-policy parity; compile.nix `aspectIncludePolicies` + the `keepInclude` filter). A
  # record reaching `normalizeList` that the static collection walk did NOT see (a runtime-CONSTRUCTED
  # record from outside the walked `den.aspects`/`den.default.includes` trees — corpus-zero) has no
  # compiled rule: stripping it would silently DROP a policy (banned), grounding it would abort on its
  # `fn` key (misleading). Name it here instead.
  unregisteredPolicyInclude =
    name:
    fail "aspect-include policy record (#65)" "a `{ __isPolicy }` include record `${name}` reached include-normalization without a compiled `__aspectInclude__` rule — it was not found by the static collection walk over `den.aspects`/`den.default.includes` (a runtime-constructed or out-of-tree record; a NAMELESS record is a v1 authoring error too — v1's register-aspect-policy requires `name`, children.nix:57). Author the record in the registry aspect tree it fires from, or extend the walk to its surface";

  # A class-content COLLAPSE reached include-normalization: an `includes` element whose navigated value was
  # a class-named aspect key carries the gen-aspects classOptions-slot `{ imports = […] }` deferredModule.merge
  # bucket, never an aspect. THE NAME RESERVATION: a `den.aspects.<path>.<class>` key whose LEAF names a
  # declared class is CLASS CONTENT by registry membership, so the typed view materializes it as that
  # class's deferredModule and a `with den.aspects; [ <path>.<class> ]` navigation reaches a keyless module.
  # Eager name-classification is the declared semantics (it is what makes classification independent of
  # whether the parent aspect is ever resolved), so the collision is real and the remedy is a RENAME — but
  # the rename is undiscoverable from the value alone, which carries no aspect name and no class name.
  # This names both sides at the declaration that authored them. ATTRIBUTION WITHOUT IDENTITY: the collapse
  # erases the node's `.key`, but `deferredModule.merge` stamps every definition's location
  # `"<origin>, via option <path>.<class>"` (setDefaultModuleLocation), so the option path — the aspect path
  # and the colliding class name — survives inside the bucket. The class half is then confirmed by REGISTRY
  # MEMBERSHIP, never by inspecting the value (the reservation is by NAME).
  reservedClassInclude =
    {
      aspectPath,
      className,
      origin,
      position,
    }:
    fail "reserved class name (C1)" "`den.aspects.${aspectPath}.${className}` is included as an aspect at `${position}`, but `${className}` names a declared class — so that key is CLASS CONTENT (the class-name reservation), and navigating it yields the class's module bucket rather than an aspect with identity.${
      # The origin is the module-system definition location the bucket carries. The compile view re-evaluates
      # the raw tree in its own eval, so today that is a synthetic marker rather than the corpus file; it is
      # reported only when it IS a filesystem path, never as a `<placeholder>` masquerading as attribution.
      if builtins.substring 0 1 origin == "/" then " Declared at ${origin}." else ""
    } RENAME the aspect key off the class name: `den.aspects.${aspectPath}.${className}` -> e.g. `den.aspects.${aspectPath}.${className}-host` (the v1 -> v2 rename rule; nix-config fddab954 renamed `den.aspects.virtualization.microvm` to `virtualization.microvm-host` beside its `den.classes.microvm`). If the key really IS class content, include its OWNING aspect `den.aspects.${aspectPath}` instead, or drop the `den.classes.${className}` registration";

  # PARAMETRIC-ASPECT RESULT — NON-INCLUDE EFFECT IN A LIST (R14 list branch, v1 `mkParametricNext`
  # aspect.nix:72-84). A bare-fn include (`den.schema.<kind>.includes = [ ({ … }: <body>) ]`, a nested
  # bare fn, or an aspect-include bare fn) is a v1 PARAMETRIC ASPECT (`wrapBareFn`), whose `__fn` RESULT is
  # type-dispatched exactly as v1 `mkParametricNext`: an ATTRSET is aspect CONTENT, a LIST is the
  # include-effect-ONLY branch (`grndDispatch` now processes it — include-effect entries contribute their
  # `.value`, bare aspects pass through). v1 THROWS on any OTHER effect kind in that list ("only include
  # effects (or bare aspects) are supported here"); the shim's `toInclude` names the offending kind here.
  parametricNonIncludeEffect =
    name: kind:
    fail "parametric-aspect include (R14 list branch)" "the bare-fn parametric include `${name}` returned a list containing a `${kind}` effect — v1 `mkParametricNext` (aspect.nix:72-84) supports ONLY include effects (or bare aspects) in a returned list. Express a non-include effect (spawn/exclude/route/…) as a `den.policies.<name>` policy referenced in the includes list, not as a list entry returned by a parametric include";

  # SURFACE TOTALITY (C1) — a top-level `den.<key>` the shim does not recognise. The permissive eval is the
  # SHIM'S OWN v1-surface eval (flake-module.nix `v1OptionsModule`, whose `den` submodule carries a
  # `lazyAttrsOf raw` freeformType): it ABSORBS unknown `den.*` keys silently so an arbitrary corpus module
  # evaluates, and that absorption's promised downstream enforcement is HERE, over the read-back config.
  # DEN v1 IS NOT PERMISSIVE AT THIS LEVEL — it declares each `den.*` key individually and puts no freeform
  # type on the `den` submodule itself, so an unknown top-level key is an UNDECLARED OPTION there, not an
  # absorbed one. v1's freeform absorption sits one level DOWN, at host ENTRY keys (`strict = false` on the
  # schema instance type, v1 entities/host.nix), where an unknown key does ride inertly. So C1's job is the
  # SHIM's own ingest surface being permissive where v1's is not: a typo'd or unknown surface key is
  # rejected with a name — never silently dropped (the C1 freeform-absorption trade-off). Names the
  # offending key + the surface the shim compiles.
  unknownSurfaceKey =
    key:
    fail "surface totality (C1)" "unknown `den.${key}` — the shim compiles { hosts, homes, schema, aspects, policies, classes, include, quirks, contentClass, default, <declared custom kinds> }; a typo'd or unknown `den.*` key is absorbed by the shim's OWN permissive v1-surface eval (den v1 does NOT absorb it — there an unknown top-level `den.*` key is an undeclared option) and rejected HERE, never silently dropped. Fix the key or extend the surface";

  # NOT-IMPLEMENTED-BY-CENSUS (C1 surface totality) — an aspect carrying `meta.__forward`, the manifestation
  # of `den.batteries.forward` (v1 `nix/lib/forward.nix` `forwardItem`). The shim does NOT implement the
  # forward-battery NTA path: the corpus census found ZERO consumers (PIN.md Open-Question-2, Tier-2
  # derived-children NTA deliberately unbuilt). Rather than pass `meta.__forward` through as opaque aspect
  # content (silently wrong), the surface aborts named, with a migration pointer. Witness-mapped as
  # not-implemented-by-census (parity/fixtures/witness-map.nix `batteriesForward`).
  batteriesForwardUnsupported =
    aspect:
    fail "batteries.forward (not implemented — corpus-zero census)" "aspect `${aspect}` carries `meta.__forward` (a `den.batteries.forward` manifestation); the shim does not implement the forward-battery NTA path — PIN.md Open-Question-2 records zero corpus consumers. Migrate the forward to a native den-hoag class + `deliver` (the tier-1 path legacy/forwards.nix takes), or, if a corpus consumer appears, build the Tier-2 derived-children NTA in legacy/forwards.nix and re-open Open Question 2";

  # THE CODOMAIN RECOVERY FAILURES (policy-recover.nix). A v1 bare closure carries no declaration
  # codomain, so the shim recovers one by firing it once at a value-less sentinel. Both failure modes are
  # the SHIM's, never the kernel's, and both are LOUD: the recovery never reports an error as an empty
  # emission, because "threw" and "emitted nothing" are different facts and collapsing them is the defect
  # the declared codomain removes.
  policyCodomainUnrecoverable =
    name:
    fail "policy codomain recovery" "could not determine the declaration codomain of v1 policy `${name}`: firing it against a value-less sentinel context raised an error, which is a RECOVERY FAILURE and NOT evidence that the policy emits nothing. Declare the kinds it produces (compat/produces-by-name.nix `${name} = [ <kind> ]`) so the shim never fires it; a body reading a coord FIELD absent from the sentinel is the usual cause (compat/probe-sentinel.nix)";
  policyCodomainUndeclared =
    name:
    fail "policy codomain" "v1 policy `${name}` declares no codomain and codomain recovery is OFF (`den.features.policyRecovery = false`). Flag-off is strictly more strict: declare the kinds it produces (compat/produces-by-name.nix `${name} = [ <kind> ]`)";

  # THE SPY REFUSAL — the codomain fire was CAUGHT, so the body decides what it emits from a COORDINATE
  # VALUE, and no authored source declares the field(s) that fire was recovering.
  #
  # WHY A REFUSAL AND NOT A WORSE RECOVERY. A codomain is a STATIC property of a body. A value-conditional
  # body has no codomain at a value-less context — it has one per context — so there is no answer to
  # invent, and the shipped value sentinel's answer (the body's FALSE branch, silently) is the
  # unsoundness this refusal replaces. The refusal is the honest total: the question is refused where it
  # has no answer, and the remedy states the answer the body cannot.
  #
  # ★ IT NAMES THE COORDINATE, NEVER THE FIELD THE BODY READ. The spy binds every coordinate field to a
  # named throw, but `tryEval` DESTROYS a caught throw's message, so the field name does not survive the
  # envelope. What does survive is the per-coordinate attribution loop's verdict, synthesized on this
  # side of the boundary exactly as `commitmentFireFailed` is.
  # ★ IT NAMES THE MISSING DECLARATION FIELD, because COMPLETING THE DECLARATION is the remedy — not
  # rewriting the body, and not restating fields some source already declares. The caller reaches this
  # only after the ref, the fleet surface and the shim tables have all been consulted (compile.nix
  # `codomainChain`), so a field named here is declared NOWHERE.
  # ★ THE REMEDY IS A COMPLETE RECORD, because `den.policyCodomains` is TOTAL BY TYPE: a partial record
  # is refused at the option, so printing one would print a value this design's own surface rejects.
  codomainValueConditional =
    name: declared: needed: declaredValues: reads:
    let
      renderList = xs: "[ " + builtins.concatStringsSep " " (map (s: "\"${s}\"") xs) + " ]";
      field = f: "${f} = ${if declaredValues ? ${f} then renderList declaredValues.${f} else "[ ]"};";
      remedy = builtins.concatStringsSep " " (
        map field [
          "emits"
          "binds"
          "suppresses"
        ]
      );
      declares =
        if declared == [ ] then
          "declares no codomain"
        else
          "declares ${builtins.concatStringsSep ", " declared}";
    in
    fail "policy codomain" "v1 policy `${name}` ${declares} but no source declares ${builtins.concatStringsSep ", " needed}, and recovering the omitted field(s) requires firing a body that decides what it emits from a coordinate value. A codomain is a STATIC property of a body, decided before any node exists, so there is no context at which this question has an answer and the shim will not invent one. The coordinate(s) it reads: ${
      if reads == [ ] then
        "«no single coordinate could be attributed»"
      else
        builtins.concatStringsSep ", " reads
    }. COMPLETE THE DECLARATION — beside the policy, leaving the body untouched: `den.policyCodomains.${name} = { ${remedy} };`. The declaration is TOTAL: all three fields are stated, and `[ ]` is a legal value meaning the body produces none of that kind. `emits` names the kinds the body may produce at ANY context — the UNION over its branches, not the ones it takes at some particular node";

  # THE FLEET SURFACE'S OWN TYPE REFUSAL, raised by the shim rather than by the option type.
  # `den.policyCodomains` is typed `attrsOf (submodule …)` with all three fields REQUIRED at
  # flake-module.nix, so a module-evaluated fleet is refused there. This is the SAME refusal for the
  # `denCompat.compile`-direct path, which never crosses an option type at all — without it the design's
  # headline claim ("an omitted field is impossible BY TYPE") would hold on one entry path and not the
  # other, which is an authoring convention wearing a type's clothes.
  policyCodomainNotTotal =
    name: value:
    let
      fields = [
        "emits"
        "binds"
        "suppresses"
      ];
    in
    if !(builtins.isAttrs value) then
      fail "policy codomain" "`den.policyCodomains.${name}` is not a record. A codomain declaration is a closed record of ${builtins.concatStringsSep ", " fields}"
    else
      let
        missing = builtins.filter (f: !(value ? ${f})) fields;
        extra = builtins.filter (f: !(builtins.elem f fields)) (builtins.attrNames value);
      in
      if missing != [ ] then
        fail "policy codomain" "`den.policyCodomains.${name}` omits ${builtins.concatStringsSep ", " missing}. A codomain declaration is TOTAL: every kind a body may produce is stated, and every kind it may not is stated as the EMPTY HEAD. Write the omitted field(s) as `[ ]` — that is a declaration, not a placeholder, and it is what makes the recovery unnecessary for this policy"
      else
        fail "policy codomain" "`den.policyCodomains.${name}` carries unknown field(s) ${builtins.concatStringsSep ", " extra}. The codomain vocabulary is closed: ${builtins.concatStringsSep ", " fields}";

  # TWO AUTHORED STATEMENTS IN CONFLICT, at the two codomain surfaces. The v1 ref's own field and
  # `den.policyCodomains.<name>` are BOTH authored, so DECLARATION-BEATS-DERIVATION — which orders an
  # authored value above a DERIVED one — is SILENT between them, and reading a silent principle as though
  # it spoke is how a precedence gets installed without an argument. Either ordering makes one of the two
  # authored statements disappear with no signal. Refused instead, exactly as
  # `selectsConflictsWithSchemaExclude` refuses the same shape one surface over.
  policyCodomainConflict =
    name: field:
    fail "policy codomain conflict" "v1 policy `${name}` declares `${field}` on its own record AND at `den.policyCodomains.${name}`, and the two DISAGREE. Both are AUTHORED statements — neither is a derivation — so declaration-beats-derivation does not order them, and honouring either one would discard the other silently. den-hoag refuses instead. DROP ONE: remove `${field}` from the policy record to keep the fleet declaration, or remove it from `den.policyCodomains.${name}` to keep the record's";

  # LAW (a) — a compose commitment RECOVERED from a policy that declares no codomain. The commitment fire
  # is gated on the DECLARED codomain, so a body producing a derived-channel DAG or a delivery route
  # without a declaration has stated a fleet-wide commitment nothing will ever collect: the fleet compose
  # seed is built BEFORE the eval, from declared bodies only. Refused rather than dropped — a dropped
  # commitment is the silent-vanish class this seam exists to close, and it is the class the kernel's
  # retired `opsInBody` refused for the same reason at the other end of the same boundary.
  # ★ RAISED FROM THE RETURNED DECLARATIONS, never from inside a body: `classifyDecls` wraps its fire in
  # `tryEval`, which DESTROYS a caught throw's message, so a refusal raised inside would arrive as
  # `policyCodomainUnrecoverable` with the channel and the field gone.
  # ★★ THE MESSAGE READS ONLY FIELDS THE FIRE HAS ALREADY FORCED, so a message-construction throw is
  # structurally impossible rather than merely unobserved — AND ITS WARRANT IS NOW A COUPLING, NOT A
  # FORCING DEPTH. This used to rest on `recoverDecls`' own `deepSeq`, which forced everything the
  # declarations carried; that `deepSeq` is gone, replaced by `policy-recover.nix` `recoveryDomain`, which
  # forces EXACTLY the kind set, the refined codomains, and `lawAFields`. The conclusion survives because
  # `lawAFields` is DEFINED as every field `commitmentFieldsOf` reads plus the `channel` rendered around
  # it — so `commitmentFieldsOf` is a COUPLED SURFACE: a field added to it below is a field owed to that
  # domain in the same edit, and adding one without it reopens exactly the message-construction throw this
  # sentence rules out.
  commitmentUndeclared =
    policyName: decl:
    fail "compose commitment" "policy `${policyName}` produced a `pipeCommit` declaration on channel `${decl.channel}` carrying ${commitmentFieldsOf decl}, from a body whose codomain is NOT DECLARED. A compose commitment seeds the ONE fleet gen-pipe compose before the eval, so it is collected from the DECLARED codomain only — an undeclared one would be built and never applied. Declare this policy's codomain as `[ \"pipeCommit\" \"pipeMark\" ]`, either in `lib/compat/produces-by-name.nix` or as `emits` on the v1 ref. BOTH kinds are required: the mark route emits a `pipeMark` at every dispatched node, so a `pipeCommit`-only declaration clears THIS abort and fails the next one at `emitsUndeclared`";

  # THE COMMITMENT FIRE'S OWN ABORT, SYNTHESIZED AT THE FIRE SITE rather than read out of the throw.
  # Nix discards a caught throw's message, so a diagnostic routed through `tryEval` cannot carry what the
  # boundary destroyed; this one is built on the caller's side of it, from the policy name and the gate.
  # `attributed` is the coordinate set a per-coordinate re-probe blamed — best-effort in BOTH directions
  # (it can under-name on a value-dependent branch and over-name on an intrinsic sentinel failure), so an
  # EMPTY attribution renders the full candidate set rather than degrading to silence.
  # ★ CEILING, stated because a fixture pins it: this fires only where `tryEval` CAUGHT the failure. A
  # coordinate consumed BY TYPE (`builtins.elem g accessGroups` on an attrset) raises Nix's own
  # argument-type error, which is uncatchable, so the eval stops with no den-compat diagnostic at all.
  commitmentFireFailed =
    policyName: channel: attributed: candidates:
    fail "compose commitment fire" "firing v1 policy `${policyName}` at the commitment sentinel raised an error while building its compose commitment${
      if channel == null then "" else " on channel `${channel}`"
    }. ${
      if attributed != [ ] then
        "The coordinate(s) it reads: ${builtins.concatStringsSep ", " attributed}"
      else
        "No single coordinate could be attributed, so the full candidate set is named: ${builtins.concatStringsSep ", " candidates}"
    }. A commitment fire binds EVERY gate coordinate to a THROWING sentinel, because a commitment is read once at DEFINITION time where no node exists — so any per-node value the body reads has no answer there. Rewrite the commitment so it reads no coordinate, or drop `pipeCommit` from this policy's declared codomain so it is never fired at the sentinel";

  # `den.schema.<K>.excludes` whose target policy attaches at a STRICT DESCENDANT of K. v1 registers an
  # exclude with `scope = "subtree"`, so it suppresses the policy at K and at every node beneath K — but
  # only beneath THAT K instance. A flat per-kind selection can only remove the policy at a KIND, which
  # would suppress it under every instance of K's ancestor chain, not just this one: strictly more than
  # the config asked for. den-hoag refuses rather than over-suppress. The same-kind case IS honoured,
  # because there the two extents coincide exactly.
  excludeSubtreeUnrepresentable =
    kind: policyName: attachKind:
    fail "schema exclude scope" "`den.schema.${kind}.excludes` names policy `${policyName}`, which attaches at kind `${attachKind}` — a strict DESCENDANT of `${kind}` under the containment schema. A v1 exclude is SUBTREE-scoped (it suppresses the policy beneath the excluding `${kind}` instance only), and den-hoag currently represents selection per KIND, which cannot say `beneath this instance`. Honouring it flatly would suppress `${policyName}` at every `${attachKind}` in the fleet, which is more than the declaration asks for, so it is refused instead of silently over-applied. The same-kind case (`${policyName}` attaching at `${kind}`) IS supported";

  # TWO AUTHORED STATEMENTS IN CONFLICT, refused rather than ordered. `den.schema.<K>.excludes` naming a
  # policy states that the policy is not selected at `K`; an authored `selects` on that same record states
  # the selection itself. BOTH are authored — an exclude is a DECLARATION made at the schema, not a
  # derivation — so DECLARATION-BEATS-DERIVATION, which orders an authored value above a DERIVED one, is
  # SILENT here, and reading it as though it spoke is how a precedence gets installed without an argument.
  # Either ordering makes one of the two authored statements DISAPPEAR with no signal, which is the defect
  # class the required-and-total `selects` surface exists to remove, arriving between two surfaces instead
  # of inside one field. So the conflict is made UNREPRESENTABLE rather than silently resolved, and it is
  # decidable exactly where it is created (the ref, the kind and the exclusion are all in hand at the
  # kind-include policy arm), so refusing costs no new information and no new instrument.
  #
  # ★ IT FIRES ON THE CONFLICT OF STATEMENTS, NOT OF OUTCOMES. An authored `selects` that happens to equal
  # `sel.any [ ]` agrees with the exclusion, but noticing that agreement would need selector equality —
  # which this surface declines to rest on. Refusing the stated conflict needs no equality at all.
  selectsConflictsWithSchemaExclude =
    kind: policyName:
    fail "authored selects vs schema exclude" "policy `${policyName}` carries an authored `selects` AND is named by `den.schema.${kind}.excludes` — two AUTHORED statements in conflict at kind `${kind}`: the record states its own selection, while the schema states that `${policyName}` is not selected at `${kind}`. Neither is a derivation, so declaration-beats-derivation does not order them, and honouring either one would discard the other silently. den-hoag refuses instead. DROP ONE: remove `selects` from `${policyName}` to keep the schema exclusion, or remove `${policyName}` from `den.schema.${kind}.excludes` to keep the authored selection";
}
