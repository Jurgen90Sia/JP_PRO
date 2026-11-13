import assert from 'node:assert/strict';

function round3(v){ return Math.round(Number(v) * 1000) / 1000; }

function quantities(parts, wasteFactor = 0) {
  if (wasteFactor < 0) throw new Error('waste_factor must be >= 0');
  const net = new Map();
  for (const p of parts || []) {
    const area = Number(p.width_mm) * Number(p.height_mm) * Number(p.quantity || 1);
    const key = `${p.material_id}|${p.thickness_mm}`;
    net.set(key, (net.get(key) || 0) + area);
  }
  const netRows = Array.from(net.entries()).map(([k,a]) => {
    const [m,t] = k.split('|');
    return { material_id: m === 'null' ? null : m, thickness_mm: t === 'undefined' ? undefined : Number(t), area_mm2: round3(a) };
  }).sort((a,b)=> String(a.material_id).localeCompare(String(b.material_id)) || (a.thickness_mm-b.thickness_mm));
  const grossRows = netRows.map(r => ({ ...r, area_mm2: round3(r.area_mm2 * (1 + wasteFactor)) }));
  return { net: netRows, gross: grossRows, waste_factor: wasteFactor };
}

const parts = [
  { material_id: 'm1', thickness_mm: 18, width_mm: 1000, height_mm: 500, quantity: 2 },
  { material_id: 'm1', thickness_mm: 18, width_mm: 500, height_mm: 500, quantity: 1 },
  { material_id: 'm2', thickness_mm: 16, width_mm: 400, height_mm: 300, quantity: 1 }
];
const q = quantities(parts, 0.1);
const netM1 = q.net.find(r => r.material_id === 'm1');
assert.equal(netM1.area_mm2, 1250000);
const grossM1 = q.gross.find(r => r.material_id === 'm1');
assert.equal(grossM1.area_mm2, 1375000);
assert.equal(q.waste_factor, 0.1);

let threw = false;
try { quantities([], -0.1); } catch(e){ threw = true; }
assert.ok(threw);
console.log('ok');
