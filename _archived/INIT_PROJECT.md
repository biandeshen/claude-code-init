# Claude Code 项目初始化脚本

> 用于在创建新项目时快速引入 Claude Code 规范
> 版本：v1.0.0 | 最后更新：2026-04-28

---

## 快速开始

### Windows (PowerShell)

```powershell
# 在新项目目录下执行
$projectPath = "your-project-path"
Copy-Item "E:\笔记\Claude Code规范\CLAUDE_Template.md" "$projectPath\CLAUDE.md"
Copy-Item "E:\笔记\Claude Code规范\SOUL_Template.md" "$projectPath\SOUL.md"
Copy-Item "E:\笔记\Claude Code规范\PLAN_Template.md" "$projectPath\PLAN_TEMPLATE.md"
```

### 或者复制以下内容到项目目录

1. `CLAUDE.md` - 从 `E:/笔记/Claude Code规范/CLAUDE_Template.md` 复制
2. `SOUL.md` - 从 `E:/笔记/Claude Code规范/SOUL_Template.md` 复制
3. `PLAN_TEMPLATE.md` - 从 `E:/笔记/Claude Code规范/PLAN_Template.md` 复制

---

## 初始化后的文件结构

```
your-project/
├── CLAUDE.md              ← 项目入口（引用通用规范）
├── SOUL.md                ← 元认知规则（引用通用模板）
├── PLAN_TEMPLATE.md       ← Plan.md 模板
├── docs/                  ← 项目文档（需手动创建）
│   └── DOCS_INDEX.md      ← 项目文档索引（需手动创建）
└── ...其他项目文件
```

---

## 手动配置步骤

### 1. 修改 CLAUDE.md

```markdown
# 将 [项目名] 替换为实际项目名
# 在"项目特有规范"章节添加项目特有的规范
```

### 2. 修改 SOUL.md

```markdown
# 将 [项目名] 替换为实际项目名
# 在"项目特有规范"章节添加项目特有的元认知规则
```

### 3. 创建 docs/DOCS_INDEX.md

```markdown
# 项目文档索引导航

> 版本：v1.0.0 | 最后更新：2026-04-28

---

## Claude Code 工具规范

> ⚠️ 以下规范来自 `E:/笔记/Claude Code规范/`
> 完整索引：[E:/笔记/Claude Code规范/DOCS_INDEX.md](file:///E:/笔记/Claude Code规范/DOCS_INDEX.md)

| 规范 | 说明 |
|------|------|
| [行为规则](file:///E:/笔记/Claude Code规范/Agent_Behavior_Rules.md) | 假设验证、错误熔断 |
| [提交规范](file:///E:/笔记/Claude Code规范/Commit_Convention.md) | feat/fix/docs 等 type |
| ... | ... |

## 项目文档

> 在此添加项目特有的文档

...
```

---

## 架构说明

```
E:/笔记/Claude Code规范/ (通用规范)
├── CLAUDE_Template.md      ← 项目模板
├── SOUL_Template.md        ← 元认知模板
├── PLAN_Template.md        ← Plan 模板
├── DOCS_INDEX.md          ← 通用规范索引
└── ...其他通用规范

your-project/ (项目目录)
├── CLAUDE.md ←──────────── 引用通用规范
├── SOUL.md   ←──────────── 引用通用模板
└── docs/
    └── DOCS_INDEX.md ←──── 项目文档索引
```

---

## 版本历史

- `v1.0.0` (2026-04-28)：初始版本

---

*更多信息请参考：[架构设计文档](../docs/PLECTOR/ARCHITECTURE_DESIGN.md)*