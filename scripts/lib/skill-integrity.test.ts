import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import test from "node:test";

const REPO_ROOT = path.resolve(import.meta.dirname, "..", "..");

const EXPECTED_VERSION = "2.5.0";

interface SkillFrontmatter {
  name: string;
  description: string;
  version?: string;
}

async function readJson(filePath: string): Promise<unknown> {
  const raw = await fs.readFile(filePath, "utf8");
  return JSON.parse(raw);
}

async function listSkillDirs(): Promise<string[]> {
  const skillsRoot = path.join(REPO_ROOT, "skills");
  const entries = await fs.readdir(skillsRoot, { withFileTypes: true });
  return entries
    .filter((e) => e.isDirectory() && e.name.startsWith("bonin-"))
    .map((e) => path.join(skillsRoot, e.name));
}

async function readSkillFrontmatter(skillDir: string): Promise<SkillFrontmatter> {
  const skillFile = path.join(skillDir, "SKILL.md");
  const raw = await fs.readFile(skillFile, "utf8");
  const match = raw.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!match) {
    throw new Error(`No frontmatter in ${skillFile}`);
  }
  const fmText = match[1];
  const nameMatch = fmText.match(/^name:\s*(.+)$/m);
  if (!nameMatch) {
    throw new Error(`Invalid frontmatter in ${skillFile}: missing name`);
  }
  // Handle YAML folded block scalar (>-) and literal block scalar (|)
  const descFolded = fmText.match(/^description:\s*>-?\s*\n((?:\s+.+\n?)+)/m);
  const descPlain = fmText.match(/^description:\s*(.+)$/m);
  let description: string;
  if (descFolded) {
    description = descFolded[1]
      .split("\n")
      .map((l) => l.trim())
      .filter(Boolean)
      .join(" ");
  } else if (descPlain) {
    description = descPlain[1].trim().replace(/^["']|["']$/g, "");
  } else {
    throw new Error(`Invalid frontmatter in ${skillFile}: missing description`);
  }
  const versionMatch = fmText.match(/^version:\s*(.+)$/m);
  return {
    name: nameMatch[1].trim(),
    description,
    version: versionMatch?.[1].trim(),
  };
}

test("plugin.json is valid JSON with correct name and version", async () => {
  const plugin = (await readJson(path.join(REPO_ROOT, ".claude-plugin", "plugin.json"))) as {
    name: string;
    version: string;
  };
  assert.equal(plugin.name, "bonin-skills", "plugin name must be bonin-skills");
  assert.equal(plugin.version, EXPECTED_VERSION, `plugin.json version must be ${EXPECTED_VERSION}`);
});

test("marketplace.json is valid JSON with consistent version", async () => {
  const market = (await readJson(path.join(REPO_ROOT, ".claude-plugin", "marketplace.json"))) as {
    name: string;
    version: string;
    plugins: Array<{ name: string; version: string }>;
  };
  assert.equal(market.version, EXPECTED_VERSION, "marketplace top-level version");
  assert.equal(market.plugins[0].version, EXPECTED_VERSION, "marketplace plugin entry version");
  assert.equal(market.plugins[0].name, "bonin-skills", "marketplace plugin name");
});

test("CLAUDE.md declares the expected version", async () => {
  const raw = await fs.readFile(path.join(REPO_ROOT, "CLAUDE.md"), "utf8");
  const match = raw.match(/Version:\s*\*\*(\d+\.\d+\.\d+)\*\*/);
  assert.ok(match, "CLAUDE.md must contain a Version declaration");
  assert.equal(match[1], EXPECTED_VERSION, "CLAUDE.md version must match expected");
});

test("USER_MANUAL.md declares the expected version", async () => {
  const raw = await fs.readFile(path.join(REPO_ROOT, "USER_MANUAL.md"), "utf8");
  const match = raw.match(/Version:\s*(\d+\.\d+\.\d+)/);
  assert.ok(match, "USER_MANUAL.md must contain a Version declaration");
  assert.equal(match[1], EXPECTED_VERSION, "USER_MANUAL.md version must match expected");
});

test("USER_MANUAL.zh.md declares the expected version", async () => {
  const raw = await fs.readFile(path.join(REPO_ROOT, "USER_MANUAL.zh.md"), "utf8");
  const match = raw.match(/版本：\s*(\d+\.\d+\.\d+)/);
  assert.ok(match, "USER_MANUAL.zh.md must contain a 版本 declaration");
  assert.equal(match[1], EXPECTED_VERSION, "USER_MANUAL.zh.md version must match expected");
});

test("every skill directory has a valid SKILL.md with frontmatter", async () => {
  const skillDirs = await listSkillDirs();
  assert.ok(skillDirs.length >= 40, `expected at least 40 skills, found ${skillDirs.length}`);
  for (const dir of skillDirs) {
    const fm = await readSkillFrontmatter(dir);
    assert.ok(fm.name.startsWith("bonin-"), `${dir}: name must start with bonin-`);
    assert.ok(fm.description.length > 10, `${dir}: description too short`);
  }
});

test("no skill references non-existent docs/ paths", async () => {
  const claudeMd = await fs.readFile(path.join(REPO_ROOT, "CLAUDE.md"), "utf8");
  const docsLinks = claudeMd.match(/\[docs\/[^\]]+\]\(docs\/[^)]+\)/g) ?? [];
  assert.equal(docsLinks.length, 0, `CLAUDE.md still references docs/ paths: ${docsLinks.join(", ")}`);
});

test("no PascalCase directories exist under bonin-push or bonin-qa", async () => {
  const checked = ["skills/bonin-push", "skills/bonin-qa"];
  for (const rel of checked) {
    const dir = path.join(REPO_ROOT, rel);
    if (!(await pathExists(dir))) continue;
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const e of entries) {
      if (!e.isDirectory()) continue;
      assert.ok(
        /^[a-z][a-z0-9-]*$/.test(e.name),
        `${rel}/${e.name}: directory must be lowercase`,
      );
    }
  }
});

test("stray URL_20260503.md file does not exist at repo root", async () => {
  const stray = path.join(REPO_ROOT, "URL_20260503.md");
  assert.equal(await pathExists(stray), false, "URL_20260503.md must be deleted");
});

test("bonin-image-gen SKILL.md contains deprecation notice", async () => {
  const raw = await fs.readFile(
    path.join(REPO_ROOT, "skills", "bonin-image-gen", "SKILL.md"),
    "utf8",
  );
  assert.ok(/Deprecated/i.test(raw), "bonin-image-gen must declare itself deprecated");
});

test("bonin-xhs-images SKILL.md contains deprecation notice", async () => {
  const raw = await fs.readFile(
    path.join(REPO_ROOT, "skills", "bonin-xhs-images", "SKILL.md"),
    "utf8",
  );
  assert.ok(/Deprecated/i.test(raw), "bonin-xhs-images must declare itself deprecated");
});

test("bonin-push scripts/push.sh uses environment variable overrides", async () => {
  const raw = await fs.readFile(
    path.join(REPO_ROOT, "skills", "bonin-push", "scripts", "push.sh"),
    "utf8",
  );
  assert.ok(
    /BONIN_SKILLS_REPO/.test(raw),
    "push.sh must reference BONIN_SKILLS_REPO env var",
  );
});

test("bonin-wechat-summary SKILL.md documents multiple platform paths", async () => {
  const raw = await fs.readFile(
    path.join(REPO_ROOT, "skills", "bonin-wechat-summary", "SKILL.md"),
    "utf8",
  );
  assert.ok(/Windows/.test(raw), "bonin-wechat-summary must document Windows path");
  assert.ok(/macOS/.test(raw), "bonin-wechat-summary must document macOS path");
});

test("no third-party author residues in skill files", async () => {
  const forbidden = ["继刚", "李继刚", "宝玉", "baoyu", "Baoyu", "JimLiu", "lijigang"];
  const skillDirs = await listSkillDirs();
  const violations: string[] = [];
  for (const dir of skillDirs) {
    await scanDir(dir, forbidden, violations, dir);
  }
  assert.deepEqual(violations, [], `Forbidden third-party residues found: ${violations.join("; ")}`);
});

test("bonin-qa references use lowercase paths", async () => {
  const skillFile = path.join(REPO_ROOT, "skills", "bonin-qa", "SKILL.md");
  const raw = await fs.readFile(skillFile, "utf8");
  assert.ok(
    /references\/extract\.md/.test(raw),
    "bonin-qa SKILL.md must reference references/extract.md",
  );
  assert.ok(
    /references\/question-design\.md/.test(raw),
    "bonin-qa SKILL.md must reference references/question-design.md",
  );
  assert.ok(
    !/References\/|Workflows\//.test(raw),
    "bonin-qa SKILL.md must not reference PascalCase dirs",
  );
});

test("bonin-push references use lowercase paths", async () => {
  const skillFile = path.join(REPO_ROOT, "skills", "bonin-push", "SKILL.md");
  const raw = await fs.readFile(skillFile, "utf8");
  assert.ok(
    /references\/push\.md/.test(raw),
    "bonin-push SKILL.md must reference references/push.md",
  );
  assert.ok(
    /scripts\/push\.sh/.test(raw),
    "bonin-push SKILL.md must reference scripts/push.sh",
  );
  assert.ok(
    !/Tools\/|Workflows\//.test(raw),
    "bonin-push SKILL.md must not reference PascalCase dirs",
  );
});

async function pathExists(p: string): Promise<boolean> {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

async function scanDir(
  dir: string,
  forbidden: string[],
  violations: string[],
  base: string,
): Promise<void> {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (e.name === "node_modules" || e.name === ".git") continue;
      await scanDir(full, forbidden, violations, base);
    } else if (e.isFile() && /\.(md|ts|mjs|js|json|html|sh)$/.test(e.name)) {
      const raw = await fs.readFile(full, "utf8").catch(() => "");
      for (const kw of forbidden) {
        if (raw.includes(kw)) {
          violations.push(`${path.relative(base, full)}: contains "${kw}"`);
        }
      }
    }
  }
}
