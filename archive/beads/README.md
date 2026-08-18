# Evacuated bead records — read before sweeping this directory

These files are the full records of tracker beads that left the `bd` payload on 2026-08-18 under the
process strip-back's P10 ruling. Each file carries one bead's title, status, priority, labels,
description, notes and every comment, verbatim as they stood at the evacuation. The beads themselves
still exist: they keep their status, priority, labels, parent and every dependency edge, and their
description is now a pointer stub naming the file here.

## Why they left

The den-hoag kernel/compat track is frozen (ADR-0002) and parked out of `bd ready`, but every
`bd list --all --limit 0 --json` — including the C10 prior-art sweep that runs before every gate — paid
for its bodies. Measured at the evacuation: the family was ~37% of tracker description mass and ~32% of
that payload. The move removed 1,686,381 description bytes and 52,452 notes bytes.

## ★ If you are running a sweep, scope PAST this directory

A repository-wide `*.md` sweep now matches 118 frozen records that are history, not live content. A
citation, a figure or a stale claim found here is a record of what was true when the bead was written —
correcting it would be editing a record. Exclude the directory, or state that you included it and why.

`git grep`, `grep -r` and the ugrep wrapper on `grep` disagree in this workspace on what they traverse;
whichever you use, say which, and check whether it descended here.

## Consulting a record

Two files are still routed to by live documents and their stubs carry the consult path:

- `den-hoag-4kh.20.md` — the instrument-trap case log, FROZEN under strip-back P4. Consult ON RECURRENCE
  via its head index, then grep the body for that index line's capitalized key phrase. It takes no new
  rows; the laws it produced live in the agent memory layer.
- `den-hoag-4kh.17.md` — the FROZEN den-hoag track's retiring-constructs register. It is **not**
  `den-hoag-rlsm`, which is the live systems register for the gen arc. Entries are anchored by
  expression or binding name and carry a verification date; an entry without one is a hypothesis.

## Restoring one

Nothing was destroyed. Strongest first: the store is Dolt-backed, so `bd show --id=<bead> --json
--as-of <commit>` returns the pre-migration record; a full `bd export --all` recovery point was taken
before the migration; each file's `## Description` block is the removed bytes verbatim; and every stub
prints its own restore command.
