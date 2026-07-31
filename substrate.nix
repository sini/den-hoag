# The ONE construction of den-hoag's substrate. Both roots go through it: the flake's `outputs` and the
# standalone `default.nix`. A ROOT SUPPLIES MATERIALS — a source path per dep, plus the two host-boundary
# flake values gen-flake's gated terminals need — and NEVER a dep value: every dep value is constructed
# here, from the dep's ROOT ENTRY, which is the only construction of a gen dep both roots can reach.
#
# WHY THIS FILE EXISTS. The two roots each hand-wrote the kernel's dep set, and a wiring restated per root
# is only as correct as the least-exercised root. The flake root re-imported gen-class's `/lib` WITH the
# gen-merge kernel while the standalone root took gen-class's root entry, whose `merge` defaults to null —
# so `applyCoreFixed` (the A10 class-share build path) threw on one root and worked on the other. Both of
# gen-class's published surfaces are merge-less by its own design, so the injection is den-hoag's to make,
# and it is made ONCE, here. The same shape had already produced two more instances in the same two files:
# gen-flake's `nixpkgs`/`flakeParts` (null-gated capabilities, threaded on the flake root only) and
# gen-settings, whose root entry resolves its deps through a `./flake.lock` its published tree does not
# ship. A name-set guard cannot see any of them: `merge` changes the BODY of `applyCoreFixed`, never the
# export set, so the two wirings expose identical names at every revision.
#
# Every formal is REQUIRED. A root that under-supplies is a function applied without a required argument:
# Nix aborts at the application site, naming the material, before any dep is forced and before any tree is
# fetched. There is no thunk for that failure to hide in. A DEFAULTED formal list would instead absorb the
# omission silently and self-wire the material from the lock — which is the defect class above, reinstated
# by the fix.
{
  # dep SOURCE TREES  (flake: inputs.<name>  ·  standalone: fetch "<name>"), one per dep, in
  # one-to-one correspondence with `srcOf` below — which is the only place any of them is read.
  genPreludeSrc,
  genAlgebraSrc,
  genTypesSrc,
  genMergeSrc,
  genSchemaSrc,
  genAspectsSrc,
  genGraphSrc,
  genScopeSrc,
  genResolveSrc,
  genSelectSrc,
  genBindSrc,
  genDispatchSrc,
  genClassSrc,
  genEdgeSrc,
  genProductSrc,
  genSettingsSrc,
  genDemandSrc,
  genPipeSrc,
  genFlakeSrc,

  # HOST-BOUNDARY MATERIALS — flake VALUES, because gen-flake reads `.lib.nixosSystem` and
  # `.lib.evalFlakeModule`, and a flake OUTPUT is not derivable from a source path without evaluating
  # that flake. These are the only two values a root supplies; each root decides what it has, and the
  # standalone root's default for both is a named throw rather than a value or a null.
  nixpkgs,
  flakeParts,
}:
let
  # ── THE PAIRING TABLE ────────────────────────────────────────────────────────────────────────────
  # The ONE place a dep NAME is paired with a dep SOURCE. Every dep-source formal declared above is
  # READ in exactly one place, and that place is here — so a mis-pairing is expressible in exactly one
  # place, and it is a place the census reads: its domain is literally `attrNames srcOf`, and its
  # interface check holds each name's declared interface against the tree THIS table hands it. Mis-pair
  # an entry and that check goes red on that dep.
  srcOf = {
    genPrelude = genPreludeSrc;
    genAlgebra = genAlgebraSrc;
    genTypes = genTypesSrc;
    genMerge = genMergeSrc;
    genSchema = genSchemaSrc;
    genAspects = genAspectsSrc;
    genGraph = genGraphSrc;
    genScope = genScopeSrc;
    genResolve = genResolveSrc;
    genSelect = genSelectSrc;
    genBind = genBindSrc;
    genDispatch = genDispatchSrc;
    genClass = genClassSrc;
    genEdge = genEdgeSrc;
    genProduct = genProductSrc;
    genSettings = genSettingsSrc;
    genDemand = genDemandSrc;
    genPipe = genPipeSrc;
    genFlake = genFlakeSrc;
  };

  # ── THE THREE NAMED LOOKUPS ──────────────────────────────────────────────────────────────────────
  # Every read of every per-dep table goes through one of these, and each one names den-hoag, the dep,
  # and the table that is missing it. Two of the three are the kernel's own reads — `srcFor` and
  # `adjustmentFor` are what the constructors below call — and `interfaceFor` is the CENSUS's, for the
  # table only the census reads. All three are EXPORTED because every read must get the same message,
  # whoever makes it: a raw `interface.${name}` in the census would report `attribute '<name>' missing`,
  # which names neither the file nor the remedy.
  srcFor =
    name:
    srcOf.${name}
      or (throw "den-hoag substrate: `${name}` names no dep source — the substrate's dep set is `srcOf` (spec §2.6)");
  interfaceFor =
    name:
    interface.${name}
      or (throw "den-hoag substrate: `${name}` names no declared interface — every name in `srcOf` carries an `interface` entry declaring its form (spec §2.6)");
  adjustmentFor =
    name:
    adjustments.${name}
      or (throw "den-hoag substrate: `${name}` is applied with no declared adjustment — every dep the substrate applies routes through the `adjustments` attrset (spec §2.6)");

  # A dep's root entry, normalized. THE FORM IS DECLARED, NOT SNIFFED: three deps publish a bare-value
  # lib and the rest publish a self-resolving function of fully-defaulted args, and which is which is a
  # fact about the dep, not about the value in hand. The declaration is the `form` field of the dep's
  # `interface` entry below — DATA, which the census reads and asserts against reality; these two
  # constructors are how a call site honours it, not where it is written.
  #
  # BOTH constructors take ONLY the dep's NAME and resolve the rest by it — `bare` its source, `fn` its
  # source and its adjustment. Neither takes a tree; neither takes an adjustment. That is the whole of
  # it: a call site has no argument position for a source the census did not check, and none for an
  # adjustment the census cannot see, so "the adjustment the census reads is applied to the tree the
  # census checked" is a property of the shape rather than of who remembered. A name absent from either
  # table a constructor reads aborts, named, at the first force of that dep; a name absent from
  # `interface` is a red census row carrying the same named message, since `interface` is the census's
  # table and not the kernel's.
  bare = name: import (srcFor name);
  fn = name: import (srcFor name) (adjustmentFor name);

  # SEALED — for a dep whose every declared formal den-hoag supplies, the self-wiring machinery is not
  # merely unused, it is made unreachable: `lock` and `fetch` throw if anything ever forces them. This
  # is what makes viability a MEASUREMENT rather than a belief, and it is why gen-settings needs no
  # upstream fix to be safe here.
  sealed = d: {
    lock = throw "den-hoag substrate: ${d}'s root entry reached its own lock. den-hoag supplies every formal ${d} declares (spec §2.3); a formal it does not supply has appeared. Give it a disposition in substrate.nix.";
    fetch =
      _: throw "den-hoag substrate: ${d}'s root entry reached its own fetch. See the `lock` message.";
  };

  # HOST MATERIAL, CHECKED — a root may OMIT a host material (its default is a named den-hoag throw
  # saying what is unavailable); it may not pass `null`. `null` is gen-flake's OWN capability-absent
  # signal, so letting one through re-creates the defect shape one dep over: gen-flake's advice to a
  # party that never imported gen-flake. This test is the only path from a root's material to gen-flake,
  # so gen-flake cannot observe a null — den-hoag's `== null` is what forces first, always, and
  # gen-flake's own `!= null` never completes. The refusal is LAZY by construction: forcing the
  # materials when the dep value is built would fire on the standalone root's omitted-material default
  # too, and constructing the gen-flake dep IS on the ordinary standalone path while forcing its
  # materials is not.
  hostValue =
    name: v:
    if v == null then
      throw "den-hoag substrate: host material `${name}` was supplied as null. A host material is a DECISION: pass the flake value, or omit the argument and take the standalone root's named default (spec §2.10). null is neither - it reaches gen-flake as its own capability-absent signal, and surfaces gen-flake's advice to a party that never imported gen-flake."
    else
      v;

  # ── THE DECLARED INTERFACE — ALL NINETEEN DEPS ───────────────────────────────────────────────────
  # Per dep, and the domain is `attrNames srcOf` exactly, in both directions: the entry FORM, and — for
  # the function-form deps — the root-entry formals as `builtins.functionArgs` reports them
  # (name → has-a-default) with a DISPOSITION for each, supplied by den-hoag or left to the dep.
  #
  # `form` is the field that makes bare-ness DATA. Without it, "this dep publishes a bare-value lib"
  # exists only as the choice of `bare` over `fn` at a call site, and a census with nothing to compare
  # against has to SNIFF the imported value — reinstating exactly the value-shape dispatch this file
  # retires, one file over. With it, the census's first check is the two-directional assertion that the
  # tree's function-ness AGREES with what den-hoag wrote down, and it fires named on disagreement in
  # either direction. A bare entry declares `form` and nothing else: a bare value has no formals, so it
  # has no dispositions to declare and no adjustment to hold them against.
  #
  # Three checks read this table and they read it in different directions: one holds `form` against the
  # tree, one holds `formals` against the tree `srcOf` pairs with this name, and one holds `supplied`
  # against the adjustment actually applied below. The disposition is the DECLARATION; the adjustment is
  # the CODE; a construction where the two can drift apart is this file's own defect shape at the
  # adjustment site, which is why they are compared rather than merely both written.
  interface = {
    # the three bare-value deps — form, and nothing else to declare
    genPrelude = {
      form = "bare";
    };
    genAlgebra = {
      form = "bare";
    };
    genSelect = {
      form = "bare";
    };

    genTypes = {
      form = "fn";
      formals = {
        prelude = true;
      };
      supplied = [ ];
    };
    genMerge = {
      form = "fn";
      formals = {
        fetch = true;
        lock = true;
        prelude = true;
        types = true;
      };
      supplied = [ ];
    };
    genSchema = {
      form = "fn";
      formals = {
        algebra = true;
        fetch = true;
        lock = true;
        merge = true;
        prelude = true;
      };
      supplied = [ ];
    };
    genAspects = {
      form = "fn";
      formals = {
        fetch = true;
        lock = true;
        merge = true;
        prelude = true;
        schema = true;
      };
      supplied = [ ];
    };
    genGraph = {
      form = "fn";
      formals = {
        prelude = true;
      };
      supplied = [ ];
    };
    genScope = {
      form = "fn";
      formals = {
        prelude = true;
      };
      supplied = [ ];
    };
    genResolve = {
      form = "fn";
      formals = {
        algebra = true;
        bind = true;
        fetch = true;
        graph = true;
        lock = true;
        prelude = true;
        rebuild = true;
        scope = true;
      };
      supplied = [ ];
    };
    genBind = {
      form = "fn";
      formals = {
        prelude = true;
      };
      supplied = [ ];
    };
    genDispatch = {
      form = "fn";
      formals = {
        prelude = true;
      };
      supplied = [ ];
    };
    genClass = {
      form = "fn";
      formals = {
        fetch = true;
        lock = true;
        merge = true;
        prelude = true;
      };
      supplied = [
        "fetch"
        "lock"
        "merge"
        "prelude"
      ];
    };
    genEdge = {
      form = "fn";
      formals = {
        fetch = true;
        graph = true;
        lock = true;
        prelude = true;
      };
      supplied = [ ];
    };
    genProduct = {
      form = "fn";
      formals = {
        fetch = true;
        lock = true;
        prelude = true;
      };
      supplied = [ ];
    };
    genSettings = {
      form = "fn";
      formals = {
        algebra = true;
        bind = true;
        fetch = true;
        lock = true;
        prelude = true;
      };
      supplied = [
        "algebra"
        "bind"
        "fetch"
        "lock"
        "prelude"
      ];
    };
    genDemand = {
      form = "fn";
      formals = {
        fetch = true;
        graph = true;
        lock = true;
        prelude = true;
        select = true;
      };
      # `select` DECLARED ABSENT — a disposition, not a silence: den-hoag reads no `demand.adapters`
      # surface anywhere, so the select adapter is a capability den-hoag has decided it does not carry.
      supplied = [ ];
    };
    genPipe = {
      form = "fn";
      formals = {
        fetch = true;
        lock = true;
        prelude = true;
        scope = true;
        select = true;
      };
      supplied = [ ];
    };
    genFlake = {
      form = "fn";
      formals = {
        fetch = true;
        flakeParts = true;
        genAspects = true;
        genBind = true;
        genMerge = true;
        genPrelude = true;
        genSchema = true;
        genTypes = true;
        importTree = true;
        lock = true;
        nixpkgs = true;
      };
      supplied = [
        "flakeParts"
        "nixpkgs"
      ];
    };
  };

  # ── THE ADJUSTMENTS — what den-hoag applies to each root entry ────────────────────────────────────
  # THE only attrset a dep application can reach: `fn` looks its argument up here, by the SAME name that
  # indexes `srcOf`, and takes no adjustment from the call site. So the census compares THIS attrset's
  # domain against the dispositions above, and because one name selects both tables, that is a
  # comparison against what is applied to the tree the interface check read, with no gap between the
  # three for a later edit to open. Every function-form dep needs an entry, including the twelve whose
  # entry is `{ }`; a dep applied under a missing name aborts named on first force. The census reads
  # `attrNames` only, so no value here is forced by it — in particular the host materials are not, and a
  # root that omitted one is not punished for a check it is not the subject of.
  adjustments = {
    genTypes = { };
    genMerge = { };
    genSchema = { };
    genAspects = { };
    genGraph = { };
    genScope = { };
    genResolve = { };
    genBind = { };
    genDispatch = { };
    genEdge = { };
    genProduct = { };
    genPipe = { };
    genDemand = { };
    genClass = {
      inherit (kernel) prelude merge;
    }
    // sealed "gen-class";
    genSettings = {
      inherit (kernel) prelude algebra bind;
    }
    // sealed "gen-settings";
    genFlake = {
      nixpkgs = hostValue "nixpkgs" nixpkgs;
      flakeParts = hostValue "flakeParts" flakeParts;
    };
  };

  # ── THE KERNEL DEP SET — the argument `import ./lib` takes. ────────────────────────────────────────
  # Fourteen deps carry no den-hoag DECISION: their root entry self-wires over the same revisions
  # den-hoag's own lock names, and their tree ships a lock that resolves what it declares, so
  # `bare "<name>"` / `fn "<name>"` over an EMPTY adjustment is the whole construction. The deps that DO
  # carry a decision are written out below.
  # A call site PASSES a NAME and nothing else — not a tree, not an adjustment. So the adjustment the
  # census reads is applied to the tree it checked: one name selects both, from two tables the census
  # reads, and a call site has no argument position from which to disagree with either. The attribute
  # name on the left is `import ./lib`'s formal, not the dep's — a slot a mis-typed name binds the wrong
  # LIBRARY into, which fails on a genuine read of it; the dep's own disposition travels with the dep
  # NAME on the right, so nothing goes silently unapplied through that position.
  kernel = {
    prelude = bare "genPrelude";
    algebra = bare "genAlgebra";
    select = bare "genSelect";
    types = fn "genTypes";
    merge = fn "genMerge";
    schema = fn "genSchema";
    aspects = fn "genAspects";
    graph = fn "genGraph";
    scope = fn "genScope";
    resolve = fn "genResolve";
    bind = fn "genBind";
    dispatch = fn "genDispatch";
    edge = fn "genEdge";
    product = fn "genProduct";
    pipe = fn "genPipe";

    # gen-class — THE TIER-2 INJECTION. Both of gen-class's published surfaces are merge-less by its own
    # design, and `applyCoreFixed` (the A10 class-share build path) throws named without the gen-merge
    # kernel. The injection is therefore den-hoag's to make; it is made HERE so it cannot be present on
    # one root and absent on the other. `prelude` is den-hoag's OWN prelude, not gen-class's locked one
    # — a deliberate override, which the root entry admits: `prelude` and `merge` are both declared
    # formals of it. Supplying both empties the unsupplied surface, so the entry is sealed.
    class = fn "genClass";

    # gen-settings — THE LOCK-DEPENDENT DEP. Its root entry resolves prelude/algebra/bind through a
    # `./flake.lock` its PUBLISHED TREE DOES NOT SHIP, so leaving it to self-wire aborts on the first
    # verb that forces a dep. All three are den-hoag kernel deps already, so supplying them costs
    # nothing and empties the unsupplied surface. This does not wait on an upstream fix, and does not
    # change if one lands.
    settings = fn "genSettings";

    # gen-flake — THE CAPABILITY-CARRYING CONSTRUCTION. Its root entry leaves `nixpkgs` and `flakeParts`
    # null, which gates `terminals.nixosSystem` and `terminals.mkFlakeTerminal` behind named throws. A
    # capability that is present on one root and absent on the other is the defect this construction
    # removes, so BOTH formals are threaded HERE, unconditionally, on both roots. Threaded through
    # `hostValue`, so the one remaining way to put a null in front of gen-flake — a root passing one
    # explicitly — is refused in den-hoag's voice. NOT sealed: gen-flake self-wires its other nine
    # formals from its own lock, which its tree ships. Threading is FREE until a gated verb is applied.
    flake = fn "genFlake";

    # gen-demand — `select ? null`, DECLARED ABSENT. Not "left at its default": den-hoag reads no
    # `demand.adapters` surface anywhere, so the select adapter is a capability den-hoag has decided it
    # does not carry. The declaration is `interface.genDemand.supplied = [ ]` above, and the census
    # holds the empty adjustment to it — which is what makes it a decision rather than a silence.
    demand = fn "genDemand";
  };
in
# The four attrsets above live in the `let` because `fn` reads `srcOf` and `adjustments`, and
# `adjustments` reads `kernel`: `let` bindings are mutually recursive, while a `rec` set's attributes
# are not in scope in the `let` that defines its helpers. `srcOf` is returned because it is the census's
# domain; it is names paired with source paths and nothing else. The three lookups are returned for the
# same reason: every read of these tables, whoever makes it, must report through the same named throws
# rather than through a raw attribute select. Two of them are the kernel's own reads, made available to
# the census so it reads the same expression the kernel binds; `interfaceFor` is the census's own, for
# the one table the kernel never reads.
{
  inherit
    srcOf
    srcFor
    interfaceFor
    adjustmentFor
    interface
    adjustments
    kernel
    ;

  # ── THE COMPAT SHIM'S SUBSTRATE ──────────────────────────────────────────────────────────────────
  # lib/compat/wiring.nix owns the SHIM's construction; this owns where its substrate comes from — the
  # same split as above. `edgeSrc` is the already-shipped source-material idea `srcOf` generalizes, and
  # it is read through `srcFor` like every other source: the shim's one source material is paired with
  # its name in the same table as every other, no dep-source formal is referenced anywhere but there,
  # and this read gets the same named message as the kernel's rather than a raw attribute error.
  compatArgs = denHoag: {
    inherit denHoag;
    inherit (kernel)
      prelude
      schema
      aspects
      merge
      graph
      edge
      ;
    edgeSrc = srcFor "genEdge";
  };

  # ── THE FLAKE-ONLY DOWNSTREAM SURFACES ───────────────────────────────────────────────────────────
  # Enumerated so no `inputs.<x>.lib` read survives outside this file.
  bridgeArgs = {
    inherit (kernel) prelude schema;
  };
  homeEnvArgs = {
    inherit (kernel) prelude;
  };
}
