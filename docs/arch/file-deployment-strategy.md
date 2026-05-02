# 文件部署策略

> 状态: ✅ 已实施 | 最后更新: 2026-05-02
> 解决: 冲突文件处理不一致、缺少模式检测、缺少预操作备份

---

## 1. 问题分析（回顾）

### 1.1 修复前的现状：每种文件的处理方式不同，但没有统一策略

| 文件/目录 | 现处理方式 | 问题 |
|-----------|-----------|------|
| `.pre-commit-config.yaml` | 直接 `cp`，静默覆盖 | **最严重**——用户已有配置直接丢失 |
| `CLAUDE.md` / `SOUL.md` | `copy_template()` 交互三选一 | ✅ 合理 |
| `.claude/settings.json` | `merge_json.py` 合并 | ✅ 合理（刚改的） |
| `commands/` / `skills/` / `hooks/` | 备份目录 → 覆盖 | ⚠️ 备份是时间戳目录，与 `.bak` 不一致 |
| `CLAUDE.local.md` / `MEMORY.local.md` | 存在则跳过，`--force` 覆盖 | ✅ 合理 |
| `.gitignore` | `configure-gitignore.sh` 交互选择 | ✅ 合理 |
| `scripts/` | 白名单覆盖 | ✅ 合理（框架文件） |

### 1.2 根因：没有统一的文件分类和冲突策略

每个文件被什么方式处理是"碰巧"写的，不是按照一个统一模型设计的。

---

## 2. 同类项目研究结论

研究了 **cc-discipline**、**ECC**、**Superpowers** 三个项目，以及主流脚手架工具（CRA、Vue CLI、Yeoman 等）的最佳实践：

### 2.1 关键发现

| 发现 | 来源 | 对我们的启示 |
|------|------|------------|
| 时间戳全量备份优于逐个 `.bak` | cc-discipline | 改为预操作 `.claude/.init-backup-*/` |
| 模式检测（fresh/upgrade/append） | cc-discipline | 第一次运行 vs 重运行行为不同 |
| 版本标记文件 | cc-discipline, ECC | 写 `.claude/.claude-code-init-version` |
| 命名空间隔离 | ECC | 暂不需要，项目级 init 不适合命名空间 |
| CLAUDE.md 绝不覆盖 | cc-discipline（强约束） | `copy_template()` 已覆盖此场景 |
| `.pre-commit-config.yaml` 不合并 | 三个项目都不做 | 不应合并，应检查跳过 |
| 幂等性：存在则跳过 + `--force` | 行业标准 | 非 `--force` 模式应安全 |

### 2.2 策略原则

```
文件类型分类:
├── 可合并文件 (mergeable)    → settings.json
│     合并规则确定，程序可自动处理
│
├── 用户内容文件 (user-content) → CLAUDE.md, SOUL.md, PLAN等模板
│     需要用户参与决策，交互式处理
│
├── 应用配置文件 (app-config)   → .pre-commit-config.yaml
│     不是框架内容，是用户配置，不替换
│
├── 框架文件 (framework)       → commands/, skills/, hooks/, scripts/
│     始终部署最新版，直接覆盖
│
└── 本地偏好文件 (local-prefs)  → CLAUDE.local.md, MEMORY.local.md
     存在即保留，--force 才覆盖
```

---

## 3. 目标策略

### 3.1 预操作备份

在 `init.sh` / `init.ps1` 开始写入文件前，先检测是否存在 `.claude/` 目录。如果存在，创建时间戳全量备份：

```
.claude/.init-backup-20260502-143022/
├── settings.json
├── hooks/          (递归)
├── skills/         (递归)
├── commands/       (递归)
└── CLAUDE.md       (仅当在 .claude/ 中)
```

备份在重运行或升级时提供安全网，用户可通过 `mv .claude/.init-backup-*/.claude .claude` 回滚。

**与 cc-discipline 的区别**：cc-discipline 备份到 `.claude/.backup-*/`，我们也用同样位置，避免命名冲突。

### 3.2 模式检测

```bash
if [ -f ".claude/.claude-code-init-version" ]; then
    MODE="reconfigure"    # 之前运行过
elif [ -d ".claude" ]; then
    MODE="append"         # 已有 .claude (来自其他工具)
else
    MODE="fresh"          # 全新项目
fi
```

版本标记文件内容：`v1.6.5`（与 package.json 一致）

### 3.3 每种文件的处理方式

| 文件 | 策略 | 实现 | 条件 |
|------|------|------|------|
| `.pre-commit-config.yaml` | **跳过** | 检测存在 → warn + skip；`--force` 时覆盖 | 当前问题最多，必须先修 |
| `CLAUDE.md` / `SOUL.md` / 模板文件 | **交互** | `copy_template()` 保持不动 | ✅ 已合理 |
| `.claude/settings.json` | **合并** | `merge_json.py` 保持不动 | ✅ 已合理 |
| `commands/` / `skills/` / `hooks/` | **覆盖** | 保持现有备份+覆盖逻辑 | ⚠️ 已有时间戳备份 |
| `CLAUDE.local.md` / `MEMORY.local.md` | **跳过** | 存在则保留，`--force` 覆盖 | ✅ 已合理 |
| `.gitignore` | **交互** | `configure-gitignore.sh` 保持不动 | ✅ 已合理 |
| `scripts/` | **覆盖** | 白名单复制保持不动 | ✅ 已合理 |

### 3.4 完整流程

```
init.sh 启动
  │
  ├─ 1. 模式检测 (fresh / append / reconfigure)
  │
  ├─ 2. 如果 mode != fresh:
  │     └─ 创建 .claude/.init-backup-{timestamp}/
  │         └─ 备份 settings.json, hooks/, skills/, commands/
  │
  ├─ 3. 文件部署
  │     ├─ 复制 scripts/       ← 覆盖（框架文件）
  │     ├─ 复制 .pre-commit-config.yaml  ← 存在则跳过（非 --force）
  │     ├─ 复制 commands/      ← 备份后覆盖
  │     ├─ 复制 skills/        ← 备份后覆盖
  │     ├─ 复制 hooks/ + settings.json ← 备份后覆盖，settings merge
  │     ├─ copy_template() CLAUDE.md/SOUL.md/模板 ← 交互
  │     ├─ CLAUDE.local.md/MEMORY.local.md  ← 存在则跳过
  │     └─ configure-gitignore.sh  ← 交互
  │
  └─ 4. 写入 .claude/.claude-code-init-version
```

---

## 4. 改动实施总结

以下改动已全部在 init.sh 和 init.ps1 中实施，并通过 67 测试验证。

### 4.1 预操作备份（已实施 ✅）

**位置**：`init.sh` 在 git init（L112）后，文件复制（L225）前

```bash
# ─── 预操作备份 ───
# 如果 .claude/ 已存在，创建时间戳全量备份
if [ -d "$PROJECT_PATH/.claude" ]; then
    BACKUP_DIR="$PROJECT_PATH/.claude/.init-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    [ -f "$PROJECT_PATH/.claude/settings.json" ] && cp "$PROJECT_PATH/.claude/settings.json" "$BACKUP_DIR/"
    [ -d "$PROJECT_PATH/.claude/hooks" ] && cp -r "$PROJECT_PATH/.claude/hooks" "$BACKUP_DIR/"
    [ -d "$PROJECT_PATH/.claude/skills" ] && cp -r "$PROJECT_PATH/.claude/skills" "$BACKUP_DIR/"
    [ -d "$PROJECT_PATH/.claude/commands" ] && cp -r "$PROJECT_PATH/.claude/commands" "$BACKUP_DIR/"
    echo_info "备份已有配置到 $(basename "$BACKUP_DIR")/"
fi
```

**PS1 同步**：同样逻辑，用 `Copy-Item -Recurse`

**影响**：移除现有逐文件 `.bak`（commands/skills/hooks 的备份），统一用预操作备份

### 4.2 改动 2：`.pre-commit-config.yaml` 安全处理（已实施 ✅）

**位置**：`init.sh` L276-285

```bash
# 当前（有问题）：
cp "$PRECOMMIT_CONFIG" "$TARGET_PRECOMMIT_CONFIG"

# 改为：
if [ -f "$TARGET_PRECOMMIT_CONFIG" ]; then
    if [ "$FORCE_OVERWRITE" = true ]; then
        cp "$TARGET_PRECOMMIT_CONFIG" "$TARGET_PRECOMMIT_CONFIG.bak"
        cp "$PRECOMMIT_CONFIG" "$TARGET_PRECOMMIT_CONFIG"
        echo_success "已覆盖 .pre-commit-config.yaml (备份为 .bak)"
    else
        echo_warn ".pre-commit-config.yaml 已存在，跳过（使用 --force 覆盖）"
    fi
else
    cp "$PRECOMMIT_CONFIG" "$TARGET_PRECOMMIT_CONFIG"
    echo_success "已复制 .pre-commit-config.yaml"
fi
```

### 4.3 改动 3：版本标记文件（已实施 ✅）

**位置**：`init.sh` 完成前（当前 L648 附近）

```bash
# 写入版本标记
echo "v1.6.5" > "$PROJECT_PATH/.claude/.claude-code-init-version"
```

**PS1 同步**：`"v1.6.5" | Out-File ...`

**用途**：为将来检测重运行/版本升级提供基础

### 4.4 改动 4：移除重复备份逻辑（已实施 ✅）

当前 commands/skills/hooks 各自有独立的备份逻辑：
```
# 当前：
if [ -d "$TARGET_COMMANDS_DIR" ] && [ -n "$(ls -A "$TARGET_COMMANDS_DIR")" ]; then
    _backup_path="${TARGET_COMMANDS_DIR}.bak-$(date +%Y%m%d-%H%M%S)"
    cp -r "$TARGET_COMMANDS_DIR" "$_backup_path"
fi
```

改为：**移除这些独立备份**，因为预操作备份（改动 1）已经覆盖了整个 `.claude/`。

### 4.5 改动 5：模式检测变量（已实施 ✅）

添加 `INSTALL_MODE` 变量，用于将来条件逻辑：

```bash
INSTALL_MODE="fresh"
if [ -f "$PROJECT_PATH/.claude/.claude-code-init-version" ]; then
    INSTALL_MODE="reconfigure"
elif [ -d "$PROJECT_PATH/.claude" ]; then
    INSTALL_MODE="append"
fi
```

### 4.6 移除 settings.json 的 `.bak`（已实施 ✅）

当前 settings.json 合并后删除 `.bak`：
```bash
cp "$SETTINGS_TARGET" "$SETTINGS_TARGET.bak"
...
rm -f "$SETTINGS_TARGET.bak"
```

改为：**预操作备份已包含 settings.json**，所以合并失败时不再需要 `.bak`，直接提示用户从备份恢复。

---

## 5. 不动的内容

| 内容 | 原因 |
|------|------|
| `merge_json.py` | 刚改好，逻辑正确 |
| `jq` 预检 | 刚加好 |
| `copy_template()` 交互逻辑 | 合理，不动 |
| `CLAUDE.local.md` / `MEMORY.local.md` 跳过逻辑 | 合理，不动 |
| `configure-gitignore.sh` | 独立脚本，不动 |
| `script_whitelist.json` | 刚更新好 |

---

## 6. 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| 时间戳备份占用磁盘 | 多次运行产生多个备份 | 提示用户清理，或只保留最近 3 次 |
| 移除逐文件 `.bak` 后用户习惯变化 | 找备份位置不同了 | 日志输出明确告知备份目录名 |
| `.pre-commit-config.yaml` 跳过后用户不知道 | 模板更新没应用 | warn 提示"已跳过，--force 可覆盖" |
