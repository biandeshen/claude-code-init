import os
BASE = r"e:\工具\claude-code-init"
skill = "brainstorming"
path = os.path.join(BASE, ".claude", "skills", skill, "SKILL.md")
with open(path, "rb") as f:
    c = f.read()
print("has version:", b"version: 1.0.0" in c)
print("has lastUpdated:", b"lastUpdated: 2026-05-01" in c)
print("first 150:", c[:150])
