---
name: project-validate
description: >
  项目完整性校验工作流。当用户提到运行校验、检查项目、validate、
  检查代码规范、完整性检查时自动加载。
  运行结构检查、密钥安全、函数长度、依赖方向、import顺序五项检查。

  中文触发词：校验、validate、检查项目、完整性、代码规范检查、
  运行检查、帮我检查

  英文触发词：validate, check, lint, verify, check project, validation
---

# Project Validate Protocol

你是项目质量校验专家。运行全面检查，确保项目符合规范。

## 校验流程

### 1. 检查脚本存在性
确认 `.claude/scripts/` 目录及脚本存在：
- `check_project_structure.py` — 项目结构
- `check_secrets.py` — 密钥安全
- `check_function_length.py` — 函数长度
- `check_dependencies.py` — 依赖方向
- `check_import_order.py` — import 顺序

### 2. 执行校验脚本
按顺序运行：

```bash
# 1. 项目结构检查
python .claude/scripts/check_project_structure.py

# 2. 密钥安全检查
python .claude/scripts/check_secrets.py

# 3. 函数长度检查
python .claude/scripts/check_function_length.py

# 4. 依赖方向检查
python .claude/scripts/check_dependencies.py

# 5. Import 顺序检查
python .claude/scripts/check_import_order.py

# 6. Pre-commit 全量检查
pre-commit run --all-files
```

### 3. 汇总结果

## 输出格式

```markdown
## 项目校验报告

### 检查结果

| 检查项 | 状态 | 问题数 |
|--------|:----:|:------:|
| 项目结构 | ✅/❌ | X |
| 密钥安全 | ✅/❌ | X |
| 函数长度 | ✅/❌ | X |
| 依赖方向 | ✅/❌ | X |
| Import顺序 | ✅/❌ | X |
| Pre-commit | ✅/❌ | X |

### 违规详情

如有违规，列出具体问题：

#### 🔴 严重问题
- `<file>:<line>` — <问题描述>

#### 🟠 警告
- `<file>:<line>` — <问题描述>

### 修复建议

#### 可自动修复
```bash
# 自动修复的命令
```

#### 需手动修复
- <具体说明>
```

## 校验规则

### 项目结构检查
- CLAUDE.md 存在
- tests/ 目录存在
- .gitignore 包含必要条目

### 密钥安全检查
- 无硬编码密钥
- .env 在 gitignore 中
- 无 test_api_key 等示例密钥

### 函数长度检查
- 函数 ≤ 50 行
- 过长函数需拆分

### 依赖方向检查
- 遵守 `.dependency-rules.json`（如有）
- 无循环依赖

### Import 顺序检查
- 标准库 → 第三方 → 本地
- 字母排序

## 安全规则

- 发现密钥泄露立即报告
- 不尝试猜测或生成密钥
- 敏感信息检查使用白名单机制
