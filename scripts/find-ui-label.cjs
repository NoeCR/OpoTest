const fs = require('fs');
const label = (process.argv[2] || '').toLowerCase();
const file = process.argv[3];
const x = fs.readFileSync(file, 'utf8').replace(/&amp;/g, '&');

function center(bounds) {
  const m = bounds.match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/);
  if (!m) return null;
  return `${Math.round((+m[1] + +m[3]) / 2)},${Math.round((+m[2] + +m[4]) / 2)}`;
}

// Prefer clickable nodes whose text or content-desc matches.
for (const hit of x.matchAll(/<node ([^>]*clickable="true"[^>]*)>/g)) {
  const attrs = hit[1];
  const textM = attrs.match(/text="([^"]*)"/);
  const descM = attrs.match(/content-desc="([^"]*)"/);
  const boundsM = attrs.match(/bounds="(\[[^\]]+\]\[[^\]]+\])"/);
  const text = (textM?.[1] || descM?.[1] || '').replace(/&amp;/g, '&');
  if (!text.toLowerCase().includes(label) || !boundsM) continue;
  const c = center(boundsM[1]);
  if (c) {
    console.log(c);
    process.exit(0);
  }
}

// Fallback: any text match.
for (const hit of x.matchAll(/text="([^"]*)"[^>]*bounds="(\[[^\]]+\]\[[^\]]+\])"/g)) {
  const text = hit[1].replace(/&amp;/g, '&');
  if (!text.toLowerCase().includes(label)) continue;
  const c = center(hit[2]);
  if (c) {
    console.log(c);
    process.exit(0);
  }
}
process.exit(1);
