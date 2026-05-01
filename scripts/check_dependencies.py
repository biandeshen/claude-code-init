#!/usr/bin/env python3
"""
检查依赖方向是否违规

规则：
  可以通过 .dependency-rules.json 自定义规则
  默认规则：
    src/     → 不依赖 lib/
    lib/     → 可依赖 src/，不依赖其他 lib/
    tests/   → 可依赖 src/ 和 lib/

使用方式：
  python scripts/check_dependencies.py
  exit code 0 = 通过，非 0 = 有违规
"""

import ast
import json
import sys
from pathlib import Path

# Windows 编码修复（条件导入）
if sys.platform == "win32":
    import io as _io_module
    io = _io_module
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass  # 管道/重定向环境，保持默认编码

# 默认依赖方向规则
DEFAULT_RULES = {
    "src": {"forbidden": ["lib"]},
    "lib": {"forbidden": ["lib"]},  # lib 不依赖其他 lib
    "tests": {"forbidden": []},     # 测试可以依赖任意模块
}

CONFIG_FILE = ".dependency-rules.json"


def deep_merge(base: dict, override: dict) -> dict:
    """深度合并两个字典，嵌套的 dict 递归合并而非覆盖"""
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def load_rules() -> dict:
    """从配置文件加载规则，配置文件不存在则使用默认规则"""
    if Path(CONFIG_FILE).exists():
        try:
            with open(CONFIG_FILE, encoding="utf-8") as f:
                custom_rules = json.load(f)
            # 深度合并默认规则和自定义规则，避免浅覆盖
            return deep_merge(DEFAULT_RULES, custom_rules)
        except Exception as e:
            print(f"[WARN] 无法加载 {CONFIG_FILE}: {e}，使用默认规则")
    return DEFAULT_RULES


def get_imports(filepath: Path) -> list:
    """从 Python 文件中提取顶层 import"""
    imports = []
    try:
        with open(filepath, encoding="utf-8") as f:
            tree = ast.parse(f.read())
    except SyntaxError:
        return imports
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                imports.append(alias.name.split(".")[0])
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                imports.append(node.module.split(".")[0])
    return imports


def detect_module(filepath: Path) -> str:
    """根据文件路径检测所属模块"""
    parts = filepath.parts
    if not parts:
        return ""
    # 取第一个目录名作为模块名
    for part in parts:
        if part not in ["", ".", "..", "venv", ".venv", "__pycache__", "node_modules"]:
            return part
    return ""


def check_file(filepath: Path, rules: dict) -> list:
    """检查单个文件的依赖是否违规"""
    errors = []
    imports = get_imports(filepath)
    module = detect_module(filepath)
    forbidden = rules.get(module, {}).get("forbidden", [])

    for imp in imports:
        if imp in forbidden:
            errors.append(
                f"{filepath}: 不允许导入 {imp}/"
                f"（{module}/ 不应依赖 {imp}/）"
            )
    return errors


def main():
    rules = load_rules()
    errors = 0

    # 检查所有 Python 文件
    for py_file in Path(".").rglob("*.py"):
        # 跳过第三方和虚拟环境
        if any(skip in str(py_file) for skip in ["venv", ".venv", "__pycache__", "node_modules"]):
            continue
        if py_file.name.startswith("_"):
            continue

        file_errors = check_file(py_file, rules)
        for err in file_errors:
            print(f"[ERROR] {err}")
        errors += len(file_errors)

    if errors == 0:
        print("[OK] 依赖方向检查通过")
    sys.exit(errors)


if __name__ == "__main__":
    main()
