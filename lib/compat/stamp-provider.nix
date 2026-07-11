# ── PROVIDER-IDENTITY STAMP (board #58, Fork A) — v1 `wrapChild` parity (pin 11866c16 nix/lib/
# aspects/fx/aspect/normalize.nix:95-119). A navigated aspect value carries `__provider` (the
# post-fold annotation walk, annotate.nix; v1 annotateDeep, types.nix:561-574); derive
# `name = last __provider` and `meta.aspect-chain = init __provider` so gen-aspects `identity.key`
# (`aspectPath = meta.aspect-chain ++ [ name ]`) equals the FULL provider path — the SAME identity
# from EVERY inclusion path, so N references of one aspect resolve ONCE (forwardExpand's seen-dedup;
# the u5 multi-reference dedup, e.g. the corpus's 11× nginx). NO REGISTRY LOOKUP: the stamped value
# CARRIES its content — identity recovery never resolves a name against a registry (the
# `resolveAspectRef` no-lookup posture in compile.nix), so a recovered name can never land on an
# empty record. A value with its OWN `name` keeps it (v1's `!(child ? name)` gate, normalize.nix:96).
# `id_hash` rides along by the aspectEntry convention over the provider path: the collection stratum
# reads `content.id_hash` as the A12 producer key (collections.nix) — a native registry aspect gets it
# from den-hoag's idModule, a compat-normalized include record gets it HERE, so a quirk-emitting
# aspect delivered via include has a producer identity.
#
# THE SINGLE IDENTITY SOURCE (the projected-hasAspect rung). This is a SHARED module, imported by BOTH
# `compile.nix` (the include-grounding path — `stampIdentity`/`groundRec`/`mkEmittedAspect`) AND
# `has-aspect.nix` (the projected-hasAspect entity surface — `refKey`'s `__provider` branch). The two
# MUST recover v1's include identity from the SAME `__provider`-derived name/aspect-chain/id_hash, so a
# `host.hasAspect den.aspects.<path>` ref keys IDENTICALLY to the resolved-aspects node it answers for
# (the by-construction agreement W2 pins). One definition, no duplication.
{ prelude }:
{
  stampProvider =
    v:
    if
      builtins.isAttrs v && !(v ? name) && builtins.isList (v.__provider or null) && v.__provider != [ ]
    then
      v
      // {
        name = prelude.last v.__provider;
        id_hash =
          v.id_hash
            or (builtins.hashString "sha256" ("den-aspect:" + builtins.concatStringsSep "/" v.__provider));
        meta = (v.meta or { }) // {
          aspect-chain = prelude.init v.__provider;
        };
      }
    else
      v;
}
