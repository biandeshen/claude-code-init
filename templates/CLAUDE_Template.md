# [项目名] 开发规范

> Claude Code 会话启动时自动读取。
> 模板版本：v1.0.0 | 最后更新：2026-04-30
> 版本：v1.0.0 | 最后更新：2026-04-28

---

## 索引架构

> **工具规范 → ECC 内置 | 项目规范 → docs/ | 元认知 → SOUL.md | 功能规格 → docs/specs/**

| 规范类型 | 来源 | 说明 |
|----------|------|------|
| **工具规范** | ECC 内置 | 156+ Skills / 38 Agents，跨项目通用 |
| **元认知规则** | [SOUL.md](SOUL.md) | 复杂度评估、决策树、熔断机制 |
| **项目规范** | `docs/` 目录 | 项目专用文档 |
| **功能规格** | `docs/specs/` | 复杂功能的事前设计蓝图 |

---

## 工具规范（ECC 内置）

ECC 已提供丰富的内置 Skills 和 Agents，无需额外配置：

| 类别 | 示例 Skill | 说明 |
|------|-----------|------|
| 代码审查 | `requesting-code-review` | 自动审查代码变更 |
| 架构分析 | `requesting-architect` | 架构评审和建议 |
| 文档生成 | `document-generation` | 自动生成文档 |
| 测试 | `tdd-explain` | TDD 工作流 |
| 重构 | `refactoring-explain` | 安全重构指导 |

**使用方式**：在 Claude Code 中直接描述需求，AI 会调用合适的 Skill。

**规范约束**：通过 [SOUL.md](SOUL.md) 的复杂度评估规则自动分流。

---

## 项目特有规范

> 在此添加项目特有的规范

### 项目结构

```
[项目名]/
├── src/               # 源代码
├── tests/             # 测试
├── docs/              # 文档
├── config/            # 配置
├── scripts/           # 脚本
└── ...
```

---

## 文档索引

| 内容 | 位置 |
|------|------|
| **元认知规则** | [SOUL.md](SOUL.md) |
| **复杂度评估** | [SOUL.md → 复杂度自动评估规则](SOUL.md) |
| **功能规格** | `docs/specs/` 目录 |
| **规格模板** | [SPEC_Template.md](.claude/SPEC_Template.md) — 功能级设计蓝图模板 |
| **项目文档** | `docs/` 目录 |

---

### Spec 优先原则

> 复杂功能开发前，AI 必须遵循：
> 1. 先检查 `docs/specs/` 是否有相关 Spec
> 2. 若无 → 参考 [SPEC_Template.md](.claude/SPEC_Template.md) 创建
> 3. Spec 定稿后再进入 SOUL.md 决策树执行

### 记忆系统

本项目使用 `.claude/memory/MEMORY.md` 管理项目记忆（单文件，内部分章节）：

| 章节 | 内容 |
|------|------|
| 索引表（文件顶部） | AI 启动时先读索引获取记忆概览 |
| 架构决策 (ADR) | 项目架构决策及原因 |
| Bug 模式 | Bug 模式与根因 |
| 编码模式 | 编码模式/约定 |
| 领域知识 | 项目背景/领域知识 |

**AI 行为规则：**
- 每次会话启动时先读 `.claude/memory/MEMORY.md` 顶部的索引表
- 修复复杂 Bug（排查 > 30 分钟）后，在对话末尾提议记录到 MEMORY.md 的「Bug 模式」章节
- 做出架构决策后，提议记录到 MEMORY.md 的「架构决策 (ADR)」章节（必须包含决策原因）
- `/commit`、`/fix`、`/review` 关键操作后，检查是否需要记录记忆
- 用户说"之前怎么修的/上次/我记得"时，自动搜索记忆库
- **禁止**在记忆中记录：密钥/Token/密码、内网IP、对人评价、未公开商业策略

**安全管理：**
- 共享记忆写入 `.claude/memory/MEMORY.md`（提交到 Git）
- 个人私密内容写入 `MEMORY.local.md`（gitignored，不提交）
- 记忆提交到 Git 前，pre-commit hook 会自动扫描密钥

---

## 版本历史

- `v1.0.0` (2026-04-28)：初始化项目规范，基于 ECC + 双索引架构

---

*核心原则：工具规范由 ECC 提供，项目规范放在 `docs/`*
