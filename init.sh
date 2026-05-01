#!/bin/bash
# claude-code-init - Claude Code 开发环境一键初始化 (Unix/macOS)
# 用法: ./init.sh /path/to/your-project
# 版本: v1.6.0 | 2026-05-01

set -euo pipefail

# 启用 nullglob，避免空通配符展开问题
shopt -s nullglob

# 注意：set -e 会在命令失败时退出脚本
# 对于可选步骤（OpenSpec、cc-discipline），使用 || true 来忽略失败

PROJECT_PATH="${1:-.}"
ORIGINAL_PATH="$PROJECT_PATH"  # 保存原始输入用于显示
FORCE_OVERWRITE=false
SKIP_ECC=false
SKIP_SUPERPOWERS=false
SKIP_OPENSPEC=false
SKIP_CCDISCIPLINE=false

# 解析参数
shift 2>/dev/null || true
for arg in "$@"; do
    case "$arg" in
        --force) FORCE_OVERWRITE=true ;;
        --skip-ecc) SKIP_ECC=true ;;
        --skip-superpowers) SKIP_SUPERPOWERS=true ;;
        --skip-openspec) SKIP_OPENSPEC=true ;;
        --skip-ccdiscipline) SKIP_CCDISCIPLINE=true ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载公共库（颜色输出 + 工具函数）
if [ -f "$SCRIPT_DIR/scripts/lib/common.sh" ]; then
    source "$SCRIPT_DIR/scripts/lib/common.sh"
else
    # 如果找不到 common.sh，使用内联定义作为后备
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    GRAY='\033[0;90m'
    NC='\033[0m'
fi

# ─── 错误清理机制 ───
# 在脚本中途失败时清理已创建的目标目录结构
CLEANUP_NEEDED=false
INIT_COMPLETED=false

cleanup() {
    if [ "$INIT_COMPLETED" = false ] && [ "$CLEANUP_NEEDED" = true ]; then
        echo ""
        echo -e "${YELLOW}⚠️  初始化未完成，正在清理...${NC}"
        if [ -d "$PROJECT_PATH/.claude" ]; then
            rm -rf "$PROJECT_PATH/.claude"
        fi
        echo -e "${YELLOW}已清理 ${PROJECT_PATH}/.claude${NC}"
    fi
}
trap cleanup EXIT INT TERM

echo_step() { echo -e "${CYAN}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
echo_fail() { echo -e "${RED}[失败]${NC} $1"; }
echo_info() { echo -e "[信息] $1"; }

echo ""
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}  Claude Code 开发环境一键初始化 (v1.6.0)${NC}"
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

# Git 初始化成功后，标记需要清理（脚本中途退出时清理）
CLEANUP_NEEDED=true

# 3. 安装核心 Claude Code 插件 (ECC + Superpowers)
if [ "$SKIP_ECC" = true ] && [ "$SKIP_SUPERPOWERS" = true ]; then
    echo_info "跳过插件安装 (--skip-ecc --skip-superpowers)"
else
    echo_step "安装核心 Claude Code 插件"
    if [ "$SKIP_ECC" != true ]; then
        echo_info "  ECC — 请在 Claude Code 中执行:"
        echo -e "    ${YELLOW}/plugin marketplace add affaan-m/everything-claude-code${NC}"
        echo -e "    ${YELLOW}/plugin install everything-claude-code@everything-claude-code${NC}"
        echo_info "  选择 'Install for you (user scope)'"
    fi
    if [ "$SKIP_SUPERPOWERS" != true ]; then
        echo_info "  Superpowers — 请在 Claude Code 中执行:"
        echo -e "    ${YELLOW}/plugin marketplace add obra/superpowers-marketplace${NC}"
        echo -e "    ${YELLOW}/plugin install superpowers@superpowers-marketplace${NC}"
    fi
fi

# 3.1 插件确认 (--force 模式下跳过交互)
if [ "$SKIP_ECC" != true ] || [ "$SKIP_SUPERPOWERS" != true ]; then
    echo ""
    echo -e "${YELLOW}==============================================${NC}"
    echo -e "${YELLOW} 重要：以上插件需要在 Claude Code 中手动安装${NC}"
    echo -e "${YELLOW}==============================================${NC}"
    if [ "$FORCE_OVERWRITE" = true ]; then
        echo_info "跳过插件确认 (--force 模式)"
    else
        echo -e "${YELLOW} 如果你已完成安装，请输入 y 继续；否则请输入 n 退出${NC}"
        read -p "是否已完成插件安装？(y/n) " confirm
        if [ "$confirm" != "y" ]; then
            echo -e "${RED}请先完成插件安装，再重新运行此脚本。${NC}"
            exit 1
        fi
    fi
    echo_success "已确认插件安装"
else
    echo_info "所有插件均已跳过，无需确认"
fi

# 4. 安装 OpenSpec (SDD) - 自动执行
if [ "$SKIP_OPENSPEC" = true ]; then
    echo_info "跳过 OpenSpec 安装 (--skip-openspec)"
else
    echo_step "安装 OpenSpec (SDD 工作流)"
    if npm install -g @fission-ai/openspec@1.3.1 && openspec init --tools claude; then
        echo_success "OpenSpec 已初始化"
    else
        echo_warn "OpenSpec 自动安装失败，请手动执行: npm install -g @fission-ai/openspec@1.3.1 && openspec init --tools claude"
    fi
fi

# 5. 安装 cc-discipline (物理防火墙) - 自动执行
if [ "$SKIP_CCDISCIPLINE" = true ]; then
    echo_info "跳过 cc-discipline 安装 (--skip-ccdiscipline)"
else
    echo_step "安装 cc-discipline (物理防火墙 Hooks)"
    CC_DISCIPLINE_PATH="$HOME/.cc-discipline"
    CC_DISCIPLINE_COMMIT="916da00691128fde44599928d76c129f3d08b8f1"  # 锁定版本 2026-04-26
    if [ ! -d "$CC_DISCIPLINE_PATH" ]; then
        echo_info "克隆 cc-discipline 仓库..."
        git clone -b main https://github.com/TechHU-GS/cc-discipline.git "$CC_DISCIPLINE_PATH"
        cd "$CC_DISCIPLINE_PATH"
        git checkout "$CC_DISCIPLINE_COMMIT"
        # 验证 commit 是否匹配锁定版本
        ACTUAL_COMMIT=$(git rev-parse HEAD)
        if [ "$ACTUAL_COMMIT" != "$CC_DISCIPLINE_COMMIT" ]; then
            echo_fail "commit 不匹配！预期: ${CC_DISCIPLINE_COMMIT:0:7}, 实际: ${ACTUAL_COMMIT:0:7}"
            cd "$PROJECT_PATH"
            rm -rf "$CC_DISCIPLINE_PATH"
            exit 1
        fi
        # GPG 签名验证（可选，需要公钥）
        if command -v gpg >/dev/null 2>&1 && git verify-commit HEAD >/dev/null 2>&1; then
            echo_success "GPG 签名验证通过"
        fi
        cd "$PROJECT_PATH"
        echo_success "已克隆并验证 cc-discipline (commit: ${CC_DISCIPLINE_COMMIT:0:7})"
    else
        echo_info "cc-discipline 已存在"
        EXISTING_COMMIT=$(git -C "$CC_DISCIPLINE_PATH" rev-parse HEAD 2>/dev/null || echo "")
        if [ "$EXISTING_COMMIT" != "$CC_DISCIPLINE_COMMIT" ]; then
            echo_warn "现有 commit (${EXISTING_COMMIT:0:7}) 与锁定版本 (${CC_DISCIPLINE_COMMIT:0:7}) 不一致，正在切换..."
            git -C "$CC_DISCIPLINE_PATH" fetch origin
            git -C "$CC_DISCIPLINE_PATH" checkout "$CC_DISCIPLINE_COMMIT"
        fi
    fi
    echo_info "正在执行 cc-discipline 初始化..."
    # --force 模式下传递 --auto 给 cc-discipline，使其非交互运行
    CC_DISCIPLINE_FLAGS=""
    if [ "$FORCE_OVERWRITE" = true ]; then
        CC_DISCIPLINE_FLAGS="--auto"
    fi
    if bash "$CC_DISCIPLINE_PATH/init.sh" $CC_DISCIPLINE_FLAGS; then
        echo_success "cc-discipline 已安装"
    else
        echo_warn "cc-discipline 初始化失败，请手动执行: bash $CC_DISCIPLINE_PATH/init.sh"
    fi
fi

# 6. 复制校验脚本和 Shell 工具（白名单部署）
echo_step "复制校验脚本和 Shell 工具到 .claude/scripts/"

# 部署目标项目需要的脚本（白名单）
# - Python 校验脚本（pre-commit hooks 使用）
# - Shell 工具脚本（Skills/Router 引用）
# 不包括：check-env.sh、configure-gitignore.*、lib/common.sh（仅 init 时用）
# 不包括：__pycache__/（编译缓存）
# 优先从 script_whitelist.json 读取，不存在则使用硬编码列表
if [ -f "$SCRIPT_DIR/scripts/script_whitelist.json" ]; then
    # 检测可用的 Python 解释器（Windows Git Bash 可能只有 python）
    PYTHON_BIN=""
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_BIN="python"
    fi
    if [ -n "$PYTHON_BIN" ]; then
        WHITELIST_FILE="$SCRIPT_DIR/scripts/script_whitelist.json"
        SCRIPT_WHITELIST=$("$PYTHON_BIN" -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
print(' '.join(data['scripts']))
" "$WHITELIST_FILE" 2>/dev/null)
    fi
fi
if [ -z "$SCRIPT_WHITELIST" ]; then
    SCRIPT_WHITELIST="check_dependencies.py check_function_length.py check_import_order.py check_project_structure.py check_secrets.py check_docs_consistency.py check_trigger_conflicts.py check_ecc.sh tmux-session.sh weekly-report.sh ralph-setup.sh trigger-optimizer.sh validate_skills.sh PROMPT.md"
fi

SCRIPTS_DIR="$SCRIPT_DIR/scripts"
TARGET_SCRIPTS_DIR="$PROJECT_PATH/.claude/scripts"
# 检查源目录与目标目录是否相同
if [ "$SCRIPTS_DIR" = "$TARGET_SCRIPTS_DIR" ]; then
    echo_info "源目录与目标目录相同，已跳过脚本复制"
elif [ -d "$SCRIPTS_DIR" ]; then
    mkdir -p "$TARGET_SCRIPTS_DIR"
    for file in $SCRIPT_WHITELIST; do
        if [ -f "$SCRIPTS_DIR/$file" ]; then
            cp "$SCRIPTS_DIR/$file" "$TARGET_SCRIPTS_DIR/"
        fi
    done
    find "$TARGET_SCRIPTS_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    echo_success "已复制校验脚本和 Shell 工具到 .claude/scripts/"
else
    echo_info "scripts 目录为空或不存在，跳过"
fi

# 7. 复制 Pre-commit 配置
echo_step "复制 Pre-commit 配置"
PRECOMMIT_CONFIG="$SCRIPT_DIR/configs/.pre-commit-config.yaml"
TARGET_PRECOMMIT_CONFIG="$PROJECT_PATH/.pre-commit-config.yaml"
if [ -f "$PRECOMMIT_CONFIG" ]; then
    cp "$PRECOMMIT_CONFIG" "$TARGET_PRECOMMIT_CONFIG"
    echo_success "已复制 .pre-commit-config.yaml"
else
    echo_info "Pre-commit 配置不存在，跳过"
fi

# 8. 安装 Pre-commit hooks
echo_step "安装 Pre-commit Hooks"

# 检查 Python 是否可用
if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
    PYTHON_CMD=$(command -v python3 || command -v python)
    # 检查 pre-commit 是否已安装
    $PYTHON_CMD -c "import pre_commit" 2>/dev/null || {
        echo_info "正在安装 pre-commit..."
        $PYTHON_CMD -m pip install --quiet "pre-commit>=4.0" 2>/dev/null && echo_success "pre-commit 安装完成"
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

# 9. 复制覆盖层模板
echo_step "复制覆盖层模板"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# 辅助: 获取模板版本号 (始终返回成功,未找到时返回空字符串)
template_version() {
    grep -m1 "模板版本：" "$1" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true
}

# 模板复制函数: 目标已存在时提供交互选择
# 用法: copy_template <源> <目标> <显示名>
copy_template() {
    _src="$1"; _target="$2"; _display="$3"

    if [ ! -f "$_target" ]; then
        cp "$_src" "$_target"
        echo_success "已复制 $_display"
        return
    fi

    _src_ver=$(template_version "$_src")
    _tgt_ver=$(template_version "$_target")

    if [ "$FORCE_OVERWRITE" = true ]; then
        cp "$_target" "$_target.bak"
        cp "$_src" "$_target"
        echo_success "已强制覆盖 $_display (原文件备份为 .bak)"
        return
    fi

    echo ""
    echo -e "${YELLOW}━━━ $_display 已存在 ━━━${NC}"
    [ -n "$_tgt_ver" ] && echo -e "  目标版本: ${GRAY}$_tgt_ver${NC}"
    [ -n "$_src_ver" ] && echo -e "  源版本:   ${GREEN}$_src_ver${NC}"
    echo ""
    echo -e "  ${CYAN}[s]${NC} 跳过(默认)  ${CYAN}[o]${NC} 覆盖(备份原文件)  ${CYAN}[d]${NC} 查看差异"
    printf "  请选择: "
    read -r _choice </dev/tty 2>/dev/null || _choice="s"
    case "$_choice" in
        o|O)
            cp "$_target" "$_target.bak"
            cp "$_src" "$_target"
            echo_success "已覆盖 $_display (原文件备份为 .bak)"
            ;;
        d|D)
            if command -v diff >/dev/null 2>&1; then
                diff -u "$_target" "$_src" || true
            elif command -v git >/dev/null 2>&1; then
                git diff --no-index "$_target" "$_src" || true
            else
                echo_warn "无法显示差异 (diff/git 不可用)"
            fi
            echo ""
            echo -e "  ${CYAN}[s]${NC} 跳过  ${CYAN}[o]${NC} 覆盖(备份原文件)"
            printf "  现在选择: "
            read -r _choice2 </dev/tty 2>/dev/null || _choice2="s"
            [ "$_choice2" = "o" ] || [ "$_choice2" = "O" ] && {
                cp "$_target" "$_target.bak"
                cp "$_src" "$_target"
                echo_success "已覆盖 $_display (原文件备份为 .bak)"
            }
            ;;
        *) echo_info "已跳过 $_display" ;;
    esac
}

if [ -d "$TEMPLATE_DIR" ]; then
    copy_template "$TEMPLATE_DIR/CLAUDE_Template.md" "$PROJECT_PATH/CLAUDE.md" "CLAUDE.md"
    if [ -f "$TEMPLATE_DIR/SOUL_Template.md" ]; then
        copy_template "$TEMPLATE_DIR/SOUL_Template.md" "$PROJECT_PATH/SOUL.md" "SOUL.md"
    else
        echo_warn "SOUL_Template.md 不存在，跳过 SOUL.md 生成"
    fi
    mkdir -p "$PROJECT_PATH/.claude"
    copy_template "$TEMPLATE_DIR/PLAN_Template.md" "$PROJECT_PATH/.claude/PLAN_Template.md" "PLAN_Template.md"
    copy_template "$TEMPLATE_DIR/SPEC_Template.md" "$PROJECT_PATH/.claude/SPEC_Template.md" "SPEC_Template.md"
    copy_template "$TEMPLATE_DIR/ROUTINE_Template.md" "$PROJECT_PATH/.claude/ROUTINE_Template.md" "ROUTINE_Template.md"
else
    echo_warn "模板目录不存在，跳过模板复制"
fi

# 9.1 模板版本检查
echo_step "检查模板版本"
check_template_version() {
    _src="$1"
    _target="$2"
    if [ -f "$_src" ] && [ -f "$_target" ]; then
        _src_ver=$(grep -m1 "模板版本：" "$_src" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
        _target_ver=$(grep -m1 "模板版本：" "$_target" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
        if [ -n "$_src_ver" ] && [ -n "$_target_ver" ] && [ "$_src_ver" != "$_target_ver" ]; then
            _name=$(basename "$_target")
            echo_warn "   $_name: 源版本 $_src_ver / 目标版本 $_target_ver — 建议手动合并更新"
        fi
    fi
}
check_template_version "$TEMPLATE_DIR/CLAUDE_Template.md" "$PROJECT_PATH/CLAUDE.md"
check_template_version "$TEMPLATE_DIR/SOUL_Template.md" "$PROJECT_PATH/SOUL.md"
check_template_version "$TEMPLATE_DIR/PLAN_Template.md" "$PROJECT_PATH/.claude/PLAN_Template.md"
check_template_version "$TEMPLATE_DIR/SPEC_Template.md" "$PROJECT_PATH/.claude/SPEC_Template.md"
check_template_version "$TEMPLATE_DIR/ROUTINE_Template.md" "$PROJECT_PATH/.claude/ROUTINE_Template.md"
echo_success "模板版本检查完成"

# 9.2 复制记忆系统模板
echo_step "复制记忆系统模板"
MEMORY_TEMPLATE="$TEMPLATE_DIR/memory/MEMORY.md"
if [ -f "$MEMORY_TEMPLATE" ]; then
    mkdir -p "$PROJECT_PATH/.claude/memory/archive"
    touch "$PROJECT_PATH/.claude/memory/archive/.gitkeep"
    copy_template "$MEMORY_TEMPLATE" "$PROJECT_PATH/.claude/memory/MEMORY.md" "MEMORY.md"
    echo_success "已复制记忆系统模板到 .claude/memory/"
else
    echo_info "记忆模板不存在，跳过"
fi

# 10. 复制自定义命令
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

# 10.1 复制 Skills
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

# 10.2 复制 Hooks 和 settings.json
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

# 11. 创建本地偏好文件 (gitignored)
echo_step "创建 CLAUDE.local.md (本地偏好)"
mkdir -p "$PROJECT_PATH/.claude"
if [ -f "$PROJECT_PATH/.claude/CLAUDE.local.md" ]; then
    if [ "$FORCE_OVERWRITE" = true ]; then
        echo_warn "CLAUDE.local.md 已存在，--force 模式：覆盖"
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
        echo_success "已覆盖 CLAUDE.local.md"
    else
        echo_warn "CLAUDE.local.md 已存在，跳过创建（使用 --force 可覆盖）"
    fi
else
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
fi

# 创建 MEMORY.local.md (个人私密记忆，不提交)
if [ -f "$PROJECT_PATH/MEMORY.local.md" ]; then
    if [ "$FORCE_OVERWRITE" = true ]; then
        echo_warn "MEMORY.local.md 已存在，--force 模式：覆盖"
        cat > "$PROJECT_PATH/MEMORY.local.md" << 'LOCALEOF'
# 个人私密记忆
# 此文件会被 .gitignore 忽略，不会提交到仓库
# 记录个人偏好、工作习惯等不适合团队共享的内容

> 由 claude-code-init 自动生成
> 模板版本: v1.0.0

---
<!-- 在此记录个人偏好设置、临时笔记等内容 -->
LOCALEOF
        echo_success "已覆盖 MEMORY.local.md"
    else
        echo_warn "MEMORY.local.md 已存在，跳过创建（使用 --force 可覆盖）"
    fi
else
    cat > "$PROJECT_PATH/MEMORY.local.md" << 'LOCALEOF'
# 个人私密记忆
# 此文件会被 .gitignore 忽略，不会提交到仓库
# 记录个人偏好、工作习惯等不适合团队共享的内容

> 由 claude-code-init 自动生成
> 模板版本: v1.0.0

---
<!-- 在此记录个人偏好设置、临时笔记等内容 -->
LOCALEOF
    echo_success "已创建 MEMORY.local.md (gitignored)"
fi

# 12. 处理 .gitignore（调用独立脚本）
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

# 13. 运行环境检查
echo ""
echo_step "运行环境完整性检查"
if [ -f "$SCRIPT_DIR/scripts/check-env.sh" ]; then
    echo_info "环境检查脚本已复制到项目"
fi

# 标记初始化完成（防止 cleanup 误删）
INIT_COMPLETED=true

# 完成
echo ""
echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}  Claude Code 开发环境初始化完成！${NC}"
echo -e "${GREEN}==============================================${NC}"
echo ""
echo -e "${CYAN}你现在拥有：${NC}"
echo -e "  ${GREEN}✅${NC} 9 个可自动触发的 Skills（审查/提交/TDD/重构/修复/解释/校验/头脑风暴/初始化）"
echo -e "  ${GREEN}✅${NC} 21 个自定义命令（/review /commit /gc /architect /fix /refactor /explain /validate /help /team /qa /capabilities /status /remember /overnight /overnight-report /plan-ceo-review /plan-eng-review /routine /messages /tdd）"
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

# 14. 全局偏好设置引导（跨所有项目生效）
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
