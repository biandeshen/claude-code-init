# claude-code-init - Claude Code 开发环境一键初始化
# 用法: .\init.ps1 -ProjectPath "E:\产品\我的新项目"
# 版本: v1.4.1 | 2026-04-28

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [switch]$SkipECC,
    [switch]$SkipSuperpowers,
    [switch]$SkipOpenSpec,
    [switch]$SkipCcDiscipline
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot

# 颜色输出
function Write-Step { param($msg) Write-Host "[步骤] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[成功] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[警告] $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "[失败] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[信息] $msg" -ForegroundColor Gray }

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Claude Code 开发环境一键初始化 (v1.4.1)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# 1. 确认目标目录
Write-Step "确认目标目录: $ProjectPath"
$OriginalPath = $ProjectPath  # 保存原始路径用于日志
if (-not (Test-Path $ProjectPath)) {
    New-Item -ItemType Directory -Force -Path $ProjectPath | Out-Null
    Write-Success "已创建目录"
}
Set-Location $ProjectPath
$ProjectPath = (Get-Location).Path

# 1.1. 检查 git 命令是否存在
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCmd) {
    Write-Warn "未找到 git 命令，请先安装 Git"
    Write-Host "  下载地址: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# 2. 初始化 Git
if (-not (Test-Path ".git")) {
    Write-Step "初始化 Git 仓库"
    git init
    Write-Success "Git 仓库已初始化"
} else {
    Write-Info "Git 仓库已存在，跳过"
}

# 3. 安装 ECC (Everything Claude Code)
if (-not $SkipECC) {
    Write-Step "安装 Everything Claude Code (ECC)"
    Write-Info "请在 Claude Code 中执行以下命令:"
    Write-Host "  /plugin marketplace add affaan-m/everything-claude-code" -ForegroundColor Yellow
    Write-Host "  /plugin install everything-claude-code@everything-claude-code" -ForegroundColor Yellow
    Write-Info "选择 'Install for you (user scope)'"
} else {
    Write-Info "跳过 ECC 安装"
}

# 4. 安装 Superpowers
if (-not $SkipSuperpowers) {
    Write-Step "安装 Superpowers"
    Write-Info "请在 Claude Code 中执行以下命令:"
    Write-Host "  /plugin marketplace add obra/superpowers-marketplace" -ForegroundColor Yellow
    Write-Host "  /plugin install superpowers@superpowers-marketplace" -ForegroundColor Yellow
} else {
    Write-Info "跳过 Superpowers 安装"
}

# 4.1 阻断性确认
Write-Host ""
Write-Host "==============================================" -ForegroundColor Yellow
Write-Host " 重要：以上 ECC 和 Superpowers 插件需要在 Claude Code 中手动安装" -ForegroundColor Yellow
Write-Host " 如果你已完成安装，请输入 y 继续；否则请输入 n 退出" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor Yellow
$confirm = Read-Host "是否已完成插件安装？(y/n)"
if ($confirm -ne "y") {
    Write-Host "请先完成插件安装，再重新运行此脚本。" -ForegroundColor Red
    exit 1
}
Write-Success "已确认插件安装"

# 5. 安装 OpenSpec (SDD) - 自动执行
if (-not $SkipOpenSpec) {
    Write-Step "安装 OpenSpec (SDD 工作流)"
    try {
        npx kld-sdd
        Write-Success "OpenSpec 已初始化"
    } catch {
        Write-Warn "OpenSpec 自动安装失败，请手动执行: npx kld-sdd"
    }
} else {
    Write-Info "跳过 OpenSpec 安装"
}

# 6. 安装 cc-discipline (物理防火墙) - 自动执行
if (-not $SkipCcDiscipline) {
    Write-Step "安装 cc-discipline (物理防火墙 Hooks)"
    # $HOME 在 PowerShell 5.x+ 均可用，此处使用 $HOME 确保跨平台兼容
    $CcDisciplinePath = if ($HOME) { "$HOME\.cc-discipline" } else { "$env:USERPROFILE\.cc-discipline" }
    $CcDisciplineCommit = "916da00691128fde44599928d76c129f3d08b8f1"  # 锁定版本 2026-04-26
    if (-not (Test-Path $CcDisciplinePath)) {
        Write-Warn "即将从第三方仓库下载代码: https://github.com/TechHU-GS/cc-discipline"
        Write-Info "克隆 cc-discipline 仓库..."
        git clone -b main https://github.com/TechHU-GS/cc-discipline.git $CcDisciplinePath
        Set-Location $CcDisciplinePath
        git checkout $CcDisciplineCommit
        Set-Location $ProjectPath
        Write-Success "已克隆 cc-discipline (commit: $($CcDisciplineCommit.Substring(0,7)))"
    } else {
        Write-Info "cc-discipline 已存在，如需更新请手动执行: git -C $CcDisciplinePath pull"
    }
    Write-Info "正在执行 cc-discipline 初始化..."
    try {
        bash "$CcDisciplinePath/init.sh"
        Write-Success "cc-discipline 已安装"
    } catch {
        Write-Warn "cc-discipline 初始化失败，请手动执行: bash $CcDisciplinePath/init.sh"
    }
} else {
    Write-Info "跳过 cc-discipline 安装"
}

# 7. 复制 Python 校验脚本
Write-Step "复制校验脚本到 .claude/scripts/"
$ScriptsDir = Join-Path $ScriptDir "scripts"
$TargetScriptsDir = "$ProjectPath\.claude\scripts"
if ($ScriptsDir -eq $TargetScriptsDir) {
    Write-Info "源目录与目标目录相同，已跳过脚本复制"
} elseif (Test-Path $ScriptsDir) {
    New-Item -ItemType Directory -Force -Path $TargetScriptsDir | Out-Null
    Copy-Item -Path "$ScriptsDir\*" -Destination $TargetScriptsDir -Force -Recurse
    Write-Success "已复制校验脚本到 .claude/scripts/"
} else {
    Write-Info "scripts 目录不存在，跳过"
}

# 8. 复制 Pre-commit 配置
Write-Step "复制 Pre-commit 配置"
$PrecommitConfig = Join-Path $ScriptDir "configs\.pre-commit-config.yaml"
$TargetPrecommitConfig = "$ProjectPath\.pre-commit-config.yaml"
if ($PrecommitConfig -eq $TargetPrecommitConfig) {
    Write-Info "源文件与目标文件相同，已跳过 Pre-commit 配置复制"
} elseif (Test-Path $PrecommitConfig) {
    Copy-Item -Path $PrecommitConfig -Destination $TargetPrecommitConfig -Force
    Write-Success "已复制 .pre-commit-config.yaml"
} else {
    Write-Info "Pre-commit 配置不存在，跳过"
}

# 9. 安装 Pre-commit hooks - 自动执行
Write-Step "安装 Pre-commit Hooks"

# 检查 Python 是否可用
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    # 检查 pre-commit 是否已安装
    try {
        $null = python -c "import pre_commit" 2>$null
    } catch {
        Write-Info "正在安装 pre-commit..."
        python -m pip install --quiet pre-commit
        Write-Success "pre-commit 安装完成"
    }
    try {
        pre-commit install
        Write-Success "Pre-commit Hooks 已安装"
    } catch {
        Write-Warn "pre-commit install 失败，请手动执行: pre-commit install"
    }
} else {
    Write-Warn "未找到 Python，无法自动安装 pre-commit"
    Write-Host "  手动安装: pip install pre-commit" -ForegroundColor Yellow
    Write-Host "  手动安装 hooks: pre-commit install" -ForegroundColor Yellow
}

# 10. 复制覆盖层模板
Write-Step "复制覆盖层模板"
$TemplateDir = Join-Path $ScriptDir "templates"
if (Test-Path $TemplateDir) {
    # 复制 CLAUDE.md
    $templateCLAUDE = Join-Path $TemplateDir "CLAUDE_Template.md"
    if (Test-Path $templateCLAUDE) {
        Copy-Item -Path $templateCLAUDE -Destination "$ProjectPath\CLAUDE.md" -Force
        Write-Success "已复制 CLAUDE.md"
    }

    # 复制 SOUL.md
    $templateSOUL = Join-Path $TemplateDir "SOUL_Template.md"
    if (Test-Path $templateSOUL) {
        Copy-Item -Path $templateSOUL -Destination "$ProjectPath\SOUL.md" -Force
        Write-Success "已复制 SOUL.md"
    }

    # 复制 PLAN_TEMPLATE.md
    $templatePLAN = Join-Path $TemplateDir "PLAN_Template.md"
    if (Test-Path $templatePLAN) {
        Copy-Item -Path $templatePLAN -Destination "$ProjectPath\PLAN_TEMPLATE.md" -Force
        Write-Success "已复制 PLAN_TEMPLATE.md"
    }
} else {
    Write-Warn "模板目录不存在，跳过模板复制"
}

# 11. 复制自定义命令
Write-Step "复制自定义命令"
$CommandsDir = Join-Path $ScriptDir "commands"
$TargetCommandsDir = "$ProjectPath\.claude\commands"
if ($CommandsDir -eq $TargetCommandsDir) {
    Write-Info "源目录与目标目录相同，已跳过命令复制"
} elseif (Test-Path $CommandsDir) {
    New-Item -ItemType Directory -Force -Path $TargetCommandsDir | Out-Null
    Copy-Item -Path "$CommandsDir\*" -Destination $TargetCommandsDir -Force -Recurse
    Write-Success "已复制自定义命令到 .claude/commands/"
} else {
    Write-Info "命令目录不存在，跳过"
}

# 11.1 复制 Skills
Write-Step "复制 Skills"
$SkillsDir = Join-Path $ScriptDir ".claude\skills"
$TargetSkillsDir = "$ProjectPath\.claude\skills"
if ($SkillsDir -eq $TargetSkillsDir) {
    Write-Info "源目录与目标目录相同，已跳过 Skills 复制"
} elseif (Test-Path $SkillsDir) {
    New-Item -ItemType Directory -Force -Path $TargetSkillsDir | Out-Null
    Copy-Item -Path "$SkillsDir\*" -Destination $TargetSkillsDir -Force -Recurse
    Write-Success "已复制 Skills 到 .claude/skills/"
} else {
    Write-Info "Skills 目录不存在，跳过"
}

# 11.2 复制 Hooks 和 settings.json
Write-Step "复制 Hooks 和设置"
$HooksSourceDir = Join-Path $ScriptDir ".claude\hooks"
$HooksTargetDir = "$ProjectPath\.claude\hooks"
$SettingsSource = Join-Path $ScriptDir ".claude\settings.json"
$SettingsTarget = "$ProjectPath\.claude\settings.json"
if ($HooksSourceDir -ne $HooksTargetDir -and (Test-Path $HooksSourceDir)) {
    New-Item -ItemType Directory -Force -Path $HooksTargetDir | Out-Null
    Copy-Item -Path "$HooksSourceDir\*" -Destination $HooksTargetDir -Force -Recurse
    Write-Success "已复制 Hooks 到 .claude/hooks/"
} else {
    Write-Info "源目录与目标目录相同或源目录不存在，已跳过 Hooks 复制"
}
if (Test-Path $SettingsSource) {
    if (Test-Path $SettingsTarget) {
        Write-Warn ".claude/settings.json 已存在，如需合并 Hook 配置请手动处理"
    } else {
        Copy-Item -Path $SettingsSource -Destination $SettingsTarget -Force
        Write-Success "已复制 settings.json 到 .claude/"
    }
}

# 12. 创建本地偏好文件 (gitignored)
Write-Step "创建 CLAUDE.local.md (本地偏好)"
$localMd = @"
# 本地个人偏好
# 此文件会被 .gitignore 忽略，不会提交到仓库

> 由 claude-code-init 自动生成
> 版本: v1.0.0 | $(Get-Date -Format 'yyyy-MM-dd')

---

## 个人偏好设置

- 开始编码前先解释 Plan
- 所有异步函数必须有 timeout
- 复杂任务先创建 Plan.md

---
"@
$localMd | Out-File -FilePath "$ProjectPath\CLAUDE.local.md" -Encoding utf8
Write-Success "已创建 CLAUDE.local.md"

# 13. 配置 .gitignore
Write-Step "配置 .gitignore"
$gitignoreScript = Join-Path $ScriptDir "scripts\configure-gitignore.ps1"
if (Test-Path $gitignoreScript) {
    & $gitignoreScript -ProjectPath $ProjectPath
} else {
    Write-Warn "configure-gitignore.ps1 未找到，跳过 .gitignore 配置"
}

# 14. 配置无人值守长任务（可选）
Write-Step "配置无人值守长任务"
Write-Info "正在复制无人值守脚本..."
$unattendedScripts = @(
    "tmux-session.sh",
    "ralph-setup.sh",
    "PROMPT.md"
)
foreach ($script in $unattendedScripts) {
    $src = Join-Path $ScriptDir "scripts\$script"
    $dst = Join-Path $ProjectPath "scripts\$script"
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dst -Force -ErrorAction SilentlyContinue
        Write-Info "已复制 $script"
    }
}

# 15. 配置 gstack 命令（可选）
Write-Step "配置 gstack 角色命令"
$gstackCommands = @(
    "team.md",
    "messages.md",
    "qa.md",
    "plan-ceo-review.md"
)
$targetCommandsDir = Join-Path $ProjectPath ".claude\commands"
foreach ($cmd in $gstackCommands) {
    $src = Join-Path $ScriptDir "commands\$cmd"
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $targetCommandsDir -Force -ErrorAction SilentlyContinue
        Write-Info "已复制 $cmd"
    }
}

Write-Host ""
Write-Host "无人值守功能已配置。" -ForegroundColor Yellow
Write-Host "  - tmux-session.sh: 启动无人值守会话" -ForegroundColor Gray
Write-Host "  - ralph-setup.sh: 安装 Ralph Wiggum 插件" -ForegroundColor Gray
Write-Host "  - /team: 启动 Agent 团队" -ForegroundColor Gray
Write-Host "  - /qa: 质量保证测试" -ForegroundColor Gray

# 完成
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  初始化完成！" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
# 显示用户输入的原始路径，而非解析后的绝对路径
$displayPath = if ($OriginalPath) { $OriginalPath } else { "." }
Write-Host "位置: $displayPath" -ForegroundColor White
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  1. 编辑 CLAUDE.md 写入项目特定的架构规则" -ForegroundColor White
Write-Host "  2. 编辑 SOUL.md 定义项目的 AI 人格" -ForegroundColor White
Write-Host "  3. 启动 Claude Code，开始开发" -ForegroundColor White
Write-Host ""
Write-Host "如需更新规范，运行:" -ForegroundColor Gray
Write-Host "  git -C `"$ScriptDir`" pull" -ForegroundColor Gray
Write-Host ""
