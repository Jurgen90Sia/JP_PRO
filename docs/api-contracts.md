# JP Cabinet PRO — Module API Contracts (Draft)

**Status:** Draft/scaffold. Contracts will evolve; reference-driven behavior remains unverified until Phase 0 audit completes.

## Conventions
- All dimensions in **mm** internally unless stated.
- Engines should be deterministic/pure where possible; SketchUp mutations isolated in `Adapter::SketchupAdapter` within transactions.
- UI↔Ruby via JSON payloads/callbacks (HtmlDialog bridge). No geometry logic in JS.
- Errors returned as structured results (`{ok:false, errors:[...]}`) not silent failures.

## Modules
- **Commands::Registry**: `register(cmd)`, `fetch(id)`, `register_defaults`. Command contract: `id, icon, label_sq, label_en, input_schema, validation, handler, required_selection, undo_behavior, test_id`.
- **Adapter::SketchupAdapter**: `transaction(name){}`, model access, selection/geometry ops (scaffold). Abort on exception.
- **Parametric::Dimensions**: `validate(input)->Result(ok,errors,values+internal)`, `compute_internal(values)`. Construction-rule aware (prototype).
- **Cabinet::Construction**: `build_parts(params)->[part_hash]`, `rebuild(params:,existing:)`.
- **Bom::Generator**: `generate(parts:,assembly_id:)`, `aggregate(items)` (match manufacturing properties).
- **Cutlist::Generator**: `generate(bom_items)` with `size_kind` explicit.
- **Drawing::TechnicalView**: `generate(parts:,cabinet_params:,view_type:,scale:,revision:)` view model (scaffold).
- **Commands::EditDimensions**: `preview(input)->Result`, `apply(input,assembly_id,project_id,revision,existing)->Result` including invalidations and snapshot.
- **Materials::Engine**: `upsert/fetch/assign/quantities` (scaffold; net/gross separation required).
- **EdgeBanding::Engine**: per-edge normalize, `total_length(parts)` by material/thickness.
- **Hardware::Engine**: structured items, `bom_lines`, `validate` (adapter-based; no fabricated mfr data).
- **Doors::FrontEngine / Drawers::Engine**: `configure/validate` (NOT_IMPLEMENTED stubs per spec enums).
- **Library::Manager**: search/insert/replace/import/export (scaffold, original assets only).
- **Nesting::Optimizer**: `plan` raises NotImplementedError until real validated algorithm exists.
- **Cnc::Exporter**: generic CSV helper; DXF/machine-specific unimplemented/unverified.
- **Persistence::Store/Snapshot**: deterministic JSON, schema/migration hooks, immutable snapshots.
- **UI::Dialog/DialogController**: HtmlDialog factory and callback wiring (SketchUp runtime required).
- **Diagnostics::Logger/RevisionTracker**: logging and downstream invalidation tracking.

## Invalidation chain (dimension change)
`geometry, parts, materials, edge_banding, hardware, bom, cutlist, nesting, drawings, reports` — outputs must be refreshed or marked stale with revision IDs (prototype emits flags; full enforcement pending).
