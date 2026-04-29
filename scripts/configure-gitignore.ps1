# scripts/configure-gitignore.ps1
# 用途：单独运行此脚本，更改 AI 配置文件的 .gitignore 策略
# 用法：.\scripts\configure-gitignore.ps1 [-ProjectPath <路径>]

param(
    [string]$ProjectPath = "."
)

Set-Location $ProjectPath

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  如何处理 AI 开发配置文件？" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1) 全部忽略（推荐）—— 将所有 AI 配置文件加入 .gitignore"
Write-Host "  2) 部分提交 —— 提交团队共享配置，仅忽略个人偏好文件"
Write-Host "  3) 全部提交 —— 所有 AI 配置提交到仓库"
Write-Host ""

$choice = Read-Host "请选择 (1/2/3，默认 1)"
if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

$gitignorePath = Join-Path $ProjectPath ".gitignore"

# 读取已有内容，移除之前 claude-code-init 写入的规则块
if (Test-Path $gitignorePath) {
    $existing = Get-Content $gitignorePath -Raw
    # 移除 claude-code-init 标记的块
    $existing = $existing -replace "(?ms)# === claude-code-init ===.*?# === claude-code-init ===", ""
    $existing = $existing.TrimEnd()
} else {
    $existing = ""
}

switch ($choice) {
    "1" {
        $rules = @(
            "# === claude-code-init ===",
            "# Claude Code 开发环境配置（已全部忽略）",
            ".claude/",
            ".pre-commit-config.yaml",
            "CLAUDE.md",
            "SOUL.md",
            "PLAN_TEMPLATE.md",
            "openspec/"
        )
        Write-Host "[OK] 已将所有 AI 配置文件加入 .gitignore" -ForegroundColor Green
    }
    "2" {
        $rules = @(
            "# === claude-code-init ===",
            "# Claude Code 个人本地文件（务必忽略）",
            ".claude/CLAUDE.local.md",
            "# === claude-code-init ==="
        )
        Write-Host "[OK] 已忽略个人偏好文件，其他配置可提交" -ForegroundColor Green
    }
    "3" {
        $rules = @(
            "# === claude-code-init ===",
            "# Claude Code 个人本地文件",
            ".claude/CLAUDE.local.md",
            "# === claude-code-init ==="
        )
        Write-Host "[OK] 所有 AI 配置文件提交就绪" -ForegroundColor Green
    }
    default {
        $rules = @(
            "# === claude-code-init ===",
            "# Claude Code 开发环境配置（已全部忽略）",
            ".claude/",
            ".pre-commit-config.yaml",
            "CLAUDE.md",
            "SOUL.md",
            "PLAN_TEMPLATE.md",
            "openspec/"
        )
        Write-Host "[OK] 已按默认处理（全部忽略）" -ForegroundColor Yellow
    }
}

$newContent = if ($existing) {
    "$existing`n`n$($rules -join "`n")"
} else {
    $rules -join "`n"
}
$newContent | Out-File -FilePath $gitignorePath -Encoding utf8
