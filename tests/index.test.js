/**
 * claude-code-init 测试套件
 * 使用 Node.js 内置 test runner (node:test)
 * 运行: npm test 或 node --test tests/*.test.js
 */

const { test, describe } = require('node:test');
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
        // 跳过 npm 否定模式（以 ! 开头，如 !scripts/__pycache__/）
        if (f.startsWith('!')) {
            continue;
        }
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

// ============================================================
// init.sh 功能性检查
// ============================================================

describe('init.sh Functional Checks', () => {
    test('init.sh: contains copy_template function', () => {
        const content = fs.readFileSync(path.join(projectRoot, 'init.sh'), 'utf-8');
        assert.ok(content.includes('copy_template()'), 'init.sh should define copy_template');
    });

    test('init.sh: contains FORCE_OVERWRITE handling', () => {
        const content = fs.readFileSync(path.join(projectRoot, 'init.sh'), 'utf-8');
        assert.ok(content.includes('FORCE_OVERWRITE'), 'init.sh should handle --force flag');
    });

    test('init.sh: CLAUDE.local.md has existence check', () => {
        const content = fs.readFileSync(path.join(projectRoot, 'init.sh'), 'utf-8');
        assert.ok(content.includes('-f "$PROJECT_PATH/.claude/CLAUDE.local.md"'), 'CLAUDE.local.md should have existence check');
    });

    test('init.sh: MEMORY.local.md has existence check', () => {
        const content = fs.readFileSync(path.join(projectRoot, 'init.sh'), 'utf-8');
        assert.ok(content.includes('-f "$PROJECT_PATH/.claude/MEMORY.local.md"'), 'MEMORY.local.md should have existence check');
    });
});

// ============================================================
// init.ps1 功能性检查
// ============================================================

describe('init.ps1 Functional Checks', () => {
    test('init.ps1: contains Copy-Template function', () => {
        const content = fs.readFileSync(path.join(projectRoot, 'init.ps1'), 'utf-8');
        assert.ok(content.includes('Copy-Template'), 'init.ps1 should define Copy-Template');
    });

    test('init.ps1: CLAUDE.local.md has Test-Path check', () => {
        const content = fs.readFileSync(path.join(projectRoot, 'init.ps1'), 'utf-8');
        assert.ok(content.includes('Test-Path $claudeLocalPath'), 'CLAUDE.local.md should have Test-Path check');
    });

    test('init.ps1: MEMORY.local.md has Test-Path check', () => {
        const content = fs.readFileSync(path.join(projectRoot, 'init.ps1'), 'utf-8');
        assert.ok(content.includes('Test-Path $memoryLocalPath'), 'MEMORY.local.md should have Test-Path check');
    });
});

// ============================================================
// Skills 存在性检查
// ============================================================

describe('Skills Existence', () => {
    test('Skills: all 10 skills have SKILL.md with YAML frontmatter', () => {
        const skillsDir = path.join(projectRoot, '.claude', 'skills');
        const skillDirs = fs.readdirSync(skillsDir).filter(d => {
            return fs.statSync(path.join(skillsDir, d)).isDirectory();
        });

        const expectedSkills = [
            'brainstorming', 'code-explain', 'code-review', 'error-fix',
            'git-commit', 'project-init', 'project-validate', 'router',
            'safe-refactoring', 'tdd-workflow'
        ];

        for (const skill of expectedSkills) {
            const skillMd = path.join(skillsDir, skill, 'SKILL.md');
            assert.ok(fs.existsSync(skillMd), `Skill ${skill} should have SKILL.md`);
            const content = fs.readFileSync(skillMd, 'utf-8');
            assert.ok(content.startsWith('---'), `Skill ${skill} should have YAML frontmatter`);
            assert.ok(content.includes('name:'), `Skill ${skill} should have name field`);
        }
    });
});

// ============================================================
// Router 决策表
// ============================================================

describe('Router Decision Table', () => {
    test('Router: decision table has code-explain and project-init entries', () => {
        const routerMd = path.join(projectRoot, '.claude', 'skills', 'router', 'SKILL.md');
        const content = fs.readFileSync(routerMd, 'utf-8');
        assert.ok(content.includes('代码解释') || content.includes('code-explain'), 'Router should route to code-explain');
        assert.ok(content.includes('项目初始化') || content.includes('project-init'), 'Router should route to project-init');
    });
});

// ============================================================
// 安全特性
// ============================================================

describe('Security', () => {
    test('Security: .gitignore contains .env entries', () => {
        const gitignore = path.join(projectRoot, '.gitignore');
        const content = fs.readFileSync(gitignore, 'utf-8');
        assert.ok(content.includes('.env'), '.gitignore should include .env pattern');
    });
});

// ============================================================
// 跨平台
// ============================================================

describe('Cross-platform', () => {
    test('Cross-platform: .gitattributes exists and covers .sh files', () => {
        const gaFile = path.join(projectRoot, '.gitattributes');
        assert.ok(fs.existsSync(gaFile), '.gitattributes should exist');
        const content = fs.readFileSync(gaFile, 'utf-8');
        assert.ok(content.includes('*.sh text eol=lf'), '.gitattributes should enforce LF for .sh files');
    });
});
