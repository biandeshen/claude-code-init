# /commit - 规范的 Git 提交

按照 Conventional Commits 规范生成提交信息。

## 触发条件

当用户输入 `/commit` 或说"提交"、"帮我 commit"时使用。

## 执行步骤

1. **检查暂存区**
   - 运行 `git status` 查看变更
   - 运行 `git diff --cached` 查看暂存内容
   - 如果没有暂存，提示用户先 `git add`

2. **分析变更类型**
   - 根据变更内容判断 type (feat/fix/docs/style/refactor/perf/test/chore)

3. **生成提交信息**
   - 按照格式: `<type>(<scope>): <subject>`
   - body 说明为什么而非做了什么

4. **预览并确认**
   - 显示生成的提交信息
   - 等待用户确认
   - 确认后执行 `git commit`

## 提交规范

| Type | 说明 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档更新 |
| style | 代码格式（不影响功能） |
| refactor | 重构（无功能变化） |
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建/工具/依赖 |

## 示例

```
✅ feat(auth): 添加用户登录功能

用户反馈需要登录功能。
采用 JWT 令牌，支持 refresh token。

Closes #123
```

## 注意事项

- 简短描述不超过 50 字符
- body 使用中文
- 一个提交只做一件事（原子提交）
