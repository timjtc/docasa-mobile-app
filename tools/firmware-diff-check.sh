#!/usr/bin/env bash
# DOCASA firmware behavior-preservation gate (Development-Process §10.2)
#
# PASS = zero removed/changed lines vs the frozen v3 baseline (whitespace-insensitive).
# Additions are expected (BLE/NVS/transmission per Plan §1.4); deletions or
# modifications of existing lines are NOT allowed without explicit user approval.
# Reviewing the ADDED hunks (printed on --verbose) is still a human responsibility —
# this script only proves nothing was removed or altered.

set -u
cd "$(dirname "$0")/.."

BASE="firmware/baseline/docasa-air-purifier-v3.ino"
# Active-sketch parameter (D-028e): first non-flag arg, default = the v5 lineage.
CUR="firmware/docasa-air-purifier-v5/docasa-air-purifier-v5.ino"
for _a in "$@"; do
  if [[ "$_a" != --* ]]; then CUR="$_a"; fi
done

if [[ ! -f "$BASE" || ! -f "$CUR" ]]; then
  echo "FATAL: missing $BASE or $CUR"
  exit 2
fi

# Whitespace-insensitive diff — standalone `diff` is missing on some Windows
# shells, so fall back to `git diff --no-index` (repo tooling is always here).
_diff_out=$(diff -w -U0 "$BASE" "$CUR" 2>/dev/null) || \
_diff_out=$(git diff --no-index --ignore-all-space --unified=0 -- "$BASE" "$CUR")

# Unified-diff format: removed lines start with '-', added with '+' (minus the
# '---'/'+++' file headers). Counts include empty lines correctly.
removed=$(( $(printf '%s\n' "$_diff_out" | grep -c "^-") -
             $(printf '%s\n' "$_diff_out" | grep -c "^---") ))
added=$(( $(printf '%s\n' "$_diff_out" | grep -c "^+") -
           $(printf '%s\n' "$_diff_out" | grep -c "^+++") ))

echo "baseline lines  : $(wc -l < "$BASE")"
echo "current  lines  : $(wc -l < "$CUR")"
echo "added lines     : $added"
echo "removed/changed : $removed"

VERBOSE=0
for _a in "$@"; do
  if [[ "$_a" == "--verbose" ]]; then VERBOSE=1; fi
done

if [[ "$VERBOSE" -eq 1 ]]; then
  echo "--- added hunks ---"
  printf '%s\n' "$_diff_out" | grep -E "^\+[^+]"
fi

if [[ "$removed" -eq 0 ]]; then
  echo "GATE: PASS — additive only (Plan §1.4 compliant). Manually review added hunks."
  exit 0
else
  echo "GATE: FAIL — $removed line(s) removed or modified vs baseline."
  echo "      Requires explicit user approval before merge (Plan §1.4). Offending lines:"
  printf '%s\n' "$_diff_out" | grep -E "^-[^-]" | head -20
  exit 1
fi
