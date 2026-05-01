#!/usr/bin/env python3
"""Path consistency checker: init scripts ↔ gitignore rules ↔ cross-platform.

Checks that every file created by init.sh/init.ps1 is covered by corresponding
gitignore rules, and that symmetric files (e.g. CLAUDE.local.md / MEMORY.local.md)
have consistent paths.
"""

import os
import re
import sys
import io

if sys.platform == 'win32':
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass
    try:
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

ISSUES = 0


def warn(msg):
    global ISSUES
    ISSUES += 1
    print(f"  [WARN] {msg}")


def ok(msg):
    print(f"  [OK]   {msg}")


def fail(msg):
    global ISSUES
    ISSUES += 1
    print(f"  [FAIL] {msg}")


# ── file reading ──────────────────────────────────────────────

def read_file(relpath):
    fpath = os.path.join(PROJECT_ROOT, relpath)
    if not os.path.isfile(fpath):
        return ""
    with open(fpath, "r", encoding="utf-8") as f:
        return f.read()


# ── 1. extract target paths from init.sh ──────────────────────

def extract_init_sh_paths():
    """Parse init.sh for all $PROJECT_PATH/... target paths."""
    content = read_file("init.sh")
    paths = set()

    # cat > "$PROJECT_PATH/..."
    # copy_template ... "$PROJECT_PATH/..." ...
    # mkdir -p "$PROJECT_PATH/..."
    # cp ... "$PROJECT_PATH/..."
    # git clone ... "$PROJECT_PATH/..."

    for m in re.finditer(r'\$PROJECT_PATH/(\.claude/[^\s"$]+)', content):
        paths.add(m.group(1))

    # Also catch root-level paths: $PROJECT_PATH/CLAUDE.md etc
    for m in re.finditer(r'\$PROJECT_PATH/([^\s"$]+)', content):
        path = m.group(1)
        # Skip variable-referenced ones like $PROJECT_PATH/$SUPERPOWERS_DIR
        if '$' not in path:
            paths.add(path)

    return sorted(paths)


# ── 2. extract target paths from init.ps1 ─────────────────────

def extract_init_ps1_paths():
    """Parse init.ps1 for all $ProjectPath paths."""
    content = read_file("init.ps1")
    paths = set()

    # Out-File -FilePath "$ProjectPath\..."
    # Copy-Template ... "$ProjectPath\..." ...
    # New-Item ... "$ProjectPath\..." ...
    # Copy-Item ... "$ProjectPath\..." ...

    for m in re.finditer(r'\$ProjectPath\\(\.claude\\[^\s"$)]+)', content):
        paths.add(m.group(1).replace('\\', '/'))

    for m in re.finditer(r'\$ProjectPath\\([^\s"$)]+)', content):
        path = m.group(1).replace('\\', '/')
        if '$' not in path and not path.endswith('"'):
            paths.add(path)

    return sorted(paths)


# ── 3. extract gitignore rules ────────────────────────────────

def extract_gitignore_rules(sh_path, ps_path):
    """Extract gitignore rules (per-option blocks) from both scripts."""
    rules = {"sh": {"1": [], "2": [], "3": [], "default": []},
             "ps1": {"1": [], "2": [], "3": [], "default": []}}

    # parse configure-gitignore.sh
    content = read_file(sh_path)
    current_option = None
    in_rules = False
    for line in content.splitlines():
        m = re.match(r'\s*(\d)\)', line)
        if m:
            current_option = m.group(1)
            in_rules = True
            continue
        m = re.match(r'\s*\*\)', line)
        if m:
            current_option = "default"
            in_rules = True
            continue
        m = re.match(r'\s*;;', line)
        if m:
            in_rules = False
            current_option = None
            continue
        if in_rules and current_option:
            stripped = line.strip()
            if stripped and not stripped.startswith('"') and not stripped.startswith('#'):
                # Handle "rules=" line with heredoc
                pass
            # lines are direct gitignore entries
            if stripped and not stripped.startswith('#') and not stripped.startswith('"') and not stripped.startswith('rules=') and not stripped.startswith('echo_'):
                rules["sh"][current_option].append(stripped)

    # parse configure-gitignore.ps1
    content = read_file(ps_path)
    current_option = None
    for line in content.splitlines():
        m = re.match(r'\s*"(\d)"\s*\{', line)
        if m:
            current_option = m.group(1)
            continue
        m = re.match(r'\s*default\s*\{', line)
        if m:
            current_option = "default"
            continue
        m = re.match(r'\s*\}', line)
        if m:
            current_option = None
            continue
        if current_option:
            m = re.match(r'\s*"([^"]+)"', line)
            if m:
                rules["ps1"][current_option].append(m.group(1))

    # Also extract heredoc rules from sh
    content = read_file(sh_path)
    for m in re.finditer(r'rules="# === claude-code-init ===(.*?)=== claude-code-init ==="', content, re.DOTALL):
        block = m.group(1).strip()
        for entry in block.splitlines():
            entry = entry.strip()
            if entry and not entry.startswith('#'):
                # Determine which option this heredoc belongs to
                pass  # already covered by the line-based parser above

    return rules


# ── 4. cross-reference checks ─────────────────────────────────

def check_symmetric_paths(init_sh_paths, init_ps1_paths):
    """Verify CLAUDE.local.md and MEMORY.local.md are at same directory level."""
    print("\n[1] Symmetric path check (CLAUDE.local.md ↔ MEMORY.local.md)")

    sh_claude = [p for p in init_sh_paths if p.endswith("CLAUDE.local.md")]
    sh_memory = [p for p in init_sh_paths if p.endswith("MEMORY.local.md")]
    ps_claude = [p for p in init_ps1_paths if p.endswith("CLAUDE.local.md")]
    ps_memory = [p for p in init_ps1_paths if p.endswith("MEMORY.local.md")]

    # Both should be in .claude/
    for label, paths in [("init.sh", sh_claude), ("init.sh", sh_memory),
                          ("init.ps1", ps_claude), ("init.ps1", ps_memory)]:
        if not paths:
            fail(f"{label}: {label.split('.')[-1]} path not found in extracted paths")
            continue

    if sh_claude and sh_memory:
        claude_dir = os.path.dirname(sh_claude[0])
        memory_dir = os.path.dirname(sh_memory[0])
        if claude_dir == memory_dir:
            ok(f"init.sh: both in .claude/ ({claude_dir})")
        else:
            fail(f"init.sh path asymmetry: CLAUDE.local.md in {claude_dir}, "
                 f"MEMORY.local.md in {memory_dir}")

    if ps_claude and ps_memory:
        claude_dir = os.path.dirname(ps_claude[0])
        memory_dir = os.path.dirname(ps_memory[0])
        if claude_dir == memory_dir:
            ok(f"init.ps1: both in .claude/ ({claude_dir})")
        else:
            fail(f"init.ps1 path asymmetry: CLAUDE.local.md in {claude_dir}, "
                 f"MEMORY.local.md in {memory_dir}")


def check_gitignore_coverage(init_sh_paths, init_ps1_paths):
    """For each option, verify MEMORY.local.md is covered by gitignore rules."""
    print("\n[2] Gitignore coverage check (MEMORY.local.md per option)")

    rules = extract_gitignore_rules(
        "scripts/configure-gitignore.sh",
        "scripts/configure-gitignore.ps1"
    )

    local_files = [".claude/CLAUDE.local.md", ".claude/MEMORY.local.md"]

    for script_name in ["sh", "ps1"]:
        for option in ["1", "2", "3", "default"]:
            script_rules = rules[script_name].get(option, [])
            for lf in local_files:
                # Check if the file is covered by any rule
                covered = False
                for rule in script_rules:
                    if rule == lf:
                        covered = True
                        break
                    # Directory rule covers all files under it
                    if rule.endswith('/') and lf.startswith(rule):
                        covered = True
                        break
                if covered:
                    ok(f"configure-gitignore.{script_name} option {option}: "
                       f"{lf} covered")
                else:
                    fail(f"configure-gitignore.{script_name} option {option}: "
                         f"{lf} NOT covered by any rule. "
                         f"Rules: {script_rules}")


def check_template_dest_consistency():
    """Verify template destination paths match between init.sh and init.ps1."""
    print("\n[3] Template destination path consistency")

    sh_content = read_file("init.sh")
    ps_content = read_file("init.ps1")

    # Extract copy_template destinations from init.sh
    sh_dests = {}
    for m in re.finditer(
            r'copy_template\s+"\$TEMPLATE_DIR/([^"]+)"\s+'
            r'"\$PROJECT_PATH/([^"]+)"\s+"([^"]+)"',
            sh_content):
        template = m.group(1)
        dest = m.group(2)
        sh_dests[template] = dest

    # Extract Copy-Template destinations from init.ps1
    ps_dests = {}
    for m in re.finditer(
            r'Copy-Template\s+\(Join-Path\s+\$TemplateDir\s+"([^"]+)"\)\s+'
            r'"\$ProjectPath\\([^"]+)"\s+"([^"]+)"',
            ps_content):
        template = m.group(1)
        dest = m.group(2).replace('\\', '/')
        ps_dests[template] = dest

    all_templates = set(list(sh_dests.keys()) + list(ps_dests.keys()))
    consistent = True
    for tpl in sorted(all_templates):
        sh_dest = sh_dests.get(tpl, "MISSING")
        ps_dest = ps_dests.get(tpl, "MISSING")
        if sh_dest == "MISSING":
            fail(f"Template {tpl} only in init.ps1, missing from init.sh")
            consistent = False
        elif ps_dest == "MISSING":
            fail(f"Template {tpl} only in init.sh, missing from init.ps1")
            consistent = False
        elif sh_dest != ps_dest:
            fail(f"Template {tpl}: init.sh → {sh_dest}, "
                 f"init.ps1 → {ps_dest} (MISMATCH)")
            consistent = False
        else:
            ok(f"Template {tpl}: both → {sh_dest}")

    if consistent:
        ok("all template destinations match across platforms")


def check_plan_template_filename():
    """Verify PLAN_Template.md has no case-sensitivity issues in gitignore rules."""
    print("\n[4] PLAN_Template.md case-sensitivity check")

    for script in ["scripts/configure-gitignore.sh",
                    "scripts/configure-gitignore.ps1"]:
        content = read_file(script)
        if "PLAN_TEMPLATE.md" in content:
            fail(f"{script}: found PLAN_TEMPLATE.md (all-caps) "
                 f"but actual file is PLAN_Template.md — "
                 f"case mismatch on case-sensitive filesystems")
        else:
            ok(f"{script}: uses correct case PLAN_Template.md")


def check_version_consistency():
    """Verify version strings match across all files."""
    print("\n[5] Version string consistency")

    files_to_check = [
        ("init.sh", r'版本:\s*(v?\d+\.\d+\.\d+)'),
        ("init.ps1", r'版本:\s*(v?\d+\.\d+\.\d+)'),
        ("CLAUDE.md", r'版本：\s*(v?\d+\.\d+\.\d+)'),
        ("SOUL.md", r'版本：\s*(v?\d+\.\d+\.\d+)'),
        ("docs/HANDOVER.md", r'版本：\s*(v?\d+\.\d+\.\d+)'),
    ]

    versions = {}
    for filepath, pattern in files_to_check:
        content = read_file(filepath)
        m = re.search(pattern, content)
        if m:
            versions[filepath] = m.group(1).lstrip('v')
        else:
            warn(f"{filepath}: no version string found")

    if len(set(versions.values())) <= 1:
        ok(f"all files agree on version {list(versions.values())[0]}")
    else:
        for fp, v in versions.items():
            fail(f"{fp}: version {v}")


def main():
    print("=" * 50)
    print("Path Consistency Check (init ↔ gitignore ↔ platforms)")
    print("=" * 50)

    init_sh_paths = extract_init_sh_paths()
    init_ps1_paths = extract_init_ps1_paths()

    check_symmetric_paths(init_sh_paths, init_ps1_paths)
    check_gitignore_coverage(init_sh_paths, init_ps1_paths)
    check_template_dest_consistency()
    check_plan_template_filename()
    check_version_consistency()

    print("\n" + "=" * 50)
    if ISSUES == 0:
        print("All path consistency checks passed")
    else:
        print(f"Found {ISSUES} issue(s)")
    print("=" * 50)
    sys.exit(1 if ISSUES > 0 else 0)


if __name__ == "__main__":
    main()
