---
name: git-commit-gen
description: 根据 git status 和 git diff 自动生成符合规范的中文 commit message，支持 Conventional Commits 格式，包含模块名称
version: 1.0.0
author: Claude Code Assistant
allowed-tools: Bash, Read, Glob
---

# Git Commit 信息生成技能

## 触发条件

当用户输入包含以下关键词时触发：
- "生成 commit"、"生成提交信息"、"commit message"
- "帮我写 commit"、"自动 commit"、"提交信息"
- "git commit"、"commit 信息"

## Commit 信息规范

本项目使用中文 Conventional Commits 格式：

```
<type>(<scope>): <subject>

[可选的详细描述]
```

### Type 类型

| Type | 说明 | 示例 |
|------|------|------|
| feat | 新功能 | feat(聊天对话): 新增消息引用功能 |
| fix | Bug 修复 | fix(聊天对话): 修复消息流式渲染问题 |
| docs | 文档变更 | docs(README): 更新安装说明 |
| style | 代码格式调整（不影响功能） | style(按钮): 调整按钮边距 |
| refactor | 重构（既不是新功能也不是修复） | refactor(API): 优化请求处理逻辑 |
| perf | 性能优化 | perf(列表): 优化虚拟滚动性能 |
| test | 测试相关 | test(工具函数): 添加单元测试 |
| build | 构建系统或外部依赖变更 | build(deps): 升级 React 到 18.3 |
| ci | CI 配置文件和脚本变更 | ci(github): 添加自动化测试流程 |
| chore | 其他不修改源码的变更 | chore(配置): 更新 eslint 规则 |

### Scope 范围

根据修改的模块确定，常见范围：
- 聊天对话、侧边栏、用户认证、API、配置、工具函数等
- 可以是文件名、功能模块名或组件名
- 如果影响多个模块，使用主要模块或使用 `*` 表示全局

### Subject 主题

- 使用中文简洁描述修改内容
- 不超过 50 个字符
- 使用动词开头：修复、新增、优化、调整、更新等
- 不使用句号结尾

## 执行步骤

### 1. 检查 Git 状态

```bash
git status --short
```

如果工作区干净（无修改），提示用户没有需要提交的更改。

### 2. 分析变更内容

```bash
# 查看修改的文件统计
git diff --stat

# 查看暂存区的详细变更（如果有暂存的文件）
git diff --cached

# 查看工作区的详细变更（如果没有暂存）
git diff
```

### 3. 智能分析并生成 Commit Message

基于变更内容，分析：

1. **确定 Type**：
   - 新增文件/功能 → feat
   - 修复问题/错误 → fix
   - 代码重构 → refactor
   - 性能优化 → perf
   - 样式调整 → style
   - 其他 → chore

2. **确定 Scope**：
   - 根据修改的主要文件路径推断模块名
   - 例如：`src/pages/chat/` → 聊天对话
   - 例如：`src/components/sidebar/` → 侧边栏
   - 例如：`src/providers/rag-chat-provider.ts` → RAG 聊天
   - 例如：`vite.config.ts` → 配置

3. **生成 Subject**：
   - 总结主要修改内容
   - 使用简洁的中文描述
   - 突出核心改动点

### 4. 输出格式

生成 2-3 个候选 commit message，按推荐度排序：

```
推荐的 Commit Message：

1. fix(聊天对话): 修复消息引用流式渲染问题

2. fix(消息组件): 修复引用源在流式响应时无法点击

3. refactor(聊天对话): 优化消息引用组件渲染逻辑
```

每个候选项后面提供简短说明（1-2 句话）解释为什么这样写。

### 5. 提供详细描述（可选）

如果变更较复杂，可以生成多行详细描述：

```
fix(聊天对话): 修复消息引用流式渲染问题

- 使用 key 属性强制重新渲染 SourcesComponent
- 解决闭包陷阱导致的 sources 数据不更新问题
- 移除所有调试 console.log 语句
```

## 参考项目历史 Commit

在生成前，查看最近的提交历史作为参考：

```bash
git log --oneline -10
```

确保生成的格式与项目现有风格一致。

## 注意事项

- 确保在 git 仓库目录下执行
- 如果有大量文件修改，考虑建议用户分多次提交
- 提交信息要准确反映实际修改内容
- 避免使用模糊的描述如"修改"、"更新"等，要说明具体修改了什么
- 如果是多个不相关的修改，建议用户分开提交

## 示例输出

```
检测到以下变更：

修改的文件：
  M src/pages/chat/components/message-content.tsx
  M src/providers/rag-chat-provider.ts
  M src/hooks/use-chat.ts

变更统计：
  3 files changed, 45 insertions(+), 23 deletions(-)

---

推荐的 Commit Message：

✅ 1. fix(聊天对话): 修复消息引用在流式响应时无法点击
   理由：主要修改集中在消息组件和聊天 provider，核心问题是修复交互 bug

⭕ 2. refactor(聊天对话): 优化消息引用组件渲染机制
   理由：从实现角度看更像是重构了渲染逻辑

⭕ 3. fix(消息组件): 解决流式渲染时的引用源闭包问题
   理由：更技术化的描述，突出了具体的技术问题

---

详细描述（可选）：

fix(聊天对话): 修复消息引用在流式响应时无法点击

- 使用 key 属性强制 SourcesComponent 重新渲染
- 解决 React 闭包导致的 sources 状态不同步问题
- 清理所有调试用的 console.log 语句

---

是否需要我帮你执行提交？(可以选择上面任意一个 commit message)
```
