# JP Cabinet PRO (Scaffold)

Original, production-oriented SketchUp extension for parametric furniture workflow:
Component Library → Parametric Cabinet → 3D Editing → Materials → Hardware → BOM → Cut List → Nesting → Technical Drawings → Reports → CNC Export.

**Status:** Phase 0 BLOCKED (reference audit incomplete — supplied AJ Cabinet screenshots/video not present in workspace). Phase 1 foundation scaffold in progress. No parity/compatibility claims.

## Repository
- `docs/` — reference audit, inventory, parity matrix, workflow map, architecture, data model, blockers
- `jp_cabinet_pro.rb` — extension registration entry
- `src/jp_cabinet_pro/` — modular engines/adapters (scaffold)
- `ui/`, `icons/` — HtmlDialog UI and original SVG assets (scaffold)
- `config/` — defaults
- `tests/` — Ruby/JS tests (scaffold)

## Targets
- SketchUp 2021–2026, Windows initially; mm internally; Albanian/English.

## Development notes
- Reference audit must remain separate from implementation spec.
- Do not fabricate undocumented behavior, manufacturer data, or CNC compatibility claims.
- Native SketchUp runtime verification requires SketchUp environment (not available in this container).

See `docs/missing-specifications.md` for blockers.
