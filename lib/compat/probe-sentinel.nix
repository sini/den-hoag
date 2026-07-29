# THE RECOVERY SENTINEL — the corpus coord FIELDS a v1 policy body reads on an entry, as TYPE-CORRECT
# NON-MATCHING values. SINGLE SOURCE, the sibling of resolve-family-names.nix / exclude-family-names.nix /
# produces-by-name.nix: each of those names a v1 corpus fact the shim knows and the kernel must not.
#
# The shim recovers a v1 bare closure's declaration codomain by firing it once against a value-less entry
# (policy-recover.nix). A body that reads a coord FIELD on that entry — `host.class`, `host.system`,
# `host.hostName` — would hit an attribute-missing read, which `tryEval` cannot catch, so the fire must
# supply each field with a value of the RIGHT TYPE that MATCHES NOTHING. The body then takes its
# value-conditional FALSE branch and the recovery reads its codomain cleanly.
#
# CEILING (self-announcing, unchanged): a body reading a field absent from this set still fails LOUDLY and
# names the field, so the remedy is to extend the set — or, better, to declare the policy's codomain in
# produces-by-name.nix, which skips the fire entirely.
#
# A DEEP field (`settings`) cannot be a string: it needs a submodule tree materialized at its own
# defaults, which only the bridge can build. The bridge threads it as the reserved
# `_probeSentinelFields.settings` and flake-module merges it onto these constants.
{
  class = "«sentinel»";
  system = "«sentinel»";
  hostName = "«sentinel»";
}
