(function () {
  const form = document.getElementById('dim-form');
  const errorsEl = document.getElementById('errors');
  const previewEl = document.getElementById('preview-summary');
  const internalEl = document.getElementById('internal-dims');

  function readInput() {
    const fd = new FormData(form);
    const num = (k, d = 0) => {
      const v = fd.get(k);
      if (v === '' || v === null) return d;
      return Number(v);
    };
    return {
      width_mm: num('width_mm'),
      height_mm: num('height_mm'),
      depth_mm: num('depth_mm'),
      panel_thickness_mm: num('custom_thickness_mm') || num('panel_thickness_mm'),
      shelf_count: parseInt(fd.get('shelf_count') || '0', 10),
      back_mount_type: fd.get('back_mount_type') || 'recessed_back',
      groove_depth_mm: num('groove_depth_mm'),
      rear_inset_mm: num('rear_inset_mm')
    };
  }

  function validateClient(v) {
    const errs = [];
    ['width_mm','height_mm','depth_mm','panel_thickness_mm'].forEach(k => { if (!(v[k] > 0)) errs.push(k + ' must be > 0'); });
    if (!(v.shelf_count >= 0)) errs.push('shelf_count must be >= 0');
    if (v.groove_depth_mm < 0 || v.rear_inset_mm < 0) errs.push('groove/rear inset must be >= 0');
    return errs;
  }

  function computeInternal(v) {
    const t = v.panel_thickness_mm;
    return {
      w: v.width_mm - 2*t,
      h: v.height_mm - 2*t,
      d: v.depth_mm - v.rear_inset_mm
    };
  }

  function showErrors(errs) { errorsEl.textContent = (errs || []).join('\n'); }

  document.getElementById('btn-preview').addEventListener('click', () => {
    const v = readInput();
    const errs = validateClient(v);
    showErrors(errs);
    const internal = computeInternal(v);
    internalEl.textContent = `W: ${internal.w.toFixed(1)} mm, H: ${internal.h.toFixed(1)} mm, D: ${internal.d.toFixed(1)} mm`;
    if (errs.length) { previewEl.textContent = 'Preview blocked by validation errors.'; return; }
    previewEl.textContent = `Preview: ${v.width_mm}x${v.height_mm}x${v.depth_mm}, t=${v.panel_thickness_mm}, shelves=${v.shelf_count}, back=${v.back_mount_type}`;
    window.JPBridge.call('dimensions_preview', v);
  });

  document.getElementById('btn-apply').addEventListener('click', () => {
    const v = readInput();
    const errs = validateClient(v);
    showErrors(errs);
    if (errs.length) return;
    window.JPBridge.call('dimensions_apply', v);
  });

  document.getElementById('btn-cancel').addEventListener('click', () => {
    window.JPBridge.call('dimensions_cancel', {});
  });
})();
