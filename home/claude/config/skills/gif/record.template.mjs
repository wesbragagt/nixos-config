// Demo recording template — adapt URLs, selectors, and beats per app.
// Run from a throwaway dir with playwright-core installed:
//   mkdir -p /tmp/gif-demo && cd /tmp/gif-demo && npm init -y && npm i playwright-core
//   node record.mjs
import { chromium } from 'playwright-core';
import fs from 'node:fs';
import { execSync } from 'node:child_process';

const URL = 'http://localhost:3000/'; // ADAPT
const OUT_DIR = '/tmp/gif-demo/video';

// If the demo edits files on disk, snapshot originals here and restore in finally.
// const DOC = '/path/to/file.md';
// const original = fs.readFileSync(DOC, 'utf8');

// Narration overlay — self-explanatory GIFs need captions.
// NEVER call while a navigation is in flight (context gets destroyed).
async function caption(page, text) {
  await page.evaluate((t) => {
    let el = document.getElementById('demo-caption');
    if (!el) {
      el = document.createElement('div');
      el.id = 'demo-caption';
      Object.assign(el.style, {
        position: 'fixed', bottom: '24px', left: '50%',
        transform: 'translateX(-50%)', zIndex: 99999,
        background: 'rgba(17, 24, 39, 0.92)', color: '#fff',
        padding: '12px 22px', borderRadius: '10px',
        font: '600 17px/1.4 system-ui, sans-serif',
        boxShadow: '0 4px 24px rgba(0,0,0,.35)', maxWidth: '80%',
        textAlign: 'center',
      });
      document.body.appendChild(el);
    }
    el.textContent = t;
  }, text);
}

const browser = await chromium.launch({
  // Playwright's downloaded browsers don't run on NixOS — use the system one.
  executablePath: execSync('which chromium').toString().trim(),
  headless: true,
});
const context = await browser.newContext({
  viewport: { width: 1280, height: 720 },
  deviceScaleFactor: 2,   // crisper text in the recording
  colorScheme: 'dark',    // light mode reads harsh in READMEs
  recordVideo: { dir: OUT_DIR, size: { width: 1280, height: 720 } },
});
const page = await context.newPage();

try {
  // Beat 1: establish the starting state
  await page.goto(URL, { waitUntil: 'networkidle' });
  await caption(page, 'ADAPT: what the viewer is looking at');
  await page.waitForTimeout(2500);

  // Beat 2: announce, then act (edit a file, click, type…)
  await caption(page, 'ADAPT: what is about to happen');
  await page.waitForTimeout(1800);
  // fs.writeFileSync(DOC, modified);            // e.g. on-disk edit
  // await page.locator('#input').pressSequentially('query', { delay: 180 });
  // NOTE: lists/palettes often auto-select the first result — Enter without
  // ArrowDown. Verify selection behavior with a trial run.

  // Beat 3: show the result
  await page.reload({ waitUntil: 'networkidle' });
  // After a keypress that navigates, wait BEFORE the next caption:
  // await page.waitForURL(/expected-path/, { waitUntil: 'networkidle' });
  await caption(page, 'ADAPT: the payoff');
  await page.waitForTimeout(3500);
} finally {
  // fs.writeFileSync(DOC, original);            // restore any edited state
  await context.close(); // flushes the video
  await browser.close();
}

const video = fs.readdirSync(OUT_DIR)[0];
console.log('VIDEO:', OUT_DIR + '/' + video);
