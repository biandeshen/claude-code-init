#!/bin/bash
# scripts/check_ecc.sh - 检测 Everything Claude Code 插件是否安装
# 部署路径：init.sh 从 scripts/ 复制到目标项目的 .claude/scripts/

ECC_INSTALLED=0

# 方法1：检查 settings.json 中的插件配置
if [ -f ".claude/settings.json" ]; then
    if grep -q "everything-claude-code\|ecc\|ecc-plugin" .claude/settings.json 2>/dev/null; then
        ECC_INSTALLED=1
    fi
fi

# 方法2：检查常见插件目录路径
if [ "$ECC_INSTALLED" = "0" ]; then
    for path in \
        "$HOME/.claude/plugins/everything-claude-code" \
        "$HOME/.claude/plugins/ecc" \
        "$HOME/.config/claude/plugins/everything-claude-code" \
        "/opt/claude/plugins/everything-claude-code"; do

        if [ -d "$path" ]; then
            ECC_INSTALLED=1
            break
        fi
    done
fi

# 方法3：校验 ECC 版本完整性
ECC_VERSION_MISMATCH=0
if [ -f ".claude/ecc/VERSION" ]; then
    ECC_VERSION=$(cat .claude/ecc/VERSION)
    # 尝试从 package.json 读取期望版本
    if [ -f "package.json" ]; then
        EXPECTED_VERSION=$(node -e "try{const p=require('./package.json');console.log(p.eccVersion||'')}catch(e){console.log('')}" 2>/dev/null)
        if [ -n "$EXPECTED_VERSION" ] && [ "$ECC_VERSION" != "$EXPECTED_VERSION" ]; then
            ECC_VERSION_MISMATCH=1
        fi
    fi
fi

echo "ECC_INSTALLED=$ECC_INSTALLED"
echo "ECC_VERSION_MISMATCH=$ECC_VERSION_MISMATCH"
exit 0
