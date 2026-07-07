# compat-legacy-severed (C5) — the legacy `forwards` surface (self-contained tagged legacy/forwards.nix)
# and its two tiers, the `den.interpret.synthesize` seam, and the Law-C5 sentinel. This file lands the
# FORWARDS HALF of the severability suite; the full severed-module half (both legacy surfaces removed +
# surface totality) completes in Task 6 (C6). Ground truth: the frozen pin denful/den@11866c16 forward
# system (forward.nix / handlers/forward.nix / route.nix) + the PIN.md corpus census.
#
#   TIER-1 (static forward, no adapter) → a plain `deliver` (collected source, reroute-shaped), the same
#     surface the corpus takes — identical to v1's tier-1 classification. Witnesses: the 3 home-platform
#     routes (homeLinux/homeDarwin/homeAarch64 → home-manager, path=[], no adaptArgs).
#   COMPLEX (adapter-bearing) → an INERT gen-edge `synthesize` source record with identity triple
#     (forwardId, fromClass, intoClass) + this module's `interpret.synthesize`. Witnesses: the hm
#     delivery (osConfig-threading adaptArgs) and the devshell route (allModuleArgs adaptArgs) — the two
#     adapter shapes PIN.md records. The record is inert (trace renders identity, never forces content);
#     the interpreter RUNS at materialization, threaded through den.interpret (item 7).
#   SENTINEL — a `den.classes.<c>.forwardTo` reaching compile un-desugared (severed module) is a named
#     definition-time error (Law C5), parallel to the `provides` sentinel.
{ denHoag, denCompat, ... }:
let
  fwd = denCompat.legacy.forwards;
  edge = denHoag.internal.edge;

  # ── the corpus forward-tier witnesses (forward SPECS mirroring PIN.md's shapes) ──────────────────────
  # Tier-1: the 3 home-platform static forwards (path=[], no adapter) → plain deliver.
  tier1Specs = {
    homeLinux = {
      fromClass = "homeLinux";
      intoClass = "home-manager";
    };
    homeDarwin = {
      fromClass = "homeDarwin";
      intoClass = "home-manager";
    };
    homeAarch64 = {
      fromClass = "homeAarch64";
      intoClass = "home-manager";
    };
  };

  # Complex: the 2 adapter-bearing routes → synthesize record + interpret.synthesize.
  #   hm delivery — os-user.nix threads osConfig: `adaptArgs = args: args // { osConfig = args.config; }`.
  hmSpec = {
    fromClass = "user";
    intoClass = "nixos";
    adapterKey = "user/nixos/users/users/alice";
    intoPath = [
      "users"
      "users"
      "alice"
    ];
    adaptArgs = args: args // { osConfig = args.config or { }; };
    sourceModule = {
      config.programs.git.enable = true;
    };
  };
  #   devshell route — `adaptArgs = { config, ... }: config.allModuleArgs`.
  devshellSpec = {
    fromClass = "devshell";
    intoClass = "flake-parts";
    adapterKey = "devshell/flake-parts/devshells/default";
    intoPath = [
      "devshells"
      "default"
    ];
    adaptArgs = { config, ... }: config.allModuleArgs or { };
    sourceModule = {
      config.packages = [ "hello" ];
    };
  };

  # ── the desugar outputs ──────────────────────────────────────────────────────────────────────────
  tier1Out = builtins.mapAttrs (_: fwd.forward) tier1Specs;
  hmRecord = fwd.forward hmSpec;
  devshellRecord = fwd.forward devshellSpec;

  # ── (D) the interpreter RUN through gen-edge's materialize fold (item 7) ──────────────────────────
  # A minimal synthesize edge (merge → the target's output cell) folded with the legacy interpreter, to
  # prove interpret.synthesize is a REAL function den-hoag threads into `materialize`, not inert data.
  synEdge = edge.edge {
    source = hmRecord;
    target = edge.targets.root {
      root = "host:h";
      class = "nixos";
    };
    mode = "merge";
  };
  folded = edge.materialize {
    edges = edge.toposort [ synEdge ];
    projection = {
      contents = { };
      universe = [ ];
      dedupMode = "raw";
    };
    interpret = fwd.interpret;
  };
  # the folded content is the composed module (a FUNCTION module — the adaptArgs arm threads args).
  foldedContent = builtins.head folded."host:h".nixos;

  # ── (E) inert: the trace renders the synthesize identity WITHOUT forcing the carried module ────────
  # (records identity, never content — v1's sourceVia="unresolved"). Module = throw ⇒ trace still renders.
  inertEdge = edge.edge {
    source = fwd.synthRecord (
      hmSpec // { sourceModule = throw "content must NOT be forced by trace"; }
    );
    target = edge.targets.root {
      root = "host:h";
      class = "nixos";
    };
    mode = "nest";
    path = hmSpec.intoPath;
    annotations = {
      complexForward = true;
      sourceVia = "unresolved";
    };
  };
  inertTraced = builtins.head (edge.trace [ inertEdge ]);

  # ── (F) the Law-C5 sentinel: a forwardTo reaching compile un-desugared is a named error ────────────
  # Force the compiled class (the sentinel is a lazy `seq` inside translateClass) so the throw is observed.
  sentinelTripped =
    (builtins.tryEval (
      builtins.seq
        (denCompat.compile {
          classes.myclass.forwardTo = {
            class = "other";
            path = [ ];
          };
        }).classes.myclass
        null
    )).success;
  # a class WITHOUT forwardTo compiles clean (the sentinel is surgical, not a blanket class reject).
  cleanClassOk =
    (builtins.tryEval (
      builtins.seq (denCompat.compile { classes.plain.wrap = null; }).classes.plain null
    )).success;

  # ── (G) desugar strips forwardTo (present-module path: the sentinel then passes) ───────────────────
  desugared = fwd.desugar {
    classes = {
      c1.forwardTo = {
        class = "x";
        path = [ ];
      };
      c1.wrap = null;
      c2.share.core = true;
    };
  };
in
{
  flake.tests.compat-legacy-severed = {
    # ── the tag (severability handle) ────────────────────────────────────────────────────────────────
    test-forwards-tag = {
      expr = fwd._denCompat.legacy;
      expected = "forwards";
    };

    # ── (A) TIER-1: static forward → a plain deliver descriptor ────────────────────────────────────────
    test-tier1-is-not-complex = {
      expr = builtins.any fwd.isComplex (builtins.attrValues tier1Specs);
      expected = false;
    };
    # each tier-1 forward → a `deliver` descriptor: collected source (sourceClass = fromClass, no module),
    # target = intoClass, merge at the root (path=[]) — identical to v1's tier-1 route classification.
    test-tier1-homeLinux-deliver = {
      expr = {
        inherit (tier1Out.homeLinux)
          __delivery
          sourceClass
          moduleSource
          target
          path
          mode
          ;
      };
      expected = {
        __delivery = true;
        sourceClass = "homeLinux";
        moduleSource = null;
        target = "home-manager";
        path = [ ];
        mode = "merge";
      };
    };
    test-tier1-homeDarwin-source = {
      expr = tier1Out.homeDarwin.sourceClass;
      expected = "homeDarwin";
    };
    test-tier1-homeAarch64-target = {
      expr = tier1Out.homeAarch64.target;
      expected = "home-manager";
    };
    # tier-1 never emits a synthesize record (it takes the plain deliver path).
    test-tier1-no-synthesize = {
      expr = tier1Out.homeLinux ? synthesize;
      expected = false;
    };

    # ── (B) COMPLEX: adapter-bearing forward → an inert synthesize record with the identity triple ─────
    test-hm-is-complex = {
      expr = fwd.isComplex hmSpec;
      expected = true;
    };
    test-devshell-is-complex = {
      expr = fwd.isComplex devshellSpec;
      expected = true;
    };
    # the synthesize source record's identity triple (forwardId, fromClass, intoClass) — the frozen schema.
    test-hm-synthesize-triple = {
      expr = hmRecord.synthesize.spec;
      expected = {
        forwardId = "user/nixos/users/users/alice";
        fromClass = "user";
        intoClass = "nixos";
      };
    };
    test-devshell-synthesize-triple = {
      expr = devshellRecord.synthesize.spec;
      expected = {
        forwardId = "devshell/flake-parts/devshells/default";
        fromClass = "devshell";
        intoClass = "flake-parts";
      };
    };
    # forwardId falls back to the scope-free adapterKey FORMULA when no adapterKey is on the spec
    # (fromClass/intoClass/staticIntoPath joined) — never v1's scope-bearing arm (Law C2).
    test-forwardId-formula-fallback = {
      expr = fwd.forwardId {
        fromClass = "a";
        intoClass = "b";
        intoPath = [
          "p"
          "q"
        ];
        adaptArgs = _: { };
      };
      expected = "a/b/p/q";
    };
    # the source record is the synthesize arm (not collected/value) — a real gen-edge source.
    test-hm-source-arm = {
      expr = builtins.attrNames hmRecord;
      expected = [ "synthesize" ];
    };

    # ── (C) the module supplies interpret.synthesize (den-hoag defines none — item 7) ──────────────────
    test-interpret-synthesize-is-fn = {
      expr = builtins.isFunction fwd.interpret.synthesize;
      expected = true;
    };

    # ── (D) the interpreter RUNS through the materialize fold ──────────────────────────────────────────
    # the fold produces content for the target root (the composer ran, item 7).
    test-fold-produces-content = {
      expr = builtins.length folded."host:h".nixos;
      expected = 1;
    };
    # the composed content is a FUNCTION module (the adaptArgs arm threads the cell's args before the
    # source sees them — v1 route.nix adaptModule) — proving the adapter composition, not a bare passthrough.
    test-fold-content-is-adapter-module = {
      expr = builtins.isFunction foldedContent;
      expected = true;
    };
    # the composed module carries the source module (its content survived the composition).
    test-fold-content-imports-source = {
      expr = (foldedContent { config = { }; }).imports or [ ] != [ ];
      expected = true;
    };

    # ── (E) inert: trace renders identity, never forces the carried module (sourceVia unresolved) ──────
    test-inert-trace-identity = {
      expr = inertTraced.source.spec.forwardId;
      expected = "user/nixos/users/users/alice";
    };
    test-inert-trace-arm = {
      expr = inertTraced.source.arm;
      expected = "synthesize";
    };
    test-inert-sourceVia-annotation = {
      expr = inertTraced.annotations.sourceVia;
      expected = "unresolved";
    };

    # ── (F) the Law-C5 sentinel ────────────────────────────────────────────────────────────────────────
    test-sentinel-fires-on-forwardTo = {
      expr = sentinelTripped;
      expected = false;
    };
    test-clean-class-compiles = {
      expr = cleanClassOk;
      expected = true;
    };

    # ── (G) desugar strips forwardTo (present-module path) ─────────────────────────────────────────────
    test-desugar-strips-forwardTo = {
      expr = desugared.classes.c1 ? forwardTo;
      expected = false;
    };
    # …while leaving the rest of the class untouched (surgical strip, not a class rebuild).
    test-desugar-keeps-other-class-keys = {
      expr = (desugared.classes.c1 ? wrap) && desugared.classes.c2.share.core;
      expected = true;
    };
  };
}
