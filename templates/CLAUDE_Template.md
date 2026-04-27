# [项目名] 开发规范

> Claude Code 会话启动时自动读取。
> 版本：v1.0.0 | 最后更新：2026-04-28

---

## 双索引架构

> **工具规范与项目规范分离**

| 索引 | 说明 | 位置 |
|------|------|------|
| **Claude Code 工具规范** | 跨项目通用规范 | [./_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md) |
| **项目文档** | 项目专用文档 | [docs/DOCS_INDEX.md](docs/DOCS_INDEX.md) |

---

## Claude Code 工具规范

> ⚠️ 这些是通用规范，存放在 `_archived/`，由 Git 统一维护。

| 规范 | 说明 | 位置 |
|------|------|------|
| 行为规则 | 假设验证、错误熔断、变更记录、主动升级 | [_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md) → Agent_Behavior_Rules.md |
| Plan 模板 | 任务计划格式、执行日志 | [_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md) → PLAN_Template.md |
| 前端规范 | 考古学家+外科医生模式 | [_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md) → Frontend_Modification_Rules.md |
| 提交规范 | feat/fix/docs 等 type | [_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md) → Commit_Convention.md |
| 代码规范 | Python 命名、导入、函数设计 | [_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md) → Coding_Convention.md |
| 语言约定 | 中文对话/英文代码 | [_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md) → Language_Convention.md |

完整索引：[./_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md)

---

## 项目特有规范

> ⚠️ 在此添加项目特有的规范（如果有）

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
| **Claude Code 工具规范索引** | [./_archived/DOCS_INDEX.md](_archived/DOCS_INDEX.md) |
| **项目文档索引** | [docs/DOCS_INDEX.md](docs/DOCS_INDEX.md) |
| **元认知规则** | [SOUL.md](SOUL.md) |

---

## 版本历史

- `v1.0.0` (2026-04-28)：初始化项目规范，基于双索引架构模板

---

*核心原则：工具是工具，项目是项目。Claude Code 工具规范在 `_archived/`，项目规范在 `docs/`*