# Security Policy

## 适用范围

本项目 `claude-code-init` 是一个 Claude Code 项目脚手架，包含模板文件和初始化脚本。

## 报告安全漏洞

如有安全漏洞，请发送邮件至：

**biandeshen@outlook.com**

> 请勿在 GitHub Issues 或其他公开渠道讨论安全问题。

## 披露时间线

| 阶段 | 时间 |
|------|------|
| 确认收到报告 | 48 小时内 |
| 初步评估严重程度 | 7 天内 |
| 发布修复（视严重程度） | 14-30 天内 |

严重漏洞会通过 [GitHub Security Advisories](https://github.com/biandeshen/claude-code-init/security/advisories) 披露。

## 第三方依赖

本脚手架会安装以下第三方工具：

| 工具 | 来源 | 用途 |
|------|------|------|
| ECC | Claude Code 插件 | Agent + Skill 生态 |
| Superpowers | Claude Code 插件 | TDD + 根因追踪 |
| OpenSpec | npm (kld-sdd) | SDD 工作流 |
| cc-discipline | GitHub | Git Hooks |

**警告**：脚本会执行 `git clone`、`npm install`、`pip install` 等命令来安装工具。请确保：
- 只使用官方仓库和官方 npm
- 检查安装脚本的内容
- 了解每个工具的权限范围

## GPG 公钥

如需加密通信，可使用以下公钥（可选）：

```
-----BEGIN PGP PUBLIC KEY BLOCK-----
[此处填入你的 GPG 公钥]
-----END PGP PUBLIC KEY BLOCK-----
```

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0.0 | 2026-04-28 | 初始安全策略 |
