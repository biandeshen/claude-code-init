#!/bin/bash
# scripts/ralph-setup.sh
# Ralph Wiggum 安装脚本 - Claude Code 无人值守循环插件
# 功能：
#   - 安装 Ralph Wiggum 插件
#   - 可选：安装 tmux-orche 作为备选方案
# 用法：
#   bash scripts/ralph-setup.sh          # 仅安装 Ralph
#   bash scripts/ralph-setup.sh --full  # 安装全部依赖

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo_step() { echo -e "${CYAN}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
echo_fail() { echo -e "${RED}[失败]${NC} $1"; }

RALPH_REPO="https://github.com/snarktank/ralph.git"
RALPH_DIR="$HOME/.claude/skills/ralph"
INSTALL_MODE="${1:-ralph}"

# 检查 Claude Code 是否安装
check_claude() {
    if ! command -v claude &> /dev/null; then
        echo_fail "Claude Code 未安装。请先安装 Claude Code。"
        exit 1
    fi
    echo_success "Claude Code 已安装: $(claude --version 2>/dev/null | head -1)"
}

# 安装 jq（Ralph 依赖）
install_jq() {
    if command -v jq &> /dev/null; then
        echo_success "jq 已安装"
        return
    fi

    echo_step "安装 jq..."
    if command -v brew &> /dev/null; then
        brew install jq
    elif command -v apt &> /dev/null; then
        sudo apt install jq -y
    elif command -v yum &> /dev/null; then
        sudo yum install jq -y
    else
        echo_warn "无法自动安装 jq，请手动安装: https://stedolan.github.io/jq/download/"
        return 1
    fi
    echo_success "jq 安装完成"
}

# 安装 Ralph Wiggum
install_ralph() {
    echo_step "安装 Ralph Wiggum..."

    if [ -d "$RALPH_DIR" ]; then
        echo_warn "Ralph 已存在于 $RALPH_DIR"
        read -p "是否更新？(y/n) " update
        if [ "$update" = "y" ]; then
            cd "$RALPH_DIR"
            git pull
            cd - > /dev/null
            echo_success "Ralph 已更新"
        fi
    else
        git clone "$RALPH_REPO" "$RALPH_DIR"
        echo_success "Ralph 已克隆到 $RALPH_DIR"
    fi

    # 复制 CLAUDE.md 到项目（可选）
    if [ -d ".claude" ]; then
        cp "$RALPH_DIR/CLAUDE.md" .claude/
        echo_success "CLAUDE.md 已复制到项目"
    fi
}

# 安装 tmux-orche（备选方案）
install_tmux_orche() {
    echo_step "安装 tmux-orche（备选方案）..."

    if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
        pip install tmux-orche 2>/dev/null || pip3 install tmux-orche 2>/dev/null
        echo_success "tmux-orche 安装完成"
    else
        echo_warn "pip 未安装，跳过 tmux-orche"
        return 1
    fi
}

# 验证安装
verify_installation() {
    echo_step "验证安装..."

    if command -v claude &> /dev/null; then
        # 检查 /ralph-loop 是否可用
        if claude --help 2>&1 | grep -qi "ralph"; then
            echo_success "Ralph Wiggum 插件可用"
        else
            echo_warn "Ralph Wiggum 插件可能需要手动加载"
            echo "在 Claude Code 中运行: /plugin marketplace add snarktank/ralph"
        fi
    fi

    if command -v jq &> /dev/null; then
        echo_success "jq 验证: $(jq --version)"
    fi
}

# 主流程
main() {
    echo ""
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${CYAN}  Ralph Wiggum 安装脚本${NC}"
    echo -e "${CYAN}==============================================${NC}"
    echo ""

    check_claude

    if [ "$INSTALL_MODE" = "--full" ]; then
        install_jq
        install_ralph
        install_tmux_orche
    else
        install_jq
        install_ralph
    fi

    verify_installation

    echo ""
    echo_success "安装完成！"
    echo ""
    echo -e "${CYAN}使用方式：${NC}"
    echo "  在 Claude Code 中运行:"
    echo "    /ralph-loop \"你的任务描述\" --max-iterations 50"
    echo ""
    echo "  或使用 tmux 脚本:"
    echo "    bash scripts/tmux-session.sh scripts/PROMPT.md"
    echo ""
}

main "$@"
