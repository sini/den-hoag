# Linearization declaration surface (r2 open question 3 / §2.7). den semantics = one instantiation
# of gen-product's general `containmentChain linearization` parameter: `den.linearization.dims` is a
# total order on the product DIMENSIONS, least-specific → most-specific, as KIND entries (identity
# law A2 — each carries a `kind` field naming its product dimension). den-hoag renders those entries
# to their product dim-name strings and hands them to `gen-product.linearizeByDimOrder`, which owns
# the count-major `(|fixed|, sortDescending ranks)` slice-ordering key (Law A1 — den-hoag never
# ranks slices itself). The `default` (schema) and `policy` sentinels are fixed and not declarable
# (§2.7); they are the fold's first/terminal slots, not chain members.
#
# Definition-time totality (Law A7): den validates the dim cover here — a missing, duplicated, or
# non-entry dim aborts with a named error — BEFORE the rendered name list crosses into gen-product
# (whose own `validateDimOrder` fires only inside `containmentChain`). nixpkgs-lib-free: gen-prelude
# + builtins only.
{
  prelude,
  product,
  errors,
}:
let
  firstDuplicate =
    xs:
    let
      go =
        seen: rest:
        if rest == [ ] then
          null
        else if builtins.elem (builtins.head rest) seen then
          builtins.head rest
        else
          go (seen ++ [ (builtins.head rest) ]) (builtins.tail rest);
    in
    go [ ] xs;
in
{
  # linearization { dims; productDims } -> gen-product linearization record.
  #   dims        : [ <kind entry> ] — the declared order (identity law: each carries `.kind`).
  #   productDims : the dimension names actually in the product (`dimKinds`) — the totality target.
  linearization =
    {
      dims,
      productDims,
    }:
    let
      names = map (
        k:
        if builtins.isAttrs k && k ? kind then
          k.kind
        else
          errors.linearizationDim "non-entry" (if builtins.isString k then k else builtins.typeOf k)
      ) dims;
      missing = builtins.filter (d: !(builtins.elem d names)) productDims;
      dup = firstDuplicate names;
    in
    if missing != [ ] then
      errors.linearizationDim "missing" (builtins.head missing)
    else if dup != null then
      errors.linearizationDim "duplicate" dup
    else
      product.linearizeByDimOrder names;
}
