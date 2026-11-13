#!/usr/bin/env node
// Generates a demo cut list CSV from the non-runtime vertical-slice prototype.
// NOT a SketchUp integration test. No geometry mutation.

function validate(input) {
  const v = { width_mm: 800, height_mm: 720, depth_mm: 560, panel_thickness_mm: 18, shelf_count: 1, top_construction: 'top_between_sides', bottom_construction: 'bottom_between_sides', back_mount_type: 'recessed_back', groove_depth_mm: 8, rear_inset_mm: 10, ...input };
  const t = v.panel_thickness_mm;
  let internalH = v.height_mm;
  if (v.top_construction === 'top_between_sides') internalH -= t;
  if (v.bottom_construction === 'bottom_between_sides') internalH -= t;
  let internalD = v.depth_mm;
  if (v.back_mount_type === 'recessed_back') internalD = v.depth_mm - v.rear_inset_mm - t;
  else if (v.back_mount_type === 'grooved_back') internalD = v.depth_mm - v.rear_inset_mm - Math.min(v.groove_depth_mm, t);
  else internalD = v.depth_mm - t;
  v.internal = { internal_width_mm: v.width_mm - 2*t, internal_height_mm: internalH, internal_depth_mm: Math.max(internalD,0) };
  return v;
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
function csvEscape(v){ if(v==null) return ''; const s=String(v); return /[",\n]/.test(s)?`"${s.replace(/"/g,'""')}"`:s; }

const p = validate({ width_mm:900,height_mm:800,depth_mm:560,panel_thickness_mm:18,shelf_count:2,top_construction:'top_between_sides',bottom_construction:'bottom_between_sides',back_mount_type:'recessed_back',groove_depth_mm:8,rear_inset_mm:10 });
const parts = buildParts(p);
const bom = parts.map((x,i)=>({ ...x, part_id:`part_${i+1}`, name:x.role, quantity:1, material_id:'', grain_direction:'', edge_banding:'', assembly_id:'asm_demo' }));
const cols = ['part_id','part_name','material','thickness','length','width','quantity','grain_direction','edge_banding','assembly_id','barcode_qr','manufacturing_notes','size_kind'];
const rows = bom.map(it => ({ part_id:it.part_id, part_name:it.name, material:it.material_id, thickness:it.thickness_mm, length:it.height_mm, width:it.width_mm, quantity:it.quantity, grain_direction:it.grain_direction, edge_banding:JSON.stringify({left:null,right:null,top:null,bottom:null}), assembly_id:it.assembly_id, barcode_qr:it.part_id, manufacturing_notes:'', size_kind:'nominal' }));
const out = [cols.join(',')].concat(rows.map(r => cols.map(c=>csvEscape(r[c])).join(','))).join('\n');
process.stdout.write(out + '\n');
