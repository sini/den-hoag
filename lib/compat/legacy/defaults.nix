# den-compat LEGACY surface: `defaults` (R4 + the built-in battery membership, spec §10).
#
# R4 — `den.default` → `den.aspects.defaults` via the GENERAL kind-include path. den v1
# `modules/aspects/defaults.nix` radiates the `den.default` aspect as a schema include to kinds `{ host,
# user, home }`. The shim desugars this COMPAT-SIDE into a plain `den.aspects.defaults` aspect wired
# through `den.schema.{host,user}.includes`, so it follows the SAME kernel path as any user aspect (no
# bespoke `__default`/`__denDefault` radiation). `den.default`'s non-includes content becomes the aspect's
# content; its `.includes` ride the aspect's includes.
#
# This module also carries the BUILT-IN MEMBERSHIP — the batteries that v1 self-appends to
# `den.default.includes` (`os-to-host`, `user-to-host`). Each battery EXPORTS its route as a `routeInclude`
# record; this module coerces them into `defaults.includes` (so they reach entities via the include arm,
# `compilePolicy`-gated on the route fn's formals). It also composes the corpus-exercised battery ports
# (`legacy/batteries/*`) into ONE pure v1 → v1 desugar, each adding its class bucket (R2). PINNED, not
# widened: only the batteries the corpus exercises are ported (os-class R3, os-user R6); the rest (hjem,
# maid, tty-autologin, wsl, …) get explicit ledger rows — no hallucinated content (spec §10 R6).
#
# SEVERABLE (Law C5): applied by flake-module.nix `desugarLegacy` when in the wiring's legacy set. Severed
# ⇒ the identity; an aspect using a battery class (`os`/`user`) then aborts as an unknown key (R9).
{
  prelude,
  errors,
  ...
}@deps:
let
  batteries = {
    os-class = import ./batteries/os-class.nix deps;
    os-user = import ./batteries/os-user.nix deps;
    # #68 (ledger u18 Family A): the v1-AMBIENT home-manager battery's user-scope emitter — the hm
    # userForward (see batteries/home-manager.nix header for the four-part v1 census; only the emitter
    # needed porting). registersClasses = [ ] (homeManager grounds to the built-in home-manager class).
    home-manager = import ./batteries/home-manager.nix deps;
  };
  batteryList = builtins.attrValues batteries;

  # The batteries' EXPORTED route records (os-to-host / user-to-host), coerced into the `defaults` aspect's
  # includes. Coercing `.name`/`.fn` into an `{ __isPolicy; name; fn }` record makes the include-arm's
  # `compilePolicy` accept it (its `fn` formals become the dispatch gate) AND lets `includeReferencedNames`
  # match the name — so the ambient `den.policies.user-to-host` global (builtins.nix) is removed from the
  # fleet-wide firing set, leaving a SINGLE firing via the include.
  routeIncludes = builtins.filter (r: r != null) (map (b: b.routeInclude or null) batteryList);
  coerce = r: {
    __isPolicy = true;
    inherit (r) name fn;
  };

  # `den.aspects.defaults` — the desugared v1 `den.default`: its non-includes content, plus the coerced
  # built-in routes PREPENDED to any user-supplied `den.default.includes`.
  defaultsAspect =
    v1:
    let
      d = v1.default or { };
    in
    (builtins.removeAttrs d [ "includes" ])
    // {
      includes = map coerce routeIncludes ++ (d.includes or [ ]);
    };

  # Wire `defaults` into a kind's schema includes so it reaches every instance of that kind via the
  # general kind-include path (the same path any user aspect follows) — replacing the `den.default`
  # radiation to {host, user}.
  #
  # MATERIALIZING `den.schema.user = { includes = … }` SUPPRESSES ingest's built-in `user.parent = "host"`
  # default (ingest fills the built-in ONLY when `user` is ABSENT from the declared schema), which would
  # leave `user.parent = null` — the user kind becomes a ROOT, not a cell under its host, so the
  # (user,host) membership cell is unreachable. Carry the built-in parent the wire suppresses. An
  # EXPLICITLY-declared parent still wins (`existing` overrides `builtinDefault`); a user-as-root native
  # fleet is unaffected.
  wireSchemaInclude =
    kind: v1:
    let
      existing = v1.schema.${kind} or { };
      builtinDefault = if kind == "user" then { parent = "host"; } else { };
    in
    v1
    // {
      schema = (v1.schema or { }) // {
        ${kind} =
          builtinDefault
          // existing
          // {
            includes = (existing.includes or [ ]) ++ [ "defaults" ];
          };
      };
    };

  # Assemble the `defaults` aspect + wire host/user schema includes, then DROP `den.default` (now empty —
  # its radiation goes inert). The batteries' class registrations have already been folded in by then.
  assembleDefaults =
    v1:
    let
      withAspect = v1 // {
        aspects = (v1.aspects or { }) // {
          defaults = defaultsAspect v1;
        };
      };
      withSchema = wireSchemaInclude "user" (wireSchemaInclude "host" withAspect);
    in
    builtins.removeAttrs withSchema [ "default" ];

  # The exported desugar: fold the battery class-registration desugars left-to-right (pinned for
  # determinism), THEN assemble `defaults` over the result.
  composeDesugars = v1: assembleDefaults (prelude.foldl' (acc: b: b.desugar acc) v1 batteryList);
in
{
  _denCompat.legacy = "defaults";

  # The batteries' registered classes (R2), for the rule-witness test's assertion.
  registeredClasses = prelude.concatMap (b: b.registersClasses) batteryList;

  # The set of built-in battery route names R4 pins as the `defaults` aspect's membership (R3/R6) — the
  # names the batteries coerce into `defaults.includes`.
  builtinPolicyNames = [
    "os-to-host"
    "user-to-host"
  ];

  # NON-PORTED batteries (corpus-unexercised at the frozen pin) — the honest ledger, not silent omission.
  # A future corpus bump exercising one re-opens its port here (spec §10 R6).
  nonPortedBatteries = [
    "define-user"
    "flake-parts"
    "flake-scope"
    "host-aspects"
    "hostname"
    "import-tree"
    "insecure"
    "primary-user"
    "tty-autologin"
    "unfree"
    "user-shell"
    "vm-autologin"
  ];

  desugar = composeDesugars;

  inherit batteries;
}
