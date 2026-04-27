#!/usr/bin/env python3
"""
密钥检测脚本 - pre-commit hook

功能：
    1. 检测 config.yaml 中的硬编码密钥
    2. 检测 .env 文件是否被提交
    3. 检测代码中的硬编码密钥

使用方式：
    python scripts/check_secrets.py
    # 或作为 pre-commit hook 自动运行

Author: Claude Code Init
Version: 1.0.0
"""

import re
import sys
from pathlib import Path

# 敏感字段关键词
SENSITIVE_KEYWORDS = [
    "api_key", "apikey", "api-key",
    "secret", "password", "passwd", "pwd",
    "token", "access_token", "refresh_token",
    "private_key", "credential",
]

# 真实密钥的特征（非示例值）
SECRET_PATTERNS = [
    r"sk-[a-zA-Z0-9]{20,}",           # OpenAI 格式
    r"sk-ant-[a-zA-Z0-9]{20,}",        # Anthropic 格式
    r"[a-f0-9]{32,}",                   # 32位+ hex
    r"[a-zA-Z0-9]{40,}",                # 40位+ 字符串
]

# 白名单（允许的值）- 使用子串匹配
WHITELIST = [
    "${",           # 环境变量引用
    "your_",       # your_secret_key
    "your_secret",
    "xxx",         # xxx_api_key
    "placeholder",  # 占位符
    "example",      # example_key
    "changeme",    # changeme_password
    "test_",        # test_token
    "dummy",        # dummy_key
    "localhost",    # 本地地址
    "127.0.0.1",   # 本地地址
    "::1",          # IPv6 本地地址
]


def check_config_file(file_path: str) -> list:
    """检查配置文件中的硬编码密钥"""
    errors = []

    try:
        with open(file_path, encoding="utf-8") as f:
            content = f.read()
            lines = content.split("\n")

        for i, line in enumerate(lines, 1):
            # 跳过注释
            if line.strip().startswith("#"):
                continue

            # 检查是否包含敏感字段
            line_lower = line.lower()
            is_sensitive = any(keyword in line_lower for keyword in SENSITIVE_KEYWORDS)

            if is_sensitive:
                # 检查值部分
                if ":" in line:
                    key, value = line.split(":", 1)
                    value = value.strip().strip('"').strip("'")

                    # 跳过白名单
                    if any(wl in value for wl in WHITELIST):
                        continue

                    # 跳过空值
                    if not value:
                        continue

                    # 检查是否是真实密钥
                    for pattern in SECRET_PATTERNS:
                        if re.search(pattern, value):
                            errors.append(
                                f"[ERROR] {file_path}:{i} - 检测到硬编码密钥\n"
                                f"   行内容: {line.strip()}\n"
                                f"   建议: 改为 {key.strip()}: \"${{{key.strip().upper()}}}\"\n"
                            )
                            break

    except Exception as e:
        print(f"检查文件失败 {file_path}: {e}")

    return errors


def check_env_committed():
    """检查 .env 文件是否被提交"""
    errors = []

    env_files = [".env", ".env.local", ".env.production", ".env.development"]
    gitignore_path = Path(".gitignore")

    if gitignore_path.exists():
        gitignore_content = gitignore_path.read_text()
        for env_file in env_files:
            if env_file not in gitignore_content:
                errors.append(
                    f"[ERROR] .gitignore 中缺少 {env_file}\n"
                    f"   建议: 添加 {env_file} 到 .gitignore\n"
                )

    return errors


def check_python_files(file_paths: list) -> list:
    """检查 Python 文件中的硬编码密钥"""
    errors = []

    for file_path in file_paths:
        if not file_path.endswith(".py"):
            continue

        try:
            with open(file_path, encoding="utf-8") as f:
                content = f.read()
                lines = content.split("\n")

            for i, line in enumerate(lines, 1):
                # 跳过注释
                if line.strip().startswith("#"):
                    continue

                # 检查是否包含敏感字段赋值
                line_lower = line.lower()
                is_sensitive = any(keyword in line_lower for keyword in SENSITIVE_KEYWORDS)

                if is_sensitive and "=" in line:
                    # 检查值部分
                    parts = line.split("=", 1)
                    if len(parts) == 2:
                        value = parts[1].strip().strip('"').strip("'")

                        # 跳过白名单（子串匹配，不区分大小写）
                        value_lower = value.lower()
                        if any(wl.lower() in value_lower for wl in WHITELIST):
                            continue

                        # 跳过空值和 os.environ 调用
                        if not value or "os.environ" in value:
                            continue

                        # 检查是否是真实密钥
                        for pattern in SECRET_PATTERNS:
                            if re.search(pattern, value):
                                errors.append(
                                    f"[ERROR] {file_path}:{i} - 检测到硬编码密钥\n"
                                    f"   行内容: {line.strip()}\n"
                                    f"   建议: 使用 os.environ.get() 或 config_loader\n"
                                )
                                break

        except Exception:
            pass

    return errors


def main():
    """主函数"""
    errors = []

    # 1. 检查配置文件
    config_files = list(Path("config").glob("*.yaml")) + list(Path("config").glob("*.yml"))
    for config_file in config_files:
        errors.extend(check_config_file(str(config_file)))

    # 2. 检查根目录的 config.yaml
    if Path("config.yaml").exists():
        errors.extend(check_config_file("config.yaml"))

    # 3. 检查 .env 是否被 gitignore
    errors.extend(check_env_committed())

    # 4. 检查 Python 文件（仅检查暂存区的文件）
    import subprocess
    try:
        result = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
            capture_output=True, text=True, encoding="utf-8"
        )
        staged_files = result.stdout.strip().split("\n")
        if staged_files and staged_files[0]:
            errors.extend(check_python_files(staged_files))
    except Exception:
        pass

    # 输出结果
    if errors:
        print("\n" + "=" * 60)
        print("[SECURITY] 密钥安全检查失败")
        print("=" * 60 + "\n")
        for error in errors:
            print(error)
        print("=" * 60)
        print("请修复上述问题后重新提交")
        print("=" * 60 + "\n")
        return 1
    else:
        print("[OK] 密钥安全检查通过")
        return 0


if __name__ == "__main__":
    sys.exit(main())
