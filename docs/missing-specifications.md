# Missing Specifications / Blockers

| ID | Area | Missing specification | Impact | Status |
|----|------|------------------------|--------|--------|
| MS-001 | Reference audit | All AJ Cabinet screenshots and full video | Cannot build confirmed command inventory or parity matrix | BLOCKED |
| MS-002 | Runtime verification | SketchUp 2021–2026 on Windows test environment | Cannot prove native API/UI/observer/packaging compatibility | BLOCKED (env) |
| MS-003 | Hardware catalogs | Verified manufacturer technical data/presets | Manufacturer-specific dimensions cannot be fabricated | OPEN (adapter-based only) |
| MS-004 | CNC machine targets | Documented machine configs, coords, tools, postprocessor specs | Machine-specific CNC output cannot be claimed verified | OPEN |
| MS-005 | Dimension semantics | AJ-observed finished vs nominal vs cutting rules per process | Must be defined explicitly; risk of mismatch until reference available | OPEN |
| MS-006 | Existing codebase | Prior JP Cabinet PRO implementation (if any outside workspace) | None supplied; starting fresh scaffold | N/A |

## Additional notes (Phase 1/2 scaffold)
- **Ruby runtime for local test execution:** not present in container; authored Minitest suites unexecuted here (see `docs/test-report.md`).
- **Vertical slice UI→SketchUp bridge:** `ui/js/bridge.js` dispatches to `window.sketchup.*` when hosted in HtmlDialog; native Ruby callback handlers and dialog wiring not yet implemented.
- **Technical drawing:** currently a deterministic view-model scaffold (`drawing/technical_view.rb`), not vector-projected geometry/PDF/DXF.
- **Construction rules:** `cabinet/construction.rb` uses placeholder formulas not yet differentiated by all specified construction rules.
