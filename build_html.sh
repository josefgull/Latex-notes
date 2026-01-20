#!/usr/bin/env bash
set -euo pipefail

# Build HTML with lwarp in an isolated directory, then copy only the
# final HTML/CSS (and any images) back to the project. Workspace stays clean.
# Usage: ./build_html.sh [basename]
# Default basename: first .tex (excluding *_html.tex), else 'dirac'.

ROOT=$(cd -- "$(dirname "$0")" && pwd)
BASENAME="${1:-}"

if [[ -z "${BASENAME}" ]]; then
  if ls "$ROOT"/*.tex >/dev/null 2>&1; then
    BASENAME=$(ls "$ROOT"/*.tex | grep -v '_html.tex$' | head -n1 | sed 's|.*/||; s/\.tex$//')
  else
    BASENAME="dirac"
  fi
fi

BUILD_DIR="$ROOT/.lwarp_build"
DIST_DIR="$ROOT/dist"

# Verify tools
command -v lwarpmk >/dev/null 2>&1 || { echo "Error: lwarpmk not found (install TeX Live lwarp)." >&2; exit 1; }
command -v lualatex >/dev/null 2>&1 || { echo "Error: lualatex not found (install TeX Live)." >&2; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "Error: rsync not found (install rsync)." >&2; exit 1; }

echo "[build_html] Preparing isolated build dir at '$BUILD_DIR'..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy workspace into build dir, skipping existing dist and the build dir itself.
rsync -a --delete \
  --exclude '.git/' \
  --exclude 'dist/' \
  --exclude '.lwarp_build/' \
  "$ROOT/" "$BUILD_DIR/"

cd "$BUILD_DIR"

# Ensure lwarpmk.conf exists in the build dir (bootstrap if needed)
if [[ ! -f lwarpmk.conf ]]; then
  echo "[build_html] Bootstrapping with lualatex to create lwarpmk.conf..."
  lualatex --interaction=nonstopmode --shell-escape "${BASENAME}.tex" >/dev/null
fi

echo "[build_html] Building HTML for '${BASENAME}.tex'..."
lwarpmk html

echo "[build_html] Collecting artifacts into '$DIST_DIR'..."
mkdir -p "$DIST_DIR"

# Copy primary HTML outputs
for f in "${BASENAME}.html" "${BASENAME}_html.html"; do
  if [[ -f "$f" ]]; then
    cp -f "$f" "$DIST_DIR/"
  fi
done

# Copy CSS used by lwarp (skip if absent)
for css in lwarp.css lwarp_formal.css lwarp_sagebrush.css sample_project.css; do
  if [[ -f "$css" ]]; then
    cp -f "$css" "$DIST_DIR/"
  fi
done

# Copy image outputs if present (common image types)
rsync -a \
  --include '*/' \
  --include '*.png' --include '*.jpg' --include '*.jpeg' --include '*.gif' --include '*.svg' --include '*.webp' \
  --exclude '*' \
  "$BUILD_DIR/" "$DIST_DIR/" || true

# Preserve lwarpmk.conf for repeatable builds
if [[ -f "lwarpmk.conf" ]]; then
  cp -f "lwarpmk.conf" "$DIST_DIR/"
fi

echo "[build_html] Cleaning temporary build dir..."
rm -rf "$BUILD_DIR"

echo "[build_html] Done. Final files are in '$DIST_DIR'. Open '$DIST_DIR/${BASENAME}.html' in your browser."
