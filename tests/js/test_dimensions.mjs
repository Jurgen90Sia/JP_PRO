import assert from 'node:assert/strict';

function computeInternal(v) {
  const t = Number(v.panel_thickness_mm);
  let w = Number(v.width_mm) - 2 * t;
  let h = Number(v.height_mm);
  if (v.top_construction === 'top_between_sides') h -= t;
  if (v.bottom_construction === 'bottom_between_sides') h -= t;
  let d = Number(v.depth_mm);
  switch (v.back_mount_type) {
    case 'recessed_back':
      d = Number(v.depth_mm) - Number(v.rear_inset_mm) - t;
      break;
    case 'grooved_back':
      d = Number(v.depth_mm) - Number(v.rear_inset_mm) - Math.min(Number(v.groove_depth_mm), t);
      break;
    case 'full_back':
    case 'surface_mounted_back':
      d = Number(v.depth_mm) - t;
      break;
    default:
      d = Number(v.depth_mm) - Number(v.rear_inset_mm);
  }
  if (d < 0) d = 0;
  return { w, h, d };
}

function validate(v) {
  const errs = [];
  ['width_mm','height_mm','depth_mm','panel_thickness_mm'].forEach(k => { if (!(Number(v[k]) > 0)) errs.push(k + ' must be > 0'); });
  if (!(Number.isInteger(v.shelf_count) && v.shelf_count >= 0)) errs.push('shelf_count must be >= 0');
  if (Number(v.groove_depth_mm) < 0 || Number(v.rear_inset_mm) < 0) errs.push('groove/rear inset must be >= 0');
  const backs = ['full_back','recessed_back','grooved_back','surface_mounted_back'];
  if (!backs.includes(v.back_mount_type)) errs.push('invalid back_mount_type');
  return errs;
}

const base = {
  width_mm: 800, height_mm: 720, depth_mm: 560, panel_thickness_mm: 18, shelf_count: 1,
  top_construction: 'top_between_sides', bottom_construction: 'bottom_between_sides',
  back_mount_type: 'recessed_back', groove_depth_mm: 8, rear_inset_mm: 10
};
assert.deepEqual(validate(base), []);
assert.deepEqual(computeInternal(base), { w: 764, h: 684, d: 532 });

const over = { ...base, top_construction: 'top_over_sides', bottom_construction: 'bottom_under_sides' };
assert.deepEqual(computeInternal(over), { w: 764, h: 720, d: 532 });

const grooved = { ...base, back_mount_type: 'grooved_back', groove_depth_mm: 8 };
assert.deepEqual(computeInternal(grooved), { w: 764, h: 684, d: 542 });

const fullBack = { ...base, back_mount_type: 'full_back' };
assert.deepEqual(computeInternal(fullBack), { w: 764, h: 684, d: 542 });

assert.ok(validate({ ...base, width_mm: 0 }).length > 0);
assert.ok(validate({ ...base, shelf_count: -1 }).length > 0);
assert.ok(validate({ ...base, back_mount_type: 'bogus' }).length > 0);
console.log('ok');
