// node tools/poster/shoot.js : html -> png, using whatever Playwright is installed.
const { chromium } = require('playwright');
const path = require('path');
const dir = path.resolve(__dirname, '../../site/qr');
(async () => {
  const b = await chromium.launch({ args: ['--no-sandbox'] });
  for (const [name, w, h] of [['diwali-poster', 1080, 1920], ['brandhoop-qr', 1200, 1200]]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto('file://' + path.join(dir, name + '.html'));
    await p.waitForTimeout(500);
    await p.screenshot({ path: path.join(dir, name + '.png') });
    await p.close();
  }
  await b.close();
})();
