#!/usr/bin/env node
/**
 * claude-code-init - Claude Code 项目脚手架
 *
 * 一键初始化 Claude Code 开发环境
 *
 * 使用方式：
 *   npx claude-code-init --project-path ./my-project
 */

const { execSync, spawnSync } = require('child_process');
const path = require('path');

// 解析命令行参数
const args = process.argv.slice(2);
let projectPath = '.';

for (let i = 0; i < args.length; i++) {
    if (args[i] === '--version' || args[i] === '-v') {
        const pkg = require('./package.json');
        console.log(`claude-code-init v${pkg.version}`);
        process.exit(0);
    }
    if (args[i] === '--project-path' && args[i + 1]) {
        projectPath = args[i + 1];
    } else if (args[i].startsWith('--project-path=')) {
        projectPath = args[i].split('=')[1];
    }
}

// 验证 projectPath
const fs = require('fs');
const resolved = path.resolve(projectPath);
const rootPath = path.parse(resolved).root;
// 禁止驱动器根目录（包括通过 ../ 回溯到根的情况）
if (resolved === rootPath) {
    console.error('[错误] 禁止使用根目录作为项目路径。');
    console.error('请使用 --project-path ./my-project 指定子目录。');
    process.exit(1);
}
// 禁止 shell 元字符
if (/[\$`;|&<>(){}]/.test(projectPath)) {
    console.error('[错误] 项目路径包含不安全字符。');
    process.exit(1);
}

// 获取脚本所在目录
const scriptDir = __dirname;

// 检测操作系统
const isWindows = process.platform === 'win32';
const isMac = process.platform === 'darwin';

// 检查系统依赖
function checkDependency(cmd, name) {
    try {
        execSync(`${cmd} --version`, { stdio: 'pipe' });
        return true;
    } catch {
        console.error(`[错误] 未找到 ${name}，请先安装。`);
        return false;
    }
}

// 检测 PowerShell（pwsh 优先，降级到 powershell）
function detectPowerShell() {
    try {
        execSync('pwsh -Command "exit 0"', { stdio: 'pipe' });
        return 'pwsh';
    } catch {
        try {
            execSync('powershell -Command "exit 0"', { stdio: 'pipe' });
            return 'powershell';
        } catch {
            return null;
        }
    }
}

console.log('='.repeat(50));
console.log('  Claude Code 项目脚手架初始化');
console.log('='.repeat(50));
console.log('');
console.log(`目标目录: ${path.resolve(projectPath)}`);
console.log(`操作系统: ${isWindows ? 'Windows' : isMac ? 'macOS' : 'Linux'}`);
console.log('');

// 预先检测 PowerShell 版本（避免重复 fork）
const psCmd = detectPowerShell();

// 检查系统依赖
console.log('[检查] 验证系统依赖...');
const deps = [
    ['git', 'Git'],
    ['python', 'Python'],
];
if (isWindows) deps.push([psCmd || 'pwsh', 'PowerShell']);
else deps.push(['bash', 'Bash']);

const missingDeps = [];
for (const [cmd, name] of deps) {
    if (!checkDependency(cmd, name)) {
        missingDeps.push(name);
    }
}

if (missingDeps.length > 0) {
    console.error('');
    console.error('[错误] 系统依赖检查失败，缺少: ' + missingDeps.join(', '));
    console.error('');
    console.error('请安装缺失的依赖后重试。');
    process.exit(1);
}
console.log('[成功] 系统依赖检查通过');
console.log('');

try {
    if (isWindows) {
        // Windows: 使用 PowerShell（优先 pwsh，降级到 powershell）
        if (!psCmd) {
            console.error('[错误] 未找到 PowerShell，请安装 PowerShell 7 或 Windows PowerShell。');
            process.exit(1);
        }
        console.log(`[执行] init.ps1 (${psCmd})`);
        const initScript = path.join(scriptDir, 'init.ps1');
        const result = spawnSync(psCmd, [
            '-File', initScript,
            '-ProjectPath', path.resolve(projectPath)
        ], {
            stdio: 'inherit',
            cwd: scriptDir
        });
        if (result.error) throw result.error;
        if (result.status !== 0) {
            const err = new Error(`init.ps1 exited with code ${result.status}`);
            err.status = result.status;
            throw err;
        }
    } else {
        // Unix/macOS: 使用 Bash
        console.log('[执行] init.sh');
        const initScript = path.join(scriptDir, 'init.sh');
        const result = spawnSync('bash', [
            initScript,
            path.resolve(projectPath)
        ], {
            stdio: 'inherit',
            cwd: scriptDir
        });
        if (result.error) throw result.error;
        if (result.status !== 0) {
            const err = new Error(`init.sh exited with code ${result.status}`);
            err.status = result.status;
            throw err;
        }
    }

    console.log('');
    console.log('='.repeat(50));
    console.log('  初始化完成！');
    console.log('='.repeat(50));
    console.log('');
    console.log('下一步：');
    console.log(`  cd ${path.resolve(projectPath)}`);
    console.log('  claude');
    console.log('');

} catch (error) {
    console.error('');
    console.error('='.repeat(50));
    console.error('  初始化失败！');
    console.error('='.repeat(50));
    console.error('');
    console.error('常见原因：');
    console.error('  1. Git 未正确安装或未添加到 PATH');
    console.error('  2. Python 未安装');
    console.error('  3. 目标目录无写入权限');
    console.error('  4. 网络问题导致 git clone 失败');
    console.error('');
    console.error('请查看上方错误信息进行排查。');
    process.exit(error.status || 1);
}
