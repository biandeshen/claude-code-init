#!/usr/bin/env python3
"""Cross-reference consistency checker for claude-code-init documentation."""

import os
import re
import sys
import io

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))

ISSUES = 0


def warn(msg):
    global ISSUES
    ISSUES += 1
    print(f"  [WARN] {msg}")


def ok(msg):
    print(f"  [OK]   {msg}")


def check_help_commands():
    print("\n[1] help.md command completeness")
    cmds_dir = os.path.join(PROJECT_ROOT, "commands")
    if not os.path.isdir(cmds_dir):
        warn("commands/ directory not found")
        return
    actual = sorted(f.replace(".md", "") for f in os.listdir(cmds_dir)
                    if f.endswith(".md"))
    help_path = os.path.join(cmds_dir, "help.md")
    if not os.path.isfile(help_path):
        warn("commands/help.md not found")
        return
    with open(help_path, "r", encoding="utf-8") as f:
        content = f.read()
    mentioned = set(re.findall(r'/([a-z][a-z0-9-]*)', content))
    missing = [c for c in actual if c not in mentioned and c != "help"]
    for c in missing:
        warn(f"help.md missing command: /{c}")
    if not missing:
        ok("help.md covers all commands")


def check_command_refs():
    print("\n[2] Command cross-reference validity")
    cmds_dir = os.path.join(PROJECT_ROOT, "commands")
    all_cmds = set(f.replace(".md", "") for f in os.listdir(cmds_dir)
                   if f.endswith(".md"))
    for fname in os.listdir(cmds_dir):
        if not fname.endswith(".md"):
            continue
        fpath = os.path.join(cmds_dir, fname)
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
        refs = set(re.findall(r'/([a-z][a-z0-9-]*)', content))
        for ref in refs:
            if ref not in all_cmds:
                warn(f"commands/{fname} references non-existent /{ref}")
    ok("command cross-reference check done")


def check_guide_commands():
    print("\n[3] GUIDE.md command table completeness")
    guide_path = os.path.join(PROJECT_ROOT, "GUIDE.md")
    cmds_dir = os.path.join(PROJECT_ROOT, "commands")
    if not os.path.isfile(guide_path):
        warn("GUIDE.md not found")
        return
    actual = set(f.replace(".md", "") for f in os.listdir(cmds_dir)
                 if f.endswith(".md"))
    with open(guide_path, "r", encoding="utf-8") as f:
        content = f.read()
    guide_cmds = set(re.findall(r'/[a-z]?\s*`/([a-z][a-z0-9-]*)`', content))
    missing = actual - guide_cmds
    for c in sorted(missing):
        warn(f"GUIDE.md command table missing /{c}")
    if not missing:
        ok("GUIDE.md command table matches commands/ directory")


def check_guide_structure():
    print("\n[4] GUIDE.md repository structure completeness")
    guide_path = os.path.join(PROJECT_ROOT, "GUIDE.md")
    if not os.path.isfile(guide_path):
        return
    with open(guide_path, "r", encoding="utf-8") as f:
        content = f.read()
    struct_match = re.search(
        r'```\n(claude-code-init/\n.*?)```', content, re.DOTALL)
    if not struct_match:
        warn("No repository structure code block in GUIDE.md")
        return
    structure = struct_match.group(1)
    for d in ["commands/", "templates/", "docs/", "scripts/", "configs/"]:
        if d not in structure:
            warn(f"GUIDE.md structure missing {d}")
    docs_dir = os.path.join(PROJECT_ROOT, "docs")
    if os.path.isdir(docs_dir):
        for f in sorted(os.listdir(docs_dir)):
            if f.endswith(".md") and f not in structure:
                warn(f"GUIDE.md structure missing docs/{f}")
    ok("GUIDE.md structure check done")


def check_stale_paths():
    print("\n[5] Stale path reference check (reports/ vs .claude/reports/)")
    # Match bare reports/ not preceded by .claude/
    reports_old = re.compile(r'(?<![a-z/])reports/(task|summary|blocked|overlimit)')
    files_to_check = []
    for root_dir in ["commands", ".claude/scripts", ".claude/skills"]:
        rd = os.path.join(PROJECT_ROOT, root_dir)
        if not os.path.isdir(rd):
            continue
        for dirpath, _, filenames in os.walk(rd):
            for fn in filenames:
                if fn.endswith(".md"):
                    files_to_check.append(os.path.join(dirpath, fn))
    found = False
    for fpath in files_to_check:
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
        matches = reports_old.findall(content)
        if matches:
            rel = os.path.relpath(fpath, PROJECT_ROOT)
            found = True
            warn(f"{rel} uses old path reports/ "
                 f"(should be .claude/reports/): {set(matches)}")
    if not found:
        ok("all report paths use .claude/reports/")


def check_template_versions():
    print("\n[6] Template version header completeness")
    tmpl_dir = os.path.join(PROJECT_ROOT, "templates")
    if not os.path.isdir(tmpl_dir):
        warn("templates/ directory not found")
        return
    all_ok_flag = True
    for fn in sorted(os.listdir(tmpl_dir)):
        if not fn.endswith(".md"):
            continue
        fpath = os.path.join(tmpl_dir, fn)
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
        if "模板版本：" not in content:
            warn(f"{fn} missing template version header")
            all_ok_flag = False
    if all_ok_flag:
        ok("all templates have version headers")


def main():
    print("=" * 50)
    print("Document Cross-Reference Consistency Check")
    print("=" * 50)
    check_help_commands()
    check_command_refs()
    check_guide_commands()
    check_guide_structure()
    check_stale_paths()
    check_template_versions()
    print("\n" + "=" * 50)
    if ISSUES == 0:
        print("All checks passed")
    else:
        print(f"Found {ISSUES} issue(s)")
    print("=" * 50)
    sys.exit(1 if ISSUES > 0 else 0)


if __name__ == "__main__":
    main()
