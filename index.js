#!/usr/bin/env node
/**
 * claude-code-init - Claude Code 项目脚手架
 *
 * 一键初始化 Claude Code 开发环境
 *
 * 使用方式：
 *   npx claude-code-init --project-path ./my-project
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// 解析命令行参数
const args = process.argv.slice(2);
let projectPath = '.';

for (let i = 0; i < args.length; i++) {
    if (args[i] === '--project-path' && args[i + 1]) {
        projectPath = args[i + 1];
    } else if (args[i].startsWith('--project-path=')) {
        projectPath = args[i].split('=')[1];
    }
}

// 获取脚本所在目录
const scriptDir = __dirname;

// 检测操作系统
const isWindows = process.platform === 'win32';
const isMac = process.platform === 'darwin';

console.log('='.repeat(50));
console.log('  Claude Code 项目脚手架初始化');
console.log('='.repeat(50));
console.log('');
console.log(`目标目录: ${path.resolve(projectPath)}`);
console.log(`操作系统: ${isWindows ? 'Windows' : isMac ? 'macOS' : 'Linux'}`);
console.log('');

try {
    if (isWindows) {
        // Windows: 使用 PowerShell
        console.log('执行: init.ps1');
        const initScript = path.join(scriptDir, 'init.ps1');
        execSync(`pwsh -File "${initScript}" -ProjectPath "${path.resolve(projectPath)}"`, {
            stdio: 'inherit',
            cwd: scriptDir
        });
    } else {
        // Unix/macOS: 使用 Bash
        console.log('执行: init.sh');
        const initScript = path.join(scriptDir, 'init.sh');
        execSync(`bash "${initScript}" "${path.resolve(projectPath)}"`, {
            stdio: 'inherit',
            cwd: scriptDir
        });
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
    console.error('初始化失败:', error.message);
    process.exit(1);
}
