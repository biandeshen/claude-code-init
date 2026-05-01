#!/bin/bash
# Skills 健康度验证脚本
# 用途：检测 SKILL.md 名称冲突、文件缺失等问题

set -e

echo "=== Claude Code Skills 健康度检查 ==="
echo ""

SKILLS_DIR=".claude/skills"
ERRORS=0

# 1. 检查所有目录是否有 SKILL.md
echo "[1/3] 检查 SKILL.md 文件存在性..."
for dir in "$SKILLS_DIR"/*/; do
    if [ -d "$dir" ]; then
        skill_name=$(basename "$dir")
        if [ ! -f "$dir/SKILL.md" ]; then
            echo "  [错误] $skill_name/ 下缺少 SKILL.md"
            ERRORS=$((ERRORS + 1))
        else
            echo "  [OK] $skill_name/"
        fi
    fi
done

# 2. 检查 name 字段唯一性
echo ""
echo "[2/3] 检查 name 字段唯一性..."

# 使用临时文件代替关联数组（兼容 Bash 3.2+/macOS）
TMPFILE=$(mktemp -t cci_validate.XXXXXX) || { echo "  [错误] 无法创建临时文件"; exit 1; }
trap 'rm -f "$TMPFILE"' EXIT INT TERM

for file in "$SKILLS_DIR"/*/SKILL.md; do
    if [ -f "$file" ]; then
        name=$(grep "^name:" "$file" | head -1 | sed 's/name: *//' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        if [ -n "$name" ]; then
            echo "$name" >> "$TMPFILE"
        fi
    fi
done

HAS_DUPLICATE=0
while read count name; do
    if [ "$count" -gt 1 ]; then
        echo "  [错误] name='$name' 出现 ${count} 次"
        ERRORS=$((ERRORS + 1))
        HAS_DUPLICATE=1
    fi
done < <(sort "$TMPFILE" | uniq -c)

if [ $HAS_DUPLICATE -eq 0 ]; then
    echo "  [OK] 所有 name 字段唯一"
fi

# 3. 检查 description 是否为空
echo ""
echo "[3/3] 检查 description 非空..."
for file in "$SKILLS_DIR"/*/SKILL.md; do
    if [ -f "$file" ]; then
        skill_name=$(grep "^name:" "$file" | head -1 | sed 's/name: *//')
        desc=$(sed -n '/^---$/,/^---$/{/^description:/p}' "$file" | head -1)
        if [ -z "$desc" ]; then
            echo "  [警告] $skill_name 缺少 description"
        fi
    fi
done

# 总结
echo ""
echo "=== 检查结果 ==="
if [ $ERRORS -eq 0 ]; then
    echo "[PASS] 所有检查通过，Skills 体系健康"
    exit 0
else
    echo "[FAIL] 发现 $ERRORS 个错误"
    exit 1
fi
