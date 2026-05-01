# 第四轮修复方案 — claude-code-init v1.5.4 → v1.5.5

> 基于 `docs/ANALYSIS_ROUND4.md` 的 37 个发现，逐个制定修复方案
> 修复目标版本：v1.5.5

---

## 修复范围总览

| 修复编号 | 严重度 | 涉及文件 | 变更类型 |
|:--------:|:------:|---------|----------|
| F-C1 | 🔴 | `.claude/hooks/smart-context.sh` | Bug 修复 |
| F-C2 | 🔴 | `commands/remember.md`, `templates/memory/MEMORY.md`, 新增 `scripts/memory-gc.sh` | 实现补全 + Bug 修复 |
| F-C3 | 🔴 | 新增 `commands/gc.md` | 新增功能 |
| F-C4 | 🔴 | `.claude/skills/router/SKILL.md` | 路径修正 |
| F-C5 | 🔴 | `.claude/skills/router/SKILL.md` | 路由规则修正 |
| F-C6 | 🔴 | `.claude/skills/code-review/SKILL.md` | 安全检查项补全 |
| F-C7 | 🔴 | 全部 10 个 `SKILL.md` | 新增回滚规范 |
| F-H1 | 🟠 | `.claude/skills/router/SKILL.md` | 决策表扩展 |
| F-H2 | 🟠 | `.claude/skills/router/SKILL.md` | 新增否定检测 |
| F-H3 | 🟠 | `index.js` | 输入验证 |
| F-H4 | 🟠 | `.claude/hooks/smart-context.sh` | 超时保护 |
| F-H5 | 🟠 | `.claude/hooks/smart-context.sh` | 正则增强 |
| F-H6 | 🟠 | `.claude/hooks/smart-context.sh` | 转义完善 |
| F-H7 | 🟠 | `commands/team.md`, `docs/AGENT_TEAMS_GUIDE.md` | 文档修正 |
| F-H8 | 🟠 | `commands/team.md` | 新增约束声明 |
| F-H9 | 🟠 | `configs/.pre-commit-config.yaml` | 范围统一 |
| F-H10 | 🟠 | `configs/.pre-commit-config.yaml` | 顺序调整 |
| F-H11 | 🟠 | `index.js` | 新增 --version |
| F-H12 | 🟠 | `CLAUDE.md`, `init.sh` | 数字修正 |
| F-M1 | 🟡 | `.claude/settings.json` | 配置启用 |
| F-M2 | 🟡 | `index.js` | 警告提示 |
| F-M3~18 | 🟡 | 多个文件 | 文档/规范统一 |

---

## 🔴 CRITICAL 修复方案

---

### F-C1: 修复 smart-context.sh `exit 0` 阻断后续场景

**根因**：场景 2 在输出 JSON 后 `exit 0`，场景 3~10 不可达。

**修复方案**：删除 `exit 0`，场景 2 改为在 `suggestion` 变量中设置安全建议后继续执行后续检查。安全文件检测的输出由末尾统一 JSON 输出处理。

**修改文件**：`.claude/hooks/smart-context.sh`

**具体变更**：
```diff
 # ─── 场景 2：编辑安全相关文件 → 确定性加载 code-review ───
 if echo "$file_path" | grep -qiE "(auth|login|password|token|secret|session|encrypt|jwt|oauth|crypto|ssl|tls|hash|cipher|cert|sign|rsa_key|api_key|private_key|secret_key)" 2>/dev/null; then
     if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
     suggestion="${suggestion}检测到你正在修改安全相关代码。「code-review」技能已自动加载。"
-    # 确定性 Skill 激活（不依赖语义匹配）
-    escaped=$(json_escape "$suggestion")
-    cat <<EOF
-{
-  "hookSpecificOutput": {
-    "hookEventName": "PreToolUse",
-    "skillToActivate": "code-review",
-    "suggestion": "$escaped"
-  }
-}
-EOF
-    exit 0
+    # 标记 code-review 技能已自动激活（不依赖语义匹配）
+    SKILL_ACTIVATED="code-review"
 fi
```

同时修改末尾统一 JSON 输出逻辑（约第 135 行），补上 `skillToActivate` 字段：
```diff
 if [ -n "$suggestion" ]; then
+    if [ -n "$SKILL_ACTIVATED" ]; then
+        cat <<EOF
+{
+  "hookSpecificOutput": {
+    "hookEventName": "PreToolUse",
+    "skillToActivate": "$SKILL_ACTIVATED",
+    "suggestion": "$escaped"
+  }
+}
+EOF
+    else
+        cat <<EOF
+{
+  "hookSpecificOutput": {
+    "hookEventName": "PreToolUse",
+    "suggestion": "$escaped"
+  }
+}
+EOF
+    fi
 fi
```

**验证方法**：
1. 构造安全文件路径输入，确认触发场景 2 + 场景 6 同时生效果
2. 测试：`file_path="auth/login.js" command="rm -rf /"` → 应同时输出安全建议 + rm -rf 阻断
3. 回归测试：所有 23 个测试仍通过

**风险**：低。场景 2 原本独占输出，现在合并到末尾统一输出，JSON 结构保持兼容。

---

### F-C2: 修复 Memory `access_count` 从不禁用递增

**根因**：`access_count` 字段仅在 MEMORY.md 模板中声明，无任何代码/命令递增它。

**修复方案**：在 `/remember` 命令的检索逻辑中加入 `access_count` 递增机制。同时调整 GC 策略为 `> 90 天且从未被检索（access_count = 0）`，降低误杀概率。

**修改文件**：
1. `commands/remember.md` — 在 "search" 和 "show" 子命令逻辑中加入递增
2. `templates/memory/MEMORY.md` — 修正 GC 策略描述

**具体变更**：

`commands/remember.md` — 新增 `access_count` 递增逻辑：
```diff
 ## 执行逻辑
 
 1. 读取 `.claude/memory/MEMORY.md` 顶部的索引表获取概览
 2. 根据子命令定位到 MEMORY.md 中的对应章节
 3. 编辑操作：直接修改 MEMORY.md 对应章节中的记忆条目
 4. GC 操作：
    - 扫描所有记忆的日期
    - 标记 > 90 天且 access_count = 0 的记忆
    - 展示预览："将归档 X 条，建议删除 Y 条"
    - 用户确认后执行（归档 → archive/，删除 → 永久移除）
+
+## access_count 递增规则
+
+> **重要**：每次 `/remember search` 或 `/remember show <ID>` 检索到记忆时，
+> 必须递增对应记忆条目的 access_count。这是 GC 的基础数据。
+>
+> 实现方式：
+> 1. 在 MEMORY.md 索引表中找到对应 memory-id 的行
+> 2. 将 access_count 值 +1
+> 3. 确保索引表 `access_count` 列与实际值保持同步
```

`templates/memory/MEMORY.md` — 修正 GC 描述（使语义更准确）：
```diff
-access_count 表示该记忆被检索次数（GC 依据：>90 天且 access_count = 0 → 归档）。
+access_count 表示该记忆被检索次数。
+每次通过 /remember search 或 /remember show 检索到记忆时自动递增。
+GC 依据：>90 天且 access_count < 2（即几乎未被检索过）→ 归档。
```

**验证方法**：
1. 在 MEMORY.md 中创建一条模拟记忆，access_count = 0
2. 执行 `/remember search` 检索该记忆
3. 确认 access_count 变为 1
4. 执行 `/remember show <ID>` 
5. 确认 access_count 变为 2

**风险**：中。此修复依赖 AI 解释执行 access_count 递增，仍非完全确定性。后续可考虑用 shell 脚本实现。

---

### F-C3: 实现 Memory GC — 创建 `/gc` 命令

**根因**：`MEMORY.md` 引用 `/gc` 命令但该命令不存在。

**修复方案**：创建 `commands/gc.md`，定义确定性 GC 流程。

**修改文件**：新增 `commands/gc.md`

**具体内容**：
```markdown
# /gc — 记忆垃圾回收

清理过期记忆，保持 MEMORY.md 精简。

## 用法

| 命令 | 作用 |
|------|------|
| `/gc` | 扫描过期记忆，交互式确认后清理 |
| `/gc --dry-run` | 仅预览，不执行清理 |
| `/gc --auto` | 非交互模式，自动清理（用于无人值守） |

## GC 策略

符合条件的记忆将被归档：
- 日期 > 90 天前
- 且 access_count = 0（从未被检索）

## 执行流程

### 1. 扫描
读取 `templates/memory/MEMORY.md` 的索引表，逐行检查每条记忆的日期和 access_count。

### 2. 预览（--dry-run 或交互模式）
```markdown
## GC 扫描结果

| memory-id | 日期 | access_count | 天数 | 操作 |
|-----------|------|:-----------:|:----:|:----:|
| ADR-001 | 2025-12-01 | 0 | 151 | 归档 |
| BUG-003 | 2026-01-15 | 1 | 106 | 保留 |

- 将归档: 1 条
- 将保留: X 条
```

### 3. 执行（用户确认后）
- 归档的记忆 → 移到 `archive/ARCHIVE-YYYY-MM-DD.md`
- 清理后更新 MEMORY.md 索引表，移除已归档条目
- 输出清理摘要

### 4. 无人值守模式（--auto）
- 仅处理 access_count = 0 的记忆
- 不询问确认，直接归档
- 输出到 `.claude/reports/gc-YYYYMMDD.md`

## 相关命令
- `/remember` — 记忆管理
```

**验证方法**：
1. 创建模拟 MEMORY.md，包含一条 >90 天且 access_count=0 的记忆
2. 执行 `/gc --dry-run`，确认预览正确
3. 执行 `/gc`，确认记忆被归档

**风险**：低。GC 不影响模板本身，仅清理用户项目中的记忆文件。

---

### F-C4: 修复 PROMPT.md 部署链 — 从 `.claude/scripts/` 移动到 `scripts/`

**根因**：init.sh 从 `scripts/` 复制到目标项目 `.claude/scripts/`，但 `PROMPT.md` 只存在于 `.claude/scripts/` 不在 `scripts/` 中。tmux-session.sh 依赖 PROMPT.md 作为默认任务文件。

**修复方案**：
1. 将 `PROMPT.md` 从 `.claude/scripts/` 移动到 `scripts/`（与部署源一致）
2. Router 路径保持不变（`.claude/scripts/tmux-session.sh` 是正确的）

**修改文件**：
- 移动：`.claude/scripts/PROMPT.md` → `scripts/PROMPT.md`
- 无需修改 `init.sh`（`cp -r scripts/*` 会自动包含 PROMPT.md）
- 无需修改 Router（路径已验证正确）

**验证方法**：
1. 确认 `scripts/PROMPT.md` 存在
2. 运行 init.sh 后确认目标项目 `.claude/scripts/PROMPT.md` 存在
3. 在目标项目中执行 `bash .claude/scripts/tmux-session.sh` 无参数模式不报错

**风险**：无。仅移动文件位置。

---

### F-C4b: 清理 `.claude/scripts/` 中 5 个过时的 Python 重复副本

**根因**：Python 校验脚本在 `scripts/` 和 `.claude/scripts/` 中各有一份。init.sh 只从 `scripts/` 部署，所以 `.claude/scripts/` 的副本是死代码，且版本过时。

**修复方案**：删除 `.claude/scripts/` 中与 `scripts/` 重复的 5 个 .py 文件。PROMPT.md 已移至 `scripts/`（见 F-C4）。

**修改文件**（删除）：
- `.claude/scripts/check_dependencies.py`
- `.claude/scripts/check_function_length.py`
- `.claude/scripts/check_import_order.py`
- `.claude/scripts/check_project_structure.py`
- `.claude/scripts/check_secrets.py`
- `.claude/scripts/__pycache__/`

**保留文件**：
- `.claude/scripts/check_docs_consistency.py`（唯一，不在 scripts/ 中）

**验证方法**：
1. 确认 `scripts/` 中有完整的 5 个 .py 文件
2. 确认 `.claude/scripts/` 中仅剩 `check_docs_consistency.py`（无重复）
3. 运行 pre-commit 确认校验脚本正常工作

**风险**：低。`.claude/scripts/` 的副本从未被部署，删除不影响任何功能。

---

### F-C5: 修正 Router ↔ Brainstorming 触发词冲突

**根因**：`方案/设计/架构` 同时被 Router 决策表路由到 `/architect` 和 Brainstorming 声明为触发词。

**修复方案**：Router 决策表第 4 行改为：`架构、方案、设计` → 启动「需求头脑风暴」技能（非直接 /architect）。Brainstorming 完成需求澄清后，由 Brainstorming 流程的第四步决定是否进入 `/architect`。

**修改文件**：
1. `.claude/skills/router/SKILL.md:34` — 路由修正
2. `.claude/skills/brainstorming/SKILL.md:40` — 第四步增加 `/architect` 过渡

**具体变更**：

Router:
```diff
-| 架构、方案、设计 | 执行 `/architect` 命令 | "评审一下这个微服务方案" |
+| 架构、方案、设计 | 启动「需求头脑风暴」技能 | "评审一下这个微服务方案" |
```

Brainstorming 第四步增加：
```diff
 ### 第四步：制定执行计划
 - 将方案拆解为可独立执行的原子任务
 - 按优先级排序
 - 估算每个任务的复杂度（0-5分），触发对应的执行模式
+- 确认后推荐使用 `/architect` 进入技术架构设计阶段
```

**验证方法**：
1. 构造输入 "帮我设计一个用户认证方案" → 确认路由到 Brainstorming
2. 构造输入 "帮我分析一下当前架构" → 确认路由到 Brainstorming
3. 确认 "这个代码架构有问题" 不会被错误路由

**风险**：中。需确认 `/architect` 命令的入口不会被完全绕过（Brainstorming 第四步确认后会引导用户使用）。

---

### F-C6: 补全 code-review OWASP Top 10 检查项

**根因**：code-review 安全审查清单仅覆盖 5 项 OWASP Top 10。

**修复方案**：在安全审查 checklist 中补齐缺失的 5 项检查。

**修改文件**：`.claude/skills/code-review/SKILL.md:32-35`

**具体变更**：
```diff
 ### 2. 安全审查
 - [ ] SQL 注入风险（参数化查询）
 - [ ] XSS 风险（输出转义）
 - [ ] 认证/授权漏洞
 - [ ] 敏感信息泄露（密钥、日志）
 - [ ] 依赖第三方数据的验证
+- [ ] 不安全的设计模式（Insecure Design — OWASP A04）
+- [ ] 过期或有漏洞的依赖（Vulnerable Components — OWASP A06）
+- [ ] 反序列化与 CI/CD 完整性（Software Integrity — OWASP A08）
+- [ ] 日志安全与监控信息泄露（Logging & Monitoring — OWASP A09）
+- [ ] 服务端请求伪造（SSRF — OWASP A10）
```

**验证方法**：暂无自动化测试。人工检查 SKILL.md 中安全审查清单完整覆盖 OWASP 2021 Top 10 全部 10 项。

**风险**：无。

---

### F-C7: 为所有 Skill 新增回滚规范

**根因**：10 个 Skill 流程定义中均无 failure rollback 步骤。

**修复方案**：在每个 SKILL.md 的流程定义后新增 "失败处理" 章节。不同 Skill 按风险等级分类处理：

**风险分级**：

| 级别 | Skill | 回滚策略 |
|:----:|-------|---------|
| 高 | code-review, safe-refactoring, git-commit | 必须声明回滚边界，修改前 git stash 备份 |
| 中 | tdd-workflow, error-fix, project-init | 分步提交，每步可独立回滚 |
| 低 | code-explain, brainstorming, project-validate, router | 只读/咨询类，无需回滚 |

**修改文件**：全部 10 个 SKILL.md

**高优 Skill 的新增模板**（以 safe-refactoring 为例）：
```markdown
## 失败处理（回滚机制）

- **修改前**：`git stash push -m "pre-refactor-{timestamp}"` 保存当前状态
- **步骤级回滚**：每个文件的修改在独立 commit 中，失败时 `git reset --hard HEAD~1`
- **整体回滚**：`git stash pop` 恢复到修改前完整状态
- **无人值守**：重试 ≤3 次，失败后跳过并记录到 `.claude/reports/blocked.md`
```

**低优 Skill 的新增模板**（以 code-explain 为例）：
```markdown
## 失败处理

本技能为只读操作，不修改任何文件。无需回滚。
```

**验证方法**：检查 10 个 SKILL.md 均包含 "失败处理" 或 "回滚" 相关章节。

**风险**：低。新增的是 AI 行为规范，不改变现有流程。

---

## 🟠 HIGH 修复方案

---

### F-H1: Router 决策表扩展 — 补齐 57 个缺失触发词

**根因**：Skill frontmatter 声明 57 个触发词未纳入 Router 决策表。

**修复方案**：
- 将 Router 决策表的触发词从各 Skill 的 frontmatter description 中提取并补充
- 同时审计决策表中无对应 Skill 声明的触发词，与 Skill owner 对齐

**修改文件**：`.claude/skills/router/SKILL.md`

**具体变更**：在决策表中新增以下条目：

| 新增触发词 | 来源 Skill | 路由目标 |
|-----------|-----------|---------|
| 怎么实现、帮我梳理 | brainstorming | 启动「需求头脑风暴」 |
| 技术选型、评估方案 | brainstorming | 启动「需求头脑风暴」 |
| 代码审计、安全检查 | code-review | 启动「代码审查」(强化安全) |
| 该怎么做、帮我分析 | brainstorming | 启动「需求头脑风暴」 |
| 项目配置 | project-init | 启动「项目初始化」 |

（完整 57 个触发词的映射表在代码 diff 中展开）

**验证方法**：grep 各 Skill 的 frontmatter 触发词 → 确认 Router 决策表中有对应映射。

**风险**：低。新增映射不影响已有路由。

---

### F-H2: Router 新增否定语义检测

**根因**：Router 将 "不要提交" 匹配为 `/commit`。

**修复方案**：在决策逻辑新增前缀检查，在匹配前检测否定词。

**修改文件**：`.claude/skills/router/SKILL.md`

**具体变更**：在 "决策逻辑" 表格前新增：
```markdown
## 否定语义过滤

在匹配决策表前，先扫描否定模式。如果触发词前出现以下否定词，则该触发词不生效：

| 否定词 | 示例 | 处理 |
|--------|------|------|
| 不要、别、不用、不、别、取消 | "不要提交，先检查" | "提交" 被过滤，"检查" 正常触发 |
| 先不、暂时不、不该 | "先不重构" | "重构" 被过滤 |

**实现规则**：
1. 拆分用户输入为从句（按逗号、分号、句号）
2. 每个从句独立匹配触发词
3. 从句中出现否定词 → 该从句中的触发词不生效
4. 其他从句正常匹配
```

**验证方法**：
- "不要提交，先帮我检查一下" → 应仅触发 code-review，不触发 /commit
- "先不重构，审查一下安全性" → 应仅触发 code-review，不触发 safe-refactoring
- "提交代码" → 正常触发 /commit（不受影响）

**风险**：低。否定词检测在匹配决策表之前，不影响正向匹配。

---

### F-H3: index.js 新增 --project-path 路径验证

**根因**：`--project-path` 接受任意字符串，无验证。

**修复方案**：在解析 `--project-path` 后增加验证逻辑。

**修改文件**：`index.js`

**具体变更**：
```javascript
// 在 projectPath 解析后，path.resolve 之前新增：
function validateProjectPath(rawPath) {
    const resolved = path.resolve(rawPath);
    
    // 1. 禁止根目录和上级目录
    const dangerousPaths = ['/', 'C:\\', 'D:\\', '/root', '/home'];
    if (dangerousPaths.includes(resolved) || resolved === path.resolve('/')) {
        console.error('[错误] 禁止使用根目录作为项目路径。');
        console.error('请使用 --project-path ./my-project 指定子目录。');
        process.exit(1);
    }
    
    // 2. 禁止路径中包含 shell 元字符
    if (/[\$`;|&<>(){}]/.test(rawPath)) {
        console.error('[错误] 项目路径包含不安全字符。');
        process.exit(1);
    }
    
    // 3. 检查目标目录是否已存在 claude-code-init 产物
    if (fs.existsSync(path.join(resolved, 'CLAUDE.md'))) {
        console.warn('[警告] 目标目录似乎已经初始化过（存在 CLAUDE.md）。');
        console.warn('继续执行将覆盖现有配置。');
    }
    
    return resolved;
}
```

**验证方法**：
- `npx claude-code-init --project-path /` → 应报错
- `npx claude-code-init --project-path "../../"` → 应报错
- `npx claude-code-init --project-path "$(whoami)"` → 应报错（shell 元字符）
- `npx claude-code-init --project-path ./my-project` → 正常通过

**风险**：低。仅增加验证逻辑，不改变正常行为。需注意 Windows 盘符路径 `C:\` 的处理。

---

### F-H4: smart-context.sh 新增 timeout 保护

**根因**：`cat` 读 stdin 无超时。

**修复方案**：用 `timeout` 命令包裹 stdin 读取。

**修改文件**：`.claude/hooks/smart-context.sh:11`

```diff
-event_data=$(cat 2>/dev/null)
+event_data=$(timeout 5 cat 2>/dev/null)
 if [ -z "$event_data" ]; then
     exit 0
 fi
```

**验证方法**：在测试中向 hook 输入空 stdin，确认 5 秒后退出而非挂起。

**风险**：macOS 默认不含 `timeout` 命令（需 coreutils）。增加兼容性处理：
```bash
# 跨平台 timeout 兼容
if command -v timeout >/dev/null 2>&1; then
    event_data=$(timeout 5 cat 2>/dev/null)
elif command -v perl >/dev/null 2>&1; then
    event_data=$(perl -e 'alarm 5; eval { local $SIG{ALRM} = sub { die "timeout\n" }; print <STDIN> }' 2>/dev/null)
else
    event_data=$(cat 2>/dev/null)
fi
```

---

### F-H5: smart-context.sh rm -rf 检测正则增强

**根因**：当前正则 `rm\s+-rf\s+(/|~|\.\.|\.)` 可以被 flag 顺序、长选项、变量展开绕过。

**修复方案**：扩展正则覆盖更多绕过方式。

**修改文件**：`.claude/hooks/smart-context.sh:77`

```diff
-# 场景 6：rm -rf 物理阻断（最高优先级）
-if echo "$command" | grep -qE "rm\s+-rf\s+(/|~|\.\.|\.)" 2>/dev/null; then
+# 场景 6：rm -rf / 危险删除物理阻断（最高优先级）
+# 覆盖：rm -rf /、rm -r -f /、rm --recursive --force /、rm "-rf" /、rm -rf ~
+if echo "$command" | grep -qE "(^|[;&|])[[:space:]]*rm[[:space:]]+(-[rRf]+\s*)+[[:space:]]*(/|~|[.][.])" 2>/dev/null; then
     cat <<EOF
 {
   "hookSpecificOutput": {

 # 场景 7：rm 危险删除命令警告
-if echo "$command" | grep -qE "rm\s+-[rRf]" 2>/dev/null; then
+if echo "$command" | grep -qE "(^|[;&|])[[:space:]]*rm[[:space:]]+(-[rRf]+|--recursive|--force)([[:space:]]|$)" 2>/dev/null; then
```

**注意**：不检测变量展开（`rm $VAR`）和命令替换（`rm $(...)`），因为纯 shell 正则无法安全地追踪变量值。此限制在注释中说明。

**验证方法**：
- `rm -rf /` → 阻断
- `rm -r -f /` → 阻断
- `rm --recursive --force /` → 阻断
- `rm $FLAGS /tmp` → 不阻断但警告（变量不可追踪）
- `find . -name '*.tmp' -exec rm -rf {}` → 不阻断但警告

**风险**：中。正则增强可能带来误报。需充分测试常见合法 rm 用法（如 `rm -rf node_modules/`）不会被误判为根目录删除。

---

### F-H6: smart-context.sh JSON 转义完善

**根因**：`json_escape` 仅处理 `\` 和 `"`，未处理控制字符。

**修复方案**：补全 JSON 转义字符集。

**修改文件**：`.claude/hooks/smart-context.sh:8`

```diff
 json_escape() {
-    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
+    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\//\\\//g' \
+        | while IFS= read -r line; do printf '%s\\n' "$line"; done \
+        | sed 's/\\n$//'
 }
```

更好的方案——使用 `jq` 如果可用：
```bash
json_escape() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$1" | jq -Rs '.'
    else
        # 回退：基础转义
        printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\//\\\//g'
    fi
}
```

**验证方法**：
- 输入含换行符 → JSON 中显示 `\n`
- 输入含 `"` → JSON 中显示 `\"`
- 输入含 `\` → JSON 中显示 `\\`

**风险**：低。jq 方案更健壮，但需声明 jq 为可选依赖。

---

### F-H7: Agent Teams 文档修正 — 标注 prompt-level 本质

**根因**：文档暗示多进程隔离，实际是 prompt roleplay。

**修复方案**：在 `commands/team.md` 顶部新增 "实现说明" 明确当前能力边界。

**修改文件**：`commands/team.md`、`docs/AGENT_TEAMS_GUIDE.md`

**具体变更**（team.md 顶部新增）：
```markdown
# /team - 启动 Agent 团队

> **实现说明（v1.5.5）**：当前 Agent Teams 在同一次 Claude Code 会话中通过 prompt
> 模拟多个角色进行协作审查。这不是真实的进程隔离，所有 "agent" 共享同一上下文。
> 真实的并行 agent 编排（git worktree + 独立进程）是 Phase 2 的目标。
> 参见 `docs/ROADMAP.md` Phase 2 计划。
```

**验证方法**：无。

**风险**：无。仅修正文档预期，不改变行为。

---

### F-H8: Agent Teams 新增约束声明

**根因**：无成本控制、无超时、无死锁检测。

**修复方案**：在 team.md 中新增 "约束与限制" 章节，声明 AI 应遵守的硬限制。

**修改文件**：`commands/team.md`

**具体变更**（在 "最佳实践" 后新增）：
```markdown
## 约束与限制

### Token 预算
- 单个 teammate 报告不超过 2000 tokens
- Lead 汇总报告不超过 5000 tokens
- 超过预算自动截断并标注

### 超时控制
- 单个 teammate 完成任务的最长 prompt 轮次：20 轮
- 超时后 teammate 输出当前进度并标记为 "时间不足"

### 输出格式
- 所有 teammate 必须使用 "标准汇报格式"（见上文）
- 不按格式的输出将被 Lead 拒绝并要求重新提交
```

**验证方法**：无，此为 AI 行为规范，依赖 AI 遵守。

**风险**：无。

---

### F-H9: Pre-commit check_secrets 与 detect-private-key 范围统一

**根因**：`detect-private-key` 排除 `.md` 文件，`check_secrets.py` 扫描 `.md`，策略矛盾。

**修复方案**：统一策略——`check_secrets.py` 是业务层扫描，扫描全部文件（保持现有行为）；`detect-private-key` 是系统级关键扫描，也加入对 `.md` 的支持。同时 `check-secrets` hook 的 `types` 从 `[yaml, python]` 扩展为扫描更多文件。

**修改文件**：`configs/.pre-commit-config.yaml`

```diff
 # 5. 密钥安全检查
 - repo: local
   hooks:
     - id: check-secrets
       name: Security check (secrets)
       entry: python .claude/scripts/check_secrets.py
       language: system
-      types: [yaml, python]
+      types: [yaml, python, text]
       pass_filenames: false
       stages: [pre-commit]
```

同时在 `detect-private-key` 中保留现有的排除逻辑，因为 `check_secrets.py` 提供了更精细的 `.md` 扫描，`detect-private-key` 的粗粒度排除是合理的。策略改为：大量文件由 `detect-private-key` 快速扫描，`.md` 文件由 `check_secrets.py` 精细扫描。

**验证方法**：向 `.md` 文件添加假密钥，确认 `check_secrets.py` 触发告警。

**风险**：低。`check_secrets.py` 已有 `.md` 扫描逻辑（代码第 259 行），此变更仅放宽 hook 的 `types` 过滤。

---

### F-H10: Pre-commit ruff --fix 顺序调整

**根因**：`ruff --fix` 在 check_secrets 等自定义钩子之后运行，修复后代码不被重新检查。

**修复方案**：将 ruff 移到自定义检查之前。

**修改文件**：`configs/.pre-commit-config.yaml`

**具体变更**：调整 repo 顺序为：
1. ruff --fix（自动修复格式）
2. ruff-format
3. check-project-structure
4. check-dependencies
5. check-function-length
6. check-import-order
7. check-secrets
8. mypy
9. 通用 hooks（trailing-whitespace 等）
10. forbid-binary-files

**验证方法**：创建有格式问题 + 潜在密钥的代码 → ruff 先修复格式 → check_secrets 再扫描（包含 ruff 修复引入的变更）。

**风险**：中。ruff --fix 可能引入新的代码行，这些行中的密钥需要被后续的 check_secrets 捕获。顺序调整后确保这一点。但需确认 `trailing-whitespace` 在 `end-of-file-fixer` 之后不会覆盖 key 检测器的结果。

---

### F-H11: index.js 新增 --version 标志

**根因**：index.js 不支持 `--version`。

**修复方案**：在参数解析后增加 `--version` 处理。

**修改文件**：`index.js`

**具体变更**：
```javascript
// 在参数解析循环中新增：
for (let i = 0; i < args.length; i++) {
    if (args[i] === '--version' || args[i] === '-v') {
        const pkg = require('./package.json');
        console.log(`claude-code-init v${pkg.version}`);
        process.exit(0);
    }
    if (args[i] === '--project-path' && args[i + 1]) {
        projectPath = args[i + 1];
    } else if (args[i].startsWith('--project-path=')) {
        projectPath = args[i].split('=')[1];
    }
}
```

**验证方法**：
- `node index.js --version` → 输出 `claude-code-init v1.5.4`
- `node index.js -v` → 同上

**风险**：无。

---

### F-H12: 修正命令数量不一致

**根因**：CLAUDE.md 说 17 个，init.sh 说 18 个，实际 20 个。

**修复方案**：统一为实际数字 20，并声明计数规则（20 个可独立调用的斜杠命令）。

**修改文件**：
- `CLAUDE.md:23` → "20 个斜杠命令"
- `CLAUDE.md:49` → "20 个斜杠命令 (→ .claude/commands/)"
- `init.sh:505` → "20 个自定义命令（/review /commit /architect /fix /refactor /explain /validate /help /team /qa /capabilities /status /remember /overnight /overnight-report /plan-ceo-review /plan-eng-review /routine /messages /tdd）"

**验证方法**：`ls commands/*.md | wc -l` = 20。CLAUDE.md 和 init.sh 的计数一致为 20。

**风险**：无。

---

### F-H13: init.sh / init.ps1 选择性部署 — 过滤 init-only 文件

**根因**：`cp -r scripts/*` 全量复制，将 `__pycache__/`、`configure-gitignore.*`、`check-env.sh`、`lib/common.sh` 等仅 init 时使用的文件部署到目标项目。

**修复方案**：改全量复制为白名单选择性复制。

**修改文件**：`init.sh:185-193`、`init.ps1:169-176`

**init.sh 变更**：
```diff
 echo_step "复制校验脚本到 .claude/scripts/"
-SCRIPTS_DIR="$SCRIPT_DIR/scripts"
-TARGET_SCRIPTS_DIR="$PROJECT_PATH/.claude/scripts"
-if [ "$SCRIPTS_DIR" = "$TARGET_SCRIPTS_DIR" ]; then
-    echo_info "源目录与目标目录相同，已跳过脚本复制"
-elif [ -d "$SCRIPTS_DIR" ] && [ "$(ls -A "$SCRIPTS_DIR" 2>/dev/null)" ]; then
-    mkdir -p "$TARGET_SCRIPTS_DIR"
-    cp -r "$SCRIPTS_DIR/"* "$TARGET_SCRIPTS_DIR/"
-    find "$TARGET_SCRIPTS_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
-    echo_success "已复制校验脚本到 .claude/scripts/"
-else
-    echo_info "scripts 目录为空或不存在，跳过"
-fi
+
+# 部署目标项目需要的脚本（白名单）
+# - Python 校验脚本（pre-commit hooks 使用）
+# - Shell 工具脚本（Skills/Router 引用）
+# 不包括：check-env.sh、configure-gitignore.*、lib/common.sh（仅 init 时用）
+# 不包括：__pycache__/（编译缓存）
+
+SCRIPT_WHITELIST="check_dependencies.py check_function_length.py check_import_order.py check_project_structure.py check_secrets.py check_docs_consistency.py tmux-session.sh weekly-report.sh ralph-setup.sh trigger-optimizer.sh validate_skills.sh PROMPT.md"
+
+SCRIPTS_DIR="$SCRIPT_DIR/scripts"
+TARGET_SCRIPTS_DIR="$PROJECT_PATH/.claude/scripts"
+if [ "$SCRIPTS_DIR" = "$TARGET_SCRIPTS_DIR" ]; then
+    echo_info "源目录与目标目录相同，已跳过脚本复制"
+elif [ -d "$SCRIPTS_DIR" ]; then
+    mkdir -p "$TARGET_SCRIPTS_DIR"
+    for file in $SCRIPT_WHITELIST; do
+        if [ -f "$SCRIPTS_DIR/$file" ]; then
+            cp "$SCRIPTS_DIR/$file" "$TARGET_SCRIPTS_DIR/"
+        fi
+    done
+    find "$TARGET_SCRIPTS_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
+    echo_success "已复制校验脚本和工具到 .claude/scripts/"
+else
+    echo_info "scripts 目录为空或不存在，跳过"
+fi
```

**init.ps1 变更**（同样改为白名单）：
```powershell
$ScriptWhitelist = @(
    "check_dependencies.py", "check_function_length.py",
    "check_import_order.py", "check_project_structure.py",
    "check_secrets.py", "check_docs_consistency.py",
    "tmux-session.sh", "weekly-report.sh", "ralph-setup.sh",
    "trigger-optimizer.sh", "validate_skills.sh", "PROMPT.md"
)
foreach ($file in $ScriptWhitelist) {
    $src = Join-Path $ScriptsDir $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $TargetScriptsDir -Force
    }
}
```

**验证方法**：
1. 运行 init.sh 后检查目标项目 `.claude/scripts/` 目录
2. 确认不包含 `__pycache__/`、`configure-gitignore.*`、`check-env.sh`、`lib/`
3. 确认包含 `tmux-session.sh`、`PROMPT.md`、`check_secrets.py` 等白名单文件
4. 运行 `pre-commit run --all-files` 确认校验脚本正常工作

**风险**：中。白名单需要与 `scripts/` 中的文件保持同步。新增文件时如果忘记更新白名单将不会被部署。

---

### F-M1: settings.json 启用 PostToolUse hook

**修改文件**：`.claude/settings.json`

```diff
 {
   "env": {
     "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
   },
   "hooks": {
     "PreToolUse": [
       {
         "matcher": "Edit",
         "command": "bash .claude/hooks/smart-context.sh"
       },
       {
         "matcher": "Bash",
         "command": "bash .claude/hooks/smart-context.sh"
       }
     ]
   }
 }
```

当前仅 PreToolUse，无 PostToolUse。但由于 smart-context.sh 的 10 个场景都是 PreToolUse 语义（事前建议），PostToolUse 需要单独的 hook 脚本。创建最小化的 `post-audit.sh`：
```json
"PostToolUse": [
  {
    "matcher": "Bash",
    "command": "bash .claude/hooks/post-audit.sh"
  }
]
```

**风险**：低。PostToolUse hook 仅在 Bash 执行后做轻量审计（如检测 rm -rf 是否被绕过执行）。

---

### F-M2: index.js 不支持平台警告

**修改文件**：`index.js:118`

```diff
 } else {
+    if (!['linux', 'darwin'].includes(process.platform)) {
+        console.warn(`[警告] 平台 "${process.platform}" 未被完整测试，将使用 Bash 路径尝试初始化。`);
+    }
     // Unix/macOS: 使用 Bash
```

---

### F-M3: ROADMAP.md 同步

**修改文件**：`docs/ROADMAP.md`

- 标记已完成的 Skills 优化项为 ✅
- 标记已完成的 Agent Teams 为 ✅（标注 "prompt-level 实现，Phase 2 增强为进程级"）

---

### F-M4: complexity-rules.yaml 与 SOUL.md 风险因子对齐

**修改文件**：`.claude/complexity-rules.yaml`

将 risk_factors 中的项目与 SOUL.md 同步：

```diff
     risk_factors:
       - condition: "影响模块超过 1 个"
         score: 1
         type: count
+      - condition: "涉及模板/命令/Skill 结构变更"
+        score: 1
+        type: flag
       - condition: "涉及 API、数据库 schema 或数据结构变更"
         ...
       - condition: "修改安全相关代码（认证、授权、加密实现）"
         score: 2
         type: flag
+      - condition: "修改 SOUL.md / CLAUDE.md 核心规则"
+        score: 2
+        type: flag
+      - condition: "新增/修改 init 脚本"
+        score: 2
+        type: flag
+      - condition: "修改 templates/ 模板文件"
+        score: 2
+        type: flag
```

**风险**：低。对齐风险因子后 Router 评分更一致。

---

### F-M5: 骨架命令新增 fallback 提示

**修改文件**：7 个骨架命令（commit.md, review.md, fix.md, refactor.md, explain.md, validate.md, tdd.md）

每个骨架命令新增一行：
```markdown
> 如果 [对应 Skill] 未加载，请手动说 "加载 xxx 技能" 触发。
```

---

### F-M6: qa.md / plan-ceo-review.md 声明 ECC 依赖

**修改文件**：`commands/qa.md`、`commands/plan-ceo-review.md`

头部新增：
```markdown
> **依赖声明**：本命令依赖 ECC (Everything Claude Code) 插件。未安装时请使用本地替代方案。
> 本地替代：qa → 手动测试 / plan-ceo-review → /brainstorming + /plan-eng-review
```

---

### F-M7: SECURITY.md 同步威胁向量

**修改文件**：`SECURITY.md`

新增 smart-context.sh 实际检测的威胁：
```markdown
### Hook 级实时保护
- `smart-context.sh`：10 种场景实时检测，包括：
  - 安全文件编辑 → 自动加载 code-review
  - rm -rf 危险命令物理阻断
  - git push --force 警告
  - 敏感函数编辑提醒
```

---

### F-M8: .claude/settings.json hook 配置优化

已在 F-M1 中处理。同时增加注释说明 hook 用途。

---

### F-M9: 测试补充

**新增测试文件**：`tests/hooks.test.js`、`tests/router.test.js`

覆盖：
- Hook exit 0 回归测试
- rm -rf 检测正则边界测试
- Router 触发词冲突回归测试
- Router 否定语义测试

**风险**：中。hook 测试需要模拟 stdin 输入和 JSON 输出解析，依赖 shell 执行环境。

---

### F-M10: ruff --fix 后二次审查

已在 F-H10 中通过调整 hook 顺序解决。

---

### F-M11: Router ECC 安装检测

**修改文件**：`.claude/skills/router/SKILL.md`

新增检测逻辑（在 "外部依赖声明" 章节）：
```markdown
## ECC 安装检测

执行降级策略前，检测 ECC 是否安装：
- 检查 `.claude/settings.json` 中是否包含 ECC 相关配置
- 检查 `~/.claude/plugins/everything-claude-code` 目录是否存在
- 未安装时自动执行降级策略并提示
```

---

### F-M12: Skill 触发词统一规范

**新增文件**：`.claude/skills/TRIGGER_SPEC.md`

定义触发词规范：
```markdown
# Skill 触发词规范 v1.0

## 格式
- 中文触发词：用顿号或逗号分隔
- 英文触发词：用逗号分隔
- 触发词在 SKILL.md frontmatter 的 description 字段中声明

## 命名原则
- 每个触发词不超过 8 个字（中文）或 3 个单词（英文）
- 触发词应为用户自然语言中的常见表达
- 避免单字触发词（如 "改"、"查"）防止路由过载
```

---

### F-M13: Brainstorming 复杂度评分去重

**修改文件**：`.claude/skills/brainstorming/SKILL.md:40`

```diff
 ### 第四步：制定执行计划
 - 将方案拆解为可独立执行的原子任务
 - 按优先级排序
-- 估算每个任务的复杂度（0-5分），触发对应的执行模式
+- 按 SOUL.md 复杂度评估规则为每个任务评分，触发对应的执行模式
+  （由 Router 在接收到评分后自动选择执行深度，本步骤不自行路由）
```

---

### F-M14: git-commit Skill 加入 Conventional Commits

**修改文件**：`.claude/skills/git-commit/SKILL.md`

在流程中新增：
```markdown
### Commit 消息格式
必须遵循 Conventional Commits 规范：
```
<type>(<scope>): <description>
```
类型：feat / fix / docs / refactor / test / chore
```

---

### F-M15: init.sh SOUL 模板存在性验证

**修改文件**：`init.sh`

在引用 SOUL_Template.md 前新增检查：
```bash
if [ ! -f "$SCRIPT_DIR/templates/SOUL_Template.md" ]; then
    echo_warn "SOUL_Template.md 不存在，跳过 SOUL.md 生成"
else
    # 正常复制流程
fi
```

---

### F-M16: QUICKSTART.md 与 GUIDE.md 建议顺序统一

**修改文件**：`docs/QUICKSTART.md`

与 GUIDE.md 同步第一步建议：统一为 "先运行 npx claude-code-init，再阅读 GUIDE.md 了解完整功能"。

---

### F-M17: HANDOVER.md 拆分

**修改文件**：`docs/HANDOVER.md`

拆分为：
- `docs/ARCHITECTURE.md` — 架构决策（提取 ADR 和设计理念）
- `docs/OPERATIONS.md` — 运维流程（提取版本发布、测试流程）
- `docs/HANDOVER.md` — 保留为索引文档（精简到 ~8KB）

---

### F-M18: 命令/Skill 输出格式统一

**修改文件**：全部 SKILL.md 和 commands/*.md

统一输出格式约定：
```markdown
## 输出格式约定

所有 Skill 和命令输出必须包含：
1. **状态标记**：✅ 成功 / ⚠️ 警告 / ❌ 失败
2. **影响范围**：修改了哪些文件/模块
3. **下一步**：推荐的后续操作（可为空）
```

---

### F-M19: init.sh 步骤命名修正

**修改文件**：`init.sh:183-184`

```diff
-# 6. 复制 Python 校验脚本
-echo_step "复制校验脚本到 .claude/scripts/"
+# 6. 复制校验脚本和 Shell 工具
+echo_step "复制校验脚本和 Shell 工具到 .claude/scripts/"
```

**验证方法**：运行 init.sh 时确认步骤提示准确反映实际行为。

**风险**：无。

---

## 修复方案可行性分析

### 风险矩阵

| 修复编号 | 实施风险 | 回归风险 | 依赖风险 |
|:--------:|:------:|:------:|:------:|
| F-C1 | 低 | 低 | 无 |
| F-C2 | 低 | 低 | 依赖 AI 解释执行 |
| F-C3 | 低 | 低 | 无 |
| F-C4 | 低 | 低 | 无 |
| F-C4b | 低 | 低 | 确认 check_docs_consistency.py 保留 |
| F-C5 | 中 | 中 | 需确认 Brainstorming 第四步衔接 |
| F-C6 | 无 | 无 | 无 |
| F-C7 | 低 | 低 | 无 |
| F-H1 | 低 | 低 | 需人工审计触发词映射 |
| F-H2 | 低 | 低 | 需测试边界否定场景 |
| F-H3 | 低 | 低 | 需 Windows 盘符路径测试 |
| F-H4 | 中 | 低 | macOS timeout 命令兼容性 |
| F-H5 | 中 | 中 | 正则增强可能误报 |
| F-H6 | 低 | 低 | jq 可选依赖 |
| F-H7 | 无 | 无 | 无 |
| F-H8 | 无 | 无 | 无 |
| F-H9 | 低 | 低 | 无 |
| F-H10 | 中 | 中 | hook 顺序变更需全面测试 |
| F-H11 | 无 | 无 | 无 |
| F-H12 | 无 | 无 | 无 |
| F-H13 | 中 | 中 | 白名单需与 scripts/ 保持同步 |

### 关键风险点

1. **F-C5 (Router↔Brainstorming 冲突)**：将"方案/设计/架构"从 `/architect` 改路由到 Brainstorming 后，需确保用户做出需求澄清后仍能进入架构设计。Brainstorming 第四步的 `/architect` 引导是关键衔接。

2. **F-H10 (pre-commit hook 顺序)**：调整 hook 顺序后需完整运行 `pre-commit run --all-files` 确认顺序变更不引入新问题。

3. **F-H5 (rm -rf 正则增强)**：扩展正则后可能对合法 `rm -rf node_modules/` 产生误报。需在正则中排除不以 `/`、`~`、`..` 开头的路径。

4. **F-H4 (timeout 兼容性)**：macOS 不含 `timeout` 命令。使用 perl fallback 或 `brew install coreutils` 作为可选方案。

5. **F-H13 (scripts 白名单部署)**：白名单需要与 `scripts/` 中的文件保持同步。新增工具脚本时必须更新 init.sh 和 init.ps1 的白名单，否则不会被部署。

### 不修复的项目

以下 3 个 MEDIUM 问题**不在本轮修复**：

| 编号 | 问题 | 不修复原因 |
|:----:|------|-----------|
| F-H7 | Agent Teams 进程隔离 | 需要 Phase 2 级别的架构变更，不是补丁级修复 |
| F-M1 | PostToolUse hook | 需要新的 hook 脚本设计，留待 Phase 2 |
| F-M17 | HANDOVER.md 拆分 | 独立任务，避免与修复补丁混在同一个 commit |

### 估计变更量

| 类别 | 修改文件数 | 新增文件数 | 代码变更行数（估） |
|------|:-------:|:-------:|:-----------:|
| CRITICAL 修复 | 15 | 1 | ~160 |
| HIGH 修复 | 10 | 0 | ~200 |
| MEDIUM 修复 | 13 | 1 | ~90 |
| **合计** | **38** | **2** | **~450** |

---

## 修复顺序建议

| 轮次 | 修复项 | 原因 |
|:----:|--------|------|
| 第 1 批 | F-C1, F-C4, F-C4b, F-H3, F-H11, F-H12, F-M19 | **安全 + 零风险**：hook exit 0、PROMPT.md 部署链、重复文件清理、输入验证、版本标志、步骤命名——不可逆且无依赖 |
| 第 2 批 | F-C5, F-C6, F-H1, F-H2, F-H5 | **路由 + 安全 + 正则**：修正核心路由逻辑、安全审查清单、正则增强——有轻微依赖 |
| 第 3 批 | F-C2, F-C3, F-C7, F-H4, F-H6, F-H13 | **Memory + 回滚 + 部署 + 健壮性**：Memory GC 实现、回滚规范、timeout/JSON 增强、选择性部署——新功能较多 |
| 第 4 批 | F-H7 ~ H10, F-M2 ~ M18 | **文档 + 配置 + 规范**：文档修正、pre-commit 顺序、SECURITY.md 等——低影响但有文件级冲突风险 |

---

*本文档将在修复执行过程中持续更新。每条修复完成后在对应项后标记 ✅。*
