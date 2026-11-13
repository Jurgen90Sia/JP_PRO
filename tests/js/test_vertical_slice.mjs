import assert from 'node:assert/strict';

function validate(input) {
  const v = {
    width_mm: 800, height_mm: 720, depth_mm: 560, panel_thickness_mm: 18,
    shelf_count: 1, top_construction: 'top_between_sides', bottom_construction: 'bottom_between_sides',
    back_mount_type: 'recessed_back', groove_depth_mm: 8, rear_inset_mm: 10,
    ...input
  };
  const errors = [];
  for (const k of ['width_mm','height_mm','depth_mm','panel_thickness_mm']) if (!(Number(v[k]) > 0)) errors.push(`${k} must be > 0`);
  if (!(Number.isInteger(v.shelf_count) && v.shelf_count >= 0)) errors.push('shelf_count must be >= 0');
  const backs = ['full_back','recessed_back','grooved_back','surface_mounted_back'];
  if (!backs.includes(v.back_mount_type)) errors.push('invalid back_mount_type');
  if (errors.length) return { ok: false, errors };
  const t = v.panel_thickness_mm;
  let internalH = v.height_mm;
  if (v.top_construction === 'top_between_sides') internalH -= t;
  if (v.bottom_construction === 'bottom_between_sides') internalH -= t;
  let internalD = v.depth_mm;
  if (v.back_mount_type === 'recessed_back') internalD = v.depth_mm - v.rear_inset_mm - t;
  else if (v.back_mount_type === 'grooved_back') internalD = v.depth_mm - v.rear_inset_mm - Math.min(v.groove_depth_mm, t);
  else internalD = v.depth_mm - t;
  return { ok: true, values: { ...v, internal: { internal_width_mm: v.width_mm - 2*t, internal_height_mm: internalH, internal_depth_mm: Math.max(internalD,0) } } };
}

function buildParts(p){
  const w=p.width_mm,h=p.height_mm,d=p.depth_mm,t=p.panel_thickness_mm;
  const parts=[];
  parts.push({role:'side_left'}); parts.push({role:'side_right'});
  parts.push({role:'top'}); parts.push({role:'bottom'}); parts.push({role:'back'});
  for(let i=0;i<p.shelf_count;i++) parts.push({role:`shelf_${i+1}`});
  return parts;
}

const input = { width_mm:900,height_mm:800,depth_mm:560,panel_thickness_mm:18,shelf_count:2,top_construction:'top_between_sides',bottom_construction:'bottom_between_sides',back_mount_type:'recessed_back',groove_depth_mm:8,rear_inset_mm:10 };
const v = validate(input);
assert.ok(v.ok);
assert.deepEqual(v.values.internal, { internal_width_mm: 864, internal_height_mm: 764, internal_depth_mm: 532 });
const parts = buildParts(v.values);
const bom = parts.map((p,i)=>({ ...p, part_id:`part_${i+1}`, quantity:1 }));
const cut = bom.map(it=>({ part_id:it.part_id, size_kind:'nominal' }));
const view = { type:'front', status:'scaffold_view_model', revision:1 };
assert.equal(parts.length, 7);
assert.equal(bom.length, 7);
assert.equal(cut.length, 7);
assert.equal(view.type, 'front');

const bad = validate({ width_mm: -1 });
assert.ok(!bad.ok);
console.log('ok');
