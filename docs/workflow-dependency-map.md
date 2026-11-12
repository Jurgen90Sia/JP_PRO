# Workflow Dependency Map

**Status:** BLOCKED — derived from prompt target workflow only; AJ-specific dependencies unverified.

## Target workflow (from requirements)

`Component Library → Parametric Cabinet → 3D Editing → Materials → Hardware → BOM → Cut List → Nesting → Technical Drawings → Reports → CNC Export`

## Known cross-module synchronization requirements (spec)

Changing a cabinet dimension must trigger:
1. Geometry recalculation
2. Part dimension recalculation
3. Material quantity update
4. Edge banding recalculation
5. Hardware validation
6. BOM refresh
7. Cut List refresh
8. Nesting invalidation
9. Technical drawing invalidation
10. Report revision update

## AJ Cabinet-specific workflow dependencies

**UNVERIFIED/BLOCKED:** No supplied screenshots or video available to map observed UI flows, command dependencies, or dialog sequencing.
