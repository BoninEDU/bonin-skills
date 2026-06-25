# Bonin Skills — User Manual

> Version: 1.114.0 | Repository: [github.com/BoninEDU/bonin-skills](https://github.com/BoninEDU/bonin-skills) | Website: [boninaigc.top](https://www.boninaigc.top) | Email: boninaigc@gmail.com

> **Bonin AIGC** — *Empower Super-Individuals and Super-Teams*

---

## Table of Contents

- [Introduction](#introduction)
- [System Requirements](#system-requirements)
- [Installation Guide](#installation-guide)
- [Project Structure](#project-structure)
- [Shared Packages](#shared-packages)
- [Skills Overview](#skills-overview)
- [Skill Reference](#skill-reference)
  - [Content & Visualization Skills](#i-content--visualization-skills)
  - [AI Generation Skills](#ii-ai-generation-skills)
  - [Publishing Skills](#iii-publishing-skills)
  - [Utility Skills](#iv-utility-skills)
  - [Knowledge Skills](#v-knowledge-skills)
  - [Deprecated Skills](#vi-deprecated-skills)
- [Environment Variables](#environment-variables)
- [FAQ](#faq)

---

## Introduction

**Bonin Skills** is a Claude Code marketplace plugin providing a comprehensive collection of AI-powered skills for content generation, image creation, paper reading, content publishing, writing, and knowledge analysis. Each skill is a self-contained directory that can be independently installed to `~/.claude/skills/` to extend Claude Code's capabilities.

The plugin is distributed through the Claude Code Marketplace and can also be installed manually.

### About Bonin AIGC

**Bonin AIGC** is on a mission to **Empower Super-Individuals and Super-Teams**. This skills collection is one of its open-source contributions to the AI-native productivity ecosystem.

- Website: [https://www.boninaigc.top](https://www.boninaigc.top)
- Email: boninaigc@gmail.com
- GitHub: [BoninEDU](https://github.com/BoninEDU)

---

## System Requirements

| Dependency | Purpose | Required/Optional |
|------------|---------|-------------------|
| **Claude Code** | Runtime environment | Required |
| **Bun** or **Node.js** | TypeScript script runtime | Required (for script-based skills) |
| **Chrome / Chromium** | CDP-based web interaction skills | Optional (needed for publishing/scraping skills) |
| **Playwright** | HTML-to-PNG screenshot capture | Optional (needed for bonin-card) |
| **Image Generation API Key** | AI image generation | Optional (needed for bonin-imagine) |

---

## Installation Guide

### Option 1: Install via Claude Code Marketplace (Recommended)

Install the bonin-skills plugin directly in Claude Code. All skills are automatically loaded.

### Option 2: Manual Installation

```bash
# 1. Clone the repository
git clone https://github.com/BoninEDU/bonin-skills.git

# 2. Copy skills to Claude Code directory
mkdir -p ~/.claude/skills
cp -r bonin-skills/skills/bonin-* ~/.claude/skills/

# 3. Restart Claude Code to reload skills
```

### Install bonin-card Dependencies

`bonin-card` requires Playwright for HTML screenshot capture:

```bash
cd skills/bonin-card && npm install && npx playwright install chromium
```

### Install Bun Runtime

```bash
# macOS
brew install oven-sh/bun/bun

# Or via npm
npm install -g bun
```

---

## Project Structure

```
bonin-skills/
├── skills/                    # All skill directories
│   └── bonin-*/               # One directory per skill
│       ├── SKILL.md           # Skill definition (YAML frontmatter + docs)
│       ├── references/        # Reference documentation
│       ├── assets/            # Templates, images, scripts
│       ├── scripts/           # Helper scripts (bash, TypeScript)
│       └── prompts/           # Image generation prompts
├── packages/                  # Shared packages
│   ├── bonin-chrome-cdp/      # Chrome CDP utility library
│   ├── bonin-fetch/           # URL fetching and conversion
│   └── bonin-md/              # Markdown rendering and HTML conversion
├── docs/                      # Developer documentation
├── screenshots/               # Style reference screenshots
├── .claude-plugin/            # Plugin configuration
│   ├── marketplace.json       # Marketplace plugin definition
│   └── plugin.json            # Plugin metadata
├── CLAUDE.md                  # Claude Code architecture guide
└── README.md                  # Project readme
```

---

## Shared Packages

| Package | Description |
|---------|-------------|
| **bonin-chrome-cdp** | Shared Chrome DevTools Protocol utilities for CDP-based skills |
| **bonin-fetch** | URL fetching tool — converts web pages to Markdown or JSON via Chrome CDP with site-specific adapters |
| **bonin-md** | Shared Markdown rendering and WeChat-compatible HTML conversion utilities |

---

## Skills Overview

| Category | Count | Description |
|----------|-------|-------------|
| Content & Visualization | 8 | Images, cards, infographics, slides, presentations |
| AI Generation | 2 | Multi-provider image generation, Gemini Web |
| Publishing | 3 | X/Twitter, WeChat Official Account, Weibo |
| Utility | 8 | Image compression, diagrams, formatting, translation, URL conversion, etc. |
| Knowledge | 17 | Paper reading, concept learning, writing, investment analysis, etc. |
| Deprecated | 2 | Kept functional but no longer maintained |

---

## Skill Reference

### I. Content & Visualization Skills

#### bonin-article-illustrator

**Version**: 1.56.2 | **Triggers**: `article illustration`, `illustrate article`, `配图`

AI article illustration generator with multiple style presets. Analyzes article content and generates matching illustrations for each paragraph.

| Command | Description |
|---------|-------------|
| `/bonin-article-illustrator` | Start article illustration workflow |
| Natural language | Say "illustrate this article", "给这篇文章配图" |

---

#### bonin-card

**Version**: 2.2.0 | **Triggers**: `铸`, `cast`, `做成图`, `做成卡片`, `视觉笔记`, `sketchnote`, `漫画`, `comic`, `白板`, `whiteboard`, `大字`, `big fonts`, `小红书卡片`

Content caster — transforms text content into PNG visuals. Seven molds available:

| Mold | Flag | Description |
|------|------|-------------|
| Long reading card | `-l` (default) | Vertical card for long-form reading |
| Infograph | `-i` | Data visualization infographic |
| Multi-card | `-m` | 1080×1440 multi-page reading cards |
| Editorial sketchnote | `-v` | Problem→Failure→Pivot→Insight→Naming, magazine + archive layout |
| Comic | `-c` | Manga-style B&W comic |
| Whiteboard | `-w` | Marker-style whiteboard layout |
| Big-fonts attachment card | `-b` | 1080×1440, weathered stele style for Xiaohongshu |

| Command | Description |
|---------|-------------|
| `/bonin-card` | Default long reading card mode |
| `/bonin-card -i` | Infograph mode |
| `/bonin-card -c` | Comic mode |
| `/bonin-card -w` | Whiteboard mode |
| `/bonin-card -b` | Big-fonts attachment card mode |
| `/bonin-card -v` | Editorial sketchnote mode |
| `/bonin-card -m` | Multi-card mode |

**Dependencies**: Node.js + Playwright

---

#### bonin-comic

**Version**: 1.56.2 | **Triggers**: `漫画`, `comic`, `manga`, `连环画`, `四格漫画`

AI comic generator with multiple art styles. Transforms story content into comic panels.

| Command | Description |
|---------|-------------|
| `/bonin-comic` | Start comic generation workflow |
| Natural language | Say "generate a comic", "画个漫画" |

---

#### bonin-cover-image

**Version**: 1.56.2 | **Triggers**: `封面`, `cover`, `cover image`, `封面图`

Cover image generator. Creates cover images for articles, books, or reports.

| Command | Description |
|---------|-------------|
| `/bonin-cover-image` | Start cover image generation |

---

#### bonin-image-cards

**Version**: 1.56.2 | **Triggers**: `小红书图片`, `XHS images`, `RedNote`, `社交卡片`, `image cards`

Social media image card generator. Breaks content into 1-10 cartoon-style image cards with 12 visual styles, 8 layouts, and 3 color palettes.

| Command | Description |
|---------|-------------|
| `/bonin-image-cards` | Start image card generation |

---

#### bonin-infographic

**Version**: 1.57.1 | **Triggers**: `信息图`, `infographic`, `数据可视化`, `图表`

Professional infographic generator with 21 layout types and 21 visual styles. Automatically analyzes content and recommends the best layout×style combination.

| Command | Description |
|---------|-------------|
| `/bonin-infographic` | Start infographic generation |

---

#### bonin-slide-deck

**Version**: 1.56.2 | **Triggers**: `slides`, `PPT`, `幻灯片`, `演示文稿`, `slide deck`

Professional slide deck generator. Creates outlines with style instructions, then generates individual slide images.

| Command | Description |
|---------|-------------|
| `/bonin-slide-deck` | Start slide deck generation |

---

#### bonin-present

**Version**: 2.0.0 | **Triggers**: `高桥流`, `present`, `做成演讲`, `标语流`, `slogan`, `manifesto`

Presentation builder with two styles:

| Style | Flag | Description |
|-------|------|-------------|
| Takahashi | default | One word per slide, ink on cream, single character fills screen |
| Slogan | `-s` | Manifesto-style, black-red-yellow color blocks, ultra-bold staggered lines, with pause slides |

| Command | Description |
|---------|-------------|
| `/bonin-present` | Takahashi style |
| `/bonin-present -s` | Slogan style |

**Output**: Single-file HTML to `~/Downloads/`

---

### II. AI Generation Skills

#### bonin-imagine

**Version**: 1.107.0 | **Triggers**: `imagine`, `生成图片`, `画图`, `generate image`, `AI绘图`

Multi-provider AI image generation backend. Supported providers:

| Provider | Models |
|----------|--------|
| OpenAI | GPT Image 2, DALL-E 3 |
| Azure OpenAI | GPT Image 2 |
| Google | Imagen 3 |
| OpenRouter | Multiple models |
| DashScope (Tongyi Wanxiang) | Multiple models |
| Z.AI | GLM-Image |
| MiniMax | Multiple models |
| Replicate | Multiple models |

| Command | Description |
|---------|-------------|
| `/bonin-imagine` | Start image generation workflow |
| Natural language | Say "generate an image of...", "画一张..." |

**Configuration**: API Key must be configured in EXTEND.md

---

#### bonin-danger-gemini-web

**Version**: 1.56.1 | **Triggers**: `gemini web`, `问 Gemini`, `Gemini搜索`

Access Gemini Web via Chrome CDP. First run requires Google account login.

| Command | Description |
|---------|-------------|
| `/bonin-danger-gemini-web` | Start Gemini Web Q&A |
| `--login` | Refresh login session |

**Dependencies**: Chrome + Google account cookies

---

### III. Publishing Skills

#### bonin-post-to-x

**Version**: 1.56.2 | **Triggers**: `发推特`, `post to X`, `发X`, `tweet`

Post content to X (Twitter). Supports regular posts (with images/videos) and X Articles (long-form Markdown).

| Command | Description |
|---------|-------------|
| `/bonin-post-to-x` | Start X posting workflow |

**Dependencies**: Chrome CDP + X account login

---

#### bonin-post-to-wechat

**Version**: 1.56.1 | **Triggers**: `发微信`, `post to WeChat`, `公众号`, `微信公众号`

Post content to WeChat Official Account. Supports article publishing (HTML/Markdown) and draft management.

| Command | Description |
|---------|-------------|
| `/bonin-post-to-wechat` | Start WeChat posting workflow |

**Dependencies**: Chrome CDP + WeChat Official Account backend

---

#### bonin-post-to-weibo

**Version**: 1.56.1 | **Triggers**: `发微博`, `post to Weibo`, `微博`

Post content to Weibo. Supports regular posts (text + images + videos) and headline articles (Markdown long-form).

| Command | Description |
|---------|-------------|
| `/bonin-post-to-weibo` | Start Weibo posting workflow |

**Dependencies**: Chrome CDP + Weibo account login

---

### IV. Utility Skills

#### bonin-compress-image

**Version**: 1.56.1 | **Triggers**: `压缩图片`, `compress image`, `图片压缩`, `optimize image`

Image compression tool. Supports PNG, JPEG, WebP formats with adjustable quality.

| Command | Description |
|---------|-------------|
| `/bonin-compress-image` | Start image compression |

**Dependencies**: Node.js + Sharp

---

#### bonin-diagram

**Version**: 1.56.1 | **Triggers**: `图表`, `diagram`, `流程图`, `Mermaid`

Diagram generator using Mermaid syntax. Creates flowcharts, sequence diagrams, Gantt charts, and more.

| Command | Description |
|---------|-------------|
| `/bonin-diagram` | Start diagram generation |

---

#### bonin-format-markdown

**Version**: 1.56.1 | **Triggers**: `格式化`, `format markdown`, `排版`, `整理格式`

Markdown formatting tool. Automatically tidies and standardizes Markdown document formatting.

| Command | Description |
|---------|-------------|
| `/bonin-format-markdown` | Start formatting workflow |

---

#### bonin-markdown-to-html

**Version**: 1.56.1 | **Triggers**: `转HTML`, `markdown to html`, `MD转HTML`, `微信格式`

Markdown to HTML converter with WeChat-compatible themes. Supports code highlighting, math formulas, PlantUML, footnotes, and more.

| Command | Description |
|---------|-------------|
| `/bonin-markdown-to-html` | Start conversion workflow |

---

#### bonin-translate

**Version**: 1.59.0 | **Triggers**: `翻译`, `translate`, `精翻`, `快翻`, `localize`

Article and document translation tool with three modes:

| Mode | Description |
|------|-------------|
| Quick | Direct translation |
| Normal | Analyze then translate |
| Refined | Analyze → Translate → Review → Polish |

Supports custom glossaries and terminology consistency via EXTEND.md.

| Command | Description |
|---------|-------------|
| `/bonin-translate` | Start translation workflow |
| Natural language | Say "translate this article", "翻译这篇文章" |

---

#### bonin-url-to-markdown

**Version**: 1.61.0 | **Triggers**: `保存网页`, `url to markdown`, `网页转MD`, `抓取网页`

URL to Markdown converter using bonin-fetch CLI (Chrome CDP with site-specific adapters). Built-in adapters for X/Twitter, YouTube transcripts, Hacker News, and generic pages via Defuddle.

| Command | Description |
|---------|-------------|
| `/bonin-url-to-markdown` | Start URL fetching workflow |

**Dependencies**: Chrome CDP

---

#### bonin-danger-x-to-markdown

**Version**: 1.56.1 | **Triggers**: `X转MD`, `x to markdown`, `推特转Markdown`

X/Twitter content to Markdown converter. Converts tweet threads and articles to Markdown format.

| Command | Description |
|---------|-------------|
| `/bonin-danger-x-to-markdown` | Start X content conversion |

**Dependencies**: Chrome CDP

---

#### bonin-youtube-transcript

**Version**: 1.1.0 | **Triggers**: `YouTube字幕`, `YouTube transcript`, `download subtitles`, `get captions`

YouTube video transcript/subtitle downloader. Supports multiple languages, translation, chapter segmentation, and speaker identification.

| Command | Description |
|---------|-------------|
| `/bonin-youtube-transcript` | Start transcript download |
| `--languages zh,en,ja` | Specify language priority |
| `--no-timestamps` | Exclude timestamps |
| `--chapters` | Chapter segmentation |
| `--speakers` | Speaker identification |
| `--format srt` | Output SRT subtitle format |
| `--translate zh-Hans` | Translate to specified language |
| `--list` | List available transcripts |
| `--refresh` | Force re-fetch |

---

### V. Knowledge Skills

#### bonin-paper

**Version**: 4.7.0 | **Triggers**: `读论文`, `paper`, `论文`, `读这篇论文`

Paper reader for non-academics. Takes a paper and extracts its ideas for personal use. Focuses on understanding, not academic evaluation.

| Command | Description |
|---------|-------------|
| `/bonin-paper` | Start paper reading |
| Natural language | Provide an arXiv link, PDF, or paper title |

**Output**: Org-mode file to `~/Documents/notes/`

---

#### bonin-paper-flow

**Version**: 1.0.2 | **Triggers**: `论文流`, `paper flow`, `读论文做卡片`

Paper workflow: read papers + cast cards in one go. Takes arXiv links, paper URLs, PDFs, or paper names, automatically completes paper analysis and generates visual cards.

| Command | Description |
|---------|-------------|
| `/bonin-paper-flow` | Start paper workflow |

---

#### bonin-paper-river

**Version**: 1.0.0 | **Triggers**: `论文溯源`, `paper river`, `倒读论文`, `论文演化`

Paper reverse-reading method: given a paper, recursively finds the preceding papers it critiques and improves upon (up to 5 levels), then finds subsequent developments, narrating the problem evolution from the source. Feynman-style explanation of each paper's problem and innovation.

| Command | Description |
|---------|-------------|
| `/bonin-paper-river` | Start paper tracing |

---

#### bonin-learn

**Version**: 1.0.0 | **Triggers**: `学这个`, `learn`, `概念解剖`, `拆解概念`

Deep concept anatomist. Deconstructs any concept through 8 exploration dimensions (history, dialectics, phenomenology, etc.).

| Command | Description |
|---------|-------------|
| `/bonin-learn` | Start concept learning |

---

#### bonin-qa

**Version**: 1.0.0 | **Triggers**: `问答`, `Q&A`, `QA`, `提问`, `抽取问题`

Information question extractor. Given an article/paper/book, extracts core ideas into Q-A pairs — Questions cut to the heart, not textbook-style; Answers are concise and clear with complete logical chains.

| Command | Description |
|---------|-------------|
| `/bonin-qa` | Start Q-A extraction |

---

#### bonin-plain

**Version**: 5.0.0 | **Triggers**: `白话`, `plain`, `说人话`, `简单说`, `大白话`

Cognitive atom: Plain rewriter. Rewrites any content so a smart 12-year-old can understand it. Structure-free — form follows content.

| Command | Description |
|---------|-------------|
| `/bonin-plain` | Start plain rewriting |

---

#### bonin-rank

**Version**: 1.0.0 | **Triggers**: `降秩`, `找秩`, `秩是什么`, `背后是什么`

Rank reduction engine. Given a domain, finds the truly independent forces that support it. Reduces a dozen phenomena to irreducible generators — then verifies by regenerating each phenomenon from them.

| Command | Description |
|---------|-------------|
| `/bonin-rank` | Start rank reduction analysis |

---

#### bonin-think

**Version**: 1.0.0 | **Triggers**: `想透`, `追本`, `本质是什么`, `深挖`, `钻到底`, `think deep`

Arrow of tracing — vertical deep-drilling thinking tool. Given an opinion, phenomenon, or question, drills down like an arrow to the irreducible essence.

| Command | Description |
|---------|-------------|
| `/bonin-think` | Start deep thinking |

---

#### bonin-word

**Version**: 1.0.1 | **Triggers**: `单词`, `word`, `这个词`, `英语单词`

Deep-dive English word mastery tool. Deconstructs a single English word into core semantics and epiphany moments.

| Command | Description |
|---------|-------------|
| `/bonin-word` | Start word analysis |
| Natural language | Say "explain the word epiphany" |

---

#### bonin-word-flow

**Version**: 1.0.1 | **Triggers**: `词卡`, `word card`, `word flow`

Word flow: deep-dive word analysis + infograph card in one go. Takes one or more English words, runs bonin-word (generates deep semantics analysis) then bonin-card -i (generates infograph PNG).

| Command | Description |
|---------|-------------|
| `/bonin-word-flow` | Start word card workflow |

---

#### bonin-writes

**Version**: 6.3.0 | **Triggers**: `写`, `writes`, `写作`, `写一篇`

Writing engine. Dissects an opinion like a scalpel, peeling it layer by layer to the core. 1000-1500 words.

| Command | Description |
|---------|-------------|
| `/bonin-writes` | Start writing engine |

---

#### bonin-invest

**Version**: 1.0.0 | **Triggers**: `投资报告`, `投资分析`, `分析这个项目`, `investment report`

Investment analysis tool. Generates deep investment analysis reports. The core judgment is whether the project is an "order-creating machine."

| Command | Description |
|---------|-------------|
| `/bonin-invest` | Start investment analysis |

---

#### bonin-read

**Version**: 1.0.0 | **Triggers**: `伴读`, `陪我读`, `读这篇`, `read with me`

Reading companion agent. Accompanies user through any text (books, articles, essays, papers, news) with translation, structural annotation, deep questioning, and cross-domain insights. Auto-detects language, translates English to Chinese (faithfulness-expressiveness-elegance).

| Command | Description |
|---------|-------------|
| `/bonin-read` | Start companion reading mode |

---

#### bonin-relationship

**Version**: 1.0.0 | **Triggers**: `关系`, `relationship`, `人物关系`

Relationship analysis tool. Analyzes relationship networks between people, concepts, or entities.

| Command | Description |
|---------|-------------|
| `/bonin-relationship` | Start relationship analysis |

---

#### bonin-roundtable

**Version**: 1.0.0 | **Triggers**: `圆桌`, `roundtable`, `多人讨论`

Roundtable discussion tool. Simulates multiple experts engaging in deep discussion around a shared topic.

| Command | Description |
|---------|-------------|
| `/bonin-roundtable` | Start roundtable discussion |

---

#### bonin-travel

**Version**: 1.0.0 | **Triggers**: `旅行研究`, `博物馆功课`, `古建功课`, `travel research`

Deep travel research workflow. Input a city name to auto-generate a structured knowledge document (Org-mode) + portable reference cards (PNG). Covers historical background, museum highlights, archaeological significance, and architectural heritage.

| Command | Description |
|---------|-------------|
| `/bonin-travel` | Start travel research |

---

#### bonin-skill-map

**Version**: 1.0.0 | **Triggers**: `技能`, `skills`, `技能地图`, `skill map`, `列出技能`

Skill map viewer. Scans all installed skills and renders a visual overview — name, version, description, category at a glance.

| Command | Description |
|---------|-------------|
| `/bonin-skill-map` | Display skill map |

---

### VI. Deprecated Skills

> The following skills are kept functional but no longer actively maintained. Use the recommended replacements.

#### bonin-image-gen (Deprecated)

**Replacement**: [bonin-imagine](#bonin-imagine)

AI image generation tool, superseded by the more capable `bonin-imagine`.

---

#### bonin-xhs-images (Deprecated)

**Replacement**: [bonin-image-cards](#bonin-image-cards)

Xiaohongshu image card generator, superseded by `bonin-image-cards`.

---

## Environment Variables

| Variable | Description | Applicable Skills |
|----------|-------------|-------------------|
| `BONIN_CHROME_PROFILE_DIR` | Chrome user profile directory (overrides default path) | All CDP skills |
| `YOUTUBE_TRANSCRIPT_COOKIES_FROM_BROWSER` | Browser cookie source passed to yt-dlp | bonin-youtube-transcript |

---

## FAQ

### Q: How do I trigger a skill?

There are two ways:
1. **Command**: Type `/skill-name`, e.g., `/bonin-card`, `/bonin-translate`
2. **Natural language**: Use trigger phrases defined in each skill's description, e.g., "铸" (cast), "translate", "read this paper"

### Q: Do skills require internet access?

Some skills require internet:
- **Internet required**: bonin-fetch, bonin-translate, bonin-imagine, bonin-youtube-transcript, all publishing skills, all CDP skills
- **No internet needed**: bonin-paper, bonin-plain, bonin-writes, bonin-word, bonin-think, and other knowledge skills

### Q: Chrome CDP skills won't start?

1. Ensure Chrome or Chromium is installed
2. First-time use requires manual login to the corresponding website (X, Weibo, WeChat Official Account, etc.)
3. Use the `BONIN_CHROME_PROFILE_DIR` environment variable to specify a Chrome profile path

### Q: Image generation skills throw errors?

1. Check if an API Key is configured in EXTEND.md
2. Verify that the API Key's corresponding service is available
3. `bonin-imagine` supports multiple providers — try switching

### Q: How do I update skills?

```bash
cd bonin-skills
git pull
cp -r skills/bonin-* ~/.claude/skills/
```

Then restart Claude Code.

### Q: Where are output files saved?

| Skill Type | Output Location |
|------------|-----------------|
| bonin-card, bonin-present | `~/Downloads/` |
| bonin-paper, bonin-plain, bonin-writes | `~/Documents/notes/` |
| bonin-youtube-transcript | `youtube-transcript/` (current directory) |
| bonin-imagine | Images returned directly in conversation |

---

> 📖 Bonin Skills v1.114.0 | © Bonin AIGC | [Website](https://www.boninaigc.top) | [GitHub](https://github.com/BoninEDU/bonin-skills) | boninaigc@gmail.com
