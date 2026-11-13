# JP Cabinet PRO — Installation (Draft)

**Status:** Draft scaffold. Extension not release-packaged/verified in SketchUp runtime in this environment.

## Requirements (target)
- SketchUp 2021–2026 (Windows initially)
- Ruby environment provided by SketchUp (version varies by SketchUp release; avoid unsupported syntax)
- No unnecessary external runtime dependencies

## Developer/install from source (manual, unverified here)
1. Copy `jp_cabinet_pro.rb` and the `src/`, `ui/`, `icons/`, `config/` folders into your SketchUp Plugins directory (path varies by SketchUp version/OS).
2. Restart SketchUp.
3. Enable/load **JP Cabinet PRO** via Extension Manager if required.

## RBZ package
- Build script scaffold: `scripts/build_rbz.rb` (requires Ruby + `zip` gem). **RBZ not built in this environment** and must only be produced after required release gates pass.
- Install via SketchUp: *Window → Extension Manager → Install Extension* and select the `.rbz`.

## Verification
- Native registration, toolbar/menu/context, HtmlDialog, and geometry behavior must be verified in SketchUp 2021–2026. **Not verified in this container.**
