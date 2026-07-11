# M2.5 — CHANNEL-BINDING TOTALITY at the terminal (spec: the terminal-contract binding law).
#
# THE NATIVE LAW: a REGISTERED channel is a named binding surface whose collected value at any node
# is TOTAL — the EMPTY collection when nothing is emitted there, analogous to an option's default.
# gen-bind's `wrapAll` binds a module arg iff the binding KEY exists, so before totality a class
# module destructuring a channel arg (the corpus's firewall-collector / secrets-collector shape,
# included on EVERY host via `den.schema.host.includes`) at a node with zero emissions was called
# without its required argument — at the first FORCING terminal only (the real nixosSystem crossing;
# the `collect` terminal never forces the module fn, which is why the gap stayed latent until the
# M2.5 corpus drvPath attempt). den v1 parity CONFIRMS the law (pin 11866c16
# assemble-pipes.nix:951 `lib.genAttrs pipeNames`); it is not its source.
#
# Four witnesses over one two-channel fleet (`fw` never emitted anywhere; `sec` emitted by a second
# aspect at the same host):
#   1. collect-level totality — the nixpkgs-free `collect` terminal's `bindings` carries BOTH
#      registered channels as keys, the never-emitted one as `[ ]` (fails-before: key absent).
#   2. collect-level value — the emitted channel's binding carries the emission (the true branch,
#      unchanged by the fix).
#   3. crossing zero-emission force (the M2.5 regression, firewall shape) — the REAL nixosSystem
#      crossing forces the consumer with `fw = [ ]` instead of throwing
#      `called without required argument 'fw'` (fails-before: that exact throw).
#   4. crossing emitted force (the age-secrets mirror rides the same consumer: `sec` carries its
#      emission through the same crossing).
{
  denHoag,
  nixpkgs,
  ...
}:
let
  # ── the fixture fleet: one nixos host, two registered channels, one bare-arg consumer ────────────
  # `collector` destructures BOTH channels as module args (the corpus collector shape). `fw` has no
  # emitter anywhere (the totality case); `sec` is emitted by `emitter` at the same host (the value
  # case). `networking.domain` renders both list lengths so ONE forced read witnesses both.
  fleet =
    withNixpkgs:
    [
      {
        config.den.schema = {
          env.parent = null;
          host.parent = "env";
          user.parent = "host";
        };
      }
      {
        config.den = {
          env.prod = { };
          host.bare = { };
        };
      }
      (
        { config, ... }:
        {
          config.den.membership = [
            {
              coords = {
                env = config.den.env.prod;
                host = config.den.host.bare;
              };
            }
          ];
        }
      )
      { config.den.contentClass.host = "nixos"; }
      {
        config.den.quirks = {
          fw = { };
          sec = { };
        };
      }
      (
        { config, ... }:
        {
          config.den.aspects.collector.nixos =
            { fw, sec, ... }:
            {
              networking.hostName = "bare";
              networking.domain = "fw${toString (builtins.length fw)}-sec${toString (builtins.length sec)}";
              nixpkgs.hostPlatform = "x86_64-linux";
            };
          # corpus-faithful emission shape: one attrset FRAGMENT per aspect (a list-valued plain
          # emission rides as ONE binding entry here — v1 auto-flattens those; the corpus emits
          # attrset fragments on both bare-arg channels, so the flatten question is out of scope).
          config.den.aspects.emitter.sec = {
            port = 22;
          };
          config.den.include = [
            {
              at = config.den.host.bare;
              aspects = [
                config.den.aspects.collector
                config.den.aspects.emitter
              ];
            }
          ];
        }
      )
    ]
    ++ (if withNixpkgs then [ { config.den.nixpkgs = nixpkgs; } ] else [ ]);

  # The pure arm: no `den.nixpkgs` ⇒ the `collect` terminal — its returned record EXPOSES `bindings`,
  # so the totality is asserted directly, forcing no module fn.
  pure = denHoag.mkDen (fleet false);
  collectBindings = pure.den.output.systems.nixos."host:bare".bindings;

  # The crossing arm: `den.nixpkgs` ⇒ crossNixos — reading `networking.domain` forces the consumer
  # through the real module fixpoint (the wrapAll partial application MUST supply both channel args).
  crossed = denHoag.mkDen (fleet true);
in
{
  flake.tests.binding-totality = {
    # (1) totality: the never-emitted registered channel is PRESENT and EMPTY at the collect terminal.
    test-collect-never-emitted-channel-is-present-empty = {
      expr = [
        (collectBindings ? fw)
        collectBindings.fw
      ];
      expected = [
        true
        [ ]
      ];
    };
    # (2) value: the emitted channel's binding carries the emission (true branch unchanged).
    test-collect-emitted-channel-carries-value = {
      expr = collectBindings.sec;
      expected = [ { port = 22; } ];
    };
    # (3)+(4) the M2.5 regression at the REAL crossing: zero-emission `fw` binds `[ ]` (no
    # `called without required argument 'fw'`), emitted `sec` binds its one entry — both forced
    # through one read of the built system's config.
    test-crossing-forces-bare-arg-consumer-with-totality = {
      expr = crossed.nixosConfigurations.bare.config.networking.domain;
      expected = "fw0-sec1";
    };
  };
}
