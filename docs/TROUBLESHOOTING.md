# 常见问题排查指南

本文档收录 `claude-code-init` 使用过程中的常见问题及其解决方案。

---

## 目录

1. [安装问题](#1-安装问题)
2. [初始化问题](#2-初始化问题)
3. [npm 分发问题](#3-npm-分发问题)
4. [Git/编码问题](#4-git编码问题)
5. [Claude Code 相关问题](#5-claude-code-相关问题)

---

## 1. 安装问题

### 1.1 `npx claude-code-init` 报错找不到包

**症状**：
```
npm error 404 Not Found - GET https://registry.npmjs.org/claude-code-init
```

**原因**：包尚未发布到 npm

**解决**：
```bash
# 方式一：手动克隆
git clone https://github.com/biandeshen/claude-code-init.git
cd claude-code-init
.\init.ps1 -ProjectPath "你的项目路径"

# 方式二：等待 npm 发布（需要仓库维护者执行 npm publish）
```

---

### 1.2 克隆脚手架失败

**症状**：
```
fatal: repository 'https://github.com/...'
```

**解决**：
1. 检查网络连接
2. 确认 Git 已安装：`git --version`
3. 尝试使用 SSH：`git clone git@github.com:biandeshen/claude-code-init.git`

---

### 1.3 PowerShell 脚本执行被拦截

**症状**：
```
无法加载文件 ...\init.ps1，因为在此系统上禁止运行脚本。
```

**原因**：PowerShell 执行策略限制

**解决**：
```powershell
# 查看当前策略
Get-ExecutionPolicy

# 临时允许执行（当前会话）
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 或永久允许（需要管理员）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 2. 初始化问题

### 2.1 `.gitignore` 配置后文件仍被追踪

**症状**：文件已被 git 追踪，即使加入 `.gitignore` 也不生效

**解决**：
```bash
# 从 git 缓存中移除（但不删除文件）
git rm --cached 文件路径

# 或移除整个缓存后重新添加
git rm -r --cached .
git add .
```

---

### 2.2 初始化脚本中文乱码

**症状**：PowerShell 输出乱码

**原因**：脚本文件缺少 UTF-8 BOM

**解决**：
```powershell
# 使用 Python 添加 BOM
python -c "
import codecs
with open('scripts/configure-gitignore.ps1', 'r', encoding='utf-8') as f:
    content = f.read()
with open('scripts/configure-gitignore.ps1', 'w', encoding='utf-8-sig') as f:
    f.write(content)
"
```

---

### 2.3 `cc-discipline` 克隆失败

**症状**：
```
git clone 失败
```

**解决**：
1. 检查 Git 是否已安装
2. 手动克隆：
   ```bash
   git clone -b main https://github.com/TechHU-GS/cc-discipline.git ~/.cc-discipline
   cd ~/.cc-discipline
   git checkout 916da00691128fde44599928d76c129f3d08b8f1
   ```
3. 然后手动运行初始化：
   ```bash
   bash ~/.cc-discipline/init.sh
   ```

---

## 3. npm 分发问题

### 3.1 `npm login` 认证失败

**症状**：
```
npm error ENEEDAUTH
```

**解决**：
1. 确认 npm 账号已注册：https://www.npmjs.com/signup
2. 重置密码：https://www.npmjs.com/forgot
3. 如果启用 2FA，确保输入一次性验证码

---

### 3.2 `npm publish` 报错版本已存在

**症状**：
```
npm error You cannot publish over the previously published version
```

**解决**：
```bash
# 升级版本号
npm version patch  # 修复补丁 1.4.1 → 1.4.2
npm version minor  # 新功能 1.4.1 → 1.5.0
npm version major  # 重大更新 1.4.1 → 2.0.0

# 然后重新发布
npm publish
```

---

### 3.3 `npm publish` 报 bin 字段错误

**症状**：
```
npm warn "bin[claude-code-init]" script name index.js was invalid and removed
```

**原因**：`bin` 字段格式不正确

**解决**：确保 `package.json` 中 `bin` 字段指向正确的入口文件：
```json
{
  "bin": {
    "claude-code-init": "./index.js"
  }
}
```

---

## 4. Git/编码问题

### 4.1 PowerShell 5.x 中文乱码

**症状**：脚本输出的中文显示为乱码

**原因**：Windows PowerShell 5.x 默认编码不是 UTF-8

**解决**：
1. 确保脚本文件保存为 **UTF-8 with BOM** 格式
2. 或在脚本开头添加：
   ```powershell
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   ```

---

### 4.2 `git push` 被拒绝

**症状**：
```
! [rejected] main -> main (fetch first)
```

**原因**：远程仓库有新的提交

**解决**：
```bash
# 拉取远程更新
git pull --rebase

# 如果有冲突，解决冲突后
git add .
git rebase --continue

# 再次推送
git push
```

---

### 4.3 `git push --force` 警告

**症状**：Hook 提示强制推送警告

**原因**：强制推送会覆盖远程历史

**解决**：
1. 尽量使用 `git pull --rebase` 代替强制推送
2. 如果必须强制推送，确认分支未被其他人同时修改
3. 使用 `--force-with-lease`（相对安全的变体）

---

## 5. Claude Code 相关问题

### 5.1 插件安装失败

**症状**：`/plugin install` 命令报错

**解决**：
```bash
# 检查 Claude Code 版本
claude --version

# 确保版本 >= 2.0
# 如果版本过低，升级 Claude Code

# 手动安装插件
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
```

---

### 5.2 Skills 没有自动触发

**症状**：输入触发词后没有加载对应 Skill

**解决**：
1. 确认 `.claude/skills/` 目录存在且包含 `SKILL.md` 文件
2. 确认 `router/SKILL.md` 中包含该触发词
3. 重启 Claude Code 会话

---

### 5.3 Hooks 不生效

**症状**：Smart Context Hook 没有给出建议

**解决**：
1. 确认 `.claude/settings.json` 中已配置 hooks
2. 检查 hooks 脚本是否有执行权限：
   ```bash
   chmod +x .claude/hooks/smart-context.sh
   ```
3. 查看 Claude Code 日志排查具体错误

---

### 5.4 Agent Teams 无法启动

**症状**：`/team` 命令报错

**原因**：Agent Teams 功能需要特定版本

**解决**：
1. 确认 Claude Code 版本 >= 2.1.32
2. 确认已启用 Agent Teams：
   ```bash
   export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
   ```
3. 或在 `~/.claude/settings.json` 中添加：
   ```json
   {
     "env": {
       "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
     }
   }
   ```

---

## 获取帮助

如果遇到本文档未覆盖的问题：

1. 查看 [GitHub Issues](https://github.com/biandeshen/claude-code-init/issues)
2. 查看 [完整使用指南](GUIDE.md)
3. 提交新的 Issue 描述问题

---

## 版本兼容性

| 组件 | 最低版本 | 推荐版本 |
|------|----------|----------|
| Claude Code | 2.0 | 最新稳定版 |
| Node.js | 16 | 18+ |
| Python | 3.8 | 3.10+ |
| Git | 2.30 | 最新稳定版 |
| PowerShell (Windows) | 5.1 | 7+ |
| tmux (Unix/macOS) | 3.0 | 最新稳定版 |
