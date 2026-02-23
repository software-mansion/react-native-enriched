#!/bin/bash
#
# Downloads the Lexbor repository and generates the amalgamation header
# using the official single.pl script.
#
# Usage:
#   bash scripts/setup-lexbor.sh
#
# See: https://github.com/lexbor/lexbor#generate-amalgamation
#
set -euo pipefail

# Pin to a specific commit on master (v2.7.0, includes single.pl)
LEXBOR_COMMIT="d3f3c2705c805c6c109ebcdd38202d6b51b191fd"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/cpp/lexbor"
OUTPUT_FILE="$OUTPUT_DIR/lexbor.h"

# Skip if already present
if [ -f "$OUTPUT_FILE" ]; then
  echo "✓ lexbor.h already exists at $OUTPUT_FILE"
  echo "  Delete it and re-run to regenerate."
  exit 0
fi

echo "→ Downloading Lexbor (commit ${LEXBOR_COMMIT:0:12})..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

git clone --depth 1 https://github.com/lexbor/lexbor.git "$TMPDIR/lexbor" 2>/dev/null

cd "$TMPDIR/lexbor"
git fetch --depth 1 origin "$LEXBOR_COMMIT" 2>/dev/null
git checkout "$LEXBOR_COMMIT" 2>/dev/null

echo "→ Generating amalgamation (html + css modules)..."

mkdir -p "$OUTPUT_DIR"
perl single.pl html css > "$OUTPUT_FILE"

LINE_COUNT=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
echo "✓ Generated $OUTPUT_FILE ($LINE_COUNT lines)"
