// Vector print files for the visiting card (front and back), for the printer:
//   (cd tools/brand && npm i)             once: installs canvas2svg
//   node tools/brand/make_vector_card.js   then   python3 tools/brand/make_vector_cmyk.py
//
// The Card Studio draws on a canvas. Here the same drawing code runs against canvas2svg, which writes SVG
// instead of pixels, so the layout is exactly the one in the PNGs but every shape, the logo and the text stay
// vector. The line art is the potrace-traced vector in tools/brand/assets. Chromium prints that SVG to PDF
// (RGB, vector); make_vector_cmyk.py then converts it to CMYK, turns the text into outlines and sets the PDF boxes.
const { chromium } = require('playwright'); const http = require('http'); const fs = require('fs'); const path = require('path');
const root = path.resolve(__dirname, '../../site'); const fonts = path.join(__dirname, 'fonts'); const assets = path.join(__dirname, 'assets');
const out = path.join(__dirname, 'build/vector'); fs.mkdirSync(out, { recursive: true });
const C2S_JS = process.env.C2S_JS || path.join(__dirname, 'node_modules/canvas2svg/canvas2svg.js');
const STYLE = process.env.CARD_STYLE || 'techgrid';
const STATE = {
  lang: 'hi', qrt: 'web', artAll: false,
  f: { tagline: 'नया फोन हो या रिपेयरिंग का काम, हर ज़रूरत का एक ही मुकाम', services: 'मोबाइल · एक्सेसरी · रिपेयर · स्किन कटिंग · EMI | All mobile service & Repair', role: '' }
};
const W = 1050, H = 600, MM = 25.4 / 300;           // the card is 3.5 x 2 in = 1050 x 600 units at 300 per inch
const BLEED = 3 / MM;                                  // 3 mm in card units
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.png': 'image/png', '.svg': 'image/svg+xml', '.jpg': 'image/jpeg', '.json': 'application/json', '.woff': 'font/woff' };
const srv = http.createServer((q, r) => {
  const u = decodeURIComponent(q.url.split('?')[0]);
  const f = u.startsWith('/__fonts/') ? path.join(fonts, u.slice(9)) : u.startsWith('/__assets/') ? path.join(assets, u.slice(10)) : path.join(root, u);
  fs.readFile(f.endsWith('/') ? f + 'index.html' : f, (e, d) => { if (e) { r.writeHead(404); return r.end(); } r.writeHead(200, { 'content-type': mime[path.extname(f)] || 'application/octet-stream', 'access-control-allow-origin': '*' }); r.end(d); });
});
// The realistic logo has three soft blur filters (glow and shadow). Chromium turns a filtered shape into a picture,
// so for print they are removed and the logo stays pure vector paths and gradients.
function printLogo(file) {
  let svg = fs.readFileSync(file, 'utf8');
  svg = svg.replace(/<filter[\s\S]*?<\/filter>/g, '').replace(/\s(filter|mask)="url\(#[^)]*\)"/g, '');
  return 'data:image/svg+xml;base64,' + Buffer.from(svg).toString('base64');
}
const dataUri = (file) => 'data:image/svg+xml;base64,' + fs.readFileSync(file).toString('base64');
const FONT_CSS = `
@font-face{font-family:Montserrat;font-weight:600;src:url(/__fonts/montserrat-latin-600-normal.woff)}
@font-face{font-family:Montserrat;font-weight:700;src:url(/__fonts/montserrat-latin-700-normal.woff)}
@font-face{font-family:Montserrat;font-weight:800;src:url(/__fonts/montserrat-latin-800-normal.woff)}
@font-face{font-family:"Noto Sans Devanagari";font-weight:600;src:url(/__fonts/noto-sans-devanagari-devanagari-600-normal.woff)}
@font-face{font-family:"Noto Sans Devanagari";font-weight:700;src:url(/__fonts/noto-sans-devanagari-devanagari-700-normal.woff)}
@font-face{font-family:"Noto Sans Devanagari";font-weight:800;src:url(/__fonts/noto-sans-devanagari-devanagari-800-normal.woff)}`;

(async () => {
  await new Promise((ok) => srv.listen(8792, ok));
  const b = await chromium.launch({ args: ['--no-sandbox'] });
  const pg = await b.newPage();
  // the Google Fonts link in the studio cannot be reached here; the bundled files are used instead
  await pg.route(/fonts\.(googleapis|gstatic)\.com/, (r) => r.fulfill({ status: 200, contentType: 'text/css', body: '' }));
  await pg.goto('http://localhost:8792/brand/cards/index.html');
  await pg.addStyleTag({ content: FONT_CSS });
  await pg.addScriptTag({ content: fs.readFileSync(C2S_JS, 'utf8') });
  await pg.waitForFunction(() => window.CardStudioAPI && window.CardStudioAPI.ready());
  await pg.evaluate((s) => window.CardStudioAPI.set(s), STATE);
  await pg.evaluate(async () => { await Promise.all(['600', '700', '800'].flatMap((w) => [document.fonts.load(w + ' 30px Montserrat'), document.fonts.load(w + ' 30px "Noto Sans Devanagari"', 'नरेश सैनी')])); await document.fonts.ready; });

  const svgs = {};
  for (const side of ['front', 'back']) {
    svgs[side] = await pg.evaluate(([id, sd, B, w, h, LINEART, LOGOS, LATSHIFT, DEVSHIFT]) => {
      // canvas2svg cannot turn an arc that runs past a full circle (the studio's dots use 0 to 7 radians) into SVG
      if (!C2S.prototype.__arcFixed) { const arc = C2S.prototype.arc; C2S.prototype.arc = function (x, y, r, a0, a1, ccw) { if (a1 - a0 >= Math.PI * 2) a1 = a0 + Math.PI * 2 - 1e-4; return arc.call(this, x, y, r, a0, a1, ccw); }; C2S.prototype.__arcFixed = true; }
      const ctx = new C2S(w, h); const orig = HTMLCanvasElement.prototype.getContext;
      HTMLCanvasElement.prototype.getContext = function () { return ctx; };
      try { window.CardStudioAPI.render(id, sd, 1, 0); } finally { HTMLCanvasElement.prototype.getContext = orig; }
      const doc = new DOMParser().parseFromString(ctx.getSerializedSvg(true), 'image/svg+xml'); const root = doc.documentElement;
      // the line art becomes the traced vector
      root.querySelectorAll('image').forEach((im) => {
        const href = im.getAttribute('xlink:href') || im.getAttribute('href') || ''; let to = href;
        if (/lineart\.png/.test(href)) { to = LINEART; im.setAttribute('data-art', '1'); } else { const m = href.match(/logo\/([\w-]+\.svg)/); if (m && LOGOS[m[1]]) to = LOGOS[m[1]]; }
        im.setAttribute('xlink:href', to); im.setAttribute('href', to);
      });
      // canvas2svg writes an image and its position as two siblings, and drops globalAlpha: put both back
      root.querySelectorAll('image').forEach((im) => {
        const nx = im.nextElementSibling; const t = nx && nx.tagName === 'g' && !nx.children.length && /translate\(([-\d.e]+),([-\d.e]+)\)/.exec(nx.getAttribute('transform') || '');
        if (t) { im.setAttribute('x', t[1]); im.setAttribute('y', t[2]); nx.remove(); }
        if (im.getAttribute('data-art')) { im.setAttribute('opacity', '0.05'); im.removeAttribute('data-art'); }
      });
      // text: the canvas 'top' baseline sits a little higher than SVG's text-before-edge in the printed PDF
      root.querySelectorAll('text').forEach((t) => {
        const fs = parseFloat(t.getAttribute('font-size')); const dev = /[\u0900-\u097F]/.test(t.textContent);
        t.setAttribute('y', (+t.getAttribute('y') - fs * (dev ? DEVSHIFT : LATSHIFT)).toFixed(2)); t.setAttribute('xml:space', 'preserve');
      });
      // anything that touches the card edge is pushed out into the bleed
      const near = (a, b) => Math.abs(a - b) < 0.6;
      root.querySelectorAll('rect').forEach((r) => {
        let x = +r.getAttribute('x') || 0, y = +r.getAttribute('y') || 0, rw = +r.getAttribute('width'), rh = +r.getAttribute('height');
        if (!rw || !rh) return; let nx = x, ny = y, nw = rw, nh = rh;
        if (near(x, 0)) { nx = -B; nw += B; } if (near(x + rw, w)) nw += B; if (near(y, 0)) { ny = -B; nh += B; } if (near(y + rh, h)) nh += B;
        r.setAttribute('x', nx); r.setAttribute('y', ny); r.setAttribute('width', nw); r.setAttribute('height', nh);
      });
      return root.innerHTML;
    }, [STYLE, side, BLEED, W, H, dataUri(path.join(assets, 'lineart-vector.svg')), Object.fromEntries(fs.readdirSync(path.join(root, 'brand/logo')).filter((n) => n.endsWith('.svg')).map((n) => [n, printLogo(path.join(root, 'brand/logo', n))])), +(process.env.LATSHIFT || 0.16), +(process.env.DEVSHIFT || 0.2)]);
    // the studio's logos are relative to the card page
  }
  for (const side of ['front', 'back']) for (const [tag, B] of [['trim', 0], ['bleed', BLEED]]) {
    const wmm = (W + 2 * B) * MM, hmm = (H + 2 * B) * MM;
    const html = `<!doctype html><meta charset="utf-8"><style>${FONT_CSS}@page{size:${wmm}mm ${hmm}mm;margin:0}html,body{margin:0;background:#fff}svg{display:block;width:${wmm}mm;height:${hmm}mm}</style>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="${-B} ${-B} ${W + 2 * B} ${H + 2 * B}" width="${wmm}mm" height="${hmm}mm"><defs><clipPath id="page"><rect x="${-B}" y="${-B}" width="${W + 2 * B}" height="${H + 2 * B}"/></clipPath></defs><g clip-path="url(#page)">${svgs[side]}</g></svg>`;
    fs.writeFileSync(path.join(out, `${side}-${tag}.svg.html`), html);
    const p = await b.newPage();
    await p.setContent(html.replace('<meta charset="utf-8">', '<meta charset="utf-8"><base href="http://localhost:8792/">'), { waitUntil: 'networkidle' });
    await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(500);
    await p.pdf({ path: path.join(out, `${side}-${tag}-rgb.pdf`), width: `${wmm}mm`, height: `${hmm}mm`, printBackground: true, margin: { top: 0, right: 0, bottom: 0, left: 0 }, pageRanges: '1' });
    await p.close();
  }
  console.log(fs.readdirSync(out).join('\n')); await b.close(); srv.close();
})();
