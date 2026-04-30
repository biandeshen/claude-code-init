# /remember — 项目记忆管理

浏览、编辑、删除项目记忆。记忆的**录入**由 AI 在关键节点自动提议（/commit、/fix、/review 后），不依赖手动调用本命令。

> 模板版本：v1.0.0 | 最后更新：2026-04-30

## 用法

| 命令 | 作用 |
|------|------|
| `/remember` | 显示记忆概览（索引 + 各类别记忆数） |
| `/remember list` | 列出所有记忆（按时间倒序） |
| `/remember list --type bug` | 按类型筛选：decision / bug / pattern / context |
| `/remember list --recent` | 仅显示最近 30 天的记忆 |
| `/remember search <关键词>` | 在所有记忆文件中搜索关键词 |
| `/remember show <ID>` | 显示指定记忆的完整内容 |
| `/remember edit <ID>` | 编辑指定记忆 |
| `/remember delete <ID>` | 删除指定记忆（需确认） |
| `/remember gc` | 扫描过期/冗余记忆，交互式清理 |

## 记忆文件结构

```
.claude/memory/
├── MEMORY.md         ← 唯一记忆文件（内部分章节）
│   ├── 索引表（文件顶部）
│   ├── 架构决策 (ADR)
│   ├── Bug 模式
│   ├── 编码模式
│   └── 领域知识
└── archive/          (超过90天的归档记忆)
```

## 记忆元数据格式

每条记忆遵循统一结构：

```markdown
### [memory-id] YYYY-MM-DD · type · P1 · tags: [tag1, tag2]

**What**: 一句话简述
**Why**: 背景和原因（为什么这样决策/为什么这样修复）
**Related**: 关联文件、PR、其他记忆ID
**Status**: active / superseded / archived
```

## 执行逻辑

1. 读取 `.claude/memory/MEMORY.md` 顶部的索引表获取概览
2. 根据子命令定位到 MEMORY.md 中的对应章节
3. 编辑操作：直接修改 MEMORY.md 对应章节中的记忆条目
4. GC 操作：
   - 扫描所有记忆的日期
   - 标记 > 90 天且 access_count = 0 的记忆
   - 展示预览："将归档 X 条，建议删除 Y 条"
   - 用户确认后执行（归档 → archive/，删除 → 永久移除）
