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
CUR="firmware/docasa-air-purifier-v4/docasa-air-purifier-v4.ino"

if [[ ! -f "$BASE" || ! -f "$CUR" ]]; then
  echo "FATAL: missing $BASE or $CUR"
  exit 2
fi

diff -w -U0 "$BASE" "$CUR" > /tmp/docasa-fw-diff.txt

# Unified-diff format: removed lines start with '-', added with '+' (minus the
# '---'/'+++' file headers). Counts include empty lines correctly.
removed=$(( $(grep -c "^-" /tmp/docasa-fw-diff.txt) - $(grep -c "^---" /tmp/docasa-fw-diff.txt) ))
added=$(( $(grep -c "^+" /tmp/docasa-fw-diff.txt) - $(grep -c "^+++" /tmp/docasa-fw-diff.txt) ))

echo "baseline lines  : $(wc -l < "$BASE")"
echo "current  lines  : $(wc -l < "$CUR")"
echo "added lines     : $added"
echo "removed/changed : $removed"

if [[ "${1:-}" == "--verbose" ]]; then
  echo "--- added hunks ---"
  grep -E "^\+[^+]" /tmp/docasa-fw-diff.txt
fi

if [[ "$removed" -eq 0 ]]; then
  echo "GATE: PASS — additive only (Plan §1.4 compliant). Manually review added hunks."
  exit 0
else
  echo "GATE: FAIL — $removed line(s) removed or modified vs baseline."
  echo "      Requires explicit user approval before merge (Plan §1.4). Offending lines:"
  grep -E "^-[^-]" /tmp/docasa-fw-diff.txt | head -20
  exit 1
fi
