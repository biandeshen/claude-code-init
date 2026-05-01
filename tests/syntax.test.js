/**
 * 语法检查 + CLI 行为测试套件
 * 运行: node --test tests/syntax.test.js
 */

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const PROJECT_ROOT = path.join(__dirname, '..');

describe('Python 脚本语法检查', () => {
    const pyFiles = [];
    function findPyFiles(dir, base = '') {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
            if (entry.name === 'node_modules' || entry.name === '__pycache__' || entry.name.startsWith('.')) continue;
            const fullPath = path.join(dir, entry.name);
            const relPath = base ? `${base}/${entry.name}` : entry.name;
            if (entry.isDirectory()) {
                findPyFiles(fullPath, relPath);
            } else if (entry.name.endsWith('.py')) {
                pyFiles.push(relPath);
            }
        }
    }
    findPyFiles(PROJECT_ROOT);

    for (const pyFile of pyFiles) {
        it(`${pyFile} 语法有效`, () => {
            const result = execSync(`python -m py_compile "${pyFile}"`, {
                cwd: PROJECT_ROOT,
                encoding: 'utf-8',
                timeout: 10000
            });
            // py_compile 成功时无输出
            assert.ok(true);
        });
    }
});

describe('Shell 脚本语法检查', () => {
    const shFiles = [];
    function findShFiles(dir, base = '') {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
            if (entry.name === 'node_modules' || entry.name === '__pycache__') continue;
            const fullPath = path.join(dir, entry.name);
            const relPath = base ? `${base}/${entry.name}` : entry.name;
            if (entry.isDirectory()) {
                findShFiles(fullPath, relPath);
            } else if (entry.name.endsWith('.sh')) {
                shFiles.push(relPath);
            }
        }
    }
    findShFiles(PROJECT_ROOT);

    for (const shFile of shFiles) {
        it(`${shFile} 语法有效`, () => {
            execSync(`bash -n "${shFile}"`, {
                cwd: PROJECT_ROOT,
                encoding: 'utf-8',
                timeout: 5000
            });
        });
    }
});

describe('index.js CLI 行为测试', () => {
    const INDEX_PATH = path.join(PROJECT_ROOT, 'index.js');

    it('--help 输出包含用法信息', () => {
        const result = execSync(`node "${INDEX_PATH}" --help`, {
            encoding: 'utf-8',
            timeout: 5000
        });
        assert.ok(result.includes('用法') || result.includes('usage') || result.includes('Usage'),
            '--help should show usage information');
    });

    it('--version 输出包含版本号', () => {
        const pkg = JSON.parse(fs.readFileSync(path.join(PROJECT_ROOT, 'package.json'), 'utf-8'));
        const result = execSync(`node "${INDEX_PATH}" --version`, {
            encoding: 'utf-8',
            timeout: 5000
        });
        assert.ok(result.includes(pkg.version),
            `--version should output version ${pkg.version}`);
    });

    it('项目根目录 (/) 应被拒绝', () => {
        assert.throws(() => {
            execSync(`node "${INDEX_PATH}" --project-path="/"`, {
                encoding: 'utf-8',
                timeout: 5000
            });
        }, undefined, 'root directory should be rejected');
    });

    it('包含 shell 元字符的路径应被拒绝', () => {
        assert.throws(() => {
            execSync(`node "${INDEX_PATH}" --project-path="test;rm -rf /"`, {
                encoding: 'utf-8',
                timeout: 5000
            });
        }, undefined, 'path with shell metacharacters should be rejected');
    });
});
