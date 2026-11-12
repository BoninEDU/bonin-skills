# bonin-stickman-video-director · 火柴人视频导演

把选题、需求、文章或脚本，做成带旁白、字幕、插画与微动效的火柴人视频。
本目录是 Bonin Skills 的第 48 个技能，完整移植自上游开源项目
[stickman-video-director](https://github.com/kaomei/stickman-video-director)（MIT，见 [LICENSE](LICENSE)）。

- 安装入口（本文件上级的 `SKILL.md`）：`bonin-stickman-video-director`
- 操作契约（真正的技能定义）：[skills/directing-stickman-videos/SKILL.md](skills/directing-stickman-videos/SKILL.md)

## 两种模式

| 模式 | 产物 | 说明 |
|------|------|------|
| **A · Director（A1–A5）** | 已确认分镜 + 独立视频提示词 | 5 段式叙事结构，约 10 秒/段，默认 60 秒 6 段；含 Style 1–5 画风 |
| **A6 · Amber Noir** | 参考图驱动的成片 | 参考锁、Gemini Puck 旁白、收尾规范 |
| **B · Autopilot（B1–B5）** | 本地渲染成片（旁白+字幕+插画+动效+音效） | B1 极简手绘 / B2 彩色手绘 / B3 复古电视 / B4 求生短剧 / B5 角色解说 |

导演模式只产出提案与提示词，不需要 Node/FFmpeg/API Key；B 模式才需要本地运行时。

## 目录结构

```text
skills/bonin-stickman-video-director/
├── SKILL.md                     # Bonin 安装入口路由
├── README.md                    # 本文件
├── LICENSE                      # 上游 MIT 许可证（原样保留）
├── CHANGELOG.zh-CN.md           # 上游更新记录
├── docs/superpowers/            # 上游设计/实施文档
├── tests/                       # 上游仓库级校验脚本与场景（见“验证”）
└── skills/directing-stickman-videos/
    ├── SKILL.md                 # 操作契约（上游技能名保持不变）
    ├── references/              # 画风、叙事、音频、QA 规范
    ├── scripts/                 # Autopilot 运行时、A6 收尾、媒体适配
    ├── assets/                  # B1–B5 参考图、字体、基准样本、授权文件
    ├── examples/                # 示例项目
    ├── tests/                   # 单元测试与 fixtures
    ├── package.json             # 运行时依赖：@napi-rs/canvas、sharp
    └── package-lock.json
```

## 安装

```bash
# 只安装本技能
npx skills add BoninEDU/bonin-skills -g --skill bonin-stickman-video-director

# 或从仓库直接安装到本机技能目录
git clone https://github.com/BoninEDU/bonin-skills.git
```

安装后，`SKILL.md` 作为入口自动路由到 `skills/directing-stickman-videos/SKILL.md`。

### 运行时依赖（仅 B 模式 / A6 脚本需要）

```bash
cd ~/.claude/skills/bonin-stickman-video-director/skills/directing-stickman-videos
npm ci
npm run doctor
```

- Node.js ≥ 20
- FFmpeg / FFprobe（不配也能从 PATH 查找；可通过 `FFMPEG` / `FFPROBE` 环境变量指定完整路径）
- Python 3（仅 A6 的 `a6_reference_check.py`、`a6_finish.py` 需要）
- 字体：内置 `assets/fonts/` 覆盖拉丁字符；中日韩等语言请用 `AUTOPILOT_FONT` 指定系统字体
- 生成服务：内置 Gemini 适配器读取 `GEMINI_API_KEY`（不要粘贴到对话）。其他服务如需接入，在 `scripts/gemini-media.mjs` 旁新增同名适配器即可（接口契约：`--allow-network --model --output --text/--prompt [--reference]`，输出 native 媒体 + `.request.json` 收据）。付费调用前必须先报价并取得授权。

### 环境变量速查

完整示例见 [.env.example](.env.example)；`.env` 已被 `.gitignore` 忽略，密钥放本地。

| 变量 | 必填 | 说明 |
|------|:----:|------|
| `GEMINI_API_KEY` | 仅 B 模式/A6 | Gemini API Key；director 模式（A1–A5）不需要任何 Key |
| `FFMPEG` / `FFPROBE` | 否 | ffmpeg/ffprobe 完整路径；不配用 PATH 查找 |
| `AUTOPILOT_FONT` | 否 | 自定义字体路径；不配用包内 Caveat.ttf（拉丁字符覆盖） |
| `XDG_CACHE_HOME` | 否 | Python Whisper 缓存目录覆盖 |

PowerShell 示例（当前会话生效）：

```powershell
$env:GEMINI_API_KEY="AIzaSy..."
$env:FFMPEG="C:\ffmpeg\bin\ffmpeg.exe"
npm run doctor
```

bash 示例：

```bash
export GEMINI_API_KEY="AIzaSy..."
export FFMPEG="/usr/local/bin/ffmpeg"
npm run doctor
```

## 使用

在对话里直接提出需求即可，例如：

- “用 B1 画风做一条 60 秒、9:16 的《为什么越努力越焦虑》火柴人视频”
- “把这篇公众号文章改成分镜，Style 4，90 秒，16:9”
- “用 A6 参考这条视频的风格，做一支 30 秒产品短片”

画风样片目录（上游公开 README）：[导演模式](https://github.com/kaomei/stickman-video-director/blob/main/README.zh-CN.md#a-styles) ·
[全自动模式](https://github.com/kaomei/stickman-video-director/blob/main/README.zh-CN.md#b-styles)。

## 验证（2026-11-10 至 2026-11-12 实跑记录）

| 项目 | 结果 |
|------|------|
| 依赖安装 `npm ci` | 成功（10 packages） |
| 自检 `npm run doctor` | `node/ffmpeg/ffprobe/canvas/sharp/fonts` 全部 `true`；`gemini_key_present: false`（未配置，属预期） |
| Node 单元测试 `node --test tests/*.test.mjs` | 120 项：**120 通过 / 0 失败**（2026-11-10 修复后。最初 84/36，成因有二：① 仓库 `core.autocrlf=true` 把指纹锁定的 LF 文本转成 CRLF，导致 33 项指纹/跨行断言失败——已通过本目录 `.gitattributes`（`* -text`）修复；② 符号链接 EPERM 3 项——已开启 Windows 开发者模式修复） |
| Python 单测 `python -m unittest discover -s tests -p 'test_a6_references.py'` | 20 项：**20 通过 / 0 失败**（同上，开发者模式开启后符号链接用例通过） |
| 仓库级校验 `tests/verify-*.py` | 8 个脚本全部通过；`verify-a6-finishing` 与 A6 渲染器已增加 Windows 字体候选，并于 2026-11-12 前实跑通过 |
| GitHub 在线安装 | `npx skills add BoninEDU/bonin-skills --skill bonin-stickman-video-director --agent codex --copy -y` 在干净目录落盘 233 个文件；安装副本 `npm ci` 成功且 `npm run doctor` 六项检查全部为 `true`（2026-11-12） |

未验证项：真实付费生成链路（图片/语音/视频服务）、B4/B5 整片渲染的完整端到端流程（需要真实素材与授权调用）。上述状态如实标注，不代表“已调试可用”。

## 与上游的差异

1. 顶层新增 Bonin 安装入口 `SKILL.md` 与本 README；包内技能名 `directing-stickman-videos` 保持不变（安装布局与回归测试依赖该名称）。
2. 未移植 `assets/readme`（约 210 MB 营销预览 GIF/MP4）、`assets/sponsors`（赞助商图）、9 个多语言 README 及上游 README 预览优化脚本：属推广/大体积二进制，按 Bonin 品牌与仓库体积规则排除。画风样片仍通过上方上游链接访问。
3. 移除 Renoise MCP 链接中的推广追踪参数（`utm_source` / `utm_medium`），保留基础安装地址。
4. 未移植依赖上游 README / 营销媒体 / git 历史的 6 个校验脚本（`verify-chinese-onboarding`、`verify-localized-readmes`、`verify-thumbnail-kit`、`verify-voice-continuity`、`verify-first-use-guidance`、`verify-readmes.sh`）与 `tests/reports/`（上游历史审计快照）；`verify-cozy-storytelling.py` 删除营销 GIF 断言，保留全部规划逻辑校验。
5. `LICENSE`、B1 素材授权说明、B5 素材致谢、字体 OFL 与 Lucide 许可证原样保留：MIT 与第三方资产许可要求保留版权声明。
6. 新增 `.gitattributes`（`* -text`）：上游 manifest 的 SHA-256 指纹按 LF 字节计算，且部分测试按字面 `\n` 做跨行匹配；禁用本目录内所有行尾转换，保证检出文件与上游 Linux CI 字节一致。

## 许可与署名

- 本技能代码与文档：MIT，Copyright (c) 2026 Stickman Video Director contributors（见 [LICENSE](LICENSE)）。
- 上游项目：https://github.com/kaomei/stickman-video-director
- 第三方资产：见 [B1 素材授权说明](skills/directing-stickman-videos/assets/b1/ATTRIBUTION.md)、
  [B5 素材致谢](skills/directing-stickman-videos/assets/b5/CREDITS.md)、
  字体目录下的 OFL 许可文件与 [Lucide 许可证](skills/directing-stickman-videos/assets/b1/LUCIDE-LICENSE.txt)。

---

# English

Stickman video production skill: Director mode (A1–A5, A6 Amber Noir) produces
approved storyboards and video prompts; Autopilot mode (B1–B5) renders narrated,
captioned videos locally. Entry point: `SKILL.md` in this directory; operational
contract: [skills/directing-stickman-videos/SKILL.md](skills/directing-stickman-videos/SKILL.md).

Ported from https://github.com/kaomei/stickman-video-director (MIT, LICENSE kept
verbatim). Marketing preview media, sponsor assets and localized READMEs are not
ported; style sample galleries remain available at the upstream links above.
Runtime: Node 20+, FFmpeg/FFprobe, Python 3 for A6 scripts, optional
`GEMINI_API_KEY` via environment (never paste keys into chat).
