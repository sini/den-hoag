# C1 witness map for the §2.4 pipe stage vocabulary. Each fixture is a den v1 declaration set
# `denCompat.compile` accepts; `ci/tests/compat-compile-golden.nix` compiles them and asserts the
# stage→op mapping, the `den.quirks` → channel registration, the key-overlap check, and the deferred
# (config-thunk) discipline (parity-watch items 5, 6). The future parity harness (P-suites) reads the
# SAME fixtures so its structural/content oracle exercises every stage row against den v1 itself.
#
# `pipe` mirrors den v1's `nix/lib/policy-effects.nix` `pipe` constructors verbatim, so a fixture reads
# exactly like a v1 corpus policy and the compat compiler consumes the real `__pipeStage`/`__policyEffect`
# records — no synthetic shapes.
{ ... }:
let
  pipe = {
    from = name: stages: {
      __policyEffect = "pipe";
      value = {
        pipeName = name;
        inherit stages;
      };
    };
    filter = fn: {
      __pipeStage = "filter";
      inherit fn;
    };
    transform = fn: {
      __pipeStage = "transform";
      inherit fn;
    };
    fold = fn: init: {
      __pipeStage = "fold";
      inherit fn init;
    };
    append = value: {
      __pipeStage = "append";
      inherit value;
    };
    for = fn: {
      __pipeStage = "for";
      inherit fn;
    };
    to = aspects: {
      __pipeStage = "to";
      inherit aspects;
    };
    as = targetPipeName: {
      __pipeStage = "as";
      inherit targetPipeName;
    };
    expose = {
      __pipeStage = "expose";
    };
    broadcast = fn: {
      __pipeStage = "broadcast";
      inherit fn;
    };
    collect = fn: {
      __pipeStage = "collect";
      inherit fn;
    };
    collectAll = fn: {
      __pipeStage = "collectAll";
      inherit fn;
    };
    withProvenance = {
      __pipeStage = "withProvenance";
    };
  };
in
{
  inherit pipe;

  # ── `den.quirks.<name>` → channel registration (acceptance 2) ───────────────────────────────────────
  # A bare marker quirk (default ordered-list channel) and one carrying gen-pipe channel options.
  channelsFixture = {
    quirks.backends.description = "http backends";
    quirks.tuned = {
      description = "with channel options";
      merge = "ordered-list";
      dedup = "by-key";
    };
  };

  # A name declared as BOTH a class and a quirk channel — the key-overlap check must abort.
  overlapFixture = {
    classes.dup = { };
    quirks.dup.description = "collides with a class";
  };

  # ── deriving stages: filter/transform/fold/for → left-to-right op DAG (acceptance 1) ────────────────
  # The op chain reads outermost→base: for(map) ∘ fold ∘ transform(map) ∘ filter, over channel `metric`.
  derivePipe = {
    quirks.metric.description = "numeric metric stream";
    policies.shapeMetric = _ctx: [
      (pipe.from "metric" [
        (pipe.filter (v: v.keep))
        (pipe.transform (v: v // { seen = true; }))
        (pipe.fold (acc: v: acc + v.n) 0)
        (pipe.for (vs: vs))
      ])
    ];
  };

  # ── delivery stages: to → route selecting aspects; as → route to a target pipe (acceptance 1) ───────
  deliverToPipe = {
    quirks.ports.description = "firewall ports";
    aspects.web = { };
    policies.routePorts = _ctx: [
      (pipe.from "ports" [ (pipe.to [ { name = "web"; } ]) ])
    ];
  };
  deliverAsPipe = {
    quirks.raw.description = "raw stream";
    quirks.shaped.description = "renamed target stream";
    policies.renameRaw = _ctx: [
      (pipe.from "raw" [ (pipe.as "shaped") ])
    ];
  };

  # ── site stages: append/expose/broadcast/collect/collectAll/withProvenance → inert markers ──────────
  sitePipe = {
    quirks.peers.description = "per-user device records";
    policies.gatherPeers = _ctx: [
      (pipe.from "peers" [
        (pipe.append { host = "self"; })
        pipe.expose
        (pipe.broadcast ({ user, ... }: true))
        (pipe.collect ({ host, ... }: true))
        (pipe.collectAll ({ host, ... }: true))
        pipe.withProvenance
      ])
    ];
  };

  # ── deferred-value discipline (parity-watch items 5, 6) ─────────────────────────────────────────────
  # A config-demanding channel value rides the quirk key RAW (den-hoag `isConfigThunk` detects it,
  # resolved via gen-bind `__configThunk` at the terminal). Its body THROWS: the shim must never force it,
  # so `compile` (and the pipe over it) crossing the value untouched proves the E6-poison never fires
  # mid-compile. The filter/transform pipe over it emits no value-demanding op (no fold/scan).
  deferredFixture = {
    quirks.marks.description = "config-derived host marks";
    aspects.svc.marks =
      { config, ... }:
      throw "den-compat pipe: a deferred channel value must not be forced mid-compile";
    policies.shapeMarks = _ctx: [
      (pipe.from "marks" [
        (pipe.filter (_: true))
        (pipe.transform (m: m))
      ])
    ];
  };
}
