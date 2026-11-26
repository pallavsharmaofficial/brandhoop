// node tools/brand/export_cards.js : renders the chosen Card Studio card as print files (600 dpi, trim and 3 mm bleed) into site/brand/print/cards/
// It serves site/ on a local port and drives the real Card Studio page, so the files match what the page shows.
const { chromium } = require('playwright'); const http = require('http'); const fs = require('fs'); const path = require('path');
const root = path.resolve(__dirname, '../../site'); const out = path.join(root, 'brand/print/cards'); fs.mkdirSync(out, { recursive: true });
const STYLE = process.env.CARD_STYLE || 'techgrid';
const STATE = {
  lang: 'hi', qrt: 'web', artAll: false,
  f: { tagline: 'नया फोन हो या रिपेयरिंग का काम, हर ज़रूरत का एक ही मुकाम', services: 'मोबाइल · एक्सेसरी · रिपेयर · स्किन कटिंग · EMI | All mobile service & Repair', role: '' }
};
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.png': 'image/png', '.svg': 'image/svg+xml', '.jpg': 'image/jpeg', '.json': 'application/json' };
const srv = http.createServer((q, r) => { const f = path.join(root, decodeURIComponent(q.url.split('?')[0])); fs.readFile(f.endsWith('/') ? f + 'index.html' : f, (e, d) => { if (e) { r.writeHead(404); return r.end(); } r.writeHead(200, { 'content-type': mime[path.extname(f)] || 'application/octet-stream' }); r.end(d); }); });
(async () => {
  await new Promise((ok) => srv.listen(8791, ok));
  const b = await chromium.launch({ args: ['--no-sandbox'] }); const pg = await b.newPage();
  await pg.goto('http://localhost:8791/brand/cards/index.html'); await pg.waitForFunction(() => window.CardStudioAPI && window.CardStudioAPI.ready());
  await pg.evaluate((s) => window.CardStudioAPI.set(s), STATE); await pg.evaluate(() => document.fonts.ready); await pg.waitForTimeout(800);
  const files = [];
  for (const side of ['front', 'back']) for (const [tag, bleed] of [['', 0], ['-bleed', 3.0 / 25.4 * 300]]) {
    const data = await pg.evaluate(([id, sd, bl]) => window.CardStudioAPI.render(id, sd, 2, bl).toDataURL('image/png'), [STYLE, side, bleed]);
    const f = path.join(out, `visiting-card-${side}${tag}-600dpi.png`); fs.writeFileSync(f, Buffer.from(data.split(',')[1], 'base64')); files.push(f);
  }
  console.log(files.join('\n')); await b.close(); srv.close();
})();
