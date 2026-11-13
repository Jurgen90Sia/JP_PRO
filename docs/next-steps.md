# Next Steps (Blocker-driven)

**Final automated state:** `scripts/test_all.sh` PASS — Ruby 16 suites, 56 runs, 297 assertions, 0 failures; JS checks/suites PASS. **Phase 0 BLOCKED, SketchUp runtime UNVERIFIED, no RBZ, no parity/production claims.**

## 1. Unblock Phase 0 (required for confirmed parity)
- Place AJ Cabinet screenshots + full video in `/workspace/app`.
- Produce timestamped video observation log; classify CONFIRMED/INFERRED/UNKNOWN.
- Populate `docs/command-inventory.csv`, `docs/feature-parity-matrix.md`, `docs/workflow-dependency-map.md`, `docs/unverified-behavior.md` from evidence.
- Align implementation, fields, and workflows to confirmed behavior; record PASS/FAIL/BLOCKED per command.

## 2. SketchUp runtime vertical slice & integration (critical)
- Implement native selection/extraction and transaction-safe SketchUp geometry rebuild (entities, materials, nested/mirrored/rotated instances, observer safety).
- Wire HtmlDialog callbacks, toolbar/menu/context, and Undo/Redo in SketchUp 2021–2026 (Windows).
- Verify end-to-end: Select Cabinet → Edit Dimensions → Rebuild Geometry → Update BOM → Generate Technical View.
- Execute integration tests and produce per-version compatibility evidence.

## 3. Complete modules against confirmed specs
- True projected/vector drawings, A4–A0 layouts, PDF/DXF rendering, barcodes/labels/revisions.
- Nesting UI/manual ops, cut-path/optimized cut length, visualization; material/edge/hardware/doors/drawers geometry and rules per confirmed/verified data.
- Component library UI + SketchUp insert/replace; PROJECT/QUOTATIONS/INDUSTRIAL LAYOUT and remaining audited commands.
- CNC: machine-specific adapters only with verified configs/tools/coords and real validation.

## 4. Release (only after gates pass)
- Resolve dimension semantics and data-contract gaps with evidence.
- Full regression + SketchUp verification matrix, documented PASS/FAIL/BLOCKED.
- Install `zip` dependency as needed and build/validate RBZ via `scripts/build_rbz.rb`.
