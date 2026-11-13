// HtmlDialog <-> Ruby bridge. In SketchUp: window.sketchup.<action>(payloadJson)
(function () {
  const Bridge = {
    call(action, payload) {
      try {
        if (window.sketchup && typeof window.sketchup[action] === 'function') {
          window.sketchup[action](JSON.stringify(payload || {}));
          return { dispatched: true, runtime: true };
        }
      } catch (e) {
        console.error('[bridge:error]', action, e);
        return { dispatched: false, error: String(e) };
      }
      console.info('[bridge:fallback]', action, payload);
      // emit local fallback result events for some actions to keep UI responsive in browser
      setTimeout(() => Bridge._fallback(action, payload || {}), 0);
      return { dispatched: false, fallback: true };
    },
    on(event, handler) {
      window.addEventListener(event, (e) => handler(e.detail || e));
    },
    _fallback(action, payload) {
      const emit = (name, detail) => window.dispatchEvent(new CustomEvent(name, { detail }));
      if (action === 'diagnostics_info') {
        emit('diagnostics_info_result', { ok: true, runtime: false, extension: 'dev', ruby: 'n/a', platform: navigator.platform, registered_commands: [] });
      } else if (action === 'selection_read') {
        emit('selection_read_result', { ok: false, runtime: false, selected: false, error: 'sketchup_runtime_required' });
      } else if (action === 'dimensions_cancel') {
        emit('dimensions_cancelled', { ok: true });
      }
      // other actions require Ruby engines; UI shows fallback notice.
    }
  };
  window.JPBridge = Bridge;
})();
