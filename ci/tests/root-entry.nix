# The repo-root ENTRY guard. den-hoag has TWO roots — the flake (whose `compat` output every other suite
# drives) and the standalone `default.nix`, whose `.compat` rides on the returned lib for a non-flake
# consumer. Only the flake root was ever exercised, so anything the standalone root wired differently was
# invisible. This file is the one suite that drives the standalone root, and its remit is correspondingly
# "both roots present the same surface AND the same capabilities, and each dep's entry is viable on both".
# Three kinds of work live here:
#
#   1. THE SPINE GUARD. A dep the standalone root failed to forward threw "called without required
#      argument" while the suites stayed green; both roots now go through ONE construction of the shim
#      (lib/compat/wiring.nix) over ONE construction of the substrate (substrate.nix).
#   2. THE CAPABILITY ARMS. A name-set guard is structurally incapable of catching a capability
#      divergence: `merge` changes the BODY of gen-class's `applyCoreFixed`, never its export set, so both
#      wirings expose the identical ten names at every revision. The arms drive the three verbs whose
#      capability den-hoag decides — gen-class's tier-2 path, gen-settings' fold, gen-flake's flake-parts
#      crossing — through the standalone root, behaviorally.
#   3. THE SUBSTRATE CENSUS. The structural half of the same sentence: substrate.nix's own declared tables
#      held against the nineteen published trees. A declaration nothing checks is a silence on a delay —
#      drop `merge` from the gen-class adjustment and the interface, domain and viability checks all stay
#      green while the capability is gone on BOTH roots; only the declared-vs-applied check goes red. The
#      census is the reason that edit cannot be made quietly.
#
# FORCING DEPTH, in the three parts that compose it.
#   · The SPINE READ keeps its original contract exactly: it reads the compat attrset spine (`attrNames` /
#     `?`) and nothing beneath it, forcing NO substrate dep. A required formal is checked when the shim
#     function is APPLIED, and the spine cannot be read without applying it.
#   · The THREE ARMS force only their own divergence's depth: gen-class forces { gen-class, gen-merge,
#     gen-prelude }, gen-settings forces { gen-settings, gen-prelude, gen-algebra }, gen-flake forces
#     gen-flake plus the host value the arm is handed. Bodies are forced only inside the verb under test —
#     no fleet, no terminal, no resolution pipeline.
#   · The CENSUS imports all nineteen root entries and forces `functionArgs` on the sixteen the
#     declaration marks `form = "fn"`, plus one `pathExists` and one lock `readFile`/`fromJSON` on the
#     fourteen that reach the viability check's lock branch. Nineteen trees realised, NO body forced,
#     nothing fetched that the CI eval does not already carry.
# So the file is a zero-force name guard PLUS a bounded-force capability witness PLUS a structural census.
# The original zero-force contract was correct for the defect it was closing — a missing formal is checked
# at application, so the spine was the whole depth needed — and it is superseded here rather than
# forgotten: this defect is invisible at that depth for a structural reason, so the file pays a bounded
# forcing cost or the defect stays unwitnessed.
#
# NON-VACUITY. The arms carry same-run positive controls on the same values (a merge-free tier-1 verb, the
# ungated `mkSystemTerminal`, the root's own `mkDen`), so a future regression flips an assertion to red
# while its control stays green — which distinguishes "the wiring broke" from "the probe broke". The two
# catchable arms assert through `tryEval`; the gen-settings arm's failure is an uncatchable abort, and it
# needs no special handling: nix-unit isolates an uncatchable abort as ONE ☢️ row with its error text and
# source location, and runs the rest of the suite. (An earlier version of this header claimed such an
# abort takes the whole suite eval down. It does not, and the constraint that belief recorded is not real.)
# What an arm does NOT certify is the identity of the throw that reddened it: a `tryEval` boolean records
# that something threw, not which thing. Asserting on a third-party library's error text would couple this
# suite to that library's prose, so the boundary is accepted, not closed.
{
  denCompat,
  denHoagSrc,
  flakeParts,
  ...
}:
let
  # ── THE STANDALONE ROOT ──────────────────────────────────────────────────────────────────────────
  # Wired from its OWN defaults — verbatim the non-flake consumer path `(import <den-hoag> { }).compat`,
  # every material resolving through the entry's own flake.lock.
  standalone = import "${denHoagSrc}/default.nix" { };
  # The same root, handed the one host material the flake-parts crossing needs. A host material is a
  # ROOT's to supply on either root — the standalone root has no flake-parts flake of its own and says so
  # in a named throw — so the arm supplies it and tests what the substrate does with it.
  standaloneWithHost = import "${denHoagSrc}/default.nix" { inherit flakeParts; };

  # ── THE SUBSTRATE UNDER CENSUS ───────────────────────────────────────────────────────────────────
  # The census's subject is substrate.nix's tables held against the trees a root pairs with them, so it
  # is applied to the standalone root's own materials, through the same lock and the same fetch that
  # root's defaults use. A mis-paired material here is not invisible: it is a red interface row on the
  # dep that moved.
  #
  # BOTH host materials are throwing sentinels, which turns "the census forces no host material" from an
  # assurance into a measurement: the census reads `attrNames` of each adjustment and never its values,
  # so a root that legitimately omitted a host material is not punished by a census run. The gen-flake
  # ARM does not ride this substrate — it goes through the real root above, which is where the material
  # is genuinely supplied.
  lock = builtins.fromJSON (builtins.readFile "${denHoagSrc}/flake.lock");
  fetch = name: builtins.fetchTree lock.nodes.${lock.nodes.root.inputs.${name}}.locked;
  s = import "${denHoagSrc}/substrate.nix" {
    genPreludeSrc = fetch "gen-prelude";
    genAlgebraSrc = fetch "gen-algebra";
    genTypesSrc = fetch "gen-types";
    genMergeSrc = fetch "gen-merge";
    genSchemaSrc = fetch "gen-schema";
    genAspectsSrc = fetch "gen-aspects";
    genGraphSrc = fetch "gen-graph";
    genScopeSrc = fetch "gen-scope";
    genResolveSrc = fetch "gen-resolve";
    genSelectSrc = fetch "gen-select";
    genBindSrc = fetch "gen-bind";
    genDispatchSrc = fetch "gen-dispatch";
    genClassSrc = fetch "gen-class";
    genEdgeSrc = fetch "gen-edge";
    genProductSrc = fetch "gen-product";
    genSettingsSrc = fetch "gen-settings";
    genDemandSrc = fetch "gen-demand";
    genPipeSrc = fetch "gen-pipe";
    genFlakeSrc = fetch "gen-flake";
    nixpkgs = throw "root-entry census: the `nixpkgs` host material was FORCED. The census reads attribute NAMES only and must never force a host material.";
    flakeParts = throw "root-entry census: the `flakeParts` host material was FORCED. The census reads attribute NAMES only and must never force a host material.";
  };

  # ── THE CENSUS ───────────────────────────────────────────────────────────────────────────────────
  # The domain is literally `attrNames srcOf` — the pairing table through which every dep tree enters the
  # construction. It is not a list kept in step with the kernel; it is the same table the kernel indexes,
  # so a dep absent from it cannot be in the kernel at all. Every table is read through substrate.nix's
  # own named lookup, so a missing name reports in den-hoag's voice naming the dep and the table, rather
  # than as `attribute '<name>' missing`.
  deps = builtins.attrNames s.srcOf;
  treeOf = name: import (s.srcFor name);
  entryOf = name: s.interfaceFor name;
  fnDeps = builtins.filter (name: (entryOf name).form == "fn") deps;
  formalsOf = name: builtins.functionArgs (treeOf name);
  render = builtins.concatStringsSep " ";
  sortNames = builtins.sort (a: b: a < b);
  # each check reports the deps that FAILED it, so a red row prints which dep and which check
  failing = pred: builtins.filter (name: !(pred name)) fnDeps;

  # The two DOMAIN checks, both two-sided. A name in `srcOf` missing from a table is a dep with no
  # disposition; a name in a table missing from `srcOf` is a disposition that reaches no dep. They fail
  # differently and both matter, so the comparison is equality rather than containment.
  d0Interface =
    let
      declared = builtins.attrNames s.interface;
    in
    if declared == deps then
      [ ]
    else
      throw "den-hoag substrate census: `interface` and `srcOf` declare different dep sets (${render declared} vs ${render deps}). Every name in one is a name in the other (spec §2.11).";
  d0Adjustments =
    let
      declared = builtins.attrNames s.adjustments;
    in
    if declared == fnDeps then
      [ ]
    else
      throw "den-hoag substrate census: `adjustments` and the interface's `form = \"fn\"` rows declare different dep sets (${render declared} vs ${render fnDeps}) (spec §2.11).";

  # FORM — the two-directional assertion that the tree's function-ness agrees with the declaration. This
  # is what makes the three bare deps first-class subjects rather than names the census steps around, and
  # it is an assertion against a written declaration, not a dispatch on a value's shape: the `form` field
  # decides which rule applies and `isFunction` only says whether reality agrees. It fires named in either
  # direction, and it dispatches the four checks below onto the `fn` rows — so a row declared `fn` over a
  # bare tree also hands the interface check a non-function, which aborts uncatchably beside the named
  # report. Both land; nix-unit isolates the raw one as its own row.
  cForm = builtins.foldl' (
    acc: name:
    let
      declaredFn = (entryOf name).form == "fn";
    in
    if builtins.isFunction (treeOf name) == declaredFn then
      acc
    else if declaredFn then
      throw "den-hoag substrate census: `${name}` is declared `form = \"fn\"` in substrate.nix's interface, but its tree imports to a non-function. Fix the declaration or the pairing in `srcOf` (spec §2.6, §2.11)."
    else
      throw "den-hoag substrate census: `${name}` is declared `form = \"bare\"` in substrate.nix's interface, but its tree imports to a function. Fix the declaration or the pairing in `srcOf` (spec §2.6, §2.11)."
  ) [ ] deps;

  # INTERFACE — `functionArgs` itself, not its `attrNames`: the boolean is has-a-default, and a formal
  # that LOSES its default is a dep den-hoag can no longer leave to self-wire, which a name-only
  # comparison cannot see. What it cannot see is a default whose VALUE changes while staying a default;
  # for every formal den-hoag supplies that is unreachable (the default is never evaluated), and the
  # formals den-hoag leaves alone are dep revisions governed by the lock.
  cInterface = failing (name: formalsOf name == (entryOf name).formals);

  # ADJUSTMENT ⊆ DECLARED FORMALS. This is what closes the ellipsis hole: five of the sixteen root
  # entries take `...`, so on those a misspelled adjustment formal is absorbed silently and the dep
  # self-wires what den-hoag meant to supply. Pure attrset arithmetic, so unlike an application probe it
  # never has to catch an uncatchable abort.
  cAdjustmentDeclared = failing (
    name:
    builtins.all (f: builtins.elem f (builtins.attrNames (formalsOf name))) (
      builtins.attrNames (s.adjustmentFor name)
    )
  );

  # VIABILITY — can every formal den-hoag does NOT supply wire itself from the dep's published tree? The
  # unsupplied surface being empty settles it at the interface, at every depth: a supplied formal's
  # default is never evaluated. Otherwise the tree must ship a lock AND that lock must resolve the inputs
  # it declares — the file check alone is not enough, because a lock that exists but does not name an
  # input the entry asks for fails on the ATTRIBUTE, uncatchably, from inside a third-party store path.
  # This is the only check here that would have caught gen-settings, whose formal set is unremarkable and
  # every one of whose exports is a function: no probe that fails to force a fold sees anything wrong.
  unsupplied =
    name:
    let
      supplied = builtins.attrNames (s.adjustmentFor name);
    in
    builtins.filter (f: !(builtins.elem f supplied) && f != "lock" && f != "fetch") (
      builtins.attrNames (formalsOf name)
    );
  # pure JSON structure over the tree's own lock: no body forced, nothing fetched. An input entry is
  # either a node KEY or a root-relative FOLLOWS PATH. The "root names at least one input" clause also
  # refuses a lock that declares nothing BECAUSE the dep genuinely has no inputs — a shape that ships in
  # this dep set (gen-select's lock is one input-less root node), inert only because that dep is a bare
  # value and short-circuits before this branch. The two cases are indistinguishable in the JSON and only
  # one is safe to admit, so the false refusal is the direction this errs in, deliberately.
  lockResolves =
    src:
    let
      l = builtins.fromJSON (builtins.readFile "${src}/flake.lock");
      rootNode = l.nodes.${l.root} or { };
      rootInputs = rootNode.inputs or { };
      keyOf = entry: if builtins.isString entry then entry else walk l.root entry;
      walk =
        key: path:
        if path == [ ] then
          key
        else if !(l.nodes ? ${key}) then
          null
        else
          let
            entry = (l.nodes.${key}.inputs or { }).${builtins.head path} or null;
            next = if entry == null then null else keyOf entry;
          in
          if next == null then null else walk next (builtins.tail path);
      resolves =
        entry:
        let
          k = keyOf entry;
        in
        k != null && (l.nodes ? ${k}) && (l.nodes.${k} ? locked);
    in
    rootInputs != { } && builtins.all resolves (builtins.attrValues rootInputs);
  cViability = failing (
    name:
    unsupplied name == [ ]
    || (builtins.pathExists "${s.srcFor name}/flake.lock" && lockResolves (s.srcFor name))
  );

  # DECLARED-SUPPLIED vs APPLIED — the check that catches this construction's own defect class. The three
  # above ask whether the dep still declares what den-hoag wrote down, whether den-hoag's adjustment stays
  # inside that declaration, and whether an unsupplied formal can self-wire. None of them asks whether the
  # disposition den-hoag DECLARED is actually applied. Drop `merge` from the gen-class adjustment and all
  # three stay green while `applyCoreFixed` throws on both roots; this is the only one that goes red. Its
  # subject is the adjustment applied to the tree the interface check read, because one name selects both
  # tables and a call site passes nothing but that name.
  cSupplied = failing (
    name: builtins.attrNames (s.adjustmentFor name) == sortNames (entryOf name).supplied
  );

  # ── THE THREE CAPABILITY ARMS ────────────────────────────────────────────────────────────────────
  # gen-class: `applyCoreFixed`'s `merge == null` guard is that function's outermost expression, so a
  # well-formed core reaches it directly. The core is built the way lib/output/class-share.nix builds
  # one — mkClasses, then mkCore — so the arm forces the real tier-2 path and not a malformed fixture.
  classLib = s.kernel.class;
  classNodes = {
    a = { };
    b = { };
  };
  classPartition = classLib.mkClasses {
    nodes = classNodes;
    keyOf = _name: _node: "one";
  };
  classCore = classLib.mkCore {
    class = builtins.head classPartition;
    projection = "denHoagRootEntry";
    projections = {
      a.shared = 1;
      b.shared = 1;
    };
  };
  armClassTier2 = builtins.tryEval (
    builtins.deepSeq
      (classLib.applyCoreFixed {
        core = classCore;
        modules = [ ];
      }).config
      "REACHED"
  );
  # the positive control: a merge-free tier-1 verb on the SAME value in the SAME run
  armClassTier1 = builtins.tryEval (builtins.deepSeq (map (c: c.key) classPartition) "REACHED");
  reached = r: if r.success then r.value else "THREW";

  # gen-settings: `resolveAll` on a ONE-ENTRY batch is the shallowest verb that forces the substrate
  # formals. Everything shallower stays green while the defect is live — `deepSeq` over the whole lib
  # value reaches, and so do `mkSchema`, `isRef`, `refsIn` and `resolveAll` on an EMPTY batch, because
  # none of them forces `prelude` or `algebra`. This arm is one-sided by nature: its failure is an
  # uncatchable `path … does not exist`, so it reports as a ☢️ row printing that error rather than as a
  # boolean diff. The viability check catches the same regression structurally, before any verb runs.
  settingsSchema = s.kernel.settings.mkSchema {
    aspect = {
      name = "denHoagRootEntry";
      id_hash = "den-hoag-root-entry-probe";
    };
    fields.enable = {
      default = false;
      merge = "replace";
    };
  };
  armSettings =
    builtins.deepSeq
      (s.kernel.settings.resolveAll {
        batch = [
          {
            schema = settingsSchema;
            layers = [ ];
          }
        ];
      }).value
      "REACHED";

  # gen-flake: `mkFlakeTerminal`'s `flakeParts != null` gate is evaluated before the flake-parts eval
  # proper, and den-hoag already mints the verb as `internal.mkFlakeTerminal`. The `or null` fallback
  # there reads PRESENT on BOTH roots — it guards against a gen-flake REVISION predating the verb and is
  # structurally blind to the capability — so presence is not the assertion; APPLYING it is. `modules` is
  # empty: the arm constructs no den fleet.
  armFlake = builtins.tryEval (
    builtins.deepSeq (builtins.attrNames (
      standaloneWithHost.internal.mkFlakeTerminal {
        self.outPath = denHoagSrc;
        inputs = { };
        modules = [ ];
        systems = [ ];
      }
    )) "REACHED"
  );
  # controls: the UNGATED terminal constructor is readable off a substrate whose host materials are
  # throwing sentinels (threading a capability is free until a gated verb is applied), and the arm's own
  # root assembles.
  armFlakeUngated = builtins.tryEval (builtins.isFunction s.kernel.flake.terminals.mkSystemTerminal);
  armFlakeRoot = builtins.tryEval (builtins.isFunction standaloneWithHost.mkDen);
in
{
  flake.tests.root-entry = {
    # ── the spine guard ──────────────────────────────────────────────────────────────────────────
    # the standalone root's `.compat` APPLIES: a formal this root fails to forward throws right here.
    test-standalone-compat-applies = {
      expr = builtins.isAttrs standalone.compat;
      expected = true;
    };
    # ONE construction, two roots — the standalone root presents the SAME shim surface as the flake
    # output. A root wiring a divergent shim (a different dep set, a severed feature) moves this list.
    test-standalone-compat-surface-equals-flake = {
      expr = builtins.attrNames standalone.compat == builtins.attrNames denCompat;
      expected = true;
    };
    # `.compat` rides ON the lib (the standalone root IS the lib): the four-concern API and the shim
    # entry verbs are both reachable from the one returned value.
    test-standalone-lib-and-compat-reachable = {
      expr = (standalone ? mkDen) && (standalone.compat ? compile) && (standalone.compat ? mkDen);
      expected = true;
    };

    # ── the substrate census ─────────────────────────────────────────────────────────────────────
    # Every row lists the deps (or the table names) that FAILED, so a regression prints what broke
    # rather than `false != true`.
    test-substrate-census-domain-interface = {
      expr = d0Interface;
      expected = [ ];
    };
    test-substrate-census-domain-adjustments = {
      expr = d0Adjustments;
      expected = [ ];
    };
    test-substrate-census-declared-form = {
      expr = cForm;
      expected = [ ];
    };
    test-substrate-census-declared-interface = {
      expr = cInterface;
      expected = [ ];
    };
    test-substrate-census-adjustment-within-formals = {
      expr = cAdjustmentDeclared;
      expected = [ ];
    };
    test-substrate-census-viability = {
      expr = cViability;
      expected = [ ];
    };
    test-substrate-census-declared-supplied-is-applied = {
      expr = cSupplied;
      expected = [ ];
    };

    # ── the three capability arms ────────────────────────────────────────────────────────────────
    # gen-class tier 2: the A10 class-share build path fires on the standalone root. Red here means the
    # gen-merge kernel stopped reaching gen-class — the divergence this file exists to witness.
    test-standalone-class-tier2-applies = {
      expr = reached armClassTier2;
      expected = "REACHED";
    };
    # its positive control: the merge-free tier-1 verb, same value, same run.
    test-standalone-class-tier1-control = {
      expr = reached armClassTier1;
      expected = "REACHED";
    };
    # gen-settings: the fold resolves on the standalone root. Red is a ☢️ row printing the abort.
    test-standalone-settings-resolves = {
      expr = armSettings;
      expected = "REACHED";
    };
    # gen-flake: the flake-parts crossing is reachable from the standalone root when the root supplies
    # the host material — the capability was present on the flake root and absent here.
    test-standalone-flake-terminal-applies = {
      expr = reached armFlake;
      expected = "REACHED";
    };
    # its controls: the ungated terminal constructor reads with BOTH host materials as throwing
    # sentinels, and the arm's own root assembles.
    test-standalone-flake-ungated-control = {
      expr = reached armFlakeUngated;
      expected = true;
    };
    test-standalone-flake-root-control = {
      expr = reached armFlakeRoot;
      expected = true;
    };
  };
}
