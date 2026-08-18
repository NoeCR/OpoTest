const fs = require('fs');
const file = process.argv[2];
const xml = fs.readFileSync(file, 'utf8');
const re = /text="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"[^>]*clickable="true"/g;
for (const m of xml.matchAll(re)) {
  const x = Math.round((+m[2] + +m[4]) / 2);
  const y = Math.round((+m[3] + +m[5]) / 2);
  if (m[1]) console.log(`${m[1]} @ ${x},${y}`);
}
