/**
 * merge_json.py 测试套件
 * 使用 Node.js 内置 test runner 调用 Python 子进程进行测试
 * 运行: node --test tests/merge_json.test.js
 */

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const MERGE_SCRIPT = path.join(__dirname, '..', 'scripts', 'merge_json.py');
const PYTHON = process.platform === 'win32' ? 'python' : 'python3';

// 临时目录管理
let tmpDir;

function runMerge(source, target) {
    return execSync(`${PYTHON} "${MERGE_SCRIPT}" "${source}" "${target}"`, {
        encoding: 'utf-8',
        timeout: 10000
    });
}

function writeJson(filePath, data) {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf-8');
}

function readJson(filePath) {
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
}

describe('merge_json.py', () => {

    before(() => {
        tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'merge-json-test-'));
    });

    after(() => {
        fs.rmSync(tmpDir, { recursive: true, force: true });
    });

    it('目标文件不存在时直接复制源文件', () => {
        const src = path.join(tmpDir, 'src1.json');
        const tgt = path.join(tmpDir, 'tgt1.json');
        writeJson(src, { env: { KEY: 'val' }, hooks: {} });

        runMerge(src, tgt);

        assert.ok(fs.existsSync(tgt), '目标文件应被创建');
        assert.deepEqual(readJson(tgt), { env: { KEY: 'val' }, hooks: {} });
    });

    it('env: 只添加目标中不存在的 key，不覆盖已有值', () => {
        const src = path.join(tmpDir, 'src2.json');
        const tgt = path.join(tmpDir, 'tgt2.json');
        writeJson(src, { env: { A: 'from_src', B: 'from_src', C: 'from_src' } });
        writeJson(tgt, { env: { A: 'from_tgt', B: 'from_tgt' } });

        runMerge(src, tgt);

        const result = readJson(tgt);
        assert.equal(result.env.A, 'from_tgt', '已有 key 不覆盖');
        assert.equal(result.env.B, 'from_tgt', '已有 key 不覆盖');
        assert.equal(result.env.C, 'from_src', '新 key 从源添加');
    });

    it('hooks: 按 (matcher, command) 去重后追加', () => {
        const src = path.join(tmpDir, 'src3.json');
        const tgt = path.join(tmpDir, 'tgt3.json');
        writeJson(src, {
            hooks: {
                SessionStart: [
                    { matcher: 'all', command: 'echo src' },
                    { matcher: 'test', command: 'echo new' }
                ]
            }
        });
        writeJson(tgt, {
            hooks: {
                SessionStart: [
                    { matcher: 'all', command: 'echo tgt' }
                ]
            }
        });

        runMerge(src, tgt);

        const result = readJson(tgt);
        // 去重键为 (matcher, command)，因此 (all, echo tgt) 和 (all, echo src) 不同
        assert.equal(result.hooks.SessionStart.length, 3, '应保留目标已有 hooks + 新增不重复的 hooks');
        assert.ok(result.hooks.SessionStart.some(h => h.command === 'echo tgt'), '应保留目标已有 hook');
        assert.ok(result.hooks.SessionStart.some(h => h.command === 'echo new'), '应添加新的不重复 hook');
        assert.ok(result.hooks.SessionStart.some(h => h.command === 'echo src'), 'command 不同时即使 matcher 相同也不去重');
    });

    it('动态遍历所有 hook 类型（不限于硬编码列表）', () => {
        const src = path.join(tmpDir, 'src4.json');
        const tgt = path.join(tmpDir, 'tgt4.json');
        writeJson(src, {
            hooks: {
                SessionStart: [{ matcher: 'all', command: 'echo a' }],
                PreToolUse: [{ matcher: 'all', command: 'echo b' }],
                PostToolUse: [{ matcher: 'all', command: 'echo c' }],
                FutureHookType: [{ matcher: 'all', command: 'echo d' }]  // 未来可能新增的类型
            }
        });
        writeJson(tgt, { hooks: {} });

        runMerge(src, tgt);

        const result = readJson(tgt);
        assert.ok(result.hooks.FutureHookType, '未来新增的 hook 类型应被处理');
        assert.equal(result.hooks.FutureHookType[0].command, 'echo d');
    });

    it('源文件不存在时报错退出码 2', () => {
        const src = '/nonexistent/source.json';
        const tgt = path.join(tmpDir, 'tgt5.json');
        assert.throws(() => runMerge(src, tgt), /command failed|exit code 2/i);
    });

    it('无效 JSON 源文件时报错退出码 2', () => {
        const src = path.join(tmpDir, 'bad_src.json');
        const tgt = path.join(tmpDir, 'tgt6.json');
        fs.writeFileSync(src, 'not json', 'utf-8');
        assert.throws(() => runMerge(src, tgt), /command failed|exit code 2/i);
    });

    it('参数数量错误时报错退出码 1', () => {
        assert.throws(() => {
            execSync(`${PYTHON} "${MERGE_SCRIPT}" only_one_arg`, {
                encoding: 'utf-8',
                timeout: 5000
            });
        }, /command failed|exit code 1/i);
    });

});
