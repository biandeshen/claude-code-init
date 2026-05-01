# claude-code-init 维护要点

> 版本：v1.5.3 | 2026-04-30

本文档记录项目维护中容易遗漏的点和注意事项，作为 HANDOVER.md 的补充。

---

## 一、路径引用规则（最高频错误来源）

### 核心概念

项目有两套路径体系：

| 体系 | 含义 | 示例 |
|------|------|------|
| **源码路径** | 脚手架 npm 包中的文件位置 | `scripts/check_secrets.py` |
| **目标路径** | init 后用户项目中的文件位置 | `.claude/scripts/check_secrets.py` |

### 判定规则

- **Skills、pre-commit、CLI 命令中的路径引用 → 一律用目标路径**
- **init.sh/init.ps1 中的 COPY 源 → 用源码路径**
- **GUIDE.md / 文档中的目录树 → 描述源码结构**
- **GUIDE.md 中的运行命令示例 → 用目标路径**

### 真实案例

```
错误：Skills 中写 "python scripts/check_secrets.py"
正确：Skills 中写 "python .claude/scripts/check_secrets.py"

原因：Skill 在目标项目中运行，脚本已被 init 复制到 .claude/scripts/
```

---

## 二、init.sh 与 init.ps1 同步

### 当前状态（v1.5.2）

init.sh 和 init.ps1 的步号**不完全一致**：

| | init.sh | init.ps1 |
|------|---------|----------|
| 步数 | ~14 | ~15 |
| 3-4 步合并 | 已合并 | 已合并 |
| gstack 步骤 | 已删除 | 已删除 |
| 注释步号 | 有断裂（缺 6、8，两个 7） | 连续 |

### 修改规则

1. 修改 init 流程时，**两个文件都要改**
2. 步号注释修改优先在 init.sh 做（sed/Python 更可靠），init.ps1 手动改
3. init.ps1 编码必须是 **UTF-8 BOM**（PowerShell 5.x 兼容要求）
4. 修改后跑 `diff` 核对步号序列

### 已知问题

- init.sh 步号 6 和 8 缺失，有两个 "# 7" — 历史遗留，暂不影响功能
- init.sh 和 init.ps1 的 gstack 删除在不同轮次完成（R3 vs R4），步号因此不同步

---

## 三、npm 发布检查清单

### `package.json` "files" 字段

每次新增文件到 `.claude/` 目录时，**必须**检查是否需要加入 "files" 白名单。

当前白名单（v1.5.2）：
```
index.js, init.ps1, init.sh, templates/, commands/,
scripts/, configs/, .claude/skills/, .claude/hooks/,
.claude/scripts/, .claude/settings.json, .claude/complexity-rules.yaml
```

### `.npmignore` 防御

即使 "files" 是白名单，`.npmignore` 也要保持防御性条目：
- `venv/` — 防止本地 Python 虚拟环境被误发布
- `__pycache__/`, `*.pyc` — Python 缓存
- `docs/`, `GUIDE.md` — 文档不随包发布

### 发布前验证

```bash
npm pack --dry-run   # 查看哪些文件会发布
```

---

## 四、死代码风险模式

### 模式 1：未赋值变量

```bash
# 危险：$ROUTER_UNATTENDED 从未被赋值
ROUTER_SKILL="..."        # ← 定义了
# 但 $ROUTER_UNATTENDED 从未定义
if [ -f "$ROUTER_UNATTENDED" ]; then  # ← 永远为 false
    ...
fi
```

### 模式 2：仅在注释中使用的变量

```bash
ROUTER_SKILL="$PROJECT_DIR/.claude/skills/router/SKILL.md"
# 全文件 grep 只有定义没有引用 → 很可能死代码
```

### 检查方法

```bash
grep -n 'VARIABLE_NAME' script.sh
# 只有一行（定义行）→ 死代码
```

---

## 五、Pre-commit / Linter 文件干扰

### 症状

`Edit` 操作报错 "File has been modified since read"

### 原因

pre-commit hooks 或编辑器（如 PSScriptAnalyzer）会在文件保存后自动修改格式/编码

### 应对

1. Edit 前立即 Read（中间不做任何操作）
2. 使用更长的 `old_string` 确保唯一性
3. 最后手段：整文件 Write 覆盖

### 特别注意

- **不要在同一轮修改中多次 Edit 同一个文件** — 先规划好，一次性改完
- Bash heredoc 中的 Python 代码换行符问题 — Windows git-bash 与 Linux 行为不同

---

## 六、Windows 兼容性

| 问题 | 影响 | 解决 |
|------|------|------|
| Python GBK 编码 | `UnicodeDecodeError` | 所有 `open()` 加 `encoding='utf-8'` |
| sed 不支持某些语法 | `sed: unterminated address regex` | 用 Python 脚本替代复杂 sed |
| PowerShell UTF-8 BOM | PS 5.x 中文乱码 | `.ps1` 必须保存为 UTF-8 BOM |
| `nul` 文件 | 意外生成残留文件 | 删除，加到 .gitignore |
| CRLF/LF | git 自动转换警告 | 忽略，git 配置会处理 |

---

## 七、文档同步点

以下文档在修改功能后需要检查更新：

| 文档 | 需更新内容 |
|------|-----------|
| HANDOVER.md | 版本号、目录树、步号表、FAQ |
| GUIDE.md | 目录树、运行命令路径 |
| README.md | 功能描述变更 |
| CHANGELOG.md | 版本条目 |
| package.json | version 号、"files" 字段 |

### HANDOVER.md 目录树注意事项

- 目录树描述的是**源码包结构**，不是目标项目结构
- Python 脚本在源码中位于 `scripts/`，不是 `.claude/scripts/`
- 修改后必须和 `ls -R` 输出对比验证

---

## 八、版本号规范

- `package.json` version → 手动修改
- `docs/HANDOVER.md` 版本号 → 手动修改
- commit tag `v*` 会触发 publish.yml → 仅在准备发布时打 tag

---

*本文档随项目演化持续更新，新增问题请追加到对应章节。*
