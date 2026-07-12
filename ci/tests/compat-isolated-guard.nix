# §8 ISOLATION CEILING GUARD (#63 review note) — den v1 declares an `isolated` collection flag on every
# schema kind (pin 11866c16 modules/options.nix:85-88, default false; the one v1 reader is the scope
# walk's boundary stamp, handlers/push-scope.nix:64 — NOTHING sets the flag at the pin or in the corpus).
# den-hoag's #63 within-class subtree fold (`classSubtreeAt`, output-modules.nix) and the #62c
# delivery-edge subtree members are BLIND `scope.descendants` walks: an isolated kind would need those
# gathers to STOP at the isolation boundary v1's isolation-aware fold honors, else a descendant's class
# content silently OVER-GATHERS into the ancestor's assembly — a WRONG drv, not a crash (the worst
# failure mode). Until an isolation-aware walk lands, compat ingest refuses LOUD (`errors.
# isolatedKindUnsupported`, read off the RAW v1 schema in `buildSchema` — ingest.nix): a v1 fleet whose
# schema sets `isolated = true` on any kind aborts named at ingestion, never a silent mis-fold.
#
# Witnesses: (1) a synthetic v1 schema kind with `isolated = true` aborts (tryEval false) with the named
# message; (2) the clean companion — the SAME fleet with the flag absent (and with the v1 default
# `isolated = false` explicit) ingests + resolves end-to-end unchanged.
{ denCompat, ... }:
let
  # a nixos host + a custom `zone` kind (no instances — the guard is a DECLARATION check); `iso` sets the
  # kind's `isolated` flag: `true` (must abort), `false` (the v1 default, explicit — must pass), or null
  # (absent — the corpus shape, must pass).
  mk =
    iso:
    denCompat.mkDen [
      {
        den = {
          hosts.x86_64-linux.igloo.class = "nixos";
          schema.zone = {
            parent = "host";
          }
          // (if iso == null then { } else { isolated = iso; });
          aspects.hostc.nixos.tag = "nixos-host";
          schema.host.includes = [ "hostc" ];
        };
      }
    ];

  # forcing the built fleet's schema attr names forces `buildSchema`'s seq chain (the guard's seat).
  forceSchema = fleet: builtins.deepSeq (builtins.attrNames fleet.den.schema) true;
  tryForce = fleet: builtins.tryEval (forceSchema fleet);

  isolated = mk true;
  explicitFalse = mk false;
  absent = mk null;
in
{
  flake.tests.compat-isolated-guard = {
    # (1) `isolated = true` on an ingested v1 kind aborts LOUD at ingestion — never a silent blind-walk
    #     over-gather (§8 risk 2).
    test-isolated-true-aborts = {
      expr = (tryForce isolated).success;
      expected = false;
    };

    # (2a) clean companion — the flag ABSENT (the corpus shape): ingests clean, the host resolves
    #      end-to-end (nixosConfigurations non-empty), nothing else moved.
    test-absent-clean-e2e = {
      expr = {
        forces = (tryForce absent).success;
        nixosConfigs = builtins.attrNames (absent.nixosConfigurations or { });
        zoneKind = absent.den.schema ? zone;
      };
      expected = {
        forces = true;
        nixosConfigs = [ "igloo" ];
        zoneKind = true;
      };
    };
    # (2b) the v1 DEFAULT value explicit (`isolated = false`, options.nix:86) passes identically — the
    #      guard rejects only the true flag, not the field's presence.
    test-explicit-false-clean = {
      expr = (tryForce explicitFalse).success;
      expected = true;
    };
  };
}
