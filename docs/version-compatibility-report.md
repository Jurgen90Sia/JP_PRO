# Version Compatibility Report — JP Cabinet PRO

**Date:** 2026-11-12  
**Overall status:** **UNVERIFIED** (no SketchUp runtime available in development environment)

| Target | Status | Evidence | Notes |
|--------|--------|----------|-------|
| SketchUp 2021 (Windows) | UNTESTED | None | Extension registration, HtmlDialog, Ruby API behavior, observers, and packaging must be verified in-app. |
| SketchUp 2022 (Windows) | UNTESTED | None | Same as above. |
| SketchUp 2023 (Windows) | UNTESTED | None | Same as above. |
| SketchUp 2024 (Windows) | UNTESTED | None | Same as above. |
| SketchUp 2025 (Windows) | UNTESTED | None | Same as above. |
| SketchUp 2026 (Windows) | UNTESTED | None | Same as above. |

## API/implementation notes
- Code targets version-compatible SketchUp Ruby APIs conceptually; **no runtime compatibility proven**.
- Embedded Ruby version differs across SketchUp releases; syntax/features must be validated per target.
- Avoids unnecessary external dependencies in scaffold.

## Environment limitations
- Container: Linux, no SketchUp, no Ruby executable. JS logic tests executed with Node (not a SketchUp runtime proof).

**Conclusion:** No supported/production-ready version claim can be made until integration tests pass on each targeted SketchUp release.
