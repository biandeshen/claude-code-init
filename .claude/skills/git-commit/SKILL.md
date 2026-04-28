---
name: 规范化提交
description: >
  当用户提到提交代码、commit、push、保存更改时使用此技能。

  触发词：提交、commit、push、存盘、提交代码、帮我commit。

  此技能会分析变更、生成符合 Conventional Commits 规范的提交信息、运行 pre-commit 检查。
---

# 规范化提交流程

## 提交流程

### 1. 变更分析
```bash
git status
git diff
```
收集：
- 变更类型：新增/修改/删除
- 影响范围：哪个模块/功能
- 变更目的：一句话描述

### 2. 确定变更类型

| 变更类型 | commit type |
|----------|-------------|
| 新功能 | feat |
| bug修复 | fix |
| 文档更新 | docs |
| 代码格式 | style |
| 重构 | refactor |
| 测试 | test |
| 构建/CI | chore |

### 3. 生成提交信息

格式：
```
<type>(<scope>): <subject>

<body>（可选，详细说明）
```

规则：
- subject 不超过 50 字
- 使用祈使句："add" 而非 "added"
- 不使用句号结尾

### 4. Pre-commit 检查
```bash
pre-commit run --all-files
```
- 如有失败，分析原因并修复
- 不得跳过检查（除非用户明确要求）

### 5. 执行提交
```bash
git add <files>
git commit -m "<message>"
git push（如需要）
```

## 输出格式

```markdown
### 变更分析
- 类型：feat/fix/docs/...
- 范围：<module>
- 文件数：X

### 提交信息
```
<type>(<scope>): <subject>
```

### 检查结果
- ✅ Pre-commit: 通过
- ⚠️ Pre-commit: X个问题（已修复）

### 执行结果
- ✅ 已提交: <hash>
- ✅ 已推送: <branch>
```

## 安全规则

- ❌ 不提交密钥、密码、token
- ❌ 不提交 .env 文件
- ❌ 不使用 `--no-verify` 跳过检查
- ❌ 提交前确认目标分支
