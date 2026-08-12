#!/usr/bin/env bash
# Beads export guard — a STALE .beads/beads.jsonl cannot be committed.
#
# WHAT IT PREVENTS, and why remembering a flag was not enough.
# `bd export` with NO `-o` writes to STDOUT. It emits well-formed JSONL, scrolls past, and
# RETURNS 0 — while the file is never touched. The correct form is
# `bd export -o .beads/beads.jsonl`, which reports "Exported N issues to ...".
# The trap is that the failure is invisible to every signal a committer normally reads: the
# file is usually already dirty from earlier churn, so `git status` shows the expected
# change, the command exited 0, and the commit message says what it always says. A partially
# stale export is indistinguishable from a fresh one by inspection. Measured once at
# 3 insertions / 2 deletions: the export held ONE of eight new issues and still showed three
# closed issues as "status":"open".
#
# WHY A GUARD RATHER THAN A RULE. The repair form is "remember the -o". The by-construction
# form is this: the stale state cannot reach a commit, so the flag need not be remembered.
#
# WHAT IT DOES. Re-runs the export and compares the result against what is STAGED. `bd export
# -o` is byte-deterministic for unchanged data (measured: two consecutive exports of 641
# issues, identical md5), so a passing run leaves the file untouched and a differing hash
# means the staged bytes really are stale.
#
# SCOPE, deliberately narrow. The guard fires only when .beads/beads.jsonl is part of the
# commit. Committing unrelated code while the export drifts on disk is NOT this defect, and
# firing there would force the export into every diff and fight the batched-export practice.
# The excluded case is therefore real and known: an export can sit stale on disk indefinitely;
# what it cannot do is enter git in that state.
#
# WIRING. Called from .beads/hooks/pre-commit (core.hooksPath points there), placed OUTSIDE
# the `--- BEGIN/END BEADS INTEGRATION ---` markers so that a `bd hooks install` rewriting the
# managed block leaves the call standing. That is a convention of beads' installer, not a
# guarantee — re-verify this wiring after any beads upgrade, the same contract the sibling
# .beads/hooks/commit-msg carries. To restore the wiring by hand, add before the final
# `exec` line of .beads/hooks/pre-commit:
#
#     "$(dirname "$0")/../../hooks/beads-export-guard.sh" || exit 1
#
# That call site resolves this script relative to the HOOK, which lives in the main checkout,
# because core.hooksPath is absolute and every linked worktree runs that same hook file. This
# script then operates on whichever worktree is committing, via `git rev-parse --show-toplevel`
# below — so the location is fixed but the subject is not.
#
# Note `bd hooks run pre-commit` does NOT export: measured with the export file stale, the
# hook exited 0 and left the file's hash unchanged, while `bd export -o` against the same
# database in the same session produced a different hash.

set -uo pipefail

EXPORT_PATH=.beads/beads.jsonl

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root" || exit 1

# Does this commit touch the export? If not, nothing stale can enter git here.
if [ -z "$(git diff --cached --name-only -- "$EXPORT_PATH")" ]; then
  exit 0
fi

if ! command -v bd >/dev/null 2>&1; then
  echo "beads-export-guard: bd is not on PATH, so the staged $EXPORT_PATH cannot be" >&2
  echo "verified. Refusing rather than passing an unchecked export." >&2
  exit 1
fi

staged=$(git rev-parse ":$EXPORT_PATH" 2>/dev/null) || {
  echo "beads-export-guard: $EXPORT_PATH is not in the index; cannot compare." >&2
  exit 1
}

if ! bd export -o "$EXPORT_PATH" >/dev/null 2>&1; then
  echo "beads-export-guard: 'bd export -o $EXPORT_PATH' failed. The staged export cannot be" >&2
  echo "confirmed current, so the commit is refused." >&2
  exit 1
fi

fresh=$(git hash-object "$EXPORT_PATH") || exit 1

if [ "$staged" != "$fresh" ]; then
  cat >&2 <<EOF
beads-export-guard: the staged $EXPORT_PATH is STALE.

  staged blob: $staged
  fresh blob:  $fresh

A fresh 'bd export -o $EXPORT_PATH' has been written to the working tree, so the difference
above is between what this commit would carry and what the database actually holds. The
usual cause is a bare 'bd export', which writes JSONL to stdout and exits 0 without touching
the file.

  git add $EXPORT_PATH

then commit again.
EOF
  exit 1
fi

exit 0
