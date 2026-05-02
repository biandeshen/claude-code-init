# claude-code-init v1.6.0 待修复计划（第二轮综合版）

**整理时间**: 2026-05-01
**基于**: 8 个维度多角色 Agent 并行审查（首轮）+ 5 个 Agent 二次交叉审查（修正）+ 8 个专门 Agent 三轮深度分析（补充）
**审查范围**: 架构设计、安全、代码质量、跨平台兼容、文档完整性、用户体验、测试 CI/CD、智能路由系统、
              Git 历史分析、Skill 质量评估、Python/Pre-commit 深度检查、npm 发布审计、错误恢复路径、
              模板质量、命令一致性、安全策略审计

---

## 修正说明

### 首轮修正（v1）

原始版本经 5 个不同角色 Agent 交叉审查后发现 12 处问题，已在第一版修复计划中修正。

### 第二轮深度分析（本版）

本版基于 8 个专门 Agent（Git 历史、Skill 深度检查、Python/Pre-commit、npm 发布、错误恢复、模板质量、命令一致性、安全策略）的深度分析结果，新增/升级以下发现：

| 类别 | 新增 P0 | 新增/升级 P1 | 新增 P2 | 总计 |
|:----:|:-------:|:-----------:|:-------:|:----:|
| 数量 | +7 | +11 | +12 | +30 |
| 累计 | 8 个 P0 | 23 个 P1 | 23 个 P2 | 54 项 |

**关键新增**：
- 3 个 P0 安全/可靠性缺陷（sudo rm 绕过、JSON 转义破坏、stdin 挂起）
- 2 个 P0 代码缺陷（pre-commit 全部 hook 路径错误、check_secrets 类型崩溃）
- 1 个 P0 错误处理缺失（init.sh 无清理 trap）
- 1 个 P0 升级（__pycache__ 泄露 → 从 P2-7 升级）
- 11 个 P1 涵盖：Skill 格式违规、预提交自动化缺失、命令路径错误、安全策略漏洞
- 12 个 P2 涵盖：模板格式、命令一致性、CI 增强、文档完善

---

## 问题汇总表

| 优先级 | 编号 | 维度 | 问题 | 状态 |
|:------:|:---:|------|------|:----:|
| **P0** | P0-1 | 代码质量 | init.sh 第 553 行 `echo -e` 重复 | 待修复 |
| **P0** | **P0-2** | **CI/CD** | **pre-commit 全部 6 个本地 hook 路径错误（`.claude/scripts/` => `scripts/`）** | **待修复** |
| **P0** | **P0-3** | **代码质量** | **check_secrets.py SECRET_PATTERNS 类型不一致（前 6 项字符串 + 后 5 项元组 → `re.search()` TypeError）** | **待修复** |
| **P0** | **P0-4** | **安全** | **smart-context.sh sudo rm -rf 绕过（正则不匹配 `sudo rm -rf /`）** | **待修复** |
| **P0** | **P0-5** | **可靠性** | **smart-context.sh JSON 转义错误（sed 将 `/` 转义为 `\/`，非法 JSON）** | **待修复** |
| **P0** | **P0-6** | **可靠性** | **smart-context.sh stdin 超时回退挂起（无 timeout 的 bare `cat`）** | **待修复** |
| **P0** | **P0-7** | **可靠性** | **init.sh 无错误清理机制（无 trap 注册，中间失败产生残损项目）** | **待修复** |
| **P0** | **P0-8** | **发布** | **scripts/__pycache__/ 泄露到 npm 包（35kB），`.npmignore` 与 `files` 字段冲突** | **待修复** |
| P1 | P1-1 | 功能 | 触发词冲突检测脚本缺失 | 待修复 |
| P1 | P1-2 | 功能 | ECC 检测逻辑未实现 | 待修复 |
| P1 | P1-3 | 测试 | F-M9 测试缺失（hooks.test.js + router.test.js） | 待修复 |
| P1 | P1-4 | CI/CD | publish.yml 包含 Node 16 测试 | 待修复 |
| P1 | P1-5 | 文档 | CLAUDE.md 命令数量写 20（实为 21） | 待修复 |
| P1 | P1-6 | 文档 | GUIDE.md 命令数量写 18（实为 21） | 待修复 |
| P1 | P1-7 | 文档 | init.sh/init.ps1 Skills/命令数量不一致 | 待修复 |
| P1 | P1-8 | 文档 | GUIDE.md 第 229 行路径描述方向错误 | 待修复 |
| P1 | P1-9 | 文档 | GUIDE.md 版本历史只到 v1.5.3 | 待修复 |
| P1 | P1-10 | 文档 | SOUL.md 版本历史只到 v1.2.0 | 待修复 |
| P1 | P1-11 | 文档 | /team 命令文档描述不存在的功能 | 待修复 |
| P1 | P1-12 | 功能 | 回滚策略（code-review 归类 + 重试次数）不统一 | 待修复 |
| **P1** | **P1-13** | **Skill** | **project-init SKILL.md 触发词在 body 而非 frontmatter（格式违规）** | **待修复** |
| **P1** | **P1-14** | **Skill** | **brainstorming SKILL.md 缺少终止条件（可能无限澄清循环）** | **待修复** |
| **P1** | **P1-15** | **代码质量** | **check_secrets.py 4 个 bare `except Exception: pass` 静默吞错误** | **待修复** |
| **P1** | **P1-16** | **代码质量** | **check_import_order.py 缺失 ~20 个标准库模块（shutil/glob/tempfile 等）** | **待修复** |
| **P1** | **P1-17** | **文档** | **README Node 版本 "16+" 与 engines ">=18.0.0" 冲突** | **待修复** |
| **P1** | **P1-18** | **发布** | **缺少 prepublish/prepack 自动化脚本（__pycache__ 清理等）** | **待修复** |
| **P1** | **P1-19** | **命令** | **5 个命令文件路径错误（引用 `.claude/scripts/` 而非 `scripts/`）** | **待修复** |
| **P1** | **P1-20** | **命令** | **plan-ceo-review.md 引用不存在的 `/autoplan` 命令** | **待修复** |
| **P1** | **P1-21** | **安全** | **SECURITY.md 缺少 PGP 密钥用于加密安全报告** | **待修复** |
| **P1** | **P1-22** | **安全** | **ECC/Superpowers 完整性检查缺失（安装来源不可验证）** | **待修复** |
| **P1** | **P1-23** | **安全** | **smart-context.sh 命令注入（转义引号可被绕过）** | **待修复** |
| P2 | P2-1 | 功能 | 风险因子缺少前/端测试/三方 API 规则 | 规划中 |
| P2 | P2-2 | 功能 | 否定词未配置化 | 规划中 |
| P2 | P2-3 | 功能 | 触发词优先级未定义 | 规划中 |
| P2 | P2-4 | 架构 | 白名单机制配置文件化 | 规划中 |
| P2 | P2-5 | 代码质量 | init.sh/init.ps1 步号同步 | ✅ 已修复 (v1.6.5) |
| P2 | P2-6 | 文档 | QUICKSTART.md 顺序统一（F-M16） | 规划中 |
| P2 | P2-7 | 功能 | SOUL_Template.md 版本字段重复 | 规划中 |
| P2 | P2-8 | CI/CD | pre-commit 缺少 shellcheck hook | 规划中 |
| P2 | P2-9 | 架构 | .npmignore + package.json files 字段同步维护 | 规划中 |
| P2 | P2-10 | 架构 | configure-gitignore 双脚本同步机制 | 规划中 |
| **P2** | **P2-11** | **模板** | **CLAUDE_Template.md 标题日期与版本历史冲突** | **规划中** |
| **P2** | **P2-12** | **模板** | **SPEC_Template.md "更新：" vs "最后更新：" 格式不一致** | **规划中** |
| **P2** | **P2-13** | **命令** | **21 个命令文件格式不统一（7 个快捷模式 vs 14 个独立模式）** | **规划中** |
| **P2** | **P2-14** | **命令** | **仅 2/21 个命令文件有版本戳（gc.md, remember.md）** | **规划中** |
| **P2** | **P2-15** | **命令** | **2 个命令文件 H1 使用 em dash（gc.md, remember.md）** | **规划中** |
| **P2** | **P2-16** | **CI/CD** | **ci.yml 缺少 CodeQL/Dependabot/Dependency Review/SBOM** | **规划中** |
| **P2** | **P2-17** | **安全** | **缺少 security.txt (RFC 9116)** | **规划中** |
| **P2** | **P2-18** | **发布** | **index.js 缺少 `--help` 标志** | **规划中** |
| **P2** | **P2-19** | **代码质量** | **check_dependencies.py 浅合并 bug（custom_rules 覆盖默认规则）** | **规划中** |
| **P2** | **P2-20** | **文档** | **CHANGELOG 缺失 v1.5.0、v1.5.5 版本条目** | **规划中** |
| **P2** | **P2-21** | **Skill** | **所有 10 个 SKILL.md 缺少版本字段** | **规划中** |
| **P2** | **P2-22** | **文档** | **长期未更新文件审计（ROADMAP.md、TROUBLESHOOTING.md 等）** | **规划中** |

**总计**: 8 个 P0，23 个 P1，23 个 P2（共 54 项）

---

## 文件锁定冲突预警 ⚠️

以下文件被多个修复项修改，**必须严格按照指定顺序执行**：

| 文件 | 涉及修复项 | 冲突类型 | 执行顺序 |
|------|-----------|---------|---------|
| `configs/.pre-commit-config.yaml` | P0-2, P2-8 | 行号依赖 | P0-2 → P2-8 |
| `scripts/check_secrets.py` | P0-3, P1-15 | 行号依赖 | P0-3 → P1-15 |
| `.claude/hooks/smart-context.sh` | P0-4, P0-5, P0-6, P1-23 | 末尾追加/行号混合 | P0-6(替换回退) → P0-5(修复json_escape) → P0-4(修复正则) → P1-23(加固) |
| `init.sh` | P0-1, P0-7, P1-7, P2-4, P2-5 | 行号依赖 | P0-1 → P0-7(末尾trap) → P1-7 → P2-4 → P2-5 |
| `init.ps1` | P1-7, P2-4, P2-5 | 行号依赖 | P1-7 → P2-4 → P2-5 |
| `.claude/complexity-rules.yaml` | P2-1, P2-2, P2-3, P1-12 | 末尾追加 | P2-1(中间插入) → P2-2(追加) → P2-3(追加) → P1-12(追加) |
| `GUIDE.md` | P1-6, P1-8, P1-9 | 位置不重叠 | 顺序无关 |
| `package.json` | P1-4, P1-18 | 不重叠 | 顺序无关 |
| `commands/*.md` | P1-19, P1-20, P2-13, P2-14, P2-15 | 文件独立 | 顺序无关 |

---

## P0 紧急修复（本周）

### P0-1: init.sh 重复行

| 属性 | 内容 |
|------|------|
| **文件** | init.sh:553 |
| **问题** | `git -C "$SCRIPT_DIR" pull` 行出现两次（第 551 行和第 553 行），第 552 行的 `echo ""` 未重复 |
| **影响** | 运行后输出两条相同的提示，代码冗余 |
| **修复方案** | 删除第 553 行（第二个 `echo -e "  git -C \"\$SCRIPT_DIR\" pull"`） |
| **验证** | `grep -c 'git -C.*SCRIPT_DIR.*pull' init.sh` 应返回 1 |

```bash
# 当前（第 549-554 行）：
echo ""
echo -e "如需更新规范，运行:"
echo -e "  git -C \"$SCRIPT_DIR\" pull"
echo ""
echo -e "  git -C \"$SCRIPT_DIR\" pull"  # ← 第 553 行，删除此行
echo ""

# 修复后：
echo ""
echo -e "如需更新规范，运行:"
echo -e "  git -C \"$SCRIPT_DIR\" pull"
echo ""
```

---

### P0-2: pre-commit 全部 6 个本地 hook 路径错误

| 属性 | 内容 |
|------|------|
| **文件** | `configs/.pre-commit-config.yaml` 第 38/48/58/68/78/130 行 |
| **问题** | 所有 6 个本地 hook 的 `entry` 引用 `.claude/scripts/check_*.py`，但部署脚本在 `scripts/` 目录 |
| **影响** | **全部 6 个本地 hook 运行失败**，pre-commit 配置形同虚设 |
| **根因** | 项目采用 SCRIPT_WHITELIST 机制从 `scripts/` 部署到 `.claude/scripts/`，但 pre-commit 配置直接引用部署路径而非源码路径 |
| **修复方案** | 将 6 处 `.claude/scripts/` 改为 `scripts/`（5 个 check 脚本 + 1 个 forbid-binary） |

```yaml
# 修复前（6 处，以 check_project_structure.py 为例）：
- id: check-project-structure
  entry: python .claude/scripts/check_project_structure.py  # ← 不存在

# 修复后：
- id: check-project-structure
  entry: python scripts/check_project_structure.py  # ← 正确路径
```

**注意**：`forbid-binary-files` hook 使用 `types: [binary]` 也存在逻辑问题——二进制文件无法通过 pre-commit 的内容管道传递。建议改用 `types: [text]` + 自定义检查。

| 验证 | `python scripts/check_project_structure.py` 应正常运行，不报模块不存在错误 |

---

### P0-3: check_secrets.py SECRET_PATTERNS 类型不一致

| 属性 | 内容 |
|------|------|
| **文件** | `scripts/check_secrets.py:38-52` |
| **问题** | `SECRET_PATTERNS` 列表中前 6 项为纯字符串（正则），后 5 项为元组 `(pattern, name, level)` |
| **影响** | 第 110 行 `re.search(pattern, value)` 遇到元组时抛出 `TypeError: expected string or bytes-like object`，**运行时崩溃** |
| **修复方案** | 统一格式：全部改为字符串（只保留 pattern），或者全部改为命名元组 |

```python
# 当前（混合类型）：
SECRET_PATTERNS = [
    r"sk-[a-zA-Z0-9]{20,}",              # ← 字符串
    ...
    (r'xox[baprs]-[a-zA-Z0-9-]+', 'Slack Token', 'HIGH'),  # ← 元组
]

# 修复方案 A（推荐，简洁）：
SECRET_PATTERNS = [
    r"sk-[a-zA-Z0-9]{20,}",
    r"xox[baprs]-[a-zA-Z0-9-]+",
    r"ya29\.[0-9A-Za-z\-_]+",
    r"sk_live_[a-zA-Z0-9]{24,}",
    r"pk_live_[a-zA-Z0-9]{24,}",
    r"rk_live_[a-zA-Z0-9]{24,}",
]

# 修复方案 B（带命名信息）：
from typing import NamedTuple
class SecretPattern(NamedTuple):
    pattern: str
    name: str = ""
    level: str = "MEDIUM"

SECRET_PATTERNS = [
    SecretPattern(r"sk-[a-zA-Z0-9]{20,}", "OpenAI API Key"),
    ...
]
```

| 验证 | `python -c "import scripts.check_secrets; print('OK')"` 无 TypeError |

---

### P0-4: smart-context.sh sudo rm -rf 绕过

| 属性 | 内容 |
|------|------|
| **文件** | `.claude/hooks/smart-context.sh:84` |
| **问题** | rm -rf 阻断正则 `(^|[;&\|])[[:space:]]*rm` 必须以 `rm` 开头——`sudo rm -rf /` 被完全绕过 |
| **影响** | **P0 安全漏洞**：用户可通过 `sudo rm -rf /` 绕过物理阻断 |
| **根因** | 正则设计未考虑 `sudo`、`command` 等命令前缀 |
| **修复方案** | 在正则前缀中增加 `sudo[[:space:]]+` 和 `command[[:space:]]+` 匹配 |

```bash
# 原正则（第 84 行）：
if echo "$command" | grep -qE "(^|[;&|])[[:space:]]*rm[[:space:]]+(-[rRf]+[[:space:]]*)+[[:space:]]*(/|~|[.][.])" 2>/dev/null; then

# 修复后：
if echo "$command" | grep -qE "(^|[;&|])[[:space:]]*(sudo[[:space:]]+|command[[:space:]]+)?rm[[:space:]]+(-[rRf]+[[:space:]]*)+[[:space:]]*(/|~|[.][.])" 2>/dev/null; then
```

| 验证 | `echo "sudo rm -rf /" | grep -qE "...修复后正则..."` 匹配成功 |

---

### P0-5: smart-context.sh JSON 转义错误

| 属性 | 内容 |
|------|------|
| **文件** | `.claude/hooks/smart-context.sh:12` |
| **问题** | sed 回退转义中 `s/\//\\\//g` 将 `/` 错误转义为 `\/`，**这并非合法 JSON 转义** |
| **影响** | 包含 `/` 路径的 suggestion 输出非法 JSON，`skillToActivate` 可能被破坏，**Hook 输出无法被 Claude Code 解析** |
| **根因** | JSON 规范只要求转义 `"`、`\` 和控制字符，`/` 不需要也不应该被转义 |
| **修复方案** | 移除 sed 中的 `/` → `\/` 转义 |

```bash
# 当前（第 12 行）：
printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\//\\\//g' \

# 修复后：
printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' \
```

| 验证 | `json_escape "/path/to/file"` 输出 `"/path/to/file"`（不含 `\/`） |

---

### P0-6: smart-context.sh stdin 超时回退挂起

| 属性 | 内容 |
|------|------|
| **文件** | `.claude/hooks/smart-context.sh:24` |
| **问题** | 当 `timeout` 和 `perl` 均不可用时，回退到 bare `cat`（无超时保护）——**stdin 可无限阻塞** |
| **影响** | 在缺乏 GNU timeout 和 perl 的环境中（如某些精简容器、Windows Git Bash），Hook 执行可能永久挂起 |
| **修复方案** | 增加 shell 内置超时（`read -t`）或使用 `dd` 的有超时变体 |

```bash
# 当前（第 19-25 行）：
if command -v timeout >/dev/null 2>&1; then
    event_data=$(timeout 5 cat 2>/dev/null)
elif command -v perl >/dev/null 2>&1; then
    event_data=$(perl -e 'alarm 5; eval { local $SIG{ALRM} = sub { die "timeout\n" }; print <STDIN> }' 2>/dev/null)
else
    event_data=$(cat 2>/dev/null)  # ← 可能永久阻塞
fi

# 修复后：
if command -v timeout >/dev/null 2>&1; then
    event_data=$(timeout 5 cat 2>/dev/null)
elif command -v perl >/dev/null 2>&1; then
    event_data=$(perl -e 'alarm 5; eval { local $SIG{ALRM} = sub { die "timeout\n" }; print <STDIN> }' 2>/dev/null)
elif command -v dd >/dev/null 2>&1; then
    event_data=$(dd bs=4096 count=128 2>/dev/null)  # 读取最多 512KB 后自动退出
else
    # 最终回退：使用 read -t 逐行读取，最多读 5 行后超时
    event_data=""
    for i in 1 2 3 4 5; do
        IFS= read -t 1 line 2>/dev/null || break
        event_data="$event_data$line"$'\n'
    done
fi
```

| 验证 | 在无可执行 `timeout` 的环境中运行 Hook 不会挂起 |

---

### P0-7: init.sh 无错误清理机制

| 属性 | 内容 |
|------|------|
| **文件** | `init.sh` |
| **问题** | 整个 init.sh 脚本未注册任何 `trap` 清理函数。如果在脚本执行中途（如文件复制、git init 后）失败，**目标项目目录处于半初始化状态** |
| **影响** | 用户得到残缺的项目初始化结果，某些文件存在、某些不存在，难以排查 |
| **修复方案** | 在脚本开头注册 `trap cleanup EXIT`，定义 cleanup 函数处理部分初始化情况 |

```bash
# 在 init.sh 开头（# 错误处理 区域）添加：
CLEANUP_NEEDED=false
INIT_COMPLETED=false

cleanup() {
    if [ "$INIT_COMPLETED" = false ] && [ "$CLEANUP_NEEDED" = true ]; then
        echo -e "\n⚠️  初始化未完成，正在清理..."
        # 删除已创建的目标目录结构
        [ -d "$TARGET_DIR/.claude" ] && rm -rf "$TARGET_DIR/.claude"
        echo -e "已清理 ${TARGET_DIR}/.claude"
    fi
}
trap cleanup EXIT

# 在初始化流程末尾标记完成：
INIT_COMPLETED=true
```

| 验证 | 在 init.sh 中途 `exit 1`，目标目录不应残留 `.claude` |

---

### P0-8: scripts/__pycache__/ 泄露到 npm 包

| 属性 | 内容 |
|------|------|
| **问题** | `scripts/__pycache__/` 目录（约 35kB）被包含在 npm 发布包中 |
| **根因** | `package.json` 使用 `files` 白名单（含 `scripts/`），但 `.npmignore` 的排除模式在 `files` 白名单激活时无效 |
| **影响** | npm 包中包含不应分发的 `.pyc` 编译缓存文件，增加包体积和潜在兼容问题 |
| **修复方案** | 在 `package.json` 的 `files` 字段中显式排除 `__pycache__` |

```json
{
  "files": [
    "index.js",
    "init.ps1",
    "init.sh",
    "templates/",
    "commands/",
    "scripts/",
    "configs/",
    ".claude/skills/",
    ".claude/hooks/",
    ".claude/settings.json",
    ".claude/complexity-rules.yaml",
    "!scripts/__pycache__/"
  ]
}
```

同时删除现有 `scripts/__pycache__/` 目录，并在 `.gitignore` 中添加 `__pycache__/`。

| 验证 | `npm pack --dry-run 2>&1 | grep -c pyc` 返回 0 |

---

## P1 功能完善（本月）

### P1-1: 触发词冲突检测脚本缺失

| 属性 | 内容 |
|------|------|
| **问题** | 无自动化机制检测跨 Skill 触发词重叠，可能导致路由混乱 |
| **影响** | 触发词冲突未被及时发现，影响路由准确性 |
| **修复方案** | 在 `scripts/` 目录新增 `check_trigger_conflicts.py`，通过白名单部署 |
| **验证** | `python3 scripts/check_trigger_conflicts.py` 退出码 0 |

**注意**：
- ❌ 原始版本错误地将脚本放在 `.claude/scripts/` → 修正为 `scripts/`
- ❌ 原始版本的 `TRIGGER_RE` 正则要求 `triggers: [...]` 格式，实际 SKILL.md 无此格式 → 修正
- ❌ 原始版本的 Router 决策表正则搜索 `→` 符号，实际主决策表无箭头 → 修正

```python
#!/usr/bin/env python3
"""
check_trigger_conflicts.py
检查所有 Skills 的触发词是否存在冲突。

当前 SKILL.md 中触发词位于 description 字段的自然语言中，
格式为：中文触发词：审查、检查、review...

运行方式: python3 scripts/check_trigger_conflicts.py
退出码: 0=通过, 1=发现冲突
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

SKILLS_DIR = Path(".claude/skills")
# 匹配 "中文触发词：xxx、xxx" 或 "中文触发词：xxx, xxx" 模式
TRIGGER_PATTERN = re.compile(
    r'中文触发词[：:]\s*([^。\n]+)',
    re.IGNORECASE
)
# 匹配用中文顿号(、)或英文逗号(,)或空格分隔的关键词
# 丢弃单字词（如"审"、"查"等碎片化匹配）
KEYWORD_SPLIT = re.compile(r'[、,，\s]+')


def extract_triggers(content: str, skill_name: str) -> list[tuple[str, str]]:
    """从 SKILL.md 内容中提取触发词"""
    triggers = []

    # 方法1：从 "中文触发词：" 声明中提取
    for match in TRIGGER_PATTERN.finditer(content):
        raw = match.group(1).strip()
        keywords = [k.strip() for k in KEYWORD_SPLIT.split(raw) if k.strip()]
        for kw in keywords:
            # 过滤单字词 (如 "审"、"修" 这类非独立语义碎片)
            if len(kw) >= 2:
                triggers.append((kw.lower(), f"触发词声明: {raw[:30]}..."))

    # 方法2：从 Router 决策表中提取（格式为 "| 触发词, 触发词 | ... |"）
    if skill_name == "router":
        table_rows = re.findall(r'\|\s*(.+?)\s*\|', content)
        # router 决策表的行模式需要特殊处理
        for row in table_rows:
            # 收集含有 "| skill:xxx" 指示的触发词
            pass  # Router 的触发词提取需要单独实现

    return triggers


def main() -> int:
    print("🔍 检查 Skills 触发词冲突...")

    if not SKILLS_DIR.exists():
        print("❌ .claude/skills/ 目录不存在")
        return 1

    trigger_map = defaultdict(list)

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue

        content = skill_md.read_text(encoding="utf-8")
        triggers = extract_triggers(content, skill_dir.name)
        for trigger, source in triggers:
            trigger_map[trigger].append((skill_dir.name, source))

    print(f"📊 已扫描 {len(trigger_map)} 个唯一触发词")

    # 检测真正的跨 Skill 冲突
    conflicts = []
    for trigger, sources in trigger_map.items():
        skills = set(s[0] for s in sources)
        if len(skills) > 1:
            conflicts.append((trigger, sources))

    if conflicts:
        print(f"\n❌ 发现 {len(conflicts)} 个触发词冲突：")
        for trigger, sources in conflicts:
            skills_str = ", ".join(s[0] for s in set(sources))
            print(f"\n  触发词: '{trigger}' 冲突于: [{skills_str}]")
        return 1

    print("\n✅ 触发词检查通过，无冲突")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

---

### P1-2: ECC 检测逻辑未实现

| 属性 | 内容 |
|------|------|
| **问题** | 降级策略依赖 AI 自行判断 ECC 是否安装，不可靠 |
| **影响** | Router 可能给出错误的降级建议 |
| **修复方案** | 在 `scripts/` 目录新增 `check_ecc.sh`，通过白名单部署 |

**注意**：
- ❌ 原始版本错误地将脚本放在 `.claude/scripts/` → 修正为 `scripts/`
- ❌ 原始版本的 Method 3 使用无效 npm 包名 `@everything-claude-code` → 删除此方法

```bash
#!/bin/bash
# scripts/check_ecc.sh - 检测 Everything Claude Code 插件是否安装
# 部署路径：init.sh 从 scripts/ 复制到目标项目的 .claude/scripts/

ECC_INSTALLED=0

# 方法1：检查 settings.json 中的插件配置
if [ -f ".claude/settings.json" ]; then
    if grep -q "everything-claude-code\|ecc\|ecc-plugin" .claude/settings.json 2>/dev/null; then
        ECC_INSTALLED=1
    fi
fi

# 方法2：检查常见插件目录路径
if [ "$ECC_INSTALLED" = "0" ]; then
    for path in \
        "$HOME/.claude/plugins/everything-claude-code" \
        "$HOME/.claude/plugins/ecc" \
        "$HOME/.config/claude/plugins/everything-claude-code" \
        "/opt/claude/plugins/everything-claude-code"; do

        if [ -d "$path" ]; then
            ECC_INSTALLED=1
            break
        fi
    done
fi

echo "ECC_INSTALLED=$ECC_INSTALLED"
exit 0
```

| 验证 | `bash scripts/check_ecc.sh` 输出格式为 `ECC_INSTALLED=0/1` |

---

### P1-3: F-M9 测试缺失

| 属性 | 内容 |
|------|------|
| **问题** | hooks.test.js 和 router.test.js 长期未实现 |
| **影响** | Router 决策逻辑和 Hook JSON 输出无自动化测试 |
| **修复方案** | 新建 `tests/hooks.test.js` 和 `tests/router.test.js` |

**注意**：项目使用 CommonJS 模块系统，**必须使用 `require` 而非 `import`**。

```javascript
// tests/hooks.test.js - 正确用法（CommonJS）
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { execSync } = require('child_process');
const path = require('path');

describe('smart-context.sh Hook 测试', () => {
    const HOOK_PATH = path.join(__dirname, '..', '.claude', 'hooks', 'smart-context.sh');

    it('场景 2（安全文件检测）输出有效 JSON', () => {
        // 注意：execSync 是同步函数，不需要 await
        // Hook 通过 CLI 参数接收输入
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'cat config.yaml' }
        });
        const result = execSync(`bash "${HOOK_PATH}" '${input}'`, {
            encoding: 'utf-8',
            timeout: 5000
        });
        const json = JSON.parse(result);
        assert.ok(json.suggestion, '应包含建议');
    });

    it('场景 6（rm -rf 阻断）以非零退出码退出', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'rm -rf /' }
        });
        // execSync 在命令失败时抛出异常
        assert.throws(() => {
            execSync(`bash "${HOOK_PATH}" '${input}'`, { encoding: 'utf-8', timeout: 5000 });
        }, /command failed/i, '应阻断 rm -rf /');
    });
});
```

| 验证 | `node --test tests/hooks.test.js` 全部通过 |

---

### P1-4: publish.yml 包含 Node 16 测试

| 属性 | 内容 |
|------|------|
| **文件** | .github/workflows/publish.yml |
| **问题** | CI 包含 Node 16 测试，但 package.json engines 要求 ≥18.0.0 |
| **修复方案** | 从 matrix 中移除 '16' |
| **验证** | `grep -o "'16'" .github/workflows/publish.yml` 不应返回结果 |

```yaml
# 当前：
node-version: ['16', '18', '20', '22']

# 修复后：
node-version: ['18', '20', '22']
```

---

### P1-5: CLAUDE.md 命令数量错误

| 属性 | 内容 |
|------|------|
| **文件** | CLAUDE.md:23, 49 |
| **问题** | 声称"20 个斜杠命令"，实际有 21 个（缺少 gc） |
| **修复方案** | 改为"21 个斜杠命令" |
| **验证** | `ls commands/ | wc -l` 返回 21，与文档一致 |

---

### P1-6: GUIDE.md 命令数量错误

| 属性 | 内容 |
|------|------|
| **文件** | GUIDE.md:355 |
| **问题** | 声称"18 个斜杠命令"，实际有 21 个 |
| **修复方案** | 改为"21 个斜杠命令" |
| **验证** | 同 P1-5 |

---

### P1-7: init.sh/init.ps1 Skills/命令数量不一致

| 属性 | 内容 |
|------|------|
| **文件** | init.sh:520, init.ps1:518 |
| **问题** | init.sh 写"10 个 Skills"（router 不应计入，应为 9）；init.sh 写"20 个命令"缺少 gc；init.ps1 写"18 个" |
| **修复方案** | 统一为"9 个可自动触发的 Skills"和"21 个斜杠命令" |
| **验证** | grep 检查数字是否匹配 |

```bash
# init.sh 原：
echo -e "  ${GREEN}✅${NC} 10 个可自动触发的 Skills（审查/提交/TDD/重构/修复/解释/校验/头脑风暴/路由/无人值守路由）"
echo -e "  ${GREEN}✅${NC} 20 个斜杠命令（/review, /commit, /fix, /refactor, /explain...）"

# 修复后：
echo -e "  ${GREEN}✅${NC} 9 个可自动触发的 Skills（审查/提交/TDD/重构/修复/解释/校验/头脑风暴/初始化）"
echo -e "  ${GREEN}✅${NC} 21 个斜杠命令（/review, /commit, /fix, /refactor, /explain...）"
```

---

### P1-8: GUIDE.md 第 229 行路径描述方向错误

| 属性 | 内容 |
|------|------|
| **文件** | GUIDE.md:229 |
| **问题** | 原文"初始化后会复制 `.claude/scripts/` 目录到项目"——路径方向搞反了 |
| **影响** | 混淆源码路径和目标路径，这是 HANDOVER 标记的"最高频错误源" |
| **修复方案** | 明确描述方向：从 scripts/ 复制到目标项目的 .claude/scripts/ |
| **验证** | grep 检查修正后的文字不再包含"复制 .claude/scripts/ 到项目" |

```markdown
# 当前：
初始化后会复制 `.claude/scripts/` 目录到目标项目

# 修复后：
初始化脚本会从 `scripts/`（源码包）将校验脚本复制到目标项目的 `.claude/scripts/`
```

---

### P1-9: GUIDE.md 版本历史缺失

| 属性 | 内容 |
|------|------|
| **文件** | GUIDE.md:405-412 |
| **问题** | 版本历史只到 v1.5.3，缺少 v1.5.4 - v1.6.0 |
| **修复方案** | 补充缺失版本条目 |
| **验证** | `grep 'v1.6.0' GUIDE.md` 存在且日期正确 |

---

### P1-10: SOUL.md 版本历史缺失

| 属性 | 内容 |
|------|------|
| **文件** | SOUL.md:155-156 |
| **问题** | 版本历史只到 v1.2.0 |
| **修复方案** | 补充 v1.2.0 之后版本 |
| **验证** | `grep 'v1.6.0' SOUL.md` 存在 |

---

### P1-11: /team 命令文档不准确

| 属性 | 内容 |
|------|------|
| **文件** | commands/team.md |
| **问题** | 描述了"使用 git worktree 创建隔离工作区"，但当前是单会话 prompt 模拟 |
| **影响** | 用户期望「真实进程隔离」与实际「共享上下文」严重不符 |
| **修复方案** | 开头明确标注 Phase 1 限制和 Phase 2 计划 |
| **验证** | `grep 'Phase 1' commands/team.md` 存在 |

```markdown
> **当前实现状态（Phase 1）**：
> 当前 Agent Teams 在同一次 Claude Code 会话中通过 prompt 模拟多角色协作。
> **这不是真实的多进程并行**，所有"agent"共享同一上下文。
>
> **Phase 2 计划**：使用 `git worktree` 创建隔离工作区，每个 agent 独立进程。
>
> 当前能力限制：
> - ✅ 多角色协调（Writer/Reviewer/Critic）
> - ❌ 真实进程隔离
> - ❌ 并行任务执行
```

---

### P1-12: 回滚策略不统一

| 属性 | 内容 |
|------|------|
| **问题** | code-review 被标注为 file_level 回滚，但自身声明"只读不修改文件" |
| **影响** | 回滚策略矛盾，无人值守时可能错误执行回滚 |
| **修复方案** | 将 code-review 移到 no_rollback 类别，统一重试次数为 3 次 |

```yaml
# complexity-rules.yaml 末尾追加
rollback_policy:
  max_retries: 3
  retry_delay: 2s
  rollback_scope:
    file_level:
      skills: [error-fix, tdd-workflow, project-init]  # code-review 已移除
    commit_level:
      skills: [safe-refactoring, git-commit]
    no_rollback:                                        # code-review 移至此处
      skills: [code-review, code-explain, project-validate, brainstorming, router]
```

| 验证 | code-review 不应在 file_level 中出现，应在 no_rollback 中 |

---

### P1-13: project-init SKILL.md 触发词格式违规

| 属性 | 内容 |
|------|------|
| **文件** | `.claude/skills/project-init/SKILL.md:56-60` |
| **问题** | 触发词声明在 body 的 `## 触发词` 章节，而非 frontmatter `description` 字段。所有其他 Skill 的触发词都在 description 中 |
| **影响** | Router 读取 project-init 的触发词方式与其他 Skill 不一致，可能导致路由遗漏 |
| **修复方案** | 将触发词合并到 frontmatter `description` 中，删除 body 中的 `## 触发词` 章节 |

```yaml
# 当前：
description: >
  新项目初始化时自动加载。检查项目结构完整性、导航 CLAUDE.md/SOUL.md、
  确认 SPEC 模板和校验脚本就位。由 Router 在用户说"初始化项目"或
  "帮我设置项目"时触发。

## 触发词
- 初始化项目、初始化环境、设置项目
- 帮我设置开发环境、首次启动
- project init, setup, initialize

# 修复后：
description: >
  新项目初始化时自动加载。中文触发词：初始化项目、初始化环境、设置项目、
  帮我设置开发环境、首次启动、project init、setup、initialize。
  检查项目结构完整性、导航 CLAUDE.md/SOUL.md、确认 SPEC 模板和校验脚本就位。
```

| 验证 | `grep '中文触发词' .claude/skills/project-init/SKILL.md` 在 description 中存在 |

---

### P1-14: brainstorming SKILL.md 缺少终止条件

| 属性 | 内容 |
|------|------|
| **文件** | `.claude/skills/brainstorming/SKILL.md` |
| **问题** | 失败处理章节写"需求不明确时继续与用户澄清"，无终止条件。AI 可能无限循环提问 |
| **影响** | 无限澄清循环，不会自动退出 |
| **修复方案** | 增加最大澄清轮数限制和降级策略 |

```markdown
## 失败处理

本技能为咨询类操作，不修改任何文件。

- **需求不明确时**：最多进行 3 轮澄清提问
- **3 轮后仍未明确**：输出当前已收集的信息摘要，标注未确认项，推荐用户使用 `/brainstorming` 或 `/plan-ceo-review` 进行更结构化的需求分析
- **用户明确表示不确定**：输出框架性建议（如"建议先用 MVP 验证核心假设"），然后退出
```

| 验证 | 第 4 次提问时输出降级建议而非继续提问 |

---

### P1-15: check_secrets.py bare except 吞错误

| 属性 | 内容 |
|------|------|
| **文件** | `scripts/check_secrets.py:138, 181(已有 except), 252, 283, 350, 383` |
| **问题** | 4 个 `except Exception: pass` 语句静默吞掉所有异常（包括编程错误如 NameError、TypeError） |
| **影响** | 代码中的 bug 被隐藏，更难调试。当前 P0-3 的 TypeError 就是被 bare except 吞掉的 |
| **修复方案** | 限定异常类型，添加日志输出 |

```python
# 当前：
except Exception:
    pass

# 修复后：
except (IOError, OSError, UnicodeDecodeError) as e:
    # 文件读取错误，跳过是合理的
    if '--debug' in sys.argv:
        print(f"[DEBUG] 跳过文件 {file_path}: {e}", file=sys.stderr)
```

| 验证 | `python3 -c "import scripts.check_secrets; print('OK')"` 不应有静默失败 |

---

### P1-16: check_import_order.py 标准库列表不完整

| 属性 | 内容 |
|------|------|
| **文件** | `scripts/check_import_order.py` |
| **问题** | `STANDARD_LIBRARY` 列表缺失约 20 个 Python 标准库模块（`shutil`、`glob`、`tempfile`、`hashlib`、`hmac`、`secrets`、`base64`、`uuid`、`calendar`、`decimal`、`statistics`、`ipaddress`、`fractions`、`enum`、`numbers`、`atexit`、`sched`、`filecmp`、`fileinput`、`getpass`、`contextlib`） |
| **影响** | 这些模块的 import 被错误归类为第三方库，导致 import 顺序检查产生误报 |
| **修复方案** | 补充缺失的标准库模块到 `STANDARD_LIBRARY` 列表 |

| 验证 | `python3 -c "import shutil, glob, tempfile; print('OK')"` 且 import 顺序检查正确识别为标准库 |

---

### P1-17: README Node 版本与 engines 冲突

| 属性 | 内容 |
|------|------|
| **文件** | `README.md` 第 ? 行、`package.json:40` |
| **问题** | README 写 "Node.js 16+"，但 `package.json` `engines.node` 要求 ">=18.0.0" |
| **影响** | 用户按 README 要求使用 Node 16 会安装失败 |
| **修复方案** | 统一为 `>=18.0.0` |

| 验证 | README 和 package.json 的 Node 版本要求一致 |

---

### P1-18: 缺少 prepublish/prepack 自动化

| 属性 | 内容 |
|------|------|
| **文件** | `package.json` |
| **问题** | 缺少 `prepack` 或 `prepublishOnly` 脚本，导致 __pycache__ 等构建产物无法在发布前自动清理 |
| **影响** | 每次 npm publish 需要手动清理，容易遗漏 |
| **修复方案** | 在 `scripts` 中添加 `prepack` 脚本自动清理 |

```json
{
  "scripts": {
    "prepack": "rm -rf scripts/__pycache__",
    "start": "node index.js",
    "test": "node --test tests/*.test.js"
  }
}
```

| 验证 | `npm pack --dry-run 2>&1 | grep -c pyc` 在 prepack 后返回 0 |

---

### P1-19: 5 个命令文件路径错误

| 属性 | 内容 |
|------|------|
| **文件** | `commands/capabilities.md:48,57`、`commands/help.md:17`、`commands/overnight.md:19`、`commands/validate.md:7` |
| **问题** | 5 处引用 `.claude/scripts/`（部署路径）而非 `scripts/`（源码路径） |
| **影响** | 命令文档指向不存在的路径，用户使用时困惑 |
| **修复方案** | 全部改为 `scripts/`（除非明确引用部署后的文件） |

```markdown
# 当前：
| 过夜任务 | `bash .claude/scripts/tmux-session.sh` |
# 修复后：
| 过夜任务 | `bash scripts/tmux-session.sh` |
```

| 验证 | `grep -r '\.claude/scripts/' commands/` 无返回值 |

---

### P1-20: plan-ceo-review.md 引用不存在的 /autoplan

| 属性 | 内容 |
|------|------|
| **文件** | `commands/plan-ceo-review.md:84` |
| **问题** | 引用 `/autoplan` 命令，但 `commands/autoplan.md` 不存在 |
| **影响** | 用户点击/搜索该命令时无结果 |
| **修复方案** | 删除 `- /autoplan` 引用，或替换为真实命令（如 `/plan`） |

| 验证 | `ls commands/autoplan.md 2>/dev/null` 不存在时，plan-ceo-review.md 应无引用 |

---

### P1-21: SECURITY.md 缺少 PGP 密钥

| 属性 | 内容 |
|------|------|
| **文件** | `SECURITY.md` |
| **问题** | 安全策略未提供 PGP 公钥用于加密漏洞报告 |
| **影响** | 敏感的安全漏洞无法通过加密渠道报告 |
| **修复方案** | 在 SECURITY.md 中提供 PGP 密钥指纹或链接 |

```
# 在 SECURITY.md 中补充：
## PGP 加密报告

对于敏感漏洞，请使用以下 PGP 密钥加密报告内容：
- 密钥指纹：`[待生成]`
- 密钥下载：`https://github.com/biandeshen.gpg`
```

| 验证 | SECURITY.md 包含 PGP 相关章节 |

---

### P1-22: ECC/Superpowers 完整性检查缺失

| 属性 | 内容 |
|------|------|
| **问题** | ECC (Everything Claude Code) 和 Superpowers 作为第三方插件，安装来源和完整性无法验证 |
| **影响** | 用户可能从不可信来源安装损坏或篡改的版本 |
| **修复方案** | 在 check_ecc.sh 中添加版本校验和 checksum 验证 |

```bash
# 在 check_ecc.sh 中补充（方法 3）：
# 方法3：校验 ECC 版本完整性
if [ -f ".claude/ecc/VERSION" ]; then
    ECC_VERSION=$(cat .claude/ecc/VERSION)
    # 预期版本：从 package.json 或独立版本文件读取
    EXPECTED_VERSION=$(node -e "console.log(require('./package.json').eccVersion || '')" 2>/dev/null)
    if [ -n "$EXPECTED_VERSION" ] && [ "$ECC_VERSION" != "$EXPECTED_VERSION" ]; then
        echo "ECC_VERSION_MISMATCH=1"
    fi
fi
```

| 验证 | `bash scripts/check_ecc.sh` 在 ECC 版本不匹配时输出 `ECC_VERSION_MISMATCH=1` |

---

### P1-23: smart-context.sh 命令注入

| 属性 | 内容 |
|------|------|
| **文件** | `.claude/hooks/smart-context.sh:31-37` |
| **问题** | event_data 中的 `tool_input.command` 通过 sed 正则提取（第 37 行），但未做输入验证。如果 command 包含精心构造的转义序列，可能破坏 JSON 输出结构 |
| **影响** | 理论上可构造恶意命令注入到 Hook 的 JSON 输出中，导致 Claude Code 解析错误或异常行为 |
| **根因** | sed 提取依赖双引号边界 `"\([^"]*\)"`，但如果 command 中包含转义引号 `\"`，sed 提取会提前截断 |
| **修复方案** | 增加对 command 内容的双重转义和长度限制 |

```bash
# 第 37 行后增加转义加固：
command=$(echo "$event_data" | sed -n 's/.*"command"\s*:\s*"\([^"]*\)".*/\1/p')
# 加固：限制命令长度，防止注入
command="${command:0:500}"
# 加固：移除控制字符，防止 JSON 注入
command=$(echo "$command" | tr -d '\000-\010\016-\037')
```

| 验证 | `echo '{"command": "rm -rf / \" }; evil' | sed ...` 提取结果不含注入内容 |

## P2 持续优化（季度）

### P2-1: 风险因子覆盖不全
**文件**: `.claude/complexity-rules.yaml`  
**修复**: 在 risk_factors 中补充 frontend-dom、no-test-coverage、external-api-call 三个条件  
**验证**: `grep 'frontend-dom\|no-test-coverage\|external-api-call' .claude/complexity-rules.yaml`

### P2-2: 否定词未配置化
**文件**: `router/SKILL.md`（当前硬编码）→ 移至 `.claude/complexity-rules.yaml`  
**修复**: 新增 `negation_patterns` 区块（strong_negation / weak_negation / conditional_negation）  
**注意**: 需在 P2-1 之后执行（均在 complexity-rules.yaml 末尾追加）

### P2-3: 触发词优先级未定义
**文件**: `.claude/complexity-rules.yaml`  
**修复**: 新增 `trigger_priority` + `context_patterns` 区块  
**注意**: 需在 P2-2 之后执行（末尾追加）

### P2-4: 白名单机制配置文件化
**文件**: `init.sh` + `init.ps1`  
**修复**: 创建 `scripts/script_whitelist.json`，init 脚本改为读取 JSON  
**注意**: 
- ⚠️ 必须包含 P1-1 (check_trigger_conflicts.py) 和 P1-2 (check_ecc.sh) 的新脚本
- ⚠️ 需同时适配 init.sh 和 init.ps1
- ⚠️ 需在 P0-1 + P1-7 之后执行（init.sh 行号稳定后）
- **验证**: `node --check scripts/script_whitelist.json`

### P2-5: init.sh/init.ps1 步号同步 → ✅ 已修复 (v1.6.5)
**文件**: `init.sh` + `init.ps1`  
**修复**: init.ps1 中 6 处步骤编号已对齐（9→8, 10.1→9.1, 11→10, 11.1→10.1, 12→11, 13→12, 14→13）。当前两端步号已一致，完整的 15 步体系进一步统一可在未来版本中完成。

### P2-6: QUICKSTART.md 顺序统一（F-M16）
**文件**: `docs/QUICKSTART.md`  
**修复**: 统一描述顺序为"先初始化 → 再阅读 GUIDE.md"

### P2-7: SOUL_Template.md 版本字段重复
**文件**: `templates/SOUL_Template.md:4-5`  
**修复**: 合并 `模板版本：v1.2.0` 和 `版本：v1.2.0` 为一行  
**验证**: `grep '^> 版本' templates/SOUL_Template.md` 仅返回 1 行

### P2-8: pre-commit 缺少 shellcheck hook
**文件**: `configs/.pre-commit-config.yaml`  
**修复**: 添加 koalaman/shellcheck-pre-commit hook

### P2-9: .npmignore + package.json files 字段同步维护
**修复**: 在维护清单中增加 npm 发布的交叉检查

### P2-10: configure-gitignore 双脚本同步
**修复**: configure-gitignore.sh 和 configure-gitignore.ps1 的同步检查

---

### P2-11: CLAUDE_Template.md 标题日期与版本历史冲突
**文件**: `templates/CLAUDE_Template.md`  
**问题**: Header 日期 "2026-05-01" 与版本历史日期 "2026-04-28" 不一致  
**修复**: 统一日期  
**验证**: Header 日期 ≥ 版本历史中最新条目的日期

### P2-12: SPEC_Template.md 格式字段不一致
**文件**: `templates/SPEC_Template.md:3-4`  
**问题**: 第 3 行使用 `更新：` 而非一致的 `最后更新：`；第 4 行 `模板版本` 与 `版本` 并存，难以区分模板版本和 spec 实例版本  
**修复**: 统一为 `最后更新：` 格式；明确区分模板版本和实例版本  
**验证**: `grep '最后更新' templates/SPEC_Template.md` 使用标准格式

### P2-13: 命令文件格式统一
**文件**: `commands/*.md`（21 个文件）  
**问题**: 7 个文件使用"快捷跳转模式"（短 + 跳转到 Skill），14 个使用"自包含模式"（详细说明）。无统一格式标准  
**修复**: 制定命令文件格式规范，统一结构（描述、触发条件、执行逻辑、示例、相关命令）  
**验证**: 所有命令文件符合同一结构模板

### P2-14: 命令文件缺少版本戳
**文件**: `commands/*.md`（21 个文件）  
**问题**: 仅 `gc.md` 和 `remember.md` 有版本/日期戳，其余 19 个文件无版本追踪  
**修复**: 在所有命令文件头部添加 `> 最后更新：YYYY-MM-DD` 行  
**验证**: `grep -L '最后更新' commands/*.md` 返回空

### P2-15: 命令文件 H1 格式不一致
**文件**: `commands/gc.md`、`commands/remember.md`  
**问题**: 在 H1 中使用 em dash（—）而非标准连字符（-）  
**修复**: 将 em dash 替换为连字符  
**验证**: `grep '^# .*—' commands/*.md` 返回空

### P2-16: CI 缺少安全扫描
**文件**: `.github/workflows/ci.yml`  
**问题**: 缺少 CodeQL 分析、Dependabot 自动更新、Dependency Review、SBOM 生成  
**修复**: 添加 CodeQL 工作流、Dependabot 配置、Dependency Review 步骤  
**验证**: `.github/dependabot.yml` 存在，ci.yml 包含 codeql-analysis 步骤

### P2-17: 缺少 security.txt (RFC 9116)
**问题**: 未实现 RFC 9116 标准安全联系文件  
**修复**: 在项目根目录创建 `.well-known/security.txt` 或在 SECURITY.md 顶部引用  
**验证**: 安全联系信息遵循 RFC 9116 格式

### P2-18: index.js 缺少 --help 标志
**文件**: `index.js`  
**问题**: 执行 `node index.js --help` 无响应  
**修复**: 添加 `--help` 参数处理，输出使用说明  
**验证**: `node index.js --help` 输出非空帮助文本

### P2-19: check_dependencies.py 浅合并 bug
**文件**: `scripts/check_dependencies.py:45-46`  
**问题**: `merged.update(custom_rules)` 当自定义规则指定部分键时完全覆盖默认规则，而非深度合并  
**影响**: 用户配置少量自定义规则时可能丢失大多数默认规则  
**修复**: 改为深度合并（逐层 update）

```python
# 当前（第 45-46 行）：
rules = DEFAULT_RULES.copy()
rules.update(custom_rules)  # shallow merge

# 修复后：
def deep_merge(base, override):
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result

rules = deep_merge(DEFAULT_RULES, custom_rules)
```

**验证**: 自定义 `rules.import_order.after` 应合并到默认规则，而非覆盖整个 `import_order`

### P2-20: CHANGELOG 缺失版本条目
**文件**: `CHANGELOG.md`  
**问题**: 缺少 v1.5.0 和 v1.5.5 版本条目（Git 历史中有对应 tag）  
**修复**: 根据 Git 历史补充缺失版本条目的变更说明  
**验证**: `grep -E '^## v1\.5\.[05]' CHANGELOG.md` 存在

### P2-21: 所有 SKILL.md 缺少版本字段
**文件**: `.claude/skills/*/SKILL.md`（10 个文件）  
**问题**: 所有 Skill 文件均无版本字段，无法追踪 Skill 规范的变更历史  
**修复**: 在每个 SKILL.md 的 frontmatter 中添加 `version: 1.0.0` 和 `lastUpdated: YYYY-MM-DD` 字段  
**验证**: `grep -L 'version:' .claude/skills/*/SKILL.md` 返回空

### P2-22: 长期未更新文件审计
**文件**: `docs/ROADMAP.md`、`docs/TROUBLESHOOTING.md`、`.claude/skills/safe-refactor/SKILL.md` 等  
**问题**: 这些文件长期未更新（仅有 1 次修改），内容可能已经过时  
**修复**: 逐一审查这些文件内容，标记是否需要弃用、更新或删除  
**验证**: 审查后的文件状态有明确标记（"已审查"、"待删除"、"已更新"）

---

## 执行顺序：七阶段计划

### Phase 0：P0 安全与 Bug 紧急修复（本周必须）

⚠️ **此阶段包含 8 个 P0 项，优先于所有其他修复。大多数 P0 项文件独立，可并行执行。**

| 文件 | 涉及修复项 | 并行组 | 说明 |
|:----:|:---------:|:------:|------|
| `configs/.pre-commit-config.yaml` | **P0-2** | 组 A | 6 处路径 `.claude/scripts/` → `scripts/` |
| `scripts/check_secrets.py` | **P0-3** | 组 A | SECRET_PATTERNS 统一为字符串 |
| `.claude/hooks/smart-context.sh` | **P0-4, P0-5, P0-6** | 组 B | 须串行：P0-6(替换回退) → P0-5(修复转义) → P0-4(修复正则) |
| `init.sh` | **P0-1, P0-7** | 组 C | 须串行：P0-1(删除重复) → P0-7(末尾添加trap) |
| `scripts/__pycache__/` | **P0-8** | 组 A | 删除目录 + .gitignore + package.json files 排除 |
| `package.json` | **P0-8** | 组 A | 同上，files 字段添加 `!scripts/__pycache__/` |

**并行执行说明**：
- 组 A（P0-2, P0-3, P0-8）：完全独立，可同时执行
- 组 B（P0-4, P0-5, P0-6）：同一文件，严格串行
- 组 C（P0-1, P0-7）：同一文件，严格串行
- 组 A/B/C 之间完全独立，可并行

**验证清单**：
```bash
# P0-1: grep -c 'git -C.*SCRIPT_DIR.*pull' init.sh 应返回 1
# P0-2: python3 scripts/check_project_structure.py 应正常执行
# P0-3: python3 -c "import re; [re.search(p, 'test') for p in [r'sk-', r'xox']]" 无 TypeError
# P0-4: echo "sudo rm -rf /" | grep -qE "...新正则..." && echo "MATCH"
# P0-5: json_escape "/path" 输出不含 \/
# P0-6: 无 timeout 环境中 Hook 不挂起
# P0-7: init.sh 中途 exit 1 后目标目录无残留
# P0-8: npm pack --dry-run 2>&1 | grep -c pyc 返回 0
```

### Phase 1：文本修复 + 独立新文件（可并行，无文件锁定冲突）

| 顺序 | 修复项 | 操作 | 验证 |
|:---:|:------:|------|------|
| 1 | P1-7 | init.sh/init.ps1 修正数字 | grep 检查数字 9 和 21 |
| 2 | P1-5 | CLAUDE.md 命令数 20→21 | 与 `ls commands/ | wc -l` 一致 |
| 3 | P1-6 | GUIDE.md 命令数 18→21 | 同上 |
| 4 | P1-9 | GUIDE.md 补充版本历史 | `grep 'v1.6.0' GUIDE.md` 存在 |
| 5 | P1-10 | SOUL.md 补充版本历史 | `grep 'v1.6.0' SOUL.md` 存在 |
| 6 | P1-8 | GUIDE.md 路径描述修正 | 文字方向正确 |
| 7 | P1-11 | commands/team.md 标记 Phase1 | 包含 "Phase 1" 标注 |
| 8 | P1-17 | README Node 版本统一 | README + package.json 一致 |
| 9 | P2-6 | QUICKSTART.md 调整 | 文本检查 |
| 10 | P2-7 | SOUL_Template.md 去重 | 只有 1 行 > 版本 |
| 11 | P2-14 | 19 个命令文件添加版本戳 | `grep -L '最后更新' commands/*.md` 为空 |
| 12 | P2-15 | 2 个命令文件 em dash → 连字符 | `grep '—' commands/*.md` 为空 |
| 13 | P2-20 | CHANGELOG 补充缺失版本 | 缺失版本条目已添加 |
| ✅ | **验证** | 逐项验证 | 全部通过 |

### Phase 2：新功能脚本（可并行）

| 顺序 | 修复项 | 操作 | 验证 |
|:---:|:------:|------|------|
| 1 | P1-1 | 新建 scripts/check_trigger_conflicts.py | `python3 scripts/check_trigger_conflicts.py` 退出码 0 |
| 2 | P1-2 | 新建 scripts/check_ecc.sh | `bash scripts/check_ecc.sh` 输出格式正确 |
| 3 | P1-3 | 新建 tests/hooks.test.js + router.test.js | `node --test tests/` 新增 2 个文件通过 |
| 4 | P1-4 | 修复 publish.yml Node 16 | grep 确认无 '16' |
| 5 | P1-18 | 添加 prepack 脚本 | `npm pack --dry-run` 不含 pyc |
| 6 | P1-22 | check_ecc.sh 添加完整性校验 | 版本不匹配时输出 MISMATCH |
| 7 | P2-18 | index.js 添加 --help | `node index.js --help` 输出帮助 |
| ✅ | **验证** | `npm test` + CI 模拟 | 全部通过 |

### Phase 3：P1 深度优化（Skill + Python 质量 + 安全策略）

| 顺序 | 修复项 | 操作 | 验证 |
|:---:|:------:|------|------|
| 1 | P1-13 | project-init SKILL.md 触发词移到 frontmatter | 触发词在 description 中 |
| 2 | P1-14 | brainstorming SKILL.md 添加终止条件 | 第 4 轮输出降级建议 |
| 3 | P1-15 | check_secrets.py bare except 限定异常类型 | `except (IOError, OSError)` 而非 `Exception` |
| 4 | P1-16 | check_import_order.py 补充标准库 | 缺失模块归类正确 |
| 5 | P1-19 | 5 个命令文件路径修复 | `grep -r '\.claude/scripts/' commands/` 无返回 |
| 6 | P1-20 | plan-ceo-review.md 删除 /autoplan 引用 | 无 autoplan 引用 |
| 7 | P1-21 | SECURITY.md 添加 PGP 章节 | 包含 PGP 密钥指纹 |
| 8 | P2-21 | 所有 SKILL.md 添加 version 字段 | `grep -L 'version:' .claude/skills/*/SKILL.md` 为空 |
| 9 | P2-22 | 长期未更新文件审计 | 审查结果有明确标记 |
| ✅ | **验证** | 全部 | 全部通过 |

### Phase 4：smart-context.sh 与 check_secrets.py 安全加固

⚠️ **此阶段涉及已修改文件的追加加固（依赖于 Phase 0 的修复）：**

| 顺序 | 修复项 | 操作 | 前提 |
|:---:|:------:|------|------|
| 1 | P1-23 | smart-context.sh 命令注入加固 | Phase 0 组 B 完成 |
| 2 | P2-19 | check_dependencies.py 深合并修复 | 独立 |
| 3 | P2-11 | CLAUDE_Template.md 日期统一 | 独立 |
| 4 | P2-12 | SPEC_Template.md 格式统一 | 独立 |
| ✅ | **验证** | 全部 | 全部通过 |

### Phase 5：complexity-rules.yaml + init 脚本集中修改

⚠️ **此阶段有文件锁定冲突，必须严格按顺序执行：**

| 阶段 | 顺序 | 修复项 | 修改方式 | 前提 |
|:---:|:---:|:------:|---------|------|
| 5a | 1 | P2-1 | complexity-rules.yaml risk_factors 中间插入 | 独立 |
| 5a | 2 | P2-2 | 末尾追加 negation_patterns | P2-1 后 |
| 5a | 3 | P2-3 | 末尾追加 trigger_priority | P2-2 后 |
| 5a | 4 | P1-12 | 最末尾追加 rollback_policy | P2-3 后 |
| 5a | ✅ | **验证** | `python3 -c "import yaml; yaml.safe_load(open('.claude/complexity-rules.yaml'))"` | 无错误 |
| 5b | 5 | P2-4 | 创建 script_whitelist.json，init 脚本改为 JSON 读取 | Phase 2 中新脚本一致 |
| 5b | 6 | P2-5 | 步号对齐（init.ps1 6 处编号修正）— ✅ 已完成 | P2-4 后行号稳定 |
| 5b | ✅ | **验证** | 全场景回归测试（3 场景） | 全部通过 |

#### P2-4 回归测试清单

```
# 场景 1：JSON 正常读取
→ 删除默认白名单，仅留 JSON → init.sh 应正确部署白名单中的文件

# 场景 2：JSON 不存在（fallback）
→ 删除 script_whitelist.json → init.sh 应使用默认硬编码白名单

# 场景 3：JSON 格式错误（fallback）
→ script_whitelist.json 写无效 JSON → init.sh 应使用默认白名单
```

### Phase 6：基础设施完善 + 长期优化

| 顺序 | 修复项 | 操作 | 验证 |
|:---:|:------:|------|------|
| 1 | P2-8 | pre-commit 添加 shellcheck | `pre-commit run shellcheck` |
| 2 | P2-9 | .npmignore + package.json files 同步 | `npm pack --dry-run` 检查 |
| 3 | P2-10 | configure-gitignore 同步检查 | diff 对比两个脚本 |
| 4 | P2-13 | 命令文件格式统一 | 所有文件符合同一模板 |
| 5 | P2-16 | CI 添加 CodeQL/Dependabot | `.github/dependabot.yml` 存在 |
| 6 | P2-17 | 创建 security.txt | 遵循 RFC 9116 |
| ✅ | **验证** | 全量回归 | `npm test` + CI |

---

## 文档同步确认

以下文件在"每次版本号变更"时需同步（共 5 个文件 8 处位置）：

| 文件 | 位置 | 内容 |
|------|------|------|
| `package.json` | version 字段 | 版本号 |
| `CLAUDE.md` | 第 4 行 header | 版本号 |
| `CLAUDE.md` | 版本历史章节 | 新增版本条目 |
| `init.sh` | 第 4 行 header + 第 57 行 banner | 版本号（2 处） |
| `init.ps1` | 第 3 行 header + 第 40 行 banner | 版本号（2 处） |
| `CHANGELOG.md` | 顶部 | 新增版本条目 |

> **注意**：HANDOVER-v1.6.0.md 第九节表格的"共 8 处"是准确的（5 个文件 × 8 个文本位置），**本文档不再将其视为错误**。

---

## 扩展统计

| 对比项 | 第一轮修正版 | 第二轮综合版 | 变化 |
|--------|-----------|-----------|------|
| P0 数量 | 1 | 8 | +7（安全/可靠性/发布缺陷） |
| P1 数量 | 12 | 23 | +11（含 Skill 格式、安全策略、命令路径等） |
| P2 数量 | 11 | 23 | +12（含模板格式、命令一致性、CI 增强等） |
| 总计 | 24 | 54 | +30 |
| 审查 Agent 数 | 5 | 13 | +8 专门领域 Agent |
| 执行阶段 | 5 | 7 | +2（Phase 0 P0 紧急 + Phase 3 P1 深度优化） |
| 涉及文件 | ~30 | ~60+ | 扩大至全部项目文件 |

> **说明**：第二轮 8 个 Agent 覆盖了首轮未深入的专业领域（Git 历史、Skill 规范、Python 质量、npm 发布、错误恢复路径、模板一致性、命令格式、安全策略），发现的问题多为"运行时会暴露"的缺陷，而非纯文档问题。优先级评估基于：运行时影响程度 × 修复复杂度。

---

*文档版本：v1.6.0*
*创建时间：2026-05-01*
*下次复审：2026-06-01*