# /overnight - 一键启动无人值守长任务

你说任务，AI 自动生成任务清单、设定成本上限、启动 tmux 会话。

## 使用方式

```
/overnight <任务描述>

示例：
/overnight 修复所有 lint 错误和测试失败
/overnight 重构 authentication 模块
/overnight 帮我完成用户管理功能的测试覆盖
```

## 工作流程

1. **解析任务**：AI 分析任务描述，拆分为原子任务
2. **生成清单**：自动创建 `.claude/scripts/PROMPT.md`
3. **设定参数**：根据任务复杂度自动设定 `--max-turns` 和 `--max-budget-usd`
4. **启动会话**：在 tmux 中启动 Claude Code 无人值守循环

## 参数估算规则

| 任务复杂度 | --max-turns | --max-budget-usd |
|:----------:|:------------:|:-----------------:|
| 简单（1-2个文件） | 30 | 5.00 |
| 中等（3-5个文件） | 50 | 10.00 |
| 复杂（5+文件或跨模块） | 100 | 20.00 |

## 输出

命令执行后会输出：
- 任务清单预览
- tmux 会话状态
- 如何重连和查看进度

## 重连查看

```bash
# 重连 tmux 会话
tmux attach -t claude-overnight

# 查看任务汇总
cat .claude/reports/summary.md

# 查看具体任务报告
ls .claude/reports/task-*.md
```

## 终止任务

```bash
# 终止 tmux 会话
tmux kill-session -t claude-overnight
```

## 前提条件

- tmux 已安装（macOS: `brew install tmux`，Linux: `apt install tmux`）
- Claude Code 已安装并认证
- 项目已初始化（运行过 `init.ps1` 或 `init.sh`）

## 限制

- 每个项目同时只能有一个无人值守会话
- 不支持 Windows（Windows 用户可使用 WSL 或手动启动 tmux）

## 相关命令

- `/overnight-report` - 查看过夜任务执行汇总
- `/team` - 启动 Agent 团队并行工作
