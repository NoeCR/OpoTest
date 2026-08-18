const fs = require('fs');
const file = process.argv[2];
const x = fs.readFileSync(file, 'utf8');
const texts = [...x.matchAll(/text="([^"]{3,80})"/g)].map((m) => m[1]);
[...new Set(texts)]
  .filter((t) => /security|privacy|encrypt|credential|certif|lock/i.test(t))
  .forEach((t) => console.log(t));
