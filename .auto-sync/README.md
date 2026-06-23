# Bonin Skills 自动化同步系统

> Automated monitoring, syncing, and auditing system for bonin-skills

## 概述

本系统每周自动监测上游技能仓库（`baoyu-skills`、`ljg-skills`）的更新，将变更同步到 `bonin-skills`，同时：

1. **脱敏作者信息** — 移除所有原作者名称、仓库地址、邮箱
2. **路径映射** — `baoyu` → `bonin`、`ljg` → `bonin`
3. **更新文档** — 同步后更新 README、CHANGELOG 等相关文档
4. **全面审计** — 检查 SKILL.md、包名、lock 文件、残留作者信息
5. **自动推送** — 审计通过后提交并推送到 GitHub

## 文件结构

```
bonin-skills/
└── .auto-sync/
    ├── sync-config.yml              # 同步配置（源仓库、规则、审计标准）
    ├── auto-sync.ps1                # 主同步程序
    ├── install-scheduled-task.ps1   # Windows 任务计划程序安装脚本
    ├── sync.log                     # 运行日志（自动生成）
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
