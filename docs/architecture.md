# JP Cabinet PRO — Architecture (Phase 1 Draft)

**Status:** DRAFT (Phase 0 reference audit BLOCKED; behavior inventory incomplete)

## 1. Goals
- Modular, testable Ruby/JS architecture for SketchUp extension.
- Single canonical data model; separate UI, geometry mutation, manufacturing calc, export.
- Transaction-safe SketchUp operations with undo/rollback.

## 2. Target platform
- SketchUp 2021–2026, Windows initially (dev in Linux container; native runtime verification pending).
- Units: millimeters internally.
- Languages: Albanian and English.

## 3. Module map (planned)
1. **Extension Bootstrap** — loader, registration, menu/toolbar wiring (`jp_cabinet_pro.rb`, `loader.rb`)
2. **Command Registry** — central command definitions (id, labels, schema, handler, undo, test id)
3. **SketchUp Adapter** — isolated API calls, transactions, observers guard
4. **Selection and Geometry Extraction** — identify cabinets/parts, transforms, instance handling
5. **Parametric Furniture Engine** — formulas & construction rules
6. **Cabinet Construction Engine** — build/rebuild panel geometry
7. **Door and Front Engine** — fronts/doors configs
8. **Drawer Engine** — drawer configs + adapter catalog
9. **Material Engine** — catalog, assignments, quantities
10. **Edge Banding Engine** — per-edge bands, lengths, dimension semantics
11. **Hardware Engine** — structured hardware data/BOM integration
12. **Component Library** — indexing, lazy load, import/export (original assets only)
13. **Manufacturing BOM** — aggregation, stable IDs, snapshots
14. **Cut List** — manufacturing-ready list/export
15. **Nesting Optimizer** — 2D rectangular nesting, validated placements
16. **Technical Drawing Engine** — vector views, layouts, PDF/DXF
17. **Report Generator** — canonical-data reports
18. **CNC Export Adapters** — generic DXF/CSV; machine-specific only with verified specs
19. **Persistence and Migration** — JSON/config, deterministic serialization, versioning
20. **Diagnostics and Test Framework** — logs, Ruby/JS tests

## 4. API contracts (high-level, to be refined)
- Each module exposes a Ruby namespace/class API with documented inputs/outputs and error types.
- Engines are pure/calculable where possible; SketchUp mutations go through Adapter in transactions.
- UI (HtmlDialog) communicates via JSON messages to a bridge; no direct geometry logic in JS.

## 5. Data flow (vertical slice target)
`Select Cabinet → Edit Dimensions (UI/Command) → validate/preview → Cabinet Construction rebuild (transaction) → Parametric/Part recalc → BOM refresh → Cut List refresh → invalidate Nesting/Drawings/Reports → Technical View generation`

## 6. Canonical model (see `docs/data-model.md`)
Single source of truth; immutable calculation snapshots for manufacturing outputs.

## 7. Known blockers
- Phase 0 reference media missing: full AJ command parity inventory incomplete.
- SketchUp runtime not available in this environment: native integration/observer/packaging tests BLOCKED until run in SketchUp 2021–2026 on Windows.
