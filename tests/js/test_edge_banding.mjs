import assert from 'node:assert/strict';

function normalize(bands = {}) {
  const edges = ['left','right','top','bottom'];
  const out = {};
  for (const e of edges) out[e] = bands[e] ?? bands[e.toUpperCase?.()] ?? null;
  // also support symbol-like string keys from JSON-ish input
  for (const e of edges) if (out[e] == null && bands[e]) out[e] = bands[e];
  return out;
}

function edgeLengths(p) {
  const w = Number(p.width_mm);
  const h = Number(p.height_mm);
  return { left: h, right: h, top: w, bottom: w };
}

function totalLength(parts) {
  const totals = new Map();
  for (const p of parts) {
    const bands = p.edge_banding || {};
    const dims = edgeLengths(p);
    const qty = p.quantity || 1;
    for (const edge of ['left','right','top','bottom']) {
      const band = bands[edge];
      if (!band) continue;
      const key = `${band.material_id}|${band.thickness_mm}`;
      totals.set(key, (totals.get(key) || 0) + dims[edge] * qty);
    }
  }
  return Array.from(totals.entries()).map(([k,v]) => {
    const [material_id, thickness_mm] = k.split('|');
    return { material_id, thickness_mm: Number(thickness_mm), length_mm: v };
  });
}

const parts = [
  { width_mm: 800, height_mm: 720, quantity: 1, edge_banding: { left: {material_id:'eb1', thickness_mm:1}, right: {material_id:'eb1', thickness_mm:1}, top: null, bottom: null } },
  { width_mm: 500, height_mm: 100, quantity: 2, edge_banding: { left: null, right: null, top: {material_id:'eb2', thickness_mm:2}, bottom: {material_id:'eb2', thickness_mm:2} } }
];
const res = totalLength(parts);
const byKey = Object.fromEntries(res.map(r => [`${r.material_id}|${r.thickness_mm}`, r.length_mm]));
assert.equal(byKey['eb1|1'], 1440);
assert.equal(byKey['eb2|2'], 2000);
assert.equal(totalLength([{ width_mm:100, height_mm:50, edge_banding:{} }]).length, 0);
console.log('ok');
