# compat/core BOUNDARY tripwire (Task 8 M1 item v) — the PERMANENT STRUCTURAL encoding of the
# "coupling we had before" lesson: den-hoag core must not KNOW about the den-compat shim. Three
# mechanical guards over the source text (the zero-machinery.nix `readFile` token-scan precedent —
# a tripwire, not a proof; its value is bluntness):
#
#   1. TOKEN SCAN     — no CORE file (lib/ outside lib/compat/) contains compat/legacy MACHINERY
#                       vocabulary. The shim depends on core; core is shim-blind.
#   2. IMPORT DIRECTION — no core file imports from lib/compat/. Dependencies point ONE way (compat → core).
#   3. SEAM ENUMERATION — the shim consumes ONLY the checked-in set of core `denHoag.*` surfaces; a NEW
#                       one fails here, so the seam is reviewed whenever it grows.
#
# EXCLUSIONS: `ci/tests/**` and `parity/**` may say anything (they TEST the shim); `lib/compat/**` is the
# shim itself. Only the core file list below is scanned.
{
  genPrelude,
  denHoagSrc,
  nixpkgsLib,
  denCompat,
  ...
}:
let
  inherit (nixpkgsLib) hasSuffix;
  inherit (genPrelude) hasInfix;

  # ── the CORE file set — lib/ MINUS lib/compat/ (explicit + checked-in, like zero-machinery.nix: adding
  #    a core file forces a visible edit here, which is the point). KEEP IN SYNC with `find lib -name
  #    '*.nix' -not -path 'lib/compat/*'`; a `test-core-file-list-complete` guard below catches drift. ──
  coreFiles = [
    "default.nix"
    "errors.nix"
    "entity.nix"
    "fleet.nix"
    "build-roots.nix"
    "scope-adapter.nix"
    "staged-resolution.nix"
    "declarations.nix"
    "concern-policies.nix"
    "concern-aspects.nix"
    "key-semantics.nix"
    "module-shape.nix"
    "concern-quirks.nix"
    "concern-classes.nix"
    "concern-collectors.nix"
    "concern-relations.nix"
    "concern-derived.nix"
    "concern-productions.nix"
    "stratum-scope.nix"
    "production-guard.nix"
    "concern-disciplines.nix"
    "linearization.nix"
    "settings.nix"
    "projects.nix"
    "demand.nix"
    "identity.nix"
    "edges.nix"
    "products.nix"
    "resolution-products.nix"
    "renders.nix"
    "receivers.nix"
    "query.nix"
    "outputs.nix"
    "nest.nix"
    "graph-escape.nix"
    "attributes/default.nix"
    "attributes/structural.nix"
    "attributes/resolved-aspects.nix"
    "attributes/collections.nix"
    "attributes/resolved-settings.nix"
    "attributes/class-modules.nix"
    "attributes/output-modules.nix"
    "attributes/resolution-relations.nix"
    "attributes/claim-accessor.nix"
    "output/terminal.nix"
    "output/class-share.nix"
    "output/flake-adapter.nix"
  ];
  readCore = f: builtins.readFile "${denHoagSrc}/lib/${f}";

  # ── (1) forbidden compat/legacy MACHINERY tokens — each is UNAMBIGUOUS shim vocabulary (a comment or a
  #    code reference to one is core knowing about the shim). Tuned to actual vocabulary; the EXCLUSIONS
  #    note below records the words deliberately NOT forbidden and why (they are core vocabulary, not shim
  #    coupling — renaming them would erase real meaning, the opposite of the guard's intent). ───────────
  forbiddenTokens = [
    "compat" # the shim's name (`den-compat`/`denCompat`) + its dir path (`compat/`) — the import guard too
    "legacy" # the legacy-surface machinery (provides/forwards/self-provide) + the "legacy-edge" seam framing
    "denCompat" # the shim's public handle (redundant with `compat`, explicit for legibility)
    "selfProvide" # R5 self-named-aspect machinery
    "self-provide" # (kebab spelling)
    "os-to-host" # the os-class battery route (R3)
    "user-to-host" # the os-user battery route (R6)
    "forwardTo" # the legacy forward class surface
    "compileFull" # a shim compile entry (post-legacy-desugar)
    "mkFleetModule" # the shim's compile→config.den bridge
    "desugarLegacy" # the shim's legacy-desugar composition
    "compileCanTake" # the shim's formal-preserving route compile path
    "__denCanTake" # the shim's canTake-route marker
  ];
  # EXCLUSIONS (core VOCABULARY, deliberately not forbidden):
  #   `v1`                    — den-hoag IS den v2; comparative design-provenance comments (e.g. "§B4a
  #                             replaces v1's provides.to-users") are ARCHITECTURE documentation, not shim
  #                             coupling. Forbidding it would delete provenance citations.
  #   `synthesize` / `rewalk` — gen-edge SOURCE ARMS (core edge vocabulary); the output fold names them as
  #                             the source kinds its `interpret` seam can carry.
  #   `interpret`             — the `den.interpret` raw OPTION is a core SEAM surface (see the seam list
  #                             below), not shim vocabulary.
  #   bare `provides`/`forwards` — English verbs ("a policy body forwards its ctx", "Task 2 provides the
  #                             builder"); the SHIM surfaces are caught by `forwardTo` + `self-provide`.
  #   `compatibleWith`/`compatible`/`compatibility` — the §4.3 render `compatibleWith` field + its prose;
  #                             a real product-face predicate, not the shim. It happens to contain the
  #                             `compat` substring, so the word-family is stripped before the scan (bare
  #                             `compat`, `compat/`, `denCompat` stay caught — `compatible` has no `/` or
  #                             `den` neighbor that the shim vocabulary needs).
  compatibleFamily = [
    "compatibleWith"
    "compatibility"
    "compatible"
  ];
  stripCompatible = t: builtins.replaceStrings compatibleFamily (map (_: "") compatibleFamily) t;
  tokenOffenders = builtins.concatMap (
    f:
    let
      t = stripCompatible (readCore f);
    in
    map (tok: "${f}:${tok}") (builtins.filter (tok: hasInfix tok t) forbiddenTokens)
  ) coreFiles;

  # ── (2) IMPORT DIRECTION — a core file importing from lib/compat/ reverses the dependency. `compat`
  #    (token 1) already catches the path fragment `compat/`; this asserts the specific import expressions
  #    separately for a legible, standalone failure. ─────────────────────────────────────────────────────
  importOffenders = builtins.filter (
    f:
    let
      t = readCore f;
    in
    hasInfix "import ./compat" t || hasInfix "import ../compat" t || hasInfix "/compat/" t
  ) coreFiles;

  # ── (3) SEAM ENUMERATION — the ONLY core `denHoag.*` surfaces the shim may consume. A comment-anchored
  #    constant + a scan of lib/compat/** that asserts its `denHoag.<top>` references are a subset. A NEW
  #    core surface reached from the shim fails here, forcing this list (and a boundary review) to grow. ──
  #
  #   API surfaces (denHoag.<x>):
  #     mkDen     — the four-concern driver (the shim's whole output target).
  #     classes   — the class-tag entry registry (identity-law class entries).
  #     declare   — the declaration-constructor vocabulary (edge/drop/spawn/member/delivery).
  #     sel       — the selector vocabulary (neededBy / nameMatches predicates).
  #     internal  — the non-public builders; the shim reaches ONLY `internal.terminal.collect` (the
  #                 nixpkgs-free terminal for its systemFor-injecting instantiate wrapper).
  #   CONFIG surfaces the shim SETS on mkDen input (`config.den.*`, via the module system — NOT denHoag.<x>
  #   calls, so not scanned): aspects, policies, classes, quirks, include, membership, contentClass,
  #   schema, <kind> instances, nixpkgs, interpret (the M1 declared-classes + interpret seams ride here).
  #   INJECTED deps (flake-wired, not denHoag.<x>): prelude, schema (gen-schema), edge/edgeCore (gen-edge).
  seamApiSurfaces = [
    "mkDen"
    "classes"
    "declare"
    "sel"
    "internal"
  ];
  seamInternalSurfaces = [ "terminal" ];

  # Scan the shim source for `denHoag.<ident>` and `inherit (denHoag) <idents>` references.
  compatDir = "${denHoagSrc}/lib/compat";
  isNix = n: nixpkgsLib.hasSuffix ".nix" n;
  # every .nix under lib/compat (top + legacy + legacy/batteries + parity), recursively.
  filesUnder =
    rel:
    let
      entries = builtins.readDir "${compatDir}/${rel}";
      names = builtins.attrNames entries;
    in
    builtins.concatMap (
      n:
      if entries.${n} == "directory" then
        filesUnder "${rel}${n}/"
      else if isNix n then
        [ "${rel}${n}" ]
      else
        [ ]
    ) names;
  compatFiles = filesUnder "";
  readCompat = f: builtins.readFile "${compatDir}/${f}";

  # Extract the capture groups of a pattern over a text (builtins.split: matches are the capture lists).
  capturesOf =
    pat: t: builtins.concatMap (m: if builtins.isList m then m else [ ]) (builtins.split pat t);
  refsIn =
    t:
    capturesOf "denHoag\\.(internal\\.)?([a-zA-Z_][a-zA-Z0-9_]*)" t
    ++ builtins.concatMap (grp: nixpkgsLib.splitString " " grp) (
      # `inherit (denHoag) a b c;` — capture the space-separated ident run before `;`.
      capturesOf "inherit \\(denHoag\\) ([a-zA-Z0-9_ ]+)" t
    );
  # top-level denHoag surfaces referenced anywhere in the shim (drop the `internal.` group + noise).
  allRefs = builtins.concatMap (f: refsIn (readCompat f)) compatFiles;
  topRefs = builtins.filter (
    # drop nulls (unmatched optional group), the `internal.` prefix capture, and the internal sub-surfaces
    # (asserted separately) — leaving the top-level `denHoag.<x>` API surfaces the shim references.
    r:
    r != null
    && r != ""
    && r != "internal"
    && r != "internal."
    && !(builtins.elem r seamInternalSurfaces)
  ) allRefs;
  seamViolations = nixpkgsLib.unique (
    builtins.filter (r: !(builtins.elem r seamApiSurfaces)) topRefs
  );

  # actual core-file-list drift guard: the on-disk core set == the checked-in list.
  actualCore =
    let
      walk =
        rel:
        let
          e = builtins.readDir "${denHoagSrc}/lib/${rel}";
        in
        builtins.concatMap (
          n:
          if e.${n} == "directory" then
            (if n == "compat" then [ ] else walk "${rel}${n}/")
          else if isNix n then
            [ "${rel}${n}" ]
          else
            [ ]
        ) (builtins.attrNames e);
    in
    walk "";

  # ── (4) LEGACY SIBLING ISOLATION — each legacy surface (lib/compat/legacy/*) is a PURE ISOLATED battery
  #    over the shared primitive; no legacy module imports another legacy MODULE (that would recouple the
  #    surfaces the severability law severs independently). SOLE exception: legacy/defaults.nix is the
  #    COMPOSITION ROOT — it may import legacy/batteries/*. Every other legacy file imports ONLY the shared
  #    `deliver.nix` primitive (forwards → ../deliver.nix; os-class/os-user → ../../deliver.nix). ─────────
  legacyFiles = builtins.filter (f: nixpkgsLib.hasPrefix "legacy/" f) compatFiles;
  importPathsOf = f: capturesOf "import +(\\.\\.?/[a-zA-Z0-9_./-]+\\.nix)" (readCompat f);
  # an import is ALLOWED iff it is the shared `deliver.nix` primitive, OR it is a `batteries/*` import from
  # the composition root. ANYTHING else a legacy file imports is a sibling recoupling (forces a review).
  legacyImportAllowed =
    f: p: hasSuffix "/deliver.nix" p || (f == "legacy/defaults.nix" && hasInfix "batteries/" p);
  siblingOffenders = builtins.concatMap (
    f:
    map (p: "${f}:${p}") (
      builtins.filter (p: p != null && !(legacyImportAllowed f p)) (importPathsOf f)
    )
  ) legacyFiles;

  # ── (5) SHARED-PRIMITIVE EXPRESSION — every legacy desugar emits records in the SHARED deliver/edge
  #    vocabulary ONLY: a `deliver`/`route` descriptor via the public deliver surface (`__delivery`), or a
  #    `synthesize` SOURCE RECORD per the frozen edge schema. No bespoke record shapes — a NEW legacy record
  #    kind is a deliberate SCHEMA-VERSION event, not a drive-by. ALGEBRA (the invariant's rationale): a
  #    forward is `select(S) → transform(M) → project(T, P)` over the shared edge primitive; `os-to-host` is
  #    the built-in forward INSTANCE with `T = fn(ctx) → host.class`. So the batteries are forward instances,
  #    not new machinery — their route bodies emit the SAME `__delivery` descriptor the deliver surface does.
  sharedRecordKinds = [
    "__delivery" # a deliver/route descriptor (the public deliver surface)
    "synthesize" # a gen-edge synthesize source record (the frozen edge schema)
  ];
  recordKind =
    r:
    if !(builtins.isAttrs r) then
      "non-record"
    else if r ? __delivery then
      "__delivery"
    else if r ? synthesize then
      "synthesize"
    else
      "bespoke:${builtins.concatStringsSep "," (builtins.attrNames r)}";
  fwd = denCompat.legacy.forwards;
  bat = denCompat.legacy.defaults.batteries;
  # the record each legacy desugar emits (probed at a representative input):
  emittedRecordKinds = [
    # forwards: tier-1 (static) → a deliver descriptor; complex (adapter-bearing) → a synthesize record.
    (recordKind (
      fwd.forward {
        fromClass = "a";
        intoClass = "b";
      }
    ))
    (recordKind (
      fwd.forward {
        fromClass = "a";
        intoClass = "b";
        adaptArgs = _: { };
      }
    ))
    # os-class / os-user built-in forward instances: their exported route body emits a deliver descriptor.
    (recordKind (
      builtins.head (
        bat.os-class.routeInclude.fn {
          host = {
            name = "h";
            class = "nixos";
          };
        }
      )
    ))
    (recordKind (
      builtins.head (
        bat.os-user.routeInclude.fn {
          user = {
            name = "u";
          };
          host = {
            name = "h";
            class = "nixos";
          };
        }
      )
    ))
  ];
  bespokeRecordKinds = builtins.filter (k: !(builtins.elem k sharedRecordKinds)) emittedRecordKinds;
in
{
  flake.tests.boundary = {
    # (1) no compat/legacy MACHINERY token in any core file.
    test-no-compat-tokens-in-core = {
      expr = tokenOffenders;
      expected = [ ];
    };

    # (2) no core file imports from lib/compat/ (the dependency points compat → core, never the reverse).
    test-no-core-imports-compat = {
      expr = importOffenders;
      expected = [ ];
    };

    # (3) the shim consumes ONLY the enumerated core API surfaces — a new one fails here (seam review).
    test-shim-consumes-only-seam = {
      expr = seamViolations;
      expected = [ ];
    };
    # the internal-surface sub-seam is exactly `terminal` (the collect terminal) — a new `internal.<x>`
    # reached from the shim widens the private-surface coupling and must be reviewed.
    test-shim-internal-seam = {
      expr = nixpkgsLib.unique (
        builtins.concatMap (
          f: capturesOf "denHoag\\.internal\\.([a-zA-Z_][a-zA-Z0-9_]*)" (readCompat f)
        ) compatFiles
      );
      expected = [ "terminal" ];
    };

    # the checked-in core file list has not drifted from the on-disk core set (adding a core file must
    # add it here, so it is actually scanned by guards 1–2).
    test-core-file-list-complete = {
      expr = builtins.sort (a: b: a < b) coreFiles == builtins.sort (a: b: a < b) actualCore;
      expected = true;
    };

    # (4) legacy SIBLING ISOLATION — no legacy module imports a legacy sibling; only the shared deliver
    # primitive (+ defaults → batteries, the composition root). A recoupling import fails here.
    test-legacy-sibling-isolation = {
      expr = siblingOffenders;
      expected = [ ];
    };

    # (5) SHARED-PRIMITIVE EXPRESSION — every legacy desugar emits records in the shared deliver/edge
    # vocabulary only (`__delivery` descriptor | `synthesize` source record). A bespoke record kind fails
    # here (a deliberate schema-version event, never a drive-by).
    test-legacy-shared-record-vocabulary = {
      expr = bespokeRecordKinds;
      expected = [ ];
    };
    # the concrete emitted kinds pin the algebra: forward tier-1 = deliver, complex = synthesize, and the
    # os/user built-in forward instances = deliver (T = fn(ctx) → host.class).
    test-legacy-emitted-record-kinds = {
      expr = emittedRecordKinds;
      expected = [
        "__delivery"
        "synthesize"
        "__delivery"
        "__delivery"
      ];
    };
  };
}
