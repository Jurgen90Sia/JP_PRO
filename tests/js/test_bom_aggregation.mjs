import assert from 'node:assert/strict';

function normalizeBanding(b) {
  b = b || {};
  return { left: b.left ?? null, right: b.right ?? null, top: b.top ?? null, bottom: b.bottom ?? null };
}
function roundMm(v) { return v == null ? null : Math.round(Number(v) * 1000) / 1000; }
function keyOf(it) {
  return JSON.stringify([
    it.name, it.material_id, it.thickness_mm,
    roundMm(it.width_mm), roundMm(it.height_mm),
    it.grain_direction, normalizeBanding(it.edge_banding)
  ]);
}

function aggregate(items) {
  const groups = new Map();
  for (const it of items) {
    const k = keyOf(it);
    if (groups.has(k)) groups.get(k).quantity += (it.quantity || 1);
    else groups.set(k, { ...it, quantity: it.quantity || 1 });
  }
  return Array.from(groups.values());
}

const items = [
  { name:'side', material_id:'m1', thickness_mm:18, width_mm:18, height_mm:720, grain_direction:'V', edge_banding:{left:null,right:null,top:null,bottom:null}, quantity:1 },
  { name:'side', material_id:'m1', thickness_mm:18, width_mm:18, height_mm:720, grain_direction:'V', edge_banding:{left:null,right:null,top:null,bottom:null}, quantity:1 },
  { name:'side', material_id:'m2', thickness_mm:18, width_mm:18, height_mm:720, grain_direction:'V', edge_banding:{left:null,right:null,top:null,bottom:null}, quantity:1 }
];
const agg = aggregate(items);
assert.equal(agg.length, 2);
const q = agg.find(x => x.material_id==='m1').quantity;
assert.equal(q, 2);

const diffBand = aggregate([
  { name:'p', material_id:'m1', thickness_mm:18, width_mm:100, height_mm:100, grain_direction:null, edge_banding:{left:{material_id:'e',thickness_mm:1},right:null,top:null,bottom:null} },
  { name:'p', material_id:'m1', thickness_mm:18, width_mm:100, height_mm:100, grain_direction:null, edge_banding:{left:null,right:null,top:null,bottom:null} }
]);
assert.equal(diffBand.length, 2);
console.log('ok');
