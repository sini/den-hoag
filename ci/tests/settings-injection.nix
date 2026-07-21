# Axis-6 (§2.10 attribute 13 → the terminal) — the SETTINGS INJECTION SEAM. den's resolved
# settings-product (`resolved-settings`, attribute 13) was a standalone read-only accessor (`aspectsAt`);
# it never parameterised a built system. The gen-aspects demo INJECTS the resolved settings into
# parametric class content (`nixos = { settings, ... }: { … settings … }`), so settings PARAMETERISE the
# build. This suite pins that seam over ONE witness aspect (P5a is the seam, not the P5b per-host union):
#
#   • delivery       — the folded settings-product (the host-tier winner over the schema default) rides the
#                      terminal `bindings` set, MIRRORING path-B's `host` harvest: a sibling channel gen-bind's
#                      `wrapAll` partial-applies from. Read off the nixpkgs-free `collect` artifact.
#   • injection      — a `{ settings, … }` witness aspect's REAL materialised NixOS config reflects that
#                      folded settings-product (the sanctioned nixpkgs crossing, as end-to-end binds `host`).
#   • additivity     — a twin aspect that declares NO `settings` arg materialises unchanged: the seam is
#                      opt-in by the aspect DECLARING the arg (`wrapAll` `boundArgNames`), never forced.
{
  denHoag,
  nixpkgs,
  ...
}:
let
  # env ⊇ host axon; the witness aspect `svc` is included at the host (nixos producing class), so its
  # settings resolve AT the host node and its nixos content builds the host system. `nixpkgs` is threaded
  # only for the real crossing (the collect den passes it null and stays nixpkgs-free).
  mk =
    {
      body,
      withNixpkgs,
    }:
    denHoag.mkDen (
      [
        {
          config.den.schema = {
            env.parent = null;
            host.parent = "env";
          };
        }
        {
          config.den = {
            env.prod = { };
            host.axon = { };
          };
        }
        (
          { config, ... }:
          {
            config.den.membership = [
              {
                coords = {
                  env = config.den.env.prod;
                  host = config.den.host.axon;
                };
              }
            ];
          }
        )
        { config.den.contentClass.host = "nixos"; }
        (
          { config, ... }:
          {
            config.den.aspects.svc = {
              settings.level.default = "base"; # the schema default (replace strategy)
              nixos = body;
            };
            config.den.include = [
              {
                at = config.den.host.axon;
                aspects = [ config.den.aspects.svc ];
              }
            ];
            # a HOST-tier layer that wins over the default — the folded winner is the discriminator.
            config.den.settings.layers = [
              {
                at = {
                  host = config.den.host.axon;
                };
                of = config.den.aspects.svc;
                set = {
                  level = "won";
                };
              }
            ];
          }
        )
      ]
      ++ nixpkgsLib.optional withNixpkgs { config.den.nixpkgs = nixpkgs; }
    );

  nixpkgsLib = nixpkgs.lib;
  hostId = "host:axon@env:prod";

  # nixpkgs-free `collect` den: the delivery surface (`bindings`) + the folded settings-product, read
  # without crossing to a real NixOS eval.
  denCollect =
    (mk {
      body = { settings, ... }: { networking.domain = settings.level; };
      withNixpkgs = false;
    }).den;
  collectSys = denCollect.output.systems.nixos.${hostId};
  rsWitness = (denCollect.structural.eval.get hostId "resolved-settings").svc.value;

  # real-crossing dens: the witness consumes a `settings` arg; the twin declares none. `nixpkgs.hostPlatform`
  # lets the NixOS eval resolve (reading `networking.domain` never forces pkgs).
  witness = mk {
    body =
      { settings, ... }:
      {
        networking.domain = settings.level;
        nixpkgs.hostPlatform = "x86_64-linux";
      };
    withNixpkgs = true;
  };
  twin = mk {
    body = _: {
      networking.domain = "const";
      nixpkgs.hostPlatform = "x86_64-linux";
    };
    withNixpkgs = true;
  };
in
{
  flake.tests.settings-injection = {
    # ── the fold itself: host-tier winner over the schema default (the seam's input) ────────────────
    test-resolved-settings-host-tier-winner = {
      expr = rsWitness.level;
      expected = "won";
    };

    # ── delivery: the folded settings-product rides the terminal `bindings` set (wrapAll's source) ──
    test-bindings-carries-settings-key = {
      expr = collectSys.bindings ? settings;
      expected = true;
    };
    test-settings-delivered-to-bindings = {
      expr = collectSys.bindings.settings.level or "no-settings-binding";
      expected = "won";
    };

    # ── injection: the REAL materialised NixOS config reflects the folded settings-product (host-tier
    #    winner, not the default). Gated on the delivery surface so a pre-seam revert short-circuits
    #    (no crossing on an unbound `settings` arg) rather than diverging on module-arg resolution.
    test-witness-materialises-folded-settings = {
      expr =
        if collectSys.bindings ? settings then
          witness.nixosConfigurations.axon.config.networking.domain
        else
          "SEAM-ABSENT";
      expected = "won";
    };

    # ── additivity: the twin declares NO settings arg → materialises unchanged (opt-in by declaration).
    test-no-settings-arg-aspect-untouched = {
      expr = twin.nixosConfigurations.axon.config.networking.domain;
      expected = "const";
    };
  };
}
