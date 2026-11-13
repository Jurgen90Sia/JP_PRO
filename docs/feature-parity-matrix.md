# Feature Parity Matrix — JP Cabinet PRO vs AJ Cabinet (Reference)

**Status:** BLOCKED — reference audit incomplete (no screenshots/video in workspace). No AJ behaviors confirmed.

| Capability Area | Reference Evidence | JP Cabinet PRO State (2026-11-13) | Implementation | Verification | Notes |
|-----------------|--------------------|-----------------------------------|----------------|--------------|-------|
| Component Library | None in workspace | JSON index prototype (search/filter/fav/recent/import/export); insert/replace runtime-stub | PROTOTYPE | Logic tests PASS; SketchUp/runtime UNVERIFIED | No UI/perf tuning; no copyrighted assets |
| Parametric Cabinet / Construction | None in workspace | Rule-aware dimensions and deterministic part generation; fronts/drawers/hardware layout integration | PROTOTYPE | Logic tests PASS | Not AJ-verified; no SketchUp entity rebuild |
| 3D Editing / SketchUp integration | None in workspace | Adapter/selection/dialog-controller stubs | SCAFFOLD | UNVERIFIED/BLOCKED | Requires SketchUp runtime |
| Materials & Edge Banding | None in workspace | Net/gross quantities (explicit waste), per-edge totals | PROTOTYPE | Logic tests PASS | Process semantics unconfirmed |
| Hardware | None in workspace | Structured items, validation, BOM aggregation (adapter-based) | PROTOTYPE | Logic tests PASS | No fabricated manufacturer data |
| BOM & Cut List | None in workspace | Aggregation and cut list generation (nominal) | PROTOTYPE | Logic tests PASS | Full canonical/process fields pending |
| Nesting | None in workspace | 2D optimizer (4 strategies), validation/utilization/offcuts/cut-length estimate | PROTOTYPE | Logic tests PASS | No manual UI/visualization; AJ unverified |
| Technical Drawings | None in workspace | View model + schematic SVG scaffold | PROTOTYPE | Logic tests PASS | Not true projection; no PDF/DXF |
| Reports | None in workspace | HTML report from canonical snapshot | PROTOTYPE | Logic tests PASS | No PDF/layout/barcodes |
| CNC Export | None in workspace | Generic CSV, generic nesting DXF (rect outlines) | PROTOTYPE/SCAFFOLD | Logic tests PASS | Not verified CNC/CAD; machine-specific UNVERIFIED |
| Full UI / modules / commands | None in workspace | 6 prototype commands registered; dialog/module scaffolds | SCAFFOLD | Partial logic tests | Many modules/commands unknown/unimplemented |

**Parity claim:** **None.** 100% compatibility/parity is not claimed.
