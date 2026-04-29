#!/bin/bash
# scripts/configure-gitignore.sh
# 用途：统一处理 AI 配置文件的 .gitignore 策略
# 用法：bash scripts/configure-gitignore.sh [项目路径]
# 与 configure-gitignore.ps1 保持一致的逻辑

PROJECT_PATH="${1:-.}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo_step() { echo -e "${CYAN}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }

cd "$PROJECT_PATH"

echo ""
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}  如何处理 AI 开发配置文件？${NC}"
echo -e "${CYAN}==============================================${NC}"
echo ""
echo -e "  ${YELLOW}1)${NC} 全部忽略（推荐）—— 将所有 AI 配置文件加入 .gitignore"
echo -e "  ${YELLOW}2)${NC} 部分提交 —— 提交团队共享配置，仅忽略个人偏好文件"
echo -e "  ${YELLOW}3)${NC} 全部提交 —— 所有 AI 配置提交到仓库"
echo ""

read -p "请选择 (1/2/3，默认 1): " choice
choice=${choice:-1}

GITIGNORE_PATH="$PROJECT_PATH/.gitignore"

# 读取已有内容，移除之前 claude-code-init 写入的规则块
if [ -f "$GITIGNORE_PATH" ]; then
    # 移除 claude-code-init 标记的块
    existing=$(sed '/# === claude-code-init ===/,/# === claude-code-init ===/d' "$GITIGNORE_PATH" 2>/dev/null || cat "$GITIGNORE_PATH")
    existing=$(echo "$existing" | sed '/^[[:space:]]*$/d' | sed '$a\')
else
    existing=""
fi

case $choice in
    1)
        rules="# === claude-code-init ===
# Claude Code 开发环境配置（已全部忽略）
.claude/
.pre-commit-config.yaml
CLAUDE.md
SOUL.md
PLAN_TEMPLATE.md
openspec/
docs/
# === claude-code-init ==="
        echo_success "已将所有 AI 配置文件加入 .gitignore"
        ;;
    2)
        rules="# === claude-code-init ===
# Claude Code 个人本地文件（务必忽略）
CLAUDE.local.md
# === claude-code-init ==="
        echo_success "已忽略个人偏好文件，其他配置可提交"
        ;;
    3)
        rules="# === claude-code-init ===
# Claude Code 个人本地文件
CLAUDE.local.md
# === claude-code-init ==="
        echo_success "所有 AI 配置文件提交就绪"
        ;;
    *)
        rules="# === claude-code-init ===
# Claude Code 开发环境配置（已全部忽略）
.claude/
.pre-commit-config.yaml
CLAUDE.md
SOUL.md
PLAN_TEMPLATE.md
openspec/
docs/
# === claude-code-init ==="
        echo_warn "无效选择，已按默认处理（全部忽略）"
        ;;
esac

# 写入文件
if [ -n "$existing" ]; then
    printf "%s\n\n%s\n" "$existing" "$rules" > "$GITIGNORE_PATH"
else
    printf "%s\n" "$rules" > "$GITIGNORE_PATH"
fi

echo_success ".gitignore 已更新"
