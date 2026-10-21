# nvim-lspconfig

> 公开插件 · [回到插件目录](../PLUGINS.md)

## 它解决什么问题

LSP 提供跳转定义、找引用、重命名、诊断、补全。lspconfig 负责**把语言和服务器接起来**，
并把常用操作绑成键。

这份配置的关键设计是：**映射按 buffer 绑定，而不是全局**。
所以同一个键在不同语言里可以指向不同实现——COBOL 的 `gd` 由私有插件接管，
Lua 的 `gd` 走 LSP。

## 在当前配置里怎么用

按键在 `LspAttach` 时注册，只在**当前 buffer 有效**：

| 按键 | 作用 |
|---|---|
| `gd` | 跳到定义 |
| `gD` | 跳到声明 |
| `K` | 悬停文档 |
| `gI` | 跳到实现 |
| `gy` | 跳到类型定义 |
| `gK` / `<C-S-k>` | 参数提示（后者在插入模式） |
| `<leader>ca` | 代码操作 |
| `<leader>cr` | 重命名符号 |
| `<leader>co` | 整理 import |
| `<leader>cl` | 查看 LSP 信息 |
| `<leader>cR` | 重命名文件 |
| `]]` / `[[` | 下一个 / 上一个引用 |
| `<a-n>` / `<a-p>` | 同上，但在浮窗里预览 |

### 与 buffer 绑定的意义

```vim
:verbose nmap gd
```

在 Lua 文件里应该显示 LSP 的映射；在 COBOL 文件里应该显示 `cobol.nvim` 的映射。
**同一个键，不同来源**——这是判断「为什么这个键行为和文档不一样」的直接方法。

### inlay hints 与折叠

- inlay hints 在服务器支持时自动打开（`textDocument/inlayHint`）。
- **折叠不交给 LSP**。`foldmethod` 保持 `expr`，由 nvim-ufo 负责。
  两套折叠会互相覆盖，所以配置明确禁止 LSP 改 `foldmethod`。

## 动手练习

1. 打开一个 Lua 文件，在函数名上按 `gd`，用 `Ctrl-o` 返回。
2. 在同一个符号上按 `K` 看文档，再按 `gK` 看参数提示。
3. `<leader>ca` 打开代码操作菜单，把光标放在一个能触发操作的位置。
4. 在符号上 `<leader>cr` 重命名，确认相关文件都被改。
5. `]]` 跳下一个引用，观察浮窗预览。
6. 打开一个 COBOL 文件，`:verbose nmap gd`，确认来源是 cobol.nvim。

**验收**：第 1–5 条在 Lua 里生效，第 6 条显示不同的映射来源。

## 注意事项

- **服务器要先装好**。用 Mason（`<leader>cm`）装，否则 `LspAttach` 不会触发，
  所有键都不存在——不是配置漏了。
- **`<leader>cr` 在 COBOL 里不是 LSP 重命名**。COBOL 没有 LSP server，
  该键被 cobol.nvim 用于记录布局计算。
- **诊断被有意限制**。配置里关掉了部分自动诊断，只保留你需要的；
  所以「没有报错」不等于「代码正确」，尤其 COBOL 要看 `cobc`。
- **inlay hints 会增加视觉噪音**。不习惯可以按需关闭，它是 buffer-local 的。

## 查快捷键和帮助

```vim
:help lspconfig
:help lsp
:LspInfo
```

`<leader>cl` 打开 LSP 信息面板，能看到当前 buffer 挂了哪些服务器、各自支持什么能力。
