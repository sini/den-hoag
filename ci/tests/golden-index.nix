# The risk-register golden INVENTORY (spec §6 register) — a single self-documenting enumeration that the
# seven NAMED goldens exist. Each risk-register item is pinned by a named golden test; this index asserts
# every one is PRESENT in the suite source (the zero-machinery.nix `readFile` token-scan precedent — a
# tripwire, not a proof: it catches a golden being renamed or deleted, forcing a visible edit here). The
# goldens themselves live in their topical suites (order-instances / edge-substrate / projection-routes);
# this file is the register's checklist. See REFERENCE.md.
{
  denHoagSrc,
  genPrelude,
  ...
}:
let
  inherit (genPrelude) hasInfix; # the stack-safe splitString-based infix scan (the boundary.nix precedent)
  read = f: builtins.readFile "${denHoagSrc}/ci/tests/${f}";
  # the seven risk-register goldens: { item; name; file } — the name is the test attr, the file its home.
  register = [
    {
      item = "1 — dedup appliesTo scope (three-cells structural multiplicity, u24 exemption)";
      name = "test-golden-reach-structural-multiplicity";
      file = "order-instances.nix";
    }
    {
      item = "2 — keep-direction per-channel declared dedup";
      name = "test-golden-collections-keep-first";
      file = "order-instances.nix";
    }
    {
      item = "3 — env-tier least-specific-first";
      name = "test-golden-settings-env-tier-least-specific-first";
      file = "order-instances.nix";
    }
    {
      item = "4 — trace key K rendered only for non-legacy kinds (SHIPPED step 2)";
      name = "test-K-boundary-unstamped-vs-demand";
      file = "edge-substrate.nix";
    }
    {
      item = "5 — A12 identity stays aspect id_hash";
      name = "test-golden-a12-identity-is-id-hash";
      file = "order-instances.nix";
    }
    {
      item = "6 — new-laws disciplines opt-in for new channels only (no silent strengthening)";
      name = "test-golden-new-laws-opt-in-current-laws";
      file = "order-instances.nix";
    }
    {
      item = "7 — delivery-order own-scope-then-parent-targeted";
      name = "test-golden-delivery-order-own-scope-before-parent-targeted";
      file = "projection-routes.nix";
    }
  ];
  # an entry is present iff its named test attr (`<name> =`) appears in its home file's source text.
  presence = map (e: {
    inherit (e) item name file;
    present = hasInfix "${e.name} =" (read e.file);
  }) register;
  missing = builtins.filter (e: !e.present) presence;
in
{
  flake.tests.golden-index = {
    # every risk-register golden is present in its home suite (a rename/deletion fails here — the register
    # is the seven-item checklist; adding an item forces a visible edit to `register`).
    test-all-seven-goldens-present = {
      expr = map (e: e.name) missing;
      expected = [ ];
    };
    # the register enumerates exactly seven items (the spec §6 count) — a self-documenting inventory pin.
    test-register-count-is-seven = {
      expr = builtins.length register;
      expected = 7;
    };
    # the named inventory, item → golden (self-documentation: the goldens by risk-register number).
    test-register-names = {
      expr = map (e: e.name) register;
      expected = [
        "test-golden-reach-structural-multiplicity"
        "test-golden-collections-keep-first"
        "test-golden-settings-env-tier-least-specific-first"
        "test-K-boundary-unstamped-vs-demand"
        "test-golden-a12-identity-is-id-hash"
        "test-golden-new-laws-opt-in-current-laws"
        "test-golden-delivery-order-own-scope-before-parent-targeted"
      ];
    };
  };
}
