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

# ─── 输出建议 ───
if [ -n "$suggestion" ]; then
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
