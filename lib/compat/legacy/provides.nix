# den-compat LEGACY surface: `provides` (self-contained, tagged — the severance surface, §2.1).
#
# The full v1 `provides.<name>` surface desugared to `neededBy` under §B4a registration-scope
# visibility. The `desugar` is a PURE v1-aspects → v1-aspects transform (Law C2 — no evaluation, no
# scope-graph reads, no resolved-state reads): each `provides` entry becomes a SYNTH CARRIER aspect
# (a den-hoag aspect carrying `neededBy` + the provided content) plus a seed on the declaring aspect's
# `includes`, and the `provides` key is stripped. den-hoag never sees `provides`; it sees only the
# grounded `neededBy`/`includes`/content vocabulary the shim core already passes through (compile.nix
# `translateAspect`). Severable: the ONE reference to this module outside `legacy/` is the flakeModule
# assembly (flake-module.nix `mkDen`, which applies `desugar`); absent, compile.nix's sentinel
# (sentinels.nix) turns any residual `provides` key into `errors.legacyProvidesAbsent` (Law C5).
#
# ── HOW the desugar reproduces v1 dispatch (the parity-watch adjudications) ────────────────────────
#
# v1's `provides` (aspect/provide.nix `mkCrossPolicy` + `mkSelfProvideInclude`, frozen pin
# denful/den@11866c16) registers a late-dispatch POLICY at the declaring aspect's resolution scope
# (`ownerIdentity`); the policy fires at DESCENDANT scopes whose destructured args are satisfied
# (`synthesize-policies.nix` `resolveArgsSatisfied`: a policy `fn`'s formals with no default must all
# be present in ctx) and whose gate passes. den-hoag's §B4a `neededBy` radiates a carrier DOWN the
# containment DAG from its seed scope to every descendant the selector matches (resolved-aspects.nix
# `ancestorResolvedKeys` + `neededByActivates` cond-2 `visible ? keyOf carrier`). The two coincide
# on the deliverable (user) scopes — the positions `provides` is FOR — as follows:
#
#   provides.to-users / provides.to-hosts  →  neededBy = sel.kind <user>
#     ADJUDICATION 1 (to-hosts ≡ to-users, evidence-based): v1's `mkCrossPolicy` gives BOTH `to-hosts`
#     and `to-users` the IDENTICAL policy fn `{ host, user, ... }: [ include (applyProvide v {host;user}) ]`
#     (provide.nix:21-30). Its required formals are `host` AND `user`, so `resolveArgsSatisfied` fires
#     it ONLY where both are in ctx — i.e. at USER/home cells, never at a bare host scope (which has
#     `host` but not `user`). So in v1 `to-hosts` and `to-users` reach the SAME positions (every
#     deliverable descendant); the names differ in intent only. The faithful desugar therefore radiates
#     BOTH to `sel.kind <user>` — den-hoag's single deliverable kind (ingest.nix folds `den.homes` and
#     `host.users` into ONE `user` registry, so there is no separate `home` kind; "user" IS user∪home).
#     A `to-hosts` → `sel.kind <host>` desugar (delivering at host scopes) would DIVERGE from v1 and is
#     rejected here on that evidence. [If a corpus ever relies on to-hosts landing HOST-class content,
#     that lands via the provided VALUE's own class routing at the user cell — the position is the same.]
#
#   provides.<entityName>  →  neededBy = sel.and [ (sel.kind <user>) (nameMatches entityName) ]
#     v1's named handler (provide.nix:32-42) makes every entity arg OPTIONAL and gates INSIDE on
#     `atDeliverableScope (user!=null || home!=null) && (host.name==key || user.name==key)`. `nameMatches`
#     reproduces that predicate over the den-hoag cell context; `sel.kind <user>` supplies the
#     deliverable-scope restriction. Runs at PRESENCE-RESOLUTION time (inside the neededBy fixpoint's
#     candidate match), never compile-time — entities declared/spawned later still match (C4 exactness).
#
#   provides.<ownName>  →  self-provide: merged INTO the declaring aspect (local, no radiation), with
#     `meta.provider = (old ++ [name])` and `meta.selfProvide = true`, per v1 `mkSelfProvideInclude`.
#
# ── ADJUDICATION 2 (containment-based B4a visibility ≡ v1 registration-scope) + the residual ────────
# A carrier seeded at scope R radiates to exactly R's deliverable descendants (proven for the identical
# selectors by den-hoag's own b4-fixpoint: a `sel.kind user` carrier at host:axon reaches axon's users
# and NOT another host's). This MATCHES v1: a `provides` on a host-included aspect reaches that host's
# users only; env-included reaches all users under the env; root-included is fleet-wide.
#   RESIDUAL, compensated: den-hoag's cond-2 requires the carrier's KEY be visible above the target,
#   which means SOMETHING carrying that key must resolve at the seed scope R — v1's policy registers at
#   R but MATERIALIZES nothing there. We compensate by seeding a CONTENTLESS STUB (`{ name = key; }`) on
#   the declaring aspect's `includes`: R gains only an empty-content aspect key (an empty class module,
#   a no-op in every class evaluation), while the full-content carrier (top-level, indexed `neededBy`)
#   radiates to the cells. So the DELIVERED CONTENT appears only at the deliverable cells, as in v1; the
#   sole structural residual is an empty key in R's resolved-aspect SET (never in v1's). This is a
#   set-level, content-null difference; the C7/C8 oracle confirms it globally.
{
  denHoag,
  prelude,
  errors,
  ...
}:
let
  inherit (denHoag) sel;

  # den-hoag's single deliverable kind. `sel.kind` stores only the kind NAME (`{ __sel="kind"; kind; }`,
  # gen-select constructors.nix), so this minimal kind value yields a selector BYTE-IDENTICAL to
  # `sel.kind config.den.schema.user` — no dependency on a live mkDen (Law C2: the desugar is pure).
  # "user" is den-hoag's built-in leaf kind and the target of ingest.nix's homes+users fold (§8).
  userKind = {
    kind = "user";
    options = { };
  };

  # nameMatches: a legacy-module-LOCAL predicate over the cell context, lifted through `sel.when`
  # (adds NOTHING to gen-select's constructor list — roadmap §8 keeps it fixed). `key` is a v1 surface
  # attr NAME (a string — the C6 internal-key carve-out); it is COMPARED against the cell's host/user
  # entry names and never crosses this module's boundary. Deliverable-scope-only: a user cell must be
  # present (`d ? user`) — a bare host scope is inert, and a standalone `user@host` home matches on its
  # synthetic host identity (ingest.nix `buildMembership`), reproducing v1 `aspect/provide.nix` exactly.
  # `sel.when`'s fn receives `(id, ctx)`; `ctx.data id` is the scope-adapter projection of the node
  # (its `decls` — the `host`/`user` coordinate entries — plus `type`/`__identity`).
  nameMatches =
    key:
    sel.when (
      id: ctx:
      let
        d = ctx.data id;
      in
      (d ? user) && (((d.host.name or null) == key) || ((d.user.name or null) == key))
    );

  # A provided VALUE → the den-hoag content it contributes on a carrier. A plain aspect attrset inlines
  # its class/channel/`includes` keys directly (dropping the structural `name`/`neededBy`/`provides`
  # that must come from the carrier, not the value). A parametric value (a bare function, or a v1
  # `__fn`/`__functor` wrapper — v1's `applyProvide` resolution shapes) rides as an `includes` member so
  # den-hoag resolves it with the cell's own ctx (its moduleArgs carry `host`/`user`), reproducing v1's
  # `applyProvide value { host; user }` per firing scope. (Byte-level content parity is the C8 oracle's;
  # here the value is placed so its content lands at the deliverable cells.)
  isParametric =
    v:
    builtins.isFunction v
    || (builtins.isAttrs v && ((v.__fn or null) != null || (v.__functor or null) != null));
  providedContent =
    v:
    if isParametric v then
      { includes = [ v ]; }
    else if builtins.isAttrs v then
      builtins.removeAttrs v [
        "name"
        "neededBy"
        "provides"
      ]
    else
      # A scalar provided value is not a valid aspect body — name it at definition (Law: legible abort).
      errors.provideValueShape v;

  # One cross-entity provides entry → its SYNTH CARRIER: a top-level den-hoag aspect carrying the static
  # `neededBy` selector (readable without forcing content, §339) + the provided content. Registered
  # top-level so resolved-aspects.nix `indexByNeededBy` (which scans `config.den.aspects`) sees its
  # `neededBy`; a bare include would never be indexed.
  mkCarrier =
    aName: key: value:
    let
      isCross = key == "to-users" || key == "to-hosts";
      selector =
        if isCross then
          sel.kind userKind # ADJUDICATION 1: to-hosts ≡ to-users → the deliverable kind
        else
          sel.and [
            (sel.kind userKind)
            (nameMatches key)
          ];
    in
    {
      name = "${aName}/${key}";
      neededBy = selector;
    }
    // providedContent value;

  # Recursive attrset merge (nixpkgs-lib-free; rhs wins at conflicting LEAVES, attrsets merge). The
  # self-provide content is DEEP-merged into the declaring aspect exactly as v1's aspectType.merge folds
  # the self-provide include into the same-named carrier — so the aspect's own class-bucket content and
  # the provided content coexist (a shallow `//` would let one class bucket clobber the other). `includes`
  # is handled additively OUTSIDE this merge (lists concatenate, they never rhs-clobber).
  rmerge =
    a: b:
    if builtins.isAttrs a && builtins.isAttrs b then
      builtins.listToAttrs (
        map (k: {
          name = k;
          value =
            if (a ? ${k}) && (b ? ${k}) then
              rmerge a.${k} b.${k}
            else if b ? ${k} then
              b.${k}
            else
              a.${k};
        }) (builtins.attrNames (a // b))
      )
    else
      b;

  # Self-provide (`provides.<ownName>`) → the content + provider tag to DEEP-merge into the declaring
  # aspect (name-identity ⇒ local, no radiation). v1 `mkSelfProvideInclude`: `meta.provider` grows by
  # the aspect name, `meta.selfProvide = true`. Returns only the provided content + provider meta; the
  # caller rmerges it onto the aspect (so `meta.provider` folds onto any existing chain).
  mkSelfContent =
    aName: aspect: value:
    (providedContent value)
    // {
      meta = {
        provider = (aspect.meta.provider or [ ]) ++ [ aName ];
        selfProvide = true;
      };
    };

  # Desugar ONE declaring aspect's `provides` → { synths; seedStubs; selfMerge }. `synths` are new
  # top-level carriers; `seedStubs` seed each carrier KEY (contentless) on the declaring aspect's
  # `includes` so cond-2 visibility holds at the deliverable descendants without materialising content
  # at the seed scope (ADJUDICATION 2 compensation); `selfMerge` folds a self-provide into the aspect.
  desugarOne =
    aName: aspect:
    let
      provides = aspect.provides;
      keys = builtins.attrNames provides;
      crossKeys = builtins.filter (k: k != aName) keys;
      hasSelf = builtins.elem aName keys;
    in
    {
      synths = builtins.listToAttrs (
        map (key: {
          name = "${aName}/${key}";
          value = mkCarrier aName key provides.${key};
        }) crossKeys
      );
      # A-IDENT (gen-aspects @14652a0): the seed stub is a NAME-REF to the top-level carrier `${aName}/${key}`,
      # so it MUST key to that referent — NOT to its own includes-POSITION. gen-aspects re-roots a bare
      # include's `meta.aspect-chain` off the option path (`[<aspect> includes]`, types.nix:233 mkDefault) and
      # `identity.key = pathKey(chain ++ [name])`, which would prepend the position → `<aspect>/includes/<name>`,
      # diverging from the carrier's top-level `${aName}/${key}` (chain `[ ]`) and BREAKING the `neededBy`
      # cond-2 visibility (`visible ? keyOf carrier`) — the carrier never radiates. Pin the chain to `[ ]`
      # (mkDefault yields to this explicit set) so the stub keys as `${aName}/${key}`, matching the carrier.
      seedStubs = map (key: {
        name = "${aName}/${key}";
        meta.aspect-chain = [ ];
      }) crossKeys;
      selfContent = if hasSelf then mkSelfContent aName aspect provides.${aName} else null;
    };

  # The public desugar: v1-aspects map → v1-aspects map with every `provides` desugared. Aspects without
  # `provides` (incl. bare-function aspects) pass through untouched. Synth carrier names are `<a>/<key>`
  # — the `/` keeps them disjoint from user aspect identifiers (like compile.nix's `__kindInclude__`).
  desugar =
    aspects:
    let
      declaring = prelude.filterAttrs (_: a: builtins.isAttrs a && (a.provides or null) != null) aspects;
      per = builtins.mapAttrs desugarOne declaring;
      allSynths = prelude.foldl' (acc: r: acc // r.synths) { } (builtins.attrValues per);
      augmented = builtins.mapAttrs (
        aName: a:
        if per ? ${aName} then
          let
            r = per.${aName};
            noProv = builtins.removeAttrs a [ "provides" ];
            # `includes` merge additively (carrier's own ++ any parametric self-content include ++ the
            # contentless seed stubs); everything else DEEP-merges the self-provide content onto the
            # carrier (rmerge), so self content and own content coexist. `includes` is stripped from
            # both sides of the rmerge to keep the additive semantics (rmerge would rhs-clobber a list).
            selfContentBody =
              if r.selfContent == null then { } else builtins.removeAttrs r.selfContent [ "includes" ];
            merged = rmerge (builtins.removeAttrs noProv [ "includes" ]) selfContentBody;
            allIncludes =
              (noProv.includes or [ ])
              ++ (if r.selfContent == null then [ ] else r.selfContent.includes or [ ])
              ++ r.seedStubs;
          in
          merged // { includes = allIncludes; }
        else
          a
      ) aspects;
    in
    augmented // allSynths;
in
{
  _denCompat.legacy = "provides";
  inherit desugar;
}
