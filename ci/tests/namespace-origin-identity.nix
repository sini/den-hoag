# The ORIGIN coordinate as a PARTITION (value-agnostic, sibling to native-identity.nix). A namespace is a
# local ORIGIN: its aspects carry `origin=["<name>"]` in their content-address, reached through gen-aspects
# `aspectId` (routed through gen-schema's `hashIdentity`) via `denHoag.aspectIdHashFor`. This witnesses the
# LAW the origin coordinate must satisfy — same origin+path ⇒ same id, distinct path ⇒ distinct id, origin
# genuinely enters the preimage (a namespace aspect ≠ a plain aspect of the same key), cross-namespace
# distinct — pinning STRUCTURE, not id literals, so it survives any future formula change.
{ denHoag, ... }:
let
  h = denHoag.aspectIdHashFor; # origin: key: <id>
in
{
  flake.tests.namespace-origin-identity = {
    test-origin-partition = {
      expr = {
        # same origin + same path ⇒ same id
        stable = h [ "hw" ] "hw/amdgpu" == h [ "hw" ] "hw/amdgpu";
        # same origin, distinct path ⇒ distinct id
        distinct = h [ "hw" ] "hw/amdgpu" != h [ "hw" ] "hw/radeon";
        # ORIGIN discriminates: a namespace aspect (origin=["hw"]) ≠ a plain aspect of the SAME key
        # (origin=[], `aspectIdHash`) — proves origin genuinely enters the preimage (the namespace shift).
        originShift = h [ "hw" ] "hw/amdgpu" != denHoag.aspectIdHash "hw/amdgpu";
        # two DIFFERENT namespaces, same relative path ⇒ distinct (origin is the discriminator)
        crossNs = h [ "a" ] "a/x" != h [ "b" ] "b/x";
      };
      expected = {
        stable = true;
        distinct = true;
        originShift = true;
        crossNs = true;
      };
    };
  };
}
