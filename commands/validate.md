# /validate - 运行项目校验脚本

> **完整指令见**: `.claude/skills/project-validate/SKILL.md`
> 本文件为快捷入口，完整校验流水线（含违规分级、自动修复建议等）由对应 Skill 提供。
> 如果 project-validate 技能未自动加载，请说 "加载 project-validate 技能"。

按顺序执行 scripts/ 中的 5 个校验脚本：

| 脚本 | 检查内容 |
|------|----------|
| `check_project_structure.py` | 项目结构完整性 |
| `check_secrets.py` | 密钥安全 |
| `check_function_length.py` | 函数长度 |
| `check_dependencies.py` | 模块依赖方向 |
| `check_import_order.py` | import 语句顺序 |

输出格式：检查结果汇总表 + 违规详情 + 修复建议

> 违规分级（严重/警告）、自动修复选项等详见 project-validate Skill。

## 快速参考

- **功能**：运行项目完整性校验流水线（5项检查 + pre-commit 全量扫描）
- **适用场景**：提交前检查时、项目质量评估时、CI 流水线中
- **完整指令**：见 `.claude/skills/project-validate/SKILL.md`
