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

    // ── 场景 1：测试文件检测 ──
    it('场景 1（编辑测试文件）应输出 TDD 建议', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { file_path: '/project/tests/test_login.py' }
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        assert.ok(result.trim(), 'should produce output for test file edit');
        const json = JSON.parse(result);
        assert.ok(json.hookSpecificOutput.suggestion
            .toLowerCase().includes('tdd'), 'should suggest TDD');
    });

    // ── 场景 2：安全文件检测 ──
    it('场景 2（安全文件检测）输出有效 JSON', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'cat config.yaml' },
            file_path: '/project/src/auth/login.py'
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        assert.ok(result.trim(), 'should produce output for auth file');
        const json = JSON.parse(result);
        assert.ok(json.hookSpecificOutput, 'should contain hookSpecificOutput');
    });

    // ── 场景 3：数据库文件检测 ──
    it('场景 3（数据库相关文件）应输出建议', () => {
        const input = JSON.stringify({
            tool_name: 'Write',
            file_path: '/project/src/models/user.py'
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        assert.ok(result.trim(), 'should produce output for db-related file');
        const json = JSON.parse(result);
        const suggestion = json.hookSpecificOutput.suggestion.toLowerCase();
        assert.ok(suggestion.includes('brainstorming') || suggestion.includes('schema'),
            'should suggest brainstorming for db-related files');
    });

    // ── 场景 4：git commit 检测 ──
    it('场景 4（git commit）应输出代码审查建议', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'git commit -m "fix bug"' }
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        if (result.trim()) {
            const json = JSON.parse(result);
            const suggestion = json.hookSpecificOutput.suggestion.toLowerCase();
            assert.ok(suggestion.includes('code-review') || suggestion.includes('审查'),
                'should suggest code review after commit');
        }
    });

    // ── 场景 5a：git push --force 检测 ──
    it('场景 5（git push --force）应输出警告', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'git push --force origin main' }
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        assert.ok(result.trim(), 'should produce output for git push --force');
        const json = JSON.parse(result);
        assert.ok(json.hookSpecificOutput, 'should contain hookSpecificOutput');
    });

    // ── 场景 5b：git push --force-with-lease 检测 ──
    it('场景 5（git push --force-with-lease）应输出提示', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'git push --force-with-lease origin main' }
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        if (result.trim()) {
            const json = JSON.parse(result);
            const suggestion = json.hookSpecificOutput.suggestion;
            assert.ok(!suggestion.includes('⚠️'),
                '--force-with-lease should not trigger danger warning');
        }
    });

    // ── 场景 6a：rm -rf / 阻断 ──
    it('场景 6（rm -rf / 阻断）以非零退出码退出', () => {
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

    // ── 场景 6b：sudo rm -rf / 阻断 ──
    it('场景 6（sudo rm -rf / 阻断）以非零退出码退出', () => {
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

    // ── 场景 6c：command rm -rf / 阻断 ──
    it('场景 6（command rm -rf / 阻断）以非零退出码退出', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'command rm -rf /' }
        });
        assert.throws(() => {
            execSync(`bash "${HOOK_PATH}"`, {
                input: input,
                encoding: 'utf-8',
                timeout: 5000
            });
        }, /command failed|exit code 2/i, 'should block command rm -rf /');
    });

    // ── 场景 6d：nohup rm -rf / 阻断 ──
    it('场景 6（nohup rm -rf / 阻断）以非零退出码退出', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'nohup rm -rf /' }
        });
        assert.throws(() => {
            execSync(`bash "${HOOK_PATH}"`, {
                input: input,
                encoding: 'utf-8',
                timeout: 5000
            });
        }, /command failed|exit code 2/i, 'should block nohup rm -rf /');
    });

    // ── 场景 10：/review 命令检测 ──
    it('场景 10（/review 命令）应输出 Agent Teams 建议', () => {
        const input = JSON.stringify({
            tool_name: 'Bash',
            tool_input: { command: 'claude /review' }
        });
        const result = execSync(`bash "${HOOK_PATH}"`, {
            input: input,
            encoding: 'utf-8',
            timeout: 5000
        });
        assert.ok(result.trim(), 'should produce output for /review command');
        const json = JSON.parse(result);
        const suggestion = json.hookSpecificOutput.suggestion.toLowerCase();
        assert.ok(
            suggestion.includes('team') || suggestion.includes('审查'),
            'should suggest Agent Teams after /review'
        );
    });

    // ── stdin 超时不挂起 ──
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
