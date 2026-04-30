#!/usr/bin/env python3
"""
检查项目结构完整性

规则：
  1. 必须存在 CLAUDE.md
  2. 如果存在 src/ 目录，应存在 tests/ 目录
  3. 如果存在 package.json，应存在 .gitignore
  4. 如果存在 requirements.txt 或 pyproject.toml，应存在 venv/ 在 .gitignore 中

使用方式：
  python scripts/check_project_structure.py
  exit code 0 = 通过，非 0 = 有违规
"""

import sys
from pathlib import Path

# Windows 编码修复
if sys.platform == "win32":
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


def check_claude_md() -> list:
    """检查 CLAUDE.md 是否存在"""
    errors = []
    if not Path("CLAUDE.md").exists():
        errors.append("[WARN] 缺少 CLAUDE.md - Claude Code 规范文件")
    return errors


def check_test_directory() -> list:
    """检查 tests/ 目录是否存在（如果 src/ 存在）"""
    errors = []
    if Path("src").exists() and not Path("tests").exists():
        errors.append("[WARN] 存在 src/ 但缺少 tests/ 目录")
    if Path("src").exists() and not Path("src/__init__.py").exists():
        errors.append("[WARN] src/ 目录缺少 __init__.py")
    return errors


def check_gitignore() -> list:
    """检查必要的 .gitignore 条目"""
    errors = []
    gitignore_path = Path(".gitignore")

    if not gitignore_path.exists():
        # 检查是否已经有 .git 目录
        if Path(".git").exists():
            errors.append("[ERROR] 缺少 .gitignore 文件")
        return errors

    gitignore_content = gitignore_path.read_text(encoding="utf-8")

    # 检查常见应该被忽略的目录/文件
    recommended_ignores = {
        "__pycache__": "Python 字节码缓存",
        "*.pyc": "Python 编译文件",
        ".venv": "Python 虚拟环境",
        "venv": "Python 虚拟环境",
        ".env": "环境变量文件",
        "node_modules": "Node.js 依赖",
    }

    missing = []
    for item, desc in recommended_ignores.items():
        if item not in gitignore_content:
            # 通配符条目（如 *.pyc）：直接建议加入 gitignore
            if "*" in item:
                missing.append(f"{item} ({desc})")
            # 字面路径条目：仅在文件系统实际存在时提醒
            elif Path(item).exists():
                missing.append(f"{item} ({desc})")

    if missing:
        errors.append(f"[WARN] .gitignore 缺少建议的条目: {', '.join(missing)}")

    return errors


def check_dependencies() -> list:
    """检查依赖文件一致性"""
    errors = []

    has_pyproject = Path("pyproject.toml").exists()
    has_requirements = Path("requirements.txt").exists()
    has_pipfile = Path("Pipfile").exists()
    has_package_json = Path("package.json").exists()

    # Python 项目
    if has_pyproject and has_requirements:
        errors.append("[WARN] 同时存在 pyproject.toml 和 requirements.txt，建议只保留一个")

    # Node.js 项目
    if has_package_json and not Path("package-lock.json").exists() and not Path("yarn.lock").exists():
        errors.append("[INFO] package.json 存在但缺少锁文件 (package-lock.json 或 yarn.lock)")

    return errors


def main():
    errors = []

    errors.extend(check_claude_md())
    errors.extend(check_test_directory())
    errors.extend(check_gitignore())
    errors.extend(check_dependencies())

    for error in errors:
        print(error)

    if not errors:
        print("[OK] 项目结构检查通过")

    # 返回错误数量，但不将警告视为失败
    critical_errors = sum(1 for e in errors if "[ERROR]" in e)
    sys.exit(critical_errors)


if __name__ == "__main__":
    main()
