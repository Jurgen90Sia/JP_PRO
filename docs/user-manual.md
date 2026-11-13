# JP Cabinet PRO — User Manual (Draft)

**Status:** Draft scaffold. UI/commands described are targets or prototypes; many modules are not implemented or not runtime-verified. Phase 0 reference audit is BLOCKED (AJ Cabinet screenshots/video not provided), so AJ-specific workflows cannot be confirmed.

## Modules (target)
PROJECT, LIBRARY, CABINETS, 3D DESIGN, MATERIALS, HARDWARE, BOM, NESTING, QUOTATIONS, SKETCHUP COMPONENTS, REPORTS / CNC, INDUSTRIAL LAYOUT.

## Vertical slice (prototype): Edit Dimensions
1. Select a cabinet (SketchUp selection integration **not yet runtime-implemented**).
2. Open **Edit Dimensions** (HtmlDialog scaffold: `ui/dialogs/dimensions.html`).
3. Set: width/height/depth, panel thickness (or custom), shelf count, top/bottom construction, back mounting type, groove depth, rear inset.
4. **Preview**: validates inputs and shows calculated internal dimensions and a proposed change summary (client-side prototype; native bridge dispatches `dimensions_preview` when hosted in SketchUp).
5. **Apply**: dispatches `dimensions_apply`. Orchestration prototype (`Commands::EditDimensions`) validates → rebuilds part set (rule-based) → generates BOM → generates Cut List → generates technical view model and reports invalidations. **Real SketchUp geometry rebuild and native callback wiring are not runtime-verified.**
6. **Cancel**: closes/discards without applying.

## Notes
- Dimensions are treated as mm internally. Finished/nominal/cutting semantics are process-dependent and currently placeholders.
- Downstream outputs (nesting/drawings/reports) must be invalidated on dimension changes; invalidation flags are emitted by prototype logic but full refresh engines are not implemented.
- No manufacturer-specific hardware/CNC presets are fabricated without verified data.
