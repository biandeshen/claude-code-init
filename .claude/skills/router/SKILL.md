---
name: router
description: >
  Intelligent workflow router for development tasks. Automatically determines
  which tools and workflows to use based on the task type. Use this skill when
  the user mentions: committing code, submitting changes, review, code quality,
  architecture review, technical design, fixing errors, bugs, debugging,
  refactoring, restructuring, explaining code, understanding logic, running
  validation checks, pre-commit, complex feature development, new capability,
  major changes, test execution, running tests, writing tests, or any
  development task that requires tool orchestration.

  Triggers: commit, submit, push, review, check, fix, error, bug, debug,
  refactor, restructure, explain, understand, validate, lint, test, tests,
  pytest, npm test, security, architecture, design, feature, new, complex,
  deploy, production, database
---

# Development Workflow Router

## Core Principle
When the user describes a development task, analyze it and route to the
correct workflow automatically. Do NOT ask the user which workflow to use
unless the task is genuinely ambiguous.

## Decision Tree

### Step 1: Classify the task

| Task Type | Indicators |
|------------|------------|
| Code Commit | User wants to save/submit/push changes |
| Code Review | User wants quality/security check before or after writing code |
| Architecture Review | User is evaluating a technical decision or system design |
| Error Fixing | User has a bug, error, test failure, or unexpected behavior |
| Refactoring | User wants to restructure code without changing behavior |
| Code Explanation | User wants to understand existing code |
| Validation | User wants to run project checks (lint, secrets, structure) |
| Test Execution | User wants to run tests, write tests, or check test coverage |
| Complex Feature | User wants to build a new feature that spans multiple modules |
| Quick Change | User wants a small edit (typo, rename, minor tweak) |

### Step 2: Select workflow based on classification

**Code Commit**
→ Execute `/commit` command (analyze changes → Conventional Commits → pre-commit)

**Code Review**
→ Execute `/review` command (security, correctness, performance, maintainability, test coverage)

**Architecture Review**
→ Execute `/architect <方案描述>` command (multi-dimensional analysis with priority-ranked recommendations)

**Error Fixing**
→ Execute `/fix` command (collect info → root cause hypothesis → solution comparison → execute → verify → commit)
→ If the same fix fails twice, STOP and request human intervention
→ If editing the same file more than 5 times, STOP and re-analyze

**Refactoring**
→ Execute `/refactor` command (define boundaries → protective tests → incremental refactoring → verify → commit)

**Code Explanation**
→ Execute `/explain <target>` command (overview → architecture → data flow → key decisions → risks)

**Validation**
→ Execute `/validate` command (run all check scripts in `.claude/scripts/`)

**Test Execution**
→ If running existing tests: execute the project's test command directly (e.g., `pytest`, `npm test`, `cargo test`)
→ If writing new tests: use Superpowers TDD workflow with `用 TDD 方式写测试`
→ If analyzing test coverage: use ECC `/ut` for unit test generation

**Complex Feature**
→ Start OpenSpec SDD workflow:
  1. `/opsx:propose <feature-name>` — Why
  2. `/opsx:spec <feature-name>` — What
  3. `/opsx:design <feature-name>` — How
  4. `/opsx:task <feature-name>` — Break down into atomic steps
  5. `/opsx:check <feature-name>` — Quality gate
  6. `/opsx:apply <feature-name>` — Execute
  7. `/opsx:archive <feature-name>` — Archive

**Quick Change**
→ Execute directly without formal workflow

### Step 3: Multi-step orchestration

| Scenario | Workflows (in order) |
|----------|---------------------|
| "Submit after review" | `/review` → (if passes) → `/commit` |
| "Review architecture before building" | `/architect` → (if approved) → OpenSpec SDD |
| "Fix error and submit" | `/fix` → (after fix verified) → `/commit` |
| "Refactor and review" | `/refactor` → (after refactoring) → `/review` |
| Security-sensitive changes | `/review` (emphasize security) → `/architect` → OpenSpec SDD |

### Step 4: ECC & Superpowers integration

- **ECC**: Use `/bob` agent for complex full-stack tasks, `/plan` for exploratory planning, `/gen-docs` for documentation generation
- **Superpowers**: Use `TDD way` for test-driven development, `subagent-driven development` for parallel task execution, `find root cause` for systematic debugging

### Step 5: Safety Rules

- For any task involving `rm -rf`, `DROP TABLE`, `git push --force`: MUST confirm with user before proceeding
- If cc-discipline blocks an edit (5+ edits to same file): STOP and perform root cause analysis
- If the same approach fails twice: STOP and request human intervention
- Never skip pre-commit hooks unless explicitly instructed by user
- For deploy/production/database migration: confirm with user before proceeding

## Multi-Agent Thinking (for complex decisions)

For architecture reviews or complex technical decisions:
1. Launch a **plan-agent** to design the implementation approach
2. Launch a **code-reviewer** to analyze potential risks and security concerns
3. Synthesize their outputs into a comprehensive recommendation

Use web search when:
- Evaluating third-party libraries or tools
- Checking best practices for unfamiliar technologies
- Validating that a technical approach is current

## Output Format

When routing a task, output:

```markdown
**Task Analysis**: [one-line description of the task]

**Selected Workflow**: [workflow name]

**Reason**: [why this workflow was chosen]

**Execution Plan**:
1. [Step 1]
2. [Step 2]
...
```
