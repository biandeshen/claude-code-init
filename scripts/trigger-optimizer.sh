#!/bin/bash
# scripts/trigger-optimizer.sh
# 分析 Skills 触发日志，推荐需要补充的触发词
# 版本: v1.0.0 | 2026-04-30

set -e

LOG_FILE="$HOME/.claude-skill-usage.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../../.claude/skills"

# 加载公共库（颜色输出 + 工具函数）
[ -f "$SCRIPT_DIR/lib/common.sh" ] && source "$SCRIPT_DIR/lib/common.sh"

echo -e "${CYAN}=== Skills 触发优化分析 ===${NC}"
echo ""

# 检查日志文件
if [ ! -f "$LOG_FILE" ]; then
    echo -e "${YELLOW}暂无触发日志${NC}"
    echo "日志文件位置：$LOG_FILE"
    echo ""
    echo "开始使用 Skills 后，运行此脚本获取优化建议。"
    echo ""
    echo -e "${CYAN}提示：${NC} 确保你的 Hook 配置中有记录 Skills 触发的逻辑。"
    exit 0
fi

# 1. Skills 触发统计
echo -e "${CYAN}--- Skills 触发频率统计 ---${NC}"
if [ -s "$LOG_FILE" ]; then
    # 提取 Skill 名称并统计
    trigger_count=$(cut -d'|' -f2 "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn)
    if [ -n "$trigger_count" ]; then
        echo "$trigger_count"
    else
        echo "（无法解析日志格式）"
    fi
else
    echo "（日志文件为空）"
fi

echo ""

# 2. 未触发过的 Skills
echo -e "${CYAN}--- 未触发过的 Skills（可能需要优化触发词）---${NC}"
if [ -d "$SKILLS_DIR" ]; then
    found_unused=false
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(grep "^name:" "$skill_dir/SKILL.md" 2>/dev/null | head -1 | sed 's/name: *//')
            if [ -n "$skill_name" ]; then
                if ! grep -q "$skill_name" "$LOG_FILE" 2>/dev/null; then
                    found_unused=true
                    echo -e "  ${YELLOW}-${NC} $skill_name"
                    echo -e "    ${RED}从未触发${NC}，建议检查 description 中的触发词是否覆盖高频使用场景"
                fi
            fi
        fi
    done
    if [ "$found_unused" = false ]; then
        echo -e "  ${GREEN}所有 Skills 都已被触发过${NC}"
    fi
else
    echo "  （Skills 目录不存在）"
fi

echo ""

# 3. 触发来源分布
echo -e "${CYAN}--- 触发来源分布 ---${NC}"
if [ -s "$LOG_FILE" ]; then
    source_count=$(cut -d'|' -f1 "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -10)
    if [ -n "$source_count" ]; then
        echo "$source_count"
    else
        echo "（无法解析日志格式）"
    fi
else
    echo "（日志文件为空）"
fi

echo ""

# 4. 优化建议
echo -e "${CYAN}=== 优化建议 ===${NC}"
echo "1. 查看你日常对话中最常用的词汇，补充到对应 Skill 的 description 中"
echo "2. 检查从未触发的 Skill，考虑是否触发词与实际使用场景不匹配"
echo "3. 运行以下命令查看更详细的触发来源分布："
echo -e "   ${YELLOW}cat $LOG_FILE | cut -d\"|\" -f1 | sort | uniq -c | sort -rn${NC}"
echo ""

# 5. 检查是否有新 Skill 可用
echo -e "${CYAN}--- 可用 Skills 列表 ---${NC}"
if [ -d "$SKILLS_DIR" ]; then
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
            skill_name=$(grep "^name:" "$skill_dir/SKILL.md" 2>/dev/null | head -1 | sed 's/name: *//')
            skill_desc=$(grep "^description:" "$skill_dir/SKILL.md" 2>/dev/null | head -1 | sed 's/description: *//' | cut -c1-60)
            if [ -n "$skill_name" ]; then
                echo -e "  ${GREEN}*$skill_name${NC} - $skill_desc"
            fi
        fi
    done
else
    echo "  （Skills 目录不存在）"
fi

echo ""
echo -e "${CYAN}=== 分析完成 ===${NC}"
