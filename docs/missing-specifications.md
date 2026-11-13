# Missing Specifications / Blockers

| ID | Area | Missing specification | Impact | Status |
|----|------|------------------------|--------|--------|
| MS-001 | Reference audit | All AJ Cabinet screenshots and full video | Cannot build confirmed command inventory or parity matrix; cannot verify AJ behavior | **BLOCKED** |
| MS-002 | Runtime verification | SketchUp 2021–2026 (Windows) test environment | Cannot prove native API/UI/observer/geometry/undo/packaging compatibility | **BLOCKED (env)** |
| MS-003 | Hardware catalogs | Verified manufacturer technical data/presets (hinges, slides, lifts, etc.) | Manufacturer-specific dimensions cannot be fabricated; adapter-based only | **OPEN** |
| MS-004 | CNC machine targets | Documented machine configs, coords, tools, postprocessor specs | Machine-specific CNC output cannot be claimed verified (generic CSV/DXF only) | **OPEN** |
| MS-005 | Dimension semantics | AJ-observed finished vs nominal vs cutting rules per process/edge compensation | Prototype uses nominal placeholders; risk of mismatch until confirmed | **OPEN** |
| MS-006 | Existing codebase | Prior JP Cabinet PRO implementation outside workspace | None supplied; implemented from scaffold in this repo | **N/A** |

## Additional notes (2026-11-13)
- **RBZ build:** `scripts/build_rbz.rb` is a scaffold; `zip` gem not installed and release gates not met — RBZ not built.
- **UI/commands:** prototype command set registered (`cabinet.edit_dimensions`, `nesting.plan`, `report.generate`, `cnc.export_csv`, `cnc.export_nesting_dxf`, `library.manage`); many AJ/UI modules (PROJECT, 3D DESIGN, QUOTATIONS, SKETCHUP COMPONENTS, INDUSTRIAL LAYOUT, full editors) unimplemented or unknown pending audit.
- **Exports/drawings:** schematic SVG/HTML and generic rect-DXF are unverified prototypes, not production/CNC-certified outputs.
