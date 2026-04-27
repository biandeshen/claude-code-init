# 语言约定

> 版本：v1.0.0 | 更新：2026-04-21
> 本文档描述代码和文档中的语言使用规范。

---

## 一、基本原则

| 场景 | 语言 | 示例 |
|------|------|------|
| 对话 | 中文 | "请帮我检查这段代码" |
| 文档 | 中文 | "## 功能说明" |
| 代码注释 | 中文 | `# 计算平均值` |
| 代码标识符 | 英文 | `def calculate_average()` |

---

## 二、代码标识符（英文）

### 变量与函数

```python
# ✅ 正确：英文命名
user_name = "张三"
max_retries = 3
def get_user_by_id(user_id: str) -> dict:

# ❌ 错误：拼音命名
yonghu_ming = "张三"  # 不用拼音
def huoqu_yonghu_by_id():  # 不用拼音
```

### 类名

```python
# ✅ 正确
class UserManager
class EventBus
class SkillRegistry

# ❌ 错误
class YonghuGuanli
class ShiJianZongXian
```

### 常量

```python
# ✅ 正确
MAX_CONNECTIONS = 100
DEFAULT_TIMEOUT = 30
```

### 例外情况

当术语是通用的技术词汇时，可以使用中文：

```python
# 可以接受：领域特定术语
def calculate_平均分():  # 在数学相关项目中
    pass

# 可以接受：数据库字段
class User:
    name: str        # 数据库字段可能已有中文名
    手机号: str      # 如果数据库使用中文列名
```

---

## 三、注释（中文）

### 块注释

```python
"""
计算用户平均分数

功能：
    1. 获取用户所有分数
    2. 计算平均值
    3. 返回结果

作者：项目名
版本：1.0.0
"""

class UserScoreCalculator:
    """用户分数计算器

    职责：
        - 管理用户分数数据
        - 提供统计分析接口
    """
```

### 行内注释

```python
# ✅ 正确：中文注释
total = sum(scores)  # 计算总分
count += 1  # 跳过已处理项

# ❌ 错误：英文注释
total = sum(scores)  # calculate total
```

---

## 四、文档（中文）

### Markdown 文档

```markdown
# 用户认证模块

## 功能说明

本模块提供用户登录、登出功能...

## 使用方法

1. 初始化认证器
2. 调用登录接口
```

### README

```markdown
# Plector

Plector 是一个智能体框架...

## 快速开始

1. 安装依赖
2. 启动服务
```

---

## 五、对外 API（英文）

对外 API 使用英文标识符：

```python
# ✅ 正确：API 使用英文
@app.get("/api/users/{user_id}")
async def get_user(user_id: str):
    return {"user_id": user_id, "name": "张三"}

# ✅ 正确：API 文档用中文
"""
GET /api/users/{user_id}

获取用户信息

参数：
    user_id: 用户 ID

返回：
    用户信息字典
"""
```

---

## 六、错误信息

### 用户可见的错误信息（中文）

```python
# ✅ 正确：用户可见信息用中文
return {
    "success": False,
    "error": "用户名或密码错误"
}

logger.error("数据库连接失败，请检查配置")

# ❌ 错误：技术术语过度使用
return {"error": "Username or password is incorrect"}
```

### 调试日志（英文）

```python
# ✅ 正确：技术日志用英文
logger.debug(f"Connection established: {host}:{port}")
logger.info("Authentication successful")
logger.warning(f"Retrying connection, attempt {attempt}/{max_retries}")
```

---

## 七、特殊场景

### 技术术语

通用技术术语保持英文：

```python
# ✅ 正确
http_status_code = 200
api_endpoint = "/users"
json_data = {"name": "张三"}
```

### 项目名与品牌名

项目名保持原始拼写：

```python
# ✅ 正确
project_name = "Plector"
logo_url = "https://example.com/logo.png"
```

### 人名与地名

使用标准中文翻译：

```python
# ✅ 正确
city = "北京"
author = "张三"
```

---

## 八、快速索引

| 内容 | 位置 |
|------|------|
| 公共代码规范 | `docs/Coding_Convention.md` |
| 提交规范 | `docs/Commit_Convention.md` |

---

*版本：v1.0.0 | 更新：2026-04-21*