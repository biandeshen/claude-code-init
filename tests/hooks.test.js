/**
 * smart-context.sh Hook 测试套件
 * 使用 Node.js 内置 test runner (node:test)
 * 运行: node --test tests/hooks.test.js
 *
 * 注意: Hook 从 stdin 读取事件数据，测试通过 input 选项传入
 */

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { execSync } = require('child_process');
const path = require('path');

const HOOK_PATH = path.join(__dirname, '..', '.claude', 'hooks', 'smart-context.sh');

describe('smart-context.sh Hook 测试', () => {

    it('场景 2（安全文件检测）输出有效 JSON', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'cat config.yaml' }
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        if (result.trim()) {
            const json = JSON.parse(result);
            assert.ok(json.hookSpecificOutput, 'should contain hookSpecificOutput');
        }
    });

    it('场景 6（rm -rf 阻断）以非零退出码退出', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'rm -rf /' }
        });
        assert.throws(() => {
            execSync(`bash "${HOOK_PATH}"`, {
                input: input,
                encoding: 'utf-8',
                timeout: 5000
            });
        }, /command failed|exit code 2/i, 'should block rm -rf /');
    });

    it('场景 6（sudo rm -rf 阻断）以非零退出码退出', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'sudo rm -rf /' }
        });
        assert.throws(() => {
            execSync(`bash "${HOOK_PATH}"`, {
                input: input,
                encoding: 'utf-8',
                timeout: 5000
            });
        }, /command failed|exit code 2/i, 'should block sudo rm -rf /');
    });

    it('场景 1（编辑测试文件）可能给出 TDD 建议', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { file_path: '/project/tests/test_login.py' }
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        if (result.trim()) {
            const json = JSON.parse(result);
            assert.ok(json.hookSpecificOutput.suggestion
                .toLowerCase().includes('tdd'), 'should suggest TDD');
        }
    });

    it('stdin 超时不挂起', () => {
        // 发送空 JSON 对象验证 hook 在无匹配场景时正常退出（不挂起）
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: '{}' + '\n',
            encoding: 'utf-8',
            timeout: 10000,
            env: { ...process.env, HOOK_TEST_MODE: '1' }
        });
        // 空 JSON 无匹配场景 → 无输出（exit 0）
        if (result.trim()) {
            // 极少数环境下有非空输出，验证为有效 JSON 即可
            JSON.parse(result);
        }
    });
});
