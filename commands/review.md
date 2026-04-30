# /review - 代码审查

> **完整指令见**: `.claude/skills/code-review/SKILL.md`
> 本文件为快捷入口，完整审查维度（OWASP 安全清单 + 逻辑审查）由对应 Skill 提供。

全面代码审查：

1. `git diff --cached` 或 `git diff HEAD~N..HEAD` 查看变更
2. 审查维度：代码风格 / 潜在 bug / 安全性 / 性能 / 测试覆盖
3. 输出分级报告（高风险 / 中风险 / 建议 + 合并结论）

> 安全审查清单、逻辑维度等详见 code-review Skill。

## 快速参考

- **功能**：多维度代码审查（代码风格/潜在Bug/安全性/性能/测试覆盖）
- **适用场景**：PR Review 时、安全检查时、代码质量评估时
- **完整指令**：见 `.claude/skills/code-review/SKILL.md`
