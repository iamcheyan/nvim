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
| 找所有引用 | `grr` 或 `<leader>ca` 里的「引用」 |
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

## 为什么 COBOL 没有 LSP

因为没有人为 COBOL 写 Language Server（至少没有成熟的）。

原因很实际：COBOL 的代码库多是几十年前的、企业内部私有，社区做通用 server 缺乏动力。

所以在 COBOL 文件里：

- `gd` 由 `cobol.nvim` 接管（它自己解析 COBOL 结构）
- 诊断由 `cobc` 提供（跑真正的编译器）
- 没有补全、没有重命名、没有代码操作

**这不是配置缺陷，是 COBOL 生态的现状。**

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

## 诊断的显示

Neovim 有两套诊断来源：

| 来源 | 例子 |
|---|---|
| LSP | pyright 报类型错误 |
| nvim-lint | shellcheck 报脚本问题 |

两者都汇入同一个诊断系统，用同样的键跳转（`]d` / `[d`）。

这份配置的显示策略：

- **符号列有标记**
- **行内下划线**
- **行尾虚拟文本关闭**（避免干扰阅读）

## 性能考虑

LSP 会索引整个工作区。大项目里这是个负担。

这份配置做了一个取舍：pyright 的 `diagnosticMode` 设成 `openFilesOnly`。

意思是「只检查打开的文件」，不扫整个工作区。代价是没打开的文件里的错误不报；
好处是启动快、不会占满 CPU。

## 常见问题

| 现象 | 原因 | 检查 |
|---|---|---|
| `gd` 没反应 | server 没装或没 attach | `:LspInfo` |
| 诊断不显示 | 该文件类型没有 server | `:LspInfo` |
| 补全不弹出 | 同上，或 blink 配置问题 | `:checkhealth blink` |
| 卡顿 | server 在索引大项目 | 看 fidget 进度提示 |
| COBOL 里 `gd` 行为和文档不同 | 那是 cobol.nvim，不是 LSP | `:verbose nmap gd` |

**排查第一站永远是 `:LspInfo`**——它列出当前 buffer 挂了哪些 server、各自支持什么能力。

## 下一步

- [05 Treesitter 与正则高亮](05-treesitter.html)
- [插件手册：nvim-lspconfig](../plugins/nvim-lspconfig.html)
- [插件手册：mason](../plugins/mason.html)
