# claude-code-init v1.6.0 交接文档

> 本文档覆盖第四轮多角色审查（40 项问题）修复后的完整项目状态。
> 重点标注了**容易遗漏的设计决策**和**未来维护中的注意事项**。
> 版本：v1.6.0 | 日期：2026-05-01

---

## 一、版本状态总览

| 文件 | 版本 | 说明 |
|------|:---:|------|
| `package.json` | 1.6.0 | 权威版本源 |
| `init.sh` | 1.6.0 | header + 运行时 banner 均已同步 |
| `init.ps1` | 1.6.0 | header + 运行时 banner 均已同步 |
| `CLAUDE.md` | 1.6.0 | header + 版本历史均已同步 |
| `CHANGELOG.md` | 1.5.5→1.6.0 | 6 个版本条目完整 |

### 第四轮修复统计

| 批次 | 版本 | 提交 | 修复数 |
|------|------|------|:---:|
| Batch 1 | v1.5.5 | `7ec075e` | 7 |
| Batch 2 | v1.5.6 | (含在 7ec075e) | 5 |
| Batch 3 | v1.5.7 | `3e6d5b7` | 6 |
| Batch 4 | v1.5.8 | `c32dd03` | 6 |
| Batch 5 | v1.5.9 | `5c06a71` | 7 |
| Batch 6 | v1.6.0 | `972bb90` | 1 |
| **合计** | | | **32** |

---

## 二、项目架构速览

```
claude-code-init/
├── index.js              # npx 入口（依赖检查 + 平台路由 + 路径验证）
├── init.sh               # Unix/macOS 初始化（14 步）
├── init.ps1              # Windows 初始化（约 15 步）
├── package.json          # npm 包定义（files 白名单决定发布内容）
│
├── scripts/              # 【部署源】— 所有要部署到目标项目的脚本
│   ├── check_dependencies.py       # pre-commit hook 使用的 Python 校验
│   ├── check_docs_consistency.py
│   ├── check_function_length.py
│   ├── check_import_order.py
│   ├── check_project_structure.py
│   ├── check_secrets.py
│   ├── tmux-session.sh              # Router 引用的 Shell 工具
│   ├── weekly-report.sh
│   ├── ralph-setup.sh
│   ├── trigger-optimizer.sh
│   ├── validate_skills.sh
│   ├── PROMPT.md                    # tmux-session.sh 的默认任务文件
│   ├── check-env.sh                # 【仅 init 使用，不部署】
│   ├── configure-gitignore.sh      # 【仅 init 使用，不部署】
│   ├── configure-gitignore.ps1     # 【仅 init 使用，不部署】
│   ├── lib/common.sh               # 【仅 init 使用，不部署】
│   └── __pycache__/                # 【编译缓存，不部署】
│
├── commands/             # 21 个斜杠命令（部署到 .claude/commands/）
├── templates/            # 5 个模板（部署到目标项目）
├── configs/              # .pre-commit-config.yaml（部署到目标项目）
│
├── .claude/              # 【项目自身的 Claude Code 配置】
│   ├── skills/           # 10 个 Skills + 1 个 TRIGGER_SPEC.md
│   ├── hooks/            # smart-context.sh（PreToolUse + PostToolUse）
│   ├── settings.json     # Hook 注册 + Agent Teams 环境变量
│   ├── complexity-rules.yaml  # 复杂度评估规则
│   └── scripts/          # 【已清空】— 所有脚本已迁移到 scripts/
│
├── docs/                 # 分析报告 + 修复方案 + 交接文档
└── tests/                # 23 个 Node.js 内置测试
```

---

## 三、⚠️ 最容易遗漏的设计决策

### 3.1 双目录设计：`scripts/` vs `.claude/scripts/`

这是项目**最高频的错误源**。两个目录职责完全不同：

| 目录 | 位置 | 职责 |
|------|------|------|
| `scripts/` | 源码包根目录 | **部署源**。init.sh Step 6 从此目录复制到目标项目 |
| `.claude/scripts/` | 目标项目（运行时） | **运行时**。pre-commit hooks 和 Skills 从此目录执行脚本 |

**⚠️ 关键规则**：
- **永远不要在源码包的 `.claude/scripts/` 中放文件** — 它已被清空且从 package.json 的 `files` 中移除
- 所有需要部署到目标项目的脚本 **必须放在 `scripts/`**
- 源码包 `.claude/scripts/` 不应该存在

### 3.2 部署白名单机制

init.sh Step 6 使用**白名单选择性复制**，不是 `cp -r scripts/*`：

```bash
SCRIPT_WHITELIST="check_dependencies.py check_function_length.py \
  check_import_order.py check_project_structure.py check_secrets.py \
  check_docs_consistency.py tmux-session.sh weekly-report.sh \
  ralph-setup.sh trigger-optimizer.sh validate_skills.sh PROMPT.md"
```

**⚠️ 关键规则**：新增脚本需要部署到目标项目时，**必须同时更新**：
1. 将文件放入 `scripts/`
2. 在 init.sh 的 `SCRIPT_WHITELIST` 中添加文件名
3. 在 init.ps1 的 `$ScriptWhitelist` 中添加文件名

遗漏任何一处将导致脚本不被部署。

### 3.3 PROMPT.md 部署链

`tmux-session.sh` 在无参数模式下读取 `.claude/scripts/PROMPT.md` 作为默认任务文件。
因此 PROMPT.md **必须部署到目标项目的 `.claude/scripts/`**。

当前状态：PROMPT.md 位于 `scripts/`，已纳入白名单 ✅

### 3.4 package.json `files` 字段

决定哪些文件被 npm publish 包含。⚠️ 当前不包含 `.claude/scripts/`（已清空）。修改后的规则：
- 脚本类文件 → 通过 `scripts/` 目录发布
- Skills/Hooks/Settings → 通过 `.claude/skills/`、`.claude/hooks/`、`.claude/settings.json` 发布
- 不要添加不存在的目录到 `files`

---

## 四、Hook 设计与安全注意事项

### 4.1 smart-context.sh 核心约束

**场景 2（安全文件检测）的 exit 0 问题已修复**。原先场景 2 在输出 JSON 后 `exit 0`，导致场景 3~10 永远不可达。修复方案：
- 场景 2 设置 `SKILL_ACTIVATED="code-review"` 标志
- 所有场景的 `suggestion` 累积到末尾
- 末尾统一输出 JSON，包含 `skillToActivate` 字段

**⚠️ 关键规则**：任何时候都不要在非阻断场景中使用 `exit`。只有场景 6（rm -rf 物理阻断）使用 `exit 2`。

### 4.2 rm -rf 检测正则

增强后的正则覆盖：
- `rm -rf /`、`rm -r -f /`（标志任意顺序）
- `rm --recursive --force /`（长选项）
- 命令链前缀：`;`、`&`、`|`

**⚠️ 已知限制**：无法检测变量展开（`rm $VAR`）和命令替换（`rm $(...)`）。此限制已在代码注释中说明。

### 4.3 JSON 转义

`json_escape` 函数优先使用 `jq -Rs`，回退到 sed 手动转义。
新增了换行符和控制字符的转义处理。

### 4.4 stdin 读取超时

使用跨平台兼容的超时方案：
1. `timeout 5 cat`（Linux）
2. `perl -e 'alarm 5...'`（macOS 不含 timeout）
3. 纯 `cat`（最后的回退）

### 4.5 PostToolUse Hook

`.claude/settings.json` 同时注册了 `PreToolUse` 和 `PostToolUse` hook，均指向 `smart-context.sh`。PostToolUse 对 Bash 操作执行事后审计。

---

## 五、Router 路由引擎注意事项

### 5.1 否定语义过滤

在决策表匹配前，先扫描否定词：
- 否定词：`不要`、`别`、`不用`、`跳过`、`取消`、`不需要`、`先不`、`暂时不`、`不该`
- 被否定的触发词不生效，其他从句正常匹配
- 示例：`"不要提交，先帮我检查一下"` → 过滤"提交"，触发"检查"

### 5.2 触发词冲突解决

`架构、方案、设计` 曾同时触发 `/architect` 命令和 `brainstorming` Skill。修复方案：
- Router 将此路由到 `brainstorming` Skill
- Brainstorming 第四步完成后推荐使用 `/architect`

### 5.3 触发词扩展

决策表已扩展为包含常见同义词，如：
- 审查 → 代码审计、audit、帮我review
- 修复 → error、fix、出错、排查问题
- 重构 → refactor、重命名、提取方法

### 5.4 ECC 依赖降级

Router 包含 ECC 安装检测逻辑。未安装时自动降级：
- `/qa` → 手动测试或 `/review`
- `/plan-ceo-review` → `/brainstorming`

---

## 六、Memory 系统

### 6.1 access_count 递增

`/remember search` 和 `/remember show` 检索到记忆时，必须递增对应记忆的 `access_count`。这是 GC 的数据基础。递增规则定义在 `commands/remember.md` 中。

### 6.2 GC 策略

`commands/gc.md` 定义了完整的 GC 流程：
- 扫描条件：日期 > 90 天 且 access_count < 2
- 三种模式：交互式 / `--dry-run` 预览 / `--auto` 无人值守
- 归档目标：`archive/ARCHIVE-YYYY-MM-DD.md`

---

## 七、Skill 回滚规范

所有 10 个 Skill 均包含"失败处理"章节，按风险分级：

| 风险级别 | Skill | 回滚策略 |
|:---:|------|------|
| 高 | code-review, safe-refactoring, git-commit | `git stash` 备份 + `git reset` 回滚 |
| 中 | tdd-workflow, error-fix, project-init | 步骤级回滚，每步独立可回退 |
| 低 | code-explain, brainstorming, project-validate, router | 只读/咨询类，标注无需回滚 |

---

## 八、Pre-commit 配置

### 8.1 Hook 执行顺序

ruff --fix **必须在所有自定义检查之前执行**，确保后续检查基于格式化后的代码：
1. ruff（自动修复格式）
2. ruff-format
3. check-project-structure
4. check-dependencies
5. check-function-length
6. check-import-order
7. check-secrets
8. mypy
9. 通用 Git hooks（trailing-whitespace 等）
10. forbid-binary-files

### 8.2 check_secrets 扫描范围

`types: [yaml, python, text]` — 已从 `[yaml, python]` 扩展，覆盖 `.md` 等文本文件。

---

## 九、版本同步规则

**⚠️ 最易遗漏的维护操作**：版本号变更时需要同步 5 处：

| 文件 | 位置 | 内容 |
|------|------|------|
| `package.json` | `version` 字段 | `"1.x.x"` |
| `CLAUDE.md` | 第 4 行 | `> 版本：v1.x.x` |
| `CLAUDE.md` | 版本历史章节 | 新增版本条目 |
| `init.sh` | 第 4 行 header | `# 版本: v1.x.x` |
| `init.sh` | 第 57 行 banner | `(v1.x.x)` |
| `init.ps1` | 第 3 行 header | `# 版本: v1.x.x` |
| `init.ps1` | 第 40 行 banner | `(v1.x.x)` |
| `CHANGELOG.md` | 顶部 | 新增版本条目 |

共 8 处需要同步。遗漏任何一处将造成版本号不一致。

---

## 十、测试覆盖

23 个 Node.js 内置测试（`node --test tests/index.test.js`），覆盖：
- 包结构（3）：package.json 格式、files 存在性、engines 声明
- 入口文件（2）：index.js 语法、核心函数定义
- 初始化脚本（8）：init.sh/init.ps1 存在性、功能性、版本锁定
- Skills（2）：10 个 Skill 存在性、Router 决策表条目
- 安全（1）：.gitignore 包含 .env
- 跨平台（1）：.gitattributes 存在性

当前状态：23/23 通过 ✅

---

## 十一、已知未修复项

以下为分析发现但优先级较低、未纳入本轮修复的问题：

| 编号 | 问题 | 原因 |
|:---:|------|------|
| F-M5 | 骨架命令 fallback 提示 | ✅ 已修复（v1.6.0） |
| F-M9 | tests 补充（hooks.test.js, router.test.js） | 需要模拟 stdin/Hook JSON 输出 |
| F-M14 | git-commit Conventional Commits | 已存在（提交流程第 2 步已包含） |
| F-M16 | QUICKSTART.md 顺序统一 | 低优先级文档调整 |
| F-M17 | HANDOVER.md 拆分 | 本文档替代 |

---

## 十二、维护清单

进行以下操作时，参考此清单避免遗漏：

- [ ] 新增脚本到 `scripts/` → 更新 init.sh + init.ps1 白名单
- [ ] 新增 Skill → 更新 Router 决策表 + 触发词
- [ ] 修改触发词 → 同步 Skill frontmatter + Router 决策表 + TRIGGER_SPEC.md
- [ ] 版本号变更 → 同步 8 处（见第九节）
- [ ] 修改 smart-context.sh → 确认场景 2 不使用 exit
- [ ] 修改 Hook → 运行 `node --test tests/index.test.js`
- [ ] 修改 init.sh Step 6 → 确认 init.ps1 同步
- [ ] 新增命令 → CLAUDE.md 命令计数 + init.sh 命令列表

---

## 十三、Git 历史追溯线索

```
972bb90 feat: v1.6.0 第四轮审查修复完整闭环
5c06a71 fix: v1.5.9 风险因子 + ECC 降级 + 触发词规范
c32dd03 fix: v1.5.8 Agent Teams 文档 + Pre-commit 优化
3e6d5b7 fix: v1.5.7 Memory GC + Skill 回滚 + Hook 加固
7ec075e fix: v1.5.6 第四轮审查修复 Batch1+2
6a2e995 fix: v1.5.4 第三轮多角色审查修复
```
