// Screenshots of the built web app (build/web) or the site, with the live shop file and the shop's
// images answered from local files:
//   node tools/brand/shoot_app.cjs <url-path> <out.png> [--w=375 --h=812 --dark --full --scroll=600 --lang=hi --site]
//   url-path: "app/#/" for the app home, "index.html" with --site for the website
const { chromium } = require('playwright');
const http = require('http'); const fs = require('fs'); const path = require('path');
const ROOT = path.resolve(__dirname, '../..');
const [urlPath, out, ...flags] = process.argv.slice(2);
const opt = (k, d) => { const f = flags.find((x) => x.startsWith('--' + k + '=')); return f ? f.split('=')[1] : d; };
const has = (k) => flags.includes('--' + k);
const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.webp': 'image/webp', '.jpg': 'image/jpeg', '.png': 'image/png', '.svg': 'image/svg+xml', '.css': 'text/css', '.glb': 'model/gltf-binary', '.otf': 'font/otf', '.ttf': 'font/ttf' };
const serve = (dir, prefix) => http.createServer((q, r) => {
  let p = decodeURIComponent(q.url.split('?')[0]); if (prefix && p.startsWith(prefix)) p = p.slice(prefix.length - 1); if (p.endsWith('/')) p += 'index.html';
  let f = path.join(dir, p);
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) f = path.join(ROOT, 'build/web', p.replace(/^\/app\//, '/'));
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) { r.writeHead(404); return r.end(); }
  r.writeHead(200, { 'content-type': MIME[path.extname(f)] || 'application/octet-stream', 'access-control-allow-origin': '*' }); fs.createReadStream(f).pipe(r);
});
(async () => {
  const srv = serve(path.join(ROOT, 'site')); await new Promise((r) => srv.listen(8767, r));
  const b = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const W = +opt('w', 375), H = +opt('h', 812);
  const ctx = await b.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: +opt('dsf', 1), isMobile: W < 700, hasTouch: W < 700, colorScheme: has('dark') ? 'dark' : 'light' });
  const p = await ctx.newPage();
  const shop = fs.readFileSync(path.join(ROOT, 'assets/live/shop.json'));
  await ctx.route(/\/(assets\/)?live\/shop\.json/, (r) => r.fulfill({ status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*' }, body: shop }));
  await ctx.route(/raw\.githubusercontent\.com\/pallavsharmaofficial\/brandhoop\/main\/site\//, (r) => {
    const f = path.join(ROOT, 'site', r.request().url().split('/main/site/')[1].split('?')[0]);
    return fs.existsSync(f) ? r.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', headers: { 'access-control-allow-origin': '*' }, body: fs.readFileSync(f) }) : r.fulfill({ status: 404, body: '' });
  });
  await ctx.route(/pallavsharmaofficial\.github\.io\/brandhoop\//, (r) => {
    const rel = r.request().url().split('/brandhoop/')[1].split('?')[0] || 'index.html'; let f = path.join(ROOT, 'site', rel);
    if (rel.startsWith('app/')) f = path.join(ROOT, 'build/web', rel.slice(4));
    return fs.existsSync(f) && fs.statSync(f).isFile() ? r.fulfill({ status: 200, contentType: MIME[path.extname(f)] || 'application/octet-stream', headers: { 'access-control-allow-origin': '*' }, body: fs.readFileSync(f) }) : r.fulfill({ status: 404, body: '' });
  });
  const lang = opt('lang', 'en');
  await p.addInitScript((l) => { try { localStorage.setItem('flutter.bh.onboarded', 'true'); localStorage.setItem('flutter.bh.lang', JSON.stringify(l)); } catch (e) {} }, lang);
  const base = has('site') ? 'http://localhost:8767/' : 'http://localhost:8767/app/';
  await p.goto(base + urlPath.replace(/^app\//, ''));
  await p.waitForTimeout(+opt('wait', 6500));
  const sc = +opt('scroll', 0);
  if (sc) { await p.mouse.move(W / 2, H / 2); for (let y = 0; y < sc; y += 200) { await p.mouse.wheel(0, 200); await p.waitForTimeout(120); } await p.waitForTimeout(1200); }
  await p.screenshot({ path: out, fullPage: has('full') });
  await b.close(); srv.close(); console.log('saved', out);
})().catch((e) => { console.error(e); process.exit(1); });
