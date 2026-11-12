import assert from 'node:assert/strict';

function computeInternal(v) {
  const t = Number(v.panel_thickness_mm);
  return {
    w: Number(v.width_mm) - 2 * t,
    h: Number(v.height_mm) - 2 * t,
    d: Number(v.depth_mm) - Number(v.rear_inset_mm)
  };
}

function validate(v) {
  const errs = [];
  ['width_mm','height_mm','depth_mm','panel_thickness_mm'].forEach(k => { if (!(Number(v[k]) > 0)) errs.push(k + ' must be > 0'); });
  if (!(Number.isInteger(v.shelf_count) && v.shelf_count >= 0)) errs.push('shelf_count must be >= 0');
  if (Number(v.groove_depth_mm) < 0 || Number(v.rear_inset_mm) < 0) errs.push('groove/rear inset must be >= 0');
  return errs;
}

// defaults case like Ruby
const base = { width_mm: 800, height_mm: 720, depth_mm: 560, panel_thickness_mm: 18, shelf_count: 1, groove_depth_mm: 8, rear_inset_mm: 10 };
assert.deepEqual(validate(base), []);
const internal = computeInternal(base);
assert.equal(internal.w, 764);
assert.equal(internal.h, 684);
assert.equal(internal.d, 550);

assert.ok(validate({ ...base, width_mm: 0 }).length > 0);
assert.ok(validate({ ...base, shelf_count: -1 }).length > 0);
console.log('ok');
