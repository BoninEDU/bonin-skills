# Bonin Skills 自动化同步系统

> Automated monitoring, syncing, and auditing system for bonin-skills

## 概述

本系统每周自动监测上游技能仓库（`baoyu-skills`、`ljg-skills`）的更新，将变更同步到 `bonin-skills`，同时：

1. **脱敏作者信息** — 移除所有原作者名称、仓库地址、邮箱
2. **路径映射** — `baoyu` → `bonin`、`ljg` → `bonin`
3. **更新文档** — 同步后更新 README、CHANGELOG 等相关文档
4. **全面审计** — 检查 SKILL.md、包名、lock 文件、残留作者信息
5. **自动推送** — 审计通过后提交并推送到 GitHub

> **2026-11 扩展**：同步源从 2 个扩展为 4 个 —— 新增 `book-to-skill` → `skills/bonin-book-to-skill/`、`handraw-style` → `skills/bonin-handraw-style/`（2026-11-01 全栈迁移的两个技能，采用 `dest_prefix` 子目录映射）。既有 baoyu/ljg 行为完全不变；两个新源的增量基准记录在 `baselines.json`（提交成功后自动推进）；配套回滚脚本 `rollback.ps1`（见下文"回滚机制"）。

## 文件结构

```
bonin-skills/
└── .auto-sync/
    ├── sync-config.yml              # 同步配置（源仓库、规则、审计标准）
    ├── auto-sync.ps1                # 主同步程序
    ├── baselines.json               # 新增源的增量基准状态（2026-11 起，自动推进）
    ├── rollback.ps1                 # 回滚脚本（2026-11 新增）
    ├── rollback-state.json          # 回滚锚点（-Snapshot 生成）
    ├── install-scheduled-task.ps1   # Windows 任务计划程序安装脚本
    ├── sync.log                     # 运行日志（自动生成）
    ├── rollback.log                 # 回滚日志（自动生成）
    └── README.md                    # 本文档
```

## 快速开始

### 1. 手动运行同步

```powershell
# 正式同步
powershell -ExecutionPolicy Bypass -File d:\Repo\bonin-skills\.auto-sync\auto-sync.ps1

# 试运行（不修改任何文件）
powershell -ExecutionPolicy Bypass -File d:\Repo\bonin-skills\.auto-sync\auto-sync.ps1 -DryRun

# 强制同步（即使没有检测到变更）
powershell -ExecutionPolicy Bypass -File d:\Repo\bonin-skills\.auto-sync\auto-sync.ps1 -Force
```

### 2. 安装每周自动同步任务

以管理员身份运行：

```powershell
powershell -ExecutionPolicy Bypass -File d:\Repo\bonin-skills\.auto-sync\install-scheduled-task.ps1
```

安装后，Windows 任务计划程序会在**每周一 06:00** 自动执行同步。

### 3. 卸载自动同步任务

```powershell
powershell -ExecutionPolicy Bypass -File d:\Repo\bonin-skills\.auto-sync\install-scheduled-task.ps1 -Uninstall
```

### 4. 手动触发同步任务

```powershell
Start-ScheduledTask -TaskName 'BoninSkillsAutoSync'
```

## 配置说明

配置文件：`sync-config.yml`

### 源仓库配置

| 字段 | 说明 |
|------|------|
| `name` | 源仓库名称标识 |
| `path` | 源仓库本地路径 |
| `baseline_commit` | 上次同步的基准 commit（程序自动更新） |
| `path_replace` | 路径映射规则（大小写敏感） |
| `content_replacements` | 内容替换规则 |
| `contributor_patterns` | 贡献者信息脱敏规则 |

### 同步规则

| 字段 | 说明 |
|------|------|
| `skip_patterns` | 跳过的文件模式（正则） |
| `binary_extensions` | 二进制文件扩展名（直接复制） |
| `auto_commit` | 同步后自动提交 |
| `auto_push` | 同步后自动推送 |

### 审计规则

| 字段 | 说明 |
|------|------|
| `check_skill_md` | 检查所有 SKILL.md 的 YAML front matter |
| `check_author_info` | 检查残留作者信息 |
| `forbidden_keywords` | 禁止出现的关键词 |
| `check_package_names` | 检查 package.json 名称一致性 |
| `check_lock_files` | 检查 bun.lock 文件 |

### 调度配置

| 字段 | 说明 |
|------|------|
| `weekly` | 每周执行 |
| `log_file` | 日志文件路径 |
| `log_retention_days` | 日志保留天数 |
| `retry_count` | 失败重试次数 |
| `retry_interval_seconds` | 重试间隔（秒） |

## 同步流程

```
┌─────────────────────────────────────────────────────────┐
│                    每周一 06:00 触发                      │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  1. 加载配置 (sync-config.yml)                           │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  2. 遍历每个源仓库                                        │
│     ├─ 获取当前 HEAD                                     │
│     ├─ 对比 baseline_commit                              │
│     ├─ 获取变更文件列表                                   │
│     └─ 逐文件同步（路径映射 + 内容脱敏）                   │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  3. 修复 bun.lock 文件残留信息                            │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  4. 全面审计                                              │
│     ├─ 检查 SKILL.md front matter                        │
│     ├─ 检查残留作者信息                                   │
│     ├─ 检查 package.json 名称                            │
│     └─ 检查 bun.lock 文件                                │
└─────────────────────┬───────────────────────────────────┘
                      │
                 审计通过？
              ┌──────┴──────┐
              │             │
           是 ▼          否 ▼
┌─────────────────┐  ┌─────────────────┐
│  5. 提交变更     │  │  退出并报错      │
│  6. 推送 GitHub  │  │  不提交变更      │
│  7. 更新 baseline│  └─────────────────┘
└─────────────────┘
```

## 脱敏规则

同步过程中，以下信息会被自动移除或替换：

### 路径映射

| 源 | 目标 |
|----|------|
| `baoyu` | `bonin` |
| `BAOYU` | `BONIN` |
| `Baoyu` | `Bonin` |
| `ljg` | `bonin` |
| `LJG` | `BONIN` |
| `Ljg` | `Bonin` |

### 作者信息

| 源 | 处理方式 |
|----|---------|
| `JimLiu` | 替换为 `BoninEDU` |
| `lijigang` | 替换为 `BoninEDU` |
| `github.com/JimLiu/baoyu-skills` | 替换为 `github.com/BoninEDU/bonin-skills` |
| `github.com/lijigang/ljg-skills` | 替换为 `github.com/BoninEDU/bonin-skills` |
| `(by @username)` | 移除 |
| `contributed by @username` | 移除 |
| `<email@example.com>` | 移除 |
| `Credit to ...` | 移除 |

## 日志

日志文件：`d:\Repo\bonin-skills\.auto-sync\sync.log`

日志格式：
```
[2026-06-23 06:00:01] [INFO] Bonin Skills Auto-Sync Started
[2026-06-23 06:00:01] [INFO] Config loaded from: ...sync-config.yml
[2026-06-23 06:00:02] [INFO] === SOURCE: baoyu ===
[2026-06-23 06:00:02] [INFO] Changed files: 15
[2026-06-23 06:00:03] [INFO]   SYNCED: skills/bonin-card/SKILL.md
...
[2026-06-23 06:00:10] [INFO] === AUDIT RESULT ===
[2026-06-23 06:00:10] [INFO]   PASS: All checks passed
[2026-06-23 06:00:11] [INFO] Sync completed successfully.
```

## 故障排查

### 推送失败

如果 GitHub 推送失败，程序会重试 3 次（间隔 60 秒）。如果仍然失败：

1. 检查网络连接
2. 检查 GitHub 认证（`git config --global credential.helper`）
3. 手动推送：`git -C d:\Repo\bonin-skills push origin master`

### 审计失败

如果审计失败，变更不会被提交。检查日志中的 `FAIL` 条目，修复问题后重新运行。

### 任务未执行

1. 检查任务状态：`Get-ScheduledTask -TaskName 'BoninSkillsAutoSync'`
2. 检查上次运行结果：`Get-ScheduledTaskInfo -TaskName 'BoninSkillsAutoSync'`
3. 确保电脑在计划时间是开机的

## 手动更新 baseline

如果需要重新同步某个源仓库的全部内容：

1. 编辑 `sync-config.yml`
2. 将对应源仓库的 `baseline_commit` 改为更早的 commit
3. 运行 `auto-sync.ps1 -Force`

> **注意（2026-11 起）**：`baoyu`/`ljg` 的 baseline 仍是 `auto-sync.ps1` 内的硬编码值（编辑脚本顶部的 `$baoyuBaseline` / `$ljgBaseline`）；`book-to-skill`/`handraw-style` 的**实际生效** baseline 在 `baselines.json` 中（编辑其中的 `baseline` 字段即可，或使用 `rollback.ps1 -RestoreBaseline` 一步回退到上一基准）。

---

## 新增同步源（2026-11 扩展）

### book-to-skill → skills/bonin-book-to-skill/

| 项 | 说明 |
|----|------|
| 源路径 | `d:\Repo\book-to-skill` |
| 目标映射 | 源仓库根 → `skills/bonin-book-to-skill/`（`dest_prefix`） |
| 内部重命名 | `book_to_skill/` → `bonin_book_to_skill/`（Python 包目录） |
| 品牌清洗 | R1–R8：`virgiliojr94` → `BoninEDU`；`book_to_skill` → `bonin_book_to_skill`；`book-to-skill` → `bonin-book-to-skill`（大小写敏感，标题形态 `Book-to-Skill` → `Bonin Book-to-Skill` 先行处理）；`Booklin` → `Bonin`；邮箱移除 |
| 排除清单 | `.github/`、`BACKERS.md`、`CONTRIBUTING.md`、`LICENSE.md`、`SECURITY*.md`、上游三语 README、`CLAUDE.md`、mkdocs/cliff 网站构建配置、`docs/assets/`（吉祥物/Logo 图像）等——与迁移时的排除矩阵一致 |

### handraw-style → skills/bonin-handraw-style/

| 项 | 说明 |
|----|------|
| 源路径 | `d:\Repo\handraw-style` |
| 目标映射 | 源仓库根 → `skills/bonin-handraw-style/`（`dest_prefix`） |
| 品牌清洗 | H1–H7：`handraw-style.com` 及子域 → `www.boninaigc.top`；`github.com/yang0/handraw-style` → `github.com/BoninEDU/bonin-skills`；`yang02010`/`yang0` → `Bonin`；`HandRaw Style Studio` → `Bonin AIGC`；`open.workbuddy.cn` → `www.boninaigc.top`；Gitee 镜像 → BoninEDU |
| SKILL.md 名称 | 仅 frontmatter 的 `name:` 行精确替换为 `name: bonin-handraw-style`；**内部子技能目录 `skills/handdraw-style-prompter/` 保持原名**（安装结构依赖，不做通用替换） |
| 排除清单 | `.github/`、上游 `README.md`/`README_en.md`（Bonin 版已另建）、`RELEASE_AUDIT.md`、workbuddy 提审脚本、私有部署脚本、根级冗余 `discourse_client.py`、发布打包脚本等——与迁移时的排除矩阵一致 |

### 与既有源的差异

| 特性 | baoyu / ljg（既有） | book-to-skill / handraw-style（新增） |
|------|--------------------|--------------------------------------|
| 路径映射 | 字符串替换（`baoyu`→`bonin`） | `dest_prefix` 前缀映射 |
| 排除规则 | 仅全局 skip_patterns | 全局 + **源特定 skip patterns** |
| baseline 存储 | 脚本内硬编码（不自动推进） | `baselines.json`（审计通过并提交成功后自动推进） |
| commit 标记 | 无源标记 | message 含源名：`feat: auto-sync from upstream (源1, 源2) - N files synced`（供回滚解析） |

> **提示**：同步 handraw-style 后，若其 `scripts/build_*.py` 模板有变更，建议手动重跑 `validate_library.py` 校验画廊重建契约。

---

## 回滚机制（rollback.ps1，2026-11 新增）

`rollback.ps1` 提供三种非破坏式回滚模式，全程**不使用** `reset --hard`、`push --force`、删除分支等破坏性操作：

| 模式 | 命令 | 用途 |
|------|------|------|
| 列出可回滚点 | `rollback.ps1 -List` | 查看最近的 auto-sync 提交 |
| 记录锚点 | `rollback.ps1 -Snapshot` | 把当前 HEAD 记录为恢复锚点（写入 `rollback-state.json`） |
| **回滚提交** | `rollback.ps1 -Revert [-Last N] [-RewindBaseline] [-Push]` | `git revert` 最近 N 个同步提交（默认 1，生成反向提交，历史不重写） |
| **恢复目录** | `rollback.ps1 -Restore -Path skills/bonin-handraw-style` | 把指定技能目录恢复到锚点状态（仅允许 `skills/bonin-*` 路径） |
| **回退基准** | `rollback.ps1 -RestoreBaseline -Source handraw-style` | 把指定源的增量基准退回上一位置 |

### 安全护栏

- **默认不推送**：revert/restore 只产生本地提交；推送必须显式加 `-Push` 或人工执行
- **工作区检查**：revert 前要求工作区干净，绝不触碰用户自己的未提交改动
- **路径白名单**：`-Restore` 仅接受 `skills/bonin-*` 目录
- **确认交互**：所有写操作默认需要确认；自动化场景可加 `-Yes`；所有模式支持 `-DryRun`

### baseline 语义（关键设计）

`-Revert` 默认**保留** baseline —— 语义为"上游这批变更有问题，跳过它们"，下次同步只拉取 revert 范围之后的新提交。

若同步清洗规则有误、修复后想**重做**同一批同步，加 `-RewindBaseline`（或独立使用 `-RestoreBaseline`）：对应源的 baseline 退回上一位置，下次同步重新拉取同一范围并重新清洗。

### 典型场景

```powershell
# 1. 上游一次有毒变更被同步进来了：撤销这次同步提交
powershell -ExecutionPolicy Bypass -File rollback.ps1 -List                  # 确认目标提交
powershell -ExecutionPolicy Bypass -File rollback.ps1 -Revert -DryRun         # 预演
powershell -ExecutionPolicy Bypass -File rollback.ps1 -Revert                 # 执行（本地提交）

# 2. 清洗规则写错导致脏内容入库：修复 auto-sync.ps1 规则后重做本次同步
powershell -ExecutionPolicy Bypass -File rollback.ps1 -Revert -RewindBaseline
# ...下次周度同步会重新拉取同范围，用修复后的规则重新清洗

# 3. 整个技能目录想回到同步前的状态
powershell -ExecutionPolicy Bypass -File rollback.ps1 -Snapshot               # 平时打好锚点
powershell -ExecutionPolicy Bypass -File rollback.ps1 -Restore -Path skills/bonin-handraw-style -DryRun
powershell -ExecutionPolicy Bypass -File rollback.ps1 -Restore -Path skills/bonin-handraw-style
```
