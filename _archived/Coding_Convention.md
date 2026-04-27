# Python 代码开发规范

> 版本：v1.0.0 | 更新：2026-04-28
> 本文档描述 Python 代码开发的通用规范，适用于任何 Python 项目。

---

## 一、命名规范

### 1.1 文件与目录

| 类型 | 规范 | 示例 |
|------|------|------|
| Python 文件 | 全小写，下划线分隔 | `agent_loop.py`, `event_bus.py` |
| 目录 | 全小写，下划线分隔 | `my_module/`, `test_utils/` |
| 配置文件 | 全小写，下划线分隔 | `config.yaml`, `settings.json` |
| 测试文件 | `test_` 前缀 | `test_event_bus.py` |

注意：
- ❌ 不使用连字符 (`-`)
- ✅ 使用下划线 (`_`)
- ❌ 不使用空格
- ❌ 不使用大写字母

### 1.2 类名

首字母大写的驼峰命名法：

```python
# ✅ 正确
class UserManager
class EventBus
class DataProcessor
class HTTPClient

# ❌ 错误
class user_manager
class USER_MANAGER
class eventbus
```

### 1.3 函数与方法

全小写，下划线分隔：

```python
# ✅ 正确
def execute_task()
def load_config()
def get_user_by_id()
def _internal_helper()  # 私有方法

# ❌ 错误
def executeTask()
def ExecuteTask()
def getUserById()
```

### 1.4 变量名

命名应贴近含义，避免无意义单字符：

```python
# ✅ 正确
user_name = "张三"
max_retries = 3
health_score = 0.85
error_message = "文件不存在"

# ❌ 错误（除非作用域极小）
n = 3
m = "张三"
x = 0.85
tmp = "文件不存在"
```

### 1.5 常量

全大写，下划线分隔：

```python
# ✅ 正确
MAX_ITERATIONS = 10
DEFAULT_TIMEOUT = 30
HEALTH_THRESHOLD = 0.6

# ❌ 错误
maxIterations = 10
default_timeout = 30
```

### 1.6 异常类

以 `Error` 结尾，继承 `Exception`：

```python
# ✅ 正确
class UserNotFoundError(Exception):
    pass

class ConfigurationError(Exception):
    pass

class NetworkTimeoutError(Exception):
    pass

# ❌ 错误
class UserNotFound(Exception):  # 缺少 Error
    pass

class user_not_found(Exception):  # 非驼峰
    pass
```

---

## 二、导入规范

### 2.1 导入顺序

```python
# 1. 标准库
import os
import sys
import json
import asyncio
from pathlib import Path
from typing import Dict, List, Optional, Callable, Any

# 2. 第三方库
import yaml
import requests

# 3. 本地模块（相对导入或绝对导入）
from myapp.utils import helper_function
from . import constants
```

### 2.2 导入规则

```python
# ✅ 每行一个导入
import os
import sys

# ❌ 不在同一行导入多个
import os, sys

# ✅ 使用 from...import 导入具体对象
from myapp.utils import validate_input, process_data

# ❌ 避免 from x import *
from myapp.utils import *
```

---

## 三、函数设计

### 3.1 函数长度

单个函数不超过 **50 行**。超过时拆分为多个小函数。

```python
# ✅ 正确：拆分
async def process_request(self, request_data):
    validated = self._validate_request(request_data)
    result = await self._execute_processing(validated)
    return self._format_response(result)

def _validate_request(self, data):
    """验证请求数据"""
    # 验证逻辑...

def _execute_processing(self, validated_data):
    """执行处理逻辑"""
    # 处理逻辑...

def _format_response(self, result):
    """格式化响应"""
    # 格式化逻辑...
```

### 3.2 参数数量

参数不超过 **5 个**。超过时使用 dataclass：

```python
# ✅ 正确：dataclass 封装
from dataclasses import dataclass
from typing import Optional

@dataclass
class QueryParams:
    user_id: str
    limit: int = 10
    offset: int = 0
    include_details: bool = False
    timeout: Optional[int] = None

def search_users(params: QueryParams) -> dict:
    ...

# ❌ 错误：参数过多
def search_users(user_id, limit, offset, include_details, timeout, sort_by, order):
    ...
```

### 3.3 返回值格式

统一返回 `dict`，包含 `success`、`data`、`error` 字段：

```python
# ✅ 正确
def get_user(user_id: str) -> dict:
    user = find_user_in_db(user_id)
    if not user:
        return {"success": False, "data": None, "error": "用户不存在"}
    return {"success": True, "data": user, "error": None}

# ❌ 错误：返回格式不一致
def get_user(user_id):
    return None  # 返回 None，调用方需要额外判断

def get_user(user_id):
    return {}  # 返回空 dict，但缺少 success 字段
```

### 3.4 异步函数

- I/O 操作使用 `async def`
- 同步函数调用异步函数时使用 `asyncio.run()` 或 `asyncio.get_event_loop()`
- 不要在异步函数中使用 `time.sleep()`，使用 `asyncio.sleep()`

```python
# ✅ 正确
async def fetch_data(url: str) -> dict:
    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(
        None, lambda: requests.get(url)
    )
    return {"success": True, "data": response.json(), "error": None}

# ❌ 错误：阻塞事件循环
async def fetch_data(url):
    response = requests.get(url)  # 阻塞 1 秒
    return response.json()
```

---

## 四、错误处理

### 4.1 异常捕获原则

- 优先捕获具体异常，避免裸 `except`
- 保留原始异常信息
- 日志记录后返回错误格式

```python
# ✅ 正确：捕获具体异常
async def execute_query(self, query: str) -> dict:
    try:
        result = await self.db.execute(query)
        return {"success": True, "data": result, "error": None}
    except ConnectionError as e:
        logger.error(f"数据库连接失败: {e}")
        return {"success": False, "data": None, "error": "数据库连接失败"}
    except QuerySyntaxError as e:
        return {"success": False, "data": None, "error": f"SQL 语法错误: {e}"}
    except Exception as e:
        logger.error(f"查询执行失败: {e}", exc_info=True)
        return {"success": False, "data": None, "error": str(e)}

# ❌ 错误：裸 except
try:
    result = await self.db.execute(query)
except:
    return None  # 隐藏了所有错误信息
```

### 4.2 异常链

```python
# ✅ 正确：保留原始异常
try:
    config = yaml.safe_load(config_path.read_text())
except yaml.YAMLError as e:
    raise ConfigurationError(f"配置文件解析失败: {e}") from e
```

### 4.3 日志

```python
import logging

logger = logging.getLogger(__name__)

# ✅ 正确
logger.info(f"用户 {user_id} 登录成功")
logger.error(f"处理请求失败: {e}", exc_info=True)
logger.warning(f"重试次数过多: {attempt}/{max_attempts}")

# ❌ 错误：使用 print
print(f"用户 {user_id} 登录成功")
```

---

## 五、注释规范

### 5.1 文件头注释

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
用户管理模块

功能：
    1. 用户注册和登录
    2. 用户信息查询
    3. 权限管理

Author: 项目名
Version: 1.0.0
"""
```

### 5.2 类注释

```python
class UserManager:
    """用户管理器

    职责：
        - 管理用户生命周期
        - 处理用户认证
        - 提供用户信息查询接口
    """
```

### 5.3 函数注释

```python
async def get_user_by_id(user_id: str) -> dict:
    """
    根据 ID 获取用户信息

    参数:
        user_id: 用户 ID

    返回:
        {"success": bool, "data": dict, "error": str or None}

    示例:
        >>> result = await get_user_by_id("user123")
        >>> print(result["data"]["name"])
        "张三"
    """
```

### 5.4 行内注释

注释应解释**为什么**，而不是**是什么**：

```python
# ✅ 正确
i += 1  # 跳过已处理的节点
cache.set(key, value, ttl=300)  # TTL=5分钟，避免内存泄漏
user = users.get(uid) or default_user  # 默认用户兜底

# ❌ 错误
i += 1  # i 加 1
cache.set(key, value, ttl=300)  # 设置缓存
```

### 5.5 TODO 注释

```python
# TODO(v1.1): 添加缓存支持
# TODO(v2.0): 重构为异步架构
# FIXME: 临时解决方案，需要重构
# NOTE: 设计参考了某开源项目
# HACK: 工作区限制，后续需要修改
```

---

## 六、代码布局

### 6.1 缩进

使用 4 个空格：

```python
# ✅ 正确
foo = long_function_name(
    var_one,
    var_two,
    var_three,
)

config = {
    "name": "test",
    "version": "1.0",
}

# ❌ 错误：混用 Tab 和空格
foo = long_function_name(
 var_one,  # Tab
    var_two,  # 空格
)
```

### 6.2 行长度

每行最多 **120 字符**。超过时使用括号续行：

```python
# ✅ 正确
result = await process_data(
    data_source=source,
    transform_type=transform,
    options=options,
)

# ❌ 错误：超过 120 字符
result = await process_data(data_source=source, transform_type=transform, options=options, callback=on_complete)
```

### 6.3 空行

| 场景 | 空行数 |
|------|--------|
| 模块之间（import 后） | 2 |
| 类之间 | 2 |
| 类内方法之间 | 1 |
| 函数之间 | 2 |

```python
import os
import sys

from myapp.utils import helper  # ← import 后空 2 行


class DataProcessor:  # ← 类前空 2 行
    """数据处理器"""

    def __init__(self):  # ← 方法前空 1 行
        ...

    async def process(self):  # ← 方法间空 1 行
        ...


class EventHandler:  # ← 类间空 2 行
    """事件处理器"""
    ...
```

---

## 七、Git 提交规范

### 7.1 提交信息格式

```
<type>(<scope>): <subject>

[可选 body]

[可选 footer]
```

**type**：

| 类型 | 说明 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档更新 |
| style | 代码格式（不影响功能） |
| refactor | 重构（无功能变化） |
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建/工具相关 |

**示例**：

```
feat(user): 添加用户注册功能

用户反馈需要注册功能。
采用邮箱验证方式。

Closes #123
```

### 7.2 提交前检查清单

```
- [ ] 所有修改文件已保存
- [ ] python -m py_compile <file>.py（无语法错误）
- [ ] 无 print() 调试语句
- [ ] 所有异常都有处理
- [ ] 阻塞调用使用 run_in_executor
- [ ] 函数不超过 50 行
- [ ] 参数不超过 5 个
- [ ] 导入顺序正确（标准库→第三方→本地）
- [ ] 命名符合规范
```

---

## 八、验证命令

```bash
# 语法检查
python -m py_compile myapp/module.py

# 模块导入
python -c "from myapp import MyClass; print('OK')"

# 单元测试
pytest tests/ -v

# 代码格式检查
ruff check myapp/
ruff format myapp/

# 类型检查（可选）
mypy myapp/
```

---

## 参考资料

- [PEP 8](https://pep8.org/)
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)

---

*版本：v1.0.0 | 更新：2026-04-28*
