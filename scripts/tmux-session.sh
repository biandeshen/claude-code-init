#!/bin/bash
# scripts/tmux-session.sh
# Claude Code 无人值守 tmux 会话管理器
# 功能：
#   - 创建/重连 tmux 会话
#   - 自动加载项目 .claude/settings.json
#   - 安全限制：--max-turns, --max-budget-usd, --max-files-changed, --max-lines-changed
#   - 路由模式：无人值守（通过 CLAUDE_MODE=unattended 标记触发）
# 用法：
#   bash .claude/scripts/tmux-session.sh                    # 使用默认任务文件
#   bash .claude/scripts/tmux-session.sh .claude/scripts/PROMPT.md # 指定任务文件

set -euo pipefail

SESSION_NAME="${SESSION_NAME:-claude-overnight}"
PROMPT_FILE="${1:-.claude/scripts/PROMPT.md}"
PROJECT_DIR="${2:-.}"

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
echo_info() { echo -e "[信息] $1"; }

# 默认安全参数
MAX_TURNS="${MAX_TURNS:-50}"
MAX_BUDGET="${MAX_BUDGET:-10.00}"
MAX_FILES="${MAX_FILES:-20}"
MAX_LINES="${MAX_LINES:-500}"
MAX_ITERATIONS="${MAX_ITERATIONS:-10}"   # 累计最大迭代次数(无人值守安全上限)

# 检查依赖
check_deps() {
    if ! command -v tmux >/dev/null 2>&1; then
        echo_fail "tmux 未安装。请运行: brew install tmux (macOS) 或 apt install tmux (Linux)"
        exit 1
    fi
    if ! command -v claude >/dev/null 2>&1; then
        echo_fail "claude 未安装或不在 PATH 中"
        exit 1
    fi
}

# 创建 reports 目录
setup_reports() {
    mkdir -p "$PROJECT_DIR/.claude/reports"
    # 初始化 summary.md
    if [ ! -f "$PROJECT_DIR/.claude/reports/summary.md" ]; then
        cat > "$PROJECT_DIR/.claude/reports/summary.md" << EOF
# 无人值守任务汇总

> 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 执行概览

| 指标 | 值 |
|------|-----|
| 开始时间 | $(date '+%Y-%m-%d %H:%M:%S') |
| 会话名 | $SESSION_NAME |
| 任务文件 | $PROMPT_FILE |
| 最大轮次 | $MAX_TURNS |
| 最大预算 | \$$MAX_BUDGET |
| 最大文件数 | $MAX_FILES |
| 最大行数 | $MAX_LINES |

## 已完成任务

<!-- 任务完成后自动追加 -->

## 失败任务

<!-- 失败任务自动记录 -->

## Git 提交记录

\`\`\`bash
# 任务执行期间的提交
\`\`\`

## 总结

<!-- 整体总结 -->
EOF
    fi
}

# 检查会话是否存在
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo_warn "会话 $SESSION_NAME 已存在"
    echo "重连会话: tmux attach -t $SESSION_NAME"
    echo "终止会话: tmux kill-session -t $SESSION_NAME"
    exit 0
fi

check_deps
setup_reports

# 创建新会话
echo_step "创建 tmux 会话: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME"

# 初始化会话
echo_step "初始化 Claude Code 无人值守循环..."

# 检查是否存在 PROMPT 文件
if [ ! -f "$PROMPT_FILE" ]; then
    echo_warn "任务文件不存在: $PROMPT_FILE"
    echo "创建默认任务文件..."
    cat > "$PROMPT_FILE" << EOF
# 过夜任务清单

## 项目背景
请根据当前项目状态描述任务背景。

## 任务列表
- [ ] 任务1：描述
- [ ] 任务2：描述

## 完成标准
- 所有测试通过
- 无 lint 错误
- 每完成一个任务必须 git commit

## 硬限制
- 最多修改 $MAX_FILES 个文件，超过则停止并记录到 \`reports/overlimit.md\`
- 最多修改 $MAX_LINES 行代码
- 禁止执行 \`rm -rf\`、\`git push --force\`、\`DROP TABLE\`
- 违反任一硬限制立即停止并记录
- 最多重试 3 次，然后记录到 \`reports/blocked.md\` 继续下一个
EOF
fi

# 构建 Claude Code 命令（关键：加载项目配置 + 安全限制）
CLAUDE_SETTINGS="$PROJECT_DIR/.claude/settings.json"
ROUTER_SKILL="$PROJECT_DIR/.claude/skills/router/SKILL.md"

# 基础参数（含安全限制）
BASE_PARAMS="--max-turns $MAX_TURNS --max-budget-usd $MAX_BUDGET --max-files-changed $MAX_FILES --max-lines-changed $MAX_LINES --max-input-rate 5000 --max-output-rate 10000"

# 如果有项目配置，加载它
if [ -f "$CLAUDE_SETTINGS" ]; then
    SETTINGS_PARAM="--settings \"$CLAUDE_SETTINGS\""
    echo_info "加载项目配置: $CLAUDE_SETTINGS"
else
    SETTINGS_PARAM=""
    echo_warn "未找到项目配置，使用受限模式"
fi

# 如果有无人值守专用路由，加载它
if [ -f "$ROUTER_UNATTENDED" ]; then
    ROUTER_PARAM="--skill router-unattended"
    echo_info "加载无人值守专用路由"
else
    echo_info "使用默认路由"
fi

# 构建完整命令
CLAUDE_CMD="claude -p \"\$(cat $PROMPT_FILE)\" $SETTINGS_PARAM $ROUTER_PARAM $BASE_PARAMS --permission-mode acceptEdits"

# 发送初始化命令
tmux send-keys -t "$SESSION_NAME" "cd \"$PROJECT_DIR\"" Enter
sleep 1

# 启动 Claude Code
echo_info "启动 Claude Code..."
echo_info "参数: --max-turns $MAX_TURNS --max-budget-usd \$$MAX_BUDGET --max-files $MAX_FILES --max-lines $MAX_LINES"

tmux send-keys -t "$SESSION_NAME" "ITER=0; while [ \$ITER -lt $MAX_ITERATIONS ]; do" Enter
tmux send-keys -t "$SESSION_NAME" "  ITER=\$((ITER + 1))" Enter
tmux send-keys -t "$SESSION_NAME" "  CLAUDE_MODE=unattended claude -p \"\$(cat $PROMPT_FILE)\" \\" Enter
if [ -n "$SETTINGS_PARAM" ]; then
    tmux send-keys -t "$SESSION_NAME" "    $SETTINGS_PARAM \\" Enter
fi
if [ -n "$ROUTER_PARAM" ]; then
    tmux send-keys -t "$SESSION_NAME" "    $ROUTER_PARAM \\" Enter
fi
tmux send-keys -t "$SESSION_NAME" "    $BASE_PARAMS \\" Enter
tmux send-keys -t "$SESSION_NAME" "    --permission-mode acceptEdits" Enter
tmux send-keys -t "$SESSION_NAME" "  sleep 2" Enter
tmux send-keys -t "$SESSION_NAME" "done" Enter

# 无人值守任务完成后自动通知
notify_completion() {
    if [ "$(uname)" = "Darwin" ]; then
        osascript -e "display notification \"Claude Code 过夜任务已完成\" with title \"claude-code-init\""
    elif [ "$(uname)" = "Linux" ] && command -v notify-send >/dev/null 2>&1; then
        notify-send "claude-code-init" "过夜任务已完成"
    fi
}

echo ""
echo_success "无人值守会话已启动"
echo ""
echo -e "${CYAN}会话控制：${NC}"
echo "  重连会话: tmux attach -t $SESSION_NAME"
echo "  分离会话: Ctrl+B, D"
echo "  终止会话: tmux kill-session -t $SESSION_NAME"
echo ""
echo -e "${CYAN}安全限制：${NC}"
echo "  最大轮次: $MAX_TURNS"
echo "  最大预算: \$$MAX_BUDGET"
echo "  最大文件数: $MAX_FILES"
echo "  最大行数: $MAX_LINES"
echo ""
echo -e "${CYAN}任务文件：${NC} $PROMPT_FILE"
echo -e "${CYAN}报告目录：${NC} $PROJECT_DIR/.claude/reports"
echo ""
echo "完成后查看汇总:"
echo "  cat $PROJECT_DIR/.claude/reports/summary.md"
