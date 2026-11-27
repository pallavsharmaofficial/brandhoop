// Builds a simple, honest 3D model of a phone from its published size and camera layout:
//   node tools/models3d/generate_phone.mjs <product-id>
// reads tools/models3d/specs/<id>.json, writes tools/models3d/raw/<id>.glb
//
// It is an illustration made from numbers (height, width, thickness, camera island, lens
// positions, colour), not a scan or a copy of anyone's model or photo. All geometry and the
// screen picture are generated here, so the result is ours (CC0).
import { Document, NodeIO } from '@gltf-transform/core';
import sharp from 'sharp';
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const id = process.argv[2];
if (!id) { console.error('usage: generate_phone.mjs <product-id>'); process.exit(2); }
const spec = JSON.parse(fs.readFileSync(path.join(here, 'specs', id + '.json'), 'utf8'));
const MM = 0.001;
const H = spec.dims.h * MM, W = spec.dims.w * MM, T = spec.dims.t * MM;
const R = (spec.cornerR || 9.5) * MM;

// ---------------------------------------------------------------- geometry helpers
/** Outline of a rounded rectangle, counter-clockwise seen from +Z, centred on (cx, cy). */
function rrect(cx, cy, w, h, r, seg = 8) {
  r = Math.max(Math.min(r, w / 2, h / 2), 0.0002);
  const pts = []; const hx = w / 2 - r, hy = h / 2 - r;
  const corners = [[hx, hy, 0], [-hx, hy, Math.PI / 2], [-hx, -hy, Math.PI], [hx, -hy, Math.PI * 1.5]];
  for (const [x, y, a0] of corners) for (let i = 0; i <= seg; i++) { const a = a0 + (i / seg) * Math.PI / 2; pts.push([cx + x + r * Math.cos(a), cy + y + r * Math.sin(a)]); }
  return pts;
}
const shrink = (o, s) => (inset) => rrect(o.cx, o.cy, o.w - 2 * inset, o.h - 2 * inset, o.r - inset, o.seg);

/** Accumulating mesh builder with smooth normals. */
class Mesh {
  constructor() { this.p = []; this.uv = []; this.groups = {}; }
  v(x, y, z, u = 0, w = 0) { this.p.push(x, y, z); this.uv.push(u, w); return this.p.length / 3 - 1; }
  tri(g, a, b, c) { (this.groups[g] ||= []).push(a, b, c); }
  /** Rings of equal length joined into a band; flip reverses the winding. */
  band(g, r0, r1, flip) { const n = r0.length; for (let i = 0; i < n; i++) { const j = (i + 1) % n; if (!flip) { this.tri(g, r0[i], r0[j], r1[i]); this.tri(g, r0[j], r1[j], r1[i]); } else { this.tri(g, r0[i], r1[i], r0[j]); this.tri(g, r0[j], r1[i], r1[j]); } } }
  fan(g, ring, centre, flip) { const n = ring.length; for (let i = 0; i < n; i++) { const j = (i + 1) % n; if (flip) this.tri(g, centre, ring[j], ring[i]); else this.tri(g, centre, ring[i], ring[j]); } }
  normals() {
    const nrm = new Float32Array(this.p.length);
    for (const idx of Object.values(this.groups)) for (let i = 0; i < idx.length; i += 3) {
      const [a, b, c] = [idx[i], idx[i + 1], idx[i + 2]]; const P = (k) => [this.p[3 * k], this.p[3 * k + 1], this.p[3 * k + 2]];
      const pa = P(a), pb = P(b), pc = P(c); const u = [pb[0] - pa[0], pb[1] - pa[1], pb[2] - pa[2]], v = [pc[0] - pa[0], pc[1] - pa[1], pc[2] - pa[2]];
      const n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]];
      for (const k of [a, b, c]) { nrm[3 * k] += n[0]; nrm[3 * k + 1] += n[1]; nrm[3 * k + 2] += n[2]; }
    }
    for (let k = 0; k < nrm.length; k += 3) { const l = Math.hypot(nrm[k], nrm[k + 1], nrm[k + 2]) || 1; nrm[k] /= l; nrm[k + 1] /= l; nrm[k + 2] /= l; }
    return nrm;
  }
}

/** A slab: rings of `outline(inset)` at heights z, with a cap at each end. profile = [[inset, z, group]...] from first cap to last cap. */
function slab(m, outline, profile, { capA, capB, flip = false, uv = null } = {}) {
  const rings = profile.map(([inset, z]) => outline(inset).map(([x, y]) => m.v(x, y, z, uv ? uv(x, y)[0] : 0, uv ? uv(x, y)[1] : 0)));
  for (let k = 0; k < rings.length - 1; k++) m.band(profile[k + 1][2], rings[k], rings[k + 1], flip);
  const cap = (ringIdx, group, up) => { const pts = outline(profile[ringIdx][0]); const cx = pts.reduce((s, q) => s + q[0], 0) / pts.length, cy = pts.reduce((s, q) => s + q[1], 0) / pts.length; const z = profile[ringIdx][1]; const c = m.v(cx, cy, z, uv ? uv(cx, cy)[0] : 0, uv ? uv(cx, cy)[1] : 0); m.fan(group, rings[ringIdx], c, up ? flip : !flip); };
  if (capA) cap(0, capA, false);
  if (capB) cap(rings.length - 1, capB, true);
  return rings;
}
const arc = (n, f) => Array.from({ length: n + 1 }, (_, i) => f(i / n * Math.PI / 2));

// ---------------------------------------------------------------- document
const doc = new Document(); const buffer = doc.createBuffer(); const scene = doc.createScene(id);
const hex = (h) => { const c = [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255); return c.map((x) => (x <= 0.04045 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4)); };
const shade = (h, k) => '#' + [1, 3, 5].map((i) => Math.max(0, Math.min(255, Math.round(parseInt(h.slice(i, i + 2), 16) * k))).toString(16).padStart(2, '0')).join('');
const mat = (name, colour, metal, rough, extra = {}) => { const m = doc.createMaterial(name).setBaseColorFactor([...hex(colour), extra.alpha ?? 1]).setMetallicFactor(metal).setRoughnessFactor(rough).setDoubleSided(false); if (extra.alpha < 1) m.setAlphaMode('BLEND'); return m; };
const glossy = spec.finish !== 'matte';
const body = spec.colour || '#3C4775';
const M = {
  back: mat('back', body, glossy ? 0.05 : 0.15, glossy ? 0.28 : 0.55),
  frame: mat('frame', shade(body, 0.72), 0.2, 0.5),
  front: mat('front-glass', '#07080C', 0.0, 0.08),
  island: mat('island', shade(body, glossy ? 0.5 : 0.45), 0.5, 0.3),
  ring: mat('lens-ring', '#B9BEC9', 0.95, 0.25),
  glass: mat('lens-glass', '#05070D', 0.0, 0.04),
  glint: mat('lens-glint', '#26324F', 0.0, 0.1),
  flash: mat('flash', '#FFE9B0', 0.0, 0.3),
  btn: mat('button', shade(body, 0.62), 0.9, 0.3),
  port: mat('port', '#06070A', 0.0, 0.6),
};
M.flash.setEmissiveFactor([0.9, 0.78, 0.45]);

function addMesh(name, m, groupMat, texMat = {}) {
  const pos = doc.createAccessor(name + '-pos').setType('VEC3').setArray(new Float32Array(m.p)).setBuffer(buffer);
  const nor = doc.createAccessor(name + '-nor').setType('VEC3').setArray(m.normals()).setBuffer(buffer);
  const tex = doc.createAccessor(name + '-uv').setType('VEC2').setArray(new Float32Array(m.uv)).setBuffer(buffer);
  const mesh = doc.createMesh(name);
  for (const [g, idx] of Object.entries(m.groups)) {
    const ia = doc.createAccessor(name + '-' + g).setType('SCALAR').setArray(new Uint32Array(idx)).setBuffer(buffer);
    mesh.addPrimitive(doc.createPrimitive().setAttribute('POSITION', pos).setAttribute('NORMAL', nor).setAttribute('TEXCOORD_0', tex).setIndices(ia).setMaterial((texMat[g] || groupMat)[g] || groupMat[g]));
  }
  const node = doc.createNode(name).setMesh(mesh); scene.addChild(node); return node;
}

// ---------------------------------------------------------------- body: back, sides, front
const eb = Math.min(spec.frame === 'rounded' ? 2.6 : 1.1, spec.dims.t * 0.42) * MM;     // back edge rounding
const ef = Math.min(spec.front === 'curved' ? 2.4 : 0.9, spec.dims.t * 0.4) * MM;       // front edge rounding
const bodyOutline = shrink({ cx: 0, cy: 0, w: W, h: H, r: R, seg: 9 });
const prof = [];
prof.push([eb, 0, 'back']);
for (const a of arc(6, (t) => t)) if (a > 0) prof.push([eb - eb * Math.sin(a), eb - eb * Math.cos(a), 'back']);
prof.push([0, T - ef, 'side']);
for (const a of arc(6, (t) => t)) if (a > 0) prof.push([ef - ef * Math.cos(a), T - ef + ef * Math.sin(a), 'front']);
// the first quad group is named by its upper ring, so the back arc is "back", the straight side "side"
prof[prof.length - 1][2] = 'front';
const bodyMesh = new Mesh();
// the flat back is the cap at the first ring; the front cap is black glass
slab(bodyMesh, bodyOutline, prof, { capA: 'back', capB: 'front' });
addMesh('body', bodyMesh, { back: M.back, side: M.frame, front: M.front });

// ---------------------------------------------------------------- screen picture
const bez = { s: 1.1 * MM, t: 1.3 * MM, b: 1.5 * MM };
const sw = W - 2 * bez.s - (spec.front === 'curved' ? 0.6 * MM : 0), sh = H - bez.t - bez.b, scy = (bez.b - bez.t) / 2;
const screenMesh = new Mesh();
const zS = T + 0.00006;
const sOutline = (inset) => rrect(0, scy, sw - 2 * inset, sh - 2 * inset, R - 1.2 * MM - inset, 9);
const uvOf = (x, y) => [(x + sw / 2) / sw, 1 - (y - scy + sh / 2) / sh];
const sRing = sOutline(0).map(([x, y]) => screenMesh.v(x, y, zS, ...uvOf(x, y)));
const sc = screenMesh.v(0, scy, zS, 0.5, 0.5); screenMesh.fan('screen', sRing, sc, true);
const label = spec.name.replace(/ 5G$/, '');
const wall = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="540" height="1170" viewBox="0 0 540 1170"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2B3558"/><stop offset=".55" stop-color="#1F2744"/><stop offset="1" stop-color="#141A33"/></linearGradient><radialGradient id="o" cx=".85" cy=".1" r=".7"><stop offset="0" stop-color="#D8662A" stop-opacity=".85"/><stop offset="1" stop-color="#D8662A" stop-opacity="0"/></radialGradient></defs><rect width="540" height="1170" fill="url(#g)"/><rect width="540" height="1170" fill="url(#o)"/><circle cx="90" cy="1020" r="210" fill="#8F99C0" opacity=".12"/><text x="270" y="430" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" font-weight="800" font-size="86" fill="#fff">9:41</text><text x="270" y="760" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" font-weight="800" font-size="46" fill="#fff" letter-spacing="3">BRANDHOOP</text><text x="270" y="808" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" font-weight="600" font-size="26" fill="#F1A774">MOBILE POINT</text><text x="270" y="880" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" font-weight="600" font-size="30" fill="#DDE1EF">${label.replace(/&/g, '&amp;')}</text></svg>`);
const wallPng = await sharp(wall).png().toBuffer();
const wallTex = doc.createTexture('screen').setImage(wallPng).setMimeType('image/png');
const screenMat = doc.createMaterial('screen').setBaseColorFactor([0.02, 0.02, 0.03, 1]).setMetallicFactor(0).setRoughnessFactor(0.12)
  .setEmissiveTexture(wallTex).setEmissiveFactor([0.9, 0.9, 0.9]).setDoubleSided(true);
addMesh('screen', screenMesh, { screen: screenMat });

// camera cut-out on the screen
const cut = spec.cutout || 'punch-center';
if (cut !== 'none') {
  const cx = cut === 'punch-left' ? -sw / 2 + 7 * MM : cut === 'punch-right' ? sw / 2 - 7 * MM : 0;
  const cy = scy + sh / 2 - 4.2 * MM; const hm = new Mesh(); const ring = []; const n = 24;
  for (let i = 0; i < n; i++) { const a = i / n * Math.PI * 2; ring.push(hm.v(cx + 1.7 * MM * Math.cos(a), cy + 1.7 * MM * Math.sin(a), zS + 0.00004)); }
  hm.fan('hole', ring, hm.v(cx, cy, zS + 0.00004), true);
  addMesh('selfie', hm, { hole: M.port });
}

// ---------------------------------------------------------------- back: camera island, lenses, flash, mark
// Back-view coordinates are millimetres from the phone's top-left corner as seen from behind.
const bx = (xb) => W / 2 - xb * MM;      // back-view x to model x (the back faces -Z, so left and right swap)
const by = (yb) => H / 2 - yb * MM;
const isl = spec.island;
let islandTop = 0;
if (isl && isl.shape !== 'none') {
  const hI = (isl.h_mm || 1.1) * MM; islandTop = hI;
  const im = new Mesh();
  const cxI = bx(isl.x + isl.w / 2), cyI = by(isl.y + isl.h / 2);
  const o = shrink({ cx: cxI, cy: cyI, w: isl.w * MM, h: isl.h * MM, r: (isl.shape === 'circle' ? Math.min(isl.w, isl.h) / 2 : isl.shape === 'pill' ? Math.min(isl.w, isl.h) / 2 : (isl.r || 4)) * MM, seg: 10 });
  const rr = Math.min(0.7 * MM, hI / 2);
  const pI = [[rr, 0, 'a']]; for (const a of arc(4, (t) => t)) if (a > 0) pI.push([rr - rr * Math.sin(a), -(rr - rr * Math.cos(a)), 'edge']);
  pI.push([0, -(hI - rr), 'edge']); for (const a of arc(4, (t) => t)) if (a > 0) pI.push([rr - rr * Math.cos(a), -(hI - rr + rr * Math.sin(a)), 'edge']);
  pI[pI.length - 1][2] = 'top';
  slab(im, o, pI, { capA: null, capB: 'top', flip: true });
  addMesh('island', im, { edge: M.island, top: M.island });
}
const lensMeshes = new Mesh();
for (const L of spec.lenses || []) {
  const r = L.r * MM, cx = bx(L.x), cy = by(L.y), z0 = L.on === 'back' ? 0 : -islandTop;
  const o = (inset) => rrect(cx, cy, 2 * (r - inset), 2 * (r - inset), r - inset, 14);
  const hb = 0.7 * MM;
  slab(lensMeshes, o, [[0, z0, 'ring'], [0, z0 - hb, 'ring'], [0.35 * MM, z0 - hb, 'ringTop'], [0.35 * MM, z0 - hb - 0.05 * MM, 'ringTop']].map((q, i, a) => i === 3 ? [q[0], q[1], 'ringTop'] : q), { capA: null, capB: 'ringTop', flip: true });
  const g = (inset, z, grp) => [inset, z, grp];
  slab(lensMeshes, o, [g(0.45 * MM, z0 - hb - 0.05 * MM, 'glass'), g(0.5 * MM, z0 - hb - 0.1 * MM, 'glass')], { capA: null, capB: 'glass', flip: true });
  slab(lensMeshes, (inset) => rrect(cx - r * 0.25, cy + r * 0.25, 2 * (r * 0.28 - inset), 2 * (r * 0.28 - inset), r * 0.28 - inset, 10), [g(0, z0 - hb - 0.12 * MM, 'glint'), g(0, z0 - hb - 0.13 * MM, 'glint')], { capA: null, capB: 'glint', flip: true });
}
for (const F of spec.flash || []) {
  const r = F.r * MM, cx = bx(F.x), cy = by(F.y), z0 = F.on === 'back' ? 0 : -islandTop;
  slab(lensMeshes, (inset) => rrect(cx, cy, 2 * (r - inset), 2 * (r - inset), r - inset, 10), [[0, z0 - 0.03 * MM, 'flash'], [0, z0 - 0.2 * MM, 'flash']], { capA: null, capB: 'flash', flip: true });
}
if (Object.keys(lensMeshes.groups).length) addMesh('camera', lensMeshes, { ring: M.ring, ringTop: M.ring, glass: M.glass, glint: M.glint, flash: M.flash });

// the brand word on the back, a flat transparent decal
const logoSvg = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="512" height="128"><text x="256" y="92" text-anchor="middle" font-family="Helvetica,Arial,sans-serif" font-weight="${spec.brand === 'OPPO' ? 700 : 300}" font-size="${spec.brand === 'OPPO' ? 84 : 96}" fill="#ffffff" fill-opacity=".72" letter-spacing="${spec.brand === 'OPPO' ? 6 : 2}">${spec.brand}</text></svg>`);
const logoTex = doc.createTexture('mark').setImage(await sharp(logoSvg).png().toBuffer()).setMimeType('image/png');
const logoMat = doc.createMaterial('mark').setBaseColorTexture(logoTex).setBaseColorFactor([1, 1, 1, 1]).setAlphaMode('BLEND').setMetallicFactor(0).setRoughnessFactor(0.4).setDoubleSided(true);
const lm = new Mesh(); const lw = Math.min(30, spec.dims.w * 0.42) * MM, lh = lw / 4; const lz = -0.00004; const lcy = by(spec.dims.h * 0.72), lcx = 0;
const q = [[lcx - lw / 2, lcy - lh / 2, 1, 1], [lcx + lw / 2, lcy - lh / 2, 0, 1], [lcx + lw / 2, lcy + lh / 2, 0, 0], [lcx - lw / 2, lcy + lh / 2, 1, 0]].map(([x, y, u, v]) => lm.v(x, y, lz, u, v));
lm.tri('mark', q[0], q[2], q[1]); lm.tri('mark', q[0], q[3], q[2]);
addMesh('mark', lm, { mark: logoMat });

// ---------------------------------------------------------------- side keys and the USB-C opening
const bm = new Mesh();
function box(m, g, x0, x1, y0, y1, z0, z1) {
  const v = [[x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0], [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1]].map((p) => m.v(...p));
  const f = [[0, 3, 2, 1], [4, 5, 6, 7], [0, 1, 5, 4], [2, 3, 7, 6], [1, 2, 6, 5], [0, 4, 7, 3]];
  for (const [a, b, c, d] of f) { m.tri(g, v[a], v[b], v[c]); m.tri(g, v[a], v[c], v[d]); }
}
const side = spec.buttons?.side === 'left' ? -1 : 1; const xs = side * (W / 2);
const zc = T / 2;
for (const k of ['power', 'volume']) {
  const b = spec.buttons?.[k]; if (!b) continue;
  const yc = H / 2 - b.y * MM, len = b.len * MM;
  box(bm, 'btn', Math.min(xs, xs + side * 0.0007), Math.max(xs, xs + side * 0.0007) - side * 0.0002, yc - len / 2, yc + len / 2, zc - 0.0009, zc + 0.0009);
}
box(bm, 'port', -4.2 * MM, 4.2 * MM, -H / 2 - 0.0001, -H / 2 + 0.0002, zc - 1.2 * MM, zc + 1.2 * MM);
addMesh('keys', bm, { btn: M.btn, port: M.port });

// every mesh in a flat scene; centre the phone on its middle
for (const n of scene.listChildren()) n.setTranslation([0, 0, -T / 2]);
fs.mkdirSync(path.join(here, 'raw'), { recursive: true });
const out = path.join(here, 'raw', id + '.glb');
await new NodeIO().write(out, doc);
console.log(JSON.stringify({ id, bytes: fs.statSync(out).size }));
