# /ship-review - 发布前全面审查

> 6 角色并行审查 + 交叉验证 + 发布决策，覆盖 10 个业界标准审查维度。

## 概述

`/ship-review` 是发布前的最终质量门禁。启动 6 个专业子 Agent 从不同维度并行审查代码库，然后交叉验证发现，最终给出 SHIP / NO SHIP 决策。

### 角色设计依据

每个 Agent 角色对齐业界标准：

| Agent | 审查维度 | 对标标准 |
|:-----:|----------|----------|
| A | Security | c-CRAB: Security |
| B | Architecture/Design | Google: Design + c-CRAB: Design |
| C | Correctness/Robustness | Google: Functionality + c-CRAB: Correctness + Robustness + Error Handling |
| D | Code Quality | Google: Naming/Comments/Style/Complexity + c-CRAB: Maintainability |
| E | Test Coverage | Google: Tests + c-CRAB: Testing |
| F | Documentation | Google: Documentation + c-CRAB: Documentation |

> 参考：[Google Code Review Standard](https://google.github.io/eng-practices/review/reviewer/looking-for.html)、[c-CRAB Benchmark](https://arxiv.org/abs/2603.23448)（10 类别）

## 执行模式

| 模式 | 条件 | 说明 |
|------|------|------|
| **并行模式**（优先） | Claude Code sub-agent 可用 | 启动 6 个子 Agent 并行审查，汇总结果 |
| **顺序模式**（降级） | sub-agent 不可用 | 当前会话内顺序执行 6 个角色 |

> 检测 sub-agent 可用性：通过 `/team` 命令或 Claude Code 内置 agent 机制判断。无法确认时默认使用顺序模式。

---

## Phase 1 — 6 角色并行审查

### Agent A: Security（安全审查）

```
职责：OWASP Top 10 全覆盖安全检查
审查清单：
  - SQL 注入、XSS、命令注入、路径遍历
  - 认证/授权漏洞、会话管理
  - 敏感数据泄露（密钥、日志、环境变量）
  - SSRF、不安全的反序列化
  - 依赖项漏洞（过期/已知 CVE）
  - 安全配置错误（CORS、CSP、TLS）
输出：安全漏洞清单（按 OWASP 分类 + CVSS 严重度）
```

### Agent B: Architecture（架构一致性）

```
职责：设计合理性与项目规范对齐
审查清单：
  - 变更是否符合 CLAUDE.md 中的架构规则
  - 模块间耦合是否合理（循环依赖检测）
  - API/DB schema 变更是否有破坏性影响
  - 是否引入了不必要的抽象层
  - 变更的时机和范围是否合理
输出：架构问题清单 + 耦合风险矩阵
```

### Agent C: Correctness（功能正确性）

```
职责：功能正确性与鲁棒性
审查清单：
  - 变更是否实现了预期功能（对照 PR 描述/PLAN.md）
  - 边界条件处理（空值、零值、极限值）
  - 错误处理完整性（异常捕获、回滚、降级）
  - 并发安全（竞态条件、死锁、数据一致性）
  - 输入验证（类型、范围、格式）
输出：正确性问题清单（按严重度分级）
```

### Agent D: Code Quality（代码质量）

```
职责：可读性、可维护性、一致性
审查清单：
  - 命名是否语义化（长到能说明意图）
  - 注释是否解释"为什么"而非"是什么"
  - 是否遵循项目代码风格规范
  - 函数长度 ≤ 50 行，圈复杂度 ≤ 10
  - 是否存在重复代码（可提取为公共函数）
  - 与周围代码风格是否一致
输出：质量问题清单 + 改进建议
```

### Agent E: Test Coverage（测试覆盖）

```
职责：测试充分性与质量
审查清单：
  - 核心逻辑是否有单元测试
  - 边界情况是否有覆盖
  - 是否有集成/端到端测试（如涉及多模块）
  - 测试可读性和可维护性
  - 测试是否在代码出错时真正失败
  - 是否存在过度 mock 导致的假阳性
输出：测试缺口清单 + 覆盖率评估
```

### Agent F: Documentation（文档完整性）

```
职责：文档与代码的一致性
审查清单：
  1. CHANGELOG.md 是否记录了本次变更？
  2. GUIDE.md 和 help.md 的命令引用是否仍有效？
  3. CLAUDE.md 的项目结构图是否仍然准确？
  4. 是否存在过时的文件路径引用？
  5. 模板版本头是否需要 bump？
  6. Router 触发词表是否与新/改动的命令一致？
  7. README 是否需要更新？
输出：文档问题清单 + 修改建议
```

---

## Phase 2 — 交叉验证与盲点扫描

**由主会话执行**，综合 6 个子 Agent 的所有发现。

### 2.1 构建发现矩阵

将 6 个 Agent 的发现汇总为统一矩阵：

| ID | 来源 | 维度 | 发现 | 严重度 | 文件:行号 |
|----|:----:|------|------|:------:|-----------|
| F1 | A | Security | SQL 注入风险 | 🔴 | api/users.js:42 |
| F2 | B | Architecture | 循环依赖 | 🟡 | src/modules/ |
| ... | ... | ... | ... | ... | ... |

### 2.2 矛盾检测

对比不同 Agent 的发现，检测矛盾或遗漏：

- **安全无架构**：Agent A 发现安全漏洞，但 Agent B 未提相关耦合？
- **校验通过但有问题**：Agent D/E 报告质量/测试问题，但 Agent C 未发现相关功能风险？
- **文档滞后**：Agent B 标记架构变更，但 Agent F 未在文档中对应？
- **Code Quality 与 Architecture 冲突**：Agent D 建议重构，但 Agent B 标记该区域为稳定接口？

### 2.3 盲点扫描

主动扫描 6 个 Agent 的直接职责都未覆盖的维度：

| 盲点维度 | 检查项 |
|----------|--------|
| **Performance** | N+1 查询？不必要的重渲染？大对象分配？ |
| **Compatibility** | API 向后兼容？数据库迁移可回滚？客户端版本要求？ |
| **i18n / a11y** | 新增文案可翻译？UI 变更符合可访问性？ |
| **Logging / Monitoring** | 关键路径有日志？错误有可观测性？ |

### 2.4 综合评分

对每个发现进行 impact × likelihood 评估：

```
综合评分 = 影响范围 (1-5) × 发生概率 (1-5)

影响范围:
  5 = 全系统宕机/数据丢失/安全漏洞
  4 = 核心功能不可用
  3 = 部分功能受影响/性能显著退化
  2 = 边缘情况/代码异味
  1 = 仅视觉/文案/风格

发生概率:
  5 = 必然触发
  4 = 高概率场景（主要流程）
  3 = 常见场景
  2 = 特定条件触发
  1 = 极端边缘
```

---

## Phase 3 — 发布决策

### 3.1 问题分级

| 级别 | 条件 | 含义 |
|:----:|------|------|
| 🔴 阻断 | 安全漏洞 / 数据丢失 / 功能错误 / 综合评分 ≥ 20 | **必须修复**才能发布 |
| 🟡 建议 | 高风险非阻断 / 综合评分 12-19 / 架构偏离 | **强烈建议**修复 |
| 🟢 备注 | 低风险 / 综合评分 < 12 / 风格/文档 | 记录即可 |

### 3.2 最终裁决

| 裁决 | 条件 |
|:----:|------|
| ✅ **SHIP** | 0 个阻断项，≤ 3 个建议修复项 |
| ⚠️ **SHIP WITH CAVEATS** | 0 个阻断项，4+ 个建议修复项（附风险说明） |
| ❌ **NO SHIP** | ≥ 1 个阻断项 |

### 3.3 输出格式

```markdown
# 发布审查报告 — {日期}

## 审查摘要
- 变更文件数：{N}，代码行数：+{A}/-{D}
- 审查 Agent：6（并行）
- 发现问题数：{N}（🔴 {n} / 🟡 {n} / 🟢 {n}）
- 盲点发现：{N}

## 🔴 阻断项（{N}）
| 发现 | Agent | 文件:行 | 评分 | 修复建议 |
|------|:-----:|---------|:----:|----------|
| ... | A | ... | 25 | ... |

## 🟡 建议修复（{N}）
| 发现 | Agent | 文件:行 | 评分 | 建议 |
|------|:-----:|---------|:----:|------|
| ... | B | ... | 16 | ... |

## 🟢 备注（{N}）
| 发现 | Agent | 文件 | 说明 |
|------|:-----:|------|------|
| ... | D | ... | ... |

## 交叉验证发现
- **矛盾**：Agent A 标记 L42 SQL 注入，Agent B 未提该模块耦合风险 — 建议手动确认
- **盲点**：API /users 新增端点无性能基准测试

## 🏁 最终裁决
**{✅ SHIP / ⚠️ SHIP WITH CAVEATS / ❌ NO SHIP}**

理由：{简述}

---
*审查完成于 {datetime} · /ship-review v1.6.5*
```

---

## 使用示例

```
/ship-review                     # 审查当前分支 vs main 的全部变更
/ship-review --target main       # 指定对比目标分支
/ship-review --scope HEAD~5      # 限定审查范围（最近 5 个提交）
```

## 与其他命令的关系

| 命令 | 关系 |
|------|------|
| `/review` | Agent A + D 的输入 |
| `/validate` | 作为 Agent 的自动化补充 |
| `/architect` | Agent B 的输入 |
| `/team` | 使用相同的 Agent Teams 并行机制 |

`/ship-review` 是 `/review` + `/validate` + `/architect` 的超集，附加 3 个独立审查维度（Correctness、Testing、Documentation）和交叉验证 + 发布决策。

## 注意事项

- 首次运行 6 个并行 Agent 约需 3-6 分钟
- 顺序模式（sub-agent 不可用时）约需 10-15 分钟
- 阻断项 ≥ 1 时，必须先修复再重新审查
- 审查结果自动保存到 `.claude/reports/ship-review-{date}.md`
