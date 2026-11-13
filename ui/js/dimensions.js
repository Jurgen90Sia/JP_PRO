(function () {
  const form = document.getElementById('dim-form');
  const errorsEl = document.getElementById('errors');
  const previewEl = document.getElementById('preview-summary');
  const internalEl = document.getElementById('internal-dims');

  function readInput() {
    const fd = new FormData(form);
    const num = (k, d = 0) => {
      const v = fd.get(k);
      if (v === '' || v === null || v === '') return d;
      const n = Number(v);
      return Number.isFinite(n) ? n : d;
    };
    return {
      width_mm: num('width_mm'),
      height_mm: num('height_mm'),
      depth_mm: num('depth_mm'),
      panel_thickness_mm: num('custom_thickness_mm') || num('panel_thickness_mm'),
      shelf_count: parseInt(fd.get('shelf_count') || '0', 10),
      top_construction: fd.get('top_construction') || 'top_between_sides',
      bottom_construction: fd.get('bottom_construction') || 'bottom_between_sides',
      back_mount_type: fd.get('back_mount_type') || 'recessed_back',
      groove_depth_mm: num('groove_depth_mm'),
      rear_inset_mm: num('rear_inset_mm')
    };
  }

  function validateClient(v) {
    const errs = [];
    ['width_mm','height_mm','depth_mm','panel_thickness_mm'].forEach(k => { if (!(v[k] > 0)) errs.push(k + ' must be > 0'); });
    if (!(Number.isInteger(v.shelf_count) && v.shelf_count >= 0)) errs.push('shelf_count must be >= 0');
    if (v.groove_depth_mm < 0 || v.rear_inset_mm < 0) errs.push('groove/rear inset must be >= 0');
    const backs = ['full_back','recessed_back','grooved_back','surface_mounted_back'];
    if (!backs.includes(v.back_mount_type)) errs.push('invalid back_mount_type');
    return errs;
  }

  function computeInternal(v) {
    const t = v.panel_thickness_mm;
    let internalW = v.width_mm - 2 * t;
    let internalH = v.height_mm;
    if (v.top_construction === 'top_between_sides') internalH -= t;
    if (v.bottom_construction === 'bottom_between_sides') internalH -= t;
    let internalD = v.depth_mm;
    switch (v.back_mount_type) {
      case 'recessed_back':
        internalD = v.depth_mm - v.rear_inset_mm - t;
        break;
      case 'grooved_back':
        internalD = v.depth_mm - v.rear_inset_mm - Math.min(v.groove_depth_mm, t);
        break;
      case 'full_back':
      case 'surface_mounted_back':
        internalD = v.depth_mm - t;
        break;
      default:
        internalD = v.depth_mm - v.rear_inset_mm;
    }
    if (internalD < 0) internalD = 0;
    return { w: internalW, h: internalH, d: internalD };
  }

  function showErrors(errs) { errorsEl.textContent = (errs || []).join('\n'); }

  function renderInternal(v) {
    const internal = computeInternal(v);
    internalEl.textContent = `W: ${internal.w.toFixed(1)} mm, H: ${internal.h.toFixed(1)} mm, D: ${internal.d.toFixed(1)} mm`;
    return internal;
  }

  document.getElementById('btn-preview').addEventListener('click', () => {
    const v = readInput();
    const errs = validateClient(v);
    showErrors(errs);
    renderInternal(v);
    if (errs.length) { previewEl.textContent = 'Preview blocked by validation errors.'; return; }
    previewEl.textContent = `Preview: ${v.width_mm}x${v.height_mm}x${v.depth_mm}, t=${v.panel_thickness_mm}, shelves=${v.shelf_count}, top=${v.top_construction}, bottom=${v.bottom_construction}, back=${v.back_mount_type}`;
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

  window.JPBridge.on('dimensions_preview_result', (detail) => {
    if (!detail) return;
    if (detail.ok === false) {
      showErrors(detail.errors || ['Preview failed']);
      return;
    }
    const p = detail.preview || {};
    const params = p.params || {};
    const parts = (p.parts || []).length;
    previewEl.textContent = `Preview OK: ${parts} parts, internal W/H/D ${params.internal ? [params.internal.internal_width_mm, params.internal.internal_height_mm, params.internal.internal_depth_mm].map(n=>Number(n).toFixed(1)).join('/') : 'n/a'} mm`;
    showErrors([]);
  });

  window.JPBridge.on('dimensions_apply_result', (detail) => {
    if (!detail) return;
    if (detail.ok === false) {
      showErrors(detail.errors || ['Apply failed']);
      previewEl.textContent = 'Apply failed.';
      return;
    }
    showErrors([]);
    const nest = detail.nesting;
    let nestText = 'nesting: n/a';
    if (nest) {
      const util = (nest.utilization != null) ? Number(nest.utilization).toFixed(4) : 'n/a';
      nestText = `nesting: ${nest.ok ? 'ok' : 'fail'} (${nest.strategy || 'n/a'}), util=${util}, placed=${nest.placements_count || 0}, unplaced=${nest.unplaced_count || 0}`;
    }
    previewEl.textContent = `Applied (rev ${detail.revision || '?'}): BOM ${detail.bom_count || 0}, CutList ${detail.cutlist_count || 0}, view ${detail.view ? detail.view.type : 'n/a'}, EB ${detail.edge_banding_count || 0}, ${nestText}. Invalidations: ${(detail.invalidations||[]).join(', ') || 'none'}`;
  });

  window.JPBridge.on('dimensions_cancelled', () => {
    previewEl.textContent = 'Cancelled.';
  });
})();
