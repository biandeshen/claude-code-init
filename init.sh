#!/bin/bash
# claude-code-init - Claude Code 开发环境一键初始化 (Unix/macOS)
# 用法: ./init.sh /path/to/your-project
# 版本: v1.5.1 | 2026-04-30

set -euo pipefail

# 启用 nullglob，避免空通配符展开问题
shopt -s nullglob

# 注意：set -e 会在命令失败时退出脚本
# 对于可选步骤（OpenSpec、cc-discipline），使用 || true 来忽略失败

PROJECT_PATH="${1:-.}"
ORIGINAL_PATH="$PROJECT_PATH"  # 保存原始输入用于显示

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

echo_step() { echo -e "${CYAN}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
echo_fail() { echo -e "${RED}[失败]${NC} $1"; }
echo_info() { echo -e "[信息] $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}  Claude Code 开发环境一键初始化 (v1.5.0)${NC}"
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
if ! command -v git >/dev/null 2>&1; then
    echo_fail "未找到 git 命令，请先安装 Git"
    echo -e "  ${YELLOW}下载地址: https://git-scm.com/downloads${NC}"
    exit 1
fi
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

# 4.1 阻断性确认
echo ""
echo -e "${YELLOW}==============================================${NC}"
echo -e "${YELLOW} 重要：以上 ECC 和 Superpowers 插件需要在 Claude Code 中手动安装${NC}"
echo -e "${YELLOW} 如果你已完成安装，请输入 y 继续；否则请输入 n 退出${NC}"
echo -e "${YELLOW}==============================================${NC}"
read -p "是否已完成插件安装？(y/n) " confirm
if [ "$confirm" != "y" ]; then
    echo -e "${RED}请先完成插件安装，再重新运行此脚本。${NC}"
    exit 1
fi
echo_success "已确认插件安装"

# 5. 安装 OpenSpec (SDD) - 自动执行
echo_step "安装 OpenSpec (SDD 工作流)"
if npm install -g @fission-ai/openspec@latest && openspec init; then
    echo_success "OpenSpec 已初始化"
else
    echo_warn "OpenSpec 自动安装失败，请手动执行: npm install -g @fission-ai/openspec@latest && openspec init"
fi

# 6. 安装 cc-discipline (物理防火墙) - 自动执行
echo_step "安装 cc-discipline (物理防火墙 Hooks)"
CC_DISCIPLINE_PATH="$HOME/.cc-discipline"
CC_DISCIPLINE_COMMIT="916da00691128fde44599928d76c129f3d08b8f1"  # 锁定版本 2026-04-26
if [ ! -d "$CC_DISCIPLINE_PATH" ]; then
    echo_info "克隆 cc-discipline 仓库..."
    git clone -b main https://github.com/TechHU-GS/cc-discipline.git "$CC_DISCIPLINE_PATH"
    cd "$CC_DISCIPLINE_PATH"
    git checkout "$CC_DISCIPLINE_COMMIT"
    cd "$PROJECT_PATH"
    echo_success "已克隆 cc-discipline (commit: ${CC_DISCIPLINE_COMMIT:0:7})"
else
    echo_info "cc-discipline 已存在，如需更新请手动执行: git -C $CC_DISCIPLINE_PATH pull"
fi
echo_info "正在执行 cc-discipline 初始化..."
if bash "$CC_DISCIPLINE_PATH/init.sh"; then
    echo_success "cc-discipline 已安装"
else
    echo_warn "cc-discipline 初始化失败，请手动执行: bash $CC_DISCIPLINE_PATH/init.sh"
fi

# 7. 复制 Python 校验脚本
echo_step "复制校验脚本到 .claude/scripts/"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
TARGET_SCRIPTS_DIR="$PROJECT_PATH/.claude/scripts"
# 检查源目录与目标目录是否相同
if [ "$SCRIPTS_DIR" = "$TARGET_SCRIPTS_DIR" ]; then
    echo_info "源目录与目标目录相同，已跳过脚本复制"
elif [ -d "$SCRIPTS_DIR" ] && [ "$(ls -A "$SCRIPTS_DIR" 2>/dev/null)" ]; then
    mkdir -p "$TARGET_SCRIPTS_DIR"
    cp -r "$SCRIPTS_DIR/"* "$TARGET_SCRIPTS_DIR/"
    find "$TARGET_SCRIPTS_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    echo_success "已复制校验脚本到 .claude/scripts/"
else
    echo_info "scripts 目录为空或不存在，跳过"
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

# 检查 Python 是否可用
if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    PYTHON_CMD=$(command -v python3 || command -v python)
    # 检查 pre-commit 是否已安装
    $PYTHON_CMD -c "import pre_commit" 2>/dev/null || {
        echo_info "正在安装 pre-commit..."
        $PYTHON_CMD -m pip install --quiet pre-commit 2>/dev/null && echo_success "pre-commit 安装完成"
    }
    if command -v pre-commit >/dev/null 2>&1; then
        pre-commit install
        echo_success "Pre-commit Hooks 已安装"
    else
        echo_warn "pre-commit install 失败，请手动执行: pre-commit install"
    fi
else
    echo_warn "未找到 Python，无法自动安装 pre-commit"
    echo -e "  ${YELLOW}手动安装: pip install pre-commit${NC}"
    echo -e "  ${YELLOW}手动安装 hooks: pre-commit install${NC}"
fi

# 10. 复制覆盖层模板
echo_step "复制覆盖层模板"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
if [ -d "$TEMPLATE_DIR" ]; then
    # 复制 CLAUDE.md
    if [ -f "$TEMPLATE_DIR/CLAUDE_Template.md" ]; then
        if [ -f "$PROJECT_PATH/CLAUDE.md" ]; then
            echo_warn "CLAUDE.md 已存在，跳过以避免覆盖已有配置"
        else
            cp "$TEMPLATE_DIR/CLAUDE_Template.md" "$PROJECT_PATH/CLAUDE.md"
            echo_success "已复制 CLAUDE.md"
        fi
    fi

    # 复制 SOUL.md
    if [ -f "$TEMPLATE_DIR/SOUL_Template.md" ]; then
        if [ -f "$PROJECT_PATH/SOUL.md" ]; then
            echo_warn "SOUL.md 已存在，跳过以避免覆盖已有配置"
        else
            cp "$TEMPLATE_DIR/SOUL_Template.md" "$PROJECT_PATH/SOUL.md"
            echo_success "已复制 SOUL.md"
        fi
    fi

    # 复制 PLAN_TEMPLATE.md
    if [ -f "$TEMPLATE_DIR/PLAN_Template.md" ]; then
        if [ -f "$PROJECT_PATH/PLAN_TEMPLATE.md" ]; then
            echo_warn "PLAN_TEMPLATE.md 已存在，跳过以避免覆盖已有配置"
        else
            cp "$TEMPLATE_DIR/PLAN_Template.md" "$PROJECT_PATH/PLAN_TEMPLATE.md"
            echo_success "已复制 PLAN_TEMPLATE.md"
        fi
    fi

    # 复制 SPEC_Template.md
    if [ -f "$TEMPLATE_DIR/SPEC_Template.md" ] && [ ! -f "$PROJECT_PATH/SPEC_Template.md" ]; then
        cp "$TEMPLATE_DIR/SPEC_Template.md" "$PROJECT_PATH/SPEC_Template.md"
        echo_success "已复制 SPEC_Template.md"
    fi

    # 复制 ROUTINE_Template.md
    if [ -f "$TEMPLATE_DIR/ROUTINE_Template.md" ] && [ ! -f "$PROJECT_PATH/ROUTINE_Template.md" ]; then
        cp "$TEMPLATE_DIR/ROUTINE_Template.md" "$PROJECT_PATH/ROUTINE_Template.md"
        echo_success "已复制 ROUTINE_Template.md"
    fi
else
    echo_warn "模板目录不存在，跳过模板复制"
fi

# 10.1 模板版本检查
echo_step "检查模板版本"
check_template_version() {
    _src="$1"
    _target="$2"
    if [ -f "$_src" ] && [ -f "$_target" ]; then
        _src_ver=$(grep -m1 "模板版本：" "$_src" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        _target_ver=$(grep -m1 "模板版本：" "$_target" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$_src_ver" ] && [ -n "$_target_ver" ] && [ "$_src_ver" != "$_target_ver" ]; then
            _name=$(basename "$_target")
            echo_warn "   $_name: 源版本 $_src_ver / 目标版本 $_target_ver — 建议手动合并更新"
        fi
    fi
}
check_template_version "$TEMPLATE_DIR/CLAUDE_Template.md" "$PROJECT_PATH/CLAUDE.md"
check_template_version "$TEMPLATE_DIR/SOUL_Template.md" "$PROJECT_PATH/SOUL.md"
check_template_version "$TEMPLATE_DIR/PLAN_Template.md" "$PROJECT_PATH/PLAN_TEMPLATE.md"
check_template_version "$TEMPLATE_DIR/SPEC_Template.md" "$PROJECT_PATH/SPEC_Template.md"
check_template_version "$TEMPLATE_DIR/ROUTINE_Template.md" "$PROJECT_PATH/ROUTINE_Template.md"
echo_success "模板版本检查完成"

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

# 11.1 复制 Skills
echo_step "复制 Skills"
SKILLS_DIR="$SCRIPT_DIR/.claude/skills"
TARGET_SKILLS_DIR="$PROJECT_PATH/.claude/skills"
if [ -d "$SKILLS_DIR" ]; then
    mkdir -p "$TARGET_SKILLS_DIR"
    cp -r "$SKILLS_DIR/"* "$TARGET_SKILLS_DIR/"
    echo_success "已复制 Skills 到 .claude/skills/"
else
    echo_info "Skills 目录不存在，跳过"
fi

# 11.2 复制 Hooks 和 settings.json
echo_step "复制 Hooks 和设置"
HOOKS_SOURCE_DIR="$SCRIPT_DIR/.claude/hooks"
HOOKS_TARGET_DIR="$PROJECT_PATH/.claude/hooks"
SETTINGS_SOURCE="$SCRIPT_DIR/.claude/settings.json"
SETTINGS_TARGET="$PROJECT_PATH/.claude/settings.json"
if [ -d "$HOOKS_SOURCE_DIR" ]; then
    mkdir -p "$HOOKS_TARGET_DIR"
    cp -r "$HOOKS_SOURCE_DIR/"* "$HOOKS_TARGET_DIR/"
    echo_success "已复制 Hooks 到 .claude/hooks/"
fi
if [ -f "$SETTINGS_SOURCE" ]; then
    if [ -f "$SETTINGS_TARGET" ]; then
        echo_warn ".claude/settings.json 已存在，如需合并 Hook 配置请手动处理"
    else
        cp "$SETTINGS_SOURCE" "$SETTINGS_TARGET"
        echo_success "已复制 settings.json 到 .claude/"
    fi
fi

# 12. 创建本地偏好文件 (gitignored)
echo_step "创建 CLAUDE.local.md (本地偏好)"
mkdir -p "$PROJECT_PATH/.claude"
cat > "$PROJECT_PATH/.claude/CLAUDE.local.md" << EOF
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
echo_success "已创建 CLAUDE.local.md (.claude/)"

# 13. 处理 .gitignore（调用独立脚本）
echo ""
echo_step "处理 AI 开发配置文件"

# 优先使用 PowerShell 脚本
if command -v pwsh >/dev/null 2>&1 || command -v powershell >/dev/null 2>&1; then
    CONFIGURE_SCRIPT="$SCRIPT_DIR/scripts/configure-gitignore.ps1"
    if [ -f "$CONFIGURE_SCRIPT" ]; then
        if command -v pwsh >/dev/null 2>&1; then
            pwsh -NoProfile -ExecutionPolicy Bypass -File "$CONFIGURE_SCRIPT" -ProjectPath "$PROJECT_PATH"
        else
            powershell -NoProfile -ExecutionPolicy Bypass -File "$CONFIGURE_SCRIPT" -ProjectPath "$PROJECT_PATH"
        fi
    fi
# 回退到 Bash 脚本
elif [ -f "$SCRIPT_DIR/scripts/configure-gitignore.sh" ]; then
    bash "$SCRIPT_DIR/scripts/configure-gitignore.sh" "$PROJECT_PATH"
else
    echo_warn "未找到配置脚本，跳过 .gitignore 配置"
fi

# 14. 配置 gstack 命令
echo_step "配置 gstack 角色命令"
GSTACK_COMMANDS="team.md messages.md qa.md plan-ceo-review.md overnight.md overnight-report.md capabilities.md status.md"
TARGET_COMMANDS_DIR="$PROJECT_PATH/.claude/commands"
for cmd in $GSTACK_COMMANDS; do
    src="$SCRIPT_DIR/commands/$cmd"
    if [ -f "$src" ]; then
        mkdir -p "$TARGET_COMMANDS_DIR"
        cp "$src" "$TARGET_COMMANDS_DIR/" 2>/dev/null || true
        echo_info "已复制 $cmd"
    fi
done

echo ""
echo -e "${YELLOW}无人值守功能已配置。${NC}"
echo -e "  ${GRAY}- tmux-session.sh: 启动无人值守会话${NC}"
echo -e "  ${GRAY}- ralph-setup.sh: 安装 Ralph Wiggum 插件${NC}"
echo -e "  ${GRAY}- /team: 启动 Agent 团队${NC}"
echo -e "  ${GRAY}- /qa: 质量保证测试${NC}"
echo -e "  ${GRAY}- trigger-optimizer.sh: 分析 Skills 触发优化建议${NC}"
echo -e "  ${GRAY}- weekly-report.sh: 生成本周使用报告${NC}"

# 15. 运行环境检查
echo ""
echo_step "运行环境完整性检查"
if [ -f "$SCRIPT_DIR/scripts/check-env.sh" ]; then
    echo_info "环境检查脚本已复制到项目"
fi

# 完成
echo ""
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}  Claude Code 开发环境初始化完成！${NC}"
echo -e "${GREEN}==============================================${NC}"
echo ""
echo -e "${CYAN}你现在拥有：${NC}"
echo -e "  ${GREEN}✅${NC} 11 个可自动触发的 Skills（审查/提交/TDD/调试/重构/修复/解释/校验/头脑风暴/路由/无人值守路由）"
echo -e "  ${GREEN}✅${NC} 10+ 个自定义命令（/review /commit /architect /fix /refactor /explain /validate /help /team /qa /capabilities /status）"
echo -e "  ${GREEN}✅${NC} 场景感知 Hook（编辑测试文件→推荐TDD，编辑安全文件→推荐审查，夜间→推荐无人值守）"
echo -e "  ${GREEN}✅${NC} 6 个项目完整性校验脚本"
echo -e "  ${GREEN}✅${NC} Pre-commit 自动检查（9 个检查项）"
echo -e "  ${GREEN}✅${NC} 无人值守长任务环境（tmux + Ralph Wiggum 循环）"
echo -e "  ${GREEN}✅${NC} Agent Teams 并行开发/审查（/team）"
echo -e "  ${GREEN}✅${NC} gstack 角色体系（CEO审查/架构审查/QA测试/一键发布）"
echo -e "  ${GREEN}✅${NC} Skills 触发优化工具（trigger-optimizer.sh）"
echo -e "  ${GREEN}✅${NC} 周报生成工具（weekly-report.sh）"
echo ""
echo -e "${YELLOW}下一步：${NC}"
echo "  1. 编辑 CLAUDE.md 写入项目特有的架构规则"
echo "  2. 编辑 SOUL.md 定义此项目的 AI 人格"
echo "  3. 启动 Claude Code，开始开发"
echo "  4. 输入 /help 查看完整使用指南"
echo "  5. 输入 /status 查看项目状态仪表盘"
echo "  6. 输入 /capabilities 按场景查看全部能力"
echo ""

# 16. 全局偏好设置引导（跨所有项目生效）
echo -e "${YELLOW}[建议] 设置全局偏好（跨所有项目生效）：${NC}"
GLOBAL_CLAUDE="$HOME/.claude/CLAUDE.md"
echo -e "  ${GRAY}将你的通用编码偏好写入 $GLOBAL_CLAUDE${NC}"
echo -e "  ${GRAY}例如：${NC}"
echo -e "  ${GRAY}- 所有函数必须有类型标注${NC}"
echo -e "  ${GRAY}- 偏好 Python 3.12+ 语法${NC}"
echo -e "  ${GRAY}- 注释使用中文${NC}"
echo ""

echo -e "如需更新规范，运行:"
echo -e "  git -C \"$SCRIPT_DIR\" pull"
echo ""
