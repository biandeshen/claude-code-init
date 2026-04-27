# /validate - 运行项目校验脚本

对项目执行完整的校验流水线。

## 触发条件

当用户输入 `/validate` 或说"运行校验"、"检查代码质量"时使用。

## 执行步骤

1. **检查 .claude/scripts/ 目录是否存在**
2. **按顺序执行校验脚本**
3. **汇总结果并输出报告**

## 校验脚本

| 脚本 | 检查内容 | Pre-commit |
|------|----------|:----------:|
| `.claude/scripts/check_project_structure.py` | 项目结构完整性（CLAUDE.md 存在、tests/ 目录、.gitignore 条目） | - |
| `.claude/scripts/check_secrets.py` | 密钥安全（config.yaml 硬编码密钥、.env 文件是否被提交） | ✅ |
| `.claude/scripts/check_function_length.py` | 函数长度（≤50 行） | ✅ |
| `.claude/scripts/check_dependencies.py` | 模块依赖方向 | ✅ |
| `.claude/scripts/check_import_order.py` | import 语句顺序 | ✅ |

## 输出格式

```markdown
## 项目校验报告

### 检查结果

| 检查项 | 结果 | 详情 |
|--------|:----:|------|
| 项目结构 | ✅/❌ | ... |
| 密钥安全 | ✅/❌ | ... |
| 函数长度 | ✅/❌ | ... |
| 依赖方向 | ✅/❌ | ... |
| import 顺序 | ✅/❌ | ... |

### 违规详情

如果任何一项失败，列出具体的违规文件和行号：

- `src/utils.js:23` - 函数 `formatDate` 长度 67 行，超过 50 行限制
- `config/auth.py:45` - 检测到可能的密钥硬编码: `password = "secret123"`

### 修复建议

...
```

## 注意事项

- 任何一项失败都应输出具体的修复建议
- 可以使用 `python .claude/scripts/check_*.py --fix` 尝试自动修复（如支持）
- 复杂项目建议安装 pre-commit hooks：`pre-commit install`
