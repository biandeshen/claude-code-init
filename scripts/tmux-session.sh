#!/bin/bash
# scripts/tmux-session.sh
# Claude Code 无人值守 tmux 会话管理器
# 功能：
#   - 创建/重连 tmux 会话
#   - 自动加载项目 .claude/settings.json
#   - Ralph Wiggum 循环执行
#   - 任务完成后生成 reports/summary.md
# 用法：
#   bash scripts/tmux-session.sh                    # 使用默认任务文件
#   bash scripts/tmux-session.sh scripts/PROMPT.md # 指定任务文件

set -e

SESSION_NAME="${SESSION_NAME:-claude-overnight}"
PROMPT_FILE="${1:-scripts/PROMPT.md}"
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

# 检查依赖
check_deps() {
    if ! command -v tmux &> /dev/null; then
        echo_fail "tmux 未安装。请运行: brew install tmux (macOS) 或 apt install tmux (Linux)"
        exit 1
    fi
    if ! command -v claude &> /dev/null; then
        echo_fail "claude 未安装或不在 PATH 中"
        exit 1
    fi
}

# 创建 reports 目录
setup_reports() {
    mkdir -p "$PROJECT_DIR/reports"
    # 初始化 summary.md
    if [ ! -f "$PROJECT_DIR/reports/summary.md" ]; then
        cat > "$PROJECT_DIR/reports/summary.md" << EOF
# 无人值守任务汇总

> 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

## 执行概览

| 指标 | 值 |
|------|-----|
| 开始时间 | $(date '+%Y-%m-%d %H:%M:%S') |
| 会话名 | $SESSION_NAME |
| 任务文件 | $PROMPT_FILE |

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
    cat > "$PROMPT_FILE" << 'EOF'
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

## 约束条件
- 最多重试 3 次，然后记录到 reports/blocked.md 继续下一个
- 不要执行 git push --force
- 每完成一个任务，在 reports/task-001.md 中写一段不超过 5 行的总结
EOF
fi

# 构建 Claude Code 命令（关键：加载项目配置）
# 使用 --settings 参数确保 cc-discipline 等规则生效
CLAUDE_CMD="claude -p \"\$(cat $PROMPT_FILE)\" \
  --settings \"$PROJECT_DIR/.claude/settings.json\" \
  --max-turns 50 \
  --max-budget-usd 10.00 \
  --permission-mode acceptEdits \
  --max-input-rate 5000 \
  --max-output-rate 10000"

# 发送初始化命令
tmux send-keys -t "$SESSION_NAME" "cd \"$PROJECT_DIR\"" Enter
sleep 1

# 启动 Ralph Wiggum 循环（如果可用）
if claude --help 2>/dev/null | grep -q "ralph"; then
    echo_info "检测到 Ralph Wiggum 插件，使用 /ralph-loop"
    tmux send-keys -t "$SESSION_NAME" "/ralph-loop \"\$(cat $PROMPT_FILE)\" --max-iterations 100" Enter
else
    # 使用原生 while 循环作为备选
    echo_info "使用原生循环作为备选方案"
    tmux send-keys -t "$SESSION_NAME" "while true; do" Enter
    tmux send-keys -t "$SESSION_NAME" "  claude -p \"\$(cat $PROMPT_FILE)\" \\" Enter
    tmux send-keys -t "$SESSION_NAME" "    --settings \"$PROJECT_DIR/.claude/settings.json\" \\" Enter
    tmux send-keys -t "$SESSION_NAME" "    --max-turns 50 \\" Enter
    tmux send-keys -t "$SESSION_NAME" "    --max-budget-usd 10.00 \\" Enter
    tmux send-keys -t "$SESSION_NAME" "    --permission-mode acceptEdits" Enter
    tmux send-keys -t "$SESSION_NAME" "  sleep 2" Enter
    tmux send-keys -t "$SESSION_NAME" "done" Enter
fi

echo ""
echo_success "无人值守会话已启动"
echo ""
echo -e "${CYAN}会话控制：${NC}"
echo "  重连会话: tmux attach -t $SESSION_NAME"
echo "  分离会话: Ctrl+B, D"
echo "  终止会话: tmux kill-session -t $SESSION_NAME"
echo ""
echo -e "${CYAN}任务文件：${NC} $PROMPT_FILE"
echo -e "${CYAN}项目目录：${NC} $PROJECT_DIR"
echo -e "${CYAN}报告目录：${NC} $PROJECT_DIR/reports"
echo ""
echo "完成后查看汇总:"
echo "  cat $PROJECT_DIR/reports/summary.md"
