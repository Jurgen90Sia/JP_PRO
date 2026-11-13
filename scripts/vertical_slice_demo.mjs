#!/usr/bin/env node
// Non-runtime vertical-slice simulation (JS) mirroring Ruby prototype logic for logic verification.
// NOT a SketchUp integration test. No geometry mutation.

import fs from 'node:fs';

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
  if (Number(v.groove_depth_mm) < 0 || Number(v.rear_inset_mm) < 0) errors.push('groove/rear inset must be >= 0');
  const backs = ['full_back','recessed_back','grooved_back','surface_mounted_back'];
  if (!backs.includes(v.back_mount_type)) errors.push('invalid back_mount_type');
  if (errors.length) return { ok: false, errors, values: v };
  const t = v.panel_thickness_mm;
  let internalH = v.height_mm;
  if (v.top_construction === 'top_between_sides') internalH -= t;
  if (v.bottom_construction === 'bottom_between_sides') internalH -= t;
  let internalD = v.depth_mm;
  if (v.back_mount_type === 'recessed_back') internalD = v.depth_mm - v.rear_inset_mm - t;
  else if (v.back_mount_type === 'grooved_back') internalD = v.depth_mm - v.rear_inset_mm - Math.min(v.groove_depth_mm, t);
  else internalD = v.depth_mm - t;
  v.internal = { internal_width_mm: v.width_mm - 2*t, internal_height_mm: internalH, internal_depth_mm: Math.max(internalD,0) };
  return { ok: true, errors: [], values: v };
}

function backDimensions(w,h,d,t,rearInset,groove,back){
  switch(back){
    case 'surface_mounted_back': return [w,h,t];
    case 'grooved_back': return [Math.max(w-2*t+2*Math.min(groove,t),0), Math.max(h-2*t+2*Math.min(groove,t),0), t];
    default: return [Math.max(w-2*t,0), Math.max(h-2*t,0), t];
  }
}
function shelfDepth(d,t,rearInset,groove,back){
  if (back==='recessed_back') return Math.max(d-rearInset-t,0);
  if (back==='grooved_back') return Math.max(d-rearInset-Math.min(groove,t),0);
  return Math.max(d-t,0);
}
function buildParts(p){
  const w=p.width_mm,h=p.height_mm,d=p.depth_mm,t=p.panel_thickness_mm;
  const parts=[];
  parts.push({role:'side_left', width_mm:t,height_mm:h,thickness_mm:d});
  parts.push({role:'side_right',width_mm:t,height_mm:h,thickness_mm:d});
  const topW = p.top_construction==='top_over_sides'?w:Math.max(w-2*t,0);
  const botW = p.bottom_construction==='bottom_under_sides'?w:Math.max(w-2*t,0);
  parts.push({role:'top', width_mm:topW, height_mm:t, thickness_mm:d});
  parts.push({role:'bottom', width_mm:botW, height_mm:t, thickness_mm:d});
  const [bw,bh,bt]=backDimensions(w,h,d,t,p.rear_inset_mm,p.groove_depth_mm,p.back_mount_type);
  parts.push({role:'back', width_mm:bw,height_mm:bh,thickness_mm:bt});
  const sd=shelfDepth(d,t,p.rear_inset_mm,p.groove_depth_mm,p.back_mount_type);
  const sw=Math.max(w-2*t,0);
  for(let i=0;i<p.shelf_count;i++) parts.push({role:`shelf_${i+1}`, width_mm:sw,height_mm:t,thickness_mm:sd});
  return parts;
}
function generateBom(parts, assemblyId){
  return parts.map((p,i)=>({ ...p, part_id:`part_${i+1}`, parent_assembly_id:assemblyId, name:p.role, quantity:1, material_id:null, grain_direction:null, edge_banding:{left:null,right:null,top:null,bottom:null}, revision:1 }));
}
function generateCutlist(bom){
  return bom.map(it=>({ part_id:it.part_id, part_name:it.name, material:it.material_id, thickness:it.thickness_mm, length:it.height_mm, width:it.width_mm, quantity:it.quantity, grain_direction:it.grain_direction, edge_banding:it.edge_banding, assembly_id:it.parent_assembly_id, barcode_qr:it.part_id, size_kind:'nominal' }));
}

const input = { width_mm:900,height_mm:800,depth_mm:560,panel_thickness_mm:18,shelf_count:2,top_construction:'top_between_sides',bottom_construction:'bottom_between_sides',back_mount_type:'recessed_back',groove_depth_mm:8,rear_inset_mm:10 };
const v = validate(input);
if (!v.ok) { console.error(JSON.stringify(v,null,2)); process.exit(1); }
const parts = buildParts(v.values);
const bom = generateBom(parts, 'asm_demo');
const cut = generateCutlist(bom);
const view = { type:'front', status:'scaffold_view_model', dimensions:{width_mm:v.values.width_mm,height_mm:v.values.height_mm,depth_mm:v.values.depth_mm}, parts:bom.length, revision:1 };
const out = { ok:true, pipeline:['preview','rebuild_parts','bom','cutlist','technical_view'], invalidations:['geometry','parts','materials','edge_banding','hardware','bom','cutlist','nesting','drawings','reports'], params:v.values, bom_count:bom.length, cutlist_count:cut.length, view };
console.log(JSON.stringify(out, null, 2));
