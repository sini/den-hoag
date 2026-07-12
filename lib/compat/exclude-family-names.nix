# THE CORPUS EXCLUDE-FAMILY TAG SET (#72, candidate A — the resolve-family-names.nix twin): the SINGLE
# source of the `den.excludeFamilyNames` knob, consumed by the SAME two callers (flake-module.nix's
# option module — catches an excluder authored DIRECTLY under `den.policies.<name>`; compile.nix's
# include-arm `excludeFamilyStamp` — catches one wired through an include, whose compiled key is
# synthetic).
#
# A v1 corpus authors `policy.exclude` policies with NO den-hoag `__excludeFamily` tag, and the corpus's
# excluder is VALUE-CONDITIONAL (`lib.optional (host.class == "droid") …` — it emits nothing at the
# value-less stratum probe), so it cannot be DETECTED; the shim DECLARES the tag here. THE OMISSION
# CATCH: an excluder omitted here that fires a `suppress` in the main run aborts LOUD
# (`errors.excludeFamilyUntagged`), never a silent drop.
#
# Census (nix-config @ b0b20769, the ONE policy-exclude emitter):
#   • drop-user-to-host-on-droid (modules/den/batteries/nix-on-droid.nix:98-104) —
#     `policy.exclude den.policies.user-to-host` at droid-class hosts (v1's suppression of the os-user
#     route where droid lacks the `users` option; registered at `den.default.includes`, :117).
[
  "drop-user-to-host-on-droid"
]
