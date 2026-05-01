#!/usr/bin/env python3
"""
check_trigger_conflicts.py
检查所有 Skills 的触发词是否存在冲突。

当前 SKILL.md 中触发词位于 description 字段的自然语言中，
格式为：中文触发词：审查、检查、review...

运行方式: python3 scripts/check_trigger_conflicts.py
退出码: 0=通过, 1=发现冲突
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

SKILLS_DIR = Path(__file__).resolve().parent.parent / ".claude/skills"
# 匹配 "中文触发词：xxx、xxx" 或 "中文触发词：xxx, xxx" 模式
TRIGGER_PATTERN = re.compile(
    r'中文触发词[：:]\s*([^。\n]+)',
    re.IGNORECASE
)
# 匹配用中文顿号(、)或英文逗号(,)或空格分隔的关键词
KEYWORD_SPLIT = re.compile(r'[、,，\s]+')


def extract_triggers(content: str) -> list[str]:
    """从 SKILL.md 内容中提取触发词"""
    triggers = []

    # 从 "中文触发词：" 声明中提取
    for match in TRIGGER_PATTERN.finditer(content):
        raw = match.group(1).strip()
        keywords = [k.strip() for k in KEYWORD_SPLIT.split(raw) if k.strip()]
        for kw in keywords:
            if len(kw) >= 2:
                triggers.append(kw.lower())

    return triggers


def main() -> int:
    print("检查 Skills 触发词冲突...")

    if not SKILLS_DIR.exists():
        print(f"错误: {SKILLS_DIR} 目录不存在")
        return 1

    trigger_map: dict[str, list[str]] = defaultdict(list)

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue

        content = skill_md.read_text(encoding="utf-8")
        triggers = extract_triggers(content)
        for trigger in triggers:
            trigger_map[trigger].append(skill_dir.name)

    print(f"已扫描 {len(trigger_map)} 个唯一触发词")

    # 检测跨 Skill 冲突
    conflicts = []
    for trigger, skills in trigger_map.items():
        unique_skills = list(set(skills))
        if len(unique_skills) > 1:
            conflicts.append((trigger, unique_skills))

    if conflicts:
        print(f"\n发现 {len(conflicts)} 个触发词冲突：")
        for trigger, skills in conflicts:
            skills_str = ", ".join(skills)
            print(f"  触发词: '{trigger}' 冲突于: [{skills_str}]")
        return 1

    print("\n触发词检查通过，无冲突")
    return 0


if __name__ == "__main__":
    sys.exit(main())
