# 安全策略

## 报告安全问题

如有安全漏洞或敏感信息泄露，请通过以下方式报告：

- **GitHub Issues**: 请勿在此公开安全问题
- **邮箱**: biandeshen@outlook.com

> 注意：请勿在公开渠道讨论安全问题，收到报告后会在 48 小时内确认。

## 安全响应

- 收到报告后会在 48 小时内确认
- 修复后会发布安全版本并公开致谢
- 严重问题会通过 GitHub Security Advisories 披露

## 第三方依赖

本项目引入的第三方工具及其安全策略：

| 工具 | 类型 | 仓库/链接 | 安全策略 |
|------|------|-----------|----------|
| **ECC** | Claude Code 插件 | [github.com/affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | 参考 ECC 项目安全政策 |
| **Superpowers** | Claude Code 插件 | [github.com/obra/superpowers-marketplace](https://github.com/obra/superpowers-marketplace) | 参考 Superpowers 项目安全政策 |
| **OpenSpec** | npm 包 | [npmjs.com/package/kld-sdd](https://www.npmjs.com/package/kld-sdd) | 使用前阅读其安全说明 |
| **cc-discipline** | Git Hooks | [github.com/TechHU-GS/cc-discipline](https://github.com/TechHU-GS/cc-discipline) | 参考 cc-discipline 项目安全政策 |

> **警告**：本项目会执行 `git clone` 和 `npm install` 等命令来安装上述工具。请确保：
> - 只从官方仓库/官方 npm 安装
> - 检查安装脚本的内容
> - 了解每个工具的权限范围