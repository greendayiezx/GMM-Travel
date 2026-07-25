#!/usr/bin/env node
/**
 * extract-packages.js
 * -------------------
 * Ekstrak katalog PACKAGES dari frontend (destination-detail.component.ts)
 * menjadi database/data/packages.json — sumber data untuk PackageCatalogSeeder.
 *
 * Jalankan setiap kali harga paket di frontend berubah:
 *   node scripts/extract-packages.js
 *   php artisan db:seed --class=PackageCatalogSeeder --force
 *
 * Catatan: script ini mengasumsikan repo frontend berada di
 *   <parent>/kliktrip-premium relatif terhadap repo backend ini.
 *   Override dengan env FRONTEND_PATH bila lokasinya berbeda.
 */
const fs = require('fs');
const path = require('path');

const FRONTEND_SRC = process.env.FRONTEND_PATH || path.resolve(
  __dirname, '..', '..', 'kliktrip-premium',
  'src/app/components/destination-detail/destination-detail.component.ts'
);
const OUT = path.resolve(__dirname, '..', 'database', 'data', 'packages.json');

if (!fs.existsSync(FRONTEND_SRC)) {
  console.error('❌ File frontend tidak ditemukan:', FRONTEND_SRC);
  console.error('   Set env FRONTEND_PATH ke lokasi destination-detail.component.ts');
  process.exit(1);
}

const code = fs.readFileSync(FRONTEND_SRC, 'utf8');

const marker = 'const PACKAGES: Record<string, DestinationPackage> = {';
const start = code.indexOf(marker);
if (start === -1) { console.error('❌ Konstanta PACKAGES tidak ditemukan'); process.exit(1); }

// Cocokkan kurung kurawal berimbang (abaikan kurung di dalam string)
let i = code.indexOf('{', start);
let depth = 0, end = -1, inStr = false, strCh = '', prev = '';
for (let p = i; p < code.length; p++) {
  const ch = code[p];
  if (inStr) {
    if (ch === strCh && prev !== '\\') inStr = false;
  } else {
    if (ch === '"' || ch === "'" || ch === '`') { inStr = true; strCh = ch; }
    else if (ch === '{') depth++;
    else if (ch === '}') { depth--; if (depth === 0) { end = p; break; } }
  }
  prev = ch;
}
if (end === -1) { console.error('❌ Kurung tidak berimbang'); process.exit(1); }

let PACKAGES;
try {
  PACKAGES = eval('(' + code.slice(i, end + 1) + ')');
} catch (e) {
  console.error('❌ Gagal parse PACKAGES:', e.message);
  process.exit(1);
}

// Replika parseFirstPrice dari frontend
function parseFirstPrice(str) {
  const match = (str || '').match(/\d[\d.,]*/);
  if (!match) return 0;
  return parseInt(match[0].replace(/[^0-9]/g, ''), 10) || 0;
}

const out = [];
for (const [name, pkg] of Object.entries(PACKAGES)) {
  let priceCategories = null;
  if (Array.isArray(pkg.priceCategories) && pkg.priceCategories.length > 0 && pkg.priceCategories[0].prices) {
    priceCategories = pkg.priceCategories[0].prices.map(cp => ({
      type: cp.type,
      price: parseFirstPrice(cp.price),
    }));
  }
  out.push({
    name,
    base_price: parseFirstPrice(pkg.price) || 0,
    price_categories: priceCategories,
    single_supplement: pkg.harga_single_supplement || null,
    duration: pkg.duration || null,
    max_pax: pkg.maxPax || null,
  });
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(out, null, 2), 'utf8');
console.log(`✓ ${out.length} paket diekspor ke ${path.relative(process.cwd(), OUT)}`);
