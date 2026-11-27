// Screenshots of the product page with a working 3D model, at phone size (375x812), using the real
// built web app (build/web) and the real viewer page. Network addresses of the live site are answered
// from local files, so the real production URLs are what is tested:
//   flutter build web --release --base-href /app/ --dart-define=BRANDHOOP_DEMO=false
//   node tools/models3d/screenshot_product.cjs <product-id> <out-dir>
const { chromium } = require('playwright');
const http = require('http'); const fs = require('fs'); const path = require('path');
const ROOT = path.resolve(__dirname, '../..');
const id = process.argv[2] || 'vivo-v80-5g'; const out = process.argv[3] || '/tmp/shots';
fs.mkdirSync(out, { recursive: true });
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.webp': 'image/webp', '.jpg': 'image/jpeg', '.png': 'image/png', '.glb': 'model/gltf-binary', '.otf': 'font/otf', '.ttf': 'font/ttf', '.css': 'text/css', '.svg': 'image/svg+xml' };
const serve = (dir) => http.createServer((q, r) => {
  let p = decodeURIComponent(q.url.split('?')[0]); if (p.endsWith('/')) p += 'index.html';
  const f = path.join(dir, p); if (!f.startsWith(dir) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { r.writeHead(404); return r.end(); }
  r.writeHead(200, { 'content-type': MIME[path.extname(f)] || 'application/octet-stream', 'access-control-allow-origin': '*' }); fs.createReadStream(f).pipe(r);
});
(async () => {
  const appSrv = serve('/tmp/site_local'); await new Promise((r) => appSrv.listen(8766, r));
  const NOWEBGL = !!process.env.NOWEBGL;   // NOWEBGL=1: a browser without WebGL, to check the fallback to photos
  const b = await chromium.launch({ args: NOWEBGL ? ['--disable-3d-apis', '--disable-gpu', '--disable-webgl'] : ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await b.newContext({ viewport: { width: 375, height: 812 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true });
  const p = await ctx.newPage();
  const SITE = 'https://pallavsharmaofficial.github.io/brandhoop/'; const RAW = 'https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/main/';
  const local = (base, root) => async (route) => {
    const rel = route.request().url().slice(base.length).split('?')[0]; const f = path.join(root, rel);
    if (rel && fs.existsSync(f) && fs.statSync(f).isFile()) return route.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', headers: { 'access-control-allow-origin': '*' }, body: fs.readFileSync(f) });
    return route.fulfill({ status: 404, body: '' });
  };
  const shopJson = (r) => r.fulfill({ status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*' }, body: fs.readFileSync(path.join(ROOT, 'assets/live/shop.json')) });
  await ctx.route(/\/(assets\/)?live\/shop\.json/, shopJson);   // the app adds ?t=<minute>, so match by pattern
  await ctx.route(/raw\.githubusercontent\.com\/pallavsharmaofficial\/brandhoop\/main\/site\//, local(RAW + 'site/', path.join(ROOT, 'site')));
  await ctx.route(/pallavsharmaofficial\.github\.io\/brandhoop\/(viewer3d\.html|vendor\/|models\/)/, local(SITE, path.join(ROOT, 'site')));
  const requested = []; p.on('request', (r) => { if (/\.glb|model-viewer|viewer3d/.test(r.url())) requested.push(r.url()); });
  p.on('console', (m) => { if (m.type() === 'error') console.log('console error:', m.text().slice(0, 160)); });
  if (process.env.DEBUG_MSG) await p.addInitScript(() => window.addEventListener('message', (e) => console.log('MSG', typeof e.data === 'string' ? e.data.slice(0, 80) : JSON.stringify(e.data).slice(0, 80), e.origin)));
  p.on('console', (m) => { if (m.text().startsWith('MSG')) console.log(m.text()); });
  const lang = process.env.LANG_HI ? 'hi' : 'en';
  await p.addInitScript((l) => { try { localStorage.setItem('flutter.bh.onboarded', 'true'); localStorage.setItem('flutter.bh.lang', JSON.stringify(l)); } catch (e) {} }, lang);
  await p.goto(`http://localhost:8766/app/#/product/${id}`);
  await p.waitForTimeout(6000);
  await p.evaluate(() => { const s = document.querySelector('flt-semantics-placeholder'); if (s) s.click(); });
  await p.waitForTimeout(1500);
  await p.screenshot({ path: `${out}/1-photos-tab.png` });
  if (process.env.DEBUG_TREE) console.log(await p.evaluate(() => [...document.querySelectorAll('flt-semantics')].map((e) => (e.getAttribute('role') || '') + ':' + (e.getAttribute('aria-label') || e.textContent || '').slice(0, 50)).join('\n')));
  const tab = p.getByRole('button', { name: /3D (View|व्यू)/ }).first();
  await tab.click({ timeout: 15000 }); await p.waitForTimeout(1500);
  await p.screenshot({ path: `${out}/2-poster-play.png` });
  // nothing from the 3D file may have been requested yet
  console.log('3D requests before play:', requested.length ? requested.join(', ') : 'none');
  requested.length = 0;
  await p.getByRole('button', { name: /Play 3D view|3D व्यू चलाएँ/ }).first().click({ timeout: 15000 });
  await p.waitForTimeout(500); await p.screenshot({ path: `${out}/3-loading.png` });
  if (NOWEBGL) {
    await p.waitForTimeout(6000); await p.screenshot({ path: `${out}/7-no-webgl-fallback-to-photos.png` });
    console.log('3D tab still offered after failure:', await p.getByRole('button', { name: /3D View/ }).count());
    console.log('fallback message shown:', await p.getByText(/3D view is not available/).count());
    await b.close(); appSrv.close(); return;
  }
  let frame; for (let i = 0; i < 60 && !frame; i++) { frame = p.frames().find((f) => f.url().includes('viewer3d.html')); if (!frame) await p.waitForTimeout(500); }
  if (!frame) { console.log('frames:', p.frames().map((f) => f.url()).join(' | ')); throw new Error('viewer iframe never appeared'); }
  await frame.waitForFunction(() => document.getElementById('mv') && document.getElementById('mv').loaded, null, { timeout: 60000 });
  await p.waitForTimeout(2500); await p.screenshot({ path: `${out}/4-3d-inline.png` });
  console.log('requests after play:', requested.map((u) => u.split('?')[0].split('/').pop()).join(', '));
  const cdp = await ctx.newCDPSession(p);
  const touchDrag = async (x1, y1, x2, y2, steps = 12) => {
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: x1, y: y1 }] });
    for (let i = 1; i <= steps; i++) { await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: x1 + (x2 - x1) * i / steps, y: y1 + (y2 - y1) * i / steps }] }); await p.waitForTimeout(16); }
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] }); await p.waitForTimeout(400);
  };
  const theta = () => frame.evaluate(() => { const m = document.getElementById('mv'); return Math.round(m.getCameraOrbit().theta * 180 / Math.PI); });
  await touchDrag(187, 250, 187, 120); // upwards on the viewer: the page moves
  await p.screenshot({ path: `${out}/5-after-vertical-drag.png` });
  const t1 = await theta(); await touchDrag(100, 150, 300, 150); const t2 = await theta();
  console.log('spin stopped by the first touch:', await frame.evaluate(() => !document.getElementById('mv').hasAttribute('auto-rotate')));
  console.log('camera theta before/after a sideways drag (degrees):', t1, t2);
  await p.screenshot({ path: `${out}/6-after-sideways-drag.png` });
  await touchDrag(187, 700, 187, 760); // back to the top to reach the viewer again
  await touchDrag(187, 300, 187, 560);
  await frame.click('#fsb'); await p.waitForTimeout(2500);
  const full = p.frames().filter((f) => f.url().includes('mode=full'))[0];
  console.log('fullscreen viewer frame opened:', !!full);
  if (full) { await full.waitForFunction(() => document.getElementById('mv') && document.getElementById('mv').loaded, null, { timeout: 60000 }); console.log('fullscreen touch-action:', await full.evaluate(() => document.getElementById('mv').getAttribute('touch-action')), '| ar attr present:', await full.evaluate(() => document.getElementById('mv').hasAttribute('ar'))); await p.waitForTimeout(1500); await p.screenshot({ path: `${out}/8-fullscreen.png` }); }
  await b.close(); appSrv.close(); console.log('done', out);
})().catch((e) => { console.error(e); process.exit(1); });
