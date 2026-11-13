# bonin-skills

Bonin AIGC 分享的 AI Agent 技能集，共 **48 个技能**，适用于 Claude Code、Codex、Trae、WorkBuddy、CodeBuddy、Gemini CLI 等支持 `SKILL.md` 的 Agent。

## Bonin AIGC

> **成就超级个体和团队** — Empower Super-Individuals and Super-Teams

- 官方网站：[https://www.boninaigc.top](https://www.boninaigc.top)
- 邮箱：boninaigc@gmail.com
- GitHub：[BoninEDU](https://github.com/BoninEDU)

## 安装

仓库默认分支为 `main`，内容为 Markdown（`.md`），无需再切换 `#md` 分支。

使用 [skills CLI](https://github.com/vercel-labs/skills)（基于 `npx`）安装：

```bash
# 安装全部技能（全局）
npx skills add BoninEDU/bonin-skills -g --all

# 安装单个技能
npx skills add BoninEDU/bonin-skills -g --skill bonin-card

# 安装多个指定技能
npx skills add BoninEDU/bonin-skills -g --skill bonin-card --skill bonin-learn

# 查看仓库中有哪些技能
npx skills add BoninEDU/bonin-skills -l
```

**参数说明：**

| 参数 | 作用 |
|------|------|
| `-g` | 全局安装到 `~/.claude/skills/`（推荐）。不加则装到当前项目 `.claude/skills/` |
| `--skill <name>` | 指定安装某个技能，可重复使用 |
| `--all` | 安装仓库内全部技能 |
| `-l` | 仅列出可用技能，不安装 |

### 各 Agent 的技能目录

`npx skills add` 会自动识别常见 Agent 布局；也可以把技能目录链接到下列位置：

| Agent | 技能目录 |
|-------|----------|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| Trae / Trae CN | `~/.trae/skills/`、`~/.trae-cn/skills/` |
| CodeBuddy | `~/.codebuddy/skills/` |
| WorkBuddy | `~/.agents/skills/`（WorkBuddy 读取该目录） |
| Gemini CLI | `~/.gemini/skills/` |

Windows PowerShell 创建目录链接示例：

```powershell
New-Item -ItemType Junction `
  -Path "$env:USERPROFILE\.claude\skills\bonin-stickman-video-director" `
  -Target "D:\repo\bonin-skills\skills\bonin-stickman-video-director"
```

### bonin-card 依赖

`bonin-card` 依赖 Playwright 截图，安装后需额外执行：

```bash
cd ~/.claude/skills/bonin-card && npm install && npx playwright install chromium
```

### bonin-stickman-video-director 依赖

导演模式（A1–A5）不需要运行时。A6 与 Autopilot（B1–B5）需要：

```bash
cd ~/.claude/skills/bonin-stickman-video-director/skills/directing-stickman-videos
npm ci
npm run doctor
```

- Node.js ≥ 20
- FFmpeg / FFprobe
- Python 3（仅 A6 脚本）
- 可选 `GEMINI_API_KEY`（付费生成前须先报价并取得授权）

### 替代方式：git clone

```bash
git clone https://github.com/BoninEDU/bonin-skills.git ~/.claude/plugins/bonin-skills
```

## 技能

### 内容与可视化（11）

| 技能 | 说明 |
|------|------|
| **bonin-article-illustrator** | 文章配图 — 按 Type × Style × Palette 为文章段落生成插图 |
| **bonin-card** | 内容铸卡 — 将内容转为 PNG 视觉卡片（长图 `-l`、信息图 `-i`、多卡 `-m`、视觉笔记 `-v`、漫画 `-c`、白板 `-w`、大字 `-b`） |
| **bonin-comic** | 知识漫画 — 多画风、多格布局的原创教育漫画 |
| **bonin-cover-image** | 封面图 — 组合 11 种配色与 7 种渲染风格生成文章封面（2.35:1 / 16:9 / 1:1） |
| **bonin-handraw-style** | 手绘风格技能集合 — 插画规划、情侣照编排、个人书库等子技能 |
| **bonin-image-cards** | 图文卡系列 — 12 种风格、8 种布局的小红书/微信图文卡片 |
| **bonin-infographic** | 信息图 — 21 种布局 × 22 种视觉风格的可发布信息图 |
| **bonin-present** | 演讲铸造器 — 默认高桥流；`-s` 标语流 |
| **bonin-slide-deck** | 幻灯片 — 从内容生成大纲、风格说明与逐张幻灯片图片 |
| **bonin-stickman-video-director** | 火柴人视频导演（第 48 个技能）— Director（A1–A5）、A6 Amber Noir、Autopilot（B1–B5）；MIT 上游署名保留 |
| **bonin-xhs-images** | 小红书图片卡（已由 `bonin-image-cards` 取代，保留兼容） |

### 知识与思维（16）

| 技能 | 说明 |
|------|------|
| **bonin-book** | 拆书 — 以「问题」为轴心，收尾一张 ASCII 参考系图 |
| **bonin-book-to-skill** | 书籍转技能工具包 — PDF 解析、技能生成与批处理脚本 |
| **bonin-invest** | 投资分析 — 核心判断项目是否是一台「秩序创造机器」 |
| **bonin-learn** | 概念解剖 — 八个方向切开一个概念，压成一句顿悟 |
| **bonin-library** | 取景框借书卡 — 一本书 → 一幅意向画面 → 一张 2050 图书馆借书卡（PNG） |
| **bonin-paper** | 论文阅读 — 为非学术人士提取论文核心想法 |
| **bonin-paper-flow** | 论文工作流 — `bonin-paper` → `bonin-library` 一气呵成 |
| **bonin-paper-river** | 论文溯源 — 倒读法递归挖前序论文（最多 5 层）+ 最新进展 |
| **bonin-plain** | 白话引擎 — 改写到聪明的十二岁小孩也能懂 |
| **bonin-qa** | 信息提问机 — 把核心观点抽成 Q-A 链 |
| **bonin-rank** | 降秩引擎 — 找出一个领域背后不可再少的独立生成器 |
| **bonin-read** | 伴读 — 翻译、结构标注、深度提问与跨领域旁逸 |
| **bonin-think** | 追本之箭 — 纵向深钻到不可再分的本质 |
| **bonin-word** | 单词精通 — 拆解英语单词的核心语义与顿悟时刻 |
| **bonin-word-flow** | 单词工作流 — `bonin-word` → `bonin-card -i` |
| **bonin-writes** | 写作引擎 — 1000–1500 字，一层层剥到底 |

### 对话与关系（3）

| 技能 | 说明 |
|------|------|
| **bonin-relationship** | 关系分析 — 五层结构诊断 + 精神分析 |
| **bonin-roundtable** | 圆桌讨论 — 求真导向的结构化多人辩证对话 |
| **bonin-travel** | 旅行研究 — 城市深度文化研究文档（Markdown）+ 便携卡片（PNG） |

### 发布（3）

| 技能 | 说明 |
|------|------|
| **bonin-post-to-wechat** | 微信公众号 — 文章与贴图发布（API 或 Chrome CDP） |
| **bonin-post-to-weibo** | 微博 — 普通微博与头条文章 |
| **bonin-post-to-x** | X / Twitter — 普通推文与 X Articles |

### AI 生成（3）

| 技能 | 说明 |
|------|------|
| **bonin-danger-gemini-web** | Gemini Web 逆向适配器 — 文本、图像与多轮对话 |
| **bonin-image-gen** | 多平台图像生成（已弃用，保留功能） |
| **bonin-imagine** | 多平台图像生成 — OpenAI、Azure、Gemini、OpenRouter、DashScope、Z.ai、MiniMax、Seedream、Replicate 等 |

### 工具（11）

| 技能 | 说明 |
|------|------|
| **bonin-compress-image** | 图片压缩 — 默认 WebP，可转 PNG |
| **bonin-danger-x-to-markdown** | X 转 Markdown — 推文与长文带 YAML front matter |
| **bonin-diagram** | 图表 — 深色主题架构图、流程图、时序图、思维导图等 SVG |
| **bonin-electron-extract** | Electron 逆向 — 从 `.asar` 提取资源与 JavaScript |
| **bonin-format-markdown** | Markdown 格式化 — 标题、摘要、层级、列表与代码块 |
| **bonin-markdown-to-html** | Markdown 转 HTML — 公众号兼容主题、代码高亮、Mermaid 等 |
| **bonin-skill-map** | 技能地图 — 扫描并可视化所有已安装技能 |
| **bonin-translate** | 精翻 — 中英互译与译文校对 |
| **bonin-url-to-markdown** | URL 转 Markdown — Chrome CDP + 站点适配器 |
| **bonin-wechat-summary** | 群聊精华 — 微信群聊结构化简报（正常版 / 毒舌版） |
| **bonin-youtube-transcript** | YouTube 字幕 — 多语言字幕、翻译、章节与封面 |

### 维护（1）

| 技能 | 说明 |
|------|------|
| **bonin-push** | 推送引擎 — 把本地 `~/.claude/skills/bonin-*` 同步到 GitHub 仓库 |

## 工作流

工作流将多个技能串联为一个命令。

| 工作流 | 技能链 | 说明 |
|--------|--------|------|
| **bonin-paper-flow** | bonin-paper → bonin-library | 读论文 + 铸取景框借书卡一气呵成 |
| **bonin-word-flow** | bonin-word → bonin-card -i | 单词深度分析 + 信息图卡片一气呵成 |

## 输出格式

全仓库统一使用 Markdown（`.md`）。`main` 是唯一维护分支；历史 `md` 分支不再更新，安装时无需指定分支。
