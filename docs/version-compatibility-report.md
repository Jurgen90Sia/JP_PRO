# Version Compatibility Report — JP Cabinet PRO

**Date:** 2026-11-13  
**Overall status:** **UNVERIFIED** (no SketchUp runtime available in development/test environment)

| Target | Status | Evidence | Notes |
|--------|--------|----------|-------|
| SketchUp 2021 (Windows) | UNTESTED | None | Extension registration, HtmlDialog, Ruby API behavior, observers, geometry, and packaging must be verified in-app. |
| SketchUp 2022 (Windows) | UNTESTED | None | Same as above. |
| SketchUp 2023 (Windows) | UNTESTED | None | Same as above. |
| SketchUp 2024 (Windows) | UNTESTED | None | Same as above. |
| SketchUp 2025 (Windows) | UNTESTED | None | Same as above. |
| SketchUp 2026 (Windows) | UNTESTED | None | Same as above. |

## API/implementation notes
- Code targets version-compatible SketchUp Ruby APIs conceptually; **no runtime compatibility proven**.
- Embedded Ruby version differs across SketchUp releases; syntax/features must be validated per target (development tests ran on Ruby 3.3.13 outside SketchUp).
- Avoids unnecessary external dependencies in scaffold.

## Automated (non-SketchUp) evidence
- Ruby 16 suites, 56 runs, 297 assertions, 0 failures; JS suites/checks PASS (`scripts/test_all.sh`). Not a substitute for SketchUp runtime tests.

**Conclusion:** No supported/production-ready version claim can be made until integration tests pass on each targeted SketchUp release.
