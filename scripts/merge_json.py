#!/usr/bin/env python3
"""
merge_json.py — 合并 claude-code-init 的 settings.json 到目标项目配置中

用法: python3 merge_json.py <source.json> <target.json>

合并规则:
- env: 新增源中存在的 key（不覆盖目标中已有的同名 key）
- hooks: 按 (matcher, command) 去重后追加，保留目标中已有的 hooks

退出码:
  0 - 成功
  1 - 参数错误
  2 - 文件读取 / JSON 解析错误
  3 - 写入错误
"""

import json
import sys
import os
import io

# 强制 stdout 使用 UTF-8（防止通过 PowerShell 管道时中文乱码）
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


def merge_settings(source_path, target_path):
    """合并 source 的 env + hooks 到 target 中，写回 target。"""

    # 读取源文件
    try:
        with open(source_path, encoding='utf-8-sig') as f:
            src = json.load(f)
    except FileNotFoundError:
        print(f"merge_json: 源文件不存在: {source_path}", file=sys.stderr)
        sys.exit(2)
    except json.JSONDecodeError as e:
        print(f"merge_json: 源文件 JSON 解析失败: {source_path}\n  {e}", file=sys.stderr)
        sys.exit(2)
    except OSError as e:
        print(f"merge_json: 无法读取源文件: {source_path}\n  {e}", file=sys.stderr)
        sys.exit(2)

    # 读取目标文件
    try:
        with open(target_path, encoding='utf-8-sig') as f:
            tgt = json.load(f)
    except FileNotFoundError:
        # 目标不存在时直接复制源
        os.makedirs(os.path.dirname(target_path) or '.', exist_ok=True)
        with open(target_path, 'w', encoding='utf-8') as f:
            json.dump(src, f, indent=2, ensure_ascii=False)
            f.write('\n')
        print("merge_json: 目标文件不存在，已直接复制源文件")
        return
    except json.JSONDecodeError as e:
        print(f"merge_json: 目标文件 JSON 解析失败: {target_path}\n  {e}", file=sys.stderr)
        sys.exit(2)
    except OSError as e:
        print(f"merge_json: 无法读取目标文件: {target_path}\n  {e}", file=sys.stderr)
        sys.exit(2)

    # 合并 env: 只添加目标中不存在的 key
    for k, v in src.get('env', {}).items():
        if k not in tgt.get('env', {}):
            tgt.setdefault('env', {})[k] = v

    # 合并 hooks: 按 (matcher, command) 去重，动态遍历所有 hook 类型
    for htype in src.get('hooks', {}):
        for hook in src.get('hooks', {}).get(htype, []):
            exists = any(
                h.get('matcher') == hook.get('matcher')
                and h.get('command') == hook.get('command')
                for h in tgt.get('hooks', {}).get(htype, [])
            )
            if not exists:
                tgt.setdefault('hooks', {}).setdefault(htype, []).append(hook)

    # 写回目标文件
    try:
        with open(target_path, 'w', encoding='utf-8') as f:
            json.dump(tgt, f, indent=2, ensure_ascii=False)
            f.write('\n')
        print("merge_json: settings.json 合并完成")
    except OSError as e:
        print(f"merge_json: 无法写入目标文件: {target_path}\n  {e}", file=sys.stderr)
        sys.exit(3)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("用法: python3 merge_json.py <source.json> <target.json>", file=sys.stderr)
        sys.exit(1)

    merge_settings(sys.argv[1], sys.argv[2])
