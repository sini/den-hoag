# Phase 1 (den-hoag class-projection over the resolved-aspect graph, spec §2) — THE EDGE MODEL.
#
# Task 1: the edge-DECLARATION reads. `resolved-aspects.nix` exposes `reachEdgesOf`/`reachSuppressOf`,
# pure list functions over a node's `resolutionActs` (the resolution stratum of `declarations`), mirroring
# the existing `policyEdgeAspects` (`__action == "edge"`) / `constraintSeen` (`__action == "drop"`) reads:
#   - `reachEdgesOf` filters `__action == "reach-edge"` → `[ { target; classFilter ? null; } ]` (the
#     POSITIVE cross-scope reachability edge: target resolves to another node, optionally class-scoped, F9).
#   - `reachSuppressOf` filters `__action == "reach-suppress"` → `[ { edge; when; } ]` (the NEGATIVE /
#     suppression edge, F3-exclude / u21: `edge` = the positive edge to remove, `when` = a scope predicate).
#   - No edge decls ⇒ `[ ]` both (additive identity — Phase 1 is unread by any consumer).
#
# UNIT read: the helpers use only `map`/`builtins.filter`/`inherit`, no `prelude`/instance args — so the
# module is imported with DUMMY first-stage deps and `{ }` instance args (the compat-builtin-classes.nix
# prelude-free precedent), and the helpers are called on a SYNTHETIC `resolutionActs` list authored inline
# in the `reach-edge`/`reach-suppress` action shape (`{ __action = "reach-edge"; target; classFilter; }`).
{ denHoagSrc, ... }:
let
  ra = import "${denHoagSrc}/lib/attributes/resolved-aspects.nix" {
    prelude = { };
    scope = { };
    resolve = { };
    aspects = { };
    select = { };
  } { };

  # A synthetic resolution-action list: one positive reach-edge (class-scoped homeManager), one negative
  # reach-suppress (droid-gated), and unrelated actions (an `edge`/`drop` from the existing strata) the
  # reads MUST ignore — proving the filter selects on `__action` exactly.
  whenDroid = scope: (scope.host.class or null) == "droid";
  acts = [
    {
      __action = "reach-edge";
      target = "host:igloo";
      classFilter = "homeManager";
    }
    {
      __action = "reach-edge";
      target = "host:cabin";
      # classFilter omitted ⇒ null (all classes).
    }
    {
      __action = "reach-suppress";
      edge = "user-to-host";
      when = whenDroid;
    }
    {
      __action = "edge";
      aspect = {
        key = "unrelated-policy-edge";
      };
    }
    {
      __action = "drop";
      aspect = {
        key = "unrelated-drop";
      };
    }
  ];
in
{
  flake.tests.reach-graph = {
    # ── Task 1 (a): reachEdgesOf reads the positive edges — target + classFilter, defaulting null. The
    #    `edge`/`drop`/`reach-suppress` actions are ignored (filter on `__action == "reach-edge"`). ──
    test-reach-edges-of = {
      expr = ra.reachEdgesOf acts;
      expected = [
        {
          target = "host:igloo";
          classFilter = "homeManager";
        }
        {
          target = "host:cabin";
          classFilter = null;
        }
      ];
    };

    # ── Task 1 (b): reachSuppressOf reads the negative edges — { edge; when } — ignoring the others. The
    #    `when` predicate is carried through as-is (a function); assert it fires on a droid scope only. ──
    test-reach-suppress-of = {
      expr =
        let
          s = ra.reachSuppressOf acts;
          only = builtins.head s;
        in
        {
          count = builtins.length s;
          edge = only.edge;
          firesOnDroid = only.when { host.class = "droid"; };
          firesOnNixos = only.when { host.class = "nixos"; };
        };
      expected = {
        count = 1;
        edge = "user-to-host";
        firesOnDroid = true;
        firesOnNixos = false;
      };
    };

    # ── Task 1 (c): additive identity — no edge declarations ⇒ [ ] for both reads. ──
    test-no-edge-decls-identity = {
      expr = {
        edges = ra.reachEdgesOf [ ];
        suppress = ra.reachSuppressOf [ ];
        # a list carrying ONLY unrelated strata is also empty for both reads.
        edgesFromUnrelated = ra.reachEdgesOf [
          {
            __action = "edge";
            aspect = {
              key = "x";
            };
          }
          {
            __action = "drop";
            aspect = {
              key = "y";
            };
          }
        ];
      };
      expected = {
        edges = [ ];
        suppress = [ ];
        edgesFromUnrelated = [ ];
      };
    };
  };
}
