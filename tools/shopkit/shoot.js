// node tools/shopkit/shoot.js : tools/shopkit/build/*.html -> site/shop-kit/*.pdf (A4) and the plan PNG
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const src = path.resolve(__dirname, 'build');
const out = path.resolve(__dirname, '../../site/shop-kit');
fs.mkdirSync(out, { recursive: true });
(async () => {
  const b = await chromium.launch({ args: ['--no-sandbox'] });
  for (const f of fs.readdirSync(src).filter((n) => n.endsWith('.html'))) {
    const name = f.replace('.html', ''); const name_ = name;
    const ctx = await b.newContext({ viewport: { width: 1240, height: name_ === 'floor-plan' ? 700 : 1754 }, deviceScaleFactor: 1 });
    const p = await ctx.newPage();
    await p.goto('file://' + path.join(src, f));
    await p.waitForTimeout(500);
    if (name === 'floor-plan') {
      await p.screenshot({ path: path.join(out, name + '.png'), fullPage: true });
    }
    await p.pdf({ path: path.join(out, name + '.pdf'), format: 'A4', printBackground: true, preferCSSPageSize: true });
    await ctx.close();
    console.log('made', name);
  }
  await b.close();
})();
