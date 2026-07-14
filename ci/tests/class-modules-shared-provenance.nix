# class-modules SHARED-VS-OWN PROVENANCE (Track A rung 1, R-ROOT-FILTER prerequisite). The #74a member
# gather doubles a home-manager option declared at BOTH host and user scope (the corpus spicetify abort,
# ledger u25); the v1 fix (`filterRootModules`, route.nix:532-552) restricts a delivery's ANCESTOR-scope
# class content to the `den.default`-SHARED modules, dropping the ancestor's scope-OWN copies. That
# restriction needs a shared-vs-own MARKER on each class-modules entry — this suite pins the marker
# (A2 consumes it). The signal is the resolved node's `__denShared` flag: a node ROOTS or DESCENDS the
# radiated `den.default` (reserved `__default`) subtree ⇒ shared; a scope-own include ⇒ own. The marker
# rides class-modules as the `__shared` sidecar (`{ <class> = [ <bool> ]; }`, positionally aligned with
# each class bucket) — PURELY ADDITIVE: the public `.${class}` bucket stays byte-identical.
#
# The derivation is on `aspect.key` / the reserved `__default` identity, NOT `__provider` (Track B is
# retiring that shadow). Native fleets set no `den.default`, so `sharedAspectKeys = [ ]` and every entry
# is own (the sidecar is inert all-`false`).
{ denCompat, ... }:
let
  keysAt = den: id: map (n: n.key) (den.structural.eval.get id "resolved-aspects");
  sharedFlagsAt =
    den: id: map (n: n.__denShared or false) (den.structural.eval.get id "resolved-aspects");
  cmAt = den: id: den.structural.eval.get id "class-modules";
  mk = fx: (denCompat.mkDen [ fx ]).den;

  # A `den.default`-radiated aspect (`shareaspect`, transitively under `default.includes` — the shared
  # subtree, v1's `@default` suffix) vs a scope-OWN host aspect (`ownaspect`, included at host `h1`). Both
  # emit ONE nixos-class module, so the host's nixos bucket carries both and the sidecar distinguishes.
  # Navigated includes (`with den.aspects; [ … ]`) carry content — the identity-bearing include path.
  fixture = mk (
    { den, ... }:
    {
      den.default.includes = with den.aspects; [ shareaspect ];
      den.aspects.shareaspect.nixos.marker.shared = true;
      den.aspects.ownaspect.nixos.marker.own = true;
      den.aspects.h1.includes = with den.aspects; [ ownaspect ];
      den.hosts.x86_64-linux.h1.class = "nixos";
    }
  );

  # A fleet with NO `den.default` — no radiation, so every resolved node is own (the marker is inert).
  noDefault = mk (
    { den, ... }:
    {
      den.aspects.solo.nixos.marker.solo = true;
      den.aspects.h1.includes = with den.aspects; [ solo ];
      den.hosts.x86_64-linux.h1.class = "nixos";
    }
  );
in
{
  flake.tests.class-modules-shared-provenance = {
    # The radiated (`__default` + its transitive `shareaspect`) nodes are SHARED; the scope-own `h1`
    # entity aspect and its `ownaspect` include are OWN. (Order = resolved-aspects resolution order.)
    test-node-shared-flag = {
      expr = {
        keys = keysAt fixture "host:h1";
        shared = sharedFlagsAt fixture "host:h1";
      };
      expected = {
        keys = [
          "h1"
          "ownaspect"
          "__default"
          "shareaspect"
        ];
        shared = [
          false
          false
          true
          true
        ];
      };
    };

    # The `__shared` sidecar exists on the class-modules value, positionally aligned with the nixos
    # bucket: two entries (ownaspect, shareaspect), flags [own, shared]. The public bucket is unchanged.
    test-shared-sidecar-aligned = {
      expr =
        let
          cm = cmAt fixture "host:h1";
        in
        {
          nixosLen = builtins.length cm.nixos;
          sharedNixos = cm.__shared.nixos;
        };
      expected = {
        nixosLen = 2;
        sharedNixos = [
          false
          true
        ];
      };
    };

    # A `den.default`-free fleet marks every entry OWN — the sidecar is present but inert (the
    # byte-identical native path: no aspect is radiated-shared).
    test-no-default-all-own = {
      expr =
        let
          cm = cmAt noDefault "host:h1";
        in
        {
          shared = sharedFlagsAt noDefault "host:h1";
          sidecar = cm.__shared.nixos;
        };
      expected = {
        shared = [
          false
          false
        ];
        sidecar = [ false ];
      };
    };
  };
}
