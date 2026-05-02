# claude-code-init - Claude Code 开发环境一键初始化
# 用法: .\init.ps1 -ProjectPath "E:\产品\我的新项目"
# 版本: v1.6.5 | 2026-05-02

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [switch]$SkipECC,
    [switch]$SkipSuperpowers,
    [switch]$SkipOpenSpec,
    [switch]$SkipCcDiscipline,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$CleanupNeeded = $false
$InitCompleted = $false

# 设置 UTF-8 输出编码（防止通过 bash 管道时中文字符乱码）
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# 路径规范化比较（处理符号链接、junction、不同路径表示形式）
function Test-SamePath {
    param([string]$PathA, [string]$PathB)
    try {
        $resolvedA = (Resolve-Path $PathA -ErrorAction Stop).ProviderPath
        $resolvedB = (Resolve-Path $PathB -ErrorAction Stop).ProviderPath
        return $resolvedA -eq $resolvedB
    } catch {
        return $false
    }
}

# 颜色输出
function Write-Step { param($msg) Write-Host "[步骤] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[成功] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[警告] $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "[失败] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[信息] $msg" -ForegroundColor Gray }

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Claude Code 开发环境一键初始化 (v1.6.5)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

try {

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

# Git 初始化成功后，标记需要清理（脚本中途退出时清理）
$CleanupNeeded = $true

# ─── 模式检测 ───
$InstallMode = "fresh"
$versionFile = "$ProjectPath\.claude\.claude-code-init-version"
if (Test-Path $versionFile) {
    $InstallMode = "reconfigure"
    Write-Info "检测到 claude-code-init 重运行（reconfigure 模式）"
} elseif (Test-Path "$ProjectPath\.claude") {
    $InstallMode = "append"
    Write-Info "检测到已有 .claude 配置（append 模式）"
}

# ─── 预操作备份 ───
if (Test-Path "$ProjectPath\.claude") {
    Write-Step "备份已有配置（预操作）"
    $backupDir = "$ProjectPath\.claude\.init-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    if (Test-Path "$ProjectPath\.claude\settings.json") { Copy-Item "$ProjectPath\.claude\settings.json" "$backupDir\" }
    if (Test-Path "$ProjectPath\.claude\hooks") { Copy-Item -Recurse "$ProjectPath\.claude\hooks" "$backupDir\" }
    if (Test-Path "$ProjectPath\.claude\skills") { Copy-Item -Recurse "$ProjectPath\.claude\skills" "$backupDir\" }
    if (Test-Path "$ProjectPath\.claude\commands") { Copy-Item -Recurse "$ProjectPath\.claude\commands" "$backupDir\" }
    Write-Success "备份到 $(Split-Path $backupDir -Leaf)/"
}

# 3. 安装核心 Claude Code 插件 (ECC + Superpowers)
if ($SkipECC -and $SkipSuperpowers) {
    Write-Info "跳过插件安装 (SkipECC, SkipSuperpowers)"
} else {
    Write-Step "安装核心 Claude Code 插件"
    if (-not $SkipECC) {
        Write-Info "  ECC — 请在 Claude Code 中执行:"
        Write-Host "    /plugin marketplace add affaan-m/everything-claude-code" -ForegroundColor Yellow
        Write-Host "    /plugin install everything-claude-code@everything-claude-code" -ForegroundColor Yellow
        Write-Info "  选择 'Install for you (user scope)'"
    }
    if (-not $SkipSuperpowers) {
        Write-Info "  Superpowers — 请在 Claude Code 中执行:"
        Write-Host "    /plugin marketplace add obra/superpowers-marketplace" -ForegroundColor Yellow
        Write-Host "    /plugin install superpowers@superpowers-marketplace" -ForegroundColor Yellow
    }
}

# 3.1 插件确认 (-Force 模式下跳过交互)
if ((-not $SkipECC -or -not $SkipSuperpowers) -and -not $Force) {
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Yellow
    Write-Host " 重要：以上插件需要在 Claude Code 中手动安装" -ForegroundColor Yellow
    Write-Host " 如果你已完成安装，请输入 y 继续；否则请输入 n 退出" -ForegroundColor Yellow
    Write-Host "==============================================" -ForegroundColor Yellow
    $confirm = Read-Host "是否已完成插件安装？(y/n)"
    if ($confirm -ne "y") {
        Write-Host "请先完成插件安装，再重新运行此脚本。" -ForegroundColor Red
        exit 1
    }
    Write-Success "已确认插件安装"
} else {
    Write-Info "已跳过插件安装确认"
}

# 4. 安装 OpenSpec (SDD) - 自动执行
if (-not $SkipOpenSpec) {
    Write-Step "安装 OpenSpec (SDD 工作流)"
    try {
        npm install -g @fission-ai/openspec@1.3.1
        openspec init --tools claude
        Write-Success "OpenSpec 已初始化"
    } catch {
        Write-Warn "OpenSpec 自动安装失败，请手动执行: npm install -g @fission-ai/openspec@1.3.1 && openspec init --tools claude"
    }
} else {
    Write-Info "跳过 OpenSpec 安装"
}

# 5. 安装 cc-discipline (物理防火墙) - 自动执行
if (-not $SkipCcDiscipline) {
    # 前置检查: jq (cc-discipline JSON 合并依赖)
    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        Write-Warn "未找到 jq，cc-discipline 需要 jq 进行 settings.json 合并"
        Write-Info "请手动安装: https://jqlang.github.io/jq/download/"
    }
    Write-Step "安装 cc-discipline (物理防火墙 Hooks)"
    # $HOME 跨平台兼容（Windows 用 USERPROFILE，Unix 用 HOME）
    $CcDisciplineHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
    $CcDisciplinePath = "$CcDisciplineHome\.cc-discipline"
    $CcDisciplineCommit = "916da00691128fde44599928d76c129f3d08b8f1"  # 锁定版本 2026-04-26
    if (-not (Test-Path $CcDisciplinePath)) {
        Write-Warn "即将从第三方仓库下载代码: https://github.com/TechHU-GS/cc-discipline"
        Write-Info "克隆 cc-discipline 仓库..."
        git clone --depth 1 -b main https://github.com/TechHU-GS/cc-discipline.git $CcDisciplinePath
        Set-Location $CcDisciplinePath
        git checkout $CcDisciplineCommit
        # 验证 commit 是否匹配锁定版本
        $actualCommit = (git rev-parse HEAD).Trim()
        if ($actualCommit -ne $CcDisciplineCommit) {
            Write-Fail "commit 不匹配！预期: $($CcDisciplineCommit.Substring(0,7)), 实际: $($actualCommit.Substring(0, [Math]::Min(7, $actualCommit.Length)))"
            Set-Location $ProjectPath
            Remove-Item -Recurse -Force $CcDisciplinePath -ErrorAction SilentlyContinue
            exit 1
        }
        # GPG 签名验证（可选，需要公钥）
        git verify-commit HEAD 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "GPG 签名验证通过"
        }
        Set-Location $ProjectPath
        Write-Success "已克隆并验证 cc-discipline (commit: $($CcDisciplineCommit.Substring(0,7)))"
    } else {
        Write-Info "cc-discipline 已存在"
        $existingCommit = (git -C $CcDisciplinePath rev-parse HEAD 2>&1).Trim()
        if ($existingCommit -ne $CcDisciplineCommit) {
            Write-Warn "现有 commit ($($existingCommit.Substring(0, [Math]::Min(7, $existingCommit.Length)))) 与锁定版本 ($($CcDisciplineCommit.Substring(0,7))) 不一致，正在切换..."
            git -C $CcDisciplinePath fetch origin
            git -C $CcDisciplinePath checkout $CcDisciplineCommit
        }
    }
    Write-Info "正在执行 cc-discipline 初始化..."
    try {
        $ccArgs = @()
        if ($Force) { $ccArgs += "--auto" }
        $bashCmd = Get-Command bash -ErrorAction SilentlyContinue
        if ($bashCmd) {
            bash "$CcDisciplinePath/init.sh" @ccArgs
            Write-Success "cc-discipline 已安装"
        } else {
            Write-Warn "未找到 bash 命令，无法自动执行 cc-discipline 初始化"
            Write-Info "请手动执行以下命令："
            Write-Host "  bash $CcDisciplinePath/init.sh" -ForegroundColor Yellow
        }
        # 验证 cc-discipline 部署完整性
        $ccDiscVerFile = "$ProjectPath\.claude\.cc-discipline-version"
        if (Test-Path $ccDiscVerFile) {
            $ccDiscVer = Get-Content $ccDiscVerFile -Raw
            if ($ccDiscVer.Trim() -eq "unknown" -or [string]::IsNullOrWhiteSpace($ccDiscVer)) {
                Write-Warn "cc-discipline 版本检测异常，部分功能可能不正常"
            }
        }
    } catch {
        Write-Warn "cc-discipline 初始化失败，请手动执行: bash $CcDisciplinePath/init.sh"
    }
} else {
    Write-Info "跳过 cc-discipline 安装"
}

# 6. 复制 Python 校验脚本（白名单部署）
Write-Step "复制校验脚本和 Shell 工具到 .claude/scripts/"

# 部署目标项目需要的脚本（白名单）
# - Python 校验脚本（pre-commit hooks 使用）
# - Shell 工具脚本（Skills/Router 引用）
# 不包括：check-env.sh、configure-gitignore.*、lib/（仅 init 时用）
# 不包括：__pycache__/（编译缓存）
$ScriptWhitelist = @(
    "check-env.sh", "check_dependencies.py", "check_docs_consistency.py",
    "check_ecc.sh", "check_function_length.py",
    "check_import_order.py", "check_path_consistency.py",
    "check_project_structure.py", "check_secrets.py",
    "check_trigger_conflicts.py",
    "tmux-session.sh", "weekly-report.sh", "ralph-setup.sh",
    "trigger-optimizer.sh", "validate_skills.sh", "PROMPT.md"
)

$ScriptsDir = Join-Path $ScriptDir "scripts"
$TargetScriptsDir = "$ProjectPath\.claude\scripts"
if (Test-SamePath $ScriptsDir $TargetScriptsDir) {
    Write-Info "源目录与目标目录相同，已跳过脚本复制"
} elseif (Test-Path $ScriptsDir) {
    New-Item -ItemType Directory -Force -Path $TargetScriptsDir | Out-Null
    foreach ($file in $ScriptWhitelist) {
        $src = Join-Path $ScriptsDir $file
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $TargetScriptsDir -Force
        }
    }
    Write-Success "已复制校验脚本和 Shell 工具到 .claude/scripts/"
} else {
    Write-Info "scripts 目录不存在，跳过"
}

# 7. 复制 Pre-commit 配置
Write-Step "复制 Pre-commit 配置"
$PrecommitConfig = Join-Path $ScriptDir "configs\.pre-commit-config.yaml"
$TargetPrecommitConfig = "$ProjectPath\.pre-commit-config.yaml"
if ($PrecommitConfig -eq $TargetPrecommitConfig) {
    Write-Info "源文件与目标文件相同，已跳过 Pre-commit 配置复制"
} elseif (Test-Path $PrecommitConfig) {
    if (Test-Path $TargetPrecommitConfig) {
        if ($Force) {
            Copy-Item -Path $TargetPrecommitConfig -Destination "$TargetPrecommitConfig.bak" -Force
            Copy-Item -Path $PrecommitConfig -Destination $TargetPrecommitConfig -Force
            Write-Success "已覆盖 .pre-commit-config.yaml（原文件备份为 .bak）"
        } else {
            Write-Warn ".pre-commit-config.yaml 已存在，跳过（使用 -Force 可覆盖）"
        }
    } else {
        Copy-Item -Path $PrecommitConfig -Destination $TargetPrecommitConfig -Force
        Write-Success "已复制 .pre-commit-config.yaml"
    }
} else {
    Write-Info "Pre-commit 配置不存在，跳过"
}

# 8. 安装 Pre-commit hooks - 自动执行
Write-Step "安装 Pre-commit Hooks"

# 检查 Python 是否可用
$pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $pythonCmd) { $pythonCmd = Get-Command python -ErrorAction SilentlyContinue }
if ($pythonCmd) {
    # 检查 pre-commit 是否已安装
    try {
        $null = & $pythonCmd -c "import pre_commit" 2>$null
    } catch {
        Write-Info "正在安装 pre-commit..."
        & $pythonCmd -m pip install --quiet "pre-commit>=4.0"
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

# 9. 复制覆盖层模板
Write-Step "复制覆盖层模板"
$TemplateDir = Join-Path $ScriptDir "templates"

# 辅助: 获取模板版本号
function Get-TemplateVersion {
    param($Path)
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
        $match = [regex]::Match($content, '模板版本：\s*(v[\d]+\.[\d]+\.[\d]+)')
        if ($match.Success) { return $match.Groups[1].Value }
    }
    return $null
}

# 模板复制函数: 目标已存在时提供交互选择
function Copy-Template {
    param($Source, $Target, $DisplayName)

    if (-not (Test-Path $Target)) {
        Copy-Item -Path $Source -Destination $Target -Force
        Write-Success "已复制 $DisplayName"
        return
    }

    $srcVer = Get-TemplateVersion $Source
    $tgtVer = Get-TemplateVersion $Target

    if ($Force) {
        Copy-Item -Path $Target -Destination "$Target.bak" -Force
        Copy-Item -Path $Source -Destination $Target -Force
        Write-Success "已强制覆盖 $DisplayName (原文件备份为 .bak)"
        return
    }

    Write-Host ""
    Write-Host "━━━ $DisplayName 已存在 ━━━" -ForegroundColor Yellow
    if ($tgtVer) { Write-Host "  目标版本: $tgtVer" -ForegroundColor Gray }
    if ($srcVer) { Write-Host "  源版本:   $srcVer" -ForegroundColor Green }
    Write-Host ""
    Write-Host "  [s] 跳过(默认)  [o] 覆盖(备份原文件)  [d] 查看差异" -ForegroundColor Cyan
    $choice = Read-Host "  请选择"
    switch ($choice) {
        'o' {
            Copy-Item -Path $Target -Destination "$Target.bak" -Force
            Copy-Item -Path $Source -Destination $Target -Force
            Write-Success "已覆盖 $DisplayName (原文件备份为 .bak)"
        }
        'd' {
            if (Get-Command git -ErrorAction SilentlyContinue) {
                git diff --no-index $Target $Source 2>$null
                if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { Write-Warn "git diff 不可用" }
            } elseif (Get-Command fc.exe -ErrorAction SilentlyContinue) {
                fc.exe /N $Target $Source
            } else {
                Write-Warn "无法显示差异 (git/fc 不可用)"
            }
            Write-Host ""
            Write-Host "  [s] 跳过  [o] 覆盖(备份原文件)" -ForegroundColor Cyan
            $choice2 = Read-Host "  现在选择"
            if ($choice2 -eq 'o') {
                Copy-Item -Path $Target -Destination "$Target.bak" -Force
                Copy-Item -Path $Source -Destination $Target -Force
                Write-Success "已覆盖 $DisplayName (原文件备份为 .bak)"
            }
        }
        default { Write-Info "已跳过 $DisplayName" }
    }
}

if (Test-Path $TemplateDir) {
    Copy-Template (Join-Path $TemplateDir "CLAUDE_Template.md") "$ProjectPath\CLAUDE.md" "CLAUDE.md"
    Copy-Template (Join-Path $TemplateDir "SOUL_Template.md") "$ProjectPath\SOUL.md" "SOUL.md"
    New-Item -ItemType Directory -Force -Path "$ProjectPath\.claude" | Out-Null
    Copy-Template (Join-Path $TemplateDir "PLAN_Template.md") "$ProjectPath\.claude\PLAN_Template.md" "PLAN_Template.md"
    Copy-Template (Join-Path $TemplateDir "SPEC_Template.md") "$ProjectPath\.claude\SPEC_Template.md" "SPEC_Template.md"
    Copy-Template (Join-Path $TemplateDir "ROUTINE_Template.md") "$ProjectPath\.claude\ROUTINE_Template.md" "ROUTINE_Template.md"
} else {
    Write-Warn "模板目录不存在，跳过模板复制"
}

# 9.1 模板版本检查
Write-Step "检查模板版本"
function Check-TemplateVersion {
    param($SrcPath, $TargetPath)
    if ((Test-Path $SrcPath) -and (Test-Path $TargetPath)) {
        $srcContent = Get-Content $SrcPath -Raw -ErrorAction SilentlyContinue
        $targetContent = Get-Content $TargetPath -Raw -ErrorAction SilentlyContinue
        $srcMatch = [regex]::Match($srcContent, '模板版本：\s*(v[\d]+\.[\d]+\.[\d]+)')
        $targetMatch = [regex]::Match($targetContent, '模板版本：\s*(v[\d]+\.[\d]+\.[\d]+)')
        if ($srcMatch.Success -and $targetMatch.Success -and ($srcMatch.Groups[1].Value -ne $targetMatch.Groups[1].Value)) {
            $name = Split-Path $TargetPath -Leaf
            Write-Warn "   $name : 源版本 $($srcMatch.Groups[1].Value) / 目标版本 $($targetMatch.Groups[1].Value) — 建议手动合并更新"
        }
    }
}
Check-TemplateVersion (Join-Path $TemplateDir "CLAUDE_Template.md") "$ProjectPath\CLAUDE.md"
Check-TemplateVersion (Join-Path $TemplateDir "SOUL_Template.md") "$ProjectPath\SOUL.md"
Check-TemplateVersion (Join-Path $TemplateDir "PLAN_Template.md") "$ProjectPath\.claude\PLAN_Template.md"
Check-TemplateVersion (Join-Path $TemplateDir "SPEC_Template.md") "$ProjectPath\.claude\SPEC_Template.md"
Check-TemplateVersion (Join-Path $TemplateDir "ROUTINE_Template.md") "$ProjectPath\.claude\ROUTINE_Template.md"
Write-Success "模板版本检查完成"

# 9.2 复制记忆系统模板
Write-Step "复制记忆系统模板"
$MemoryTemplate = Join-Path $TemplateDir "memory\MEMORY.md"
if (Test-Path $MemoryTemplate) {
    New-Item -ItemType Directory -Force -Path "$ProjectPath\.claude\memory\archive" | Out-Null
    New-Item -ItemType File -Force -Path "$ProjectPath\.claude\memory\archive\.gitkeep" | Out-Null
    Copy-Template $MemoryTemplate (Join-Path $ProjectPath ".claude\memory\MEMORY.md") "MEMORY.md"
    Write-Success "已复制记忆系统模板到 .claude/memory/"
} else {
    Write-Info "记忆模板不存在，跳过"
}

# 10. 复制自定义命令
Write-Step "复制自定义命令"
$CommandsDir = Join-Path $ScriptDir "commands"
$TargetCommandsDir = "$ProjectPath\.claude\commands"
if (Test-SamePath $CommandsDir $TargetCommandsDir) {
    Write-Info "源目录与目标目录相同，已跳过命令复制"
} elseif (Test-Path $CommandsDir) {
    New-Item -ItemType Directory -Force -Path $TargetCommandsDir | Out-Null
    Copy-Item -Path "$CommandsDir\*" -Destination $TargetCommandsDir -Force -Recurse
    Write-Success "已复制自定义命令到 .claude/commands/"
} else {
    Write-Info "命令目录不存在，跳过"
}

# 10.1 复制 Skills
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

# 10.2 复制 Hooks 和 settings.json
Write-Step "复制 Hooks 和设置"
$HooksSourceDir = Join-Path $ScriptDir ".claude\hooks"
$HooksTargetDir = "$ProjectPath\.claude\hooks"
$SettingsSource = Join-Path $ScriptDir ".claude\settings.json"
$SettingsTarget = "$ProjectPath\.claude\settings.json"
if (-not (Test-SamePath $HooksSourceDir $HooksTargetDir) -and (Test-Path $HooksSourceDir)) {
    New-Item -ItemType Directory -Force -Path $HooksTargetDir | Out-Null
    Copy-Item -Path "$HooksSourceDir\*" -Destination $HooksTargetDir -Force -Recurse
    Write-Success "已复制 Hooks 到 .claude/hooks/"
} else {
    Write-Info "源目录与目标目录相同或源目录不存在，已跳过 Hooks 复制"
}
if (Test-Path $SettingsSource) {
    if (Test-Path $SettingsTarget) {
        # 调用独立脚本合并 settings.json（env + hooks 按规则去重，预操作备份已包含此文件）
        $pythonBin = $null
        if (Get-Command python3 -ErrorAction SilentlyContinue) { $pythonBin = "python3" }
        elseif (Get-Command python -ErrorAction SilentlyContinue) { $pythonBin = "python" }
        if ($pythonBin) {
            try {
                $mergeScript = Join-Path $ScriptDir "scripts\merge_json.py"
                & $pythonBin $mergeScript $SettingsSource $SettingsTarget 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "已合并 settings.json（smart-context hooks + Agent Teams 环境变量）"
                    # Windows 平台兼容：移除 settings.json 中不兼容的 bash hooks
                    # Claude Code 在 Windows 上使用 Bun 运行时，其 uv_spawn 无法启动 bash
                    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
                        try {
                            $s = Get-Content $SettingsTarget -Raw -ErrorAction Stop
                            $before = $s.Length
                            # 1) 移除单个 bash hook: "command": "bash ..."（连带前面的逗号）
                            $s = $s -replace ',\s*"command":\s*"bash\s[^"]*"', ''
                            # 2) 移除空 hooks 数组: "hooks": [   ]
                            while ($s -match '"hooks":\s*\[\s*\]') {
                                $s = $s -replace '"hooks":\s*\[\s*\]\s*,?\s*', ''
                            }
                            # 3) 移除空的 matcher 对象 { "matcher": "..." }
                            $s = $s -replace '\{[^}]*"matcher":\s*"[^"]*"\s*\}\s*,?\s*', ''
                            if ($s.Length -ne $before) {
                                $s | Out-File -FilePath $SettingsTarget -Encoding utf8 -Force
                                Write-Info "已移除不兼容的 bash hooks，适配 Windows+Bun 运行环境"
                            }
                        } catch {
                            Write-Warn "Windows hooks 兼容处理失败: $_"
                        }
                    }
                } else {
                    Write-Warn "settings.json 合并失败，请从 .init-backup-* 备份中手动恢复"
                }
            } catch {
                Write-Warn "settings.json 合并失败，请从 .init-backup-* 备份中手动恢复"
            }
        } else {
            Write-Warn "settings.json 已存在，无法自动合并（Python 不可用），请从 .init-backup-* 备份中手动合并"
        }
    } else {
        Copy-Item -Path $SettingsSource -Destination $SettingsTarget -Force
        Write-Success "已复制 settings.json 到 .claude/"
    }
}

# 11. 创建本地偏好文件 (gitignored)
Write-Step "创建 CLAUDE.local.md (本地偏好)"
New-Item -ItemType Directory -Force -Path "$ProjectPath\.claude" | Out-Null
$claudeLocalPath = "$ProjectPath\.claude\CLAUDE.local.md"
$claudeLocalTemplate = Join-Path $ScriptDir "templates\CLAUDE.local.template.md"
if (Test-Path $claudeLocalPath) {
    if ($Force) {
        Write-Warn "CLAUDE.local.md 已存在，-Force 模式：覆盖"
        if (Test-Path $claudeLocalTemplate) {
            (Get-Content $claudeLocalTemplate) -replace '__DATE__', (Get-Date -Format 'yyyy-MM-dd') | Out-File -FilePath $claudeLocalPath -Encoding utf8
            Write-Success "已覆盖 CLAUDE.local.md"
        } else {
            Write-Warn "CLAUDE.local.template.md 不存在，跳过 CLAUDE.local.md 创建"
        }
    } else {
        Write-Warn "CLAUDE.local.md 已存在，跳过创建（使用 -Force 可覆盖）"
    }
} elseif (Test-Path $claudeLocalTemplate) {
    (Get-Content $claudeLocalTemplate) -replace '__DATE__', (Get-Date -Format 'yyyy-MM-dd') | Out-File -FilePath $claudeLocalPath -Encoding utf8
    Write-Success "已创建 CLAUDE.local.md (.claude/)"
} else {
    Write-Warn "CLAUDE.local.template.md 不存在，跳过 CLAUDE.local.md 创建"
}

# 创建 MEMORY.local.md (个人私密记忆，不提交)
$memoryLocalPath = "$ProjectPath\.claude\MEMORY.local.md"
$memoryLocalTemplate = Join-Path $ScriptDir "templates\MEMORY.local.template.md"
if (Test-Path $memoryLocalPath) {
    if ($Force) {
        Write-Warn "MEMORY.local.md 已存在，-Force 模式：覆盖"
        if (Test-Path $memoryLocalTemplate) {
            Copy-Item -Path $memoryLocalTemplate -Destination $memoryLocalPath -Force
            Write-Success "已覆盖 MEMORY.local.md"
        } else {
            Write-Warn "MEMORY.local.template.md 不存在，跳过 MEMORY.local.md 创建"
        }
    } else {
        Write-Warn "MEMORY.local.md 已存在，跳过创建（使用 -Force 可覆盖）"
    }
} elseif (Test-Path $memoryLocalTemplate) {
    Copy-Item -Path $memoryLocalTemplate -Destination $memoryLocalPath -Force
    Write-Success "已创建 MEMORY.local.md (gitignored)"
} else {
    Write-Warn "MEMORY.local.template.md 不存在，跳过 MEMORY.local.md 创建"
}

# 12. 配置 .gitignore
Write-Step "配置 .gitignore"
$gitignoreSh = Join-Path $ScriptDir "scripts\configure-gitignore.sh"
$gitignorePs1 = Join-Path $ScriptDir "scripts\configure-gitignore.ps1"

if ($Force) {
    # --force 模式：直接写入默认规则（全部忽略），避免通过管道传递输入
    $gitignorePath = Join-Path $ProjectPath ".gitignore"
    $existing = if (Test-Path $gitignorePath) {
        (Get-Content $gitignorePath -Raw) -replace '# === claude-code-init ===[\s\S]*?# === claude-code-init ===', ""
    } else { "" }
    $rules = @(
        "# === claude-code-init ===",
        "# Claude Code 开发环境配置（已全部忽略）",
        ".claude/",
        ".pre-commit-config.yaml",
        "CLAUDE.md",
        "SOUL.md",
        "PLAN_Template.md",
        "openspec/",
        "# Backup files（由 copy_template 生成）",
        "*.bak",
        "# === claude-code-init ==="
    )
    $newContent = if ($existing.Trim()) { "$($existing.Trim())`n`n$($rules -join "`n")" } else { $rules -join "`n" }
    $newContent | Out-File -FilePath $gitignorePath -Encoding utf8 -Force
    Write-Success "已将所有 AI 配置文件加入 .gitignore"
} elseif (Test-Path $gitignorePs1) {
    # Windows 上优先使用 PowerShell 变体（原生体验）
    & $gitignorePs1 -ProjectPath $ProjectPath
} elseif (Test-Path $gitignoreSh) {
    Write-Info "使用 bash 配置 .gitignore"
    bash "$gitignoreSh" "$ProjectPath"
} else {
    Write-Warn "未找到配置脚本，跳过 .gitignore 配置"
}

# 13. 运行环境检查
Write-Step "运行环境完整性检查"
$checkEnvScript = Join-Path $ScriptDir "scripts\check-env.sh"
if (Test-Path $checkEnvScript) {
    Write-Info "环境检查脚本已复制到项目"
}

# 标记初始化完成（防止 cleanup 误删）
$InitCompleted = $true

# 写入版本标记（用于后续运行的模式检测）
"v1.6.5" | Out-File -FilePath "$ProjectPath\.claude\.claude-code-init-version" -Encoding utf8 -Force

# 完成
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  Claude Code 开发环境初始化完成！" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "你现在拥有：" -ForegroundColor Cyan
Write-Host "  ✅ 10 个核心 Skills（审查/提交/TDD/重构/修复/解释/校验/头脑风暴/初始化/路由）" -ForegroundColor White
if (-not $SkipCcDiscipline) {
    Write-Host "  ✅ + cc-discipline 额外技能（commit/evaluate/investigate/retro 等）" -ForegroundColor White
}
Write-Host "  ✅ 22 个自定义命令（/review /commit /gc /architect /fix /refactor /explain /validate /help /team /qa /capabilities /status /remember /overnight /overnight-report /plan-ceo-review /plan-eng-review /routine /messages /tdd /ship-review）" -ForegroundColor White
Write-Host "  ✅ 场景感知 Hook（编辑测试文件→推荐TDD，编辑安全文件→推荐审查，夜间→推荐无人值守）" -ForegroundColor White
Write-Host "  ✅ 9 个项目完整性校验脚本" -ForegroundColor White
Write-Host "  ✅ Pre-commit 自动检查（18 个检查项）" -ForegroundColor White
Write-Host "  ✅ 无人值守长任务环境（tmux + Ralph Wiggum 循环）" -ForegroundColor White
Write-Host "  ✅ Agent Teams 并行开发/审查（/team）" -ForegroundColor White
Write-Host "  ✅ gstack 角色体系（CEO审查/架构审查/QA测试/6-Agent 发布审查）" -ForegroundColor White
Write-Host "  ✅ Skills 触发优化工具（trigger-optimizer.sh）" -ForegroundColor White
Write-Host "  ✅ 周报生成工具（weekly-report.sh）" -ForegroundColor White
Write-Host ""
Write-Host "下一步：" -ForegroundColor Yellow
Write-Host "  1. 编辑 CLAUDE.md 写入项目特有的架构规则" -ForegroundColor White
Write-Host "  2. 编辑 SOUL.md 定义此项目的 AI 人格" -ForegroundColor White
Write-Host "  3. 启动 Claude Code，开始开发" -ForegroundColor White
Write-Host "  4. 输入 /help 查看完整使用指南" -ForegroundColor White
Write-Host "  5. 输入 /status 查看项目状态仪表盘" -ForegroundColor White
Write-Host "  6. 输入 /capabilities 按场景查看全部能力" -ForegroundColor White
Write-Host ""

# 14. 全局偏好设置引导（跨所有项目生效）
Write-Host "[建议] 设置全局偏好（跨所有项目生效）：" -ForegroundColor Yellow
$globalHome = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$globalClaude = "$globalHome\.claude\CLAUDE.md"
Write-Host "  将你的通用编码偏好写入 $globalClaude" -ForegroundColor Gray
Write-Host "  例如：" -ForegroundColor Gray
Write-Host "  - 所有函数必须有类型标注" -ForegroundColor Gray
Write-Host "  - 偏好 Python 3.12+ 语法" -ForegroundColor Gray
Write-Host "  - 注释使用中文" -ForegroundColor Gray
Write-Host ""

Write-Host "如需更新规范，运行:" -ForegroundColor Gray
Write-Host "  git -C `"$ScriptDir`" pull" -ForegroundColor Gray
Write-Host ""

} catch {
    Write-Fail "初始化失败: $_"
    $InitCompleted = $false
    exit 1
} finally {
    if (-not $InitCompleted -and $CleanupNeeded) {
        Write-Host ""
        Write-Warn "⚠️  初始化未完成，正在清理..."
        $claudeDir = "$ProjectPath\.claude"
        if (Test-Path $claudeDir) {
            Remove-Item -Recurse -Force $claudeDir
            Write-Warn "已清理 $claudeDir"
        }
    }
}
