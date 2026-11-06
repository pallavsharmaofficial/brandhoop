// node tools/poster/shoot.js : html -> png (and A4 pdf), using whatever Playwright is installed.
const { chromium } = require('playwright');
const path = require('path');
const dir = path.resolve(__dirname, '../../site/qr');
(async () => {
  const b = await chromium.launch({ args: ['--no-sandbox'] });
  const jobs = [['diwali-poster', 1080, 1920, 1], ['diwali-poster-a4', 1240, 1754, 2], ['brandhoop-qr', 1200, 1200, 1]];
  for (const [name, w, h, dsf] of jobs) {
    const ctx = await b.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: dsf });
    const p = await ctx.newPage();
    await p.goto('file://' + path.join(dir, name + '.html'));
    await p.waitForTimeout(700);
    await p.screenshot({ path: path.join(dir, name + '.png') });
    await ctx.close();
  }
  await b.close();
})();
