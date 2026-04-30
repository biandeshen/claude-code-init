/**
 * claude-code-init 测试套件
 * 使用 Node.js 内置 test runner (node:test)
 * 运行: npm test 或 node --test tests/*.test.js
 */

const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

const projectRoot = path.resolve(__dirname, '..');

// ============================================================
// 包结构测试
// ============================================================

test('package.json 格式有效', () => {
    const pkgPath = path.join(projectRoot, 'package.json');
    const raw = fs.readFileSync(pkgPath, 'utf8');
    const pkg = JSON.parse(raw);
    assert.ok(pkg.name, 'name 字段必须存在');
    assert.ok(pkg.version, 'version 字段必须存在');
    assert.ok(pkg.main, 'main 字段必须存在');
    assert.ok(pkg.bin && Object.keys(pkg.bin).length > 0, 'bin 字段必须存在且非空');
    assert.ok(Array.isArray(pkg.files), 'files 必须是数组');
    assert.ok(pkg.files.length > 0, 'files 不能为空');
});

test('package.json 中声明的 files 全部存在', () => {
    const pkg = require(path.join(projectRoot, 'package.json'));
    for (const f of pkg.files) {
        const fullPath = path.join(projectRoot, f);
        assert.ok(
            fs.existsSync(fullPath),
            `files 中声明的路径应存在: ${f}`
        );
    }
});

test('package.json 中 engines 声明正确', () => {
    const pkg = require(path.join(projectRoot, 'package.json'));
    assert.ok(pkg.engines, 'engines 字段必须存在');
    assert.ok(pkg.engines.node, 'engines.node 必须声明');
    assert.match(pkg.engines.node, />=\d+/, 'engines.node 应包含 >= 约束');
});

// ============================================================
// 入口文件测试
// ============================================================

test('index.js 语法检查通过', () => {
    assert.doesNotThrow(
        () => { execSync('node --check index.js', { cwd: projectRoot, stdio: 'pipe' }); },
        'node --check index.js 应无语法错误'
    );
});

test('index.js 包含核心函数定义', () => {
    const content = fs.readFileSync(path.join(projectRoot, 'index.js'), 'utf8');
    assert.ok(content.includes('checkDependency'), 'index.js 应包含 checkDependency 函数');
    assert.ok(content.includes('detectPowerShell'), 'index.js 应包含 detectPowerShell 函数');
    assert.ok(content.includes('spawnSync'), 'index.js 应使用 spawnSync 安全执行子进程');
});

// ============================================================
// 初始化脚本测试
// ============================================================

test('init.sh 存在且为有效的 Bash 脚本', () => {
    const initSh = path.join(projectRoot, 'init.sh');
    assert.ok(fs.existsSync(initSh), 'init.sh 必须存在');
    const content = fs.readFileSync(initSh, 'utf8');
    assert.ok(content.startsWith('#!/bin/bash'), 'init.sh 必须以 shebang 开头');
    assert.ok(content.includes('set -euo pipefail'), 'init.sh 必须设置 strict mode');
    assert.ok(content.includes('SKIP_'), 'init.sh 必须支持 --skip-* 参数');
});

test('init.ps1 存在且为有效的 PowerShell 脚本', () => {
    const initPs1 = path.join(projectRoot, 'init.ps1');
    assert.ok(fs.existsSync(initPs1), 'init.ps1 必须存在');
    const content = fs.readFileSync(initPs1, 'utf8');
    assert.ok(content.includes('param('), 'init.ps1 必须包含 param 块');
    assert.ok(content.includes('Skip'), 'init.ps1 必须支持 skip 参数');
});

// ============================================================
// 系统依赖测试（CI 环境验证）
// ============================================================

test('git 命令可用', () => {
    assert.doesNotThrow(
        () => { execSync('git --version', { stdio: 'pipe' }); },
        'git 命令必须在系统中可用'
    );
});

test('npm 可读取 package.json 版本号', () => {
    const result = execSync('npm pkg get version', {
        cwd: projectRoot,
        stdio: 'pipe',
        encoding: 'utf8'
    });
    assert.ok(result.includes('.'), 'version 应为 semver 格式');
});

// ============================================================
// 安全特性测试
// ============================================================

test('index.js 使用 spawnSync 而非 execSync 执行外部脚本', () => {
    const content = fs.readFileSync(path.join(projectRoot, 'index.js'), 'utf8');
    // init.ps1 / init.sh 执行必须使用 spawnSync
    assert.ok(
        content.includes("spawnSync(psCmd") || content.includes("spawnSync('bash'"),
        '外部脚本执行必须使用 spawnSync 防注入'
    );
});

test('init.sh 锁定 cc-discipline 版本', () => {
    const content = fs.readFileSync(path.join(projectRoot, 'init.sh'), 'utf8');
    assert.ok(
        content.includes('CC_DISCIPLINE_COMMIT='),
        'init.sh 必须锁定 cc-discipline commit'
    );
    assert.ok(
        content.includes('rev-parse HEAD'),
        'init.sh 必须验证 commit 完整性'
    );
});

test('init.ps1 锁定 cc-discipline 版本', () => {
    const content = fs.readFileSync(path.join(projectRoot, 'init.ps1'), 'utf8');
    assert.ok(
        content.includes('CcDisciplineCommit'),
        'init.ps1 必须锁定 cc-discipline commit'
    );
    assert.ok(
        content.includes('rev-parse HEAD'),
        'init.ps1 必须验证 commit 完整性'
    );
});
