# The option-declaration surface (§ options-projection foundation): `mkDen` exposes the evaluated
# option-declaration tree (`den._options`) and its provenance (`den._provenance`) that `entity.build`
# otherwise discards. These are the declared-schema face — an attrset of gen-merge option leaves
# (each `_type == "option"`) mirrored by a provenance tree — reachable WITHOUT forcing `.config`
# (declarations only). Underscore-prefixed = internal passthrough, off the output/compat surface.
{
  denHoag,
  ...
}:
let
  den =
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.host.h0 = { };
      }
    ]).den;

  # Independence fixture: identical fleet EXCEPT its RESOLVED fleet config carries a live `throw` thunk
  # (`h0.outputs.fam`). Forcing `.config` (via the instance registry) throws; the option-DECLARATION
  # walk must not touch it. The poison sits in FLEET config, not schema — a leaf's `.type` references
  # `den.schema.<kind>` (static), never `den.host.<name>`, so the walk is clean regardless.
  poisonDen =
    (denHoag.mkDen [
      {
        config.den.schema.host.parent = null;
        config.den.host.h0 = {
          outputs.fam = throw "CONFIG-FORCED";
        };
      }
    ]).den;

  isOpt = v: builtins.isAttrs v && (v._type or null) == "option";
  hasSomeOption =
    v:
    if isOpt v then
      true
    else if builtins.isAttrs v then
      builtins.any hasSomeOption (builtins.attrValues v)
    else
      false;
  # The projection DISCOVERY pass: recurse the option tree reading only structure + each leaf's `_type`
  # (a config-free literal), never `.type` (which forces static schema config). `deepSeq` of the result
  # forces every `_type`.
  walkTypes =
    v:
    if isOpt v then
      v._type
    else if builtins.isAttrs v then
      builtins.map walkTypes (builtins.attrValues v)
    else
      null;
in
{
  flake.tests.lsp-options-surface = {
    # `_options` is an attrset reachable without forcing `.config`.
    test-options-exposed = {
      expr = builtins.isAttrs (den._options or null);
      expected = true;
    };
    # Some leaf under `_options.den.*` carries `_type == "option"` (the gen-merge option schema).
    test-options-have-option-leaves = {
      expr = hasSomeOption (den._options.den or { });
      expected = true;
    };
    # `_provenance` is exposed likewise (the provenance tree mirroring the config tree).
    test-provenance-exposed = {
      expr = builtins.isAttrs (den._provenance or null);
      expected = true;
    };
    # THE INDEPENDENCE SEAM: walking every `_options` leaf's `_type` succeeds even when RESOLVED fleet
    # config carries a live `throw` (`walkOk`), while forcing that config throws (`configThrows`). Pins
    # the "reachable WITHOUT forcing `.config`" guarantee as a permanent regression guard.
    test-options-independent-of-resolved-config = {
      expr = {
        walkOk = builtins.deepSeq (walkTypes poisonDen._options) "OK";
        configThrows =
          !(builtins.tryEval (builtins.deepSeq poisonDen.registries.host.h0.outputs "forced")).success;
      };
      expected = {
        walkOk = "OK";
        configThrows = true;
      };
    };
  };
}
