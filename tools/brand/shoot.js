// node tools/brand/shoot.js : renders tools/brand/build/manifest.json into PNG and PDF files
const { chromium } = require('playwright'); const fs = require('fs'); const path = require('path');
const root = path.resolve(__dirname, '../..'); const build = path.join(__dirname, 'build');
(async () => {
  const m = JSON.parse(fs.readFileSync(path.join(build, 'manifest.json'), 'utf8'));
  const b = await chromium.launch({ args: ['--no-sandbox', '--allow-file-access-from-files'] });
  for (const e of m) {
    const px = (v) => (e.unit === 'mm' ? Math.round(v / 25.4 * 96) : v);
    const ctx = await b.newContext({ viewport: { width: px(e.w), height: px(e.h) }, deviceScaleFactor: e.dsf || 1 });
    const p = await ctx.newPage(); await p.goto('file://' + path.join(build, e.html)); await p.waitForTimeout(450);
    await p.evaluate(() => document.fonts.ready);
    if (e.png) { const out = path.join(root, e.png); fs.mkdirSync(path.dirname(out), { recursive: true }); await p.screenshot({ path: out, omitBackground: true }); }
    if (e.pdf) { const out = path.join(root, e.pdf); fs.mkdirSync(path.dirname(out), { recursive: true });
      await p.pdf({ path: out, width: e.w + e.unit, height: e.h + e.unit, printBackground: true, pageRanges: '1' }); }
    await ctx.close(); console.log('made', e.html);
  }
  await b.close();
})();
