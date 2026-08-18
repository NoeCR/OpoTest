const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'capture', 'screens');
const files = fs
  .readdirSync(dir)
  .filter((f) => f.startsWith('ui_20260817_101') || f.startsWith('ui_20260817_102'))
  .sort();

for (const f of files) {
  const xml = fs.readFileSync(path.join(dir, f), 'utf8');
  const texts = [...xml.matchAll(/text="([^"]{2,200})"/g)]
    .map((m) => m[1].replace(/&#10;/g, ' ').trim())
    .filter(Boolean);
  const interesting = texts.filter((t) =>
    /constit|título|test|pregunt|nota|correct|incorrect|result|review|aclara|estrella|complet|iniciar|finalizar|legisl|capítulo|artículo|temario|preliminar|estructura|%/i.test(t)
  );
  if (interesting.length) {
    console.log(`\n=== ${f} ===`);
    [...new Set(interesting)].slice(0, 30).forEach((t) => console.log(' -', t));
  }
}
