#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "== JS syntax =="
node --check ui/js/bridge.js
node --check ui/js/dimensions.js
node --check scripts/vertical_slice_demo.mjs
node --check scripts/export_cutlist_csv.mjs
echo "== JS tests =="
node tests/js/test_dimensions.mjs
node tests/js/test_construction.mjs
node tests/js/test_vertical_slice.mjs
node tests/js/test_edge_banding.mjs
node tests/js/test_bom_aggregation.mjs
node tests/js/test_fronts_drawers.mjs
node tests/js/test_materials.mjs
echo "== Ruby tests =="
for f in tests/ruby/test_*.rb; do
  echo "-- $f"
  ruby "$f"
done
echo "ALL_PASS"
