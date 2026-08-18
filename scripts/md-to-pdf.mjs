#!/usr/bin/env node
// Renders reference/*.md into printable PDFs at reference/*.pdf using marked + playwright-chromium.
import { readdir, readFile } from 'node:fs/promises';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { marked } from 'marked';
import { chromium } from 'playwright-chromium';

const __dirname = dirname(fileURLToPath(import.meta.url));
const referenceDir = join(__dirname, '..', 'reference');

const files = process.argv.slice(2).length
  ? process.argv.slice(2)
  : (await readdir(referenceDir)).filter((f) => f.endsWith('.md') && f !== 'README.md');

const template = (title, body) => `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>${title}</title>
<style>
  body { font-family: -apple-system, Helvetica, Arial, sans-serif; color: #1a1a1a; padding: 2rem 3rem; line-height: 1.5; }
  h1 { border-bottom: 3px solid #326ce5; padding-bottom: 0.3rem; }
  h2 { color: #326ce5; margin-top: 1.8rem; border-bottom: 1px solid #ddd; padding-bottom: 0.2rem; }
  pre { background: #f5f5f5; border-radius: 6px; padding: 0.8rem 1rem; overflow-x: auto; font-size: 0.8rem; white-space: pre-wrap; word-break: break-word; }
  code { font-family: "SF Mono", Menlo, Consolas, monospace; }
  table { border-collapse: collapse; width: 100%; margin: 0.8rem 0; }
  th, td { border: 1px solid #ddd; padding: 0.4rem 0.7rem; text-align: left; font-size: 0.9rem; }
  th { background: #f0f4fc; }
  blockquote { color: #555; border-left: 3px solid #ccc; margin: 0.8rem 0; padding: 0.2rem 1rem; font-size: 0.9rem; }
  a { color: #326ce5; }
</style>
</head>
<body>${body}</body>
</html>`;

const browser = await chromium.launch();
for (const file of files) {
  const mdPath = join(referenceDir, file);
  const md = await readFile(mdPath, 'utf-8');
  const html = template(basename(file, '.md'), marked.parse(md));
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'networkidle' });
  const pdfPath = join(referenceDir, basename(file, '.md') + '.pdf');
  await page.pdf({ path: pdfPath, format: 'Letter', margin: { top: '0.5in', bottom: '0.5in', left: '0.5in', right: '0.5in' }, printBackground: true });
  await page.close();
  console.log(`✓ exported to reference/${basename(pdfPath)}`);
}
await browser.close();
