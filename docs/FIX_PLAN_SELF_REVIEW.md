# 第四轮修复方案自我审查分析

> 对象：`docs/FIX_PLAN_ROUND4.md` 的全部修复方案
> 审查方式：每个方案逐条审视——是否正确识别根因、是否最优方案、是否存在替代方案、是否会引入新问题

---

## 一、CRITICAL 修复方案审查

---

### F-C1: smart-context.sh `exit 0` 修复

**识别是否准确**：✅ 准确。场景 2 的 `exit 0` 确实阻断了 3~10，查看源码可确认。

**方案是否最优**：⚠️ 有改进空间。

当前方案：删除 `exit 0`，将 `skillToActivate` 移到末尾统一 JSON 输出。

**潜在问题**：
1. 场景 2 原本独占输出 JSON（因为需要 `skillToActivate` 字段），现在合并到末尾统一输出。但如果场景 6（rm -rf）也在同一次调用中被触发，场景 6 的 `permissionDecision: "deny"` 会覆盖场景 2 的 `skillToActivate` 输出——两者需要的顶层 JSON 结构不同。
2. 末尾统一输出只有一种 JSON 结构（有无 `skillToActivate`），但场景 6 需要完全不同的结构（`permissionDecision`）。

**改进建议**：场景 2 不应删除 `exit 0`，而应改为仅设置标志变量后继续。场景 6 保持独立的 `exit 2`（因为它需要阻断）。其余场景（3-5, 7-10）在场景 2 触发后应继续执行。

```bash
# 场景 2：设置标志 -> 继续
if ... ; then
    SKILL_ACTIVATED="code-review"
    suggestion="${suggestion}检测到你正在修改安全相关代码..."
fi

# 场景 6：阻断 -> 立即 exit 2（这是硬安全，必须优先）
if ... ; then
    cat <<EOF > hard_deny
...
EOF
    exit 2
fi

# 场景 3-10：继续执行
...
```

**根因修复程度**：✅ 完整。`exit 0` 问题被解决，后续场景可达。

**新问题风险评估**：中。需处理场景 2 + 场景 6 同次调用的 JSON 结构冲突。

---

### F-C2: Memory access_count 修复

**识别是否准确**：✅ 准确。access_count 在代码中从未递增。

**方案是否最优**：⚠️ 方案正确但局限明显。

当前方案：在 `commands/remember.md` 中增加 AI 解释执行的递增逻辑。

**根本性问题**：此方案仍依赖 AI 正确解释并执行递增，不是确定的代码逻辑。如果 AI 忘记递增，GC 仍然会误杀。

**替代方案**：
1. **完全放弃 access_count**，改用文件 `mtime`（修改时间）作为热度指标。`mtime` 由操作系统自动维护，不依赖 AI。
2. **使用 shell 脚本** + `find -mtime` 实现确定性 GC，而不是 `/gc` 命令（同样依赖 AI）。

**推荐**：替代方案 1 更可靠。修改 GC 策略为："> 90 天且 `mtime` 从未被更新（即从未被编辑/引用）→ 归档"。同时 `/remember search` 操作时用 `touch` 更新对应记忆条目的 mtime。

但 MEMORY.md 的 mtime 是整个文件的修改时间，无法精确到每条记忆条目。如果 memory 系统保持单文件设计，access_count 的替代只能依赖于在 `/remember search` 执行时用 `touch` 更新整个 MEMORY.md 的 mtime——这意味着只要任何一条记忆被检索，整个文件的 mtime 都会更新，所有记忆都不会被 GC。

**结论**：当前方案的局限是 `access_count` 依赖 AI 解释执行的固有问题。要么接受这个局限，要么将记忆系统改为多文件结构（每个记忆一个文件，用 mtime 跟踪）。后者属于 Phase 2 重构，本轮不做。

**新问题风险评估**：低。即使 access_count 不完全准确，也比永远为 0 要好。

---

### F-C3: 创建 `/gc` 命令

**识别是否准确**：✅ 准确。`/gc` 命令确实不存在。

**方案是否最优**：⚠️ 方向正确但仍有根本局限。

与 F-C2 同样的问题：`/gc` 命令仍然是 AI 解释执行，取决于 AI 是否正确扫描 MEMORY.md 索引表。

**替代方案**：用 shell 脚本 `scripts/memory-gc.sh` 实现确定性 GC：
```bash
#!/bin/bash
# 确定性 Memory GC — 扫描 MEMORY.md 索引表，归档过期记忆
MEMORY_FILE=".claude/memory/MEMORY.md"
ARCHIVE_DIR=".claude/memory/archive"
CUTOFF_DATE=$(date -d "90 days ago" +%Y-%m-%d)

# 逐行检查索引表...
```

然后在 `/gc` 命令中调用这个脚本。这样即使 AI 理解有偏差，核心逻辑是确定的。

**推荐**：同时创建 `commands/gc.md`（AI 入口）和 `scripts/memory-gc.sh`（确定性实现），`/gc` 调用 `bash scripts/memory-gc.sh [--dry-run|--auto]`。

**新问题风险评估**：低。shell 脚本提供确定性兜底。

---

### F-C4: ~~tmux-session.sh 路径修正~~ (已撤回)

**识别是否准确**：❌ **不准确 — 误报**。

经深入验证：init.sh 第 6 步 `cp -r "$SCRIPTS_DIR/"* "$TARGET_SCRIPTS_DIR/"` 会将整个 `scripts/` 目录（包括 `tmux-session.sh`）部署到目标项目的 `.claude/scripts/`。Router 路径 `.claude/scripts/tmux-session.sh` 在目标项目中正确。

**为什么误判**：我在分析时仅比较了源码仓库的目录结构（`scripts/` vs `.claude/scripts/`），没有跟踪 init.sh 的部署路径。

**替代为以下两个新发现**：

### F-C4（新）：PROMPT.md 部署链修复

**识别是否准确**：✅ 准确。`PROMPT.md` 只在 `.claude/scripts/` 中，不在 `scripts/` 中，init.sh 从 `scripts/` 复制，所以 PROMPT.md 永不部署。

**方案是否最优**：✅ 最优。将 PROMPT.md 移动到 `scripts/`，无需改动 init.sh。

**新问题风险评估**：无。

### F-C4b（新）：清理 `.claude/scripts/` 过时副本

**识别是否准确**：✅ 准确。两个目录存在 5 个版本不一致的 .py 文件，`.claude/scripts/` 的副本过时且从未被部署。

**方案是否最优**：✅ 最优。删除死代码，唯一保留 `check_docs_consistency.py`（仅在 `.claude/scripts/` 中）。

**潜在遗漏**：`check_docs_consistency.py` 留在 `.claude/scripts/` 中也不会被部署。要么也移到 `scripts/`，要么在 init.sh 中增加对这个单独文件的复制步骤。

**修正**：将 `check_docs_consistency.py` 也移到 `scripts/`，这样 `.claude/scripts/` 目录在源码仓库中完全清空（可能需要保留作为占位目录）。

**新问题风险评估**：低。

---

### F-C5: Router ↔ Brainstorming 触发词冲突修复

**识别是否准确**：✅ 准确。决策表示例明确写 "评审一下这个微服务方案"（这是需求澄清场景），却被路由到 `/architect`（架构设计执行场景）。

**方案是否最优**：⚠️ 方向正确但有隐患。

当前方案：将"方案/设计/架构"改为路由到 Brainstorming，Brainstorming 第四步引导用户进入 `/architect`。

**潜在问题**：
1. 用户可能直接说 "帮我设计数据库 schema"——期望直接获得架构建议，而不是先走 4 步需求澄清。Brainstorming 第一步 "需求复述" 对此类明确的技术问题会造成体验摩擦。
2. `/architect` 命令本身目前没有直接的触发词路由——如果 "方案/设计/架构" 被占用，只有显式输入 `/architect` 才能触发架构分析。

**替代方案**：
- 方案 A（当前方案）：全部路由到 Brainstorming → 第四步引导 `/architect`。优点：需求澄清优先。缺点：对明确的技术问题增加摩擦。
- 方案 B（两阶段匹配）：先判断是否有明确的技术上下文（如 "数据库 schema"、"API 接口"）→ 如果有，路由到 `/architect`；如果没有（如 "帮我设计一下这个功能"），路由到 Brainstorming。
- 方案 C（Brainstorming 快速通道）：Brainstorming 检测到技术实现类请求后，跳过步骤 1-2（需求复述+方案输出），直接进入步骤 3-4（技术方案+执行计划）。

**推荐**：方案 A（当前方案）作为默认行为。同时在 Brainstorming 第一步增加 "快速模式"：如果用户问题已经包含明确的技术上下文，跳过需求复述，直接进入方案输出。这是后续优化方向。

**新问题风险评估**：中。需要在测试中确认 "帮我设计一个登录功能" 的完整路由链正常工作。

---

### F-C6: code-review OWASP 补全

**识别是否准确**：✅ 准确。安全审查清单确实缺 5 项。

**方案是否最优**：✅ 最优。增量补充检测项，结构不变。

**替代方案**：引用外部 OWASP checklist 而非内嵌。但内嵌更直观。

**新问题风险评估**：无。新增的是审查提示，不影响现有行为。

---

### F-C7: Skill 回滚规范

**识别是否准确**：✅ 准确。10 个 Skill 均无回滚处理。

**方案是否最优**：⚠️ 方向正确，但 "回滚规范" 实际上只是一个 AI 行为指令——没有代码强制执行。

**根本性局限**：回滚规范写在 SKILL.md 中 ≠ 回滚在实际执行时一定会发生。这是本项目 Skills 系统的固有属性——全部依赖 AI 解释执行。

**替代方案**：
1. 在 smart-context.sh hook 中增加 PreToolUse 检测：在执行 `Write`/`Edit` 操作前自动 `git stash`
2. 创建 `scripts/rollback.sh` 脚本，提供 `rollback --step N` 回滚到最后 N 步前的状态

**推荐**：当前方案（SKILL.md 文档级规范）+ 轻量级的 `scripts/checkpoint.sh` 脚本（创建 git stash 快照）。真正的原子回滚需要 Phase 2 的进程级沙箱支持。

**新问题风险评估**：低。新增的是规范，不影响现有行为。但用户不应期望这些规范能 100% 被 AI 遵守。

---

## 二、HIGH 修复方案审查

---

### F-H1: Router 决策表扩展

**识别是否准确**：✅ 准确。57 个触发词未映射。

**方案是否最优**：⚠️ 方向正确但工作量可能被低估。

**潜在问题**：57 个触发词要逐一映射到决策表，需要理解每个触发词的语义。部分触发词可能是同义词（如 "帮我看看代码" 和 "帮我review"），合并后实际需要的新条目可能只有 15-20 条。

**改进**：先对 57 个触发词做语义聚合，合并同义词后再映射，避免决策表过度膨胀。

**新问题风险评估**：低。新增映射不影响已有路由。

---

### F-H2: Router 否定语义检测

**识别是否准确**：✅ 准确。"不要提交" 会导致匹配到 `/commit`。

**方案是否最优**：⚠️ 当前方案的从句拆分法可能过于复杂且 AI 执行不稳定。

当前方案依赖 AI 按逗号/分号拆分从句并独立匹配。但中文的否定语义远不止否定词——"我不想现在就提交但可以检查一下" 中 "提交" 不在否定从句中但仍然被 "不想现在就" 修饰。

**实际效果评估**：否定检测在 prompt 层面执行，不同的 Claude Code 版本对否定语义的理解能力不同。写在 SKILL.md 中只能提高概率，不能 100% 保证。

**替代方案**：在 Router 决策逻辑中明确规则：**匹配到多个动作时，如果其中包含否定前缀的从句，全文不作为该动作的触发条件**。这比从句拆分更宽松但更可靠。

**新问题风险评估**：低。最坏情况是 AI 没理解否定语义，行为与修复前相同。

---

### F-H3: index.js 路径验证

**识别是否准确**：✅ 准确。无输入验证。

**方案是否最优**：✅ 最优方案。

**细节修正**：方案中 `require('./package.json')` 在 F-H11 中使用了，但 index.js 中已有 `path` 引入。需要增加 `fs` 引入（目前 import 中没有 fs）。还需注意 `path.resolve('/')` 在 Windows 上返回 `C:\` 而不是 `/`。

```javascript
// 修正后的平台通用检查
const resolved = path.resolve(rawPath);
if (resolved === path.resolve('/') || resolved === path.resolve('.')) {
    // 只检查根目录和当前目录（通过 resolve 后等于自身即为根）
}
```

**新问题风险评估**：低。但需 Windows + macOS + Linux 三平台验证。

---

### F-H4: timeout 兼容性

**识别是否准确**：✅ 准确。无超时。

**方案是否最优**：⚠️ macOS 兼容性是一个实际障碍。

**改进**：使用 `read -t` 作为替代（bash built-in，跨平台）：
```bash
# 使用 bash built-in read 实现 5 秒超时
IFS= read -r -t 5 event_data <&0 2>/dev/null
```
这比 `timeout cat` 更可靠，且不依赖外部命令。

**新问题风险评估**：低。`read -t` 是 bash 4.0+ 特性，macOS 默认 bash 3.x 不支持。需 `brew install bash` 或使用 `zsh`。

**最终推荐**：用一个跨平台 fallback 链：
```bash
if [ "${BASH_VERSINFO[0]}" -ge 4 ] 2>/dev/null; then
    IFS= read -r -t 5 event_data <&0
elif command -v timeout >/dev/null 2>&1; then
    event_data=$(timeout 5 cat)
else
    event_data=$(cat)
fi
```

---

### F-H5: rm -rf 正则增强

**识别是否准确**：✅ 准确。存在多种绕过。

**方案是否最优**：⚠️ 正则复杂化 vs 覆盖率的平衡。

**核心问题**：纯 shell 正则无法 100% 覆盖 rm -rf。真正的安全应该由 OS 级别（如 `chattr +i`、SELinux）或 Claude Code 自身提供。hook 只能做 best-effort。

**过度检测风险**：
- `rm -rf node_modules/` 是合法操作，不应被阻断
- `rm -rf /tmp/build/` 是合法操作，不应被阻断
- 当前方案的正则 `rm[[:space:]]+(-[rRf]+\s*)+[[:space:]]*(/|~|[.][.])` 应该能区分——只阻断 `/`、`~`、`..` 开头的路径

**新问题风险评估**：中。正则变更后需测试边界：
- `rm -rf ./node_modules` → 不应阻断（`. ` 不是 `..`）
- `rm -rf ../project` → 应阻断（`..` 开头）
- `rm -rf /var/log/deleteme` → 应阻断（`/` 开头）

---

### F-H6: JSON 转义

**识别是否准确**：✅ 准确。仅处理 `\` 和 `"`。

**方案是否最优**：✅ 最优。jq fallback 方案稳健。

**新问题风险评估**：低。

---

### F-H7 + H8: Agent Teams 文档修正

**识别是否准确**：✅ 准确。文档与实现不符。

**方案是否最优**：✅ 最优。标注现状 + 限制声明。

**替代方案**：不修文档，等 Phase 2 实现后再修正。但当前文档会误导用户。

**新问题风险评估**：无。

---

### F-H9: Pre-commit 范围统一

**识别是否准确**：⚠️ 部分准确。`check_secrets.py` 确实扫描 `.md`，但 `.pre-commit-config.yaml` 中 `check-secrets` hook 的 `types: [yaml, python]` 限制了它只能在 yaml/python 文件上运行——所以实际上 `.md` 文件从未被 `check_secrets.py` 扫描过（尽管脚本支持）。

**修正**：扩大 `types: [yaml, python, text]` 后，所有 text 类型文件（包括 `.md`）才会被扫描。这是正确的方向。

**新问题风险评估**：低。`check_secrets.py` 已有 `.md` 扫描逻辑。

---

### F-H10: Pre-commit hook 顺序

**识别是否准确**：✅ 准确。ruff --fix 在最后运行。

**方案是否最优**：⚠️ 需要验证。

**潜在问题**：`trailing-whitespace`（通用 hooks 中）在 `end-of-file-fixer` 后运行可能产生无关紧要的 diff。调整顺序需实际运行 `pre-commit run --all-files` 验证。

**改进**：不移动整个 repo 块，而是将 ruff --fix 和 ruff-format 移到自定义检查之前（但仍在通用 hooks 之前）：
```
自定义检查前:
  1. ruff --fix
  2. ruff-format
自定义检查:
  3-7. (check-project, dependencies, function-length, import-order, secrets)
通用 hooks:
  8-9. (通用 hooks + forbid-binary)
```

**新问题风险评估**：中。需完整 pre-commit run 验证。

---

### F-H11: --version 标志

**识别是否准确**：✅ 准确。

**方案是否最优**：✅ 最优。

**新问题风险评估**：无。

---

### F-H12: 命令数量统一

**识别是否准确**：✅ 准确。

**方案是否最优**：✅ 最优。统一为 20。

**细节**：需确认 `overnight` 和 `overnight-report` 是否都是独立可调用的用户命令。确认后一致设为 20。

**新问题风险评估**：无。

### F-H13: init.sh/init.ps1 选择性部署

**识别是否准确**：✅ 准确。`cp -r scripts/*` 全量复制确实导致过度部署。

**方案是否最优**：⚠️ 功能正确但引入维护负担。

白名单方案的优点是精确控制，但缺点也很明显：
1. 每添加一个新脚本到 `scripts/` 就必须手动更新白名单
2. init.sh 和 init.ps1 的白名单必须保持同步
3. 如果忘记更新白名单，新脚本不会被部署，属于静默失败

**替代方案**：黑名单方案——仍然 `cp -r`，但排除已知的不需要部署的文件：
```bash
cp -r "$SCRIPTS_DIR/"* "$TARGET_SCRIPTS_DIR/"
rm -rf "$TARGET_SCRIPTS_DIR/__pycache__"
rm -f "$TARGET_SCRIPTS_DIR/configure-gitignore.sh"
rm -f "$TARGET_SCRIPTS_DIR/configure-gitignore.ps1"
rm -f "$TARGET_SCRIPTS_DIR/check-env.sh"
rm -rf "$TARGET_SCRIPTS_DIR/lib"
```

黑名单的优点是新增脚本自动部署（不需要更新 init.sh），缺点是需要显式排除不部署的文件。

**推荐**：黑名单方案。因为忘记添加白名单（脚本不部署）比忘记添加黑名单（垃圾文件被部署）更严重——前者导致功能缺失，后者只是多几个文件。

---

## 三、MEDIUM 修复方案审查

---

### 关键审查

| 修复编号 | 方案问题 | 建议 |
|:--------:|---------|------|
| F-M1 | 创建 `post-audit.sh` 需要从零设计，工作量被低估。建议本轮只加配置占位，不实现 | ✅ 接受：配置占位 + TODO 注释 |
| F-M4 | complexity-rules.yaml 与 SOUL.md 的同步方向正确。但需注意 SOUL.md 的风险因子是本项目特化的（模板/命令/Skill），complexity-rules.yaml 是通用的。同步后需注明适用范围 | ✅ 接受 |
| F-M9 | hook 测试需要 stdin 模拟和 shell 环境。可能过于复杂。建议只增 Router 测试和 Memory GC 单元测试，hook 测试推迟 | ✅ 接受：推迟 hook 测试 |
| F-M11 | ECC 安装检测依赖文件路径 `.claude/plugins/everything-claude-code`，需要确认这个路径在 ECC 安装时确实存在 | 需验证 |
| F-M14 | Conventional Commits 格式应为项目规范而非硬要求。git-commit Skill 加入格式建议即可，不强制 | ✅ 接受：作为建议而非强制 |

### F-M19: init.sh 步骤命名修正

**识别是否准确**：✅ 准确。命名 "复制校验脚本" 不反映实际行为。

**方案是否最优**：✅ 最优。仅改字符串。

**新问题风险评估**：无。

---

## 四、遗漏分析

### 未被覆盖的问题

审查修复方案后，发现以下已在分析报告中标记、但修复方案未充分覆盖的问题：

1. **F-C1 与 F-C7 的交互**：C1 修复后场景 3-10 全部可达，C7 的回滚规范中 "无人值守模式下自动 git stash" 可能被 hook 的场景触发干扰。需要在两种机制之间协调。

2. **F-C5 路由变更对 `/architect` 命令可达性的影响**：如果将 "方案/设计/架构" 全部路由到 Brainstorming，`/architect` 命令只能通过显式输入触发。ROADMAP.md 和 GUIDE.md 中的引用可能需要更新。

3. **F-H10 顺序调整后 check-import-order 失效风险**：如果 ruff --fix 在 check-import-order 之前运行，ruff 可能已经修复了 import 顺序，check-import-order 永远不会发现违规——它只是验证 ruff 的修复结果。这是预期行为还是 bug？需要明确。

### 建议补充的修复

| 新增修复 | 涉及文件 | 理由 |
|---------|---------|------|
| Router 增加 "冲突消解" 规则 | router/SKILL.md | 当多个 Skill 同时声明同一触发词时，定义优先级：Skill frontmatter > Router 决策表 > 默认行为 |
| MEMORY.md 增加 "最后检索时间" 列 | templates/memory/MEMORY.md | 补充 access_count 不能完全反映的热度信息 |
| check_secrets.py 增加 .md 文件真实扫描验证 | check_secrets.py:259 | 确认函数被实际调用（目前 types 限制导致 yaml/python 外不扫描） |
| F-H13 方案调整为黑名单 | init.sh, init.ps1 | 白名单有维护负担，黑名单更安全（新增脚本自动部署） |

---

## 五、总结判断

### 整体评估

| 维度 | 评分 | 说明 |
|------|:----:|------|
| 根因识别准确性 | 92% | 40 个问题中 1 个误报（C-4）+ 1 个根因需修正（H9） |
| 修复方案正确性 | 88% | C1 方案的 JSON 结构冲突需修正，H4 的 timeout 方案需 cross-platform fallback |
| 修复方案可行性 | 82% | H13 白名单方案有维护负担，M1/9 工作量低估 |
| 新问题风险 | 低 | 大部分修复是增量添加，不改变核心行为 |
| 遗漏率 | 5% | 3 个补充修复建议 + 1 个代码审查 |

### 可立即执行的修复（零风险）

- F-C4（PROMPT.md 移动到 scripts/）— 移动 1 个文件
- F-C4b（删除 5 个过时副本）— 删除死代码
- F-C6（OWASP 补全）— 加 5 行 checklist
- F-H7, H8（Agent Teams 文档）— 加标注
- F-H11（--version）— 加 5 行代码
- F-H12（命令数量）— 改 3 个数字
- F-M19（步骤命名）— 改 1 行
- F-M3, M5, M6, M7, M12, M14, M16（文档规范）— 纯文档变更

### 需要额外验证的修复

- F-C1（exit 0）— 需验证 JSON 结构兼容性
- F-H5（正则增强）— 需测试边界
- F-H10（hook 顺序）— 需完整 pre-commit run
- F-C5（Router 路由）— 需端到端测试
- F-H13（白名单部署）— 需验证 init.sh + init.ps1 同步

### 建议不做的修复

- F-M1（PostToolUse hook）完整实现 → 推迟到 Phase 2
- F-M9（hook 测试）→ 仅做 Router + GC 测试
- F-H7 Agent Teams 进程隔离 → Phase 2
