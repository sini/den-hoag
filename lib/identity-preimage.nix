# den-hoag NAMESPACE-identity preimages (§A2). Two kernel-owned namespaces carry a content-stable
# id_hash over a STRING preimage — distinct from lib/identity.nix's structural edge/instance
# fingerprints. This is the SINGLE authority for both preimages, so the aspect authority
# (concern-aspects.nix idModule), the class authority (classEntries/effectiveClassEntries), and any
# downstream recompute of an entry's id_hash (Law C6) can NEVER drift.
{ }:
{
  aspectIdHash = key: builtins.hashString "sha256" "den-aspect:${key}";
  classIdHash = name: builtins.hashString "sha256" "den-class:${name}";
}
