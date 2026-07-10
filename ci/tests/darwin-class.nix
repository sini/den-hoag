# Darwin native output class (assembly spec §2.10) — `darwin` is a BUILT-IN output class, PEER to `nixos`
# (a macOS system type: it crosses nix-darwin's `darwinSystem` and produces `darwinConfigurations`, exactly
# as `nixos` crosses nixpkgs and produces `nixosConfigurations`). This suite pins the REGISTRATION + the
# output face WITHOUT a real nix-darwin crossing (the nixpkgs-free `collect` terminal — den-hoag's own CI
# path): a host kind whose content class is `darwin` folds `darwin`-keyed aspect content into the darwin
# bucket and surfaces at `darwinConfigurations.<host>`, disjoint from `nixosConfigurations`. The real
# `crossDarwin` crossing (nix-darwin's `lib.darwinSystem`) is exercised at the ship-gate (`den.darwin`
# supplied against a corpus carrying a nix-darwin input), never in-repo — the same dev-time-only status as
# the full-fleet P2 drv-hash arm.
#
# WHY CORE, NOT COMPAT: darwin is not legacy vocabulary — it is a genuine system output class a native
# den v2 fleet targets on macOS. The legacy os-class battery's elem-gate `[nixos darwin]` merely ALSO
# routes to it; the registration itself lives in core (`lib/default.nix` classNames + the crossings map),
# so a pure den v2 fleet gets `darwinConfigurations` with zero compat surface.
{ denHoag, ... }:
let
  # Two OS-system kinds so BOTH output faces are exercised side-by-side: `machine` → darwin, `server` →
  # nixos. Both are scope ROOTS (parent = null), so each carries its own class content at its root node.
  schema = {
    config.den.schema = {
      machine.parent = null;
      server.parent = null;
    };
  };
  fleet = denHoag.mkDen [
    schema
    {
      config.den = {
        machine.mac1 = { };
        server.box1 = { };
        # per-kind producing class — `machine` produces darwin, `server` produces nixos.
        contentClass.machine = "darwin";
        contentClass.server = "nixos";
        aspects.macApp = {
          darwin = {
            marker = "d";
          };
        };
        aspects.srvApp = {
          nixos = {
            marker = "n";
          };
        };
      };
    }
    (
      { config, ... }:
      {
        config.den.include = [
          {
            at = config.den.machine.mac1;
            aspects = [ config.den.aspects.macApp ];
          }
          {
            at = config.den.server.box1;
            aspects = [ config.den.aspects.srvApp ];
          }
        ];
      }
    )
  ];
  den = fleet.den;
  eval = den.structural.eval;
  darwinBucket = (eval.get "machine:mac1" "class-modules").darwin or [ ];
  nixosBucket = (eval.get "server:box1" "class-modules").nixos or [ ];
in
{
  flake.tests.darwin-class = {
    # darwin is a registered built-in class — it carries a class ENTRY (identity law A2) in the fleet's
    # class-tag vocabulary, alongside nixos / home-manager / k8s-manifests.
    test-darwin-registered = {
      expr = (den.classes.darwin.name or null) == "darwin";
      expected = true;
    };
    # a `darwin`-keyed aspect content bucket CLASSIFIES (three-branch dispatch, registered-class branch) and
    # folds into the darwin bucket at the darwin host's scope node — the M2 close of "darwin aborts at
    # resolveBucket" (a darwin key aborted named before registration, R9's no-strictness-escape).
    test-darwin-content-assembles = {
      expr = builtins.length darwinBucket >= 1;
      expected = true;
    };
    # the `darwinConfigurations` output face is host-name-keyed (collect artifact — forcing the SPINE counts
    # darwin hosts without building any system, per-member lazy A17), the darwin twin of nixosConfigurations.
    test-darwin-configurations-face = {
      expr = {
        hasMac = fleet.darwinConfigurations ? mac1;
        noBox = !(fleet.darwinConfigurations ? box1);
      };
      expected = {
        hasMac = true;
        noBox = true;
      };
    };
    # the two OS faces are DISJOINT by producing class: a nixos host rides `nixosConfigurations`, NEVER
    # `darwinConfigurations`, and vice-versa (the class-major spine partitions members by content class).
    test-faces-disjoint = {
      expr = {
        nixosHasBox = fleet.nixosConfigurations ? box1;
        nixosNoMac = !(fleet.nixosConfigurations ? mac1);
      };
      expected = {
        nixosHasBox = true;
        nixosNoMac = true;
      };
    };
    # nixos still assembles alongside — adding darwin to the core class set is additive, no regression.
    test-nixos-unaffected = {
      expr = builtins.length nixosBucket >= 1;
      expected = true;
    };
  };
}
