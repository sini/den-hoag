# den-hoag NAMESPACE-identity helpers (§A2). Two kernel-owned namespaces (aspect, class) need a
# content-stable id_hash keyed by a STRING preimage — distinct from lib/identity.nix's structural
# edge/instance fingerprints. Identity is gen-native's responsibility now: den-hoag RETIRES its former
# `sha256 "den-aspect:${key}"` / `"den-class:${name}"` hand-roll onto the gen-native content-address
# (the designed route documented at gen-aspects/lib/default.nix:53). This is the SINGLE authority for
# both helpers, so any downstream recompute of an entry's id_hash (Law C6) can NEVER drift.
#   • aspect — routed through the canonical `aspects.aspectId` (all three aspect kinds share it), so a
#     helper recompute over a node's key equals that node's OWN gen-aspects-stamped `id_hash` (origin=[],
#     den-hoag sets no providerPrefix). `aspectId [] {name=key; chain=[]}` = key verbatim (identity.key
#     over a chain-less node) = the kernel node's `.key`, hence the same content-address.
#   • class — routed through gen-schema's ONE `hashIdentity` formula (the SAME formula `aspectId` hashes
#     through), with a distinct `"class"` kind tag so class ids partition from aspect ids of a like key.
{ aspects, schema }:
let
  # Origin-aware aspect content-address — the gen-link ORIGIN coordinate, reached through gen-aspects
  # `aspectId` (routed through gen-schema's ONE `hashIdentity`; route-through-native, no formula twin).
  # `origin=[]` yields preimage `aspect|origin=|key=<k>` — today's partition, byte-preserved — so
  # `aspectIdHash` below stays value-identical. A namespace is a LOCAL ORIGIN: it stamps its aspects with
  # `origin=["<name>"]`, partitioning their content-address from a plain aspect of the same key.
  aspectIdHashFor =
    origin: key:
    aspects.aspectId origin {
      name = key;
      meta.aspect-chain = [ ];
    };
in
{
  inherit aspectIdHashFor;
  aspectIdHash = aspectIdHashFor [ ]; # origin=[] — the unchanged default (byte-identical to before)
  classIdHash = name: schema.hashIdentity "class" [ "name" ] (k: { inherit name; }.${k});
}
