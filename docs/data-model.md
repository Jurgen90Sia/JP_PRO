# JP Cabinet PRO — Canonical Data Model (Draft)

**Status:** DRAFT. Dimension semantics (finished/nominal/cutting) must be defined per process and validated against reference behavior when available.

## Core entities
- **Project**: id, name, units(mm), revision, settings, assemblies[]
- **Assembly**: id, project_id, name, type(cabinet), cabinets/components, revision
- **Cabinet**: id, assembly_id, params(width,height,depth,thickness,construction_rule,...), components/panels/fronts/drawers/hardware refs
- **ComponentDefinition**: id, name, category, metadata, source, original_asset_flag
- **ComponentInstance**: id, definition_id, parent_id, transform, quantity_context
- **Panel**: id, parent_id, role(side/top/bottom/shelf/back/partition/stretcher/custom), w/h/t, local_cs, world_transform, material_id, grain, edge_bands{L,R,T,B}, qty, status, source_geom_ref, revision
- **Front**: id, parent_id, type(door/drawer_front), config, dimensions, clearances, hinge/opening
- **Drawer**: id, parent_id, config(fronts,box,slides,clearances), parts refs
- **Hardware**: id, type, catalog_ref(adapter), placement, qty, bom_fields, geometry_ref(optional)
- **Material**: id, name, thickness_variants, finish, grain, texture_scale/orientation
- **EdgeBand**: id, material_id, thickness(0.4/1.0/2.0/custom)
- **MachiningOperation**: id, part_id, type, params (adapter-defined)
- **CutListItem**: part_id, name, material, thickness, length, width, qty, grain, edge_banding, assembly_id, barcode_qr, notes, size_kind(finished|nominal|cutting)
- **Sheet**: id, material_id, thickness, w,h, kerf, trim, grain
- **NestingPlacement**: sheet_id, part_id, x,y,w,h, rotated, validated
- **DrawingView**: id, type(front/rear/left/right/top/bottom/iso/exploded/panel), scale, layout, refs
- **ProductionReport**: id, project_revision, snapshot_ref, sections

## Manufacturing part requirements
Every manufacturing part carries: stable unique ID, parent assembly ID, name+role, W/H/T, local CS, world transform, material ID, grain direction, edge banding per edge, quantity, manufacturing status, source geometry reference, revision/version info.

## Rules
- No double-counting across shared SketchUp component definitions/instances.
- Aggregate CutList items only when manufacturing properties match.
- Immutable calculation snapshots for BOM/CutList/Nesting/Drawings/Reports tied to revision IDs.
- Invalidate downstream outputs on dimension/material/edge/hardware changes (see sync chain).
