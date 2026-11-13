# JP Cabinet PRO

Original SketchUp extension scaffold/prototype for parametric furniture workflow:  
Component Library → Parametric Cabinet → 3D Editing → Materials → Hardware → BOM → Cut List → Nesting → Technical Drawings → Reports → CNC Export.

## Status (final)
- **Phase 0 reference audit: BLOCKED** — AJ Cabinet screenshots/video not provided in workspace; no behaviors invented, **no parity claimed**.
- **SketchUp native runtime verification: BLOCKED/UNVERIFIED** (no SketchUp 2021–2026 environment). No RBZ built.
- **Automated non-runtime tests: PASS** — Ruby 16 suites, 56 runs, 297 assertions, 0 failures; JS syntax + 7 suites PASS. Run: `./scripts/test_all.sh`
- **Production-ready: NO.**

See `docs/final-status.md`, `docs/test-report.md`, `docs/phase-status.md`, and `docs/missing-specifications.md`.

## Repository
- `docs/` — audit/inventory/parity, architecture, data model, API contracts, manuals, compatibility, status, tests
- `jp_cabinet_pro.rb` + `src/jp_cabinet_pro/` — modular Ruby implementation (bootstrap, commands, adapter/selection stubs, parametric/cabinet, fronts/drawers, materials/edge/hardware, BOM/cutlist, nesting, drawing/report, CNC, library, persistence/diagnostics, UI controllers)
- `ui/` — HtmlDialog/CSS/JS scaffolds (dimensions, nesting, library, report, module shell)
- `icons/svg/` — original SVG icons
- `config/` — defaults and i18n
- `tests/ruby/`, `tests/js/` — automated tests
- `scripts/` — `test_all.sh`, vertical-slice demo, cutlist CSV demo, `build_rbz.rb` (scaffold)

## Key prototype capabilities (logic-tested, non-runtime)
- Rule-aware dimension validation/internal calc and deterministic cabinet/front/drawer part generation
- BOM aggregation + cut list, material net/gross quantities, edge-banding totals
- 2D nesting optimizer with geometric validation/utilization and offcuts (no manual UI)
- Schematic SVG view model and HTML snapshot report; generic CSV and nesting DXF exports (**not verified CNC/CAD**)
- Component library metadata index (JSON); revision tracking and immutable snapshots
- Command registry/factory for prototype commands

## Limitations (explicit)
- No confirmed AJ behavior without reference media; command inventory includes inferred/unverified prototypes.
- No real SketchUp entity rebuild, native UI wiring, observers, or runtime-verified exports.
- Manufacturer-specific hardware/CNC presets require verified data (not fabricated).
- Generic DXF/CSV are not verified CNC programs.

## Install / compatibility
Draft only — see `docs/installation.md` and `docs/version-compatibility-report.md` (all targets UNTESTED).
