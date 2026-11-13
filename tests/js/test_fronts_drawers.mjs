import assert from 'node:assert/strict';

// Spec-derived scaffold validation (AJ behavior unverified). No geometry.
const FRONT_TYPES = ['single','double','three','four'];
const SPLITS = ['none','horizontal','vertical','custom_proportional'];
const MOUNTINGS = ['full_overlay','partial_overlay','inset','lift_up','bi_fold','sliding'];
const HINGE_SIDES = ['left','right','top','bottom'];

function validateFront(config = {}) {
  const errors = []; const warnings = [];
  const c = { type: 'single', split: 'none', mounting: 'full_overlay', ...config };
  if (!FRONT_TYPES.includes(c.type)) errors.push('invalid front type');
  if (!SPLITS.includes(c.split)) errors.push('invalid split');
  if (!MOUNTINGS.includes(c.mounting)) errors.push('invalid mounting');
  if (c.hinge_side && !HINGE_SIDES.includes(c.hinge_side)) errors.push('invalid hinge_side');
  for (const k of ['gap_mm','front_thickness_mm','opening_angle_deg']) {
    if (k in c && !(Number(c[k]) >= 0)) errors.push(`${k} must be >= 0`);
  }
  if (c.type === 'single' && c.split !== 'none') warnings.push('split ignored for single');
  return { ok: errors.length === 0, errors, warnings, config: c };
}

const DRAWER_MOUNTINGS = ['overlay','inset'];
function validateDrawer(config = {}) {
  const errors = []; const warnings = [];
  const c = { count: 1, mounting: 'overlay', ...config };
  c.count = Number.isInteger(c.count) ? c.count : parseInt(c.count, 10);
  if (!(c.count >= 1)) errors.push('count must be >= 1');
  if (!DRAWER_MOUNTINGS.includes(c.mounting)) errors.push('invalid mounting');
  if (c.front_heights_mm) {
    if (!Array.isArray(c.front_heights_mm) || !c.front_heights_mm.every(x => Number(x) > 0)) errors.push('front_heights_mm invalid');
  }
  if (!c.catalog_ref) warnings.push('no catalog_ref');
  return { ok: errors.length === 0, errors, warnings, config: c };
}

assert.ok(validateFront({}).ok);
assert.ok(validateFront({ type:'double', split:'vertical', mounting:'inset', hinge_side:'left', gap_mm:2 }).ok);
assert.ok(!validateFront({ type:'bogus' }).ok);
assert.ok(validateFront({ type:'single', split:'horizontal' }).warnings.length > 0);

assert.ok(validateDrawer({}).ok);
assert.ok(validateDrawer({ count:3, mounting:'inset', front_heights_mm:[100,150,200], catalog_ref:'adapter-x' }).ok);
assert.ok(!validateDrawer({ count:0 }).ok);
assert.ok(!validateDrawer({ mounting:'floating' }).ok);
console.log('ok');
