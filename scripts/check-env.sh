#!/bin/bash
# scripts/check-env.sh
# Claude Code 开发环境完整性检查
# 注意：此脚本是自包含的，不依赖 lib/common.sh（部署后无此依赖）

# ─── 颜色输出（自包含，不依赖 common.sh） ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# 注意：此脚本被部署到 .claude/scripts/ 后无 common.sh 依赖
# 因此这些输出函数是必要的重复（自包含设计）
echo_step() { echo -e "${CYAN}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
echo_fail() { echo -e "${RED}[失败]${NC} $1"; }
echo_info() { echo -e "[信息] $1"; }

echo -e "${CYAN}=== Claude Code 开发环境检查 ===${NC}"
echo ""

CHECK_OK="${GREEN}✅${NC}"
CHECK_FAIL="${RED}❌${NC}"
CHECK_WARN="${YELLOW}⚠️${NC}"

# 1. Claude Code 版本
echo "--- Claude Code ---"
if command -v claude >/dev/null 2>&1; then
    claude_version=$(claude --version 2>&1 | head -1)
    echo -e "$CHECK_OK Claude Code: $claude_version"

    # 检查版本是否 >= 2.0
    version_num=$(echo "$claude_version" | sed -n 's/[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' | head -1)
    if [ -n "$version_num" ]; then
        major=$(echo "$version_num" | cut -d. -f1)
        if [ "$major" -ge 2 ]; then
            echo -e "  版本要求: ${GREEN}满足${NC} (>= 2.0)"
        else
            echo -e "  版本要求: ${RED}不满足${NC} (需要 >= 2.0)"
        fi
    fi
else
    echo -e "$CHECK_FAIL Claude Code 未安装"
    echo "  安装: https://docs.anthropic.com/en/docs/claude-code/getting-started"
fi

# 2. 全局插件
echo ""
echo "--- 全局插件 ---"
if [ -d "$HOME/.claude/plugins/everything-claude-code" ]; then
    echo -e "$CHECK_OK ECC (Everything Claude Code)"
else
    echo -e "$CHECK_FAIL ECC 未安装"
    echo "  在 Claude Code 中运行: /plugin install everything-claude-code@everything-claude-code"
fi

if [ -d "$HOME/.claude/plugins/superpowers" ]; then
    echo -e "$CHECK_OK Superpowers"
else
    echo -e "$CHECK_FAIL Superpowers 未安装"
    echo "  在 Claude Code 中运行: /plugin install superpowers@superpowers-marketplace"
fi

# 3. Python
echo ""
echo "--- Python ---"
if command -v python3 >/dev/null 2>&1; then
    python_version=$(python3 --version 2>&1)
    echo -e "$CHECK_OK $python_version"
elif command -v python >/dev/null 2>&1; then
    python_version=$(python --version 2>&1)
    echo -e "$CHECK_OK $python_version (python3 不可用，回退到 python)"
else
    echo -e "$CHECK_FAIL Python 未安装"
    echo "  安装: https://www.python.org/downloads/"
fi

# 版本检查（兼容 python3 和 python 两种名称）
PYTHON_BIN=""
command -v python3 >/dev/null 2>&1 && PYTHON_BIN="python3" || PYTHON_BIN="python"
if [ -n "$PYTHON_BIN" ] && command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    py_ver=$("$PYTHON_BIN" --version 2>&1)
    version_num=$(echo "$py_ver" | sed -n 's/[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' | head -1)
    major=$(echo "$version_num" | cut -d. -f1)
    minor=$(echo "$version_num" | cut -d. -f2)
    if [ "$major" -gt 3 ] || ([ "$major" -eq 3 ] && [ "$minor" -ge 8 ]); then
        echo "  版本要求: ${GREEN}满足${NC} (>= 3.8)"
    else
        echo "  版本要求: ${YELLOW}建议升级${NC} (推荐 >= 3.10)"
    fi
fi

# 4. Node.js
echo ""
echo "--- Node.js ---"
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version 2>&1)
    echo -e "$CHECK_OK Node.js: $node_version"

    version_num=$(echo "$node_version" | sed -n 's/[^0-9]*\([0-9][0-9]*\).*/\1/p' | head -1)
    if [ "$version_num" -ge 16 ]; then
        echo -e "  版本要求: ${GREEN}满足${NC} (>= 16)"
    else
        echo -e "  版本要求: ${RED}不满足${NC} (需要 >= 16)"
    fi
else
    echo -e "$CHECK_FAIL Node.js 未安装"
    echo "  安装: https://nodejs.org/"
fi

# 5. Git
echo ""
echo "--- Git ---"
if command -v git >/dev/null 2>&1; then
    git_version=$(git --version 2>&1)
    echo -e "$CHECK_OK $git_version"
else
    echo -e "$CHECK_FAIL Git 未安装"
    echo "  安装: https://git-scm.com/"
fi

# 6. Pre-commit
echo ""
echo "--- Pre-commit ---"
if command -v pre-commit >/dev/null 2>&1; then
    echo -e "$CHECK_OK pre-commit 已安装"
else
    echo -e "$CHECK_WARN pre-commit 未安装"
    echo "  可选安装: pip install pre-commit"
fi

# 7. tmux (Unix/macOS)
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" ]]; then
    echo ""
    echo "--- tmux ---"
    if command -v tmux >/dev/null 2>&1; then
        tmux_version=$(tmux -V 2>&1)
        echo -e "$CHECK_OK $tmux_version"
    else
        echo -e "$CHECK_WARN tmux 未安装（无人值守需要）"
        echo "  macOS: brew install tmux"
        echo "  Linux: apt install tmux"
    fi
fi

# 总结
echo ""
echo "=== 检查完成 ==="
echo ""
echo "如有问题，查看完整文档: docs/TROUBLESHOOTING.md"
