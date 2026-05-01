# /tdd - 测试驱动开发

按照 TDD 工作流开发功能：先写测试 → 实现代码 → 重构优化。

> **完整流程见**: `.claude/skills/tdd-workflow/SKILL.md`
> 本文件为快捷入口，完整 TDD 工作流（含验收测试、质量门禁等）由对应 Skill 提供。
> 如果 tdd-workflow 技能未自动加载，请说 "加载 tdd-workflow 技能"。

## 用法

```
/tdd <功能描述>
```

## TDD 循环

1. **Red**：编写失败的测试用例
2. **Green**：编写最小实现代码使测试通过
3. **Refactor**：重构代码，保持测试绿灯
4. **重复**：直到功能完成

## 快速参考

- **功能**：测试驱动开发工作流（Red→Green→Refactor 循环）
- **适用场景**：开发新功能时、修复 Bug 需要回归测试时、重构需要安全网时
- **完整指令**：见 `.claude/skills/tdd-workflow/SKILL.md`
