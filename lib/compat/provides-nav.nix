# den-compat ROOT-NAV registry (`den._` / `den.provides`) — the name→handle lookup of the root-namespace
# provider aliases a v1 corpus navigates off the `den` module arg. After migration rule 3 rewrote
# define-user/primary-user/hostname → `den.batteries.*`, TWO genuine root-nav survivors remain:
#   • forward         — the real `forwardEach` class-reroute (v1 `nix/lib/forward.nix`, pin 11866c16).
#   • mutual-provider — an INERT includable (v1 `modules/compat/mutual-provider-shim.nix`, a `__functor`
#                       aspect `{ name; description; }` with ZERO effects: "cross-entity routing is now
#                       built into emitAspectPolicies"). Reproduced as a plain attrset aspect carrying
#                       ONLY the `name`/`description` STRUCTURAL facets (concern-aspects.nix:171-183) —
#                       no class content, no `includes` ⇒ contributes nothing; safe in
#                       `den.default.includes = [ … ]`. Byte-faithful to the v1 shape (den-hoag needs no
#                       `__functor`: an `includes` list accepts a plain attrset aspect directly).
#
# COMPAT-thin (litmus): a CLOSED keyed attrset — no recursion, fold, edge-walk, or transpose. The
# registry SEAM is the flexibility (register a root-nav handle by adding a member); the members are just
# these two. TOTALITY: an unregistered `den._.<typo>` is a Nix-NATIVE missing-attr abort — LOUD, names
# the key, never silent-null (mirrors the class-registry totality INTENT, concern-collectors.nix:113-142).
# A den-branded named throw is impossible here: `den._.<x>` names arrive as literal attr PATHS (Nix has
# no missing-attr hook), whereas class-registry names arrive as string VALUES through `entries.${n} or
# throw`. The closed-membership witness (`den._ ? forward`, `? mutual-provider`, `!? <typo>`) proves the
# surface is exactly these two.
forwardEach: {
  forward = forwardEach;
  mutual-provider = {
    name = "mutual-provider";
    description = "cross-entity routing is built into emitAspectPolicies (inert compat shim)";
  };
}
