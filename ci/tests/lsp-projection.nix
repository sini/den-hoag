# The option-declaration PROJECTION (§ options-projection): `den.lib.lsp.optionsProjection` re-keys
# `den._options` (the evaluated `_type == "option"` tree) into the shape a Nix LSP (nixd) walks — option
# leaves preserved (`_type`/`type`/`description`/`default`), gen-schema refinement metadata stripped off
# each leaf's `.type`, submodule/attrsOf descent shapes kept. Reads a real fleet's declared schema; the
# refinement strip is pinned on a synthetic refined type (a base type carrying `__schema.baseType`).
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

  projected = denHoag.lsp.optionsProjection { options = den._options; };

  # Synthetic refined type (gen-schema refined.nix shape): a base type wrapped with `__schema` carrying
  # `refinements` + `baseType`. The base is a plain attrset (no functions) so the stripped result is
  # value-comparable. `stripRefinements` must return `baseType` and drop `__schema`.
  baseType = {
    name = "myBase";
  };
  refinedType = baseType // {
    __schema = {
      refinements = [
        {
          check = _: true;
          message = "m";
        }
      ];
      baseType = baseType;
    };
  };
  refinedLeaf = {
    opt = {
      _type = "option";
      type = refinedType;
      description = "a refined leaf";
      default = null;
    };
  };
  projectedRefined = denHoag.lsp.optionsProjection { options = refinedLeaf; };
in
{
  flake.tests.lsp-projection = {
    # The projection returns an attrset (the re-keyed tree).
    test-projection-is-attrs = {
      expr = builtins.isAttrs projected;
      expected = true;
    };

    # A flat option leaf (`den.membership`, a `listOf raw` decl) projects with `_type == "option"`,
    # a `type.name`, and its `description` preserved.
    test-leaf-preserved = {
      expr = {
        optionType = projected.den.membership._type;
        typeNameIsString = builtins.isString projected.den.membership.type.name;
        descriptionIsString = builtins.isString projected.den.membership.description;
      };
      expected = {
        optionType = "option";
        typeNameIsString = true;
        descriptionIsString = true;
      };
    };

    # An attrsOf-style instance-registry leaf (`den.host`) keeps its descent shape — the walk does NOT
    # flatten the element type out of the projected `.type` (`nestedTypes.elemType` still present).
    test-descent-shape-preserved = {
      expr = {
        optionType = projected.den.host._type;
        hasElemType = projected.den.host.type.nestedTypes ? elemType;
      };
      expected = {
        optionType = "option";
        hasElemType = true;
      };
    };

    # A gen-schema-refined `.type` is refinement-stripped: the projected type == the base type, with no
    # `__schema` metadata leaking through.
    test-refinement-stripped = {
      expr = {
        typeIsBase = projectedRefined.opt.type == baseType;
        noSchemaLeak = !(projectedRefined.opt.type ? __schema);
        leafPreserved = projectedRefined.opt._type == "option";
      };
      expected = {
        typeIsBase = true;
        noSchemaLeak = true;
        leafPreserved = true;
      };
    };
  };
}
