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
- FFmpeg / FFprobe（可用 `FFMPEG`、`FFPROBE` 环境变量指定路径）
- Python 3（仅 A6 的 `a6_reference_check.py`、`a6_finish.py` 需要）
- 字体：内置 `assets/fonts/` 覆盖拉丁字符；中日韩等语言请用 `AUTOPILOT_FONT` 指定字体
- 生成服务：图片/语音使用你自己的已配置服务或适配器；内置 Gemini 适配器读取环境变量 `GEMINI_API_KEY`（不要粘贴到对话中）。订阅不等于 API 配额，付费调用前必须先报价并取得授权。

## 使用

在对话里直接提出需求即可，例如：

- “用 B1 画风做一条 60 秒、9:16 的《为什么越努力越焦虑》火柴人视频”
- “把这篇公众号文章改成分镜，Style 4，90 秒，16:9”
- “用 A6 参考这条视频的风格，做一支 30 秒产品短片”

画风样片目录（上游公开 README）：[导演模式](https://github.com/kaomei/stickman-video-director/blob/main/README.zh-CN.md#a-styles) ·
[全自动模式](https://github.com/kaomei/stickman-video-director/blob/main/README.zh-CN.md#b-styles)。

## 验证（2026-11-10 实跑记录）

| 项目 | 结果 |
|------|------|
| 依赖安装 `npm ci` | 成功（10 packages） |
| 自检 `npm run doctor` | `node/ffmpeg/ffprobe/canvas/sharp/fonts` 全部 `true`；`gemini_key_present: false`（未配置，属预期） |
| Node 单元测试 `node --test tests/*.test.mjs` | 120 项：84 通过 / 36 失败；在**上游源仓库同机对照**同样为 84/36，失败成因是 Windows 符号链接权限与上游既有断言，非移植引入 |
| Python 单测 `python -m unittest discover -s tests -p 'test_a6_references.py'` | 20 项：19 通过 / 1 错误（`WinError 1314` 创建符号链接需要特权） |
| 仓库级校验 `tests/verify-*.py` | `verify-a6-guidance`、`verify-b-common-quality`、`verify-b1-baseline`、`verify-b1-production-standard`、`verify-cozy-storytelling`（已去除营销 GIF 断言）通过；`verify-a6-finishing`（写死 macOS 系统字体路径）、`verify-ab-preservation`（上游脚本自身 IndexError）、`verify-historical-cartoon`（上游指纹过期）在上游源仓库同样失败，属上游既有问题 |

未验证项：真实付费生成链路（图片/语音/视频服务）、Windows 符号链接相关用例、B4/B5 整片渲染的完整端到端流程（需要真实素材与授权调用）。上述状态如实标注，不代表“已调试可用”。

## 与上游的差异

1. 顶层新增 Bonin 安装入口 `SKILL.md` 与本 README；包内技能名 `directing-stickman-videos` 保持不变（安装布局与回归测试依赖该名称）。
2. 未移植 `assets/readme`（约 210 MB 营销预览 GIF/MP4）、`assets/sponsors`（赞助商图）、9 个多语言 README 及上游 README 预览优化脚本：属推广/大体积二进制，按 Bonin 品牌与仓库体积规则排除。画风样片仍通过上方上游链接访问。
3. 移除 Renoise MCP 链接中的推广追踪参数（`utm_source` / `utm_medium`），保留基础安装地址。
4. 未移植依赖上游 README / 营销媒体 / git 历史的 6 个校验脚本（`verify-chinese-onboarding`、`verify-localized-readmes`、`verify-thumbnail-kit`、`verify-voice-continuity`、`verify-first-use-guidance`、`verify-readmes.sh`）与 `tests/reports/`（上游历史审计快照）；`verify-cozy-storytelling.py` 删除营销 GIF 断言，保留全部规划逻辑校验。
5. `LICENSE`、B1 素材授权说明、B5 素材致谢、字体 OFL 与 Lucide 许可证原样保留：MIT 与第三方资产许可要求保留版权声明。

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
