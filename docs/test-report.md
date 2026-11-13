# Test Report — JP Cabinet PRO

**Date:** 2026-11-13  
**Environment:** Linux container (`/workspace/app`), Ruby 3.3.13, Node v24.22.1, no SketchUp runtime.

## Automated tests executed (Ruby/Minitest) — **PASS**
| Suite | Path | Scope | Result |
|-------|------|-------|--------|
| Dimensions validation | `tests/ruby/test_dimensions.rb` | Rule-aware validation, internal dim calc | 4 runs, 10 assertions |
| BOM/CutList generation | `tests/ruby/test_bom_cutlist.rb` | Part build (scaffold), BOM aggregation, cut list fields | 2 runs, 8 assertions |
| Vertical slice pipeline | `tests/ruby/test_vertical_slice.rb` | Preview/apply → parts/fronts/drawers/hardware → BOM/CutList → view+SVG + materials/edge_banding + nesting(opt) + invalidations + snapshot + revision_state | 6 runs, 48 assertions |
| Edge banding | `tests/ruby/test_edge_banding.rb` | Per-edge length totals by material/thickness | 1 run, 1 assertion |
| Fronts/Drawers validation & layout | `tests/ruby/test_fronts_drawers.rb` | Spec-derived config validation + prototype layout generation | 6 runs, 14 assertions |
| Hardware | `tests/ruby/test_hardware.rb` | Validation, BOM lines, aggregation (adapter-based) | 3 runs, 7 assertions |
| Revision tracker | `tests/ruby/test_revision_tracker.rb` | Downstream invalidation/valid state tracking + snapshot view | 3 runs, 12 assertions |
| Snapshot persistence | `tests/ruby/test_snapshot.rb` | Immutable snapshot build/serialize (incl. nesting, view_svg) | 1 run, 11 assertions |
| Materials | `tests/ruby/test_materials.rb` | Net/gross quantities, waste factor validation | 3 runs, 6 assertions |
| CNC exporter | `tests/ruby/test_cnc_exporter.rb` | Generic CSV; generic nesting DXF (rect outlines, not verified CNC); machine-unverified | 4 runs, 30 assertions |
| Nesting optimizer | `tests/ruby/test_nesting.rb` | 2D nesting strategies, kerf/trim/grain/grouping, bounds/overlap validation, utilization, unplaced, offcuts, cut_length estimate | 7 runs, 62 assertions |
| Component library | `tests/ruby/test_library.rb` | JSON index upsert/search/find/favorites/recent/save/load/import/export; SketchUp insert requires runtime | 4 runs, 15 assertions |
| Drawing & Report | `tests/ruby/test_drawing_report.rb` | View model + schematic SVG scaffold; HTML report from canonical snapshot (nesting/view_svg/fronts/drawers/hardware) | 4 runs, 24 assertions |
| Command registry | `tests/ruby/test_command_registry.rb` | Default registrations, contract fields, factory resolution | 3 runs, 29 assertions |
| Command integration | `tests/ruby/test_commands_integration.rb` | PlanNesting/GenerateReport/ExportCnc/ManageLibrary commands end-to-end (non-SketchUp) | 3 runs, 15 assertions |
| Persistence store | `tests/ruby/test_persistence_store.rb` | Envelope serialize/deserialize/migrate, save/load | 2 runs, 5 assertions |

**Total:** 56 runs, 297 assertions, 0 failures, 0 errors, 0 skips.

## JS/UI logic tests (executed) — **PASS**
| Suite | Path | Scope | Status |
|-------|------|-------|--------|
| Dimensions client logic | `tests/js/test_dimensions.mjs` | Internal dim calc + validation parity | PASS |
| Construction parity | `tests/js/test_construction.mjs` | Rule-based part sizing/back/shelf parity | PASS |
| Vertical slice parity | `tests/js/test_vertical_slice.mjs` | Non-runtime pipeline parity | PASS |
| Edge banding | `tests/js/test_edge_banding.mjs` | Length totals logic | PASS |
| BOM aggregation | `tests/js/test_bom_aggregation.mjs` | Aggregation key/matching logic | PASS |
| Fronts/Drawers validation | `tests/js/test_fronts_drawers.mjs` | Spec-derived config validation | PASS |
| Materials | `tests/js/test_materials.mjs` | Net/gross quantity parity | PASS |
| Syntax checks | `ui/js/*.js`, `scripts/*.mjs` | `node --check` | PASS |

## Demo / script checks
- `scripts/vertical_slice_demo.mjs`: PASS (non-runtime pipeline output generated).
- `scripts/export_cutlist_csv.mjs`: script present (prototype); CSV export logic covered via Ruby/JS tests and exporter.
- `scripts/build_rbz.rb`: scaffold only (**not executed**; `zip` gem unavailable, release gates not met).

## Integration / native runtime — NOT EXECUTED (BLOCKED/UNVERIFIED)
| Area | Status | Reason |
|------|--------|--------|
| SketchUp extension registration, toolbar/menu, HtmlDialog bridge | BLOCKED | No SketchUp 2021–2026 runtime |
| Real geometry rebuild, selection, nested/mirrored transforms, observers | BLOCKED | Requires SketchUp model/runtime |
| Undo/Redo transaction safety in SketchUp | BLOCKED | Requires SketchUp runtime |
| True projected drawings, PDF/DXF machine/CAD validity, nesting manual UI | NOT_IMPLEMENTED/UNVERIFIED | Schematic SVG/HTML/rect-DXF scaffolds only |

## Summary
- Automated logic tests executed: **Ruby 56/297 PASS, JS all PASS** (`./scripts/test_all.sh`).
- Runtime-verified in SketchUp: **NO**.
- Production-ready: **NO**. Parity: **NOT CLAIMED**.
