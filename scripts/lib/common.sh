#!/bin/bash
# scripts/lib/common.sh
# 公共函数库，供所有脚本 source 使用
# 版本: v1.0.0 | 2026-04-30

# ─── 技术栈检测 ───
# 返回项目使用的技术栈：Python / JS/TS / Python + JS/TS / General
check_stack() {
    local stack=""
    if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || ls *.py >/dev/null 2>&1; then
        stack="Python"
    fi
    if [ -f "package.json" ] || ls *.ts >/dev/null 2>&1; then
        if [ -n "$stack" ]; then
            stack="$stack + JS/TS"
        else
            stack="JS/TS"
        fi
    fi
    [ -z "$stack" ] && stack="General"
    echo "$stack"
}

# ─── 颜色输出 ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 输出函数
echo_step() { echo -e "${CYAN}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
echo_fail() { echo -e "${RED}[失败]${NC} $1"; }
echo_info() { echo -e "[信息] $1"; }
