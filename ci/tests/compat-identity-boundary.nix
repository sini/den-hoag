# compat-identity-boundary (C6 / A2) — the ingestion boundary is the ONE place v1 name-strings become
# id_hash-bearing registry entries, exactly once. This suite proves three things:
#   (a) runtime probe — every value in an ENTITY position of `compile`'s output carries `id_hash`;
#   (b) source lint — no `"<kind>:<name>"` scope-string is CONSTRUCTED in the shim core (`}:${` idiom),
#       so a string never rides onward past the boundary (`legacy/` + `errors.nix` are exempt — the
#       legacy modules compare v1 name keys internally, errors render strings for messages, both legal);
#   (c) boundary behaviour — a two-level `den.hosts.<sys>.<name>` path compiles to an entry-valued
#       reference, and a raw string handed to a den-hoag entry position aborts named (A2), never rides.
{
  denCompat,
  denHoag,
  denHoagSrc,
  nixpkgsLib,
  ...
}:
let
  # A fixture with a real cell: host axon + user alice (a `host.users` member), so membership carries
  # entity-valued coords (both entities declared ⇒ both id_hash-bearing).
  fixture = {
    hosts.x86_64-linux.axon = {
      class = "nixos";
      users.alice = { };
    };
  };
  compiled = denCompat.compile fixture;

  # (a) every entity position: the flat registries + every membership coordinate.
  entityPositions = [
    compiled.entities.registries.host.axon
    compiled.entities.registries.user.alice
  ]
  ++ builtins.concatMap (m: [
    m.coords.host
    m.coords.user
  ]) compiled.entities.membership;
  allEntities = builtins.all (v: builtins.isAttrs v && v ? id_hash) entityPositions;

  # (b) the string-passing lint over the shim CORE (legacy/ + errors.nix exempt). `}:${` is the exact
  # bytes of joining two interpolations with a colon — den-hoag's `"${kind}:${name}"` scope-string
  # idiom. The core desugars to entries, so it must never build one.
  coreFiles = [
    "default.nix"
    "ingest.nix"
    "compile.nix"
    "deliver.nix"
    "flake-module.nix"
  ];
  readCore = f: builtins.readFile "${denHoagSrc}/lib/compat/${f}";
  scopeStringOffenders = builtins.filter (f: nixpkgsLib.hasInfix "}:\${" (readCore f)) coreFiles;
in
{
  flake.tests.compat-identity-boundary = {
    # (a) runtime probe — no bare string survived to an entity position.
    test-all-entity-positions-have-id-hash = {
      expr = allEntities;
      expected = true;
    };

    # (b) source lint — the core constructs no scope-string.
    test-no-scope-string-in-core = {
      expr = scopeStringOffenders;
      expected = [ ];
    };

    # (c) a host referenced by its two-level path is entry-valued, not a name string.
    test-host-reference-is-entry = {
      expr =
        (compiled.entities.registries.host.axon ? id_hash)
        && !(builtins.isString compiled.entities.registries.host.axon);
      expected = true;
    };
    # ...and that entry is what membership binds (the reference did not degrade to a string).
    test-membership-binds-entry = {
      expr =
        (builtins.head compiled.entities.membership).coords.host.id_hash
        == compiled.entities.registries.host.axon.id_hash;
      expected = true;
    };

    # (c) a raw "kind:name" string handed to a den-hoag entry position aborts NAMED (A2) — the shim
    # never lets a string ride past the boundary into a declaration.
    test-string-in-entry-position-aborts = {
      expr = (builtins.tryEval (denHoag.declare.edge "aspect:system")).success;
      expected = false;
    };
  };
}
