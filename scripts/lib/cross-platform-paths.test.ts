import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import test from "node:test";

const REPO_ROOT = path.resolve(import.meta.dirname, "..", "..");

interface PathIssue {
  file: string;
  line: number;
  pattern: string;
  snippet: string;
}

const SKILL_DIRS_TO_SCAN = path.join(REPO_ROOT, "skills");

async function scanForHardcodedPaths(
  root: string,
  patterns: Array<{ regex: RegExp; label: string }>,
): Promise<PathIssue[]> {
  const issues: PathIssue[] = [];
  await walk(root, async (filePath, lines) => {
    lines.forEach((line, i) => {
      for (const { regex, label } of patterns) {
        if (regex.test(line)) {
          issues.push({
            file: path.relative(REPO_ROOT, filePath),
            line: i + 1,
            pattern: label,
            snippet: line.trim().slice(0, 120),
          });
        }
      }
    });
  });
  return issues;
}

async function walk(
  dir: string,
  cb: (filePath: string, lines: string[]) => Promise<void>,
): Promise<void> {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (e.name === "node_modules" || e.name === ".git" || e.name === "assets") continue;
      await walk(full, cb);
    } else if (e.isFile() && /\.(md|sh|ts|mjs|js)$/.test(e.name)) {
      const raw = await fs.readFile(full, "utf8").catch(() => "");
      const lines = raw.split("\n");
      await cb(full, lines);
    }
  }
}

test("no hard-coded macOS-only $HOME/code paths in skill scripts", async () => {
  const issues = await scanForHardcodedPaths(SKILL_DIRS_TO_SCAN, [
    { regex: /\$HOME\/code\//, label: "hard-coded $HOME/code/ path" },
    { regex: /~\/code\//, label: "hard-coded ~/code/ path" },
  ]);
  // Acceptable patterns:
  // - ${BONIN_SKILLS_REPO:-$HOME/code/...} — env var override in shell
  // - $BONIN_SKILLS_REPO ... $HOME/code/... — env var documented alongside default
  // - $BONIN_SKILLS_REPO ... ~/code/... — same, with tilde notation
  const realIssues = issues.filter((i) => {
    if (i.snippet.includes("${BONIN_SKILLS_REPO:-")) return false;
    if (i.snippet.includes("${BONIN_SKILLS_LOCAL:-")) return false;
    if (/BONIN_SKILLS_REPO/.test(i.snippet)) return false;
    return true;
  });
  assert.deepEqual(
    realIssues,
    [],
    `Hard-coded $HOME/code paths found without env override: ${JSON.stringify(realIssues, null, 2)}`,
  );
});

test("bonin-wechat-summary does not hard-code only macOS path", async () => {
  const skillFile = path.join(REPO_ROOT, "skills", "bonin-wechat-summary", "SKILL.md");
  const raw = await fs.readFile(skillFile, "utf8");
  const hasMacPath = /~\/Library\/Containers\/com\.tencent\.xinWeChat/.test(raw);
  const hasWindowsPath = /%APPDATA%\\Tencent\\WeChat/.test(raw);
  assert.ok(hasMacPath, "macOS path should be documented");
  assert.ok(hasWindowsPath, "Windows path must also be documented");
});

test("bonin-push push.sh provides environment variable overrides for all hard-coded paths", async () => {
  const scriptPath = path.join(REPO_ROOT, "skills", "bonin-push", "scripts", "push.sh");
  const raw = await fs.readFile(scriptPath, "utf8");
  assert.ok(
    /\$\{BONIN_SKILLS_REPO:-/.test(raw),
    "push.sh must allow BONIN_SKILLS_REPO override",
  );
  assert.ok(
    /\$\{BONIN_SKILLS_LOCAL:-/.test(raw),
    "push.sh must allow BONIN_SKILLS_LOCAL override",
  );
  assert.ok(
    /\$\{BONIN_REPO_URL:-/.test(raw),
    "push.sh must allow BONIN_REPO_URL override",
  );
});

test("no raw ~/Library paths in non-macOS-specific skills without platform notes", async () => {
  const issues: PathIssue[] = [];
  await walk(SKILL_DIRS_TO_SCAN, async (filePath, lines) => {
    const rel = path.relative(REPO_ROOT, filePath);
    // bonin-wechat-summary is allowed to document macOS path with platform notes
    if (rel.includes("bonin-wechat-summary")) return;
    lines.forEach((line, i) => {
      if (/~\/Library\//.test(line)) {
        // Acceptable if the line or nearby lines have platform markers
        const ctx = lines.slice(Math.max(0, i - 2), i + 3).join("\n");
        if (/macOS|# macOS|Platform paths:|macOS:/.test(ctx)) return;
        issues.push({
          file: rel,
          line: i + 1,
          pattern: "raw ~/Library/ path",
          snippet: line.trim().slice(0, 120),
        });
      }
    });
  });
  assert.deepEqual(
    issues,
    [],
    `Raw ~/Library/ paths found without platform documentation: ${JSON.stringify(issues, null, 2)}`,
  );
});

test("all internal references in SKILL.md use lowercase paths", async () => {
  const issues: PathIssue[] = [];
  await walk(SKILL_DIRS_TO_SCAN, async (filePath, lines) => {
    if (!filePath.endsWith("SKILL.md")) return;
    lines.forEach((line, i) => {
      // Check for references to PascalCase dirs
      const pascalRefs = line.match(/`(Tools|Workflows|References)\/[^`]+`/g);
      if (pascalRefs) {
        issues.push({
          file: path.relative(REPO_ROOT, filePath),
          line: i + 1,
          pattern: "PascalCase directory reference",
          snippet: line.trim().slice(0, 120),
        });
      }
    });
  });
  assert.deepEqual(
    issues,
    [],
    `PascalCase directory references found: ${JSON.stringify(issues, null, 2)}`,
  );
});

test("CLAUDE.md does not contain broken docs/ markdown links", async () => {
  const claudeMd = await fs.readFile(path.join(REPO_ROOT, "CLAUDE.md"), "utf8");
  const brokenLinks = claudeMd.match(/\]\(docs\/[^)]+\)/g) ?? [];
  assert.equal(
    brokenLinks.length,
    0,
    `CLAUDE.md still has docs/ links: ${brokenLinks.join(", ")}`,
  );
});
