(function () {
  const I18N = {
    en: null, sq: null
  };
  let lang = 'en';
  let lastResult = null; // last preview/apply pipeline result
  let lastNesting = null;
  let lastReport = null;

  const PAGES = [
    { id: 'designer', key: 'cabinet_designer' },
    { id: 'dimensions', key: 'dimensions_construction' },
    { id: 'fronts', key: 'fronts_drawers' },
    { id: 'materials', key: 'materials_edge' },
    { id: 'hardware', key: 'hardware' },
    { id: 'library', key: 'component_library' },
    { id: 'bom', key: 'bom_cutlist' },
    { id: 'nesting', key: 'nesting' },
    { id: 'reports', key: 'reports_export' },
    { id: 'settings', key: 'settings_diagnostics' }
  ];

  function t(key) {
    const d = (I18N[lang] && I18N[lang][key]) || (I18N.en && I18N.en[key]) || key;
    return d;
  }

  async function loadI18n() {
    try {
      const res = await fetch('i18n.json'.replace('ui/','').replace('i18n','../config/i18n'));
    } catch (e) {}
    try {
      const res = await fetch('../config/i18n.json');
      if (res.ok) { const j = await res.json(); I18N.en = j.en || I18N.en; I18N.sq = j.sq || I18N.sq; }
    } catch (e) { /* ignore */ }
  }

  function applyI18n() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const k = el.getAttribute('data-i18n');
      if (k) el.textContent = t(k);
    });
  }

  function buildNav() {
    const nav = document.getElementById('nav');
    nav.innerHTML = '';
    PAGES.forEach(p => {
      const b = document.createElement('button');
      b.textContent = t(p.key);
      b.dataset.page = p.id;
      b.dataset.i18nKey = p.key;
      b.addEventListener('click', () => navigate(p.id));
      nav.appendChild(b);
    });
  }

  function navigate(id) {
    PAGES.forEach(p => {
      const sec = document.getElementById('page-' + p.id);
      if (sec) sec.classList.toggle('active', p.id === id);
      const btn = document.querySelector(`.nav button[data-page="${p.id}"]`);
      if (btn) btn.classList.toggle('active', p.id === id);
    });
    const p = PAGES.find(x => x.id === id) || PAGES[0];
    const title = document.getElementById('page-title');
    if (title) title.textContent = t(p.key);
  }

  function formFields(containerId, prefix) {
    const c = document.getElementById(containerId);
    if (!c) return;
    c.innerHTML = `
      <label>${t('width_mm')}<input name="width_mm" type="number" step="0.1" min="1" value="800"></label>
      <label>${t('height_mm')}<input name="height_mm" type="number" step="0.1" min="1" value="720"></label>
      <label>${t('depth_mm')}<input name="depth_mm" type="number" step="0.1" min="1" value="560"></label>
      <label>${t('panel_thickness_mm')}
        <select name="panel_thickness_mm">
          <option value="16">16</option>
          <option value="18" selected>18</option>
          <option value="22">22</option>
          <option value="custom">custom</option>
        </select>
      </label>
      <label>${t('custom_thickness_mm')}<input name="custom_thickness_mm" type="number" step="0.1" min="0" value=""></label>
      <label>${t('shelf_count')}<input name="shelf_count" type="number" step="1" min="0" value="1"></label>
      <label>${t('partition_count')}<input name="partition_count" type="number" step="1" min="0" value="0"></label>
      <label>${t('top_construction')}
        <select name="top_construction"><option value="top_between_sides">top_between_sides</option><option value="top_over_sides">top_over_sides</option></select>
      </label>
      <label>${t('bottom_construction')}
        <select name="bottom_construction"><option value="bottom_between_sides">bottom_between_sides</option><option value="bottom_under_sides">bottom_under_sides</option></select>
      </label>
      <label>${t('back_mount_type')}
        <select name="back_mount_type">
          <option value="full_back">full_back (solid)</option>
          <option value="recessed_back" selected>recessed_back</option>
          <option value="grooved_back">grooved_back</option>
          <option value="hdf_grooved">hdf_grooved</option>
          <option value="surface_mounted_back">surface_mounted_back</option>
        </select>
      </label>
      <label>${t('groove_depth_mm')}<input name="groove_depth_mm" type="number" step="0.1" min="0" value="8"></label>
      <label>${t('rear_inset_mm')}<input name="rear_inset_mm" type="number" step="0.1" min="0" value="10"></label>
      <label>${t('plinth_height_mm')}<input name="plinth_height_mm" type="number" step="0.1" min="0" value="0"></label>
      <label>${t('legs_height_mm')}<input name="legs_height_mm" type="number" step="0.1" min="0" value="0"></label>
      <label>${t('leg_count')}<input name="leg_count" type="number" step="1" min="0" value="4"></label>
    `;
  }

  function readBase(containerId) {
    const c = document.getElementById(containerId);
    const out = {};
    if (!c) return out;
    c.querySelectorAll('input, select, textarea').forEach(el => {
      if (!el.name) return;
      if (el.type === 'number') out[el.name] = el.value === '' ? null : Number(el.value);
      else out[el.name] = el.value;
    });
    if (out.panel_thickness_mm === 'custom') out.panel_thickness_mm = Number(out.custom_thickness_mm || 18);
    else out.panel_thickness_mm = Number(out.panel_thickness_mm || 18);
    if (out.shelf_count != null) out.shelf_count = parseInt(out.shelf_count, 10) || 0;
    if (out.partition_count != null) out.partition_count = parseInt(out.partition_count, 10) || 0;
    if (out.leg_count != null) out.leg_count = parseInt(out.leg_count, 10) || 0;
    return out;
  }

  function readFrontsDrawersHardware() {
    const v = {};
    if (document.getElementById('fronts-enabled').value === 'true') {
      v.fronts = {
        type: val('fronts-type'), mounting: val('fronts-mounting'), split: val('fronts-split'),
        gap_mm: num('fronts-gap'), perimeter_gap_mm: num('fronts-perimeter'), front_thickness_mm: num('fronts-thickness')
      };
    }
    if (document.getElementById('drawers-enabled').value === 'true') {
      v.drawers = {
        count: parseInt(val('drawers-count'), 10) || 1, mounting: val('drawers-mounting'),
        gap_mm: num('drawers-gap'), perimeter_gap_mm: num('fronts-perimeter'),
        slide_clearance_mm: num('drawers-slide'), box_depth_mm: num('drawers-depth'),
        side_thickness_mm: num('drawers-side-t'), back_thickness_mm: 16, bottom_thickness_mm: 16
      };
    }
    try {
      const hw = JSON.parse(document.getElementById('hardware-json').value || '[]');
      if (Array.isArray(hw) && hw.length) v.hardware = hw;
    } catch (e) {}
    v.waste_factor = num('mat-waste');
    return v;
  }

  function val(id) { const e = document.getElementById(id); return e ? e.value : ''; }
  function num(id) { const n = Number(val(id)); return isFinite(n) ? n : 0; }
  function setText(id, txt) { const e = document.getElementById(id); if (e) e.textContent = txt; }
  function setHTML(id, html) { const e = document.getElementById(id); if (e) e.innerHTML = html; }

  function computeInternalPreview(v) {
    const t = Number(v.panel_thickness_mm || 18);
    let w = Number(v.width_mm||0) - 2*t;
    let h = Number(v.height_mm||0);
    if (v.top_construction === 'top_between_sides') h -= t;
    if (v.bottom_construction === 'bottom_between_sides') h -= t;
    let d = Number(v.depth_mm||0);
    if (v.back_mount_type === 'recessed_back') d -= Number(v.rear_inset_mm||0) + t;
    else if (v.back_mount_type === 'grooved_back' || v.back_mount_type === 'hdf_grooved') d -= Number(v.rear_inset_mm||0) + Math.min(Number(v.groove_depth_mm||0), t);
    else d -= t;
    return { w, h, d: Math.max(d,0) };
  }

  function gatherPayload(from) {
    const base = readBase(from === 'dimensions' ? 'dimensions-grid' : 'designer-grid');
    const ext = readFrontsDrawersHardware();
    return Object.assign({}, base, ext);
  }

  function showResult(targetOut, targetErr, detail) {
    if (!detail) return;
    if (detail.ok === false) {
      if (targetErr) setText(targetErr, (detail.errors || ['Failed']).join('\n'));
      setText(targetOut, 'ERROR');
      return;
    }
    if (targetErr) setText(targetErr, '');
    lastResult = detail;
    const summary = {
      ok: detail.ok,
      applied: detail.applied,
      revision: detail.revision,
      bom_count: detail.bom_count || (detail.bom ? detail.bom.length : 0),
      cutlist_count: detail.cutlist_count || (detail.cutlist ? detail.cutlist.length : 0),
      fronts_count: detail.fronts_count,
      drawers_count: detail.drawers_count,
      hardware_count: detail.hardware_count,
      nesting: detail.nesting || (detail.nesting_full ? { ok: detail.nesting_full.ok, utilization: detail.nesting_full.utilization } : null),
      materials: detail.materials ? { waste_factor: detail.materials.waste_factor, net_rows: (detail.materials.net||[]).length } : null,
      edge_banding_count: detail.edge_banding_count || (detail.edge_banding ? detail.edge_banding.length : 0),
      revision_state: detail.revision_state,
      entity_status: detail.entity_status
    };
    setText(targetOut, JSON.stringify(summary, null, 2));
  }

  function bind() {
    // lang
    document.querySelectorAll('.lang-toggle button').forEach(b => b.addEventListener('click', () => {
      lang = b.dataset.lang || 'en';
      buildNav();
      applyI18n();
      formFields('designer-grid'); formFields('dimensions-grid');
      navigate(currentPage());
    }));

    // designer actions
    document.getElementById('btn-preview').addEventListener('click', () => {
      const v = gatherPayload('designer');
      setText('designer-internal', JSON.stringify(computeInternalPreview(v), null, 2));
      JPBridge.call('dimensions_preview', v);
    });
    document.getElementById('btn-apply').addEventListener('click', () => JPBridge.call('dimensions_apply', gatherPayload('designer')));
    document.getElementById('btn-create').addEventListener('click', () => JPBridge.call('cabinet_create', gatherPayload('designer')));
    document.getElementById('btn-read-sel').addEventListener('click', () => JPBridge.call('selection_read', {}));
    document.getElementById('btn-apply-sel').addEventListener('click', () => JPBridge.call('selection_apply', gatherPayload('designer')));

    document.getElementById('dim-preview').addEventListener('click', () => JPBridge.call('dimensions_preview', gatherPayload('dimensions')));
    document.getElementById('dim-apply').addEventListener('click', () => JPBridge.call('dimensions_apply', gatherPayload('dimensions')));

    document.getElementById('fronts-preview').addEventListener('click', () => JPBridge.call('dimensions_preview', gatherPayload('designer')));

    document.getElementById('materials-run').addEventListener('click', () => JPBridge.call('dimensions_preview', gatherPayload('designer')));

    document.getElementById('hardware-run').addEventListener('click', () => {
      try {
        const hw = JSON.parse(document.getElementById('hardware-json').value || '[]');
        setText('hardware-output', 'Hardware items captured: ' + (Array.isArray(hw)?hw.length:0) + '\n' + JSON.stringify(hw, null, 2) + '\n(Validation/aggregation runs in pipeline apply/preview; adapter-based catalog, manufacturer data unverified)');
      } catch (e) { setText('hardware-output', 'Invalid JSON: ' + e.message); }
    });

    document.getElementById('lib-search').addEventListener('click', () => JPBridge.call('library_action', { action:'search', query: val('lib-query'), index_path: val('lib-path') }));
    document.getElementById('lib-upsert').addEventListener('click', () => {
      try { const comp = JSON.parse(val('lib-json')||'{}'); JPBridge.call('library_action', { action:'upsert', component: comp, index_path: val('lib-path') }); }
      catch(e){ setText('library-output', 'Invalid JSON: ' + e.message); }
    });

    document.getElementById('bom-refresh').addEventListener('click', () => {
      if (!lastResult) return setText('bom-output', 'No pipeline result yet. Run Preview/Apply first.');
      setText('bom-output', JSON.stringify({ bom: lastResult.bom || '(summary only)', cutlist: lastResult.cutlist || '(summary only)' }, null, 2));
    });

    document.getElementById('nest-run').addEventListener('click', () => {
      const parts = (lastResult && lastResult.cutlist) ? lastResult.cutlist.map(r => ({ id: r.part_id, w: r.width, h: r.length, qty: r.quantity||1, material: r.material, thickness: r.thickness, grain: r.grain_direction })) : [];
      const sheets = [{ id:'S1', w:num('nest-sw'), h:num('nest-sh'), kerf:num('nest-kerf'), trim:num('nest-trim'), material: (parts[0]||{}).material, thickness: (parts[0]||{}).thickness }];
      if (!parts.length) return setText('nesting-output', 'No cutlist parts available. Run Preview/Apply first.');
      JPBridge.call('nesting_plan', { parts, sheets, strategy: val('nest-strategy') });
    });

    document.getElementById('report-run').addEventListener('click', () => {
      const snap = lastResult && lastResult.snapshot ? lastResult.snapshot : lastResult;
      if (!snap) return setText('report-output', 'No snapshot available. Run Apply first.');
      JPBridge.call('report_generate', { snapshot: snap, options: {} });
    });
    document.getElementById('export-csv').addEventListener('click', () => {
      const cutlist = lastResult && lastResult.cutlist ? lastResult.cutlist : [];
      if (!cutlist.length) return setText('report-output', 'No cutlist. Run Apply first.');
      JPBridge.call('export_csv', { cutlist });
    });
    document.getElementById('export-dxf').addEventListener('click', () => {
      const nesting = lastNesting || (lastResult && (lastResult.nesting_full || lastResult.nesting));
      const sheets = [{ id:'S1', w:num('nest-sw'), h:num('nest-sh') }];
      if (!nesting) return setText('report-output', 'No nesting result. Run Plan Nesting first.');
      JPBridge.call('export_nesting_dxf', { nesting: nesting.nesting || nesting, sheets });
    });

    document.getElementById('diag-run').addEventListener('click', () => JPBridge.call('diagnostics_info', {}));

    // results
    JPBridge.on('dimensions_preview_result', d => { showResult('designer-output','designer-errors', d); showResult('dimensions-output', null, d); setText('fronts-output', JSON.stringify(d.preview || d, null, 2)); setText('materials-output', JSON.stringify({materials:d.materials, edge_banding:d.edge_banding, edge_banding_count:d.edge_banding_count}, null, 2)); });
    JPBridge.on('dimensions_apply_result', d => { showResult('designer-output','designer-errors', d); showResult('dimensions-output', null, d); });
    JPBridge.on('cabinet_create_result', d => setText('designer-output', JSON.stringify(d, null, 2)));
    JPBridge.on('selection_read_result', d => setText('designer-output', JSON.stringify(d, null, 2)));
    JPBridge.on('selection_apply_result', d => setText('designer-output', JSON.stringify(d, null, 2)));
    JPBridge.on('nesting_plan_result', d => { lastNesting = d; setText('nesting-output', JSON.stringify(d, null, 2)); });
    JPBridge.on('report_generate_result', d => { lastReport = d; setText('report-output', JSON.stringify({ok:d.ok, errors:d.errors, has_html: !!d.html}, null, 2)); if (d.html) setHTML('report-html', d.html); });
    JPBridge.on('export_csv_result', d => setText('report-output', JSON.stringify({ok:d.ok, format:d.format, note:d.note, preview: (d.content||'').slice(0,2000)}, null, 2)));
    JPBridge.on('export_nesting_dxf_result', d => setText('report-output', JSON.stringify({ok:d.ok, format:d.format, note:d.note, preview: (d.content||'').slice(0,1200)}, null, 2)));
    JPBridge.on('library_action_result', d => setText('library-output', JSON.stringify(d, null, 2)));
    JPBridge.on('diagnostics_info_result', d => setText('diag-output', JSON.stringify(d, null, 2)));
  }

  function currentPage() {
    const a = document.querySelector('.page.active');
    return a ? a.id.replace('page-','') : 'designer';
  }

  async function init() {
    try { const res = await fetch('../config/i18n.json'); if (res.ok) { const j = await res.json(); I18N.en = j.en; I18N.sq = j.sq; } } catch(e){}
    buildNav();
    formFields('designer-grid');
    formFields('dimensions-grid');
    bind();
    navigate('designer');
    JPBridge.call('diagnostics_info', {});
  }

  window.JPApp = { navigate };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
