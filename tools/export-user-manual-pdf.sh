#!/usr/bin/env bash
# DOCASA User Manual PDF export (Task 25): pandoc → styled HTML → headless
# Chromium print, which honors the @page A4 CSS in docs/pdf-header.html.
# No LaTeX engine needed. Output under releases/ is local-only (gitignored).
# Toolchain: pandoc (scoop) + Google Chrome at its default install path.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p releases
stamp=$(date +%Y%m%d)
out="releases/DOCASA-User-Manual-$stamp.pdf"
html="releases/User-Manual.html" # intermediate, overwritten on every run

pandoc docs/User-Manual.md -f markdown -s --toc --toc-depth=2 \
  --metadata title="DOCASA Air Purifier — Mobile App User Manual" \
  --include-in-header=docs/pdf-header.html -t html5 -o "$html"

chrome="/c/Program Files/Google/Chrome/Application/chrome.exe"
[ -x "$chrome" ] || { echo "chrome not found at $chrome" >&2; exit 1; }
"$chrome" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$(cygpath -w "$PWD/$out")" \
  "file:///$(cygpath -m "$PWD/$html")"

echo "user manual PDF: $out"
