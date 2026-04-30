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

# 尝试导入 yaml（如果不可用则回退到逐行解析）
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

# 敏感字段关键词
SENSITIVE_KEYWORDS = [
    "api_key", "apikey", "api-key",
    "secret", "password", "passwd", "pwd",
    "token", "access_token", "refresh_token",
    "private_key", "credential",
]

# 真实密钥的特征（非示例值）
SECRET_PATTERNS = [
    r"sk-[a-zA-Z0-9]{20,}",              # OpenAI API Key
    r"sk-ant-[a-zA-Z0-9]{20,}",           # Anthropic API Key
    r"ghp_[a-zA-Z0-9]{36}",               # GitHub Personal Access Token
    r"github_pat_[a-zA-Z0-9]{22,}",       # GitHub Fine-grained Token
    r"glpat-[a-zA-Z0-9]{20,}",            # GitLab Personal Access Token
    r"AKIA[0-9A-Z]{16}",                  # AWS Access Key ID
    r"eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}",  # JWT Token
    r"-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----",  # Private Key Block
]

# 白名单（允许的值）
# 这些是明确的占位符示例值，不是真实密钥

# 精确匹配的白名单项
WHITELIST_EXACT = [
    "your_secret",     # 完整占位符
    "your_api_key",
    "your_password",
    "your_token",
    "your_key",
    "xxx",             # xxx_api_key
    "placeholder",     # 占位符
    "example",         # example_key
    "changeme",        # changeme_password
    "dummy",           # dummy_key
    "localhost",        # 本地地址
    "127.0.0.1",       # 本地地址
    "::1",             # IPv6 本地地址
]

# 前缀匹配的白名单项（允许以这些前缀开头的值）
WHITELIST_PREFIX = ["test_", "${", "$env:"]


def is_whitelisted(value: str) -> bool:
    """检查值是否在白名单中"""
    value_lower = value.lower()

    # 精确匹配
    if value_lower in [w.lower() for w in WHITELIST_EXACT]:
        return True

    # 前缀匹配
    for prefix in WHITELIST_PREFIX:
        if value_lower.startswith(prefix.lower()):
            return True

    return False


def _walk_yaml(obj, path="", errors=None, file_path=""):
    """递归遍历 YAML 结构查找敏感字段"""
    if errors is None:
        errors = []

    if isinstance(obj, dict):
        for key, value in obj.items():
            key_str = str(key).lower()
            new_path = f"{path}.{key}" if path else str(key)
            if isinstance(value, (dict, list)):
                _walk_yaml(value, new_path, errors, file_path)
            else:
                is_sensitive = any(kw in key_str for kw in SENSITIVE_KEYWORDS)
                if is_sensitive and isinstance(value, str) and value:
                    if not is_whitelisted(value):
                        for pattern in SECRET_PATTERNS:
                            if re.search(pattern, value):
                                errors.append(
                                    f"[ERROR] {file_path}:{new_path} - 检测到硬编码密钥\n"
                                    f"   字段: {key}\n"
                                    f"   建议: 改为环境变量引用\n"
                                )
                                break
    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            if isinstance(item, dict):
                _walk_yaml(item, f"{path}[{idx}]", errors, file_path)

    return errors


def check_config_file(file_path: str) -> list:
    """检查配置文件中的硬编码密钥（支持 YAML 递归解析）"""
    errors = []

    if HAS_YAML:
        try:
            with open(file_path, encoding="utf-8") as f:
                config = yaml.safe_load(f)

            if isinstance(config, (dict, list)):
                errors = _walk_yaml(config, file_path=file_path)
                return errors
        except (yaml.YAMLError, Exception):
            # YAML 解析失败，回退到逐行检查
            pass

    # 回退：逐行检查（原有逻辑，兼容非 YAML 文件）
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
                    if is_whitelisted(value):
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

                        # 跳过白名单
                        if is_whitelisted(value):
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
