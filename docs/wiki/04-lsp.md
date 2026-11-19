# LSP 是什么

> 为什么编辑器能「跳到定义」？为什么 COBOL 没有这个功能？这一篇讲清 LSP 的边界。

## 一句话

LSP（Language Server Protocol）是**编辑器和语言分析程序之间的通信协议**。

编辑器负责界面，服务器负责「理解代码」。两者用 JSON-RPC 对话。

## 为什么需要协议

早期每个编辑器都要为每种语言单独写支持（Vim 有 ctags、cscope、各种 ftplugin）。
N 个编辑器 × M 种语言 = N×M 份工作。

LSP 把这件事解耦：语言方只写一个 server，编辑器方只写一个 client。
N + M 份工作。

## LSP 能做什么

| 能力 | 你需要什么 |
|---|---|
| 跳到定义 | 光标在符号上按 `gd` |
| 找所有引用 | Neovim 内置 `grr` |
| 悬停文档 | `K` |
| 重命名 | `<leader>cr` |
| 代码操作（加 import、提取变量） | `<leader>ca` |
| 诊断（语法错误、类型错误） | 自动显示 |
| 补全 | 输入时弹出 |
| 格式化 | `gq` 或 `<leader>fo` |

**共同点**：这些都需要「理解代码的语义」。正则做不到。

## LSP 不能做什么

- **不能保证代码能跑**。它做静态分析，运行时错误它不知道。
- **不能替代编译器**。COBOL 的最终验证是 `cobc`。
- **不是编辑器的一部分**。它是外部程序，要单独安装。

## 本配置里的 COBOL 能力

本配置没有为 COBOL 启用 LSP server；它使用专门的插件处理语言结构和编译检查：

- `gd` 由 `cobol.nvim` 接管（它自己解析 COBOL 结构）
- 诊断可由 `cobol.nvim` 调用 `cobc` 提供
- Blink 仍可提供路径、片段和当前 buffer 补全，但没有 LSP 语义补全
- 没有 LSP 重命名和代码操作

因此这里描述的是当前配置的能力，不代表整个 COBOL 生态没有 LSP 实现。

## 客户端和服务器的关系

```
Neovim                nvim-lspconfig          语言服务器
   │                        │                      │
   │──── 启动请求 ─────────>│                      │
   │                        │──── 启动进程 ───────>│
   │<──── LspAttach ────────┤                      │
   │                        │<──── 能力声明 ────────│
   │──── 请求跳转定义 ──────────────────────────────>│
   │<──── 返回位置 ─────────────────────────────────│
```

三个组件各管一段：

| 组件 | 职责 |
|---|---|
| Neovim 内置 LSP 客户端 | 协议通信、消息路由 |
| nvim-lspconfig | 每种 server 的启动参数和默认配置 |
| mason.nvim | 下载安装 server 二进制 |

这份配置里 `<leader>cm` 打开 Mason 装 server，装完 mason-lspconfig 自动接上。

## 键位为什么是 buffer 局部的

LSP 的键在 `LspAttach` 事件里注册——也就是「server 连上这个 buffer 时」。

所以：

- 没有 server 的文件，`gd` 用的是别的实现（或者不存在）
- 同一个 `gd`，在 Lua 文件走 LSP，在 COBOL 文件走 cobol.nvim

`：verbose nmap gd` 能看出当前 buffer 里它是谁。

## 诊断的显示与侧边栏徽章

诊断来源包括：

| 来源 | 例子 |
|---|---|
| LSP | pyright 报类型错误 |
| 语言插件 / 编译器 | 例如 COBOL 插件调用 `cobc` 检查 |

诊断来源汇入 Neovim 的诊断系统，可用 `]d` / `[d` 跳转。当前配置没有启用 nvim-lint。

### 显示策略与渲染原理

```
[LSP 服务器 / 语言插件]
           │
           ▼
[Neovim 内置 vim.diagnostic]
           ├── 标记列 signs
           └── 文本下划线
```

当前显示设置如下：

1. **行尾虚拟文本关闭**（`virtual_text = false`）：避免悬浮文字挤占代码视线。
2. **行内下划线**（`underline = true`）：保留出错位置波浪线标明精确范围。
3. **标记列**（`signs`）：启用诊断标记；启用 Nerd Font 时使用配置中的图标。
4. **Neo-tree** 设置 `enable_diagnostics = false`，文件树不显示诊断标记。

### 诊断标记与 Nerd Font

当前配置将 `vim.g.have_nerd_font` 设为 `true`，诊断标记使用以下 Nerd Font 字符。终端需要安装支持这些字符的 Nerd Font 才能正确显示：

| 级别 | 字符 |
|---|:---:|
| Error | ` ` |
| Warn | ` ` |
| Info | ` ` |
| Hint | ` ` |

#### 图标与颜色
Neovim 根据诊断严重级别选择对应标记；颜色由 `DiagnosticSign*` 高亮组决定。没有配置自动检测终端字体或单字母回退。

### 诊断相关按键与排查

当看到代码行出现 ``（警告）或 ``（错误）时：

| 按键 | 作用 | 说明 |
|---|---|---|
| `<leader>cd` | 浮窗查看当前行诊断 | 弹出 Float Window 显示具体错误信息、规则名称与来源 |
| `]d` / `[d` | 跳转到下 / 上一个诊断 | 快速在文件内的各个问题点之间巡检 |
| `<leader>ud` | 切换诊断显示 | 由 Snacks toggle 控制 Neovim 诊断启用状态 |

## 性能考虑

语言服务器是否检查整个工作区取决于各自设置。当前 basedpyright 配置只检查已打开的文件。

因此，未打开文件里的问题不会由 basedpyright 报出。

## 常见问题

| 现象 | 原因 | 检查 |
|---|---|---|
| 行号旁出现黄色警告图标 `` | 该行存在 Warning 级别代码诊断（如未使用变量、语法警告等） | `<leader>cd` 浮窗看原因，或 `]d` 跳转 |
| `gd` 没反应 | server 没装或没 attach | `:LspInfo` |
| 诊断不显示 | 该文件类型没有 server | `:LspInfo` |
| 补全不弹出 | 同上，或 blink 配置问题 | `:checkhealth blink` |
| 卡顿 | server 在索引大项目 | 看 fidget 进度提示 |
| COBOL 里 `gd` 行为和文档不同 | 那是 cobol.nvim，不是 LSP | `:verbose nmap gd` |

排查 LSP 问题可先运行 `:LspInfo`，查看当前 buffer 附加的服务器及其能力。COBOL 编译检查则查看 cobol.nvim 的命令和诊断。

## 下一步

- [05 Treesitter 与正则高亮](05-treesitter.html)
- [插件手册：nvim-lspconfig](../plugins/nvim-lspconfig.html)
- [插件手册：mason](../plugins/mason.html)
