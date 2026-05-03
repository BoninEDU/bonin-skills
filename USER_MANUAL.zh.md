# Bonin Skills 用户手册

> 版本：1.113.0 | 仓库：[github.com/BoninEDU/bonin-skills](https://github.com/BoninEDU/bonin-skills) | 邮箱：boninedu2025@gmail.com

---

## 目录

- [项目简介](#项目简介)
- [系统要求](#系统要求)
- [安装指南](#安装指南)
- [项目结构](#项目结构)
- [共享包](#共享包)
- [技能总览](#技能总览)
- [技能详细说明](#技能详细说明)
  - [内容与可视化技能](#一内容与可视化技能)
  - [AI 生成技能](#二ai-生成技能)
  - [发布技能](#三发布技能)
  - [工具技能](#四工具技能)
  - [知识技能](#五知识技能)
  - [已弃用技能](#六已弃用技能)
- [环境变量](#环境变量)
- [常见问题](#常见问题)

---

## 项目简介

**Bonin Skills** 是一套为 Claude Code 打造的技能集合插件，涵盖内容生成、AI 图像生成、论文阅读、内容发布、写作工具、知识分析等多个领域。每个技能都是自包含的独立目录，可单独安装到 `~/.claude/skills/` 以扩展 Claude Code 的能力。

本插件通过 Claude Code Marketplace 分发，也可手动安装使用。

---

## 系统要求

| 依赖 | 用途 | 必需/可选 |
|------|------|----------|
| **Claude Code** | 运行环境 | 必需 |
| **Bun** 或 **Node.js** | TypeScript 脚本运行时 | 必需（部分技能） |
| **Chrome / Chromium** | CDP 网页操作技能 | 可选（发布/抓取技能需要） |
| **Playwright** | HTML 截图生成 PNG | 可选（bonin-card 需要） |
| **图像生成 API Key** | AI 图像生成 | 可选（bonin-imagine 需要） |

---

## 安装指南

### 方式一：通过 Claude Code Marketplace 安装（推荐）

在 Claude Code 中直接安装 bonin-skills 插件，所有技能自动加载。

### 方式二：手动安装

```bash
# 1. 克隆仓库
git clone https://github.com/BoninEDU/bonin-skills.git

# 2. 复制技能到 Claude Code 目录
mkdir -p ~/.claude/skills
cp -r bonin-skills/skills/bonin-* ~/.claude/skills/

# 3. 重启 Claude Code 以加载技能
```

### 安装 bonin-card 依赖

`bonin-card` 需要 Playwright 进行 HTML 截图：

```bash
cd skills/bonin-card && npm install && npx playwright install chromium
```

### 安装 Bun 运行时

```bash
# macOS
brew install oven-sh/bun/bun

# 或通过 npm
npm install -g bun
```

---

## 项目结构

```
bonin-skills/
├── skills/                    # 所有技能目录
│   └── bonin-*/               # 每个技能一个目录
│       ├── SKILL.md           # 技能定义（YAML 前置 + 文档）
│       ├── references/        # 参考文档
│       ├── assets/            # 模板、图片、脚本
│       ├── scripts/           # 辅助脚本（bash, TypeScript）
│       └── prompts/           # 图像生成提示词
├── packages/                  # 共享包
│   ├── bonin-chrome-cdp/      # Chrome CDP 工具库
│   ├── bonin-fetch/           # URL 抓取与转换
│   └── bonin-md/              # Markdown 渲染与 HTML 转换
├── docs/                      # 开发者文档
├── screenshots/               # 风格参考截图
├── .claude-plugin/            # 插件配置
│   ├── marketplace.json       # Marketplace 插件定义
│   └── plugin.json            # 插件元数据
├── CLAUDE.md                  # Claude Code 架构指南
└── README.md                  # 项目说明
```

---

## 共享包

| 包名 | 说明 |
|------|------|
| **bonin-chrome-cdp** | Chrome DevTools Protocol 共享工具库，供 CDP 技能使用 |
| **bonin-fetch** | URL 抓取工具，通过 Chrome CDP 和站点适配器将网页转为 Markdown 或 JSON |
| **bonin-md** | Markdown 渲染与微信兼容 HTML 转换工具库 |

---

## 技能总览

| 分类 | 技能数 | 说明 |
|------|--------|------|
| 内容与可视化 | 8 | 图片、卡片、信息图、幻灯片、演讲 |
| AI 生成 | 2 | 多平台图像生成、Gemini Web |
| 发布 | 3 | X/Twitter、微信公众号、微博 |
| 工具 | 8 | 图片压缩、图表、格式化、翻译、URL 转换等 |
| 知识 | 17 | 论文阅读、概念学习、写作、投资分析等 |
| 已弃用 | 2 | 保留功能但不再维护 |

---

## 技能详细说明

### 一、内容与可视化技能

#### bonin-article-illustrator

**版本**：1.56.2 | **触发词**：`文章配图`、`article illustration`、`illustrate article`、`配图`

为文章生成 AI 插图，支持多种风格预设。分析文章内容后自动生成与段落匹配的插图。

| 命令 | 说明 |
|------|------|
| `/bonin-article-illustrator` | 启动文章配图流程 |
| 自然语言 | 说"给这篇文章配图"、"illustrate this" |

---

#### bonin-card

**版本**：2.2.0 | **触发词**：`铸`、`cast`、`做成图`、`做成卡片`、`视觉笔记`、`漫画`、`白板`、`大字`、`小红书卡片`

内容铸造器——将文本内容转化为 PNG 视觉图。支持七种模具：

| 模具 | 参数 | 说明 |
|------|------|------|
| 长阅读卡 | `-l`（默认） | 适合长文阅读的竖版卡片 |
| 信息图 | `-i` | 数据可视化信息图 |
| 多卡片 | `-m` | 1080×1440 多页阅读卡 |
| 编辑速记 | `-v` | 问题→失败→转折→洞见→命名，杂志+档案布局 |
| 漫画 | `-c` | 日漫风格黑白漫画 |
| 白板 | `-w` | 马克笔风格白板布局 |
| 大字附件卡 | `-b` | 1080×1440，碑刻风格，适合小红书 |

| 命令 | 说明 |
|------|------|
| `/bonin-card` | 默认长阅读卡模式 |
| `/bonin-card -i` | 信息图模式 |
| `/bonin-card -c` | 漫画模式 |
| `/bonin-card -w` | 白板模式 |
| `/bonin-card -b` | 大字附件卡模式 |
| `/bonin-card -v` | 编辑速记模式 |
| `/bonin-card -m` | 多卡片模式 |

**依赖**：Node.js + Playwright

---

#### bonin-comic

**版本**：1.56.2 | **触发词**：`漫画`、`comic`、`manga`、`连环画`、`四格漫画`

AI 漫画生成器，支持多种艺术风格。将故事内容转化为漫画分镜。

| 命令 | 说明 |
|------|------|
| `/bonin-comic` | 启动漫画生成流程 |
| 自然语言 | 说"画个漫画"、"生成漫画" |

---

#### bonin-cover-image

**版本**：1.56.2 | **触发词**：`封面`、`cover`、`cover image`、`封面图`

封面图片生成器。为文章、书籍或报告生成封面图。

| 命令 | 说明 |
|------|------|
| `/bonin-cover-image` | 启动封面生成流程 |

---

#### bonin-image-cards

**版本**：1.56.2 | **触发词**：`小红书图片`、`XHS images`、`RedNote`、`社交卡片`、`image cards`

社交媒体图片卡片生成器。将内容拆分为 1-10 张卡通风格图片卡片，支持 12 种视觉风格、8 种布局、3 种配色方案。

| 命令 | 说明 |
|------|------|
| `/bonin-image-cards` | 启动图片卡片生成流程 |

---

#### bonin-infographic

**版本**：1.57.1 | **触发词**：`信息图`、`infographic`、`数据可视化`、`图表`

专业信息图生成器。支持 21 种布局类型和 21 种视觉风格，自动分析内容并推荐最佳布局×风格组合。

| 命令 | 说明 |
|------|------|
| `/bonin-infographic` | 启动信息图生成流程 |

---

#### bonin-slide-deck

**版本**：1.56.2 | **触发词**：`slides`、`PPT`、`幻灯片`、`演示文稿`、`slide deck`

专业幻灯片生成器。从内容创建大纲和风格说明，然后逐张生成幻灯片图片。

| 命令 | 说明 |
|------|------|
| `/bonin-slide-deck` | 启动幻灯片生成流程 |

---

#### bonin-present

**版本**：2.0.0 | **触发词**：`高桥流`、`讲这个`、`present`、`做成演讲`、`标语流`、`宣言体`、`slogan`

演讲铸造器。两种风格：

| 风格 | 参数 | 说明 |
|------|------|------|
| 高桥流 | 默认 | 一页一词、墨字奶白底、单字撑满屏 |
| 标语流 | `-s` | 口号体宣言风、黑红黄大色块、ultra-bold 错位多行、含休止页 |

| 命令 | 说明 |
|------|------|
| `/bonin-present` | 高桥流模式 |
| `/bonin-present -s` | 标语流模式 |

**输出**：单文件 HTML 到 `~/Downloads/`

---

### 二、AI 生成技能

#### bonin-imagine

**版本**：1.107.0 | **触发词**：`imagine`、`生成图片`、`画图`、`generate image`、`AI绘图`

多平台 AI 图像生成后端。支持以下提供商：

| 提供商 | 模型 |
|--------|------|
| OpenAI | GPT Image 2、DALL-E 3 |
| Azure OpenAI | GPT Image 2 |
| Google | Imagen 3 |
| OpenRouter | 多模型 |
| DashScope（通义万相） | 多模型 |
| Z.AI | GLM-Image |
| MiniMax | 多模型 |
| Replicate | 多模型 |

| 命令 | 说明 |
|------|------|
| `/bonin-imagine` | 启动图像生成流程 |
| 自然语言 | 说"画一张..."、"generate an image of..." |

**配置**：需要在 EXTEND.md 中配置 API Key

---

#### bonin-danger-gemini-web

**版本**：1.56.1 | **触发词**：`gemini web`、`问 Gemini`、`Gemini搜索`

通过 Chrome CDP 访问 Gemini Web。首次运行需登录 Google 账号。

| 命令 | 说明 |
|------|------|
| `/bonin-danger-gemini-web` | 启动 Gemini Web 问答 |
| `--login` | 刷新登录状态 |

**依赖**：Chrome + Google 账号 Cookie

---

### 三、发布技能

#### bonin-post-to-x

**版本**：1.56.2 | **触发词**：`发推特`、`post to X`、`发X`、`tweet`

发布内容到 X (Twitter)。支持普通帖子（含图片/视频）和 X Articles（长文 Markdown）。

| 命令 | 说明 |
|------|------|
| `/bonin-post-to-x` | 启动 X 发布流程 |

**依赖**：Chrome CDP + X 账号登录

---

#### bonin-post-to-wechat

**版本**：1.56.1 | **触发词**：`发微信`、`post to WeChat`、`公众号`、`微信公众号`

发布内容到微信公众号。支持文章发布（HTML/Markdown）和草稿管理。

| 命令 | 说明 |
|------|------|
| `/bonin-post-to-wechat` | 启动微信公众号发布流程 |

**依赖**：Chrome CDP + 微信公众号后台

---

#### bonin-post-to-weibo

**版本**：1.56.1 | **触发词**：`发微博`、`post to Weibo`、`微博`

发布内容到微博。支持普通帖子（文字+图片+视频）和头条文章（Markdown 长文）。

| 命令 | 说明 |
|------|------|
| `/bonin-post-to-weibo` | 启动微博发布流程 |

**依赖**：Chrome CDP + 微博账号登录

---

### 四、工具技能

#### bonin-compress-image

**版本**：1.56.1 | **触发词**：`压缩图片`、`compress image`、`图片压缩`、`optimize image`

图片压缩工具。支持 PNG、JPEG、WebP 格式，可调节压缩质量。

| 命令 | 说明 |
|------|------|
| `/bonin-compress-image` | 启动图片压缩流程 |

**依赖**：Node.js + Sharp

---

#### bonin-diagram

**版本**：1.56.1 | **触发词**：`图表`、`diagram`、`流程图`、`Mermaid`

图表生成器。使用 Mermaid 语法生成流程图、时序图、甘特图等。

| 命令 | 说明 |
|------|------|
| `/bonin-diagram` | 启动图表生成流程 |

---

#### bonin-format-markdown

**版本**：1.56.1 | **触发词**：`格式化`、`format markdown`、`排版`、`整理格式`

Markdown 格式化工具。自动整理和规范 Markdown 文档格式。

| 命令 | 说明 |
|------|------|
| `/bonin-format-markdown` | 启动格式化流程 |

---

#### bonin-markdown-to-html

**版本**：1.56.1 | **触发词**：`转HTML`、`markdown to html`、`MD转HTML`、`微信格式`

Markdown 转 HTML 工具。支持代码高亮、数学公式、PlantUML、脚注等，提供微信兼容主题。

| 命令 | 说明 |
|------|------|
| `/bonin-markdown-to-html` | 启动转换流程 |

---

#### bonin-translate

**版本**：1.59.0 | **触发词**：`翻译`、`translate`、`精翻`、`快翻`、`本地化`

文章与文档翻译工具。三种翻译模式：

| 模式 | 说明 |
|------|------|
| 快速翻译（quick） | 直接翻译 |
| 标准翻译（normal） | 分析后翻译 |
| 精细翻译（refined） | 分析→翻译→审校→润色 |

支持自定义术语表（通过 EXTEND.md）和术语一致性检查。

| 命令 | 说明 |
|------|------|
| `/bonin-translate` | 启动翻译流程 |
| 自然语言 | 说"翻译这篇文章"、"translate to Chinese" |

---

#### bonin-url-to-markdown

**版本**：1.61.0 | **触发词**：`保存网页`、`url to markdown`、`网页转MD`、`抓取网页`

URL 转 Markdown 工具。使用 bonin-fetch CLI（Chrome CDP + 站点适配器），内置 X/Twitter、YouTube 字幕、Hacker News 和通用页面适配器。

| 命令 | 说明 |
|------|------|
| `/bonin-url-to-markdown` | 启动 URL 抓取流程 |

**依赖**：Chrome CDP

---

#### bonin-danger-x-to-markdown

**版本**：1.56.1 | **触发词**：`X转MD`、`x to markdown`、`推特转Markdown`

X/Twitter 内容转 Markdown 工具。将推文线程、文章等转为 Markdown 格式。

| 命令 | 说明 |
|------|------|
| `/bonin-danger-x-to-markdown` | 启动 X 内容转换 |

**依赖**：Chrome CDP

---

#### bonin-youtube-transcript

**版本**：1.1.0 | **触发词**：`YouTube字幕`、`YouTube transcript`、`视频字幕`、`download subtitles`

YouTube 视频字幕/文稿下载器。支持多语言、翻译、章节分割和说话人识别。

| 命令 | 说明 |
|------|------|
| `/bonin-youtube-transcript` | 启动字幕下载 |
| `--languages zh,en,ja` | 指定语言优先级 |
| `--no-timestamps` | 不含时间戳 |
| `--chapters` | 按章节分割 |
| `--speakers` | 说话人识别 |
| `--format srt` | 输出 SRT 字幕格式 |
| `--translate zh-Hans` | 翻译为指定语言 |
| `--list` | 列出可用字幕 |
| `--refresh` | 强制重新获取 |

---

### 五、知识技能

#### bonin-paper

**版本**：4.7.0 | **触发词**：`读论文`、`paper`、`论文`、`读这篇论文`

论文阅读器（面向非学术人士）。提取论文核心思想供个人使用，注重理解而非学术评价。

| 命令 | 说明 |
|------|------|
| `/bonin-paper` | 启动论文阅读 |
| 自然语言 | 提供 arXiv 链接、PDF 或论文标题 |

**输出**：Org-mode 格式文件到 `~/Documents/notes/`

---

#### bonin-paper-flow

**版本**：1.0.2 | **触发词**：`论文流`、`paper flow`、`读论文做卡片`

论文工作流：读论文 + 铸卡片一步到位。输入 arXiv 链接、论文 URL、PDF 或论文名，自动完成论文分析并生成视觉卡片。

| 命令 | 说明 |
|------|------|
| `/bonin-paper-flow` | 启动论文工作流 |

---

#### bonin-paper-river

**版本**：1.0.0 | **触发词**：`论文溯源`、`paper river`、`倒读论文`、`论文演化`

论文倒读法：给定一篇论文，递归找出它批判和改进的前序论文（最多5层），再找它之后的最新进展，从源头正向讲述问题演化史。以问题为轴，费曼式讲解每篇论文看到的问题和解法创新。

| 命令 | 说明 |
|------|------|
| `/bonin-paper-river` | 启动论文溯源 |

---

#### bonin-learn

**版本**：1.0.0 | **触发词**：`学这个`、`learn`、`概念解剖`、`拆解概念`

深度概念解剖器。通过 8 个探索维度（历史、辩证、现象学等）解构任何概念。

| 命令 | 说明 |
|------|------|
| `/bonin-learn` | 启动概念学习 |

---

#### bonin-qa

**版本**：1.0.0 | **触发词**：`问答`、`Q&A`、`QA`、`提问`、`抽取问题`

信息提问机。给一篇文章/论文/书，把核心观点抽成 Q-A 对——Question 切要害，不教科书；Answer 简洁清晰，逻辑链完整。

| 命令 | 说明 |
|------|------|
| `/bonin-qa` | 启动 Q-A 抽取 |

---

#### bonin-plain

**版本**：5.0.0 | **触发词**：`白话`、`plain`、`说人话`、`简单说`、`大白话`

认知原子：白话重写器。将任何内容重写为让聪明的 12 岁孩子也能理解的语言。无固定结构——形式跟随内容。

| 命令 | 说明 |
|------|------|
| `/bonin-plain` | 启动白话重写 |

---

#### bonin-rank

**版本**：1.0.0 | **触发词**：`降秩`、`找秩`、`秩是什么`、`背后是什么`

降秩引擎。给一个领域，找出背后真正撑着它的几根独立的力。十几个现象砍到不可再少的生成器——砍完能把现象一个个生回来，才算数。

| 命令 | 说明 |
|------|------|
| `/bonin-rank` | 启动降秩分析 |

---

#### bonin-think

**版本**：1.0.0 | **触发词**：`想透`、`追本`、`本质是什么`、`深挖`、`钻到底`、`think deep`

追本之箭——纵向深钻思维工具。给一个观点、现象或问题，像箭一样一路向下钻到不可再分的本质。

| 命令 | 说明 |
|------|------|
| `/bonin-think` | 启动深度思考 |

---

#### bonin-word

**版本**：1.0.1 | **触发词**：`单词`、`word`、`这个词`、`英语单词`

英语单词深度解析工具。将单个英语单词拆解为核心语义和顿悟时刻。

| 命令 | 说明 |
|------|------|
| `/bonin-word` | 启动单词解析 |
| 自然语言 | 说"解释一下 epiphany 这个词" |

---

#### bonin-word-flow

**版本**：1.0.1 | **触发词**：`词卡`、`word card`、`word flow`

单词工作流：深度解析 + 信息图卡片一步到位。输入一个或多个英语单词，先运行 bonin-word 生成深度语义分析，再运行 bonin-card -i 生成信息图 PNG。

| 命令 | 说明 |
|------|------|
| `/bonin-word-flow` | 启动词卡工作流 |

---

#### bonin-writes

**版本**：6.3.0 | **触发词**：`写`、`writes`、`写作`、`写一篇`

写作引擎。像手术刀剖开一个观点，一层层剥到底。1000-1500 字。

| 命令 | 说明 |
|------|------|
| `/bonin-writes` | 启动写作引擎 |

---

#### bonin-invest

**版本**：1.0.0 | **触发词**：`投资报告`、`投资分析`、`分析这个项目`、`investment report`

投资分析工具。生成深度投资分析报告。核心判断是项目是否是一台「秩序创造机器」。

| 命令 | 说明 |
|------|------|
| `/bonin-invest` | 启动投资分析 |

---

#### bonin-read

**版本**：1.0.0 | **触发词**：`伴读`、`陪我读`、`读这篇`、`read with me`

阅读伴侣。陪伴用户阅读任何文本（书籍、文章、论文、新闻），提供翻译、结构标注、深度提问和跨领域洞见。自动检测语言，英文翻译为中文（信达雅）。

| 命令 | 说明 |
|------|------|
| `/bonin-read` | 启动伴读模式 |

---

#### bonin-relationship

**版本**：1.0.0 | **触发词**：`关系`、`relationship`、`人物关系`

关系分析工具。分析人物、概念或实体之间的关系网络。

| 命令 | 说明 |
|------|------|
| `/bonin-relationship` | 启动关系分析 |

---

#### bonin-roundtable

**版本**：1.0.0 | **触发词**：`圆桌`、`roundtable`、`多人讨论`

圆桌讨论工具。模拟多位专家围绕同一主题展开深度讨论。

| 命令 | 说明 |
|------|------|
| `/bonin-roundtable` | 启动圆桌讨论 |

---

#### bonin-travel

**版本**：1.0.0 | **触发词**：`旅行研究`、`博物馆功课`、`古建功课`、`travel research`

深度旅行研究工具。输入城市名称，自动生成结构化知识文档（Org-mode）+ 便携参考卡片（PNG）。涵盖历史背景、博物馆亮点、考古意义和建筑遗产。

| 命令 | 说明 |
|------|------|
| `/bonin-travel` | 启动旅行研究 |

---

#### bonin-skill-map

**版本**：1.0.0 | **触发词**：`技能`、`skills`、`技能地图`、`skill map`、`列出技能`

技能地图查看器。扫描所有已安装技能并渲染可视化概览——名称、版本、描述、分类一目了然。

| 命令 | 说明 |
|------|------|
| `/bonin-skill-map` | 显示技能地图 |

---

### 六、已弃用技能

> 以下技能保留功能但不再主动维护，建议使用替代技能。

#### bonin-image-gen（已弃用）

**替代**：[bonin-imagine](#bonin-imagine)

AI 图像生成工具，已被功能更强大的 `bonin-imagine` 取代。

---

#### bonin-xhs-images（已弃用）

**替代**：[bonin-image-cards](#bonin-image-cards)

小红书图片卡片生成器，已被 `bonin-image-cards` 取代。

---

## 环境变量

| 变量名 | 说明 | 适用技能 |
|--------|------|----------|
| `BONIN_CHROME_PROFILE_DIR` | Chrome 用户配置文件目录（覆盖默认路径） | 所有 CDP 技能 |
| `YOUTUBE_TRANSCRIPT_COOKIES_FROM_BROWSER` | 传递给 yt-dlp 的浏览器 Cookie 来源 | bonin-youtube-transcript |

---

## 常见问题

### Q: 如何触发技能？

有两种方式：
1. **命令方式**：输入 `/技能名`，如 `/bonin-card`、`/bonin-translate`
2. **自然语言**：使用技能描述中的触发词，如"铸"、"翻译"、"读论文"

### Q: 技能需要联网吗？

部分技能需要联网：
- **需要联网**：bonin-fetch、bonin-translate、bonin-imagine、bonin-youtube-transcript、所有发布技能、所有 CDP 技能
- **不需要联网**：bonin-paper、bonin-plain、bonin-writes、bonin-word、bonin-think 等知识技能

### Q: Chrome CDP 技能无法启动？

1. 确保已安装 Chrome 或 Chromium
2. 首次使用需手动登录对应网站（X、微博、微信公众号等）
3. 可通过 `BONIN_CHROME_PROFILE_DIR` 环境变量指定 Chrome 配置文件路径

### Q: 图像生成技能报错？

1. 检查是否在 EXTEND.md 中配置了 API Key
2. 确认 API Key 对应的服务可用
3. `bonin-imagine` 支持多个提供商，可切换尝试

### Q: 如何更新技能？

```bash
cd bonin-skills
git pull
cp -r skills/bonin-* ~/.claude/skills/
```

然后重启 Claude Code。

### Q: 输出文件保存在哪里？

| 技能类型 | 输出位置 |
|----------|----------|
| bonin-card、bonin-present | `~/Downloads/` |
| bonin-paper、bonin-plain、bonin-writes | `~/Documents/notes/` |
| bonin-youtube-transcript | `youtube-transcript/`（当前目录） |
| bonin-imagine | 图像直接在对话中返回 |

---

> 📖 Bonin Skills v1.113.0 | © BoninEDU | [GitHub](https://github.com/BoninEDU/bonin-skills)
