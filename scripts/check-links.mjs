#!/usr/bin/env node
/**
 * bonin-skills Dead Link Checker
 *
 * Scans all SKILL.md and reference docs for internal markdown links and
 * file references, then verifies each target exists. Reports broken links.
 *
 * Usage:
 *   node scripts/check-links.mjs              # scan + report
 *   node scripts/check-links.mjs --json       # output JSON
 *   node scripts/check-links.mjs --strict     # exit non-zero on any broken link
 *
 * Cross-platform: works on macOS, Linux, Windows.
 */

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..");

const args = new Set(process.argv.slice(2));
const JSON_OUT = args.has("--json");
const STRICT = args.has("--strict");

const SKIP_DIRS = new Set(["node_modules", ".git", "dist", "build", "out", ".auto-sync", "reports"]);
const SCAN_EXTENSIONS = new Set([".md"]);

const LINK_PATTERNS = [
  // [text](relative/path.md)
  { regex: /\[([^\]]*)\]\(([^)]+)\)/g, kind: "markdown", group: 2 },
  // [text](./relative/path.md#anchor)
  { regex: /\[([^\]]*)\]\(([^)#]+)(#[^)]*)?\)/g, kind: "markdown-anchor", group: 2 },
];

const FILE_REF_PATTERNS = [
  // `scripts/push.sh` or `references/extract.md` in backticks
  { regex: /`((?:scripts|references|prompts|assets|packages)\/[^`\s]+\.[a-z]+)`/g, kind: "backtick-ref" },
  // see references/extract.md
  { regex: /\b((?:scripts|references|prompts|assets)\/[\w\-\/]+\.\w+)/g, kind: "inline-ref" },
];

async function main() {
  const brokenLinks = [];
  const checkedLinks = [];
  const skillsRoot = path.join(REPO_ROOT, "skills");
  const rootMds = await listMarkdownFiles(REPO_ROOT, 1);
  const skillMds = await listMarkdownFiles(skillsRoot, 4);

  const allMds = [...rootMds, ...skillMds];

  for (const mdFile of allMds) {
    const links = await extractLinks(mdFile);
    for (const link of links) {
      checkedLinks.push(link);
      if (link.kind === "external" || link.kind === "anchor-only") continue;
      const target = resolveTarget(mdFile, link.target);
      if (!target) continue;
      const { exists, resolved } = await skillAwareExists(mdFile, link.target);
      if (!exists && !isTemplatePlaceholder(link.target)) {
        brokenLinks.push({
          source: path.relative(REPO_ROOT, mdFile),
          line: link.line,
          target: link.target,
          resolved: resolved ? path.relative(REPO_ROOT, resolved) : null,
          kind: link.kind,
        });
      }
    }
  }

  if (JSON_OUT) {
    console.log(JSON.stringify({
      totalChecked: checkedLinks.length,
      brokenCount: brokenLinks.length,
      broken: brokenLinks,
    }, null, 2));
  } else {
    printReport(checkedLinks.length, brokenLinks);
  }

  if (STRICT && brokenLinks.length > 0) {
    process.exit(1);
  }
}

async function listMarkdownFiles(dir, maxDepth, currentDepth = 0) {
  if (currentDepth > maxDepth) return [];
  const entries = await fs.readdir(dir, { withFileTypes: true }).catch(() => []);
  const files = [];
  for (const e of entries) {
    if (e.isDirectory()) {
      if (SKIP_DIRS.has(e.name)) continue;
      files.push(...await listMarkdownFiles(path.join(dir, e.name), maxDepth, currentDepth + 1));
    } else if (e.isFile() && SCAN_EXTENSIONS.has(path.extname(e.name))) {
      files.push(path.join(dir, e.name));
    }
  }
  return files;
}

async function extractLinks(mdFile) {
  const raw = await fs.readFile(mdFile, "utf8");
  const lines = raw.split("\n");
  const links = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    // Markdown links
    for (const { regex, kind, group } of LINK_PATTERNS) {
      regex.lastIndex = 0;
      let m;
      while ((m = regex.exec(line)) !== null) {
        const target = m[group];
        if (!target) continue;
        if (target.startsWith("http://") || target.startsWith("https://")) {
          links.push({ line: i + 1, target, kind: "external" });
        } else if (target.startsWith("#")) {
          links.push({ line: i + 1, target, kind: "anchor-only" });
        } else {
          links.push({ line: i + 1, target, kind });
        }
      }
    }
    // File references in backticks / inline
    for (const { regex, kind } of FILE_REF_PATTERNS) {
      regex.lastIndex = 0;
      let m;
      while ((m = regex.exec(line)) !== null) {
        links.push({ line: i + 1, target: m[1], kind });
      }
    }
  }
  return links;
}

function resolveTarget(sourceFile, target) {
  if (!target) return null;
  // Strip anchor
  const cleanTarget = target.split("#")[0];
  if (!cleanTarget) return null;
  // Resolve relative to the source file's directory
  const sourceDir = path.dirname(sourceFile);
  const direct = path.resolve(sourceDir, cleanTarget);
  return direct;
}

async function pathExists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

/**
 * Some references in `references/subdir.md` point to `assets/file.html`
 * meaning the skill's top-level `assets/` dir, not `references/assets/`.
 * Try resolving from the skill root (parent of references/) as a fallback.
 * Also handles nested dirs like `references/config/file.md` -> `references/file.md`
 * and `references/presets/file.md` -> `references/file.md`.
 */
async function skillAwareExists(sourceFile, target) {
  const direct = resolveTarget(sourceFile, target);
  if (!direct) return { exists: false, resolved: null };
  if (await pathExists(direct)) return { exists: true, resolved: direct };

  const sourceDir = path.dirname(sourceFile);
  const parts = sourceDir.split(path.sep);

  // Find the skill root (directory containing SKILL.md)
  let skillRoot = sourceDir;
  for (let i = parts.length - 1; i >= 0; i--) {
    const candidate = parts.slice(0, i + 1).join(path.sep);
    if (await pathExists(path.join(candidate, "SKILL.md"))) {
      skillRoot = candidate;
      break;
    }
  }

  // Fallback 1: resolve from skill root
  const cleanTarget = target.split("#")[0];
  const fromSkillRoot = path.resolve(skillRoot, cleanTarget);
  if (await pathExists(fromSkillRoot)) return { exists: true, resolved: fromSkillRoot };

  // Fallback 2: resolve from each ancestor directory up to skill root
  let current = sourceDir;
  while (current !== skillRoot && current !== path.dirname(current)) {
    current = path.dirname(current);
    const fromAncestor = path.resolve(current, cleanTarget);
    if (await pathExists(fromAncestor)) return { exists: true, resolved: fromAncestor };
  }

  return { exists: false, resolved: direct };
}

function isTemplatePlaceholder(target) {
  // Patterns like <layout>.md, <style>.md are template placeholders, not real files
  // Also skip glob patterns (*.md), NN-{slug} patterns, YYYYMMDD patterns
  if (/[<>{}]/.test(target)) return true;
  if (/\*/.test(target)) return true;
  if (/NN-/.test(target)) return true;
  if (/YYYYMMDD|HHMMSS/.test(target)) return true;
  if (/\{slug\}|\{type\}|\{preset\}|\{topic-slug\}|\{relative-path\}|\{ext\}/.test(target)) return true;
  if (/page-xxx/.test(target)) return true;
  return false;
}

function printReport(totalChecked, broken) {
  console.log(`\n=== bonin-skills Dead Link Check ===\n`);
  console.log(`Total links checked: ${totalChecked}`);
  console.log(`Broken links found: ${broken.length}\n`);

  if (broken.length === 0) {
    console.log("✅ All internal links resolve correctly.\n");
    return;
  }

  console.log("❌ Broken links:\n");
  const bySource = new Map();
  for (const b of broken) {
    if (!bySource.has(b.source)) bySource.set(b.source, []);
    bySource.get(b.source).push(b);
  }
  for (const [source, items] of bySource) {
    console.log(`  ${source}:`);
    for (const item of items) {
      console.log(`    L${item.line} [${item.kind}] -> ${item.target}`);
    }
  }
  console.log("");
}

main().catch((err) => {
  console.error("Link check failed:", err);
  process.exit(2);
});
