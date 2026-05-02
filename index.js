#!/usr/bin/env node
'use strict';
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
const forwardFlags = [];  // 转发到 init.sh/init.ps1 的标志
const knownFlags = new Set([
    '--force', '--skip-ecc', '--skip-superpowers',
    '--skip-openspec', '--skip-ccdiscipline'
]);

for (let i = 0; i < args.length; i++) {
    if (args[i] === '--version' || args[i] === '-v') {
        const pkg = require('./package.json');
        console.log(`claude-code-init v${pkg.version}`);
        process.exit(0);
    }
    if (args[i] === '--help' || args[i] === '-h') {
        console.log(`
用法: npx @biandeshen/claude-code-init [选项]

选项:
  --project-path <路径>  目标项目目录（默认: 当前目录）
  --force                强制覆盖已有文件（跳过交互确认）
  --skip-ecc             跳过 ECC 插件安装
  --skip-superpowers     跳过 Superpowers 插件安装
  --skip-openspec        跳过 OpenSpec 安装
  --skip-ccdiscipline    跳过 cc-discipline 安装
  --version, -v          显示版本号
  --help, -h             显示此帮助信息

示例:
  npx @biandeshen/claude-code-init --project-path ./my-project
  npx @biandeshen/claude-code-init --project-path ./my-project --force --skip-ecc
`);
        process.exit(0);
    }
    if (args[i] === '--project-path' && args[i + 1]) {
        projectPath = args[i + 1];
        i++;  // 跳过下一个参数（值）
    } else if (args[i].startsWith('--project-path=')) {
        projectPath = args[i].split('=')[1];
    } else if (knownFlags.has(args[i])) {
        forwardFlags.push(args[i]);
    } else if (args[i].startsWith('--')) {
        console.error(`[警告] 未知选项: ${args[i]}，已忽略`);
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
// 禁止 shell 注入元字符（使用 spawnSync 但仍提供早期检测）
// 只阻止真正的 shell 注入字符: $ ` ; | & < > ( ) { }
if (/[\$\x60;|&<>(){}]/.test(projectPath)) {
    console.error('[错误] 项目路径包含不安全字符。');
    process.exit(1);
}

// 获取脚本所在目录
const scriptDir = __dirname;

// 检测操作系统
const isWindows = process.platform === 'win32';
const isMac = process.platform === 'darwin';

// 检查系统依赖（支持自定义版本检测命令）
function checkDependency(cmd, name, versionCmd) {
    try {
        execSync(versionCmd || `${cmd} --version`, { stdio: 'pipe' });
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
if (isWindows) {
    // PowerShell 5.1 不支持 --version，需用 -Command 查询版本
    const psName = psCmd || 'pwsh';
    const psVerCmd = `${psName} -Command "$PSVersionTable.PSVersion.ToString()"`;
    deps.push([psName, 'PowerShell', psVerCmd]);
} else {
    deps.push(['bash', 'Bash']);
}

const missingDeps = [];
for (const dep of deps) {
    const [cmd, name, versionCmd] = dep;
    if (!checkDependency(cmd, name, versionCmd)) {
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

// 转换 CLI 标志到子进程参数
function toShFlag(flag) {
    return flag;  // 与 init.sh 格式一致，直接传递
}

function toPsFlag(flag) {
    // --force → -Force, --skip-ecc → -SkipECC, --skip-superpowers → -SkipSuperpowers
    // --skip-openspec → -SkipOpenSpec, --skip-ccdiscipline → -SkipCcDiscipline
    const map = {
        '--force': '-Force',
        '--skip-ecc': '-SkipECC',
        '--skip-superpowers': '-SkipSuperpowers',
        '--skip-openspec': '-SkipOpenSpec',
        '--skip-ccdiscipline': '-SkipCcDiscipline',
    };
    return map[flag] || flag;
}

try {
    if (isWindows) {
        // Windows: 使用 PowerShell（优先 pwsh，降级到 powershell）
        if (!psCmd) {
            console.error('[错误] 未找到 PowerShell，请安装 PowerShell 7 或 Windows PowerShell。');
            process.exit(1);
        }
        console.log(`[执行] init.ps1 (${psCmd})`);
        const initScript = path.join(scriptDir, 'init.ps1');
        const psArgs = [
            '-File', initScript,
            '-ProjectPath', path.resolve(projectPath)
        ];
        for (const flag of forwardFlags) {
            psArgs.push(toPsFlag(flag));
        }
        const result = spawnSync(psCmd, psArgs, {
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
        if (!['linux', 'darwin'].includes(process.platform)) {
            console.warn(`[警告] 平台 "${process.platform}" 未被完整测试，将使用 Bash 路径尝试初始化。`);
        }
        console.log('[执行] init.sh');
        const initScript = path.join(scriptDir, 'init.sh');
        const shArgs = [
            initScript,
            path.resolve(projectPath)
        ];
        for (const flag of forwardFlags) {
            shArgs.push(toShFlag(flag));
        }
        const result = spawnSync('bash', shArgs, {
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
