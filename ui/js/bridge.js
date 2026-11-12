// HtmlDialog <-> Ruby bridge (scaffold). In SketchUp: window.sketchup.callX(payloadJson)
(function () {
  const Bridge = {
    call(action, payload) {
      if (window.sketchup && typeof window.sketchup[action] === 'function') {
        window.sketchup[action](JSON.stringify(payload || {}));
        return { dispatched: true };
      }
      // Dev fallback: no native host.
      console.info('[bridge:fallback]', action, payload);
      return { dispatched: false, fallback: true };
    },
    on(event, handler) {
      window.addEventListener(event, (e) => handler(e.detail || e));
    }
  };
  window.JPBridge = Bridge;
})();
