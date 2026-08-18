/**
 * Exporta el temario completo de Testea desde la API pública.
 * Uso: node scripts/export-temario.js [--resume] [--concurrency=8]
 */
const fs = require('fs');
const path = require('path');

const BASE_URL = 'https://glados-cakeserver.com/';
const DATA_DIR = path.join(__dirname, '..', 'data');
const TESTS_DIR = path.join(DATA_DIR, 'tests');
const MANIFEST_PATH = path.join(DATA_DIR, 'manifest.json');
const PROGRESS_PATH = path.join(DATA_DIR, '.export-progress.json');

const args = process.argv.slice(2);
const resume = args.includes('--resume');
const concurrency = Number(
  (args.find((a) => a.startsWith('--concurrency=')) || '--concurrency=8').split('=')[1]
);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fetchJson(endpoint, retries = 3) {
  const url = endpoint.startsWith('http') ? endpoint : `${BASE_URL}${endpoint.replace(/^\//, '')}`;
  for (let i = 0; i < retries; i++) {
    try {
      const res = await fetch(url, { headers: { Accept: 'application/json' } });
      if (!res.ok) throw new Error(`HTTP ${res.status} ${url}`);
      const data = await res.json();
      if (data.error === 1 || data.error === '1') {
        throw new Error(`API error ${data.errortype || 'unknown'} @ ${url}`);
      }
      return data;
    } catch (err) {
      if (i === retries - 1) throw err;
      await sleep(500 * (i + 1));
    }
  }
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeJson(filePath, data) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
}

function collectTestIdsFromQMap(qMap, bucket = new Set()) {
  if (!qMap || typeof qMap !== 'object') return bucket;
  for (const entry of Object.values(qMap)) {
    if (!entry) continue;
    if (Array.isArray(entry.mainLevel)) {
      entry.mainLevel.forEach((id) => bucket.add(String(id)));
    } else if (entry.mainLevel && typeof entry.mainLevel === 'object') {
      for (const arr of Object.values(entry.mainLevel)) {
        if (Array.isArray(arr)) arr.forEach((id) => bucket.add(String(id)));
      }
    }
    if (Array.isArray(entry.subLevel)) {
      entry.subLevel.forEach((id) => bucket.add(String(id)));
    }
  }
  return bucket;
}

function collectFromLawLevel(qByLawNew, lawId, bucket) {
  const node = qByLawNew?.[lawId] ?? qByLawNew?.[String(lawId)];
  if (!node) return;
  if (node.mainLevel && typeof node.mainLevel === 'object' && !Array.isArray(node.mainLevel)) {
    for (const arr of Object.values(node.mainLevel)) {
      if (Array.isArray(arr)) arr.forEach((id) => bucket.add(String(id)));
    }
  }
  if (Array.isArray(node.subLevel)) {
    node.subLevel.forEach((id) => bucket.add(String(id)));
  }
}

async function mapPool(items, limit, fn) {
  const results = [];
  let index = 0;
  async function worker() {
    while (index < items.length) {
      const i = index++;
      results[i] = await fn(items[i], i);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return results;
}

async function exportHierarchy() {
  ensureDir(DATA_DIR);
  ensureDir(TESTS_DIR);

  console.log('Fetching global options and laws...');
  const [options, lawsPayload] = await Promise.all([
    fetchJson('api/testea/get-options/'),
    fetchJson('api/testea/get-laws'),
  ]);

  writeJson(path.join(DATA_DIR, 'options.json'), options);

  const laws = lawsPayload.arLaws || [];
  const qByLawNew = lawsPayload.qByLawNew || {};
  writeJson(path.join(DATA_DIR, 'laws-index.json'), { laws, qByLawNew });

  const testIds = new Set();
  collectTestIdsFromQMap(qByLawNew, testIds);

  const hierarchy = { laws: [], exportedAt: new Date().toISOString() };

  for (const law of laws) {
    console.log(`Law: ${law.code} (${law.id})`);
    const lawData = await fetchJson(`api/testea/get-law/idlaw/${law.id}`);
    collectFromLawLevel(lawData.qByLawNew ?? qByLawNew, law.id, testIds);
    collectTestIdsFromQMap(lawData.qByTitle, testIds);
    collectTestIdsFromQMap(lawData.qByArticle, testIds);

    const lawNode = {
      ...law,
      titles: [],
      articles: lawData.arArticles || [],
      qByLawNew: lawData.qByLawNew,
      qByTitle: lawData.qByTitle,
    };

    writeJson(path.join(DATA_DIR, 'laws', law.id, 'law.json'), lawData);

    for (const title of lawData.arTitles || []) {
      const titleData = await fetchJson(`api/testea/get-title/idtitle/${title.id}`);
      collectTestIdsFromQMap(titleData.qByTitle, testIds);
      collectTestIdsFromQMap(titleData.qByChapter, testIds);
      collectTestIdsFromQMap(titleData.qByArticle, testIds);

      const titleNode = {
        ...title,
        chapters: [],
        articles: titleData.arArticles || [],
        qByTitle: titleData.qByTitle,
        qByChapter: titleData.qByChapter,
        qByArticle: titleData.qByArticle,
      };

      writeJson(path.join(DATA_DIR, 'laws', law.id, 'titles', `${title.id}.json`), titleData);

      for (const chapter of titleData.arChapters || []) {
        const chapterData = await fetchJson(`api/testea/get-chapter/idchapter/${chapter.id}`);
        collectTestIdsFromQMap(chapterData.qByChapter, testIds);
        collectTestIdsFromQMap(chapterData.qBySection, testIds);
        collectTestIdsFromQMap(chapterData.qByArticle, testIds);

        titleNode.chapters.push({
          ...chapter,
          sections: chapterData.arSections || [],
          articles: chapterData.arArticles || [],
          qByChapter: chapterData.qByChapter,
          qBySection: chapterData.qBySection,
          qByArticle: chapterData.qByArticle,
        });

        writeJson(
          path.join(DATA_DIR, 'laws', law.id, 'titles', title.id, 'chapters', `${chapter.id}.json`),
          chapterData
        );

        for (const section of chapterData.arSections || []) {
          try {
            const sectionData = await fetchJson(`api/testea/get-section/idsection/${section.id}`);
            collectTestIdsFromQMap(sectionData.qBySection, testIds);
            collectTestIdsFromQMap(sectionData.qByArticle, testIds);
            writeJson(
              path.join(
                DATA_DIR,
                'laws',
                law.id,
                'titles',
                title.id,
                'chapters',
                chapter.id,
                'sections',
                `${section.id}.json`
              ),
              sectionData
            );
          } catch (e) {
            console.warn(`  Section ${section.id} skipped: ${e.message}`);
          }
        }

        for (const article of chapterData.arArticles || []) {
          try {
            const articleData = await fetchJson(`api/testea/get-article/idarticle/${article.id}`);
            collectTestIdsFromQMap(articleData.qByArticle, testIds);
            writeJson(
              path.join(
                DATA_DIR,
                'laws',
                law.id,
                'titles',
                title.id,
                'chapters',
                chapter.id,
                'articles',
                `${article.id}.json`
              ),
              articleData
            );
          } catch (e) {
            console.warn(`  Article ${article.id} skipped: ${e.message}`);
          }
        }

        await sleep(50);
      }

      for (const article of titleData.arArticles || []) {
        if (titleNode.chapters.some((c) => (c.articles || []).some((a) => a.id === article.id))) continue;
        try {
          const articleData = await fetchJson(`api/testea/get-article/idarticle/${article.id}`);
          collectTestIdsFromQMap(articleData.qByArticle, testIds);
          writeJson(
            path.join(DATA_DIR, 'laws', law.id, 'titles', title.id, 'articles', `${article.id}.json`),
            articleData
          );
        } catch (e) {
          console.warn(`  Title-article ${article.id} skipped: ${e.message}`);
        }
      }

      lawNode.titles.push(titleNode);
      await sleep(50);
    }

    hierarchy.laws.push(lawNode);
  }

  writeJson(path.join(DATA_DIR, 'hierarchy.json'), hierarchy);

  const ids = [...testIds].sort((a, b) => Number(a) - Number(b));
  writeJson(path.join(DATA_DIR, 'test-ids.json'), { count: ids.length, ids });
  return ids;
}

async function exportTests(ids) {
  let progress = { done: [], failed: [] };
  if (resume && fs.existsSync(PROGRESS_PATH)) {
    progress = JSON.parse(fs.readFileSync(PROGRESS_PATH, 'utf8'));
  }

  const pending = ids.filter(
    (id) => !progress.done.includes(id) && !fs.existsSync(path.join(TESTS_DIR, `${id}.json`))
  );

  console.log(`Exporting ${pending.length}/${ids.length} tests (concurrency ${concurrency})...`);

  let completed = progress.done.length;
  await mapPool(pending, concurrency, async (id) => {
    try {
      const data = await fetchJson(`api/testea/get-test/id/${id}`);
      writeJson(path.join(TESTS_DIR, `${id}.json`), data);
      progress.done.push(id);
      completed++;
      if (completed % 25 === 0) {
        console.log(`  Tests: ${completed}/${ids.length}`);
        writeJson(PROGRESS_PATH, progress);
      }
    } catch (err) {
      progress.failed.push({ id, error: err.message });
      console.warn(`  Test ${id} failed: ${err.message}`);
    }
  });

  writeJson(PROGRESS_PATH, progress);
  return progress;
}

async function buildManifest(ids, progress) {
  let questionInstances = 0;
  const bankQuestionIds = new Set();
  for (const id of progress.done) {
    try {
      const t = JSON.parse(fs.readFileSync(path.join(TESTS_DIR, `${id}.json`), 'utf8'));
      const qs = t?.test?.q?.['1'] || t?.test?.q?.[1] || [];
      questionInstances += qs.length;
      for (const item of qs) {
        if (item?.q?.id) bankQuestionIds.add(String(item.q.id));
      }
    } catch (_) {}
  }

  const manifest = {
    source: BASE_URL,
    exportedAt: new Date().toISOString(),
    schemaVersion: 1,
    stats: {
      laws: JSON.parse(fs.readFileSync(path.join(DATA_DIR, 'laws-index.json'), 'utf8')).laws.length,
      testIds: ids.length,
      testsExported: progress.done.length,
      testsFailed: progress.failed.length,
      questionInstances,
      uniqueQuestions: bankQuestionIds.size,
    },
    sync: {
      recommendedIntervalDays: 7,
      lastExport: new Date().toISOString(),
    },
  };
  writeJson(MANIFEST_PATH, manifest);
  console.log('\nManifest:', manifest.stats);
}

async function main() {
  console.log('=== Testea temario export ===\n');
  const ids = await exportHierarchy();
  const progress = await exportTests(ids);
  await buildManifest(ids, progress);
  console.log('\nDone. Data in:', DATA_DIR);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
