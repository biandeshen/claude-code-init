#!/bin/bash
# .claude/hooks/smart-context.sh
# 场景感知自动推荐 Skill，基于当前操作上下文提供智能建议
# 不依赖 jq，使用纯 shell 实现

event_data=$(cat 2>/dev/null)
if [ -z "$event_data" ]; then
    exit 0
fi

# 提取 tool_name
tool_name=$(echo "$event_data" | sed -n 's/.*"tool_name"\s*:\s*"\([^"]*\)".*/\1/p')

# 提取 file_path
file_path=$(echo "$event_data" | sed -n 's/.*"file_path"\s*:\s*"\([^"]*\)".*/\1/p')

# 提取 command
command=$(echo "$event_data" | sed -n 's/.*"command"\s*:\s*"\([^"]*\)".*/\1/p')

suggestion=""

# ─── 场景 1：编辑测试文件 → 推荐 TDD ───
if echo "$file_path" | grep -qE "(^|/)tests?/" 2>/dev/null; then
    suggestion="检测到你正在编辑测试文件。建议使用「tdd-workflow」技能来强制执行红-绿-重构循环，输入 /tdd-workflow 手动触发。 | "
fi

# ─── 场景 2：编辑安全相关文件 → 推荐安全审查 ───
if echo "$file_path" | grep -qiE "(auth|login|password|token|secret|session|encrypt|jwt|oauth|crypto|ssl|tls|hash|cipher|cert|sign|rsa_key|api_key|private_key|secret_key)" 2>/dev/null; then
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}检测到你正在修改安全相关代码。建议使用「code-review」技能重点审查安全性，输入 /code-review 手动触发。"
fi

# ─── 场景 3：编辑涉及数据库的文件 → 推荐架构评审 ───
if echo "$file_path" | grep -qiE "(migration|schema|model|repository|dao|db/)" 2>/dev/null; then
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}检测到你正在修改数据库相关代码。如果涉及 Schema 变更，建议先用「brainstorming」技能确认方案。"
fi

# ─── 场景 4：执行 git commit → 推荐代码审查 ───
if echo "$command" | grep -q "git commit" 2>/dev/null; then
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}代码已提交。建议在推送前使用「code-review」技能进行最终安全检查。"
fi

# ─── 场景 5：执行 git push --force → 警告 ───
if echo "$command" | grep -q "git push" 2>/dev/null; then
    if echo "$command" | grep -q "\-\-force-with-lease" 2>/dev/null; then
        # --force-with-lease 是相对安全的变体
        if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
        suggestion="${suggestion}检测到 git push --force-with-lease。请确认远程分支未被其他人更新。"
    elif echo "$command" | grep -q "\-\-force\b" 2>/dev/null; then
        # 裸 --force 才是真正的危险操作
        if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
        suggestion="${suggestion}⚠️ 检测到 git push --force。请确认你了解这将对远程仓库产生的影响。"
    fi
fi

# ─── 场景 6：rm -rf 物理阻断（最高优先级）───
# 检测危险删除命令——物理阻断，Claude Code 无法绕过
if echo "$command" | grep -qE "rm\s+-rf\s+(/|~|\.\.|\.)" 2>/dev/null; then
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "检测到危险命令 rm -rf，已自动阻止。如需执行，请在终端中手动操作并确认。"
  }
}
EOF
    exit 2
fi

# ─── 场景 7：执行 rm -rf 等危险删除命令 → 警告 ───
if echo "$command" | grep -qE "rm\s+-(rRf)" 2>/dev/null; then
    if echo "$command" | grep -qE "rm\s+-(rRf).*\$|rm\s+-(rRf).*~" 2>/dev/null; then
        # 变量展开或 ~ 可能是危险模式
        if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
        suggestion="${suggestion}⚠️ 检测到包含变量或通配符的删除命令，可能误删重要文件。"
    elif echo "$command" | grep -qE "rm\s+-(rRf)\s+/" 2>/dev/null; then
        # rm -rf / 是最危险的命令
        if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
        suggestion="${suggestion}⚠️ 危险！检测到 rm -rf / 命令，这会删除系统文件。"
    fi
fi

# ─── 场景 7：语义级安全检测（函数名检测）───
# 获取最近编辑的函数名
edited_function=$(git diff HEAD 2>/dev/null | grep "^@@" -A5 | grep -oP "(def|function|class|fn)\s+\K\w+" | head -1)

# 语义级安全检测
if echo "$edited_function" | grep -qiE "(encrypt|decrypt|hash|token|auth|login|password|secret|sanitize|validate)" 2>/dev/null; then
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}检测到你正在编辑安全敏感函数「$edited_function」，建议使用「code-review」技能重点审查安全性。"
fi

# ─── 场景 8：夜间无人值守推荐 ───
current_hour=$(date +%H 2>/dev/null || echo "12")
if [ "$current_hour" -ge 18 ] && [ "$current_hour" -le 23 ]; then
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}已到夜间，是否需要设置无人值守过夜任务？输入 'bash scripts/tmux-session.sh scripts/PROMPT.md' 启动"
fi

# ─── 自动记忆关键决策 ───
if echo "$suggestion" | grep -qiE "(5分|SDD|安全审查|重大变更)" 2>/dev/null; then
    # 触发记忆功能记录此决策
    memory_hint="此任务涉及重大决策，建议使用 /memory 记录决策理由"
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}💡 涉及重大决策，可使用 /memory 记录"
fi

# ─── 输出建议 ───
if [ -n "$suggestion" ]; then
    # 记录触发日志
    LOG_FILE="$HOME/.claude-skill-usage.log"
    echo "$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S') | smart-context | $suggestion" >> "$LOG_FILE" 2>/dev/null || true

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
