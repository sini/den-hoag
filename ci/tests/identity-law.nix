# Task 3 — the A2 identity-law surface (spec §7). Every entry-typed declaration constructor
# rejects a "kind:name" scope-string OR a provenance `rendered` display value, taking only a
# registry entry (carrying id_hash). The check is EAGER, so `builtins.tryEval` over the bare
# constructor call catches it (no deep force needed). Entry-valued calls succeed and carry the
# entry through. Entries come from a real built den (host/user/env registries carry id_hash);
# aspects arrive with the aspect concern (Task 4), so a host entry stands in for `edge` here —
# `edge` only asserts id_hash presence, which every entry satisfies.
{ denHoag, ... }:
let
  fx = import ./_fixtures/fleet.nix;
  declare = denHoag.declare;
  den = (denHoag.mkDen fx.base).den;

  hostEntry = den.registries.host.axon; # carries id_hash
  userEntry = den.registries.user.alice;
in
{
  flake.tests.identity-law = {
    # (a) — a "kind:name" scope-string in an entry position aborts (named error).
    test-edge-string-aborts = {
      expr = (builtins.tryEval (declare.edge "aspect:theme")).success;
      expected = false;
    };
    test-member-string-dim-aborts = {
      expr =
        (builtins.tryEval (
          declare.member {
            user = "user:alice";
            host = hostEntry;
          }
        )).success;
      expected = false;
    };
    test-configure-string-aborts = {
      expr =
        (builtins.tryEval (
          declare.configure {
            of = "aspect:app";
            set = { };
          }
        )).success;
      expected = false;
    };

    # (b) — the entry-valued forms succeed and carry the entry through by id_hash.
    test-edge-entry-succeeds = {
      expr = (declare.edge hostEntry).aspect.id_hash == hostEntry.id_hash;
      expected = true;
    };
    test-member-entries-succeed = {
      expr =
        (declare.member {
          user = userEntry;
          host = hostEntry;
        }).coords.user.id_hash == userEntry.id_hash;
      expected = true;
    };
    test-configure-entry-succeeds = {
      expr =
        (declare.configure {
          of = hostEntry;
          set = {
            x = 1;
          };
        }).of.id_hash == hostEntry.id_hash;
      expected = true;
    };

    # (c) — a provenance `rendered` display string ("alice@axon") never round-trips as input.
    test-rendered-not-accepted = {
      expr = (builtins.tryEval (declare.edge "alice@axon")).success;
      expected = false;
    };
  };
}
