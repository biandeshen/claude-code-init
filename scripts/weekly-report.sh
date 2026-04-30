#!/bin/bash
# scripts/weekly-report.sh
# 生成本周 Claude Code 使用报告
# 版本: v1.0.0 | 2026-04-30

set -e

LOG_FILE="$HOME/.claude-skill-usage.log"
REPORTS_DIR=".claude/reports"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Claude Code 本周使用报告${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 获取本周起始日期（本周一）
if command -v date >/dev/null 2>&1; then
    # 尝试获取本周一日期（兼容 Linux/macOS）
    THIS_WEEK=$(date -d "last Monday" +%Y-%m-%d 2>/dev/null || date -v-mon +%Y-%m-%d 2>/dev/null || echo "$(date +%Y-%m-01)")
else
    THIS_WEEK="$(date +%Y-%m-01)"
fi

echo -e "${YELLOW}报告周期：${THIS_WEEK} 至今${NC}"
echo ""

# 平台检测：为 macOS BSD find 准备兼容的时间过滤器
if [ "$(uname)" = "Darwin" ]; then
    WEEK_REF=$(mktemp /tmp/cci_week_ref_XXXXXX) || { echo "无法创建临时文件"; exit 1; }
    trap 'rm -f "$WEEK_REF"' EXIT
    FIND_TIME_FILTER="-newer $WEEK_REF"
    touch -t "$(echo "$THIS_WEEK" | tr -d '-')0000" "$WEEK_REF"
else
    FIND_TIME_FILTER="-newermt $THIS_WEEK"
fi

# 1. Git 统计
echo -e "${CYAN}--- Git 活动 ---${NC}"
if git rev-parse --git-dir > /dev/null 2>&1; then
    AUTHOR_NAME=$(git config user.name 2>/dev/null || echo "Unknown")
    AUTHOR_EMAIL=$(git config user.email 2>/dev/null)

    # 本周提交次数
    if [ -n "$AUTHOR_EMAIL" ]; then
        commit_count=$(git log --oneline --since="$THIS_WEEK" --author="$AUTHOR_NAME" 2>/dev/null | wc -l | tr -d ' ')
    else
        commit_count=$(git log --oneline --since="$THIS_WEEK" 2>/dev/null | wc -l | tr -d ' ')
    fi

    # 本周修改文件数
    if [ -n "$AUTHOR_EMAIL" ]; then
        file_count=$(git log --oneline --since="$THIS_WEEK" --name-only --author="$AUTHOR_NAME" 2>/dev/null | sort -u | wc -l | tr -d ' ')
    else
        file_count=$(git log --oneline --since="$THIS_WEEK" --name-only 2>/dev/null | sort -u | wc -l | tr -d ' ')
    fi

    # 本周新增代码行数
    if [ -n "$AUTHOR_EMAIL" ]; then
        lines_added=$(git log --since="$THIS_WEEK" --author="$AUTHOR_NAME" --pretty=tformat: --numstat 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        lines_deleted=$(git log --since="$THIS_WEEK" --author="$AUTHOR_NAME" --pretty=tformat: --numstat 2>/dev/null | awk '{sum+=$2} END {print sum+0}')
    else
        lines_added=$(git log --since="$THIS_WEEK" --pretty=tformat: --numstat 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        lines_deleted=$(git log --since="$THIS_WEEK" --pretty=tformat: --numstat 2>/dev/null | awk '{sum+=$2} END {print sum+0}')
    fi

    echo "本周提交次数：$commit_count"
    echo "本周修改文件数：$file_count"
    echo "本周代码增量：+$lines_added / -$lines_deleted 行"

    # 未提交改动
    unstaged=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    echo "当前未提交文件：$unstaged 个"
else
    echo "  （非 Git 仓库或无法访问）"
fi

echo ""

# 2. Skills 触发统计
echo -e "${CYAN}--- Skills 触发频率 ---${NC}"
if [ -f "$LOG_FILE" ]; then
    if grep "$THIS_WEEK" "$LOG_FILE" > /dev/null 2>&1; then
        echo "触发排名："
        grep "$THIS_WEEK" "$LOG_FILE" | cut -d'|' -f2 | sort | uniq -c | sort -rn | head -10 | \
            while read count name; do
                echo -e "  ${GREEN}$count${NC} 次 - $name"
            done
    else
        echo "本周暂无 Skills 触发记录"
    fi
else
    echo "  （触发日志文件不存在：$LOG_FILE）"
fi

echo ""

# 3. 无人值守任务
echo -e "${CYAN}--- 无人值守任务 ---${NC}"
if [ -d "$REPORTS_DIR" ]; then
    # 查找本周的 summary 文件
    this_week_summaries=$(find "$REPORTS_DIR" -name "summary-*.md" $FIND_TIME_FILTER 2>/dev/null | wc -l | tr -d ' ')

    echo "本周无人值守任务：$this_week_summaries 次"

    if [ "$this_week_summaries" -gt 0 ]; then
        echo ""
        echo "最近一次报告摘要："
        latest_summary=$(ls -t "$REPORTS_DIR"/summary-*.md 2>/dev/null | head -1)
        if [ -n "$latest_summary" ] && [ -f "$latest_summary" ]; then
            head -20 "$latest_summary" | while read line; do
                echo "  $line"
            done
        fi
    fi

    # 检查失败任务
    failed_count=$(find "$REPORTS_DIR" -name "failed-*.md" $FIND_TIME_FILTER 2>/dev/null | wc -l | tr -d ' ')
    if [ "$failed_count" -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️ 本周有 $failed_count 个失败任务${NC}"
        find "$REPORTS_DIR" -name "failed-*.md" $FIND_TIME_FILTER 2>/dev/null | head -3 | while read f; do
            echo "  - $f"
        done
    fi
else
    echo "本周未使用无人值守功能"
fi

echo ""

# 4. 代码审查统计
echo -e "${CYAN}--- 代码审查 ---${NC}"
review_reports=$(find "$REPORTS_DIR" -name "review-*.md" $FIND_TIME_FILTER 2>/dev/null | wc -l | tr -d ' ')
if [ "$review_reports" -gt 0 ]; then
    echo "本周进行代码审查：$review_reports 次"
else
    echo "本周未进行代码审查"
fi

echo ""

# 5. 建议
echo -e "${CYAN}--- 建议 ---${NC}"
if [ "$commit_count" -gt 20 ]; then
    echo -e "${GREEN}✓${NC} 开发活跃度很高"
elif [ "$commit_count" -lt 5 ]; then
    echo -e "${YELLOW}!${NC} 本周提交较少，考虑是否有未完成的任务"
fi

if [ "$review_reports" -eq 0 ]; then
    echo -e "${YELLOW}!${NC} 建议定期进行代码审查以保证代码质量"
fi

if [ -n "$unstaged" ] && [ "$unstaged" -gt 10 ]; then
    echo -e "${YELLOW}!${NC} 有 $unstaged 个文件未提交，建议及时 commit"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  报告结束${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "详细日志：$LOG_FILE"
echo ""
