# u15 — THE FULL v1 BUILT-IN CLASS SET registration (the u14 register; ledger B15/q rung). den v1's
# flakeModule imports EVERY `modules/**.nix` (nix/flakeModule.nix:3 — `listFilesRecursive`, no `/_`), so
# every built-in module that DECLARES a `den.classes.<name>` is ALWAYS registered on a v1 fleet, regardless
# of whether the corpus produces content for it. `lib/compat/builtins.nix` now registers, as a bare inert
# declared class each (the flake-parts recipe), the v1 built-ins den-hoag's kind-generic core `classNames`
# (nixos/darwin/home-manager/k8s-manifests) + the os/user legacy desugars do NOT already carry: the battery
# convenience classes `wsl`/`maid`/`hjem` (batteries/{wsl,maid,hjem}.nix @ pin 11866c16) and the flake system
# output classes `packages`/`apps`/`checks`/`devShells`/`legacyPackages` (policies/flake.nix:41). A bare
# declared class admits its name to `classifyKey`'s CLASS branch + ingest's `classRegistry`, is never a
# producing class (no fold edge), and carries no wrap/instantiate/share (an INERT collect-only terminal, no
# gen-flake crossing) — so a §2.2 abort on a v1 built-in class name (the u14 `wsl` blocker: the compat
# primary-user battery emits `wsl.defaultUser`) NEVER recurs. Registration only unblocks CLASSIFICATION; a
# corpus with no producing member ⇒ no output entry (the corpus-relative INERT posture, ledger B15/q).
#
# Witnesses:
#   • the ACTUAL builtins.nix registration (prelude-free unit read — the wiring regression guard);
#   • SYNTHETIC: a self-named host aspect emits `wsl` content → it classifies (no abort) and is PRODUCED
#     into the wsl class bucket (the class-content assembly = its collect terminal);
#   • CORPUS-SHAPE COMPANION: the SAME fleet with no wsl emitter ⇒ the wsl bucket is EMPTY (no output) and
#     the nixos content is byte-identical (nothing else moved), wsl still registered;
#   • the §2.2 abort posture stays LOUD for a genuinely-unknown class name (R9 three-branch strictness).
{
  denCompat,
  denHoagSrc,
  ...
}:
let
  # The real built-in provisioning module (lib/compat/builtins.nix, wired into the flakeModule). Read with
  # dummy args: the `classes` values this suite reads are LITERALS, never forcing prelude/errors/declare (the
  # lazy `policies`/`deliverLib` bindings + the `imports` fleet-context stay unforced) — a regression guard on
  # the ACTUAL wiring, the unit twin of the ship-gate corpus re-probe.
  builtinsMod = import "${denHoagSrc}/lib/compat/builtins.nix" {
    prelude = { };
    errors = { };
    declare = { };
  };
  classesView = builtinsMod.config.den.classes;
  # the full v1 built-in class set this rung registers — each must be present + carry a description.
  builtinClassNames = [
    "flake-parts"
    "wsl"
    "maid"
    "hjem"
    "packages"
    "apps"
    "checks"
    "devShells"
    "legacyPackages"
  ];

  # ── a nixos host `igloo`; `withWsl` toggles a host-attached aspect emitting wsl content beside nixos ──
  # The mkDen UNIT path wires only `flakeModuleCore` — builtinsModule rides the OUTPUT `flakeModule` the
  # CORPUS imports (the ship-gate corpus re-probe is the end-to-end proof it provisions these classes), so
  # the fixture declares `den.classes.wsl` INLINE, byte-identically to how builtinsModule sets it (a bare
  # `{ description }`). This is the compat-flake-parts-class.nix precedent: the registration guard above reads
  # builtinsModule directly; the mkDen fixture mirrors its provisioning to exercise the classify+collect path.
  mk =
    withWsl:
    denCompat.mkDen [
      {
        den = {
          hosts.x86_64-linux.igloo.class = "nixos";
          classes.wsl.description = "wsl (inline mirror of builtins.nix provisioning)";
          aspects.hostc = {
            nixos.tag = "nixos-host";
          }
          // (if withWsl then { wsl.tag = "wsl-host"; } else { });
          schema.host.includes = [ "hostc" ];
        };
      }
    ];

  # every `tag` string reachable in a wrapped deferredModule (the gen-aspects `{ imports = [ … ]; }` form).
  tags =
    m:
    if builtins.isAttrs m then
      (if m ? tag then [ m.tag ] else [ ])
      ++ (if m ? imports then builtins.concatMap tags m.imports else [ ])
    else
      [ ];
  # the node's within-class content assembly at a class (graphAccessor.contentsOf — the classSubtreeAt read).
  bucketTags =
    fleet: id: class:
    builtins.concatMap tags (map (c: c.content) (fleet.den.output.graphAccessor.contentsOf id class));

  producing = mk true; # wsl content emitted → classifies + collects into the wsl bucket
  inert = mk false; # corpus-shape: NO wsl producer
  igloo = "host:igloo";

  ok = f: (builtins.tryEval (builtins.deepSeq f true)).success;
  forceEdges = f: builtins.concatMap (r: f.den.graph.edges r) (builtins.attrNames f.den.scopeRoots);

  # an aspect keying an arbitrary class-position name; a REGISTERED class (declared inline, mirroring
  # builtinsModule) classifies, an UNREGISTERED name still aborts at the §2.2 three-branch dispatch (R9).
  keyFleet =
    {
      key,
      register,
    }:
    denCompat.mkDen [
      {
        den = {
          hosts.x86_64-linux.igloo.class = "nixos";
          aspects.hostc = {
            nixos.tag = "x";
            ${key} = { };
          };
          schema.host.includes = [ "hostc" ];
        }
        // (if register then { classes.${key}.description = "reg"; } else { });
      }
    ];
in
{
  flake.tests.compat-builtin-classes = {
    # ── the ACTUAL builtins.nix registration (regression guard on the wiring, prelude-free) ─────────────
    # every v1 built-in this rung ports is present in `config.den.classes` and carries a description.
    test-builtins-registers-full-set = {
      expr = {
        registered = builtins.all (n: classesView ? ${n}) builtinClassNames;
        described = builtins.all (n: (classesView.${n}.description or "") != "") builtinClassNames;
      };
      expected = {
        registered = true;
        described = true;
      };
    };
    # `wsl` specifically — the u14 blocker's fix (the compat primary-user battery emits `wsl.defaultUser`).
    test-wsl-registered = {
      expr = classesView ? wsl && (classesView.wsl.description or "") != "";
      expected = true;
    };

    # ── SYNTHETIC: the registered `wsl` class CLASSIFIES + is PRODUCED into its bucket ───────────────────
    # a host-attached aspect emits `wsl` content; with `wsl` registered the key routes to classifyKey's CLASS
    # branch (no §2.2 abort) and the class-content assembly collects it — the bucket carries `wsl-host`.
    test-wsl-classifies-and-collects = {
      expr = {
        forces = ok (forceEdges producing);
        wslBucket = bucketTags producing igloo "wsl";
        nixosBucket = bucketTags producing igloo "nixos";
        registered = producing.den.classes ? wsl;
      };
      expected = {
        forces = true;
        wslBucket = [ "wsl-host" ];
        nixosBucket = [ "nixos-host" ];
        registered = true;
      };
    };

    # ── CORPUS-SHAPE COMPANION: NO wsl producer ⇒ NO wsl output, nothing else moved ─────────────────────
    # the SAME fleet without the wsl emitter: the wsl bucket is EMPTY (no producing member ⇒ no output), the
    # nixos content is byte-identical to the producing fixture (nothing else moved), and wsl stays registered.
    test-inert-companion-no-output-nothing-moved = {
      expr = {
        forces = ok (forceEdges inert);
        wslBucket = bucketTags inert igloo "wsl";
        nixosBucket = bucketTags inert igloo "nixos";
        stillRegistered = inert.den.classes ? wsl;
      };
      expected = {
        forces = true;
        wslBucket = [ ];
        nixosBucket = [ "nixos-host" ];
        stillRegistered = true;
      };
    };

    # ── the §2.2 abort posture stays LOUD for a genuinely-unknown class name (R9) ────────────────────────
    # a registered built-in (`maid`) classifies clean; a genuinely-unknown key still aborts — only the named
    # v1 built-ins were admitted, the three-branch strictness is intact.
    test-unknown-key-still-aborts = {
      expr = {
        maid = ok (
          forceEdges (keyFleet {
            key = "maid";
            register = true;
          })
        );
        devShells = ok (
          forceEdges (keyFleet {
            key = "devShells";
            register = true;
          })
        );
        unknown =
          !(ok (
            forceEdges (keyFleet {
              key = "totallyUnknownKey";
              register = false;
            })
          ));
      };
      expected = {
        maid = true;
        devShells = true;
        unknown = true;
      };
    };
  };
}
