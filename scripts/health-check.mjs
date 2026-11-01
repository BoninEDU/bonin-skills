#!/usr/bin/env node
/**
 * bonin-skills Health Check Script
 *
 * Runs the full unit test suite, collects junction/integrity diagnostics,
 * and writes a Markdown health report to reports/health-<timestamp>.md.
 *
 * Usage:
 *   node scripts/health-check.mjs              # run + report
 *   node scripts/health-check.mjs --quiet      # run, only print on failure
 *   node scripts/health-check.mjs --schedule   # exit code 0/1 for cron use
 *
 * Cross-platform: works on macOS, Linux, Windows (PowerShell / Git Bash).
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..");
const REPORTS_DIR = path.join(REPO_ROOT, "reports");

const args = new Set(process.argv.slice(2));
const QUIET = args.has("--quiet");
const SCHEDULE = args.has("--schedule");

const timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
const reportPath = path.join(REPORTS_DIR, `health-${timestamp}.md`);

async function main() {
  const startedAt = new Date();
  const diagnostics = await collectDiagnostics();
  const testResult = runTests();
  const report = buildReport(startedAt, testResult, diagnostics);

  await fs.mkdir(REPORTS_DIR, { recursive: true });
  await fs.writeFile(reportPath, report, "utf8");

  if (!QUIET || !testResult.passed) {
    console.log(report);
    console.log(`\nReport written to: ${reportPath}`);
  }

  if (SCHEDULE) {
    process.exit(testResult.passed ? 0 : 1);
  }
}

function runTests() {
  const runner = path.join(REPO_ROOT, "scripts", "run-node-tests.mjs");
  const result = spawnSync("node", [runner], {
    cwd: REPO_ROOT,
    encoding: "utf8",
    shell: process.platform === "win32",
  });
  const output = result.stdout + result.stderr;
  const passMatch = output.match(/# pass\s+(\d+)/);
  const failMatch = output.match(/# fail\s+(\d+)/);
  const totalMatch = output.match(/# tests\s+(\d+)/);
  const durationMatch = output.match(/# duration_ms\s+([\d.]+)/);
  return {
    passed: result.status === 0,
    exitCode: result.status,
    total: totalMatch ? parseInt(totalMatch[1], 10) : 0,
    pass: passMatch ? parseInt(passMatch[1], 10) : 0,
    fail: failMatch ? parseInt(failMatch[1], 10) : 0,
    durationMs: durationMatch ? parseFloat(durationMatch[1]) : 0,
    output: output.slice(-2000),
  };
}

async function collectDiagnostics() {
  return {
    platform: `${os.type()} ${os.release()} (${os.platform()})`,
    nodeVersion: process.version,
    skillCount: await countSkills(),
    pluginVersion: await readPluginVersion(),
    claudeSkillsJunctions: await countJunctions(path.join(os.homedir(), ".claude", "skills")),
    traeSkillsJunctions: await countJunctions(path.join(os.homedir(), ".trae", "skills")),
    codexSkillsUntouched: await checkCodexUntouched(),
    gitCommit: await readGitCommit(),
  };
}

async function countSkills() {
  const skillsRoot = path.join(REPO_ROOT, "skills");
  try {
    const entries = await fs.readdir(skillsRoot, { withFileTypes: true });
    return entries.filter((e) => e.isDirectory() && e.name.startsWith("bonin-")).length;
  } catch {
    return -1;
  }
}

async function readPluginVersion() {
  try {
    const raw = await fs.readFile(path.join(REPO_ROOT, ".claude-plugin", "plugin.json"), "utf8");
    return JSON.parse(raw).version;
  } catch {
    return "unknown";
  }
}

async function countJunctions(skillsDir) {
  try {
    const entries = await fs.readdir(skillsDir, { withFileTypes: true });
    return entries.filter((e) => e.name.startsWith("bonin-")).length;
  } catch {
    return 0;
  }
}

async function checkCodexUntouched() {
  const codexDir = path.join(os.homedir(), ".codex", "skills");
  try {
    const entries = await fs.readdir(codexDir, { withFileTypes: true });
    const names = entries.filter((e) => e.isDirectory()).map((e) => e.name);
    return {
      intact: names.includes("bonincode-skills") && names.includes("bonindev-skills"),
      entries: names,
    };
  } catch {
    return { intact: true, entries: [] };
  }
}

async function readGitCommit() {
  const result = spawnSync("git", ["rev-parse", "--short", "HEAD"], {
    cwd: REPO_ROOT,
    encoding: "utf8",
  });
  return result.stdout.trim() || "unknown";
}

function buildReport(startedAt, testResult, diag) {
  const endedAt = new Date();
  const durationSec = ((endedAt - startedAt) / 1000).toFixed(2);
  const status = testResult.passed ? "HEALTHY" : "UNHEALTHY";
  const statusEmoji = testResult.passed ? "✅" : "❌";

  return `# bonin-skills Health Report

**Status:** ${statusEmoji} ${status}
**Generated:** ${endedAt.toISOString()}
**Duration:** ${durationSec}s

## Environment

| Item | Value |
|------|-------|
| Platform | ${diag.platform} |
| Node.js | ${diag.nodeVersion} |
| Git commit | \`${diag.gitCommit}\` |
| Plugin version | ${diag.pluginVersion} |
| Skill count | ${diag.skillCount} |

## Test Results

| Metric | Value |
|--------|-------|
| Total tests | ${testResult.total} |
| Passed | ${testResult.pass} |
| Failed | ${testResult.fail} |
| Test duration | ${testResult.durationMs} ms |
| Exit code | ${testResult.exitCode} |

## IDE Integration

| IDE location | bonin-* junctions |
|--------------|-------------------|
| \`~/.claude/skills\` | ${diag.claudeSkillsJunctions} |
| \`~/.trae/skills\` | ${diag.traeSkillsJunctions} |

## Separate Stack Integrity (must remain untouched)

| Stack | Status |
|-------|--------|
| \`~/.codex/skills/bonincode-skills\` | ${diag.codexSkillsUntouched.intact ? "✅ Intact" : "❌ Missing"} |
| \`~/.codex/skills/bonindev-skills\` | ${diag.codexSkillsUntouched.intact ? "✅ Intact" : "❌ Missing"} |

${testResult.passed ? "" : "## Failed Test Output\n\n```\n" + testResult.output + "\n```"}

---

*This report is generated by \`scripts/health-check.mjs\`. Run \`node scripts/health-check.mjs\` manually, or schedule it via cron / Task Scheduler.*
`;
}

main().catch((err) => {
  console.error("Health check failed:", err);
  process.exit(2);
});
