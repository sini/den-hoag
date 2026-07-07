# compat-surface (C1) — SURFACE TOTALITY + the witness map. Two obligations:
#
#   (1) COVERAGE — every den v1 §2.2 surface row has a witness fixture (`parity/fixtures/witness-map.nix`
#       maps row → fixture id), and every witness the shim claims to compile DOES compile — no shim
#       rejection of a construct den v1 accepts (a rejection is a C1 failure regardless of parity). The
#       ONE deliberately-unbuilt surface (`den.batteries.forward` / `meta.__forward`, corpus-zero census)
#       is witnessed as a NAMED ABORT, never a silent absorption.
#
#   (2) TOTALITY — the promised downstream enforcement of the freeform-absorption trade-off: the permissive
#       v1 eval (flake-module.nix `v1OptionsModule` freeformType) absorbs an unknown/typo'd `den.*` key
#       SILENTLY so an arbitrary corpus module evaluates; `compile` then rejects it named
#       (`errors.unknownSurfaceKey`), over the read-back config. A typo is caught HERE, never dropped.
#
# The witness fixtures are the C7/C8 parity harness's input (each is a real v1 declaration set). This
# suite exercises the v2 (compat) arm's ACCEPTANCE; the two-arm content/graph diff is Tasks 7–8.
{ denCompat, denHoagSrc, ... }:
let
  # The witness map, threaded `denCompat` so the deliver/route/provide witnesses call the real surface
  # functions (read through the store path, the same route compile-golden reads pipe-stages).
  wm = import "${denHoagSrc}/parity/fixtures/witness-map.nix" { inherit denCompat; };
  inherit (wm) fixtures rows mandatory;

  # ── acceptance: force the compile SPINE (ingestion + aspect/class/channel translation + the totality
  #    seq) WITHOUT forcing a parametric body — attrNames only, so a poisoned class body stays a thunk.
  proj = c: {
    kinds = builtins.attrNames c.entities.schema;
    regIds = builtins.mapAttrs (_: r: builtins.mapAttrs (_: e: e.id_hash) r) c.entities.registries;
    members = builtins.length c.entities.membership;
    # per-aspect attrNames forces each `translateAspect` (its provides / meta.__forward sentinels).
    aspectKeys = builtins.mapAttrs (n: _: builtins.attrNames c.aspects.${n}) c.aspects;
    policyNames = builtins.attrNames c.policies;
    # per-class attrNames forces each `translateClass` (its forwardTo sentinel).
    classKeys = builtins.mapAttrs (n: _: builtins.attrNames c.classes.${n}) c.classes;
    channelKeys = builtins.mapAttrs (n: _: builtins.attrNames c.channels.${n}) c.channels;
  };
  # runBodies fixtures: run each compiled policy body at a probe ctx and force each declaration's spine
  # (the effect → declaration half). Only fixtures with ctx-agnostic (`_ctx:`) bodies are flagged.
  runB = c: builtins.mapAttrs (_: p: map builtins.attrNames (p { })) c.policies;
  accept =
    fx:
    let
      c = denCompat.compileFull fx.decls;
      spine = builtins.deepSeq (proj c) true;
    in
    if fx.runBodies or false then builtins.deepSeq (runB c) spine else spine;

  isNI = fx: fx ? notImplemented;
  allIds = builtins.attrNames fixtures;
  normalIds = builtins.filter (id: !(isNI fixtures.${id})) allIds;
  niIds = builtins.filter (id: isNI fixtures.${id}) allIds;

  # ── coverage: the canonical §2.2 rows (transcribed from the spec's v1-construct column, the
  #    authoritative list — NOT read back from the map, which would tautologise the check).
  canonicalRows = [
    "den.hosts"
    "den.homes"
    "den.schema"
    "den.aspects"
    "den.policies"
    "policy.resolve"
    "policy.include|exclude"
    "deliver"
    "policy.route|provide"
    "policy.instantiate"
    "policy.spawn"
    "policy.for|when"
    "pipe.from"
    "den.quirks"
    "den.classes"
    "den.default"
    "aspect.provides"
    "batteries.forward|forwardTo"
  ];
  referencedIds = builtins.concatLists (builtins.attrValues rows ++ builtins.attrValues mandatory);

  # ── totality probes ─────────────────────────────────────────────────────────────────────────────────
  aborts = e: !(builtins.tryEval (builtins.deepSeq e true)).success;
  # a bogus top-level key, direct-compiled.
  totalityDirect = aborts (builtins.attrNames (denCompat.compile { bogusSurfaceKey = 1; }));
  # a TYPO of a real key (`apsects`), direct-compiled — the self-review's "catches a typo'd/unknown key".
  totalityTypo = aborts (builtins.attrNames (denCompat.compile { apsects.a = { }; }));
  # the FULL freeform-absorption closure: the v1 eval ABSORBS the typo (freeformType), compile CATCHES it
  # over the read-back config. This is the trade-off's promised downstream enforcement, end to end.
  totalityAbsorbed = aborts (
    builtins.attrNames (denCompat.compile (denCompat.evalV1 [ { config.den.apsects.a = { }; } ]))
  );
  # a KNOWN key does NOT abort (the check is surgical, not a blanket reject).
  knownKeyOk =
    (builtins.tryEval (builtins.attrNames (denCompat.compile { aspects.a = { }; }))).success;

  # ── mandatory-witness discriminators (the semantics that make each witness the RIGHT one) ─────────────
  whenHasAspectC = denCompat.compileFull fixtures.policyWhenHasAspect.decls;
  whenPlainC = denCompat.compileFull fixtures.policyWhenPlain.decls;
  defaultC = denCompat.compileFull fixtures.denDefault.decls;
  schemaC = denCompat.compileFull fixtures.schemaCustomKind.decls;
  homesC = denCompat.compileFull fixtures.homesMultiSystem.decls;

  mkAccept = id: {
    name = "test-accept-${id}";
    value = {
      expr = (builtins.tryEval (accept fixtures.${id})).success;
      expected = true;
    };
  };
  mkAbort = id: {
    name = "test-notimpl-aborts-${id}";
    value = {
      expr = (builtins.tryEval (accept fixtures.${id})).success;
      expected = false;
    };
  };
in
{
  flake.tests.compat-surface =
    # every compiling witness ACCEPTS (no shim rejection); every not-implemented witness ABORTS named.
    builtins.listToAttrs (map mkAccept normalIds)
    // builtins.listToAttrs (map mkAbort niIds)
    // {
      # ── coverage ──────────────────────────────────────────────────────────────────────────────────
      # every §2.2 row has a witness in the map (the C1 completeness obligation).
      test-rows-cover-canonical = {
        expr = builtins.all (r: rows ? ${r}) canonicalRows;
        expected = true;
      };
      # the §2.2 table has exactly 18 rows — a drift tripwire (a new row without a witness fails here).
      test-canonical-row-count = {
        expr = builtins.length canonicalRows;
        expected = 18;
      };
      # every id the map references (rows ∪ mandatory) is a real fixture — no dangling witness ref.
      test-referenced-ids-exist = {
        expr = builtins.all (id: fixtures ? ${id}) referencedIds;
        expected = true;
      };
      # every fixture is referenced by some row/mandatory entry — no dead (unmapped) witness.
      test-no-dead-fixtures = {
        expr = builtins.all (id: builtins.elem id referencedIds) allIds;
        expected = true;
      };
      # every mandatory dedicated witness (task C1) resolves to an existing fixture.
      test-mandatory-witnesses-exist = {
        expr = builtins.all (ids: builtins.all (id: fixtures ? ${id}) ids) (builtins.attrValues mandatory);
        expected = true;
      };

      # ── totality (the freeform-absorption trade-off enforcement) ────────────────────────────────────
      test-totality-unknown-key-aborts = {
        expr = totalityDirect;
        expected = true;
      };
      test-totality-typo-aborts = {
        expr = totalityTypo;
        expected = true;
      };
      test-totality-absorbed-typo-aborts = {
        expr = totalityAbsorbed;
        expected = true;
      };
      test-totality-known-key-ok = {
        expr = knownKeyOk;
        expected = true;
      };

      # ── mandatory-witness semantics ────────────────────────────────────────────────────────────────
      # policy.when over hasAspect lifts to a CONDITIONAL ASPECT (the neededBy+guard fixpoint), not policy.
      test-when-hasAspect-lifts-to-aspect = {
        expr = (whenHasAspectC.aspects ? whenHasA) && !(whenHasAspectC.policies ? whenHasA);
        expected = true;
      };
      # a plain (non-hasAspect) predicate when stays a POLICY (a plain rule-guard), never an aspect.
      test-when-plain-stays-policy = {
        expr = (whenPlainC.policies ? guardByHost) && !(whenPlainC.aspects ? guardByHost);
        expected = true;
      };
      # den.default → the reserved `__default` aspect + a fleet-wide `__denDefault` radiation policy.
      test-default-registers-aspect-and-policy = {
        expr = (defaultC.aspects ? __default) && (defaultC.policies ? __denDefault);
        expected = true;
      };
      # den.default's `homeManager` class key grounds to `home-manager` (the v1ClassKeyMap).
      test-default-grounds-home-manager = {
        expr = builtins.elem "home-manager" (builtins.attrNames defaultC.aspects.__default);
        expected = true;
      };
      # custom kinds: the containment DAG (env under host, cluster under env) atop the built-ins.
      test-schema-custom-kind-topology = {
        expr = {
          env = schemaC.entities.schema.env.parent;
          cluster = schemaC.entities.schema.cluster.parent;
        };
        expected = {
          env = "host";
          cluster = "env";
        };
      };
      # the kind-attached include (cluster.includes) lifts to a fire-at-kind policy (__kindInclude__cluster).
      test-schema-kind-include-policy = {
        expr = schemaC.policies ? __kindInclude__cluster;
        expected = true;
      };
      # multi-system @system homes: two membership cells (one per host/system), ONE user registry entry.
      test-homes-multisystem-cells = {
        expr = {
          cells = builtins.length homesC.entities.membership;
          users = builtins.attrNames homesC.entities.registries.user;
        };
        expected = {
          cells = 2;
          users = [ "alice" ];
        };
      };

      # ── not-implemented-by-census metadata (the honest witness that a row is unbuilt, not absorbed) ──
      test-batteries-forward-census = {
        expr =
          (fixtures.batteriesForward.notImplemented ? census)
          && (fixtures.batteriesForward.notImplemented ? pointer);
        expected = true;
      };
    };
}
