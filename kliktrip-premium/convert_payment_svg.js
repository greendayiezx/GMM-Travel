const fs = require('fs');
const path = require('path');

const assetsDir = path.join(__dirname, 'src', 'assets');

const items = [
  {
    png: 'logo-destination.png',
    svgs: ['icon-destination.svg', 'logo-destination.svg'],
    w: 401,
    h: 447
  },
  {
    png: 'icon-coin.png',
    svgs: ['icon-coin.svg'],
    w: 342,
    h: 398
  }
];

items.forEach(t => {
  const pngPath = path.join(assetsDir, t.png);
  if (fs.existsSync(pngPath)) {
    const buf = fs.readFileSync(pngPath);
    const base64 = buf.toString('base64');
    const svgContent = `<?xml version="1.0" encoding="UTF-8"?>
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${t.w}" height="${t.h}" viewBox="0 0 ${t.w} ${t.h}">
  <image width="${t.w}" height="${t.h}" xlink:href="data:image/png;base64,${base64}"/>
</svg>`;
    
    t.svgs.forEach(svgName => {
      const outPath = path.join(assetsDir, svgName);
      fs.writeFileSync(outPath, svgContent);
      console.log('Created SVG:', svgName);
    });
  }
});
