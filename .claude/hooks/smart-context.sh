#!/bin/bash
# .claude/hooks/smart-context.sh
# 基于当前操作上下文，自动推荐合适的 Skill

# 从 stdin 读取 Claude Code 传递的事件数据
event_data=$(cat)

# 提取当前操作类型和文件路径
tool_name=$(echo "$event_data" | jq -r '.tool_name // ""' 2>/dev/null)
file_path=$(echo "$event_data" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
command=$(echo "$event_data" | jq -r '.tool_input.command // ""' 2>/dev/null)

suggestion=""

# ─── 场景匹配 ───

# 1. 编辑了测试文件 → 推荐 TDD
if echo "$file_path" | grep -qE "(^|/)tests?/.*\.(py|ts|js|go|rs)$"; then
    suggestion="检测到你正在编辑测试文件。建议使用「tdd-workflow」技能来强制执行红-绿-重构循环。"
fi

# 2. 连续修改同一个文件超过 3 次 → 推荐系统化调试
edit_count=$(echo "$event_data" | jq -r '.consecutive_edits // 0' 2>/dev/null)
if [ "$edit_count" -ge 3 ] 2>/dev/null; then
    suggestion="已连续编辑同一文件 $edit_count 次。建议暂停并启用「systematic-debug」技能进行根因分析。"
fi

# 3. 执行了 git commit → 推荐代码审查
if echo "$command" | grep -q "git commit"; then
    suggestion="代码已提交。建议在推送前使用「code-review」技能进行最终安全检查。"
fi

# 4. 编辑了涉及安全相关的文件 → 推荐安全审查
if echo "$file_path" | grep -qiE "(auth|login|password|token|secret|session|jwt|oauth|permission|acl)"; then
    suggestion="检测到你正在修改安全相关代码。建议使用「code-review」技能重点审查安全性。"
fi

# 5. 提交信息包含 refactor → 推荐重构检查
if echo "$command" | grep -qE "git (commit|add).*refactor"; then
    suggestion="检测到重构提交。建议使用「safe-refactoring」技能验证重构的安全性。"
fi

# 6. 编辑了数据库相关文件 → 提示数据安全
if echo "$file_path" | grep -qiE "(db|database|migration|schema|sql|model\.py|repository)"; then
    suggestion="检测到数据库相关修改。请确保已备份数据，并使用「code-review」检查数据操作安全性。"
fi

# ─── 输出建议 ───
if [ -n "$suggestion" ]; then
    # 输出为 JSON，Claude Code 会将其注入到对话上下文
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "suggestion": "$suggestion"
  }
}
EOF
fi

exit 0
