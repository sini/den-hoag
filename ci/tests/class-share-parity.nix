# Task 10 (A10) — class-share PARITY + gate authority (spec §2.10, Law A18). Class-share is an
# IMPLEMENTATION STRATEGY, not semantics: the gen-class tier-2 `applyCoreFixed` spine-skip is
# byte-identical to the ordinary full merge, authorised ONLY by the byte gate, and it leaves
# `config(root)` + trace E untouched.
#
# Two arms:
#   (A) class-share level (the mechanism) — `classShare.build` over synthetic members: the
#       applyCoreFixed-built member is byte-identical to the ordinary full merge (gateCore green);
#       a member-varying value drops out of the core at `mkCore`; a member that also defines the core
#       loc falls through byte-identically; a divergent core fails the gate LOUD.
#   (B) fleet level (the invariant) — the SAME fleet built with `share.core` on vs off has byte-equal
#       `config(root)` and trace E (share.core shapes only `systems.<class>.<member>`).
{
  denHoag,
  nixpkgsLib,
  ...
}:
let
  I = denHoag.internal;
  classShare = I.classShare;
  merge = I.merge;
  nixosEntry = denHoag.classes.nixos;

  # ══ Arm A — the mechanism (classShare.build over synthetic members) ═════════════════════════════════
  # Two members of one class; every member's projection is FULLY shared at the projection loc, so the
  # core carries the whole projection and each member's DELTA is an axis at a different loc.
  members2 = {
    m1 = { };
    m2 = { };
  };
  classOf = _node: nixosEntry; # both members produce the same class ⇒ one partition
  # Test-local synthetic loc for the ISOLATED mechanism tests — deliberately distinct from the live
  # den path's loc (internal.classShareCoreAttr = "denClassShareCore") so nothing here accidentally
  # couples to the assembly wiring.
  projectionPath = "denCore";
  sharedProj = _id: {
    alpha = "A";
    beta = [
      1
      2
    ];
  };
  built = classShare.build {
    members = members2;
    inherit classOf;
    projectionOf = sharedProj;
    inherit projectionPath;
    shareCore = true;
  };
  core = (builtins.head built.perClass).core;

  # a member delta = an axis at its OWN loc (never the core loc), so the core is the sole def there.
  axisDelta = axis: [
    {
      options.axisKey = merge.mkOption { };
      config.axisKey = axis;
    }
  ];
  # the plain full-merge REFERENCE twin of applyCoreFixed's internal coreModule (marker → plain values,
  # kernel OFF): the byte oracle for the shared build.
  plainCoreModule = {
    options.${projectionPath} = merge.mkOption { };
    config.${projectionPath} = core.values;
  };

  shareCfgM1 = built.outputFor "m1" (axisDelta "m1-axis");
  refCfgM1 =
    (merge.evalModuleTree { modules = (axisDelta "m1-axis") ++ [ plainCoreModule ]; }).config;
  gateM1 = built.gate "m1" (sharedProj "m1");

  # ── fall-through: a member that ALSO defines the core loc merges (byte-identical, no skip) ──
  coreDefiningDelta = [
    {
      options.${projectionPath} = merge.mkOption { type = merge.anything; };
      config.${projectionPath} = {
        extra = "member-owned";
      };
    }
  ];
  fallCfg = built.outputFor "m1" coreDefiningDelta;
  fallRef = (merge.evalModuleTree { modules = coreDefiningDelta ++ [ plainCoreModule ]; }).config;

  # ── host.addr drops out of the core at mkCore (member-varying, config-independent) ──
  varyProj =
    id:
    {
      alpha = "A"; # shared
    }
    // {
      addr = if id == "m1" then "10.0.0.1" else "10.0.0.2"; # member-varying ⇒ dropped
    };
  builtVary = classShare.build {
    members = members2;
    inherit classOf;
    projectionOf = varyProj;
    inherit projectionPath;
    shareCore = true;
  };
  coreVary = (builtins.head builtVary.perClass).core;

  # ── divergent core fails the gate LOUD (A18 teeth) ──
  # den-hoag path: a member whose REAL projection diverges from the shared core at a shared key — the
  # gate is RED and `authorize` aborts (a stale/wrong core is never silently reused).
  tamperedReal = (sharedProj "m1") // {
    alpha = "TAMPERED";
  };
  gateRed = built.gate "m1" tamperedReal;
  authorizeThrows =
    !(builtins.tryEval (builtins.deepSeq (built.authorize "m1" tamperedReal) true)).success;
  # gen-class teeth, den-level: a wrong CORE (same keys, one tampered value) gated against the real
  # member is RED (mirrors gen-class ci/tests/apply-fixed `fixed-teeth`).
  wrongCore = I.class.mkCoreRecord {
    class = (builtins.head built.perClass).cls;
    projection = projectionPath;
    sharedKeys = core.sharedKeys;
    values = core.values // {
      alpha = "WRONG";
    };
  };
  wrongGate = I.class.gateCore {
    core = wrongCore;
    candidate = wrongCore.values;
    real = sharedProj "m1";
  };

  # ══ Arm B — the fleet invariant (config(root) + trace E under share.core on/off) ════════════════════
  schema = {
    config.den.schema = {
      env.parent = null;
      host.parent = "env";
      user.parent = "host";
    };
  };
  instances = {
    config.den = {
      env.prod = { };
      host.axon = { };
      host.blade = { };
    };
  };
  membership =
    { config, ... }:
    {
      config.den.membership = [
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.axon;
          };
        }
        {
          coords = {
            env = config.den.env.prod;
            host = config.den.host.blade;
          };
        }
      ];
    };
  classing.config.den.contentClass.host = "nixos";
  quirk.config.den.quirks.ports = { };
  # an aspect emitting a class-invariant channel value (shared across hosts) AND nixos class content.
  content =
    { config, ... }:
    {
      config.den.aspects.svc = {
        ports = [
          22
          80
        ];
        nixos = {
          boot.isContainer = true;
        };
      };
      config.den.include = [
        {
          at = config.den.host.axon;
          aspects = [ config.den.aspects.svc ];
        }
        {
          at = config.den.host.blade;
          aspects = [ config.den.aspects.svc ];
        }
      ];
    };
  shareOn.config.den.classes.nixos.share.core = true;

  base = [
    schema
    instances
    membership
    classing
    quirk
    content
  ];
  denOff = (denHoag.mkDen base).den;
  denOn = (denHoag.mkDen (base ++ [ shareOn ])).den;
  axonId = "host:axon";

  configOff = denOff.output.outputFor axonId;
  configOn = denOn.output.outputFor axonId;
  traceOff = denOff.graph.trace axonId;
  traceOn = denOn.graph.trace axonId;
in
{
  flake.tests.class-share-parity = {
    # ── Arm A: the mechanism ──
    # applyCoreFixed-built member == the ordinary full-merge reference, byte-for-byte (gate authority).
    test-share-byte-identical-to-full-merge = {
      expr = builtins.toJSON shareCfgM1 == builtins.toJSON refCfgM1;
      expected = true;
    };
    # the byte gate authorises the share (green) — else the parity claim is vacuous.
    test-gate-green = {
      expr = gateM1.gate;
      expected = true;
    };
    # the projection loc reconstructs EXACTLY core.values (the short-circuit returned `values` verbatim).
    test-core-loc-is-core-values = {
      expr = shareCfgM1.${projectionPath} == core.values;
      expected = true;
    };
    # a member that ALSO defines the core loc falls through to the full merge, still byte-identical.
    test-fall-through-byte-identical = {
      expr = builtins.toJSON fallCfg == builtins.toJSON fallRef;
      expected = true;
    };
    # …and the fall-through actually MERGED (member's own value survives beside the core values).
    test-fall-through-merges = {
      expr = (fallCfg.${projectionPath}).extra or null;
      expected = "member-owned";
    };
    # a member-varying config-independent value drops out of the core at mkCore (only `alpha` shared).
    test-varying-value-drops-from-core = {
      expr = coreVary.sharedKeys;
      expected = [ "alpha" ];
    };
    test-varying-value-absent-from-core-values = {
      expr = coreVary.values ? addr;
      expected = false;
    };
    # ── Arm A: the gate teeth (A18) ──
    # a member whose real projection diverges from the core is RED at the gate…
    test-divergent-real-gate-red = {
      expr = gateRed.gate;
      expected = false;
    };
    # …and `authorize` aborts LOUD (a divergent core is never silently reused).
    test-divergent-real-authorize-throws = {
      expr = authorizeThrows;
      expected = true;
    };
    # a WRONG core (tampered value) gated against the real member is RED (gen-class teeth, den-level).
    test-wrong-core-gate-red = {
      expr = wrongGate.gate;
      expected = false;
    };

    # ── Arm B: the fleet invariant (A18) ──
    # config(root) is byte-equal with share.core on vs off (share.core is not semantics).
    test-config-root-invariant = {
      expr = builtins.toJSON configOn == builtins.toJSON configOff;
      expected = true;
    };
    # config(root) is non-empty (the invariance above is not vacuous).
    test-config-root-nonempty = {
      expr = configOff.${axonId}.ports or null;
      expected = [
        [
          22
          80
        ]
      ];
    };
    # trace E is byte-equal with share.core on vs off.
    test-trace-invariant = {
      expr = traceOn == traceOff;
      expected = true;
    };
    # the trace is non-empty (the invariance above is not vacuous).
    test-trace-nonempty = {
      expr = builtins.length traceOff >= 1;
      expected = true;
    };
  };
}
