# 完整方案：`claude-code-init` Skill 仓库

### 一、仓库结构

```
claude-code-init/                    # Git 仓库根目录
├── README.md                        # 使用说明
├── init.ps1                         # Windows PowerShell 一键初始化脚本
├── init.sh                          # macOS/Linux 一键初始化脚本
├── templates/                       # 覆盖层模板文件
│   ├── CLAUDE_Template.md           # CLAUDE.md 覆盖层模板
│   ├── SOUL_Template.md             # 元认知模板
│   └── PLAN_Template.md             # 任务计划模板
├── commands/                        # 自定义斜杠命令模板
│   ├── review.md
│   ├── commit.md
│   └── architect.md
└── _archived/                       # 你的旧规范归档（可选保留）
    ├── Agent_Behavior_Rules.md
    ├── Coding_Convention.md
    ├── Naming_Convention.md
    ├── Commit_Convention.md
    ├── Frontend_Modification_Rules.md
    ├── Skill_Development_Convention.md
    └── Secrets_Management.md
```

### 二、核心脚本：`init.ps1`

```powershell
# init.ps1 — Claude Code 开发环境一键初始化
# 用法: .\init.ps1 -ProjectPath "E:\产品\我的新项目"

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

# 解析模板所在目录（脚本同级目录下的 templates/）
$TemplateDir = Join-Path $PSScriptRoot "templates"
$CommandsDir = Join-Path $PSScriptRoot "commands"

# 1. 创建项目目录
New-Item -ItemType Directory -Force -Path $ProjectPath | Out-Null
Set-Location $ProjectPath

# 2. 初始化 Git
git init

# 3. 安装 OpenSpec
npx kld-sdd

# 4. 安装 cc-discipline（首次需要 clone，后续直接运行）
if (-not (Test-Path "$HOME/.cc-discipline")) {
    git clone https://github.com/TechHU-GS/cc-discipline.git "$HOME/.cc-discipline"
}
bash "$HOME/.cc-discipline/init.sh"

# 5. 复制覆盖层模板
Copy-Item (Join-Path $TemplateDir "CLAUDE_Template.md") "$ProjectPath\CLAUDE.md"
Copy-Item (Join-Path $TemplateDir "SOUL_Template.md") "$ProjectPath\SOUL.md"
Copy-Item (Join-Path $TemplateDir "PLAN_Template.md") "$ProjectPath\PLAN_TEMPLATE.md"

# 6. 创建自定义命令目录并复制命令模板
New-Item -ItemType Directory -Force -Path "$ProjectPath\.claude\commands" | Out-Null
Copy-Item (Join-Path $CommandsDir "review.md") "$ProjectPath\.claude\commands\"
Copy-Item (Join-Path $CommandsDir "commit.md") "$ProjectPath\.claude\commands\"
Copy-Item (Join-Path $CommandsDir "architect.md") "$ProjectPath\.claude\commands\"

# 7. 创建 CLAUDE.local.md（本地偏好，自动 gitignored）
"# 本地个人偏好
- 开始编码前先解释 Plan
- 所有异步函数必须有 timeout
" | Out-File -FilePath "$ProjectPath\CLAUDE.local.md" -Encoding utf8

# 8. 确认 .gitignore 忽略本地文件
if (-not (Test-Path "$ProjectPath\.gitignore")) {
    "CLAUDE.local.md" | Out-File -FilePath "$ProjectPath\.gitignore" -Encoding utf8
} else {
    $gitignore = Get-Content "$ProjectPath\.gitignore"
    if ($gitignore -notcontains "CLAUDE.local.md") {
        Add-Content -Path "$ProjectPath\.gitignore" -Value "`nCLAUDE.local.md"
    }
}

Write-Host ""
Write-Host "Plector 版 Claude Code 开发环境已就绪。" -ForegroundColor Green
Write-Host "  位置: $ProjectPath"
Write-Host ""
Write-Host "下一步:"
Write-Host "  1. 编辑 CLAUDE.md 写入项目特定的架构规则"
Write-Host "  2. 编辑 SOUL.md 定义项目的 AI 人格"
Write-Host "  3. 启动 claude，开始开发"
```

### 三、使用方式

**首次使用**（一辈子一次）：
```bash
# clone 你的 skill 仓库到本地
git clone https://github.com/你的账号/claude-code-init.git E:\工具\claude-code-init
```

**每次新建项目**（一行命令）：
```powershell
E:\工具\claude-code-init\init.ps1 -ProjectPath "E:\产品\我的新项目"
```

**可选**：把脚本路径加到 PATH，然后直接用 `init-project` 命令：
```powershell
# 在 PowerShell Profile 中添加
function init-project {
    E:\工具\claude-code-init\init.ps1 -ProjectPath $args[0]
}
# 之后一行搞定
init-project "E:\产品\新项目"
```

---

### 四、还需手动一次的事（全局一次）

ECC 和 Superpowers 的用户级安装仍需在 Claude Code 中手动执行一次：

```text
# 在 Claude Code 会话中（一辈子一次）
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code

/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

这四行命令，你一辈子只敲一次。

---

### 五、建议放的位置

```
E:\工具\claude-code-init\    ← 你的规范 Skill 仓库
├── init.ps1
├── init.sh
├── templates/               ← 这套永远从这里复制
├── commands/
└── _archived/
```

这样彻底和你的 `E:/笔记/Claude Code规范/` 解耦——规范笔记归笔记，Skill 工具归工具。