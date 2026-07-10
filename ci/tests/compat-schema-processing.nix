# Schema processing at the flake-parts boundary (ship-gate M1.75). v1's `options.den.schema` is a gen-schema
# `mkSchemaOption` that turns raw kind DECLARATIONS (`den.schema.<K> = { parent; options; isEntity; … }`) into
# gen-schema KIND-VALUES `{ kind; strict; refs; options; validators; refinements }`. A corpus module reads that
# processed value at declaration time (`options.den.clusters = mkInstanceRegistry den.schema.cluster`), so the
# bridge reproduces the processing (else the corpus's own mkInstanceRegistry throws `attribute 'refs' missing`).
# The bridge does it as an `apply` on `options.den.schema` running the shim's OWN gen-schema in a NESTED eval
# (gen-schema types never enter the consumer's nixpkgs eval — the type-crossing dodge), with the RAW
# declarations stashed under `__rawSchema` for the SHIM (definitions-vs-value split: corpus ← processed,
# shim ← raw, since the shim re-processes and would double-declare `_kindNames`).
#
# This witness reproduces the corpus's schema/cluster.nix pattern as close as den-hoag CI can WITHOUT the
# corpus's own gen-schema input: it asserts the bridge PRODUCES a contract-shaped kind-value at
# config.den.schema.<K>, and stashes the raw. FIDELITY LIMIT: it does not run the corpus's exact
# mkInstanceRegistry rev — that consumption is re-proven by every ship-gate probe (a produced kind-value
# missing a contract field surfaces there as a named `attribute '<f>' missing`, the M1.75 loudness).
{
  lib,
  denCompat,
  denHoag,
  denHoagSrc,
  ...
}:
let
  mkCrossNixos =
    npkgs:
    (import "${denHoagSrc}/lib/output/terminal.nix" {
      inherit (denHoag.internal) bind flake;
    } { nixpkgs = npkgs; }).crossNixos;
  bridge = import "${denHoagSrc}/lib/compat/bridge.nix" {
    compat = denCompat;
    inherit mkCrossNixos;
    schema = denHoag.internal.schema;
    denLib = denHoag;
  };
  flakeStub = {
    options.flake = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = { };
    };
  };
  # A custom `rack` kind declared corpus-style, PLUS a second module contributing another field to the same
  # kind — proving the sub-option deep-merges declarations across modules before the apply processes them.
  ev = lib.evalModules {
    modules = [
      flakeStub
      bridge
      {
        den.schema.rack = {
          options.slots = lib.mkOption {
            type = lib.types.int;
            default = 0;
          };
        };
      }
      { den.schema.rack.parent = null; }
    ];
  };
  kv = ev.config.den.schema.rack;
in
{
  flake.tests.compat-schema-processing = {
    # the apply produces a gen-schema KIND-VALUE carrying the contract fields a mkInstanceRegistry reads.
    test-kind-value-contract = {
      expr = {
        kind = kv.kind or "<none>";
        hasRefs = kv ? refs;
        hasOptions = (kv.options or { }) ? slots;
        hasValidators = kv ? validators;
      };
      expected = {
        kind = "rack";
        hasRefs = true;
        hasOptions = true;
        hasValidators = true;
      };
    };
    # the RAW declarations are stashed for the shim (definitions-vs-value split) and deep-merged across the
    # two modules (parent from one, options from the other).
    test-raw-schema-stashed-and-merged = {
      expr = {
        stashed = ev.config.den.schema.__rawSchema ? rack;
        parentMerged = (ev.config.den.schema.__rawSchema.rack or { }) ? parent;
        optionsMerged = (ev.config.den.schema.__rawSchema.rack or { }) ? options;
      };
      expected = {
        stashed = true;
        parentMerged = true;
        optionsMerged = true;
      };
    };
  };
}
