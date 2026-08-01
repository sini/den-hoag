This directory ships VERBATIM artifacts. Their bytes are provenance, not style.

xfail-core-probe.nix is a byte-identical copy of the validated spec core
(papers specs/2026-07-29-three-state-ci-gate.core.nix, md5
0c6812835d4e8541e6eed215f38832ab). The md5 equality is the provenance check;
it is consulted by the spec's §12 errata and by anyone verifying that the
shipped probe IS the gated artifact. It is unevaluated by construction (the
`_`-rule keeps this directory out of flake.tests).

Do not format these files. The ci format gate (`cd ci && nix fmt -- --ci`)
excludes this directory. The repo-root `nix fmt` (stock nixfmt-tree) does NOT
know the exclusion and will try to reformat the probe — if it does, revert the
probe before committing; a formatted probe severs the anchor while changing
nothing semantic. The durable fix (a parameterised source root plus a rev
stated with each run, replacing verbatim shipping) is recorded at the spec's
§10 item 6.
