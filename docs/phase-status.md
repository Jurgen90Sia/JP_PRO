# Phase Status

| Phase | Status | Evidence / Notes |
|-------|--------|------------------|
| 0 — Reference audit & feature inventory | **BLOCKED** | `docs/reference-audit.md`, `command-inventory.csv` (placeholder), `feature-parity-matrix.md`, `workflow-dependency-map.md`, `unverified-behavior.md`. No screenshots/video in workspace; no AJ behaviors confirmed. |
| 1 — Architecture, data contracts, project foundation | **IN PROGRESS (scaffold)** | `docs/architecture.md`, `docs/data-model.md`, `docs/missing-specifications.md`, module structure, bootstrap/registry/adapter/persistence/selection scaffolds, config, README. Contracts/runtime incomplete. |
| 2 — Parametric cabinet geometry | **IN PROGRESS (prototype)** | Validation/internal calc and placeholder part builder; construction-rule-dependent formulas and real SketchUp rebuild pending. |
| 3 — Editors, doors, drawers, materials, hardware | **IN PROGRESS (scaffold)** | Dimensions HtmlDialog scaffold (`ui/dialogs/dimensions.html`, CSS/JS/bridge) with client validation/preview/apply/cancel dispatch; native Ruby callbacks/wiring and SketchUp selection/rebuild not implemented. Materials/edge-banding/hardware engine scaffolds added; doors/drawers not implemented. |
| 4 — Component library | **NOT_STARTED** | — |
| 5 — BOM, Cut List, material calculations | **IN PROGRESS (prototype)** | Basic BOM/cutlist generators; edge-banding length/material-qty scaffolds; full rules/semantics pending. |
| 6 — Nesting optimizer | **SCAFFOLD (not implemented)** | `nesting/optimizer.rb` raises NotImplementedError; no fabricated utilization. |
| 7 — Technical drawings and reports | **IN PROGRESS (prototype)** | Deterministic view-model scaffold (`drawing/technical_view.rb`); no vector projection/PDF/DXF/report engine. |
| 8 — CNC adapters and exports | **SCAFFOLD** | Generic CSV helper in `cnc/exporter.rb`; DXF/machine-specific unimplemented/unverified. |
| 9 — Complete UI, icons, command integration | **IN PROGRESS (scaffold)** | Original SVG icons started (`icons/svg/cabinet.svg`, `dimensions.svg`); command registry placeholder; no full module UI/toolbar integration. |
| 10 — Native SketchUp testing, stabilization, RBZ | **BLOCKED** | No SketchUp runtime; authored Ruby tests unexecuted in container; no RBZ build. |

**Parity claim:** None. **Production-ready:** No.
