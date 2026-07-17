# Two-level edge identity: content vs placement (REFERENCE.md; the applicative/nominal
# reading of Backpack-style instance identity — same content + same structural filling =
# same instance; structurally distinct fills that would produce equal values count as
# distinct, the F-ing modules honesty ceiling). Function values never enter fingerprints;
# produced values never enter the structural fill map — only the PRODUCING node's
# instanceId does, so identity hashing can never force content.
{ prelude }:
let
  hash = v: builtins.hashString "sha256" (builtins.toJSON v);

  # canonical serialization for fingerprint inputs: attrsets serialize with sorted keys via
  # toJSON (builtins.toJSON sorts attrs); LISTS preserve order (deliberate — order-bearing
  # coordinates like mount paths must distinguish).
  rejectFunctions =
    where: v:
    if builtins.isFunction v then
      throw "den.identity: function value in ${where} — reference registry entries by name"
    else if builtins.isAttrs v then
      builtins.mapAttrs (n: rejectFunctions "${where}.${n}") v
    else if builtins.isList v then
      map (rejectFunctions "${where}[]") v
    else
      v;

  dataFingerprint = data: hash (rejectFunctions "edge data" data);

  assemblyId =
    { entityId, class }:
    hash [
      entityId
      class
    ];

  instanceId =
    { assemblyId, s }:
    hash [
      assemblyId
      (rejectFunctions "structural fill" s)
    ];

  edgeId =
    {
      kind,
      fromInstanceId,
      toInstanceId,
      dataFingerprint,
    }:
    hash [
      kind
      fromInstanceId
      toInstanceId
      dataFingerprint
    ];

  # fill-reference acyclicity: fills : { <instanceId> = [ referenced instanceId … ]; }.
  # A cycle would make instance identity an undeclared fixpoint — abort naming a member.
  # Detection: id is cyclic iff id ∈ closure(its direct references) — catches self-loops
  # and longer cycles alike.
  checkFillAcyclic =
    fills:
    let
      reachableFrom =
        id:
        map (i: i.key) (
          builtins.genericClosure {
            startSet = map (r: { key = r; }) (fills.${id} or [ ]);
            operator = item: map (r: { key = r; }) (fills.${item.key} or [ ]);
          }
        );
      cyclic = builtins.filter (id: builtins.any (r: r == id) (reachableFrom id)) (
        builtins.attrNames fills
      );
    in
    if cyclic == [ ] then
      null
    else
      throw "den.identity: structural-fill reference cycle through instance ${builtins.head cyclic}";
in
{
  inherit
    dataFingerprint
    assemblyId
    instanceId
    edgeId
    checkFillAcyclic
    ;
}
