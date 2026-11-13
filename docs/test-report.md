# Test Report — JP Cabinet PRO

**Date:** 2026-11-13  
**Environment:** Linux container (`/workspace/app`), Ruby 3.3.13, Node available, no SketchUp runtime.

## Automated tests executed (Ruby/Minitest) — **PASS**
| Suite | Path | Scope | Status | Result |
|-------|------|-------|--------|--------|
| Dimensions validation | `tests/ruby/test_dimensions.rb` | Rule-aware validation, internal dim calc | **PASS** | 4 runs, 10 assertions |
| BOM/CutList generation | `tests/ruby/test_bom_cutlist.rb` | Part build (scaffold), BOM aggregation, cut list fields | **PASS** | 2 runs, 8 assertions |
| Vertical slice pipeline | `tests/ruby/test_vertical_slice.rb` | Preview/apply → parts → BOM → CutList → view+SVG + materials/edge_banding + nesting(opt) + invalidations + snapshot + revision_state | **PASS** | 5 runs, 41 assertions |
| Edge banding | `tests/ruby/test_edge_banding.rb` | Per-edge length totals by material/thickness | **PASS** | 1 run, 1 assertion |
| Fronts/Drawers validation | `tests/ruby/test_fronts_drawers.rb` | Spec-derived config validation scaffolds | **PASS** | 4 runs, 6 assertions |
| Revision tracker | `tests/ruby/test_revision_tracker.rb` | Downstream invalidation/valid state tracking + snapshot view | **PASS** | 3 runs, 12 assertions |
| Snapshot persistence | `tests/ruby/test_snapshot.rb` | Immutable snapshot build/serialize (incl. nesting, view_svg) | **PASS** | 1 run, 11 assertions |
| Materials | `tests/ruby/test_materials.rb` | Net/gross quantities, waste factor validation | **PASS** | 3 runs, 6 assertions |
| CNC exporter | `tests/ruby/test_cnc_exporter.rb` | Generic CSV; generic nesting DXF (rect outlines, not verified CNC); machine-unverified | **PASS** | 4 runs, 30 assertions |
| Nesting optimizer | `tests/ruby/test_nesting.rb` | 2D nesting strategies, kerf/trim/grain/grouping, bounds/overlap validation, utilization, unplaced, offcuts, cut_length estimate | **PASS** | 7 runs, 62 assertions |
| Component library | `tests/ruby/test_library.rb` | JSON index upsert/search/find/favorites/recent/save/load/import/export; SketchUp insert requires runtime | **PASS** | 4 runs, 15 assertions |
| Drawing & Report | `tests/ruby/test_drawing_report.rb` | View model + schematic SVG scaffold; HTML report from canonical snapshot (nesting/view_svg) | **PASS** | 4 runs, 24 assertions |
| Command registry | `tests/ruby/test_command_registry.rb` | Default registrations, contract fields, factory resolution | **PASS** | 3 runs, 29 assertions |
| Command integration | `tests/ruby/test_commands_integration.rb` | PlanNesting/GenerateReport/ExportCnc/ManageLibrary commands end-to-end (non-SketchUp) | **PASS** | 3 runs, 15 assertions |
| Persistence store | `tests/ruby/test_persistence_store.rb` | Envelope serialize/deserialize/migrate, save/load | **PASS** | 2 runs, 5 assertions |

**Total:** 50 runs, 275 assertions, 0 failures, 0 errors, 0 skips (`scripts/test_all.sh`).

## JS/UI logic tests (executed) — **PASS**
| Suite | Path | Scope | Status |
|-------|------|-------|--------|
| Dimensions client logic | `tests/js/test_dimensions.mjs` | Internal dim calc + validation parity | **PASS** |
| Construction parity | `tests/js/test_construction.mjs` | Rule-based part sizing/back/shelf parity | **PASS** |
| Vertical slice parity | `tests/js/test_vertical_slice.mjs` | Non-runtime pipeline parity | **PASS** |
| Edge banding | `tests/js/test_edge_banding.mjs` | Length totals logic | **PASS** |
| BOM aggregation | `tests/js/test_bom_aggregation.mjs` | Aggregation key/matching logic | **PASS** |
| Fronts/Drawers validation | `tests/js/test_fronts_drawers.mjs` | Spec-derived config validation | **PASS** |
| Materials | `tests/js/test_materials.mjs` | Net/gross quantity parity | **PASS** |
| Syntax checks | `ui/js/*.js`, `scripts/*.mjs` | `node --check` | **PASS** |

## Integration / native runtime (required, not executed)
| Area | Status | Reason |
|------|--------|--------|
| SketchUp extension registration, toolbar/menu, HtmlDialog bridge | **BLOCKED** | No SketchUp 2021–2026 runtime |
| Real geometry rebuild, selection, nested/mirrored transforms, observers | **BLOCKED** | Requires SketchUp model/runtime |
| Undo/Redo transaction safety in SketchUp | **BLOCKED** | Requires SketchUp runtime |
| True projected drawings, PDF/DXF machine/CAD validity, nesting manual UI | **NOT_IMPLEMENTED/UNVERIFIED** | Schematic SVG/HTML/rect-DXF scaffolds only; no certified CAD/CNC validation |

## Summary
- Automated logic tests executed: **Ruby 50/275 PASS, JS all PASS**.
- Runtime-verified in SketchUp: NO.
- Production-ready: NO.
