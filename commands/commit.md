# /commit - 规范的 Git 提交

> **完整指令见**: `.claude/skills/git-commit/SKILL.md`
> 本文件为快捷入口，完整提交流程（含 pre-commit 检查、push 确认等）由对应 Skill 提供。

执行 Conventional Commits 规范化提交：

1. `git status` + `git diff --cached` 分析变更
2. 根据变更内容判断 type (feat/fix/docs/style/refactor/perf/test/chore)
3. 按 `<type>(<scope>): <subject>` 格式生成提交信息
4. 预览确认后执行 `git commit`

> 提交规范详情、pre-commit 检查清单、push 确认流程见 git-commit Skill。

## 快速参考

- **功能**：生成符合 Conventional Commits 规范的提交信息（feat/fix/docs/...）
- **适用场景**：代码提交时、需要统一团队提交规范时
- **完整指令**：见 `.claude/skills/git-commit/SKILL.md`
