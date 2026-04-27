# claude-code-init - Claude Code 开发环境一键初始化
# 用法: .\init.ps1 -ProjectPath "E:\产品\我的新项目"
# 版本: v1.0.0 | 2026-04-28

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
Write-Host "  Claude Code 开发环境一键初始化 (v1.0.0)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# 1. 确认目标目录
Write-Step "确认目标目录: $ProjectPath"
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

# 5. 安装 OpenSpec (SDD)
if (-not $SkipOpenSpec) {
    Write-Step "安装 OpenSpec (SDD 工作流)"
    Write-Info "请在终端执行:"
    Write-Host "  npx kld-sdd" -ForegroundColor Yellow
} else {
    Write-Info "跳过 OpenSpec 安装"
}

# 6. 安装 cc-discipline (物理防火墙)
if (-not $SkipCcDiscipline) {
    Write-Step "安装 cc-discipline (物理防火墙 Hooks)"
    $CcDisciplinePath = "$HOME\.cc-discipline"
    if (-not (Test-Path $CcDisciplinePath)) {
        Write-Warn "即将从第三方仓库下载代码: https://github.com/TechHU-GS/cc-discipline"
        Write-Info "克隆 cc-discipline 仓库..."
        git clone https://github.com/TechHU-GS/cc-discipline.git $CcDisciplinePath
        Write-Warn "即将执行第三方脚本: $HOME/.cc-discipline/init.sh"
        Write-Info "请在项目目录执行:"
        Write-Host "  bash `$HOME/.cc-discipline/init.sh" -ForegroundColor Yellow
    } else {
        Write-Warn "即将执行第三方脚本: $HOME/.cc-discipline/init.sh"
        Write-Info "请在项目目录执行:"
        Write-Host "  bash `$HOME/.cc-discipline/init.sh" -ForegroundColor Yellow
    }
} else {
    Write-Info "跳过 cc-discipline 安装"
}

# 7. 复制 Python 校验脚本
Write-Step "复制校验脚本到 scripts/"
$ScriptsDir = Join-Path $ScriptDir "scripts"
$TargetScriptsDir = "$ProjectPath\scripts"
if (Test-Path $ScriptsDir) {
    New-Item -ItemType Directory -Force -Path $TargetScriptsDir | Out-Null
    Copy-Item -Path "$ScriptsDir\*" -Destination $TargetScriptsDir -Force -Recurse
    Write-Success "已复制校验脚本到 scripts/"
} else {
    Write-Info "scripts 目录不存在，跳过"
}

# 8. 复制 Pre-commit 配置
Write-Step "复制 Pre-commit 配置"
$PrecommitConfig = Join-Path $ScriptDir "configs\.pre-commit-config.yaml"
$TargetPrecommitConfig = "$ProjectPath\.pre-commit-config.yaml"
if (Test-Path $PrecommitConfig) {
    Copy-Item -Path $PrecommitConfig -Destination $TargetPrecommitConfig -Force
    Write-Success "已复制 .pre-commit-config.yaml"
} else {
    Write-Info "Pre-commit 配置不存在，跳过"
}

# 9. 安装 Pre-commit hooks
Write-Step "安装 Pre-commit Hooks"

# 检查 Python 是否可用
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    # 检查 pre-commit 是否已安装
    $precommitCheck = python -c "import pre_commit" 2>$null
    if (-not $precommitCheck) {
        Write-Info "正在下载并安装 pre-commit（可能需要几分钟，请耐心等待）..."
        python -m pip install --quiet pre-commit
        Write-Success "pre-commit 安装完成"
    }
    Write-Info "执行: pre-commit install"
    pre-commit install
    Write-Success "Pre-commit Hooks 已安装"
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
if (Test-Path $CommandsDir) {
    New-Item -ItemType Directory -Force -Path $TargetCommandsDir | Out-Null
    Copy-Item -Path "$CommandsDir\*" -Destination $TargetCommandsDir -Force -Recurse
    Write-Success "已复制自定义命令到 .claude/commands/"
} else {
    Write-Info "命令目录不存在，跳过"
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

# 13. 更新 .gitignore
Write-Step "更新 .gitignore"
$gitignorePath = "$ProjectPath\.gitignore"
if (-not (Test-Path $gitignorePath)) {
    "CLAUDE.local.md" | Out-File -FilePath $gitignorePath -Encoding utf8
} else {
    $gitignore = Get-Content $gitignorePath -Raw
    if ($gitignore -notmatch "CLAUDE\.local\.md") {
        Add-Content -Path $gitignorePath -Value "`n# Claude Code 本地偏好`nCLAUDE.local.md"
    }
}
Write-Success "已更新 .gitignore"

# 完成
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  初始化完成！" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "位置: $ProjectPath" -ForegroundColor White
Write-Host ""
Write-Host "下一步:" -ForegroundColor Cyan
Write-Host "  1. 编辑 CLAUDE.md 写入项目特定的架构规则" -ForegroundColor White
Write-Host "  2. 编辑 SOUL.md 定义项目的 AI 人格" -ForegroundColor White
Write-Host "  3. 启动 Claude Code，开始开发" -ForegroundColor White
Write-Host ""
Write-Host "如需更新规范，运行:" -ForegroundColor Gray
Write-Host "  git -C `"$ScriptDir`" pull" -ForegroundColor Gray
Write-Host ""
