# den v1 `flakeModules.strict` (denful/den nix/strict.nix): a top-level flake-parts module a consumer
# imports to put EVERY den schema kind into STRICT mode — any option set on an entity without an explicit
# declaration aborts (via `den.lib.strict`, the freeform-throw module, lib/compat/strict.nix).
#
# `.imports = [ den.lib.strict ]` (NOT the bare `den.schema.<kind> = den.lib.strict` v1 wrote): den-hoag's
# `den.schema` is a def-COLLECTOR feeding a nested gen-schema eval whose kind merge reads attrset defs
# (`filter isAttrs`) — a bare function value would be dropped/mis-shaped, not merged as strict. The imports
# form wraps `den.lib.strict` as a kind-module import (bridge.nix `rawImportsOf` concatenates it into the
# kind-value's `__functor`), which is v1-faithful: v1's schema option equally merged the strict fn as a
# module (templates/ci/modules/public-api/strict.nix `den.schema.flake.imports = [ den.lib.strict … ]`).
# `den.lib.strict` reaches this module through the `den` arg the bridge binds (`_module.args.den.lib`).
{ den, ... }:
{
  den.schema.host.imports = [ den.lib.strict ];
  den.schema.user.imports = [ den.lib.strict ];
  den.schema.aspect.imports = [ den.lib.strict ];
  den.schema.home.imports = [ den.lib.strict ];
  den.schema.flake.imports = [ den.lib.strict ];
}
