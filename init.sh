#!/bin/bash
# claude-code-init - Claude Code 开发环境一键初始化 (Unix/macOS)
# 用法: ./init.sh /path/to/your-project
# 版本: v1.0.0 | 2026-04-28

set -e

PROJECT_PATH="${1:-.}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo_step() { echo -e "${CYAN}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
echo_fail() { echo -e "${RED}[失败]${NC} $1"; }
echo_info() { echo -e "[信息] $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}  Claude Code 开发环境一键初始化 (v1.0.0)${NC}"
echo -e "${CYAN}==============================================${NC}"
echo ""

# 1. 确认目标目录
echo_step "确认目标目录: $PROJECT_PATH"
if [ ! -d "$PROJECT_PATH" ]; then
    mkdir -p "$PROJECT_PATH"
    echo_success "已创建目录"
fi
cd "$PROJECT_PATH"
PROJECT_PATH="$(pwd)"

# 2. 初始化 Git
if [ ! -d ".git" ]; then
    echo_step "初始化 Git 仓库"
    git init
    echo_success "Git 仓库已初始化"
else
    echo_info "Git 仓库已存在，跳过"
fi

# 3. 安装 ECC (Everything Claude Code)
echo_step "安装 Everything Claude Code (ECC)"
echo_info "请在 Claude Code 中执行以下命令:"
echo -e "  ${YELLOW}/plugin marketplace add affaan-m/everything-claude-code${NC}"
echo -e "  ${YELLOW}/plugin install everything-claude-code@everything-claude-code${NC}"
echo_info "选择 'Install for you (user scope)'"

# 4. 安装 Superpowers
echo_step "安装 Superpowers"
echo_info "请在 Claude Code 中执行以下命令:"
echo -e "  ${YELLOW}/plugin marketplace add obra/superpowers-marketplace${NC}"
echo -e "  ${YELLOW}/plugin install superpowers@superpowers-marketplace${NC}"

# 5. 安装 OpenSpec (SDD)
echo_step "安装 OpenSpec (SDD 工作流)"
echo_info "请在终端执行:"
echo -e "  ${YELLOW}npx kld-sdd${NC}"

# 6. 安装 cc-discipline (物理防火墙)
echo_step "安装 cc-discipline (物理防火墙 Hooks)"
CC_DISCIPLINE_PATH="$HOME/.cc-discipline"
if [ ! -d "$CC_DISCIPLINE_PATH" ]; then
    echo_info "克隆 cc-discipline 仓库..."
    git clone https://github.com/TechHU-GS/cc-discipline.git "$CC_DISCIPLINE_PATH"
fi
echo_info "请在项目目录执行:"
echo -e "  ${YELLOW}bash $CC_DISCIPLINE_PATH/init.sh${NC}"

# 7. 复制 Python 校验脚本
echo_step "复制校验脚本到 scripts/"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
TARGET_SCRIPTS_DIR="$PROJECT_PATH/scripts"
if [ -d "$SCRIPTS_DIR" ]; then
    mkdir -p "$TARGET_SCRIPTS_DIR"
    cp -r "$SCRIPTS_DIR/"* "$TARGET_SCRIPTS_DIR/"
    echo_success "已复制校验脚本到 scripts/"
else
    echo_info "scripts 目录不存在，跳过"
fi

# 8. 复制 Pre-commit 配置
echo_step "复制 Pre-commit 配置"
PRECOMMIT_CONFIG="$SCRIPT_DIR/configs/.pre-commit-config.yaml"
TARGET_PRECOMMIT_CONFIG="$PROJECT_PATH/.pre-commit-config.yaml"
if [ -f "$PRECOMMIT_CONFIG" ]; then
    cp "$PRECOMMIT_CONFIG" "$TARGET_PRECOMMIT_CONFIG"
    echo_success "已复制 .pre-commit-config.yaml"
else
    echo_info "Pre-commit 配置不存在，跳过"
fi

# 9. 安装 Pre-commit hooks
echo_step "安装 Pre-commit Hooks"
if command -v pre-commit &> /dev/null; then
    pre-commit install
    echo_success "Pre-commit Hooks 已安装"
else
    echo_warn "Pre-commit 未安装，显示安装说明:"
    echo -e "  ${YELLOW}pip install pre-commit${NC}"
    echo -e "  ${YELLOW}pre-commit install${NC}"
fi

# 10. 复制覆盖层模板
echo_step "复制覆盖层模板"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
if [ -d "$TEMPLATE_DIR" ]; then
    # 复制 CLAUDE.md
    if [ -f "$TEMPLATE_DIR/CLAUDE_Template.md" ]; then
        cp "$TEMPLATE_DIR/CLAUDE_Template.md" "$PROJECT_PATH/CLAUDE.md"
        echo_success "已复制 CLAUDE.md"
    fi

    # 复制 SOUL.md
    if [ -f "$TEMPLATE_DIR/SOUL_Template.md" ]; then
        cp "$TEMPLATE_DIR/SOUL_Template.md" "$PROJECT_PATH/SOUL.md"
        echo_success "已复制 SOUL.md"
    fi

    # 复制 PLAN_TEMPLATE.md
    if [ -f "$TEMPLATE_DIR/PLAN_Template.md" ]; then
        cp "$TEMPLATE_DIR/PLAN_Template.md" "$PROJECT_PATH/PLAN_TEMPLATE.md"
        echo_success "已复制 PLAN_TEMPLATE.md"
    fi
else
    echo_warn "模板目录不存在，跳过模板复制"
fi

# 11. 复制自定义命令
echo_step "复制自定义命令"
COMMANDS_DIR="$SCRIPT_DIR/commands"
TARGET_COMMANDS_DIR="$PROJECT_PATH/.claude/commands"
if [ -d "$COMMANDS_DIR" ]; then
    mkdir -p "$TARGET_COMMANDS_DIR"
    cp -r "$COMMANDS_DIR/"* "$TARGET_COMMANDS_DIR/"
    echo_success "已复制自定义命令到 .claude/commands/"
else
    echo_info "命令目录不存在，跳过"
fi

# 12. 创建本地偏好文件 (gitignored)
echo_step "创建 CLAUDE.local.md (本地偏好)"
cat > "$PROJECT_PATH/CLAUDE.local.md" << 'EOF'
# 本地个人偏好
# 此文件会被 .gitignore 忽略，不会提交到仓库

> 由 claude-code-init 自动生成
> 版本: v1.0.0 | $(date +%Y-%m-%d)

---

## 个人偏好设置

- 开始编码前先解释 Plan
- 所有异步函数必须有 timeout
- 复杂任务先创建 Plan.md

---
EOF
echo_success "已创建 CLAUDE.local.md"

# 13. 更新 .gitignore
echo_step "更新 .gitignore"
if [ ! -f "$PROJECT_PATH/.gitignore" ]; then
    echo "CLAUDE.local.md" > "$PROJECT_PATH/.gitignore"
else
    if ! grep -q "CLAUDE.local.md" "$PROJECT_PATH/.gitignore"; then
        echo "" >> "$PROJECT_PATH/.gitignore"
        echo "# Claude Code 本地偏好" >> "$PROJECT_PATH/.gitignore"
        echo "CLAUDE.local.md" >> "$PROJECT_PATH/.gitignore"
    fi
fi
echo_success "已更新 .gitignore"

# 完成
echo ""
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}  初始化完成！${NC}"
echo -e "${GREEN}==============================================${NC}"
echo ""
echo -e "位置: ${PROJECT_PATH}"
echo ""
echo -e "${CYAN}下一步:${NC}"
echo "  1. 编辑 CLAUDE.md 写入项目特定的架构规则"
echo "  2. 编辑 SOUL.md 定义项目的 AI 人格"
echo "  3. 启动 Claude Code，开始开发"
echo ""
echo -e "如需更新规范，运行:"
echo -e "  git -C \"$SCRIPT_DIR\" pull"
echo ""
