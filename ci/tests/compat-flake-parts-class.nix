# flake-parts CLASS registration (ship-gate rung, CLASS-A-MINIMAL; R2 compat-side class vocabulary).
# `flake-parts` is a v1 flake-level SCOPE class the corpus routes INTO — the `devshell-to-flake-parts`
# policy emits `route { fromClass = "devshell"; intoClass = "flake-parts"; path = ["devshells" "default"]; }`
# (corpus modules/den/classes/devshell.nix:16). That policy's empty formals fire it at every scope, so
# `translateDelivery` calls `resolveBucket "deliver" "flake-parts"` — which aborted `unknown class
# flake-parts` until the class was registered. `lib/compat/builtins.nix` now registers it through den-hoag's
# PUBLIC class registry (a bare `den.classes.flake-parts`, the general declared-classes surface, assembly
# §2.2; `entity.discoverClasses`) — the same compat-side mechanism os-class registers `os` with
# (legacy/batteries/os-class.nix:44-50). A bare declared class is INERT (no wrap/instantiate/share → no
# gen-flake crossing, collect-only) and never a PRODUCING class (no phantom fold edge); the flake-level
# devShells output family is NOT built this rung, so the routed content is LATENT (gate class F, board #51;
# ledger row B2). `flake-parts` is ALSO a schema KIND (builtins.nix `schema.flake-parts.isEntity`) — this
# suite pins that the KIND + CLASS registrations COEXIST, that the route fires without the deliver abort, and
# that the deliver abort posture stays LOUD for a genuinely-unknown class name.
{
  denCompat,
  denHoagSrc,
  ...
}:
let
  # The real built-in provisioning module (lib/compat/builtins.nix, wired into the flakeModule). Read with
  # dummy args: the `classes`/`schema` values this suite reads are literals, never forcing prelude/errors
  # (the lazy `policies`/`deliverLib` bindings stay unforced) — a regression guard on the ACTUAL wiring, the
  # unit-level twin of the ship-gate corpus re-probe (compat-builtins.nix's own convention: mechanisms unit,
  # provisioning end-to-end).
  builtinsMod = import "${denHoagSrc}/lib/compat/builtins.nix" {
    prelude = { };
    errors = { };
    # dummy `declare` — this suite reads only the static `config.den.classes` view; the fleet-context
    # enrichment (which forces `declare`) rides `imports`, never touched here (stays unforced).
    declare = { };
  };

  # A fleet reproducing the corpus emitter: the flake-parts KIND (isEntity) + a KIND-attached content-set
  # include on it (as the corpus's aspects/devshell/*.nix do), the flake-parts + devshell CLASSES, the
  # top-level `devshell-to-flake-parts` route policy (empty formals → fires everywhere → drives
  # resolveBucket), and a self-named host aspect so host:igloo carries real nixos content (R5 self-provide,
  # so the host resolves end-to-end). `denCompat.mkDen` applies the full legacy wiring (batteries auto-apply).
  mkFleet =
    intoClass:
    denCompat.mkDen [
      {
        config.den = {
          schema.flake-parts.isEntity = true;
          schema.flake-parts.includes = [
            {
              devshell = {
                commands = [ ];
              };
            }
          ];
          hosts.x86_64-linux.igloo.users.tux = { };
          classes = {
            devshell = { };
            flake-parts = {
              description = "fp";
            };
          };
          policies.devshell-to-flake-parts = _: [
            (denCompat.route {
              fromClass = "devshell";
              intoClass = intoClass;
              path = [
                "devshells"
                "default"
              ];
              adaptArgs = { config, ... }: config;
            })
          ];
          aspects.igloo = {
            nixos = {
              networking.hostName = "igloo";
            };
          };
        };
      }
    ];

  fleet = mkFleet "flake-parts";
  den = fleet.den;
  edges = builtins.concatMap (r: den.graph.edges r) (builtins.attrNames den.scopeRoots);
  devshellEdges = builtins.filter (e: (e.source.collected.class or null) == "devshell") edges;

  ok = e: (builtins.tryEval (builtins.deepSeq e true)).success;
  aborts = e: !(ok e);
  forceEdges = f: builtins.concatMap (r: f.den.graph.edges r) (builtins.attrNames f.den.scopeRoots);

  # An aspect CONTENT key `flake-parts` — self-named at host:igloo so its content is forced through
  # class-modules (classifyKey's three-branch dispatch). With flake-parts a registered class the key routes
  # to the CLASS branch; the schema-KIND registration alone would NOT admit it (kinds are not consulted by
  # classifyKey), so this pins the CLASS branch specifically. An unregistered key still aborts (R9).
  aspectKeyFleet =
    key:
    denCompat.mkDen [
      {
        config.den = {
          schema.flake-parts.isEntity = true;
          hosts.x86_64-linux.igloo.users.tux = { };
          classes.flake-parts = {
            description = "fp";
          };
          aspects.igloo.${key} = { };
        };
      }
    ];
in
{
  flake.tests.compat-flake-parts-class = {
    # ── the ACTUAL builtins.nix registration (regression guard on the wiring) ──────────────────────────
    # builtins.nix registers `den.classes.flake-parts` as a bare declared class carrying a description.
    test-builtins-registers-class = {
      expr = {
        registered = builtinsMod.config.den.classes ? flake-parts;
        described = (builtinsMod.config.den.classes.flake-parts.description or "") != "";
      };
      expected = {
        registered = true;
        described = true;
      };
    };
    # COEXISTENCE at the source: the SAME module carries flake-parts as BOTH a schema KIND (isEntity) and a
    # registered CLASS — disjoint config namespaces (`den.schema.*` vs `den.classes.*`), no collision.
    test-builtins-kind-and-class-coexist = {
      expr = {
        kind = builtinsMod.config.den.schema.flake-parts.isEntity or false;
        class = builtinsMod.config.den.classes ? flake-parts;
      };
      expected = {
        kind = true;
        class = true;
      };
    };

    # ── (a) the devshell → flake-parts route FIRES at a real host, NO deliver abort ────────────────────
    # Forcing the fleet edges (which drives resolveBucket at fire time) succeeds, and exactly one
    # devshell-sourced delivery edge materializes — the route resolved `flake-parts` instead of aborting.
    test-route-fires-no-abort = {
      expr = {
        forces = ok edges;
        devshellDeliveries = builtins.length devshellEdges;
      };
      expected = {
        forces = true;
        devshellDeliveries = 1;
      };
    };
    # the delivery edge targets the flake-parts CLASS at the host root, nesting at devshells.default (the
    # route's path) — the route materialized to the declared placement, not a dropped/misrouted no-op.
    test-delivery-target-is-flake-parts = {
      expr =
        let
          e = builtins.head devshellEdges;
        in
        {
          target = e.target.class or null;
          mode = e.mode or null;
          path = e.path or null;
        };
      expected = {
        target = "flake-parts";
        mode = "nest";
        path = [
          "devshells"
          "default"
        ];
      };
    };

    # ── (b) coexistence: KIND-include list still processes + aspect content key routes to the class bucket ─
    # The kind-attached `den.schema.flake-parts.includes` content-set (a devshell content set) processes
    # cleanly alongside the class registration — the main fleet (which carries it) forces without abort.
    test-kind-include-still-processes = {
      expr = ok edges;
      expected = true;
    };
    # flake-parts is present as BOTH a kind and a class in the BUILT fleet (den-hoag mkDen output).
    test-built-fleet-kind-and-class = {
      expr = {
        kind = den.schema ? flake-parts;
        class = den.classes ? flake-parts;
      };
      expected = {
        kind = true;
        class = true;
      };
    };
    # an aspect CONTENT key `flake-parts` classifies (CLASS branch) — no unknown-key abort; a genuinely
    # unknown key still aborts (R9 three-branch strictness). The class branch, NOT the kind, admits it.
    test-aspect-flake-parts-key-classifies = {
      expr = {
        flakeParts = ok (forceEdges (aspectKeyFleet "flake-parts"));
        unknown = aborts (forceEdges (aspectKeyFleet "totallyUnknownKey"));
      };
      expected = {
        flakeParts = true;
        unknown = true;
      };
    };

    # ── (c) the deliver abort posture stays LOUD for a genuinely-unknown class name ─────────────────────
    # Registering flake-parts did not relax resolveBucket: a route into an unregistered class still aborts
    # (C6 loud fall-through unchanged) — only the ONE named class was admitted.
    test-unknown-class-still-aborts = {
      expr = aborts (forceEdges (mkFleet "totally-unknown-class"));
      expected = true;
    };

    # ── (d) host resolution clean end-to-end WITH the route firing ─────────────────────────────────────
    # The self-named host aspect resolves at host:igloo and the nixos terminal lists the host — the fleet
    # resolves end-to-end (nixosConfigurations non-empty) while the flake-parts route fires in the same eval.
    test-host-resolution-clean-e2e = {
      expr = {
        resolved = map (n: n.key) (den.structural.eval.get "host:igloo" "resolved-aspects");
        nixosConfigs = builtins.attrNames (fleet.nixosConfigurations or { });
      };
      expected = {
        resolved = [ "igloo" ];
        nixosConfigs = [ "igloo" ];
      };
    };
  };
}
