const fs = require('fs');
const path = require('path');

const assetsDir = path.join(__dirname, 'src', 'assets');

const targets = [
  {
    png: 'Layanan Visa & Airport Tax.png',
    svgs: ['icon-layanan-visa-airport-tax.svg', 'Layanan Visa & Airport Tax.svg', 'icon-visa-tax.svg']
  },
  {
    png: 'Travel Insurance.png',
    svgs: ['icon-travel-insurance.svg', 'Travel Insurance.svg']
  },
  {
    png: 'Optional Tour & Wisata Tambahan.png',
    svgs: ['icon-optional-tour-wisata-tambahan.svg', 'Optional Tour & Wisata Tambahan.svg', 'icon-optional-tour.svg']
  }
];

targets.forEach(t => {
  const pngPath = path.join(assetsDir, t.png);
  if (fs.existsSync(pngPath)) {
    const buf = fs.readFileSync(pngPath);
    const base64 = buf.toString('base64');
    const svgContent = `<?xml version="1.0" encoding="UTF-8"?>
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1254" height="1254" viewBox="0 0 1254 1254">
  <image width="1254" height="1254" xlink:href="data:image/png;base64,${base64}"/>
</svg>`;
    
    t.svgs.forEach(svgName => {
      const outPath = path.join(assetsDir, svgName);
      fs.writeFileSync(outPath, svgContent);
      console.log('Successfully created:', svgName);
    });
  } else {
    console.error('PNG not found:', t.png);
  }
});
