# JP Cabinet PRO — Completion Matrix (Milestone 1 Audit)

**Date:** 2026-11-13  
**Basis:** source inspection + `./scripts/test_all.sh` (PASS: Ruby 16 files, 56 runs, 297 assertions; JS 7 suites + syntax).  
**Runtime:** No SketchUp 2021–2026 in container; SketchUp API paths are source-reviewed only and **UNVERIFIED**. Phase 0 AJ reference audit **BLOCKED** (no media in workspace).

Legend: **IMPLEMENTED** (code+logic complete for scope), **TESTED** (automated non-runtime or runtime evidence), **PARTIAL**, **BLOCKED**, **FAILED**.

## 1. Audit Summary

| Area | Evidence (files) | State | Notes |
|------|-------------------|-------|------|
| Extension bootstrap/loader | `jp_cabinet_pro.rb`, `src/jp_cabinet_pro/bootstrap/loader.rb` | PARTIAL | Registers extension/loads modules and calls `register_defaults`; no native toolbar/menu/command UI objects, no observer registration. |
| Command registry/factory | `commands/registry.rb`, `commands/factory.rb`, 6 command classes | PARTIAL/TESTED(logic) | 6 prototype commands registered and factory-resolved; missing SketchUp UICommand wiring, execute contracts vary, many required commands absent. |
| SketchUp adapter | `adapter/sketchup_adapter.rb` | PARTIAL | Transaction wrapper only; no entity creation/rebuild, attribute read/write, selection access, material sync, operation grouping helpers. |
| Selection/extraction | `selection/extractor.rb` | BLOCKED(stub) | Returns `sketchup_runtime_required`; no recursive traversal, transform handling, cabinet identification, double-count prevention. |
| Parametric dimensions | `parametric/dimensions.rb` | IMPLEMENTED/TESTED | Rule-aware validation/internal dims (top/bottom/back/groove/inset/shelves). No AJ-verified formulas. |
| Cabinet construction/rebuild | `cabinet/construction.rb` | PARTIAL/TESTED(logic) | Deterministic part list (carcass/shelves/back) + fronts/drawers/hardware layout integration; no SketchUp entities, no plinth/legs/partitions/HDF groove geometry, no safe edit of existing groups/defs. |
| Doors/fronts | `doors/front_engine.rb` | PARTIAL/TESTED | Spec-derived layout/validation; AJ behavior unverified; no geometry. |
| Drawers | `drawers/engine.rb` | PARTIAL/TESTED | Layout/box parts; slide clearances adapter-based placeholders; no geometry/catalog dims. |
| Materials/edge banding/hardware | `materials/engine.rb`, `edge_banding/engine.rb`, `hardware/engine.rb` | PARTIAL/TESTED | Calculations/BOM aggregation OK; no SketchUp material sync, no process-specific compensation, no verified catalogs. |
| BOM/CutList | `bom/generator.rb`, `cutlist/generator.rb` | PARTIAL/TESTED | Aggregation and nominal cutlist; canonical/process semantics incomplete. |
| Nesting | `nesting/optimizer.rb`, `commands/plan_nesting.rb` | PARTIAL/TESTED | 2D validated placements/utilization/offcuts/cut-length estimate; no manual/visual UI, no incremental perf tuning. |
| Drawing/report/CNC | `drawing/technical_view.rb`, `report/generator.rb`, `cnc/exporter.rb`, commands | PARTIAL/TESTED | Schematic SVG/HTML and generic CSV/DXF(rect) only; not true projection/PDF/verified CNC. |
| Library | `library/manager.rb`, `commands/manage_library.rb` | PARTIAL/TESTED | JSON index ops tested; insert/replace `SKETCHUP_RUNTIME_REQUIRED`; no native UI. |
| Persistence/revision | `persistence/store.rb`, `snapshot.rb`, `diagnostics/revision_tracker.rb` | PARTIAL/TESTED | File snapshots and in-memory invalidation tracking; no SketchUp AttributeDictionary persistence/restore, no incremental dependency engine. |
| UI/HtmlDialog | `ui/*`, `ui/dialog*.rb`, `ui/dialog_controller.rb` | PARTIAL | Dimensions dialog + module info pages, bridge/callbacks for preview/apply/cancel; no full 10-panel app, limited i18n, no live binding to all engines/commands, native execution unverified. |
| Tests | `tests/ruby/*`, `tests/js/*`, `scripts/test_all.sh` | TESTED(non-runtime) | Logic/parity/syntax covered; no real SketchUp runtime tests (create/resize/nested transforms/Undo-Redo/save-reopen observers). |
| Build/release | `scripts/build_rbz.rb` | BLOCKED | Script scaffold; `zip` gem missing in env; no validated RBZ/install checks. |

## 2. Command Inventory (actual)

| Command ID | Handler/behavior | Registry | Executable now (non-SketchUp logic) | SketchUp-native | Status |
|------------|------------------|----------|--------------------------------------|-----------------|--------|
| `cabinet.edit_dimensions` | Preview/apply pipeline → parts/fronts/drawers/hardware/BOM/cutlist/materials/EB/nesting(opt)/view+SVG/snapshot/revision | Yes | Yes (logic) | No (no selection/entity rebuild/UI wiring) | PARTIAL/TESTED |
| `nesting.plan` | 2D nesting plan/validation | Yes | Yes | N/A calc | PARTIAL/TESTED |
| `report.generate` | Snapshot → structured report + HTML | Yes | Yes | N/A | PARTIAL/TESTED |
| `cnc.export_csv` | Generic CSV from rows | Yes | Yes | N/A | PARTIAL/TESTED |
| `cnc.export_nesting_dxf` | Generic DXF rect outlines from validated nesting | Yes | Yes | N/A | PARTIAL/TESTED |
| `library.manage` | Search/upsert/import/export metadata | Yes | Yes | Insert/replace blocked | PARTIAL/TESTED |
| Create cabinet / rebuild in model / materials-hardware apply as model ops | - | No | No | No | NOT_IMPLEMENTED |
| PROJECT/3D DESIGN/QUOTATIONS/SKETCHUP COMPONENTS/INDUSTRIAL LAYOUT | - | No | No | No | BLOCKED (AJ refs) / NOT_IMPLEMENTED |

## 3. Native SketchUp Integration Gaps (blocking real functionality)

- No `UI::Toolbar`, `UI.menu`, `UI::Command`, context menu registration.
- No cabinet creation as `Sketchup::Group/ComponentInstance` with tagged definition/attributes.
- No selection identification of JP Cabinet entities; no recursive bounds/transform-safe extraction.
- No `AttributeDictionary` schema (`jp_cabinet_pro`) for params/snapshot/revision persistence and restore.
- No model observers/app observers with `@suspended` recursion guards.
- `HtmlDialog` created only via helper; not shown from commands; callback set limited to dimensions; no `set_url/set_html` app shell routing for 10 panels.
- No shared-component-definition safe edit strategy (make_unique/copy rules) implemented.
- Undo/Redo: transaction wrapper exists but not used around real entity mutations.

## 4. Performance / Quality Issues Observed

- Full pipeline recomputation on apply (acceptable now, but no incremental dirty-flag execution beyond tracker state).
- Nesting is O(n * sheets * free_rects) greedy; fine for prototype, needs profiling at scale.
- Repeated Hash symbolize/dup patterns; minor allocation overhead.
- UI sends full payloads; no throttling/debounce.
- Docs contain stale counts in places; must keep evidence-based.

## 5. Milestone 1 Priorities (this iteration)

1. Implement native-ready SketchUp integration layer: richer adapter (model/selection/attributes/entities helpers guarded), extractor with recursive transform-aware logic, bootstrap UI registration (toolbar/menu/commands/dialog show), cabinet builder/rebuilder operating on SketchUp entities when available, persistence via attributes, observer scaffold with recursion protection.
2. Extend construction/parametric support (plinth/legs/partitions/solid/HDF-grooved back details where deterministic) and wire dependency invalidation consistently.
3. Complete HtmlDialog app shell/panels with real command bindings and EN/SQ strings.
4. Add tests for new logic (Ruby/JS) and run `scripts/test_all.sh`.
5. Attempt RBZ packaging with system `zip` fallback; report honest status.

**Completion matrix status:** IMPLEMENTED/TESTED for this audit artifact (evidence-based). Overall project remains **PARTIAL/BLOCKED** for native runtime and AJ parity.
