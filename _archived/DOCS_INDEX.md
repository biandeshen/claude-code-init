# Claude Code 规范文档索引导航

> Claude Code 工具规范索引 | 版本：v1.0.0 | 最后更新：2026-04-28
>
> 本目录包含 Claude Code 工具的通用规范，可跨项目复用。

---

## 一、文档索引

### A. 行为规范

| 文档 | 说明 | 层级 |
|------|------|------|
| [Agent_Behavior_Rules.md](Agent_Behavior_Rules.md) | ⭐ 核心行为规则（假设验证、熔断、变更记录、主动升级） | 必须 |
| [SOUL_Template.md](SOUL_Template.md) | 元认知模板（决策树、技能联动） | 推荐 |

### B. 代码规范

| 文档 | 说明 |
|------|------|
| [Coding_Convention.md](Coding_Convention.md) | Python 代码规范（命名、导入、函数设计、错误处理） |
| [Naming_Convention.md](Naming_Convention.md) | 命名规范（文件、类、函数、变量） |

### C. 提交与工作流

| 文档 | 说明 |
|------|------|
| [Commit_Convention.md](Commit_Convention.md) | Git 提交规范（type/format/checklist） |
| [PLAN_Template.md](PLAN_Template.md) | 任务计划模板（格式、执行日志） |

### D. 前端与UI

| 文档 | 说明 |
|------|------|
| [Frontend_Modification_Rules.md](Frontend_Modification_Rules.md) | 前端修改规范（考古学家+外科医生模式） |

### E. 语言与沟通

| 文档 | 说明 |
|------|------|
| [Language_Convention.md](Language_Convention.md) | 语言约定（中文对话/英文代码） |

### F. 技能开发

| 文档 | 说明 |
|------|------|
| [Skill_Development_Convention.md](Skill_Development_Convention.md) | 技能开发规范（SKILL.md 格式、工作流） |
| [Secrets_Management.md](Secrets_Management.md) | 密钥管理规范 |

### G. 工具指南

| 文档 | 说明 |
|------|------|
| [CLAUDE_CODE_TOOLS.md](CLAUDE_CODE_TOOLS.md) | Claude Code 工具使用指南 |
| [CLAUDE_Template.md](CLAUDE_Template.md) | CLAUDE.md 模板 |

---

## 二、文档依赖关系图

```
                    ┌─────────────────────────────────────────┐
                    │     Agent_Behavior_Rules.md (⭐核心)    │
                    │     假设验证 / 熔断 / 变更记录 / 主动升级  │
                    └──────────────────┬──────────────────────┘
                                       │
                    ┌──────────────────┴───────────────────┐
                    │                                     │
                    ▼                                     ▼
           ┌─────────────┐                        ┌─────────────┐
           │Coding_Conv │                        │PLAN_Template│
           │(代码规范)   │                        │(任务计划)    │
           └──────┬──────┘                        └──────┬──────┘
                  │                                     │
                  └───────────────┬─────────────────────┘
                                  ▼
                         ┌─────────────┐
                         │ Commit_Conv  │
                         │ (提交规范)   │
                         └─────────────┘
```

---

## 三、快速查找表

| 遇到问题 | 查哪里 |
|----------|--------|
| 不知道假设验证怎么做 | Agent_Behavior_Rules.md → 第一章 |
| 不知道提交格式 | Commit_Convention.md |
| 不知道函数命名规范 | Coding_Convention.md → 命名章节 |
| 不知道 Plan.md 格式 | PLAN_Template.md |
| 前端修改不知道怎么做 | Frontend_Modification_Rules.md |
| 不知道中文英文分工 | Language_Convention.md |
| 不知道技能开发流程 | Skill_Development_Convention.md |

---

## 四、版本历史

- `v1.0.0` (2026-04-28)：初始版本，定义 Claude Code 工具规范索引

---

*本索引由 Git 统一维护，位于 `E:/笔记/Claude Code规范/`*