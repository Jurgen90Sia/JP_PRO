# Next Steps (Prioritized)

**Current state:** prototype/scaffold with strong non-runtime logic coverage (**Ruby 46/253, JS all PASS**). **No SketchUp runtime verification. Phase 0 AJ reference audit BLOCKED** (no screenshots/video in workspace). No parity/production/RBZ claims.

## 1. Unblock Phase 0 (required for confirmed parity)
- Obtain and place AJ Cabinet screenshots + full video in workspace.
- Produce timestamped video observation log; classify CONFIRMED/INFERRED/UNKNOWN.
- Populate `docs/command-inventory.csv`, `docs/feature-parity-matrix.md`, `docs/workflow-dependency-map.md`, `docs/unverified-behavior.md` from evidence.
- Reconcile prototype behavior/fields with confirmed AJ commands; record PASS/FAIL/BLOCKED per command.

## 2. SketchUp runtime vertical slice (critical path)
- Implement native `Selection/Extractor` and transaction-safe `Cabinet::Construction` geometry in SketchUp (real entities, component/group handling, nested/mirrored transforms).
- Wire HtmlDialog callbacks (`UI::DialogController/Dialog`) to `cabinet.edit_dimensions` in SketchUp; show preview/apply/cancel and handle Undo/Redo.
- Verify end-to-end: Select Cabinet → Edit Dimensions → Rebuild Geometry → Update BOM → Generate Technical View in SketchUp 2021–2026 (Windows).

## 3. Canonical model hardening
- Finalize finished/nominal/cutting dimension semantics per process (edge banding compensation not global).
- Enforce stable IDs, source geometry refs, revision propagation, and snapshot consumers; prevent double-counting of shared definitions.
- Implement dependency invalidation/refresh for nesting/drawings/reports on relevant changes.

## 4. Module completion (after evidence/runtime)
- **Drawings/Reports:** true projected/vector views, A4–A0 layouts, PDF/DXF export, title blocks/labels/barcodes per confirmed spec.
- **Nesting:** integrate into UI/workflow, manual repositioning/rotation/collision UI, offcut visualization, cut-length calculation (validated), grain/kerf/trim per spec.
- **CNC:** keep generic DXF/CSV as unverified exports; add machine-specific adapters only with documented configs/tools/coords and real validation.
- **Library/UI:** lazy-loading/indexing UI, SketchUp insert/replace/observers (loop-safe), full module screens and command wiring (no decorative-only actions).
- **Materials/Edge/Hardware/Doors/Drawers:** implement geometry/rules and catalogs from confirmed/verified data only.

## 5. Quality, packaging, release gates
- Run Ruby+JS suites in CI-capable env; add SketchUp integration tests where available.
- Produce version compatibility report per SketchUp 2021–2026 with evidence.
- Build RBZ via `scripts/build_rbz.rb` only after required gates pass; document PASS/FAIL/BLOCKED honestly.

## Update 2026-11-13
- Added `scripts/test_all.sh` (JS syntax+tests + all Ruby suites). Current logic test status: **Ruby 50/275 PASS, JS all PASS**.
- Nesting: `cut_length_mm` now computed as perimeter-sum estimate (validated placements), `offcuts` collected; still no shared-cut optimization or manual/UI ops.
- Remaining critical blockers unchanged: Phase 0 AJ reference media missing; SketchUp 2021–2026 runtime required for native geometry/HtmlDialog/Undo/export/RBZ verification.
