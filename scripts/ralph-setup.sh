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

# 加载公共库（颜色输出 + 工具函数）
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$_SCRIPT_DIR/lib/common.sh" ]; then
    source "$_SCRIPT_DIR/lib/common.sh"
fi

RALPH_REPO="https://github.com/snarktank/ralph.git"
RALPH_DIR="$HOME/.claude/skills/ralph"
RALPH_COMMIT=""  # 留空则自动锁定 main 分支最新 commit（供应链安全：固定提交哈希）
INSTALL_MODE="${1:-ralph}"

# 检查 Claude Code 是否安装
check_claude() {
    if ! command -v claude >/dev/null 2>&1; then
        echo_fail "Claude Code 未安装。请先安装 Claude Code。"
        exit 1
    fi
    echo_success "Claude Code 已安装: $(claude --version 2>/dev/null | head -1)"
}

# 安装 jq（Ralph 依赖）
install_jq() {
    if command -v jq >/dev/null 2>&1; then
        echo_success "jq 已安装"
        return
    fi

    echo_step "安装 jq..."
    if command -v brew >/dev/null 2>&1; then
        brew install jq
    elif command -v apt >/dev/null 2>&1; then
        sudo apt install jq -y
    elif command -v yum >/dev/null 2>&1; then
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

    # 供应链安全：自动锁定 main 分支最新 commit
    if [ -z "$RALPH_COMMIT" ]; then
        RALPH_COMMIT=$(git ls-remote "$RALPH_REPO" refs/heads/main 2>/dev/null | cut -f1)
        if [ -z "$RALPH_COMMIT" ]; then
            echo_fail "无法获取 ralph 仓库最新 commit hash，请检查网络连接"
            return 1
        fi
        echo_info "已锁定 ralph 版本: ${RALPH_COMMIT:0:8}"
    fi

    if [ -d "$RALPH_DIR" ]; then
        echo_warn "Ralph 已存在于 $RALPH_DIR"
        # 检查已安装版本与锁定版本是否一致
        local installed_commit=""
        if [ -d "$RALPH_DIR/.git" ]; then
            installed_commit=$(cd "$RALPH_DIR" && git rev-parse HEAD 2>/dev/null)
        fi
        if [ "$installed_commit" = "$RALPH_COMMIT" ]; then
            echo_success "Ralph 版本与锁定版本一致 (${RALPH_COMMIT:0:8})"
            return 0
        fi
        read -p "已安装版本 (${installed_commit:0:8}) 与锁定版本 (${RALPH_COMMIT:0:8}) 不一致，是否更新？(y/n) " update
        if [ "$update" = "y" ]; then
            cd "$RALPH_DIR"
            git fetch origin main
            git checkout "$RALPH_COMMIT"
            cd - > /dev/null
            echo_success "Ralph 已更新至 ${RALPH_COMMIT:0:8}"
        fi
    else
        # 先 clone，再 checkout 到锁定 commit
        git clone --filter=blob:none "$RALPH_REPO" "$RALPH_DIR"
        cd "$RALPH_DIR"
        git checkout "$RALPH_COMMIT"
        cd - > /dev/null
        echo_success "Ralph 已安装 (版本: ${RALPH_COMMIT:0:8})"
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

    if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
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

    if command -v claude >/dev/null 2>&1; then
        # 检查 /ralph-loop 是否可用
        if claude --help 2>&1 | grep -qi "ralph"; then
            echo_success "Ralph Wiggum 插件可用"
        else
            echo_warn "Ralph Wiggum 插件可能需要手动加载"
            echo "在 Claude Code 中运行: /plugin marketplace add snarktank/ralph"
        fi
    fi

    if command -v jq >/dev/null 2>&1; then
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
    echo "    bash .claude/scripts/tmux-session.sh .claude/scripts/PROMPT.md"
    echo ""
}

main "$@"
