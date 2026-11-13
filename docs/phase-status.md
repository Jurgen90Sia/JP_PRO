# Phase Status

| Phase | Status | Evidence / Notes |
|-------|--------|------------------|
| 0 — Reference audit & feature inventory | **BLOCKED** | No AJ Cabinet screenshots/video in workspace. `docs/reference-audit.md`, `command-inventory.csv`, `feature-parity-matrix.md`, `workflow-dependency-map.md`, `unverified-behavior.md`. No AJ behaviors confirmed; no parity claimed. |
| 1 — Architecture, data contracts, project foundation | **PROTOTYPE (incomplete)** | Modular architecture, canonical model/docs, bootstrap/loader, command registry+factory, adapter/selection stubs, persistence store+snapshots, diagnostics/revision tracker, config/i18n. Native SketchUp contracts/runtime incomplete. |
| 2 — Parametric cabinet geometry | **PROTOTYPE (incomplete)** | Rule-aware validation/internal calc and deterministic part builder for top/bottom/back/shelves. No real SketchUp entity rebuild/transactional mutation. Formulas not reference-verified. |
| 3 — Editors, doors, drawers, materials, hardware | **PROTOTYPE (incomplete)** | Dimensions HtmlDialog/dialog-controller scaffold (native wiring unverified). Fronts/drawers layout+validation, hardware structured/BOM/aggregation, materials net/gross and edge-banding integrated and tested. No SketchUp geometry/selection runtime. |
| 4 — Component library | **PROTOTYPE (incomplete)** | JSON-backed index (search/filter/favorites/recent/import/export/save/load). Insert/replace `SKETCHUP_RUNTIME_REQUIRED`. No native UI/lazy-load perf/copyrighted assets. |
| 5 — BOM, Cut List, material calculations | **PROTOTYPE (incomplete)** | BOM aggregation, cutlist (`size_kind: nominal`), edge-banding totals, material net/gross quantities. Full canonical/process semantics and UI integration pending. |
| 6 — Nesting optimizer | **PROTOTYPE (incomplete)** | 2D nesting (4 strategies), kerf/trim, grain-aware rotation flag, grouping, geometric validation, utilization from validated placements, unplaced/offcuts, cut-length estimate. No manual UI/visualization/optimized cut path; AJ parity unverified. |
| 7 — Technical drawings and reports | **PROTOTYPE (incomplete)** | Deterministic view model + schematic SVG scaffold and HTML report from canonical snapshot. **Not true SketchUp projection; no PDF/DXF rendering engine, barcodes, or production layouts.** |
| 8 — CNC adapters and exports | **PROTOTYPE/SCAFFOLD** | Generic CSV and generic nesting DXF (rect outlines, not verified CNC/CAD). Machine-specific outputs UNVERIFIED/unimplemented. |
| 9 — Complete UI, icons, command integration | **SCAFFOLD (incomplete)** | Module shell, dialog scaffolds (dimensions/nesting/library/report), bridge, original SVG icons, command registry/factory wiring for prototype commands. No full module UI/toolbar/menu/context native integration; many modules not implemented. |
| 10 — Native SketchUp testing, stabilization, RBZ | **BLOCKED** | Logic tests PASS (**Ruby 56/297, JS all PASS** via `scripts/test_all.sh`). No SketchUp 2021–2026 runtime for native/integration tests, compatibility verification, or RBZ build/validation. `scripts/build_rbz.rb` scaffold only. |

**Vertical slice:** prototype pipeline logic tested PASS (non-runtime), including fronts/drawers/hardware, materials/edge_banding, optional nesting, schematic SVG, snapshot and revision state. **SketchUp selection, real geometry rebuild, native HtmlDialog execution, and true drawing rendering NOT runtime-verified.**  
**Parity claim:** None. **Production-ready:** No.
