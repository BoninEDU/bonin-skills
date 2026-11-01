#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { globSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

const testFiles = [
  "scripts/lib/skill-release-guard.test.ts",
  "scripts/lib/release-files.test.ts",
  "scripts/lib/skill-integrity.test.ts",
  "scripts/lib/cross-platform-paths.test.ts",
];

const args = process.argv.slice(2);
const coverage = args.includes("--experimental-test-coverage");

const tsxArgs = ["--test", ...testFiles.map((f) => path.resolve(root, f))];
if (coverage) tsxArgs.push("--experimental-test-coverage");

const result = spawnSync("npx", ["-y", "tsx", ...tsxArgs], {
  stdio: "inherit",
  cwd: root,
  shell: process.platform === "win32",
});

process.exit(result.status ?? 1);
