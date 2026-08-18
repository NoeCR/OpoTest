const fs = require('fs');
const file = process.argv[2];
const x = fs.readFileSync(file, 'utf8').replace(/&amp;/g, '&');
const texts = [...x.matchAll(/text="([^"]{2,80})"/g)].map((m) => m[1]);
[...new Set(texts)].forEach((t) => console.log(t));
