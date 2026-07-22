# #62a — the core PER-NODE CHANNEL-AUGMENTATION seam (`den.channelGather`, output-modules.nix
# `channelBindingsAt`). A supplier augments the channel value bound to a class module's formals with
# contributions GATHERED from beyond the node's own emissions: `channelGather result id ->
# { <channel> = [ contribution ]; }` (curried on `result`, applied per node), appended AFTER the node's
# local emissions per channel (F4: bound =
# local ++ gathered — the v1 `mkCombinedBase markedBase ++ markedExposed` shape, assemble-pipes.nix:935-948).
# This slice is the CORE seam ALONE (hand-supplied hook); the compat expose twin that fills it is #62b.
#
# THE IDENTITY LAW: the native default supplier (`_: { }`) makes the binding surface byte-identical to the
# pre-seam own-emissions path — proved by the `identity` companion below AND by the 810 baseline tests
# passing UNCHANGED. Two witnesses over one native fleet (synthetic `unit` kind, nixpkgs-free `collect`
# terminal so `.bindings` is read directly, no module fixpoint forced):
#   • augmented — a hand-supplied gather appends a gathered value AFTER the node's own emission on that
#     channel (`local ++ gathered`), and TOTALITY holds: a channel the node NEVER emits locally but the
#     gather supplies is PRESENT (not dropped by an own-emissions-only key set) — the corpus `resolved-users`
#     -at-a-host shape.
#   • identity — the SAME fleet with NO gather hook: the binding is the node's own emission alone.
{ denHoag, ... }:
let
  # A native fleet: one `unit`-kind root producing nixos content, one registered channel `ch` it emits to,
  # and a second channel `recv` it NEVER emits (the totality case). `gather` (or null) is the only variable.
  base =
    gather:
    [
      { config.den.schema.unit.parent = null; }
      { config.den.unit.u1 = { }; }
      { config.den.contentClass.unit = "nixos"; }
      {
        config.den.quirks = {
          ch = { };
          recv = { };
        };
      }
      (
        { config, ... }:
        {
          # emits `ch = [ "own" ]`; the nixos body destructures BOTH channels (so both are bound surfaces).
          config.den.aspects.emit = {
            ch = [ "own" ];
            nixos =
              { ch, recv, ... }:
              {
                networking.hostName = "u1";
                nixpkgs.hostPlatform = "x86_64-linux";
              };
          };
          config.den.include = [
            {
              at = config.den.unit.u1;
              aspects = [ config.den.aspects.emit ];
            }
          ];
        }
      )
    ]
    ++ (if gather == null then [ ] else [ { config.den.channelGather = gather; } ]);

  # The hand-supplied supplier: at `unit:u1`, append a plain gathered value to `ch` AND supply the
  # never-emitted `recv` (the totality path — a gather-only channel must survive into the binding).
  gatherHook =
    result: id:
    if id == "unit:u1" then
      {
        ch = [
          {
            deferred = false;
            value = "gathered";
          }
        ];
        recv = [
          {
            deferred = false;
            value = "only-gathered";
          }
        ];
      }
    else
      { };

  withGather = denHoag.mkDen (base gatherHook);
  identity = denHoag.mkDen (base null);

  bindingsOf = den: den.den.output.systems.nixos."unit:u1".bindings;
in
{
  flake.tests.channel-gather-seam = {
    # (1) local ++ gathered: the node's own `ch` emission FIRST, the gathered value appended after it.
    test-augment-appends-gathered-after-local = {
      # #74b: the bound value list is FLAT (v1 flattenAndExtract — a LIST emission spreads).
      expr = (bindingsOf withGather).ch;
      expected = [
        "own"
        "gathered"
      ];
    };
    # (2) totality: a channel the node never emits locally is present when the gather supplies it.
    test-gather-only-channel-is-present = {
      expr = (bindingsOf withGather).recv;
      expected = [ "only-gathered" ];
    };
    # (3) identity companion: absent hook ⇒ own emission alone (`ch`), and the never-emitted `recv` is
    #     the empty registered-channel default — byte-identical to the pre-seam own-emissions surface.
    test-identity-default-is-own-emissions = {
      expr = {
        ch = (bindingsOf identity).ch;
        recv = (bindingsOf identity).recv;
      };
      expected = {
        ch = [ "own" ]; # flat (v1 flattenAndExtract, #74b)
        recv = [ ];
      };
    };
  };
}
