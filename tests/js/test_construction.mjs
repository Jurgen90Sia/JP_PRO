import assert from 'node:assert/strict';

function backDimensions(w, h, d, t, rearInset, groove, back) {
  switch (back) {
    case 'full_back':
      return [Math.max(w - 2*t, 0), Math.max(h - 2*t, 0), t];
    case 'recessed_back':
      return [Math.max(w - 2*t, 0), Math.max(h - 2*t, 0), t];
    case 'grooved_back':
      return [Math.max(w - 2*t + 2*Math.min(groove, t), 0), Math.max(h - 2*t + 2*Math.min(groove, t), 0), t];
    case 'surface_mounted_back':
      return [w, h, t];
    default:
      return [Math.max(w - 2*t, 0), Math.max(h - 2*t, 0), t];
  }
}

function shelfDepth(d, t, rearInset, groove, back) {
  let depth;
  switch (back) {
    case 'recessed_back': depth = d - rearInset - t; break;
    case 'grooved_back': depth = d - rearInset - Math.min(groove, t); break;
    case 'full_back':
    case 'surface_mounted_back': depth = d - t; break;
    default: depth = d - rearInset;
  }
  return Math.max(depth, 0);
}

function buildParts(p) {
  const w=p.width_mm, h=p.height_mm, d=p.depth_mm, t=p.panel_thickness_mm;
  const shelves=p.shelf_count|0, rearInset=p.rear_inset_mm, groove=p.groove_depth_mm;
  const back=p.back_mount_type, topRule=p.top_construction, bottomRule=p.bottom_construction;
  const parts = [];
  parts.push(['side_left', t, h, d]);
  parts.push(['side_right', t, h, d]);
  const horizW = (topRule === 'top_over_sides') ? w : Math.max(w - 2*t, 0);
  const bottomW = (bottomRule === 'bottom_under_sides') ? w : Math.max(w - 2*t, 0);
  parts.push(['top', horizW, t, d]);
  parts.push(['bottom', bottomW, t, d]);
  parts.push(['back', ...backDimensions(w,h,d,t,rearInset,groove,back)]);
  const sd = shelfDepth(d,t,rearInset,groove,back);
  const sw = Math.max(w - 2*t, 0);
  for (let i=0;i<shelves;i++) parts.push([`shelf_${i+1}`, sw, t, sd]);
  return parts;
}

const base = { width_mm:800,height_mm:720,depth_mm:560,panel_thickness_mm:18,shelf_count:1,top_construction:'top_between_sides',bottom_construction:'bottom_between_sides',back_mount_type:'recessed_back',groove_depth_mm:8,rear_inset_mm:10 };
let parts = buildParts(base);
assert.equal(parts.length, 6);
assert.deepEqual(parts[2], ['top', 764, 18, 560]);
assert.deepEqual(parts[3], ['bottom', 764, 18, 560]);
assert.deepEqual(parts[4], ['back', 764, 684, 18]);
assert.deepEqual(parts[5], ['shelf_1', 764, 18, 532]);

const over = { ...base, top_construction:'top_over_sides', bottom_construction:'bottom_under_sides', shelf_count:0 };
parts = buildParts(over);
assert.equal(parts.length, 5);
assert.deepEqual(parts[2], ['top', 800, 18, 560]);
assert.deepEqual(parts[3], ['bottom', 800, 18, 560]);

const surface = { ...base, back_mount_type:'surface_mounted_back', shelf_count:2 };
parts = buildParts(surface);
assert.deepEqual(parts[4], ['back', 800, 720, 18]);
assert.equal(parts.length, 7);
console.log('ok');
