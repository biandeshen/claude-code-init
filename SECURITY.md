# Security Policy

## 适用范围
本项目 `claude-code-init` 是 Claude Code 项目脚手架（模板 + 脚本），
不包含运行时代码。安全风险主要涉及：
- 供应链污染（依赖的第三方工具被篡改）
- 模板内容包含敏感信息泄露

## 报告安全漏洞
如有安全漏洞，请发邮件至 biandeshen [at] outlook [dot] com，切勿公开提 Issue。
我们承诺在 48 小时内回复。

## 安全审计
### 自动化检查
- `check_secrets.py`：检测提交中是否包含密钥、token、密码等敏感信息
- `.pre-commit-config.yaml`：集成 detect-private-key 等安全检查

### 手动审查
- 所有外部依赖使用固定版本/提交 hash
- cc-discipline 提供物理防火墙，阻断危险操作

### Hook 级实时保护
- `smart-context.sh`：10 种场景实时检测，包括：
  - 安全文件编辑 → 自动加载 code-review 技能
  - `rm -rf /` 危险删除命令物理阻断
  - `git push --force` 强制推送警告
  - 敏感函数编辑提醒
  - 夜间无人值守推荐
  - 首次 /review 后推荐 Agent Teams
  - stdin 读取超时保护（5 秒）

## 第三方依赖

| 依赖 | 来源 | 版本策略 |
|------|------|----------|
| Everything Claude Code | GitHub: affaan-m/everything-claude-code | 最新稳定版 |
| Superpowers | Git: obra/superpowers | 最新稳定版 |
| OpenSpec | npm: @fission-ai/openspec | 最新稳定版 |
| cc-discipline | GitHub: TechHU-GS/cc-discipline | 锁定 commit: `916da006` |

## 版本安全更新
我们会在发现漏洞后的 7 天内发布补丁版本。

## PGP 加密报告

对于敏感漏洞，请通过 GitHub Security Advisory 私密报告。
<!-- PGP 密钥尚在配置中，就绪后会更新此处。 -->
