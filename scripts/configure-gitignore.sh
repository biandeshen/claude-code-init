#!/bin/bash
# scripts/configure-gitignore.sh
# 用途：统一处理 AI 配置文件的 .gitignore 策略
# 用法：bash scripts/configure-gitignore.sh [项目路径]
# 与 configure-gitignore.ps1 保持一致的逻辑

set -e

PROJECT_PATH="${1:-.}"

# 加载公共库（颜色输出 + 工具函数）
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$_SCRIPT_DIR/lib/common.sh" ]; then
    source "$_SCRIPT_DIR/lib/common.sh"
fi

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

read -p "请选择 (1/2/3，默认 1): " choice || true
choice=${choice:-1}

GITIGNORE_PATH="$PROJECT_PATH/.gitignore"

# 读取已有内容，移除之前 claude-code-init 写入的规则块
if [ -f "$GITIGNORE_PATH" ]; then
    # 移除 claude-code-init 标记的块
    existing=$(sed '/# === claude-code-init ===/,/# === claude-code-init ===/d' "$GITIGNORE_PATH" 2>/dev/null || cat "$GITIGNORE_PATH")
    existing=$(echo "$existing" | sed '/^[[:space:]]*$/d')
    # Ensure trailing newline (portable alternative to GNU sed '$a\')
    [ -n "$existing" ] && existing="$existing"$'\n'
else
    existing=""
fi

# 规则定义（按选择分支，1 和默认共享相同规则）
RULES_IGNORE_ALL="# === claude-code-init ===
# Claude Code 开发环境配置（已全部忽略）
.claude/
.pre-commit-config.yaml
CLAUDE.md
SOUL.md
PLAN_Template.md
openspec/
# Backup files（由 copy_template 生成）
*.bak
# === claude-code-init ==="

RULES_PARTIAL="# === claude-code-init ===
# Claude Code 个人本地文件（务必忽略）
.claude/CLAUDE.local.md
.claude/MEMORY.local.md
# Backup files（由 copy_template 生成）
*.bak
# === claude-code-init ==="

case $choice in
    1)
        rules="$RULES_IGNORE_ALL"
        echo_success "已将所有 AI 配置文件加入 .gitignore"
        ;;
    2)
        rules="$RULES_PARTIAL"
        echo_success "已忽略个人偏好文件，其他配置可提交"
        ;;
    3)
        rules="$RULES_PARTIAL"
        echo_success "所有 AI 配置文件提交就绪"
        ;;
    *)
        rules="$RULES_IGNORE_ALL"
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

# 去重 .claude/ 条目（若已在标记块外存在，避免重复）
if [ -f "$GITIGNORE_PATH" ]; then
    TMPFILE=$(mktemp "${GITIGNORE_PATH}.XXXXXX") || TMPFILE="${GITIGNORE_PATH}.tmp"
    awk 'index($0, ".claude/") == 1 {if(!seen++)print; next} {print}' "$GITIGNORE_PATH" > "$TMPFILE" && mv "$TMPFILE" "$GITIGNORE_PATH"
fi
