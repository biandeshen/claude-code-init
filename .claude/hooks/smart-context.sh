#!/bin/bash
# .claude/hooks/smart-context.sh
# 场景感知自动推荐 Skill，基于当前操作上下文提供智能建议
# 不依赖 jq，使用纯 shell 实现

# JSON 字符串转义函数（处理双引号和反斜杠）
json_escape() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$1" | jq -Rs '.'
    else
        # 回退：基础转义（反斜杠、双引号）
        # 注意：不在 while read pipeline 中追加 \n，因为 suggestion 始终为单行
        printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
    fi
}

# 跨平台 timeout 兼容读取 stdin（防止挂起）
if command -v timeout >/dev/null 2>&1; then
    event_data=$(timeout 5 cat 2>/dev/null)
elif command -v perl >/dev/null 2>&1; then
    event_data=$(perl -e 'alarm 5; eval { local $SIG{ALRM} = sub { die "timeout\n" }; print <STDIN> }' 2>/dev/null)
else
    # 回退：使用 read -t 逐行读取，最多读 5 行后超时（不要用 dd，它会阻塞等待 EOF）
    event_data=""
    for _ in 1 2 3 4 5; do
        IFS= read -t 1 line 2>/dev/null || break
        event_data="$event_data$line"$'\n'
    done
fi
if [ -z "$event_data" ]; then
    exit 0
fi

# 提取 tool_name
tool_name=$(echo "$event_data" | sed -n 's/.*"tool_name"\s*:\s*"\([^"]*\)".*/\1/p')

# 提取 file_path
file_path=$(echo "$event_data" | sed -n 's/.*"file_path"\s*:\s*"\([^"]*\)".*/\1/p')

# 提取 command
command=$(echo "$event_data" | sed -n 's/.*"command"\s*:\s*"\([^"]*\)".*/\1/p')
# 加固：限制命令长度，防止注入
command="${command:0:500}"
# 加固：移除控制字符，防止 JSON 注入
command=$(echo "$command" | tr -d '\000-\010\016-\037')

suggestion=""

# ─── 场景 1：编辑测试文件 → 推荐 TDD ───
if echo "$file_path" | grep -qE "(^|/)tests?/" 2>/dev/null; then
    suggestion="检测到你正在编辑测试文件。建议使用「tdd-workflow」技能来强制执行红-绿-重构循环，输入 /tdd-workflow 手动触发。 | "
fi

# ─── 场景 2：编辑安全相关文件 → 确定性加载 code-review ───
if echo "$file_path" | grep -qiE "(auth|login|password|token|secret|session|encrypt|jwt|oauth|crypto|ssl|tls|hash|cipher|cert|sign|rsa_key|api_key|private_key|secret_key)" 2>/dev/null; then
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}检测到你正在修改安全相关代码。「code-review」技能已自动加载。"
    # 确定性 Skill 激活（不依赖语义匹配）
    # 设置标志，在末尾统一 JSON 输出时包含 skillToActivate 字段
    SKILL_ACTIVATED="code-review"
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
if echo "$command" | grep -qE "git\s+push" 2>/dev/null; then
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
# 覆盖：rm -rf /、sudo rm -rf /、nice rm -rf /、nohup rm -rf / 等
# 检测常见命令前缀（sudo/command/nice/nohup/env/time/systemd-run/busybox/chroot）
# 注意：变量展开（rm $VAR）和命令替换（rm $(...)）无法通过纯 shell 正则检测
if echo "$command" | grep -qE "(^|[;&|])[[:space:]]*((sudo|command|nice|nohup|env|time|systemd-run|busybox|chroot)[[:space:]]+)?rm[[:space:]]+(-[rRf]+[[:space:]]*)+[[:space:]]*(/|~|[.][.])" 2>/dev/null; then
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
if echo "$command" | grep -qE "(^|[;&|])[[:space:]]*rm[[:space:]]+(-[rRf]+|--recursive|--force)([[:space:]]|$)" 2>/dev/null; then
    if echo "$command" | grep -qE "rm\s+-[rRf].*\$|rm\s+-[rRf].*~" 2>/dev/null; then
        # 变量展开或 ~ 可能是危险模式
        if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
        suggestion="${suggestion}⚠️ 检测到包含变量或通配符的删除命令，可能误删重要文件。"
    elif echo "$command" | grep -qE "rm\s+-[rRf]\s+/" 2>/dev/null; then
        # rm -rf / 是最危险的命令
        if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
        suggestion="${suggestion}⚠️ 危险！检测到 rm -rf / 命令，这会删除系统文件。"
    fi
fi

# ─── 场景 8：语义级安全检测（函数名检测）───
# 测试模式下跳过（避免 git diff HEAD 在有未提交更改的环境中误触发）
if [ "${HOOK_TEST_MODE:-0}" != "1" ]; then
# 获取最近编辑的函数名
edited_function=$(git diff HEAD 2>/dev/null | grep "^@@" -A5 | sed -n 's/.*(def\|function\|class\|fn)\s\+\([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/p' | head -1)

# 语义级安全检测
if echo "$edited_function" | grep -qiE "(encrypt|decrypt|hash|token|auth|login|password|secret|sanitize|validate)" 2>/dev/null; then
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}检测到你正在编辑安全敏感函数「$edited_function」，建议使用「code-review」技能重点审查安全性。"
fi
fi

# ─── 场景 9：夜间无人值守推荐 ───
# 测试模式下跳过时间依赖检测（避免 CI 夜间失败）
if [ "${HOOK_TEST_MODE:-0}" != "1" ]; then
    current_hour=$(date +%H 2>/dev/null || echo "12")
    if [ "$current_hour" -ge 18 ] && [ "$current_hour" -le 23 ]; then
        if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
        suggestion="${suggestion}已到夜间，是否设置云端 Routine 定时执行？输入 /routine 创建定时任务。"
    fi
fi

# ─── 场景 10：首次审查后推荐 Agent Teams ───
if echo "$command" | grep -q "/review" 2>/dev/null; then
    if [ -n "$suggestion" ]; then suggestion="$suggestion "; fi
    suggestion="${suggestion}首次使用代码审查？试试 /team 3 启动三人生审查，覆盖安全、性能和测试三个维度。"
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
    echo "$(date '+%Y-%m-%dT%H:%M:%S' 2>/dev/null) | smart-context | $suggestion" >> "$LOG_FILE" 2>/dev/null || true

    escaped=$(json_escape "$suggestion")
    if [ -n "$SKILL_ACTIVATED" ]; then
        cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "skillToActivate": "$SKILL_ACTIVATED",
    "suggestion": "$escaped"
  }
}
EOF
    else
        cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "suggestion": "$escaped"
  }
}
EOF
    fi
fi

exit 0
