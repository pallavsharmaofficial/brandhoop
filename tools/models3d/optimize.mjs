// Optimises one downloaded phone model for the storefront and renders nothing:
//   node tools/models3d/optimize.mjs <product-id>
// raw/<id>.glb -> site/models/<id>.glb  (dedup, prune, weld, centre, WebP textures
// at most 1024 px, Draco) and fails if the result is over 3 MB.
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { dedup, prune, weld, center, textureCompress, draco, flatten, join, resample } from '@gltf-transform/functions';
import draco3d from 'draco3dgltf';
import sharp from 'sharp';
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../..');
const id = process.argv[2];
if (!id) { console.error('usage: optimize.mjs <product-id>'); process.exit(2); }
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'draco3d.decoder': await draco3d.createDecoderModule(),
  'draco3d.encoder': await draco3d.createEncoderModule(),
});
const doc = await io.read(path.join(here, 'raw', id + '.glb'));
await doc.transform(
  dedup(), flatten(), join(), prune(), weld({ tolerance: 0.0001 }), resample(), center({ pivot: 'center' }),
  textureCompress({ encoder: sharp, targetFormat: 'webp', resize: [1024, 1024], quality: 82 }),
  draco({ quantizePosition: 14, quantizeNormal: 10, quantizeTexcoord: 12 }),
);
fs.mkdirSync(path.join(root, 'site/models'), { recursive: true });
const out = path.join(root, 'site/models', id + '.glb');
await io.write(out, doc);
const kb = Math.round(fs.statSync(out).size / 1024);
console.log(JSON.stringify({ id, sizeKb: kb }));
if (kb > 3072) { console.error('over 3 MB'); process.exit(1); }
