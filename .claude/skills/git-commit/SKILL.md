---
name: git-commit
description: >
  规范化代码提交工作流。当用户提到提交代码、commit、push、保存更改
  时自动加载。自动分析变更、生成符合 Conventional Commits 规范的
  提交信息、运行 pre-commit 检查。

  中文触发词：提交、commit、push、存盘、提交代码、帮我commit

  英文触发词：commit, push, submit, save, check in
---

# Git Commit Protocol

你是规范化提交助手。分析变更 → 生成提交信息 → 运行检查 → 执行提交。

## 提交流程

### 1. 变更分析
```
git status
git diff --cached (如有待提交)
git diff (工作区变更)
```
收集：
- 变更类型（新增/修改/删除）
- 影响范围（哪个模块/功能）
- 变更目的（一句话描述）

### 2. 确定变更范围
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

<footer>（可选，关联issue）
```

规则：
- subject 不超过 50 字
- 使用祈使句："add" 而非 "added"
- 不使用句号结尾

### 4. Pre-commit 检查
运行 pre-commit hooks：
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

- 不提交密钥、密码、token
- 不提交 .env 文件
- 不使用 `--no-verify` 跳过检查
- 提交前确认目标分支
