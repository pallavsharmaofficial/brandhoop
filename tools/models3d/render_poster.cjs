// Renders site/models/<id>.webp, the poster shown before the 3D model is loaded:
//   node tools/models3d/render_poster.cjs <product-id> [base-url]
// It opens the real viewer page on a local static server (python3 -m http.server in site/).
const { chromium } = require('playwright');
const path = require('path'); const fs = require('fs');
const sharp = (() => { try { return require('sharp'); } catch { return require(path.join(__dirname, 'node_modules/sharp')); } })();
const id = process.argv[2]; const base = process.argv[3] || 'http://localhost:8765';
(async () => {
  const b = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const p = await b.newPage({ viewport: { width: 800, height: 800 }, deviceScaleFactor: 1 });
  await p.goto(`${base}/viewer3d.html?src=models/${id}.glb&mode=inline`);
  await p.waitForFunction(() => document.getElementById('mv') && document.getElementById('mv').loaded, null, { timeout: 60000 });
  await p.evaluate(() => { const m = document.getElementById('mv'); m.removeAttribute('auto-rotate'); m.cameraOrbit = '155deg 78deg auto'; m.jumpCameraToGoal(); document.getElementById('fsb').style.display = 'none'; document.getElementById('bar').style.display = 'none'; });
  await p.waitForTimeout(1500);
  const png = await p.screenshot();
  await sharp(png).resize(640, 640).webp({ quality: 80 }).toFile(path.join(__dirname, '../../site/models', id + '.webp'));
  await b.close(); console.log('poster', id);
})().catch(e => { console.error(e); process.exit(1); });
