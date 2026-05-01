#!/usr/bin/env python3
"""
检查 import 语句顺序

规则：
  1. 标准库 (import os, sys 等)
  2. 第三方库 (import requests, numpy 等)
  3. 本地导入 (from . import x, from .. import x)

使用方式：
  python scripts/check_import_order.py
  exit code 0 = 通过，非 0 = 有违规
"""

import ast
import sys
from pathlib import Path
from collections import defaultdict
from typing import Optional, Tuple

# Python 标准库列表（完整）
STANDARD_LIBRARY = {
    # 核心
    "os", "sys", "builtins", "io",
    # 基础类型
    "bool", "int", "float", "str", "bytes", "bytearray", "list", "dict", "set", "tuple", "frozenset",
    # 常用模块
    "re", "json", "time", "datetime", "random", "math", "statistics",
    "collections", "itertools", "functools", "operator", "contextlib",
    "pathlib", "argparse", "getopt", "getpass", "optparse", "shlex",
    # 文件处理
    "shutil", "glob", "tempfile", "filecmp", "fileinput",
    # 类型
    "typing", "types", "abc", "copy", "pprint", "reprlib",
    # IO
    "io", "fileinput", "stat", "statvfs",
    # 文本
    "string", "textwrap", "unicodedata", "stringprep", "readline",
    # 格式化
    "xml", "csv", "html",
    # 网络
    "urllib", "http", "socket", "socketserver",
    # 安全 / 哈希
    "hashlib", "hmac", "secrets", "base64",
    # 标识
    "uuid",
    # 日期时间
    "calendar", "datetime",
    # 数字
    "decimal", "statistics", "fractions", "numbers",
    # 高级
    "logging", "traceback", "warnings",
    "threading", "multiprocessing", "concurrent", "asyncio",
    "subprocess", "sched", "queue", "_thread",
    # 程序生命周期
    "atexit", "sched",
    # 持久化
    "pickle", "copyreg", "shelve", "dbm", "sqlite3",
    "marshal", "gzip", "bz2", "lzma", "zipfile", "tarfile",
    # 压缩
    "zlib", "zipimport", "pkgutil", "modulefinder",
    # 运行
    "unittest", "doctest",
    "inspect", "dis", "compileall", "ast",
    # 其他
    "gc", "weakref", "enum", "dataclasses",
    "codecs", "locale", "gettext", "platform",
    "errno", "ctypes", "signal", "mmap", "resource",
    "ipaddress", "enum",
}

# 第三方库（可以通过配置文件扩展）
THIRD_PARTY = {
    "requests", "numpy", "pandas", "tensorflow", "torch", "keras",
    "flask", "django", "fastapi", "sanic", "bottle", "pyramid",
    "sqlalchemy", "psycopg2", "pymysql", "redis", "elasticsearch",
    "pydantic", "attrs", "dataclasses", "attrs",
    "pytest", "unittest", "mock", "coverage", "tox", "nox",
    "black", "flake8", "pylint", "ruff", "mypy", "bandit",
    "click", "typer", "rich", "colorama", "tqdm", "pillow",
    "yaml", "toml", "configparser", "dotenv",
    "aiohttp", "httpx", "websocket", "websockets",
    "celery", "rq", "huey", "dramatiq",
    "jinja2", "mako", "chevron", "markdown",
    "cryptography", "pyjwt", "passlib", "bcrypt",
    "pyppeteer", "playwright", "selenium", "beautifulsoup4",
    "lxml", "html5lib", "cssselect",
    "sqlparse", "pgcli", "mysqldcli",
    "fabric", "paramiko", "invoke", "pexpect",
    "chardet", "idna", "certifi", "urllib3",
}

# Windows 编码修复（条件导入）
if sys.platform == "win32":
    import io as _io_module
    io = _io_module
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


def get_import_category(imp: str) -> int:
    """获取导入的分类

    Returns:
        1 = 标准库
        2 = 第三方库
        3 = 本地导入
    """
    if imp.startswith("."):
        return 3
    if imp in STANDARD_LIBRARY:
        return 1
    if imp in THIRD_PARTY:
        return 2
    # 不在已知列表中的，检查是否是第三方库（通常是小写单词）
    if imp.islower() or "_" in imp:
        return 2
    return 1


def check_file_import_order(filepath: Path) -> list:
    """检查单个文件的 import 顺序"""
    errors = []
    try:
        with open(filepath, encoding="utf-8") as f:
            content = f.read()
            tree = ast.parse(content)
    except SyntaxError:
        return errors

    imports = []
    for node in ast.walk(tree):
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.append((node.lineno, get_import_category(alias.name.split(".")[0]), alias.name))
            else:  # ImportFrom
                module = node.module or ""
                imports.append((node.lineno, get_import_category(module.split(".")[0]), f"from {module}"))

    # 检查顺序
    current_category = 0
    for lineno, category, name in imports:
        if current_category == 0:
            current_category = category
        elif category < current_category:
            errors.append(
                f"{filepath}:{lineno} import 顺序错误\n"
                f"   导入 '{name}' 的分类 ({category}) 小于前面的分类 ({current_category})"
            )
        elif category > current_category:
            current_category = category

    return errors


def main():
    errors = 0
    for py_file in Path(".").rglob("*.py"):
        # 跳过第三方和虚拟环境
        if any(skip in str(py_file) for skip in ["venv", ".venv", "__pycache__", "node_modules"]):
            continue
        if py_file.name.startswith("_"):
            continue

        file_errors = check_file_import_order(py_file)
        for err in file_errors:
            print(f"[WARN] {err}")
        errors += len(file_errors)

    if errors == 0:
        print("[OK] import 顺序检查通过")
    sys.exit(errors)


if __name__ == "__main__":
    main()
