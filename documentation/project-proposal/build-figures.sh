#!/usr/bin/env bash
# Re-render every figures/*.tex (standalone TikZ) to a 300 dpi PNG next to it.
# Needs pdflatex and pdftoppm (poppler). Run from anywhere.
set -euo pipefail
cd "$(dirname "$0")/figures"
for src in *.tex; do
  name="${src%.tex}"
  pdflatex -interaction=nonstopmode -halt-on-error "$src" > /dev/null
  pdftoppm -png -r 300 -singlefile "$name.pdf" "$name"
  rm -f "$name.aux" "$name.log" "$name.pdf"
  echo "rendered figures/$name.png"
done
