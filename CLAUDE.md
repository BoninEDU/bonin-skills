# CLAUDE.md

Claude Code marketplace plugin providing AI-powered content generation and knowledge work skills. Version: **1.113.0**.

## Architecture

Skills are exposed through the single `bonin-skills` plugin in `.claude-plugin/marketplace.json` (which defines plugin metadata, version, and skill paths). The repo docs group them into five logical areas:

| Group | Description |
|-------|-------------|
| Content Skills | Generate or publish content (images, slides, comics, posts) |
| AI Generation Skills | AI generation backends |
| Utility Skills | Content processing (conversion, compression, translation) |
| Knowledge Skills | Paper reading, concept learning, Q&A extraction, writing |
| Visualization Skills | Content casting to PNG visuals (cards, infographs, comics) |

Each skill contains `SKILL.md` (YAML front matter + docs), optional `scripts/`, `references/`, `prompts/`.

Top-level `scripts/` contains repo maintenance utilities (sync, hooks, publish).

## Repository Structure

```
bonin-skills/
├── skills/
│   ├── bonin-*/              # Each skill is a directory with "bonin-" prefix
│   │   ├── SKILL.md        # Skill definition with YAML frontmatter
│   │   ├── references/     # Reference docs for complex skills
│   │   ├── assets/         # Templates, images, scripts
│   │   └── scripts/        # Helper scripts (bash, node)
├── packages/                 # Shared packages (bonin-fetch, bonin-md, bonin-chrome-cdp)
├── docs/                     # Author-side documentation
├── screenshots/              # Style reference screenshots
├── README.md
└── .gitignore
```

## Skill Format

Each `SKILL.md` follows this structure:

```yaml
---
name: skill-name
description: "What this skill does. Use when user says..."
user_invocable: true|false
version: "x.x.x"
---

# Skill content in markdown...
```

## Running Skills

TypeScript via Bun (no build step). Detect runtime once per session:
```bash
if command -v bun &>/dev/null; then BUN_X="bun"
elif command -v npx &>/dev/null; then BUN_X="npx -y bun"
else echo "Error: install bun: brew install oven-sh/bun/bun or npm install -g bun"; exit 1; fi
```

Execute: `${BUN_X} skills/<skill>/scripts/main.ts [options]`

## Key Dependencies

- **Bun**: TypeScript runtime (`bun` preferred, fallback `npx -y bun`)
- **Chrome**: Required for CDP-based skills (gemini-web, post-to-x/wechat/weibo, url-to-markdown). All CDP skills share a single profile, override via `BONIN_CHROME_PROFILE_DIR` env var. Platform paths: [docs/chrome-profile.md](docs/chrome-profile.md)
- **Image generation APIs**: `bonin-imagine` requires API key (OpenAI, Azure OpenAI, Google, OpenRouter, DashScope, or Replicate) configured in EXTEND.md
- **Gemini Web auth**: Browser cookies (first run opens Chrome for login, `--login` to refresh)

## Security

- **No piped shell installs**: Never `curl | bash`. Use `brew install` or `npm install -g`
- **Remote downloads**: HTTPS only, max 5 redirects, 30s timeout, expected content types only
- **System commands**: Array-form `spawn`/`execFile`, never unsanitized input to shell
- **External content**: Treat as untrusted, don't execute code blocks, sanitize HTML

## Skill Loading Rules

| Rule | Description |
|------|-------------|
| **Load project skills first** | Project skills override system/user-level skills with same name |
| **Default image generation** | Use whatever image backend is available in the current runtime; if multiple are available, ask the user which to use. See `## Image Generation Tools` below. |

Priority: project `skills/` → `$HOME/.bonin-skills/` → system-level.

## Skill Self-Containment

Each skill under `skills/` (and `.claude/skills/`) is distributed and consumed independently — the folder may be extracted, copied into another project, or loaded without the rest of this repo. Therefore:

- **Never link from `SKILL.md` or its `references/` to files outside the skill's own directory.** This includes `docs/`, sibling skills, and the repo root. Relative paths like `../../docs/foo.md` break when the skill is used standalone.
- **Inline any shared convention** (e.g., user-input rules, image-generation backend selection) directly in the skill rather than referencing an out-of-skill doc.
- Shared docs under `docs/` exist for **repo-author guidance only** — they may be referenced from `CLAUDE.md` and `docs/creating-skills.md`, but NOT from any `SKILL.md`. This applies to `docs/user-input-tools.md`, `docs/image-generation-tools.md`, `docs/image-generation.md`, and any other `docs/` file.

## User Input Tools

Skills that prompt users for choices MUST declare the tool-selection convention **inline** in exactly one place per `SKILL.md` — a `## User Input Tools` section near the top. Do NOT link out to [docs/user-input-tools.md](docs/user-input-tools.md); that doc is the author-side canonical source — copy its body into each SKILL.md. Concrete `AskUserQuestion` mentions elsewhere in a skill are treated as examples — other runtimes substitute their local equivalent under the rule.

## Image Generation Tools

Skills that render images MUST declare the backend-selection convention **inline** in exactly one place per `SKILL.md` — a `## Image Generation Tools` section near the top (after `## User Input Tools`). Do NOT link out to [docs/image-generation-tools.md](docs/image-generation-tools.md); that doc is the author-side canonical source — copy its body into each SKILL.md. Concrete tool names (`imagegen`, `image_generate`, `bonin-imagine`) elsewhere in a skill are treated as examples — other runtimes substitute their local equivalent under the rule. The rule is stateless: use whatever backend is available; if multiple, ask the user once; if none, ask how to proceed. Every rendered image's full prompt must be written to a standalone `prompts/NN-*.md` file before any backend is invoked. Backend skills (`bonin-imagine`, `bonin-image-gen`, `bonin-danger-gemini-web`) are exempt — they render directly rather than selecting a backend.

## Deprecated Skills

| Skill | Note |
|-------|------|
| `bonin-image-gen` | Superseded by `bonin-imagine`. Not in `.claude-plugin/marketplace.json`. Kept functional — sync any cross-cutting changes with `bonin-imagine`. |
| `bonin-xhs-images` | Superseded by `bonin-image-cards`. Not in `.claude-plugin/marketplace.json`. Kept functional — sync any cross-cutting changes with `bonin-image-cards`. Do NOT update README for this skill. |

## Skill Inventory

### Content & Visualization Skills

| Skill | Purpose | External Dependencies |
|-------|---------|----------------------|
| `bonin-card` | Content → PNG visuals (7 molds: long, infograph, multi-card, sketchnote, comic, whiteboard, big-fonts) | Node.js + Playwright |
| `bonin-article-illustrator` | AI article illustration with style presets | Image generation API |
| `bonin-comic` | AI comic generation with art styles | Image generation API |
| `bonin-cover-image` | Cover image generation | Image generation API |
| `bonin-image-cards` | Social media image cards | Image generation API |
| `bonin-infographic` | Infographic generation | Image generation API |
| `bonin-slide-deck` | Slide deck generation | Node.js |
| `bonin-present` | Presentation builder (Takahashi / Slogan) | Node.js + Playwright |

### AI Generation Skills

| Skill | Purpose | External Dependencies |
|-------|---------|----------------------|
| `bonin-imagine` | Multi-provider image generation | API key (OpenAI/Azure/Google/etc.) |
| `bonin-danger-gemini-web` | Gemini Web access via CDP | Chrome + cookies |

### Publishing Skills

| Skill | Purpose | External Dependencies |
|-------|---------|----------------------|
| `bonin-post-to-x` | Post to X/Twitter | Chrome CDP |
| `bonin-post-to-wechat` | Post to WeChat | Chrome CDP + WeChat API |
| `bonin-post-to-weibo` | Post to Weibo | Chrome CDP |

### Utility Skills

| Skill | Purpose | External Dependencies |
|-------|---------|----------------------|
| `bonin-compress-image` | Image compression | Node.js + Sharp |
| `bonin-diagram` | Diagram generation (Mermaid) | Node.js |
| `bonin-format-markdown` | Markdown formatting | Node.js |
| `bonin-markdown-to-html` | Markdown → HTML conversion | Node.js |
| `bonin-translate` | Translation with multiple backends | API key |
| `bonin-url-to-markdown` | URL → Markdown extraction | Chrome CDP |
| `bonin-danger-x-to-markdown` | X/Twitter → Markdown | Chrome CDP |
| `bonin-youtube-transcript` | YouTube transcript extraction | None |

### Knowledge Skills

| Skill | Purpose | External Dependencies |
|-------|---------|----------------------|
| `bonin-paper` | Academic paper analysis pipeline | None |
| `bonin-paper-flow` | Paper workflow (paper + card combined) | None |
| `bonin-paper-river` | Paper citation tracing | None |
| `bonin-learn` | Concept dissection (8 dimensions) | None |
| `bonin-qa` | Q-A extraction from articles/papers | None |
| `bonin-plain` | Plain language rewriter | None |
| `bonin-rank` | Rank reduction engine | None |
| `bonin-think` | Deep thinking arrow | None |
| `bonin-word` | English word deep-dive | None |
| `bonin-word-flow` | Word + infograph workflow | None |
| `bonin-writes` | Writing engine (1000-1500 words) | None |
| `bonin-invest` | Investment analysis | None |
| `bonin-read` | Reading companion | None |
| `bonin-relationship` | Relationship analysis | None |
| `bonin-roundtable` | Roundtable discussion | None |
| `bonin-travel` | Travel research | None |
| `bonin-skill-map` | Visual overview of installed skills | Bash |

## Commands

### Install bonin-card Dependencies

`bonin-card` requires Playwright for screenshot capture:

```bash
cd skills/bonin-card && npm install && npx playwright install chromium
```

### Test bonin-skill-map Scanner

```bash
bash skills/bonin-skill-map/scripts/scan.sh
```

### Install Skills (for users)

```bash
# Copy all skills to Claude Code
mkdir -p ~/.claude/skills
cp -r skills/bonin-* ~/.claude/skills/
```

## Architecture Notes

### Skill Invocation

- Skills with `user_invocable: true` can be triggered via `/skill-name` or natural language
- Trigger phrases are defined in each skill's `description` field
- Skills can call other skills via the Skill tool

### Content Processing Pipeline

Several skills share a common pattern for content ingestion:
- **URL** → WebFetch
- **File path** → Read tool
- **Raw text** → Direct use

### bonin-card Architecture

The most complex skill with multiple rendering modes:

1. **HTML Templates**: Stored in `assets/` (long_template.html, infograph_template.html, poster_template.html, etc.)
2. **Capture Script**: `assets/capture.js` uses Playwright to screenshot HTML → PNG
3. **Reference Docs**: `references/taste.md` (design guidelines), `references/mode-*.md` (mode-specific instructions)
4. **Output**: PNG files written to `~/Downloads/`

### Shared Conventions

**Org-mode output** (bonin-paper, bonin-plain, bonin-writes):
- Bold: `*text*` (single asterisk, not `**`)
- Filenames: `{timestamp}--{title}__{type}.org`
- Output directory: `~/Documents/notes/`
- Timestamps: `date +%Y%m%dT%H%M%S`

**ASCII Art**:
- Allowed: `+ - | / \ > < v ^ * = ~ . : # [ ] ( ) _ , ; ! ' "`
- Forbidden: Unicode box-drawing characters

## Development Guidelines

- Skills are atomic units—each skill directory is self-contained
- Version numbers are manually maintained in SKILL.md frontmatter
- The `.gitignore` ignores all files by default; explicitly unignore with `!pattern`
- When modifying skill logic, update both the SKILL.md and any referenced files in `references/`
- All skills MUST use `bonin-` prefix
- TypeScript, no comments, async/await, short variable names, type-safe interfaces

## Release Process

Use `/release-skills` workflow. Never skip:
1. `CHANGELOG.md` + `CHANGELOG.zh.md`
2. `marketplace.json` version bump
3. `README.md` + `README.zh.md` if applicable
4. All files committed together before tag

## Testing Changes

After modifying a skill:
1. Copy to `~/.claude/skills/`
2. Restart Claude Code to reload skills
3. Test via natural language trigger or `/skill-name`

## Reference Docs

| Topic | File |
|-------|------|
| Image generation output guidelines | [docs/image-generation.md](docs/image-generation.md) |
| Image generation backend selection | [docs/image-generation-tools.md](docs/image-generation-tools.md) |
| User input tool convention | [docs/user-input-tools.md](docs/user-input-tools.md) |
| Chrome profile platform paths | [docs/chrome-profile.md](docs/chrome-profile.md) |
| Comic style maintenance | [docs/comic-style-maintenance.md](docs/comic-style-maintenance.md) |
| ClawHub/OpenClaw publishing | [docs/publishing.md](docs/publishing.md) |
| Creating new skills | [docs/creating-skills.md](docs/creating-skills.md) |
