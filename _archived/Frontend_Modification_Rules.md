# 前端修改规范

> 版本：v1.1.0 | 更新：2026-04-21
> 本文档描述前端/UI 修改的策略规范，适用于任何前端项目。

---

## 一、修改前检查

### 1.1 必须执行

1. `Read` 文件完整内容
2. `Bash: git log -p -3 -- <file>` 分析历史

### 1.2 可选执行

- 查看相关组件的引用
- 理解组件的 props/emits/computed
- 检查是否有测试覆盖

---

## 二、场景策略

### 2.1 修改样式

| 策略 | 工具 |
|------|------|
| 只改 CSS，不动 HTML/JS | `Edit` |

```html
<!-- ✅ 正确：只改样式类 -->
<div class="container old-class new-class">

<!-- ❌ 错误：同时改结构和样式 -->
<div class="new-container">
```

### 2.2 添加功能

| 策略 | 工具 |
|------|------|
| 追加不改原有 | `Edit` |

```javascript
// ✅ 正确：追加新逻辑
function handleClick() {
    oldLogic();  // 保留原有逻辑
    newFeature();  // 追加新功能
}

// ❌ 错误：修改原有逻辑
function handleClick() {
    newLogic();  // 替换了原有逻辑
}
```

### 2.3 修复 Bug

| 策略 | 工具 |
|------|------|
| 只改问题行 | `Edit` |

```javascript
// ✅ 正确：精准定位问题
if (user && user.isActive) {  // 修复 null 检查
    showDashboard();
}

// ❌ 错误：重写整个函数
function handleUser() {
    // ... 重写整个函数 50 行
}
```

### 2.4 修改 Vue 组件

| 策略 | 工具 |
|------|------|
| 先列 props/emits/computed | `Read` + `Grep` |

```vue
<!-- ✅ 正确：先理解组件接口 -->
<template>
  <UserCard
    :user="currentUser"      <!-- props -->
    @click="handleClick"      <!-- emit -->
  />
</template>

<script>
// 修改前先确认 props/emits
const props = defineProps(['user'])
const emit = defineEmits(['click'])
</script>
```

### 2.5 重写页面

| 策略 | 工具 |
|------|------|
| **需用户明确授权** | `Write` |

```
重写页面是高风险操作，必须：
1. 说明影响范围
2. 获取用户明确授权
3. 备份原文件（如果有版本控制则可跳过）
```

---

## 三、修改后验证

### 3.1 基本验证

| 场景 | 验证命令 |
|------|----------|
| Python 代码 | `Bash: python -m py_compile <file>.py` |
| 前端组件 | `Bash: npm run build` 或等效命令 |
| 样式文件 | 检查语法错误 |

### 3.2 视觉验证

使用 `playwright` 截图对比进行视觉验证：

```bash
# 安装 playwright（如未安装）
npm install -D playwright
npx playwright install chromium

# 截图对比脚本示例
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('http://localhost:3000');
  await page.screenshot({ path: 'screenshot.png' });
  await browser.close();
})();
```

```
1. 修改前截图
2. 修改后截图
3. 对比差异
```

---

## 四、禁止项

| 禁止项 | 说明 |
|--------|------|
| ❌ 无理解就修改 | 必须先 Read 完整文件 |
| ❌ 一次性大量修改 | 应该分步修改并验证 |
| ❌ 忽略 lint 错误 | 必须修复后再继续 |
| ❌ 重写页面无授权 | 必须获取明确授权 |

---

## 五、工作流示例

### 场景：修复按钮样式问题

```
1. Read button.css                    # 理解文件结构
2. git log -p -3 -- button.css        # 查看历史变更
3. [假设] 问题可能是颜色变量未定义     # 输出假设
4. Edit 修改样式类                   # 精准修改
5. 截图验证修复效果                   # 视觉验证
```

---

## 六、快速索引

| 内容 | 位置 |
|------|------|
| Agent 行为规则 | `E:/笔记/Claude Code规范/Agent_Behavior_Rules.md` |
| 公共代码规范 | `E:/笔记/Claude Code规范/Coding_Convention.md` |

---

*版本：v1.1.0 | 更新：2026-04-21*
*新增：使用 playwright 替代 chrome-devtools 进行视觉验证*