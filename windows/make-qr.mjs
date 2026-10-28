import { writeFileSync } from 'node:fs'
import { generate } from '../frontend/node_modules/lean-qr/index.mjs'
import { toPngBuffer } from '../frontend/node_modules/lean-qr/extras/node_export.mjs'

const [url, output] = process.argv.slice(2)
if (!url || !output) throw new Error('Usage: make-qr.mjs <url> <output.png>')
writeFileSync(output, toPngBuffer(generate(url), { scale: 9, pad: 4, off: [255, 255, 255] }))
